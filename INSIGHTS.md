Insights
========

Deep Sleep
----------
When putting the device to deep sleep (`echo "mem" > /sys/power/state`), make sure to have 1 or
2 seconds of `sleep` before and after the hibernation to allow for outstanding data to flush.
Otherwise, the device seems to freeze after 10-30 minutes and reboot.

Power Usage
-----------
In case of pulling a new image every 30 seconds, there doesn't seem to be much of a difference
between keeping the device active until the next pull or putting it to deep sleep and then
reconnecting to WiFi after wakeup. In both cases, a fully charged battery will last about 36 hours.
I.e. the reconnection seems to pull the same amount of energy you're saving in the 20 seconds deep
sleep period. In some cases even more. But this might make bigger difference with longer update
intervals.

WiFi Toggle
-----------
There are multiple ways to toggle WiFi:

1. `stop wifid` / `start wifid`
2. `lipc-set-prop com.lab126.wifid enable 0` / `1`
3. `lipc-set-prop com.lab126.cmd wirelessEnable 0` / `1`

Doing lots of `stop wifid` / `start wifid` seems to have deleted the saved WiFi networks at some
point for me. After reboot, I had to manually type the password so the Kindle was able to connect
to my WiFi again.

It appears, that leaving the cpu_governor at `ondemand` (instead of setting it to `powersave`)
fixes this issue.

Lua libraries
-------------
The Kindle Paperwhite 10th gen comes with a few Lua libraries in `/var/lib/lua/`.

* cjson
  * _NAME
  * _VERSION
  * decode
  * decode_invalid_numbers
  * decode_max_depth
  * encode
  * encode_invalid_numbers
  * encode_keep_buffer
  * encode_max_depth
  * encode_number_precision
  * encode_sparse_array
  * new
  * null

* devcap_lua (also: `devcap.lua` with convenience functions)
  * devcap_get_int
  * devcap_get_string
  * devcap_is_available
  * is_low_ram_device
  * is_low_varlocal_device

* liblab126IGL
  * FAST_MODE
    * AB
    * HL
    * KB
    * PZ
  * FLASH_MODE
    * FULL
    * GLFAST
    * GL_FAST_FULL
    * GL
    * GL_SLOW_FULL
    * GC
    * XOR
    * GCFAST
    * TWOPASS
    * A2
    * PARTIAL_THEN_FULL
    * FAST_FULL
    * WIPE
    * SLOW_FULL
    * REAGL
    * FAST_WHITE
    * REAGLD
    * SLOW_WHITE
    * NONE
    * DU
    * SLOW_WHITE2
  * ROTATION
    * DOWN
    * LEFT
    * RIGHT
    * UP
  * SENSITIVITY_MODE
    * reader
    * image_heavy
    * disabled
    * flashnext
    * midgrays
    * flashfastpages
    * flashpages
    * dialog
  * apply_halftone
  * bitwiseOr
  * bitwiseAnd
  * debug_params
  * define_wipe_curve
  * deinit
  * display_damage_notify
  * display_disable_fastmode
  * display_fastmode_rect
  * display_flash_rect
  * display_pause
  * display_resume
  * display_set_sensitivity
  * display_unpaused_rect
  * get_reader_reagl_config
  * init
  * orientation_set
  * sensitivity_direction
  * set_epdc_grayscale_mode
  * set_grip_suppression
  * signal_user_action

* liblipclua
  * ERROR
  * init
  * run_event_loop
  * set_error_handler

* libpixmanlua
  * region

* libluasqlite3-loader (see `sqlite3.lua` in that folder for examples)

* llog_c (also: `llog.lua` with convenience functions)
  * LLOG_FACILITY
  * LLOG_LEVEL
  * LLOG_MSG_ID
  * SYSLOG
  * check_log_level
  * init
  * log
