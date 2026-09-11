# StandSpace

**StandSpace** is a customizable modular standby dashboard for iPhone and iPad, inspired by the glanceable experience of Apple StandBy while giving users much more control over layout, module size, and visual style.

> Status: early prototype / Xcode starter.

## Current prototype

- SwiftUI dashboard optimized for landscape use.
- Modular cards with multiple sizes: `1×1`, `2×1`, `1×2`, and `2×2`.
- Module styles: glass, minimal, solid, outline, and gradient.
- Background presets: black, midnight, and night red.
- Clock, date, device battery, and custom text modules.
- Module editor for adding, deleting, resizing, styling, and reordering modules.
- Local persistence for dashboard configuration.
- Optional keep-screen-awake behavior while the dashboard is visible.
- iPhone and iPad support.

## Roadmap

The next milestone is a direct-manipulation editor similar to the iOS Home Screen: long-press to enter edit mode, drag modules on the canvas, resize them from handles, and add modules from a visual gallery.

Future modules may include weather, calendar, reminders, media controls, photos, timers, Shortcuts actions, Home data, connectivity, maps/ETA, activity, and world clocks.

## Requirements

- Xcode with an iOS 17+ SDK
- iOS / iPadOS 17.0+
- An Apple Developer team for installing on a physical device

## Run

1. Clone this repository.
2. Open `StandSpace.xcodeproj`.
3. Select the `StandSpace` target.
4. Open **Signing & Capabilities** and select your development team.
5. Verify the bundle identifier is `com.tiburonns.StandSpace`, or change it if needed for your signing account.
6. Build and run on an iPhone or iPad.

---

# StandSpace — Español

**StandSpace** es un dashboard modular y personalizable para iPhone y iPad, inspirado en la experiencia de consulta rápida de Apple StandBy, pero con mucho más control sobre la distribución, el tamaño de los módulos y su diseño visual.

> Estado: prototipo inicial / proyecto base para Xcode.

## Prototipo actual

- Dashboard SwiftUI optimizado para uso horizontal.
- Módulos con tamaños `1×1`, `2×1`, `1×2` y `2×2`.
- Estilos: cristal, minimalista, sólido, contorno y gradiente.
- Fondos: negro, medianoche y rojo nocturno.
- Módulos de reloj, fecha, batería del dispositivo y texto personalizado.
- Editor para agregar, eliminar, cambiar tamaño, estilo y orden de los módulos.
- Configuración persistente de forma local.
- Opción para mantener la pantalla encendida mientras se muestra el dashboard.
- Compatibilidad con iPhone y iPad.

## Próximo objetivo

El siguiente paso es crear un editor de manipulación directa similar a la pantalla de inicio de iOS: mantener pulsado para editar, arrastrar módulos sobre el lienzo, redimensionarlos mediante controles y agregar nuevos módulos desde una galería visual.

## Ejecutar

1. Clona este repositorio.
2. Abre `StandSpace.xcodeproj`.
3. Selecciona el target `StandSpace`.
4. Entra en **Signing & Capabilities** y selecciona tu equipo de desarrollo.
5. Verifica el identificador `com.tiburonns.StandSpace`.
6. Compila y ejecuta en un iPhone o iPad.
