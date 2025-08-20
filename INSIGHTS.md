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
sleep period. But this might make a difference with longer update intervals.

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
