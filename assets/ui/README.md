# Cryptonomics Tycoon — UI Kit v1.0

Foundation only; no runtime changes. Shared assets for portrait 1080 × 1920 Godot UI.

## Visual standards
- Cartoon Tycoon 2.5D; light from upper left; layered gold borders and emerald panels.
- Palette: #075440, #087F69, #E9AD32, #FFE5B4, #65CF23, #D83C32, #159BD7, #F9F5E7, #092E26.
- Panels: main, finance, metrics, operations, selection, warning; scalable nine-patch textures.
- Buttons: primary, upgrade, management, information, danger; normal, pressed, selected, disabled states. Explain disabled actions.
- Icons: transparent, consistent lighting, no embedded text; reuse existing suitable assets.
- Planned fonts: Vazirmatn, Fredoka, Roboto Mono; verify licenses and include notices before integration. Persian RTL; financial values LTR.
- Shared tabs, cards, progress bars, navigation and short feedback animations.

## Implementation order
1. Folder foundation (this commit).
2. Panels; buttons; icons; fonts.
3. Shared theme and animation helpers.
4. Independent UI showcase and device testing.
5. Approved integration into existing scenes.

Preserve existing scenes, save data, gameplay and navigation until integration is approved. Placeholder directories do not contain finished assets.
