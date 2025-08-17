# ----------------------------- UTILITY FUNCTIONS -------------------------------- #

# Print text centred
function printc {
  local len=${#1}
  local halflen=$((len/2))
  local x=$((33-halflen))
  eips $x $PRINTC_Y $*
  PRINTC_Y=$((PRINTC_Y+1))
}

function printlog {
  # Scroll feature calculates 72 rows, params: <start_row> <num_rows>
  # Scrolls only 24 pixels, not leaving a space between lines
  eips -z 50 22
  eips 1 59 "$1"
}

function degauss {
  # Flash contents of whole screen, i.e. turn inverted and back to remove artefacts
  # (or grab attention)
  eips -s w=1072,h=1448 -f
}

get_kindle_width() {
  # Run the command and capture its output
  local result=$(eips -i)

  # Extract xres using grep and awk
  local xres=$(echo "$result" | grep "xres:" | head -1 | awk '{print $2}')

  # Return just the width value
  echo "$xres"
}

get_kindle_height() {
  # Run the command and capture its output
  local result=$(eips -i)

  # Extract yres using grep and awk
  local yres=$(echo "$result" | grep "yres:" | head -1 | awk '{print $4}')

  # Return just the height value
  echo "$yres"
}
