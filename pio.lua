local board = require('board')

local pio = {}
pio.pin = {}
pio.port = {}

pio.INPUT = 'in'
pio.OUTPUT = 'out'
pio.PULLUP = '1'
pio.PULLDOWN = '0'
pio.NOPULL = ''

--[[ Access the GPIO from user space
  echo 20 > /sys/class/gpio/export; export the pins to userland
  echo out > /sys/class/gpio/gpio20/direction; set direction: 'in' or 'out'
  echo 1 > /sys/class/gpio/gpio20/value; set the value: '1' or '0'
  cat /sys/class/gpio/gpio20/value; get the value
  events can be triggered by GPIO pins:
  echo rising > /sys/class/gpio/gpio20/edge; use 'rising', 'falling' or 'both'
  to get the event do a read from the value file. The read will block until the event occurs
  For debugging, cat /sys/kernel/debug/gpio
--]]

local gpio_path = '/sys/class/gpio/'

local function multi_write(op, ...)
    local filename = gpio_path .. op
    local fh = assert(io.open(filename, 'w'))
    for i,v in pairs{...}  do
        fh:write(v)
        fh:flush()
    end
    fh:close()
end

-- exports the pins (makes them available in user space)
function pio.pin.export(...)
    local op = 'export'
    return multi_write(op, ...)
end

-- unexports the pins
function pio.pin.unexport(...)
    local op = 'unexport'
    return multi_write(op, ...)
end

-- reads or writes from/to file
local function file_access(filename, op, value)
    local result
    --print('debug:', filename, ' ', op, ' ', value)
    local fh = assert(io.open(filename, op))
    if op == 'r' then
        result = fh:read()
    elseif op == 'w' then
        result = fh:write(value)
    else
        result = nil
    end
    fh:close()
    return result
end

function pio.pin.setdir(direction, ...)
    -- make sure that we don't write junk
    if direction ~= pio.OUTPUT and direction ~= pio.INPUT then
        return nil, 'invalid direction: ' .. direction
    end
    for i,v in ipairs{...} do
        local gpio_nr = tonumber(v)
        if gpio_nr == nil then
            goto continue_setdir
        end
        local filename = gpio_path .. '/gpio' .. gpio_nr .. '/direction'
        file_access(filename, 'w', direction)
::continue_setdir::
    end
    return 
end

-- iterate over pins and set/get values;
-- op must be 'r' or 'w'
-- value must be 0 or 1 ... well, at least a number
local function pin_set_get(op, value, ...)
    local values = {}
    local i = 1
    for i,p in pairs{...} do
        local gpio_nr = tonumber(p)
        if gpio_nr == nil then
            goto continue
        end
        local filename = gpio_path .. '/gpio' .. gpio_nr .. '/value'
        values[i] = file_access(filename, op, value)
        i = i + 1
    end
    ::continue::
    return table.unpack(values)
end

-- get pin value
function pio.pin.getval(...)
    return pin_set_get('r', nil, ...)
end

-- set pin value
function pio.pin.setval(value, ...)
    -- at least, make sure it's a number
    value = tonumber(value)
    --print('setting pin to ', value)
    if value == nil then
        return nil, 'invalid value'
    end
    return pin_set_get('w', value, ...)
end

function pio.pin.sethigh(...)
    return pio.pin.setval(1, ...)
end

function pio.pin.setlow(...)
    return pio.pin.setval(0, ...)
end

-- set pull type (up, down, strong, weak, ...)
-- not all processors support it, so implement it if needed
function pio.pin.setpull(type, ...)
    return nil, 'not implemented'
end

return pio
