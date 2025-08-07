# ----------------------------- UTILITY FUNCTIONS -------------------------------- #
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
