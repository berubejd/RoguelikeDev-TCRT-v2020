extends Node

# Define Slots Signals
#warning-ignore:unused_signal
signal display_tooltip(item)
#warning-ignore:unused_signal
signal hide_tooltip

# Define Item Pickup Signals
#warning-ignore:unused_signal
signal pickup_item(item)

# Define Initial and SaveGame Signals
#warning-ignore:unused_signal
signal init_inventory()
#warning-ignore:unused_signal
signal load_inventory()

# Define equipping signals
#warning-ignore:unused_signal
signal item_equipped(item)
#warning-ignore:unused_signal
signal item_removed(item)
