local utils = {}

--- Sleeps for the number of seconds given
--- @param secs integer Seconds to sleep
function utils.sleep(secs)
    os.execute("sleep " .. tonumber(secs))
end

--- Sleeps for the number of milliseconds given
--- @param msecs integer Milliseconds to sleep
function utils.msleep(msecs)
    local usecs = msecs * 1000
    os.execute("usleep " .. usecs)
end

--- Prints all members of a table and their values
--- @param tbl table Table to print
function utils.printTable(tbl)
    for k, v in pairs(tbl) do
        print(k .. " = " .. v .. " (" .. type(v) .. ")")
    end
end

--- Trims whitespace from the beginning and end of the string. Taken from the trim5()
--- implementation at http://lua-users.org/wiki/StringTrim
--- @param s string
--- @return string # Input string with leading and trailing whitespaces removed
function utils.strim(s)
    return s:match("^%s*(.*%S)")
end

--- Reads keys and values from the specified config file
--- @param filename string Filepath to read from
--- @param defaults table Default values (optional)
function utils.importConfig(filename, defaults)
    if not defaults then
        defaults = {}
    end
    for line in io.lines(filename) do
        local k, v = line:match('^%s*([^ =]+)%s*=%s*"?([^"]+)"?%s*$')
        if k ~= nil then
            k = utils.strim(k)
            v = utils.strim(v)
            if tonumber(v) then
                v = tonumber(v)
            end
            defaults[k] = v
        end
    end
    return defaults
end

--- Pings the given host until reachable or the number of retries is reached
--- @param hostname string Hostname to ping
--- @param tries integer Number of tries (Default: 1)
--- @param callback function|nil Callback to run after each unsuccessful ping
--- @return boolean # TRUE if host was reached, FALSE if host wasn't reachable
function utils.pingWait(hostname, tries, callback)
    tries = tries or 1
    repeat
        local exitcode = os.execute('ping -c 1 "' .. hostname .. '" >/dev/null 2>&1')
        if exitcode == 0 then return true end
        if callback then callback() end
        tries = tries - 1
        if tries > 0 then utils.sleep(1) end
    until tries == 0
    return false
end

return utils
