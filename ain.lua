local board = require('board')
local utils = require('utils')
local ain = {}

-- enable ADC (load device tree file)
-- 1. load cape-bone-iio
-- 2. see if the AIN? files exist in /sys/devices/ocp.?/helper.?/
function ain.enable()
    local ain_path
    if utils.load_devtree('cape-bone-iio') then
        ain_path = utils.find_file('/sys/devices', 'ocp.')
        ain_path = utils.find_file(ain_path, 'helper.')
        if ain_path then
            ain_path = ain_path .. '/AIN'
            ain.ain_path = ain_path
        end
    end
    return ain_path
end

-- for each pin, read adc file, value = value / 1800
function ain.read(...)
    if not ain.ain_path then
        return -- no files to read from
    end
    local values = {}
    for i,c in pairs{...} do
        local filename = ain.ain_path .. c
        local fh = assert(io.open(filename, 'r'), 'can not open adc channel' .. filename)
        local val = tonumber(fh:read()) / 1800
        values[i] = val
    end
    return table.unpack(values)
end

return ain
