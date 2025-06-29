#!/bin/bash
# --- Configuration ---
# Directory containing your wallpapers (CHANGE THIS TO YOURS)
WALLPAPER_DIR="$HOME/Pictures/wallpapers/"
# Monitor identifier (e.g., eDP-1, DP-1).
# Leave empty ("") for swww to apply to all/focused output.
# Check 'swww query' for output names if you want to be specific.
MONITOR="eDP-1" # Example: Set your monitor if needed, or leave ""
# Rofi theme configuration file
ROFI_CONFIG="$HOME/.config/rofi/wallconf.rasi"

# swww specific configuration
SWWW_TRANSITION_TYPE="grow"    # e.g., simple, fade, left, right, top, bottom, wipe, grow, outer, any
SWWW_TRANSITION_DURATION="0.7" # Duration of the transition in seconds
# Alternatively, you can use FPS and Step for finer control:
# SWWW_TRANSITION_FPS="60"
# SWWW_TRANSITION_STEP="20" # Step duration in milliseconds (20ms * 50 steps = 1s at 60 FPS for a 1s duration)
# If SWWW_TRANSITION_DURATION is set, FPS and Step might be ignored or calculated.
# Refer to 'swww --help' for details on transition options.
# --- End Configuration ---

# Check if wallpaper directory exists
if [ ! -d "$WALLPAPER_DIR" ]; then
  rofi -theme "$ROFI_CONFIG" -e "Wallpaper directory not found: $WALLPAPER_DIR"
  exit 1
fi

# Check if rofi config exists, create fallback if not
if [ ! -f "$ROFI_CONFIG" ]; then
  echo "Warning: Rofi config file not found at $ROFI_CONFIG"
  echo "Using default rofi theme..."
  ROFI_CONFIG="" # This will make Rofi use its default theme if the file is not found
fi

# Find image files using null-terminated strings to handle filenames with spaces
# Added -mindepth 1 to avoid matching the directory itself
mapfile -d '' IMAGE_FILES_NULL < <(find "$WALLPAPER_DIR" -mindepth 1 -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.gif" -o -iname "*.webp" -o -iname "*.avif" \) -print0)

if [ ${#IMAGE_FILES_NULL[@]} -eq 0 ]; then
  if [ -n "$ROFI_CONFIG" ]; then
    rofi -theme "$ROFI_CONFIG" -e "No image files found in $WALLPAPER_DIR"
  else
    rofi -e "No image files found in $WALLPAPER_DIR"
  fi
  exit 1
fi

# Build associative array and rofi options
declare -A WALLPAPER_FULL_PATHS
ROFI_OPTIONS_STRING=""

for img_file_null in "${IMAGE_FILES_NULL[@]}"; do
  img_file="${img_file_null%$'\0'}"
  if [ -n "$img_file" ]; then
    base_name=$(basename "$img_file")
    WALLPAPER_FULL_PATHS["$base_name"]="$img_file"
    ROFI_OPTIONS_STRING+="$base_name\n"
  fi
done

# Remove trailing newline
ROFI_OPTIONS_STRING=${ROFI_OPTIONS_STRING%\\n}

# Show rofi menu for wallpaper selection
if [ -n "$ROFI_CONFIG" ]; then
  SELECTED_BASENAME=$(echo -e "$ROFI_OPTIONS_STRING" | rofi -theme "$ROFI_CONFIG" -dmenu -p "Select Wallpaper" -i)
else
  SELECTED_BASENAME=$(echo -e "$ROFI_OPTIONS_STRING" | rofi -dmenu -p "Select Wallpaper" -i)
fi

# Exit if user cancelled selection
if [ -z "$SELECTED_BASENAME" ]; then
  echo "No wallpaper selected. Exiting."
  exit 0
fi

# Get full path of selected wallpaper
SELECTED_WALLPAPER_PATH="${WALLPAPER_FULL_PATHS["$SELECTED_BASENAME"]}"

if [ -z "$SELECTED_WALLPAPER_PATH" ] || [ ! -f "$SELECTED_WALLPAPER_PATH" ]; then
  rofi_error_msg="Error: Could not find the full path for '$SELECTED_BASENAME' or file does not exist."
  if [ -n "$ROFI_CONFIG" ]; then
    rofi -theme "$ROFI_CONFIG" -e "$rofi_error_msg"
  else
    rofi -e "$rofi_error_msg"
  fi
  exit 1
fi

# --- Start of swww wallpaper setting logic ---
echo "Selected wallpaper: $SELECTED_WALLPAPER_PATH"

SWWW_COMMAND_ARRAY=(swww img) # Use an array for command and arguments for safety

# Monitor handling for swww
if [ -n "$MONITOR" ]; then
  SWWW_COMMAND_ARRAY+=(--outputs "$MONITOR")
fi

# Transition handling for swww
if [ -n "$SWWW_TRANSITION_TYPE" ]; then
  SWWW_COMMAND_ARRAY+=(--transition-type "$SWWW_TRANSITION_TYPE")
fi

# Prefer duration if set, otherwise use FPS/Step
if [ -n "$SWWW_TRANSITION_DURATION" ]; then
  SWWW_COMMAND_ARRAY+=(--transition-duration "$SWWW_TRANSITION_DURATION")
elif [ -n "$SWWW_TRANSITION_FPS" ] && [ -n "$SWWW_TRANSITION_STEP" ]; then
  SWWW_COMMAND_ARRAY+=(--transition-fps "$SWWW_TRANSITION_FPS")
  SWWW_COMMAND_ARRAY+=(--transition-step "$SWWW_TRANSITION_STEP")
fi

SWWW_COMMAND_ARRAY+=("$SELECTED_WALLPAPER_PATH")

echo "Executing: ${SWWW_COMMAND_ARRAY[*]}"
swww_output=$("${SWWW_COMMAND_ARRAY[@]}" 2>&1) # Capture output and error
exit_status=$?

if [ $exit_status -eq 0 ]; then
  echo "Wallpaper set successfully using swww."
  if [ -n "$swww_output" ]; then
    echo "swww output: $swww_output"
  fi
else
  rofi_error_message="Error setting '$SELECTED_BASENAME' with swww. Check terminal."
  echo "Error setting wallpaper using swww. Exit status: $exit_status"
  echo "swww command was: ${SWWW_COMMAND_ARRAY[*]}"
  echo "swww output: $swww_output"

  if [ -n "$ROFI_CONFIG" ]; then
    rofi -theme "$ROFI_CONFIG" -e "$rofi_error_message"
  else
    rofi -e "$rofi_error_message"
  fi
  exit 1
fi
# --- End of swww wallpaper setting logic ---

exit 0
