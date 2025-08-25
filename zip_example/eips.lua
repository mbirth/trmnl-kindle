--[[
    Helper functions related to the Kindle's framebuffer handling tool "eips"
]]

local eips = {}

eips._infoCache = nil

--- Returns a table with information about the display, currently only: xres and yres
--- @return { xres: integer, yres: integer } # Display dimensions
--- @diagnostic disable: need-check-nil
function eips.info()
    if eips._infoCache then
        return eips._infoCache
    end
    local handle = io.popen("eips -i | grep xres | head -1")
    -- returns: "    xres:                   1072    yres:                   1448"
    local output = handle:read("*a")
    handle:close()
    local m = string.gmatch(output, "%d+")
    local xres = m()
    local yres = m()
    eips._infoCache = { xres = xres, yres = yres }
    return eips._infoCache
end

--- Clears the screen
function eips.clearScreen()
    os.execute("eips -c >/dev/null")
end

--- Flashes the given region to remove artefacts (or grab attention)
--- @param x integer? X coordinate (0..1071)
--- @param y integer? Y coordinate (0..1447)
--- @param w integer? Box width
--- @param h integer? Box height
--- @diagnostic disable: redefined-local
function eips.flash(x, y, w, h)
    local x = x or 0
    local y = y or 0
    local dim = eips.info()
    local w = w or (dim.xres - x)
    local h = h or (dim.yres - y)
    local cmd = "eips -s w=" .. w .. ",h=" .. h .. " -f -x " .. x .. " -y " .. y .. " >/dev/null"
    os.execute(cmd)
end

--- Draws a rectangle in a specific shade of grey on the screen
--- @param x integer X coordinate in pixels (0..1071)
--- @param y integer Y coordinate in pixels (0..1447)
--- @param w integer Rectangle width in pixels
--- @param h integer Rectangle height in pixels
--- @param grey integer Greyscale level (black 0..255 white)
function eips.drawxy(x, y, w, h, grey)
    local cmd = "eips -d l=" .. string.format("%x", grey) .. ",w=" .. w .. ",h=" .. h .. " -x " .. x .. " -y " .. y .. " >/dev/null"
    os.execute(cmd)
end

--- Draws a rectangle in a specific shade of grey on the screen
--- @param row integer Row to start (0..59)
--- @param col integer Column to start (0..66)
--- @param rows integer Rectangle height in rows
--- @param cols integer Rectangle width in columns
--- @param grey integer Greyscale level (black 0..255 white)
function eips.draw(row, col, rows, cols, grey)
    -- Characters are 16 x 24
    eips.drawxy(col * 16, row * 24, cols * 16, rows * 24, grey)
end

--- Flashes the contents of the screen to remove artefacts (or grab attention)
function eips.degauss()
    eips.flash()
end

--- Prints text at the specified row/col
--- @param row integer Row to start (0..59)
--- @param col integer Column to start (0..66)
--- @param text string Text to print
--- @param inverse boolean? Whether to invert the text (black background, white text)
function eips.print(row, col, text, inverse)
    local cmd = "eips " .. col .. " " .. row
    if inverse then
        cmd = cmd .. " -h"
    end
    cmd = cmd .. " \"" .. text .. "\" >/dev/null"
    os.execute(cmd)
end

--- Prints text centred at the specified row
--- @param row integer Row to start (0..59)
--- @param text string Text to print
--- @param inverse boolean? Whether to invert the text (black background, white text)
function eips.printc(row, text, inverse)
    local col = 33 - math.floor(( #text / 2 ) + 0.5)   -- add 0.5 to imitate rounding
    eips.print(row, col, text, inverse)
end

--- Prints a log message into the very last row of the screen.
--- Scrolls up the bottom part of the screen before adding the new text.
--- @param text string Text to write to the last line
--- @param inverse boolean? Whether to invert the text (black background, white text)
function eips.printlog(text, inverse)
    -- Scroll feature calculates with 72 rows (20px each) instead of 60 (24px each)
    -- Syntax: eips -z <start_row> <num_rows> [max_width]
    -- Scrolls only 23 pixels, not leaving a space between lines. Width is in pixels.
    os.execute("eips -z 50 22 >/dev/null")
    eips.print(59, 1, text, inverse)
    print("[LOG] " .. text)   -- also output to console
end


return eips
