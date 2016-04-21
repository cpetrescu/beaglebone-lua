lfs = require('lfs')

local utils = {}

-- Looks in 'dir' for a file name starting with 'prefix'
-- Returns the first match

function utils.find_file(dir, prefix)
    assert(dir and dir ~= '', 'invalid folder')
    assert(prefix and prefix ~= '', 'invalid prefix')
    for entry in lfs.dir(dir) do
        if string.match(entry, prefix) then
            return dir .. '/' .. entry
        end
    end
end

-- load device tree overlay (.dtbo file from /lib/firmware)
function utils.load_devtree(dtbo)
    local sys_path = '/sys/devices'
    local fname = utils.find_file(sys_path, 'bone_capemgr.')
    if fname then
        fname = fname .. '/slots'
    else
        return nil
    end
    local fh = assert(io.open(fname, 'w'))
    fh:write(dtbo)
    fh:close()
    return true
end

-- onloading overlays seems to be broken. It causes kernel panics.
-- So, Im gonna implement this some other time
function utils.unload_devicetree(devtree)
    return nil, "not implemented"
end

return utils
