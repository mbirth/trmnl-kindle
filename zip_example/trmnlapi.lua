--[[
    Everything related to the TRMNL API
]]

json = require("json")

local TrmnlFactory = {}
local Trmnl = {}
Trmnl.__index = Trmnl

--- Create new TRMNL object
--- @param api_url string URL to TRMNL API endpoint
--- @param api_token string API Token for the endpoint
--- @param identity string Identity of this device, usually the MAC address
function TrmnlFactory.new(api_url, api_token, identity)
    local obj = setmetatable({}, Trmnl)
    obj.USER_AGENT = "trmnl-lua/0.1.1"
    obj.API_URL = api_url
    obj.API_TOKEN = api_token
    obj.IDENTITY = identity
    obj.PNG_WIDTH = 800
    obj.PNG_HEIGHT = 400
    obj.PNG_ROTATION = 0
    obj.TMP_DIR = "/tmp"
    return obj
end
setmetatable(TrmnlFactory, { __call = TrmnlFactory.new })

--- Sets the display dimensions and rotation
--- @param xres integer Horizontal resolution (default: 800)
--- @param yres integer Vertical resolution (default: 400)
--- @param rotation integer Rotation in degrees (default: 0)
function Trmnl:setDisplayDimensions(xres, yres, rotation)
    self.PNG_WIDTH = xres
    self.PNG_HEIGHT = yres
    self.PNG_ROTATION = rotation
end

--- Sets a callback to get the current battery capacity
--- @param callback function
function Trmnl:setBatteryCapacityCallback(callback)
    self.batteryCapacityCallback = callback
end

--- Sets a callback to get the current battery voltage
--- @param callback function
function Trmnl:setBatteryVoltageCallback(callback)
    self.batteryVoltageCallback = callback
end

--- Sets a callback to query the RSSI for the WiFi connection
--- @param callback function
function Trmnl:setRssiCallback(callback)
    self.rssiCallback = callback
end

--- Sets the directory to use for temporary files
--- @param newTmpDir string
function Trmnl:setTempDir(newTmpDir)
    self.TMP_DIR = newTmpDir
end

--- Outputs current readings from the battery callbacks (if set) to the terminal
function Trmnl:debugBattery()
    if self.batteryCapacityCallback then print("Battery Capacity: " .. self.batteryCapacityCallback()) end
    if self.batteryVoltageCallback then print("Battery Voltage: " .. self.batteryVoltageCallback()) end
end

--- Retrieve display info from API endpoint
--- @return table|nil
--- @diagnostic disable: need-check-nil
function Trmnl:getDisplayInfo()
    local headers = {
        ["id"] = self.IDENTITY,
        ["access-token"] = self.API_TOKEN,
        ["fw-version"] = "99.9.9",
        ["png-width"] = self.PNG_WIDTH,
        ["png-height"] = self.PNG_HEIGHT,
        ["png-rotation"] = self.PNG_ROTATION
    }
    if self.batteryCapacityCallback then headers["battery-percent"] = self.batteryCapacityCallback() else headers["battery-percent"] = 100 end
    if self.batteryVoltageCallback then headers["battery_voltage"] = self.batteryVoltageCallback() else headers["battery_voltage"] = 4.0 end
    if self.rssiCallback then headers["rssi"] = self.rssiCallback() else headers["rssi"] = 0 end

    local cmd = "curl -L -s"
    for k, v in pairs(headers) do
        cmd = cmd .. ' -H "' .. k .. ': ' .. v .. '"'
    end
    cmd = cmd .. ' -A "' .. self.USER_AGENT .. '" "' .. self.API_URL .. '/api/display"'

    local handle = io.popen(cmd)
    local output = handle:read("*a")
    handle:close()

    if output == "" then return nil end

    local status, result = pcall(json.decode, output)
    if not status then
        print("ERROR processing JSON: ", result)
        return nil
    end
    return result
end

--- Download image file according to provided displayInfo
--- @param displayInfo table Output from Trmnl:getDisplayInfo()
--- @return string|nil Path to downloaded file (or nil on error)
function Trmnl:downloadImage(displayInfo)
    local imageUrl = displayInfo["image_url"]
    local localFile = self.TMP_DIR .. "/display.png"

    local cmd = "curl -L -s"
    cmd = cmd .. ' -H "Accept: image/png"'
    cmd = cmd .. ' -A "' .. self.USER_AGENT .. '" -o "' .. localFile .. '" "' .. imageUrl .. '"'

    local exitcode = os.execute(cmd)

    if exitcode > 0 then return nil end
    return localFile
end

return TrmnlFactory
