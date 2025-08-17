#!/bin/sh
###############################################################################
# TRMNL.sh
#
# Kindle-friendly shell script that:
#  1. Prints debug messages on-screen using eips
#  2. Fetches JSON from TRMNL's API
#  3. Parses out the image URL and refresh rate
#  4. Downloads the image by POSTing the entire JSON response to the proxy
#  5. Displays the image via eips
#  6. Prints the FULL image URL and FULL filename below the displayed image
#  7. Loops, sleeping for <refresh_rate> seconds
###############################################################################

# If eips is not found (i.e. running locally), define a no-op stub for testing
if ! command -v eips >/dev/null 2>&1; then
  eips() {
    # Simply echo to console so you can see what *would* happen on Kindle
    echo "[eips STUB] $*"
  }
fi

# Splash
eips -c
eips -d l=cc,w=384,h=216 -x 336 -y 288
eips -d l=88,w=320,h=168 -x 368 -y 312
eips -d l=44,w=256,h=120 -x 400 -y 336
eips -d l=00,w=192,h=72 -x 432 -y 360
eips 29 16 -h "TRMNL.sh"

# Kindle Paperwhite 10th gen:
#   Pixels are 1072 x 1448
#   Characters are 16 x 24
#   Text screen is 67 columns (0..66) and 60 lines (0..59)
#   eips 0 0 X <-- top left corner
#   eips 33 29 X <-- centre
#   eips 66 59 X <-- bottom right corner

source ./TRMNL.conf
source ./utils.sh

PRINTC_Y=25; printc "Starting..."

# TODO: Read RSSI via iwconfig or cat /proc/net/wireless
RSSI="0"
USER_AGENT="trmnl-display/0.1.1"

# Temporary folder to hold downloaded files
printlog "Check/prepare folder for temporary files..."
TMP_DIR="/tmp/trmnl-kindle"
mkdir -p "$TMP_DIR"

# Size of the PNG in *pixels*
printlog "Read display dimensions..."
PNG_WIDTH=$(get_kindle_height)
PNG_HEIGHT=$(get_kindle_width)
ROTATION=90




while true; do


  # 1) Indicate the start of a new loop

  # 2) Fetch JSON metadata
  BATTERY_VOLTAGE=$(cat /sys/class/power_supply/bd71827_bat/capacity)
  RESPONSE="$(
    curl -L -s \
      -H "access-token: $API_KEY" \
      -H "battery-voltage: $BATTERY_VOLTAGE" \
      -H "png-width: $PNG_WIDTH" \
      -H "png-height: $PNG_HEIGHT" \
      -H "rssi: $RSSI" \
      -A "$USER_AGENT" \
      "${BASE_URL}/api/display"
  )"

  # If no response, display error and retry
  if [ -z "$RESPONSE" ]; then
    PRINTC_Y=22; printc -h "ERROR: Empty answer from server. Retry in 60s..."
    sleep 60
    continue
  fi

  # Show part of the JSON in debug (trim if it's too long)
  SHORT_JSON="$(echo "$RESPONSE" | cut -c1-60)"

  # Parse JSON (naive sed approach)
  IMAGE_URL=$(echo "$RESPONSE" | sed -n 's/.*"image_url":"\([^"]*\)".*/\1/p' | sed 's/\\u0026/\&/g')

  REFRESH_RATE=$(echo "$RESPONSE" | sed -n 's/.*"refresh_rate":\([^,}]*\).*/\1/p')
  [ -z "$REFRESH_RATE" ] && REFRESH_RATE="60"

  # Quick check for missing URL
  if [ -z "$IMAGE_URL" ]; then
    PRINTC_Y=23; printc -h "ERROR: Unable to parse image_url from JSON. Retry in 60s..."
    sleep 60
    continue
  fi

  # Extract filename directly from the top-level JSON field if present
  FILENAME=$(echo "$RESPONSE" | sed -n 's/.*"filename":"\([^"]*\)".*/\1/p')

  # If the JSON has no "filename" field or is empty, try extracting from the URL
  if [ -z "$FILENAME" ]; then
    # Try to get filename from URL path
    FILENAME=$(echo "$IMAGE_URL" | sed -n 's/.*\/\([^?/]*\)\?.*/\1/p')
    # If that fails too, use default
    [ -z "$FILENAME" ] && FILENAME="display.png"
  fi

  # Make sure it ends with .png for eips
  case "$FILENAME" in
    *.png) : ;;
    *) FILENAME="${FILENAME}.png" ;;
  esac

  # Download the image via the proxy endpoint using POST with full JSON
  IMAGE_PATH="$TMP_DIR/$FILENAME"
  rm -f "$IMAGE_PATH"

  # Download the image directly from IMAGE_URL
  curl -s -o "$IMAGE_PATH" \
    -A "$USER_AGENT" \
    "$IMAGE_URL"

  # Check download success
  if [ ! -s "$IMAGE_PATH" ]; then
    PRINTC_Y=24; printc -h "ERROR: Image download failed. Retry in 60s..."
    sleep 60
    continue
  fi


  eips -g "$IMAGE_PATH"

  if [ "$DEBUG_MODE" = true ]; then
    eips 0 18 "URL: $IMAGE_URL"
    eips 0 19 "File: $IMAGE_PATH"
  fi

  sleep "$REFRESH_RATE"
done
