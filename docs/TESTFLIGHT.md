# StandSpace TestFlight preflight / Preflight de TestFlight

## English

StandSpace 0.4.3 (build 9) must pass the Release Simulator and unsigned iPhoneOS builds in CI before it is treated as a TestFlight candidate.

### Before Archive

1. Complete `docs/TESTING.md`.
2. Test Calendar and Apple Music permission flows in English and Spanish.
3. Test portrait and landscape on iPhone and iPad.
4. Verify persistence after force-quit/relaunch and after device rotation.
5. Verify timer restoration after background suspension.
6. Verify selected photos reload without excessive memory growth.
7. Verify OLED dim/pixel-shift options during a long-running session.
8. Confirm every module remains readable at one larger Dynamic Type size.

### Archive

1. Pull the protected `main` branch after CI is green.
2. Open `StandSpace.xcodeproj`.
3. Select your paid Apple Developer Team.
4. Confirm `com.tiburonns.StandSpace`.
5. Product > Archive.
6. Organizer > Validate App.
7. Upload through App Store Connect and begin with Internal Testing.

Compilation does not certify calendar/music behavior, screen-awake behavior, OLED behavior, or long-duration persistence. Those remain physical-device gates.

---

## Español

StandSpace 0.4.3 (build 9) debe pasar en CI la compilación Release para Simulator y la compilación iPhoneOS sin firma antes de considerarse candidato para TestFlight.

### Antes del Archive

1. Completa `docs/TESTING.es.md`.
2. Prueba permisos de Calendario y Apple Music en inglés y español.
3. Prueba vertical y horizontal en iPhone y iPad.
4. Verifica persistencia tras cerrar/reabrir y rotar el dispositivo.
5. Verifica restauración del temporizador después de suspensión.
6. Verifica carga de fotos sin crecimiento excesivo de memoria.
7. Prueba atenuación OLED/pixel shift en una sesión prolongada.
8. Comprueba los módulos con un tamaño mayor de Dynamic Type.

### Archive

1. Actualiza el `main` protegido una vez que CI esté verde.
2. Abre `StandSpace.xcodeproj`.
3. Selecciona tu Team de Apple Developer de pago.
4. Confirma `com.tiburonns.StandSpace`.
5. Product > Archive.
6. Organizer > Validate App.
7. Sube a App Store Connect y comienza con Internal Testing.

La compilación no certifica Calendario/Música, keep-screen-awake, OLED ni persistencia prolongada; esos siguen siendo gates físicos.
