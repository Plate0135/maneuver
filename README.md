Maneuver

Maneuver is an Ashita v4 addon for HorizonXI designed for the Puppetmaster job.

It tracks your active Maneuvers, displays their current overload value, shows remaining Maneuver duration, and provides an easy-to-read overload gauge.

Author: Plate
Platform: HorizonXI
Client: Ashita v4
Job: Puppetmaster

Features
Tracks your own Puppetmaster Maneuvers.
Ignores Maneuvers used by other Puppetmasters.
Supports all eight Maneuver elements:
Fire
Ice
Wind
Earth
Thunder
Water
Light
Dark
Displays active Maneuver stack count: x1, x2, or x3.
Displays remaining Maneuver duration.
Automatically removes an element when its final Maneuver expires.
Automatically hides the entire HUD when no Maneuvers are active.
Resizable HUD.
Persistent user settings.
Adjustable background opacity.
Optional timers, headers, backgrounds, and auto-hide behavior.
Designed specifically for HorizonXI's level 75 era.
Overload Gauge

The overload gauge is not a literal 0–100% overload chance meter.

On HorizonXI, the value reported for a Maneuver represents its actual overload percentage. Maneuver converts that value into a larger visual gauge to make overload risk easier to see at a glance.

Gauge Scale

30% actual overload chance is treated as 100% on the visual gauge.

The conversion is:

Display Gauge = Actual Overload % / 30 × 100

Examples:

Actual Overload	Gauge Display
0%	0%
3%	10%
6%	20%
9%	30%
12%	40%
15%	50%
18%	60%
21%	70%
24%	80%
27%	90%
30%	100%

So if the addon shows:

Actual: 15%
Gauge:  50%

your actual overload value is still 15%. The 50% simply means you are halfway to the addon's 30% = full gauge reference point.

Values at or above 30% are displayed as a full gauge.

Installation

Download the latest release and place the maneuver folder into your Ashita addons directory.

Your folder should look similar to:

HorizonXI/
└── Game/
    └── addons/
        └── maneuver/
            ├── maneuver.lua
            ├── README.md
            └── assets/

Then start HorizonXI and enter:

/addon load maneuver

To reload the addon:

/addon reload maneuver

To unload it:

/addon unload maneuver
Commands

The main command is:

/maneuver
Show / Hide

Toggle the HUD:

/maneuver

Show it:

/maneuver show

Hide it:

/maneuver hide
Help

Display the available commands:

/maneuver help
Clear

Clear the currently tracked Maneuver information:

/maneuver clear
Reset

Restore the HUD and settings to their defaults:

/maneuver reset

This can also be useful if the HUD is accidentally moved somewhere off-screen.

Save Settings

Save the current addon settings:

/maneuver save
Reload Settings

Reload your saved settings:

/maneuver reload
Timer Settings

Enable Maneuver timers:

/maneuver timer on

Disable Maneuver timers:

/maneuver timer off

When enabled, the timer displays how long the next active stack of that element has remaining.

When the final Maneuver of that element expires, the row is removed.

Auto-Hide

Enable automatic hiding:

/maneuver autohide on

Disable automatic hiding:

/maneuver autohide off

With auto-hide enabled, the addon completely disappears whenever you have no active Maneuvers.

Headers

Enable column headers:

/maneuver headers on

Disable column headers:

/maneuver headers off
Row Background

Enable the solid background behind active Maneuver rows:

/maneuver background on

Disable it:

/maneuver background off
Background Opacity

Change the opacity of the row background:

/maneuver opacity 80

Replace 80 with your desired opacity value.

For example:

/maneuver opacity 100

Fully opaque.

/maneuver opacity 50

50% opacity.

/maneuver opacity 20

Very transparent.

Puppetmaster-Only Mode

By default, Maneuver is intended to operate while Puppetmaster is your main job.

Enable PUP-only behavior:

/maneuver puponly on

Disable it:

/maneuver puponly off
How Player Detection Works

Maneuver does not require you to enter your character name or manually configure a player ID.

The addon obtains the current player's server ID dynamically and uses incoming action information to verify that the Maneuver was actually performed by you.

This is important when multiple Puppetmasters are nearby because another player's Maneuvers should not update your tracker.

Maneuver Stacks

Maneuver supports the normal Puppetmaster limit of three active Maneuvers.

Examples:

Fire x1
Fire x2
Fire x3

Different elements can also be tracked simultaneously:

Fire x2
Wind x1

When three Maneuvers are already active and another Maneuver is used, the addon updates its active Maneuver tracking accordingly.

Supported Elements
Element	Supported
Fire	✅
Ice	✅
Wind	✅
Earth	✅
Thunder	✅
Water	✅
Light	✅
Dark	✅
Compatibility

Maneuver was developed for:

HorizonXI
Ashita v4
Puppetmaster
Level 75 / Treasures of Aht Urhgan-era HorizonXI gameplay

It is not currently intended as a retail FFXI addon.

Troubleshooting

If the addon is behaving unexpectedly, first try:

/maneuver clear

Then:

/addon reload maneuver

If the HUD position or settings become unusable:

/maneuver reset

For additional troubleshooting information:

/maneuver debug

Debug mode is primarily intended for diagnosing packet or Maneuver detection issues.

Testing

If you are testing Maneuver on a new character, useful things to verify include:

Fire, Ice, Wind, Earth, Thunder, Water, Light, and Dark Maneuvers are recognized correctly.
x1, x2, and x3 stacks display correctly.
Maneuver timers expire correctly.
Rows disappear when their final Maneuver expires.
The HUD disappears when no Maneuvers remain and auto-hide is enabled.
Resizing works correctly.
Settings survive an addon reload.
Another Puppetmaster's Maneuvers do not modify your HUD.

Testing with two Puppetmasters standing near one another is especially helpful for confirming player filtering.

Credits

Maneuver was created by Plate for the HorizonXI Puppetmaster community.

Feedback, bug reports, and testing from other HorizonXI Puppetmasters are welcome.

Disclaimer

Maneuver is a third-party community addon and is not affiliated with or endorsed by HorizonXI, Square Enix, or the Final Fantasy XI development team.
