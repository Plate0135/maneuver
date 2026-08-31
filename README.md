# Maneuver

**Maneuver** is a configurable real-time Lua HUD addon for **HorizonXI** and **Ashita v4** that tracks Puppetmaster maneuvers, remaining duration, stack count, and server-reported automaton overload values.

The addon was built to make Puppetmaster maneuver management easier to read during gameplay while correctly isolating maneuver actions performed by the local player.

**Version:** 1.0.0  
**Author:** Plate  
**Platform:** HorizonXI  
**Client:** Ashita v4  
**Job:** Puppetmaster

## Features

- Tracks Fire, Ice, Wind, Earth, Thunder, Water, Light, and Dark Maneuver.
- Tracks active maneuver stacks (`x1`, `x2`, `x3`).
- Displays remaining maneuver duration.
- Displays the server-reported overload value for each active element.
- Converts overload values into an easy-to-read visual gauge.
- Uses the current player's dynamic server ID to ignore maneuvers performed by other players.
- Removes expired maneuver rows immediately after the final stack expires.
- Automatically hides the HUD when no maneuver information is active.
- Resizable HUD with persistent user settings.
- Configurable timers, headers, row backgrounds, opacity, auto-hide, and PUP-only behavior.
- Includes troubleshooting/debug output for tracking problems.

## Overload Gauge

The gauge is **not a literal 0–100% overload chance meter**. Maneuver uses **30% actual overload as the full-gauge reference point** so changes in overload risk are easier to see at a glance.

```text
Display Gauge = (Actual Overload % / 30) × 100
```

| Actual Overload | Gauge Display |
| ---: | ---: |
| 0% | 0% |
| 3% | 10% |
| 6% | 20% |
| 9% | 30% |
| 12% | 40% |
| 15% | 50% |
| 18% | 60% |
| 21% | 70% |
| 24% | 80% |
| 27% | 90% |
| 30%+ | 100% |

For example, if Maneuver reports `Actual: 15%` and the gauge is at `50%`, the actual overload value remains **15%**. The gauge is simply halfway to its 30% full-scale reference.

## Installation

1. Download the latest release.
2. Extract the `maneuver` folder into your Ashita addons directory.
3. Start HorizonXI.
4. Load the addon:

```text
/addon load maneuver
```

A typical installation looks like:

```text
HorizonXI/
└── Game/
    └── addons/
        └── maneuver/
            ├── maneuver.lua
            ├── README.txt
            ├── LICENSE.txt
            └── assets/
```

Reload after updating with `/addon reload maneuver`, or unload it with `/addon unload maneuver`.

## Commands

| Command | Description |
| --- | --- |
| `/maneuver` | Toggle the HUD. |
| `/maneuver show` | Show the HUD. |
| `/maneuver hide` | Hide the HUD. |
| `/maneuver help` | Display command help. |
| `/maneuver clear` | Clear currently tracked maneuver data. |
| `/maneuver reset` | Reset settings and HUD position/size. |
| `/maneuver save` | Save settings. |
| `/maneuver reload` | Reload saved settings. |
| `/maneuver timer on\|off` | Enable or disable maneuver timers. |
| `/maneuver autohide on\|off` | Enable or disable automatic hiding. |
| `/maneuver headers on\|off` | Show or hide column headers. |
| `/maneuver background on\|off` | Show or hide active-row backgrounds. |
| `/maneuver opacity 0-100` | Set row-background opacity. |
| `/maneuver puponly on\|off` | Restrict tracking/rendering to PUP main job. |
| `/maneuver debug` | Toggle troubleshooting information. |

`/overload` and `/pupoverload` are retained as compatibility aliases for older development builds.

## Default Settings

- Auto-hide: **On**
- Timers: **On**
- Headers: **On**
- Row background: **On**
- Row opacity: **94%**
- PUP-only mode: **On**

Settings are persisted through Ashita's settings system.

## How It Works

Maneuver is event-driven. It listens for relevant game actions and messages, verifies that the maneuver originated from the local player, maintains the active maneuver state, associates HorizonXI overload information with the appropriate element, and renders the current state through an ImGui HUD.

```text
HorizonXI action / message
          │
          ▼
 Local-player validation
          │
          ▼
 Maneuver state + timer tracking
          │
          ▼
 Overload-value matching
          │
          ▼
 Dynamic ImGui HUD rendering
```

The local player's server ID is obtained dynamically, so users do not need to edit the addon with a character name or manually configured player ID.

## Technical Highlights

This project demonstrates practical use of:

- Lua application development
- Event-driven programming
- Real-time state management
- Packet/action filtering
- ImGui UI rendering
- Persistent configuration
- Dynamic asset loading
- Input validation and command handling
- Debugging and iterative user-interface development
- Public release packaging and documentation

## Troubleshooting

If the HUD is off-screen or incorrectly sized, run:

```text
/maneuver reset
```

If icons do not appear, confirm that the `assets` directory is installed beside `maneuver.lua`.

For tracking problems, enable troubleshooting information with:

```text
/maneuver debug
```

## Compatibility

Maneuver was developed and tested for **HorizonXI's level-75 era environment using Ashita v4**. Behavior on other FFXI servers or clients is not guaranteed.

## Contributing & Testing

Bug reports and testing feedback are welcome. When reporting a tracking issue, include what maneuver was used, what the HUD displayed, and any useful output from `/maneuver debug`.

## License

Maneuver is released under the [MIT License](LICENSE).
