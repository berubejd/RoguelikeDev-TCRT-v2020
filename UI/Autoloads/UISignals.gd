extends Node

# Enable control of the main UI from the pause menu
#warning-ignore:unused_signal
signal display_ui
#warning-ignore:unused_signal
signal hide_ui

# Enable popups
#warning-ignore:unused_signal
signal display_pausemenu

# Update UI
#warning-ignore:unused_signal
signal update_health(current_health, max_health)
#warning-ignore:unused_signal
signal update_experience(level, current_xp, needed_xp)
#warning-ignore:unused_signal
signal update_gold(gold)

# Toggle display of exit arrow
#warning-ignore:unused_signal
signal display_exit_arrow
#warning-ignore:unused_signal
signal hide_exit_arrow

# Display messages
#warning-ignore:unused_signal
signal display_message(message)
