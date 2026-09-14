set -u
OUT="${1:-$HOME/surface-pro6-report-$(date +%Y%m%d-%H%M%S).txt}"
exec > >(tee "$OUT") 2>&1
section() { printf '\n\n===== %s =====\n' "$1"; }
run() { printf '\n$ %s\n' "$*"; "$@" || true; }
section "IDENTITY"; run date -Is; run uname -a; run cat /etc/os-release; run systemd-detect-virt; run cat /sys/devices/virtual/dmi/id/product_name; run cat /sys/devices/virtual/dmi/id/product_sku
section "KERNEL CMDLINE AND SLEEP"; run cat /proc/cmdline; run cat /sys/power/mem_sleep; run cat /sys/power/state; run sh -c 'grep -H . /sys/power/{disk,wakeup_count} 2>/dev/null || true'
section "S0IX / LOW POWER IDLE"; run sh -c 'grep -H . /sys/devices/system/cpu/cpuidle/low_power_idle_* 2>/dev/null || true'; run sh -c 'grep -H . /sys/kernel/debug/pmc_core/*residency* /sys/kernel/debug/pmc_core/*slp_s0* 2>/dev/null || true'; run sh -c 'journalctl -b --no-pager | grep -Ei "suspend|resume|s2idle|S0ix|low.power.idle" | tail -n 200'
section "PCI"; run lspci -nnk
section "USB"; run lsusb -t; run lsusb
section "INPUT / TYPE COVER / TOUCHPAD / BUTTONS"; run sh -c 'cat /proc/bus/input/devices'; run libinput list-devices; run sh -c 'grep -Ei -A6 -B2 "Surface|Type Cover|Keyboard|Touchpad|Power Button|Volume" /proc/bus/input/devices || true'
section "TABLET MODE / SWITCHES"; run sh -c 'grep -Ei -A8 -B2 "SW:|switch|tablet|cover" /proc/bus/input/devices || true'; run sh -c 'for e in /sys/class/input/event*; do [ -e "$e/device/capabilities/sw" ] && printf "%s: " "$e" && cat "$e/device/capabilities/sw"; done'
section "IPTS / TOUCH / PEN"; run systemctl status 'iptsd@*' --no-pager; run journalctl -b -u 'iptsd@*' --no-pager; run sh -c 'lsmod | grep -Ei "ipts|surface|hid"'; run sh -c 'journalctl -b -k --no-pager | grep -Ei "ipts|touch|stylus|pen" | tail -n 200'
section "WACOM"; run libwacom-list-local-devices
section "IIO SENSORS / AUTOROTATE"; run monitor-sensor --version; run sh -c 'find /sys/bus/iio/devices -maxdepth 2 -type f -name name -print -exec cat {} \; 2>/dev/null'; run systemctl status iio-sensor-proxy --no-pager; run sh -c 'busctl --system introspect net.hadess.SensorProxy /net/hadess/SensorProxy 2>/dev/null || true'
section "GRAPHICS"; run drm_info; run glxinfo -B; run vulkaninfo --summary
section "DISPLAY BRIGHTNESS"; run brightnessctl -l; run brightnessctl info
section "NETWORK / WIFI"; run nmcli general; run nmcli device; run iw dev; run rfkill list; run sh -c 'lspci -nnk | grep -Ei -A4 "network|wireless" || true'
section "BLUETOOTH"; run systemctl status bluetooth --no-pager; run bluetoothctl show; run bluetoothctl devices; run sh -c 'journalctl -b -u bluetooth --no-pager | tail -n 200'
section "AUDIO / SPEAKERS / MICROPHONES"; run wpctl status; run pactl info; run pactl list short sinks; run pactl list short sources; run sh -c 'arecord -l 2>/dev/null || true'; run sh -c 'aplay -l 2>/dev/null || true'
section "CAMERAS / IPU3 / LIBCAMERA"; run v4l2-ctl --list-devices; run sh -c 'ls -la /dev/video* /dev/media* 2>/dev/null'; run cam -l; run sh -c 'media-ctl -p 2>/dev/null || true'; run sh -c 'journalctl -b -k --no-pager | grep -Ei "ipu3|cio2|ov5693|ov7251|ov8865|dw9719|camera|v4l2|media" | tail -n 300'
section "BATTERY"; run upower -e; run sh -c 'for d in /sys/class/power_supply/*; do echo ---$d; grep -H . "$d"/{type,status,capacity,energy_full,energy_full_design,charge_full,charge_full_design,cycle_count} 2>/dev/null; done'; run acpi -V
section "PERFORMANCE MODES / PLATFORM PROFILE"; run sh -c 'find /sys -type f \( -name platform_profile -o -name platform_profile_choices \) -print -exec cat {} \; 2>/dev/null | head -n 100'; run surface status
section "THERMAL"; run sensors; run systemctl status thermald --no-pager
section "STORAGE / SD / USB"; run lsblk -o NAME,TYPE,SIZE,FSTYPE,MODEL,TRAN,MOUNTPOINTS; run nvme list; run sh -c 'journalctl -b -k --no-pager | grep -Ei "mmc|sdhci|sd card|usb-storage|uas" | tail -n 200'
section "SURFACE CONTROL"; run surface status
section "FAILED SERVICES"; run systemctl --failed --no-pager
section "KERNEL WARNINGS"; run journalctl -b -k -p warning --no-pager
section "SURFACE FEATURE KERNEL LOG"; run sh -c 'journalctl -b -k --no-pager | grep -Ei "surface|ipts|ithc|ipu3|cio2|ov5693|ov7251|ov8865|dw9719|camera|mwifiex|ath10k|sensor|suspend|resume|s2idle|tablet|button|battery"'
section "MANUAL FEATURE MATRIX CHECKLIST"; printf '%s\n' 'Verify interactively: [ ] Type Cover keyboard  [ ] touchpad/click/gestures  [ ] attach/detach tablet mode  [ ] touchscreen/multitouch  [ ] pen hover/touch/buttons  [ ] Wi-Fi  [ ] Bluetooth  [ ] speakers  [ ] microphone  [ ] Power/Volume buttons  [ ] microSD  [ ] brightness  [ ] autorotation/sensors  [ ] battery/charging  [ ] front camera  [ ] rear camera  [ ] performance modes  [ ] suspend/resume by Type Cover  [ ] suspend/resume by Power button  [ ] S0ix residency increases across suspend'; printf '%s\n' 'Hibernate is intentionally disabled in this Live ISO and must not be counted as an SP6 hardware failure.'; printf '%s\n' 'Power note: paired BLE devices such as Surface Pen may affect low-power behavior; repeat S0ix/suspend testing with relevant BLE devices unpaired/disabled if residency or drain looks abnormal.'
section "SUMMARY"; run inxi -Fazy
printf '\nReport saved to: %s\n' "$OUT"
