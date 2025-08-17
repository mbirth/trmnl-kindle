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

# https://github.com/koreader/koreader/blob/c4f9c60742409c8edb2f13c50bbb7ab8d9997218/platform/kindle/koreader.sh#L201-L216
# check if we are supposed to shut down the Amazon framework
eips 19 29 -h "Stopping Kindle Framework..."
# The framework job sends a SIGTERM on stop, trap it so we don't get killed if we were launched by KUAL
trap "" TERM
stop lab126_gui
# NOTE: Let the framework teardown finish, so we don't start before the black screen...
usleep 1250000
# And remove the trap like a ninja now!
trap - TERM

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

PRINTC_Y=22
printc "Configured URL:"
printc "${BASE_URL}"

PRINTC_Y=25; printc "Starting..."

sleep 1

# TODO: Read RSSI via iwconfig or cat /proc/net/wireless
RSSI="0"
USER_AGENT="trmnl-display/0.1.1"

printlog "Determine hostname from URL..."
BASE_HOST=$(echo $BASE_URL | sed -E 's/^https?:\/\/([^/:]+).*$/\1/')

# Temporary folder to hold downloaded files
printlog "Check/prepare folder for temporary files..."
TMP_DIR="/tmp/trmnl-kindle"
mkdir -p "$TMP_DIR"

printlog "Read MAC address..."
MAC_ADDRESS=$(cat /sys/class/net/wlan0/address)

# Size of the PNG in *pixels*
printlog "Read display dimensions..."
PNG_WIDTH=$(get_kindle_height)
PNG_HEIGHT=$(get_kindle_width)
ROTATION=90

# https://github.com/Ectalite/trmnl-kindle/blob/f67d9cddd460afa02f658c254e9dcc4573b712e4/zip_example/TRMNL.sh#L66
printlog "Disabling screensaver..."
lipc-set-prop com.lab126.powerd preventScreenSaver 1

# https://github.com/koreader/koreader/blob/c4f9c60742409c8edb2f13c50bbb7ab8d9997218/platform/kindle/koreader.sh#L284-L287
# List of services we stop in order to reclaim a tiny sliver of RAM...
TOGGLED_SERVICES="framework stored webreader kfxreader kfxview todo tmd lipcd rcm archive scanner otav3 otaupd"
for job in ${TOGGLED_SERVICES}; do
  printlog "Stopping server ${job}..."
  stop "${job}"
done

FROZEN_PROCESSES="awesome cvm volumd"
for job in ${FROZEN_PROCESSES}; do
  printlog "Freezing process ${job}..."
  killall -STOP ${job}
done

# https://github.com/Ectalite/trmnl-kindle/blob/f67d9cddd460afa02f658c254e9dcc4573b712e4/zip_example/TRMNL.sh#L65
printlog "Setting CPU governor to powersave"
echo "powersave" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor

# Flash logo box
eips -s w=386,h=216 -f -x 336 -y 288

printlog "All done. Starting main loop..."

# Clear screen
eips -c

IMPRESSIONS=0
while : ; do
  # Indicator that we're alive
  eips -d l=00,w=8,h=8 -x 0 -y 0

  # Make sure WiFi is ready
  # https://github.com/Ectalite/trmnl-kindle/blob/f67d9cddd460afa02f658c254e9dcc4573b712e4/zip_example/wait-for-wifi.sh
  ping_count=0
  while : ; do
    ping -c 1 "$BASE_HOST" >/dev/null 2>&1
    [ $? -eq 0 ] && break 1
    eips -s w=2,h=2 -f -x 0 -y 0
    ping_count=$((ping_count + 1))
    if [ $ping_count -gt 10 ]; then
      PRINTC_Y=29; printc -h "${BASE_HOST} not pingable. Retrying..."
    fi
    usleep 500000
  done

  # Fetch JSON metadata
  # Required header values: https://github.com/usetrmnl/byos_laravel/blob/6bc74b2c5c95ba9771704ff4c74e8696619872f7/routes/api.php#L16-L43
  BATTERY_PERCENT=$(cat /sys/class/power_supply/bd71827_bat/capacity)
  BATTERY_VOLTAGE=$(cat /sys/class/power_supply/bd71827_bat/voltage_now)
  BATTERY_VOLTAGE=$((BATTERY_VOLTAGE / 1000000))
  RESPONSE="$(
    curl -L -s \
      -H "id: $MAC_ADDRESS" \
      -H "access-token: $API_KEY" \
      -H "battery-percent: $BATTERY_PERCENT" \
      -H "battery_voltage: $BATTERY_VOLTAGE" \
      -H "png-width: $PNG_WIDTH" \
      -H "png-height: $PNG_HEIGHT" \
      -H "png-rotation: $ROTATION" \
      -H "rssi: $RSSI" \
      -H "fw-version: 99.9.9" \
      -A "$USER_AGENT" \
      "${BASE_URL}/api/display"
  )"

  # If no response, display error and retry
  if [ -z "$RESPONSE" ]; then
    PRINTC_Y=22; printc -h "ERROR: Empty answer from server. Retry in 60s..."
    sleep 60
    continue
  fi

  eips -d l=00,w=8,h=8 -x 0 -y 12

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

  eips -d l=00,w=8,h=8 -x 0 -y 24

  FLASH_FLAG=""
  if [ "$IMPRESSIONS" -gt "$DEGAUSS_AFTER"]; then
    FLASH_FLAG="-f"
    IMPRESSIONS=0
  fi

  # Display the downloaded image
  eips -g "$IMAGE_PATH" $FLASH_FLAG

  IMPRESSIONS=$((IMPRESSIONS + 1))

  # Downloading + rendering takes about 3 seconds
  REFRESH_RATE=$((REFRESH_RATE - GRACE_PERIOD - 3))

  # Grace period, mostly to have a chance to SSH and abort during development
  sleep $GRACE_PERIOD

  # Deep sleep
  # https://github.com/Ectalite/trmnl-kindle/blob/f67d9cddd460afa02f658c254e9dcc4573b712e4/zip_example/TRMNL.sh#L202-L204
  echo 0 > /sys/class/rtc/rtc1/wakealarm
  echo "+${REFRESH_RATE}" > /sys/class/rtc/rtc1/wakealarm
  echo "mem" > /sys/power/state
  #sleep "$REFRESH_RATE"
done
