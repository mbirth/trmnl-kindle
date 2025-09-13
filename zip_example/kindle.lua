--[[
    Kindle-specific methods
]]

local kindle = {}
local utils = require("utils")

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

---@type string
kindle._defaultGatewayCache = nil

--- Returns the MAC address of the wlan0 network adapter
--- @return string
function kindle.getMacAddress()
    return utils.strim(utils.readfile("/sys/class/net/wlan0/address"))
end

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
    -- The framework job sends a SIGTERM on stop, trap it so we don't get killed
    os.execute('stop lab126_gui')
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

--- Enables WiFi
function kindle.enableWifi()
    os.execute("lipc-set-prop com.lab126.cmd wirelessEnable 1")
    -- Alternative: start wifid
    -- Alternative: lipc-set-prop com.lab126.wifid enable 1
end

--- Disables WiFi
function kindle.disableWifi()
    os.execute("lipc-set-prop com.lab126.cmd wirelessEnable 0")
    -- Alternative: stop wifid
    -- Alternative: lipc-set-prop com.lab126.wifid enable 0
end

--- Returns the battery capacity in percent
--- @return integer
--- @diagnostic disable: assign-type-mismatch, return-type-mismatch
function kindle.getBatteryPercent()
    return tonumber(utils.readfile("/sys/class/power_supply/bd71827_bat/capacity"))
end

--- Returns the battery voltage
--- @return number
--- @diagnostic disable: assign-type-mismatch, return-type-mismatch
function kindle.getBatteryVoltage()
    return (tonumber(utils.readfile("/sys/class/power_supply/bd71827_bat/voltage_now")) / 1000000)
end

--- Hibernate for the given number of seconds
--- @param seconds integer
function kindle.deepSleep(seconds)
    -- Clear any existing wakealarm
    local f = io.open("/sys/class/rtc/rtc1/wakealarm", "w")
    f:write("0")
    f:close()

    -- Set new wakealarm as relative timestamp
    f = io.open("/sys/class/rtc/rtc1/wakealarm", "w")
    f:write("+" .. tostring(seconds))
    f:close()

    -- Hibernate! (for some reason, using io.open() + f:write() doesn't work here!)
    os.execute('echo "mem" > /sys/power/state')
end

--- Delays execution for the specified number of seconds, either using the normal `sleep`
--- command, or by turning off WiFi, hibernating the CPU and turning WiFi back on afterwards
--- @param seconds integer Number of seconds to sleep
--- @param wakeCallback function|nil Callback to call() after waking up
--- @param pingCallback function|nil Callback to call() on each ping
--- @param errorCallback function|nil Callback to call(hostname) on reconnection error
function kindle.smartSleep(seconds, wakeCallback, pingCallback, errorCallback)
    if seconds < 60 then
        utils.sleep(seconds)
        if wakeCallback then wakeCallback() end
    else
        -- Time we want to leave this routine again
        local targetStamp = os.time() + seconds

        -- Get default gateway (for pinging later) while connection is still good
        if not kindle._defaultGatewayCache then
            local cmd = "route -n | grep UG | awk '{printf \"%s\",$2}'"
            local handle = io.popen(cmd)
            kindle._defaultGatewayCache = handle:read("*a")
            handle:close()
        end

        kindle.disableWifi()

        -- Shorten deep sleep to account for WiFi reconnection time
        seconds = seconds - 9

        -- Some time to settle down before hibernating
        utils.sleep(2)

        kindle.deepSleep(seconds)

        if wakeCallback then wakeCallback() end

        -- Some time to wake up after hibernating
        utils.sleep(1)

        kindle.enableWifi()

        -- Wait for Wifi to reacquire signal
        utils.sleep(3)

        repeat
            -- Try to ping host up to 20 times, flash indicator between tries
            local pingResult = utils.pingWait(kindle._defaultGatewayCache, 20, pingCallback)
            if not pingResult then
                if errorCallback then errorCallback(kindle._defaultGatewayCache) end
                -- Toggle WiFi just to make sure we have a connection
                kindle.disableWifi()
                utils.sleep(1)
                kindle.enableWifi()
            end
        until pingResult

        -- NOTE: WiFi reconnect occasionally takes a few seconds longer.
        --       If you need exact timing, you'd need to shorten the deep sleep time and then
        --       calculate the remaining sleep time here and sleep for another few seconds until
        --       the desired sleep time (targetStamp) has been reached.

    end
end

return kindle
