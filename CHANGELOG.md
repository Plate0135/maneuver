# Changelog

All notable public changes to Maneuver are documented here.

## [1.0.0] - 2026-08-30

### Added
- Public-release settings system with persistent Ashita configuration.
- Commands for HUD visibility, timers, auto-hide, headers, row backgrounds, opacity, PUP-only mode, reset, save, reload, clear, help, and debugging.
- Dynamic local-player server ID detection.
- Tracking for all eight Puppetmaster maneuver elements.
- Active maneuver stack and remaining-duration tracking.
- Dynamic HUD rows that disappear when the final maneuver stack expires.
- Visual overload gauge using 30% actual overload as the full-scale reference.
- Public installation and usage documentation.

### Changed
- Addon renamed and packaged as `maneuver` for public release.
- HUD behavior and settings were generalized for use by other players.

### Compatibility
- `/overload` and `/pupoverload` remain available as aliases for older development builds.
