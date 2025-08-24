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
function utils.printtable(tbl)
    for k, v in pairs(tbl) do
        print(k .. " = " .. v)
    end
end

--- Trims whitespace from the beginning and end of the string. Taken from the trim5()
--- implementation at http://lua-users.org/wiki/StringTrim
--- @param s string
--- @return string # Input string with leading and trailing whitespaces removed
function utils.strim(s)
    return s:match("^%s*(.*%S)")
end

return utils
