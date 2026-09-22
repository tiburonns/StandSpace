# StandSpace 0.4.3 — Physical Acceptance Plan

[Español](TESTING.es.md) · **English**

This checklist validates the current `main` experience on real iPhone/iPad hardware. CI proves the project builds and deterministic layout/language logic passes; it cannot prove permissions, touch ergonomics, media behavior, orientation changes, screen-awake behavior, or long-running persistence.

## Test environment

Record the iPhone/iPad model, iOS/iPadOS version, Xcode version, signing team, tested commit, and whether the device has an OLED display.

## 1. Install and launch

1. Open `StandSpace.xcodeproj`.
2. Select the StandSpace target and a physical iPhone or iPad.
3. Select a valid signing team and run.
4. Relaunch after force-quitting.

Pass: the app installs, launches without a crash, restores the selected Space, and does not lose the dashboard after relaunch.

## 2. Portrait and landscape layout

1. Test portrait and landscape.
2. Rotate repeatedly while the Dashboard, Clock, Photos, Music, and Focus landscape pages are visible.
3. Verify safe-area handling, no clipped controls, and no module overlap.
4. On iPad, repeat in at least two window sizes if multitasking is available.

Pass: every orientation remains usable, modules stay inside the canvas, and the horizontal pager returns to a valid page after rotation.

## 3. Editing and grid behavior

1. Enter edit mode.
2. Drag every supported module type.
3. Resize modules through several supported spans.
4. Duplicate and delete modules.
5. Open the inspector and change style, title, text, portrait size, and landscape size.
6. Relaunch the app.

Pass: snapping is predictable, unsupported sizes cannot be selected, edits persist, and portrait/landscape layouts remain independent.

## 4. Spaces and persistence

1. Customize Desk, Night, Work, and Kitchen with visibly different modules and backgrounds.
2. Switch among all four Spaces.
3. Relaunch.
4. Change settings such as keep-screen-awake, auto-dim, OLED protection, and background.
5. Relaunch again.

Pass: each Space keeps its own content/layout/background and global preferences persist without overwriting another Space.

## 5. Timer and suspension

1. Start a timer.
2. Lock the device or leave StandSpace for several minutes.
3. Return before and after the target end time.
4. Pause, resume, and reset it.

Pass: remaining time is calculated from the stored end date instead of losing time while suspended.

## 6. Calendar

1. Add the Calendar module.
2. Deny access once and verify a useful denied state.
3. Grant full event access in Settings.
4. Create a near-future event and return to StandSpace.

Pass: the module handles denied/granted states without a crash and shows the next eligible event after permission is granted.

## 7. Battery, storage, and device information

1. Observe Battery while charging and unplugged.
2. Change app language between System, English, and Español.
3. Compare Storage and Device Info with values visible in iOS Settings where practical.

Pass: battery state text follows the selected language, values update plausibly, and unavailable information degrades to a clear placeholder.

## 8. Photos

1. Open the landscape Photos page.
2. Grant photo access and select a large image.
3. Relaunch and rotate repeatedly.
4. Replace the selected image.

Pass: the selected image persists, loads without a visible memory spike/crash, and remains responsive during orientation changes.

## 9. Music

1. Open the Music page with nothing playing.
2. Grant media-library access when requested.
3. Play an Apple Music/library track.
4. Test play/pause, previous, and next controls.
5. Background and foreground StandSpace.

Pass: artwork/metadata update when available, controls operate the active queue where iOS permits it, and denied/unavailable media access is handled cleanly.

## 10. Language and permission copy

1. Test System, English, and Español.
2. Review Settings, gallery, module inspector, battery states, migration warning, Calendar permission flow, and Music permission flow.
3. Relaunch after each explicit language selection.

Pass: app-owned copy follows the selected language and system permission descriptions appear in the OS-selected language.

## 11. OLED care and screen awake

1. Enable keep-screen-awake and leave the dashboard untouched long enough to verify the display stays awake.
2. Enable auto-dim and observe the inactivity transition.
3. Enable OLED protection and observe subtle pixel shifting over several minutes.
4. Disable each option and confirm behavior stops.

Pass: the options change only the intended behavior and the app restores the normal idle timer when leaving the experience.

## 12. Migration safety

Use a development fixture or an older build if available.

1. Open data created by an older supported schema and verify it is repaired/migrated.
2. Present data marked with a schema newer than the app supports.

Pass: supported older data loads; newer unknown data triggers the localized warning and is not silently overwritten until the user explicitly resets Spaces.

## Release gate

StandSpace can be called physically validated only after the applicable sections above pass on real hardware. Simulator builds and CI success are necessary but do not replace this gate.
