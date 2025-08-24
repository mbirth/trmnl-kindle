--[[
    Kindle-specific methods
]]

local kindle = {}

-- https://github.com/koreader/koreader/blob/c4f9c60742409c8edb2f13c50bbb7ab8d9997218/platform/kindle/koreader.sh#L284-L287
kindle.stopServices = {
    "framework", "stored", "webreader", "kfxreader", "kfxview", "todo", "tmd", "lipcd", "rcm",
    "archive", "scanner", "otav3", "otaupd", "volumd"
}

kindle.stopProcesses = {
    "awesome", "cvm"
}

---@type integer
kindle._maxBrightnessCache = nil

--- Returns the maximum brightness level allowed on this Kindle
--- @return integer # Maximum brightness level
--- @diagnostic disable: need-check-nil
function kindle.getMaxBrightness()
    if kindle._maxBrightnessCache then
        return kindle._maxBrightnessCache
    end
    local handle = io.popen("lipc-get-prop com.lab126.powerd flMaxIntensity")
    local output = handle:read("*a")
    handle:close()
    kindle._maxBrightnessCache = math.floor(output) or 0
    return kindle._maxBrightnessCache
end

--- Sets the brightness level of the frontlight
--- @param level integer Desired brightness level (0 = off)
function kindle.setBrightness(level)
    level = math.floor(level)
    assert(level >= 0)
    assert(level <= kindle.getMaxBrightness(), "Brightness level out of range")
    os.execute("lipc-set-prop com.lab126.powerd flIntensity " .. level)
end

--- Stops the Kindle Framework job
function kindle.stopFramework()
    os.execute('trap "" TERM; stop lab126_gui; usleep 1250000; trap - TERM')
end

--- Disables the built-in screensaver so the device doesn't go to sleep after a timeout
--- See: [Ectalite/trmnl-kindle](https://github.com/Ectalite/trmnl-kindle/blob/f67d9cddd460afa02f658c254e9dcc4573b712e4/zip_example/TRMNL.sh#L66)
function kindle.disableScreensaver()
    os.execute("lipc-set-prop com.lab126.powerd preventScreenSaver 1")
end

--- Stops the given system service
--- @param servicename string
function kindle.stopService(servicename)
    os.execute("stop " .. servicename)
end

--- Stops the given process by sending a SIGSTOP
--- @param processname string
function kindle.stopProcess(processname)
    os.execute("killall -STOP " .. processname)
end


return kindle
