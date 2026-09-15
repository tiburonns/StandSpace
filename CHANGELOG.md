# Changelog

## 0.4.0 — Spaces, swipe pages & OLED care

- Added four persistent Spaces: Desk, Night, Work, and Kitchen.
- Existing dashboards migrate into the Desk Space instead of being discarded.
- Each Space keeps its own modules, background, portrait layout, and landscape layout.
- Added a landscape page carousel: Dashboard, Clock, Photos, Music, and Focus.
- Added a persistent user-selected photo page using PhotosPicker.
- Added an Apple Music page with artwork, now-playing metadata, and basic transport controls when media-library access is granted.
- Added auto-dim after inactivity, with a shorter delay in Night Space.
- Added subtle OLED pixel shifting that moves the interface by only a few points over time.
- Added quick Space switching in the main toolbar and landscape controls.
- Added Auto-dim and OLED Protection toggles to Settings.
- Added independent portrait and landscape module-size editing.


## 0.3.1 — Landscape StandBy

- Added a first-class landscape mode with 6, 8, or 10 adaptive grid columns.
- Portrait and landscape now persist independent module positions and sizes.
- Added landscape layout presets: Adaptive, Duo, Quad, and Focus.
- Added compact immersive controls that stay out of the way in landscape.
- Added quick Night and OLED background controls for bedside use.
- Landscape editing supports drag, snapping, resizing, duplication, and module configuration without changing the portrait layout.
- Default modules now include a dedicated landscape arrangement.


## 0.3.0 — Natural Canvas & useful modules

- Added explicit grid positions so modules can be placed in specific cells and gaps can remain empty.
- Added live drag-to-resize directly from the grid with snapping and size feedback.
- Added Timer, Calendar, Storage, Device Info, and Day Progress modules.
- Added calendar permission handling without prompting from the module gallery.
- Updated the default dashboard to showcase more than clock/date/battery.
- Added CI build validation for future Xcode changes.

All notable StandSpace changes are tracked here.

## 0.2.1 — Xcode build fix

- Fixed a non-exhaustive `ModuleSize` switch in `ClockModuleView` introduced when 0.2 added larger module sizes.
- Made clock sizing derive from grid spans so future size additions do not silently break compilation.

## 0.2.0 — Canvas foundations

- Added direct edit mode entered from the toolbar or by long-pressing a module.
- Added drag-to-reorder with grid snapping and haptic feedback.
- Added a resize handle with module-specific supported sizes.
- Added quick duplicate, delete, and inspector controls on the selected module.
- Added a visual module gallery with search, categories, size selection, style selection, and live preview.
- Expanded module sizes from four presets to eight grid spans up to 4×2.
- Added a tinted module appearance and additional board backgrounds.
- Added adaptive 4/6/8-column layouts for iPhone and iPad widths.
- Preserved v0.1 raw values and persistence keys so existing saved dashboards continue to decode.
- Documented the free-product principle: no paywalls or Pro-only core modules.

## 0.1.0 — Initial prototype

- SwiftUI dashboard for iPhone and iPad.
- Clock, date, battery, and custom text modules.
- Multiple module styles and four initial sizes.
- Local persistence, background selection, and keep-screen-awake option.
