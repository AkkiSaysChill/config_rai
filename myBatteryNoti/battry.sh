#!/usr/bin/env zsh

# Battery threshold
THRESHOLD=20

# Get battery percentage (assumes BAT0, change if needed)
BATTERY_LEVEL=$(cat /sys/class/power_supply/BAT1/capacity)

# Charging state (can be 'Charging', 'Discharging', etc.)
BATTERY_STATUS=$(cat /sys/class/power_supply/BAT1/status)

# Send notification if battery is below threshold and discharging
if [ "$BATTERY_LEVEL" -le "$THRESHOLD" ] && [ "$BATTERY_STATUS" = "Discharging" ]; then
  notify-send -u critical "⚠️ Battery Low" "Battery is at ${BATTERY_LEVEL}%!"
fi
