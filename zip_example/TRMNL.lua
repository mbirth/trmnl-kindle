#!/usr/bin/env lua

--[[
    TRMNL-Kindle in Lua
    Markus Birth <2025@mbirth.uk>
    https://github.com/mbirth/trmnl-kindle/
    
    This is a TRMNL implementation based on the Shell script variant at
    https://github.com/usetrmnl/trmnl-kindle . Optimised for the Kindle Paperwhite 10th gen.
]]

-- Resources:
-- https://www.mobileread.com/forums/showthread.php?t=272221

local eips = require("eips")
local kindle = require("kindle")
local TrmnlApi = require("trmnlapi")
local utils = require("utils")

eips.print(28, 17, string.rep(" ", 32), true)
eips.print(29, 17, "  Stopping Kindle Framework...  ", true)
eips.print(30, 17, string.rep(" ", 32), true)

-- kindle.stopFramework()

eips.clearScreen()

-- Splash
eips.draw(12, 21, 9, 24, 0xcc)
eips.draw(13, 23, 7, 20, 0x88)
eips.draw(14, 25, 5, 16, 0x44)
eips.draw(15, 27, 3, 12, 0)
eips.print(16, 29, "TRMNL.sh", true)

eips.printc(25, "Starting...")

-- Load config file
local config = {
    USER_AGENT = "trmnl-display/0.1.1",
    TMP_DIR = "/tmp/trmnl-kindle",
    TRMNL_ROTATION = 90
}
for line in io.lines("TRMNL.conf") do
    local k, v = line:match('^%s*([^ =]+)%s*=%s*"?([^"]+)"?%s*$')
    if k ~= nil then
        k = utils.strim(k)
        config[k] = utils.strim(v)
    end
end

eips.printc(22, "Configured URL:")
eips.printc(23, config.BASE_URL)

utils.sleep(1)

eips.printlog("Determine hostname from URL...")
config.BASE_HOST = config.BASE_URL:match("https?://([^/:]+)")

eips.printlog("Check/prepare folder for temporary files...")
os.execute('mkdir -p "' .. config.TMP_DIR .. '"')

eips.printlog("Read MAC address...")
---@type file*
local f = io.input("/sys/class/net/wlan0/address")
config.MAC_ADDRESS = utils.strim(f:read("*a"))
f:close()

eips.printlog("Disable screensaver...")
kindle.disableScreensaver()

-- Stop Kindle services
for i, svcName in ipairs(kindle.stopServices) do
	eips.printlog("Stopping service " .. svcName .. "...")
    -- kindle.stopService(svcName)
end

-- Stop Kindle processes
for i, procName in ipairs(kindle.stopProcesses) do
	eips.printlog("Stopping process " .. procName .. "...")
    -- kindle.stopProcess(procName)
end

eips.printlog("Setting display frontlight brightness to " .. config.BRIGHTNESS .. "...")
kindle.setBrightness(config.BRIGHTNESS)

eips.printlog("Initialise TRMNL object...")
local trmnl = TrmnlApi.new(config.BASE_URL)
trmnl:setBatteryCapacityCallback(function() return kindle.getBatteryPercent() end)
trmnl:setBatteryVoltageCallback(function() return kindle.getBatteryVoltage() end)

-- Flash Splash box
eips.flash(336, 288, 386, 216)

eips.printlog("All done. Starting main loop...")

eips.clearScreen()

-- DEBUG:
utils.printtable(config)

local impressions = 0
while true do
    -- Indicate that we're alive
    eips.drawxy(0, 0, 8, 8, 0)

    kindle.enableWifi()

    -- Wait for Wifi to reacquire signal
    utils.sleep(3)

    repeat
        -- Try to ping host up to 20 times, flash indicator between tries
        local pingResult = utils.pingWait(config.BASE_HOST, 20, function() eips.flash(0, 0, 8, 8) end)
        if not pingResult then
            eips.printc(29, config.BASE_HOST .. " not pingable. Retrying...")
            -- Toggle WiFi just to make sure we have a connection
            kindle.disableWifi()
            utils.sleep(1)
            kindle.enableWifi()
        end
    until pingResult

    -- Indicate successful connection
    eips.drawxy(0, 12, 8, 8, 0)

    trmnl:batteryDebug()


    -- DEBUG: STOP
    os.exit(0)

end



eips.degauss()
