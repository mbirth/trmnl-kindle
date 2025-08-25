--[[
    Everything related to the TRMNL API
]]

local TrmnlFactory = {}
local Trmnl = {}
Trmnl.__index = Trmnl

--- Create new TRMNL object
--- @param api_url string URL to TRMNL API endpoint
function TrmnlFactory.new(api_url)
    local obj = setmetatable({}, Trmnl)
    obj.API_URL = api_url
    return obj
end
setmetatable(TrmnlFactory, { __call = TrmnlFactory.new })

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

--- Outputs current readings from the battery callbacks (if set) to the terminal
function Trmnl:debugBattery()
    if self.batteryCapacityCallback then print("Battery Capacity: " .. self.batteryCapacityCallback()) end
    if self.batteryVoltageCallback then print("Battery Voltage: " .. self.batteryVoltageCallback()) end
end

return TrmnlFactory
