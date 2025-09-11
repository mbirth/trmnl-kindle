#!/usr/bin/env lua

--[[
    TRMNL-Kindle in Lua
    Markus Birth <2025@mbirth.uk>
    https://github.com/mbirth/trmnl-kindle/
    
    This is a TRMNL implementation based on the Shell script variant at
    https://github.com/usetrmnl/trmnl-kindle . Optimised for the Kindle Paperwhite 10th gen.
]]

-- Resources:
-- https://www.lua.org/manual/5.1/manual.html
-- https://www.mobileread.com/forums/showthread.php?t=272221

local eips = require("eips")
local kindle = require("kindle")
local TrmnlApi = require("trmnlapi")
local utils = require("utils")

eips.print(28, 17, string.rep(" ", 32), true)
eips.print(29, 17, "  Stopping Kindle Framework...  ", true)
eips.print(30, 17, string.rep(" ", 32), true)

kindle.stopFramework()

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
    TMP_DIR = "/tmp/trmnl-kindle"
}
config = utils.importConfig("TRMNL.conf", config)

eips.printc(22, "Configured URL:")
eips.printc(23, config.BASE_URL)

utils.sleep(1)

eips.printlog("Determine hostname from URL...")
config.BASE_HOST = config.BASE_URL:match("https?://([^/:]+)")

eips.printlog("Check/prepare folder for temporary files...")
os.execute('mkdir -p "' .. config.TMP_DIR .. '"')

-- Get MAC address for TRMNL-identity
eips.printlog("Read MAC address...")
local macAddress = kindle.getMacAddress()

eips.printlog("Disable screensaver...")
kindle.disableScreensaver()

-- Stop Kindle services
for _, svcName in ipairs(kindle.stopServices) do
	eips.printlog("Stopping service " .. svcName .. "...")
    kindle.stopService(svcName)
end

-- Stop Kindle processes
for _, procName in ipairs(kindle.stopProcesses) do
	eips.printlog("Stopping process " .. procName .. "...")
    kindle.stopProcess(procName)
end

eips.printlog("Setting display frontlight brightness to " .. config.BRIGHTNESS .. "...")
kindle.setBrightness(config.BRIGHTNESS)

eips.printlog("Determining display details...")
local displayInfo = eips.info()

eips.printlog("Initialise TRMNL object...")
local trmnl = TrmnlApi.new(config.BASE_URL, config.API_KEY, macAddress)
trmnl:setDisplayDimensions(displayInfo.yres, displayInfo.xres, 90)   -- swap width/height and set 90deg rotation
trmnl:setBatteryCapacityCallback(function() return kindle.getBatteryPercent() end)
trmnl:setBatteryVoltageCallback(function() return kindle.getBatteryVoltage() end)
trmnl:setTempDir(config.TMP_DIR)

-- Flash Splash box
eips.flash(336, 288, 386, 216)

eips.printlog("All done. Starting main loop...")

eips.clearScreen()

-- DEBUG:
utils.printTable(config)

local impressions = 0
while true do
    -- Indicate start of server query
    eips.drawxy(0, 12, 8, 8, 0)

    -- Load next image metadata from TRMNL server
    local dispInfo = trmnl:getDisplayInfo()
    local refreshRate = 0
    if dispInfo then
        -- Indicate successful query
        eips.drawxy(0, 24, 8, 8, 0)

        refreshRate = dispInfo["refresh_rate"]

        -- Download remote file to local
        local imagePath = trmnl:downloadImage(dispInfo)

        if imagePath then

            -- Render image
            eips.render(imagePath)

            -- Degauss/redraw screen if reached configured amount of impressions
            impressions = impressions + 1
            if impressions >= config.DEGAUSS_AFTER then
                eips.degauss()
                impressions = 0
            end

        else
            eips.printc(22, "ERROR: Image not downloaded. Retry in 10s...", true)
            eips.printc(23, dispInfo["image_url"])
            refreshRate = 10
        end
    else
        eips.printc(22, "ERROR: Empty answer from server. Retry in 60s...", true)
        refreshRate = 60
    end

    -- Go to sleep
    kindle.smartSleep(
        refreshRate,
        function() eips.drawxy(0, 0, 8, 8, 0) end,
        function() eips.flash(0, 0, 8, 8) end,
        function(hostname) eips.printc(29, hostname .. " not pingable. Retrying...") end
    )
end
