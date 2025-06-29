#!/bin/zsh
# Configuration
hidden_ws=9
state_file="/tmp/hyprland_window_positions.json"
lock_file="/tmp/hypr_minimized_state.lock"
timing_file="/tmp/hypr_minimize_timing.lock"

save_positions() {
    echo "Saving window positions..."
    hyprctl clients -j | jq '[.[] | select(.workspace.id != '$hidden_ws') | {address: .address, workspace: .workspace.id, title: .title, class: .class}]' >"$state_file"
    echo "Window positions saved to $state_file"
}

restore_positions() {
    # Check if we just executed hide command recently (within 2 seconds)
    if [ -f "$timing_file" ]; then
        last_hide=$(cat "$timing_file" 2>/dev/null || echo 0)
        current_time=$(date +%s)
        time_diff=$((current_time - last_hide))
        
        if [ $time_diff -lt 2 ]; then
            echo "Restore called too soon after hide ($time_diff seconds). Ignoring to prevent race condition."
            return
        fi
    fi

    if [ ! -f "$lock_file" ]; then
        echo "Nothing to restore. Skipping..."
        return
    fi

    rm -f "$lock_file"
    rm -f "$timing_file"  # Clean up timing file
    
    echo "Restoring window positions..."
    
    # Add small delay to ensure hyprland has processed the hide command completely
    sleep 0.2
    
    # Get current windows on hidden workspace
    current_windows=$(hyprctl clients -j | jq -r '.[] | select(.workspace.id == '$hidden_ws') | .address')
    
    # Read saved positions and restore
    while IFS= read -r window_data; do
        address=$(echo "$window_data" | jq -r '.address')
        original_ws=$(echo "$window_data" | jq -r '.workspace')
        title=$(echo "$window_data" | jq -r '.title')
        
        # Check if this window still exists on hidden workspace
        if echo "$current_windows" | grep -q "$address"; then
            echo "Restoring '$title' to workspace $original_ws"
            hyprctl dispatch movetoworkspacesilent "$original_ws,address:$address"
        else
            echo "Window '$title' ($address) no longer exists"
        fi
    done < <(jq -c '.[]' "$state_file")
    
    echo "Restoration complete"
}

hide_windows() {
    if [ -f "$lock_file" ]; then
        echo "Already minimized. Skipping..."
        return
    fi
    
    # Record the time when hide is executed
    date +%s > "$timing_file"
    
    save_positions
    touch "$lock_file"
    
    echo "Moving windows to hidden workspace $hidden_ws..."
    
    hyprctl clients -j | jq -r '.[] | select(.workspace.id != '$hidden_ws') | .address' | while read -r address; do
        if [ -n "$address" ]; then
            hyprctl dispatch movetoworkspacesilent "$hidden_ws,address:$address"
        fi
    done
    
    echo "All windows moved to workspace $hidden_ws"
}

# Main script logic
case "${1:-}" in
"save")
    save_positions
    ;;
"restore")
    restore_positions
    ;;
"hide")
    hide_windows
    ;;
*)
    echo "Usage: $0 {save|restore|hide}"
    echo ""
    echo "Commands:"
    echo "  save    - Save current window positions"
    echo "  restore - Restore windows to their saved positions"
    echo "  hide    - Save positions and move all windows to hidden workspace"
    echo ""
    echo "Example workflow:"
    echo "  $0 hide     # Hide all windows (automatically saves positions)"
    echo "  $0 restore  # Restore all windows to original positions"
    exit 1
    ;;
esac
