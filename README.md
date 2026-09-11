# StandSpace

**Your space. Your information.**

StandSpace is a free, customizable modular dashboard for iPhone and iPad. It takes the glanceable idea behind a standby display and turns it into a flexible canvas: users decide what is visible, how large it is, how it looks, and how the space is arranged.

> Current milestone: **0.2 — Canvas foundations**

## Product principles

- **Free by design.** No paywalls, no “Pro” module tier, and no intentionally crippled core experience.
- **Useful before flashy.** Every module should earn its space on the screen.
- **Direct manipulation.** Editing should feel physical: long-press, move, resize, duplicate, remove.
- **Private by default.** Prefer on-device data and private Apple platform storage when sync is introduced.
- **Native first.** SwiftUI, WidgetKit, App Intents, ActivityKit, and Apple platform conventions before custom hacks.
- **Accessible and adaptable.** iPhone and iPad layouts should adapt rather than merely scale.

## What works now

- Landscape-friendly SwiftUI dashboard.
- Long-press or toolbar entry into direct edit mode.
- Drag modules to reorder them on a snapping grid.
- Resize modules from the lower-right handle.
- Duplicate, delete, or open a module inspector directly on the canvas.
- Visual module gallery with search, categories, preview, size, and style selection.
- Eight grid spans from 1×1 through 4×2, filtered per module.
- Adaptive 4-, 6-, and 8-column canvas behavior based on available width.
- Clock, date, device battery, and custom text modules.
- Glass, minimal, solid, outline, gradient, and tinted module styles.
- Black, Midnight, Night Red, OLED, Aurora, and Warm backgrounds.
- Local persistence and optional keep-screen-awake behavior.
- Compatibility path for dashboards saved by the 0.1 prototype.

## Next milestones

### 0.3 — Module engine + first useful pack

- Formal module/provider protocol so modules can be added without growing a giant switch statement.
- Weather.
- Calendar / next event.
- Reminders.
- Media / Now Playing where platform APIs allow it.
- Photos.
- Timer / Pomodoro.

### 0.4 — Spaces and themes

- Multiple saved Spaces such as Desk, Night, Kitchen, Work, and Car.
- Full theme engine: typography, spacing, corner radius, accent, module material, and background.
- OLED protection options such as subtle pixel shifting and low-light presets.

### 0.5 — Apple ecosystem integration

- App Intents and Shortcuts actions.
- WidgetKit / Apple StandBy-compatible widgets where supported.
- Live Activities for temporary ongoing modules.
- iCloud sync for Spaces and preferences.
- Import/export of shareable StandSpace layouts.

See CHANGELOG.md for the current release notes.

## Requirements

- Xcode with an iOS 17+ SDK
- iOS / iPadOS 17.0+
- An Apple Developer team for installation on a physical device

## Run

1. Clone this repository.
2. Open StandSpace.xcodeproj.
3. Select the StandSpace target.
4. Open **Signing & Capabilities** and select your development team.
5. Verify the bundle identifier com.tiburonns.StandSpace or change it for your signing account.
6. Build and run on an iPhone or iPad.

---

# StandSpace — Español

**Tu espacio. Tu información.**

StandSpace es un dashboard modular gratuito y personalizable para iPhone y iPad. Toma la idea de una pantalla de consulta rápida y la convierte en un lienzo flexible: el usuario decide qué se muestra, cuánto espacio ocupa, cómo se ve y cómo se organiza.

> Hito actual: **0.2 — Bases del Canvas**

## Principios del producto

- **Gratis por diseño.** Sin paywalls, sin módulos esenciales “Pro” y sin limitar funciones para venderlas después.
- **Útil antes que llamativo.** Cada módulo debe justificar el espacio que ocupa.
- **Manipulación directa.** Mantener pulsado, mover, redimensionar, duplicar y eliminar.
- **Privacidad por defecto.** Priorizaremos datos en el dispositivo y almacenamiento privado del ecosistema Apple cuando llegue la sincronización.
- **Nativo primero.** SwiftUI y las APIs oficiales de Apple antes de soluciones frágiles.
- **Adaptable.** iPhone y iPad tendrán distribuciones pensadas para cada tamaño, no sólo una interfaz estirada.

## Ya funciona

- Dashboard SwiftUI pensado para horizontal.
- Modo de edición mediante pulsación larga o el botón Editar.
- Arrastrar para reordenar sobre una cuadrícula con snapping.
- Redimensionar desde la esquina inferior derecha.
- Duplicar, eliminar y abrir el inspector directamente sobre un módulo.
- Galería visual con búsqueda, categorías, vista previa, tamaño y estilo.
- Ocho tamaños de cuadrícula desde 1×1 hasta 4×2, según lo que admita cada módulo.
- Canvas adaptativo de 4, 6 u 8 columnas según el ancho disponible.
- Reloj, fecha, batería del dispositivo y texto personalizado.
- Estilos cristal, minimalista, sólido, contorno, gradiente y tinte.
- Fondos Negro, Medianoche, Rojo nocturno, OLED, Aurora y Cálido.
- Persistencia local y opción de mantener la pantalla encendida.
- Compatibilidad con configuraciones guardadas por el prototipo 0.1.

## Lo siguiente

La versión 0.3 formalizará el **Module Engine** y comenzará el primer paquete de módulos realmente útiles: clima, calendario, recordatorios, multimedia, fotos y temporizadores. Después construiremos Spaces/perfiles, temas avanzados, App Intents, widgets, Live Activities, iCloud e importación/exportación.

Consulta CHANGELOG.md para ver los cambios de cada versión.
