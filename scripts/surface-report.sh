set -u
OUT="${1:-$HOME/surface-pro6-report-$(date +%Y%m%d-%H%M%S).txt}"
exec > >(tee "$OUT") 2>&1
section() { printf '\n\n===== %s =====\n' "$1"; }
run() { printf '\n$ %s\n' "$*"; "$@" || true; }
section "IDENTITY"; run date -Is; run uname -a; run cat /etc/os-release; run systemd-detect-virt; run cat /sys/devices/virtual/dmi/id/product_name; run cat /sys/devices/virtual/dmi/id/product_sku
section "KERNEL CMDLINE AND SLEEP"; run cat /proc/cmdline; run cat /sys/power/mem_sleep; run cat /sys/power/state
section "PCI"; run lspci -nnk
section "USB"; run lsusb -t; run lsusb
section "INPUT DEVICES"; run sh -c 'cat /proc/bus/input/devices'; run libinput list-devices
section "IPTS"; run systemctl status 'iptsd@*' --no-pager; run journalctl -b -u 'iptsd@*' --no-pager; run sh -c 'lsmod | grep -Ei "ipts|surface|hid"'
section "WACOM"; run libwacom-list-local-devices
section "IIO SENSORS"; run monitor-sensor --version; run sh -c 'find /sys/bus/iio/devices -maxdepth 2 -type f -name name -print -exec cat {} \; 2>/dev/null'; run systemctl status iio-sensor-proxy --no-pager
section "GRAPHICS"; run drm_info; run glxinfo -B; run vulkaninfo --summary
section "DISPLAY BRIGHTNESS"; run brightnessctl -l; run brightnessctl info
section "NETWORK"; run nmcli general; run nmcli device; run iw dev; run rfkill list
section "BLUETOOTH"; run systemctl status bluetooth --no-pager; run bluetoothctl show
section "AUDIO"; run wpctl status; run pactl info; run pactl list short sinks; run pactl list short sources
section "CAMERAS"; run v4l2-ctl --list-devices; run sh -c 'ls -la /dev/video* /dev/media* 2>/dev/null'; run cam -l
section "BATTERY"; run upower -e; run sh -c 'for d in /sys/class/power_supply/*; do echo ---$d; grep -H . "$d"/{type,status,capacity,energy_full,energy_full_design,charge_full,charge_full_design,cycle_count} 2>/dev/null; done'; run acpi -V
section "THERMAL"; run sensors; run systemctl status thermald --no-pager
section "STORAGE"; run lsblk -o NAME,TYPE,SIZE,FSTYPE,MODEL,TRAN,MOUNTPOINTS; run nvme list
section "SURFACE CONTROL"; run surface status
section "FAILED SERVICES"; run systemctl --failed --no-pager
section "KERNEL WARNINGS"; run journalctl -b -k -p warning --no-pager
section "SURFACE/IPTS/CAMERA KERNEL LOG"; run sh -c 'journalctl -b -k --no-pager | grep -Ei "surface|ipts|ithc|ipu3|cio2|ov5693|ov7251|ov8865|dw9719|camera|mwifiex|ath10k|sensor"'
section "SUMMARY"; run inxi -Fazy
printf '\nReport saved to: %s\n' "$OUT"
