# StandSpace

**Your space. Your information.**

StandSpace is a free, customizable modular dashboard for iPhone and iPad. It takes the glanceable idea behind a standby display and turns it into a flexible canvas: users decide what is visible, how large it is, how it looks, and how the space is arranged.

> Released milestone: **0.4.0 — Spaces, swipe pages & OLED care**  
> Current `main`: **0.4.3 (build 9)** — complete EN/ES/System model localization, localized permissions, reliability, persistence, timer, photo-memory, and CI hardening.

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
- Clock, date, device battery, custom text, Timer, Calendar, Storage, Device Info, and Day Progress modules.
- Persistent Spaces for Desk, Night, Work, and Kitchen, each with independent modules, backgrounds, portrait layout, and landscape layout.
- First-class landscape StandBy experience with Dashboard, Clock, Photos, Music, and Focus swipe pages.
- User-selected photo display and an Apple Music page with artwork, now-playing metadata, and basic transport controls when access is granted.
- Glass, minimal, solid, outline, gradient, and tinted module styles.
- Black, Midnight, Night Red, OLED, Aurora, and Warm backgrounds.
- Auto-dim and subtle OLED pixel shifting options.
- Local persistence, independent portrait/landscape module sizing, and optional keep-screen-awake behavior.
- Compatibility and migration paths for dashboards saved by earlier StandSpace versions.
- Versioned Space persistence, suspension-safe Timer state, downsampled photo loading, and lower-frequency/event-driven Music refresh for better reliability and efficiency.
- CI checks the privacy manifest, runs deterministic grid/packing tests, and builds the iOS target on every push/PR.

## Next milestone

### 0.5 — Apple ecosystem integration

- App Intents and Shortcuts actions.
- WidgetKit / Apple StandBy-compatible widgets where supported.
- Live Activities for temporary ongoing modules.
- iCloud sync for Spaces and preferences.
- Import/export of shareable StandSpace layouts.
- Continue expanding the module-provider architecture and hardening persistence/migrations.

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

> Hito distribuido: **0.4.0 — Spaces, páginas deslizables y cuidado OLED**  
> `main` actual: **0.4.3 (build 9)** — localización completa EN/ES/Sistema de modelos, permisos localizados, fiabilidad, persistencia, temporizador, memoria de fotos y CI.

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
- Reloj, fecha, batería del dispositivo, texto personalizado, Temporizador, Calendario, Almacenamiento, Información del dispositivo y Progreso del día.
- Spaces persistentes para Escritorio, Noche, Trabajo y Cocina, cada uno con módulos, fondo y distribuciones independientes en vertical y horizontal.
- Experiencia StandBy horizontal con páginas deslizables de Dashboard, Reloj, Fotos, Música y Focus.
- Página de foto elegida por el usuario y página de Apple Music con portada, información de reproducción y controles básicos cuando se concede acceso.
- Estilos cristal, minimalista, sólido, contorno, gradiente y tinte.
- Fondos Negro, Medianoche, Rojo nocturno, OLED, Aurora y Cálido.
- Atenuación automática y desplazamiento sutil de píxeles para protección OLED.
- Persistencia local, tamaños independientes por orientación y opción de mantener la pantalla encendida.
- Compatibilidad y migración para configuraciones guardadas por versiones anteriores de StandSpace.
- Persistencia versionada de Spaces, Temporizador resistente a suspensión, carga de fotos con downsampling y actualización de Música basada en eventos con respaldo de baja frecuencia para mejorar fiabilidad y eficiencia.
- El CI valida el manifiesto de privacidad, ejecuta pruebas deterministas de cuadrícula/packing y compila el target iOS en cada push/PR.

## Lo siguiente

La versión 0.5 se enfocará en la integración con el ecosistema Apple: App Intents y Atajos, widgets compatibles con WidgetKit/StandBy donde sea posible, Live Activities para módulos temporales, sincronización de Spaces y preferencias mediante iCloud, e importación/exportación de diseños compartibles. También continuará la expansión de la arquitectura de módulos y el endurecimiento de persistencia y migraciones.

Consulta CHANGELOG.md para ver los cambios de cada versión.
