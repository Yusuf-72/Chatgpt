# IMPERIUM — 3D Android build

IMPERIUM is a Godot 4.4.1 3D historical strategy-game work in progress.

## Current playable systems
- Third-person ruler avatar in a furnished palace hall.
- Walkable palace corridor and enclosed courtyard with a fountain, trees and lanterns.
- Ambassador NPC with interactive diplomatic choices.
- Separate 3D strategic map with selectable province tiles, city markers, army tokens and treasury actions.
- 3D battlefield scene with unit selection, formations, advance, charge, hold, retreat and siege orders.
- Campaign date, treasury, army recruitment, diplomacy, succession choice and local save data.
- Offline historical campaign catalogue with 8 selectable realms and 12 ruler entries; ruler selection filters by realm and limits start year to the listed reign window.
- Succession now follows successor links in the offline ruler catalogue; older save files are migrated to ruler IDs.
- Android touch movement and interaction controls.

## Controls
- Move: WASD / on-screen directional controls.
- Look: mouse / drag on the right side of the screen.
- Sprint: Shift / on-screen sprint.
- Interact with ambassador: E / interaction button.
- Open 2D province panel: M.
- Open 3D battlefield: B.
- Use the **3D Dünya Haritası** button for the 3D strategic map.

## Build
Open this folder as a Godot 4.4.1 project. Android export preset is configured for arm64-v8a. The GitHub Actions workflow `.github/workflows/godot-android.yml` exports a debug APK artifact.

## Scope and limitations
This is a playable 3D alpha, not the fully finished historical sandbox originally envisioned. The strategic map currently contains a small 1444 Anatolia/Balkans province set; the map is stylized and not a complete globe. The expanded ruler catalogue does not yet imply that every realm has its own matching map, economy simulation, or historical scenario. The ruler and ambassador are procedural placeholder characters, and the palace/battlefield use primitive 3D geometry. Historical coverage, all-era/all-civilization data, detailed character animation, advanced tactical AI, and production-quality art remain future development work.
