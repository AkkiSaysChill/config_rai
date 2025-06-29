#!/usr/bin/zsh

# Get battery percentage (works for most systems, adjust if needed)
battery_level=$(cat /sys/class/power_supply/BAT*/capacity)
bat_stat=$(cat /sys/class/power_supply/BAT*/status)

# Read last notified level
last_notify_file="/tmp/.battery_notify_level"
last_level=""

if [ -f "$last_notify_file" ]; then
  last_level=$(cat "$last_notify_file")
fi

if [[ "$bat_stat" == "Discharging" ]]; then
  if ((battery_level <= 10)) && [[ "$last_level" != "10" ]]; then
    notify-send -u critical "Battery low" "Battery is at ${battery_level}%!"
    echo "10" >"$last_notify_file"
  elif ((battery_level <= 20)) && [[ "$last_level" != "20" ]]; then
    notify-send -u normal "Battery warning" "Battery is at ${battery_level}%"
    echo "20" >"$last_notify_file"
  elif ((battery_level > 20)); then
    # Reset when above threshold
    echo "" >"$last_notify_file"
  fi
fi
