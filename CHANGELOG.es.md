# Registro de cambios de StandSpace

**[English](CHANGELOG.md) · Español**

## 0.4.3 (desarrollo) — localización completa y hardening

- Títulos/subtítulos persistentes localizados en Spaces, páginas/presets horizontal, categorías, módulos, estilos y fondos.
- Cobertura determinista para Sistema / English / Español, con fallback regional.
- Mantiene las mejoras de fiabilidad de 0.4.2.

## 0.4.2 — localización, fiabilidad y eficiencia

- Selector persistente Sistema / English / Español y permisos localizados.
- Privacy manifest para UserDefaults y espacio en disco mostrado al usuario.
- Timer persistente basado en fecha absoluta para sobrevivir suspensión/recreación de vistas.
- Persistencia de Spaces versionada con migración desde v1.
- Página Música basada en notificaciones de reproducción y polling de respaldo de baja frecuencia.
- Fotos elegidas por el usuario con downsampling.

## 0.4.0 — Spaces, páginas deslizables y cuidado OLED

- Cuatro Spaces persistentes: Escritorio, Noche, Trabajo y Cocina.
- Migración del dashboard previo hacia Escritorio.
- Módulos, fondo y layouts independientes por Space y orientación.
- Carrusel horizontal: Dashboard, Reloj, Fotos, Música y Focus.
- Página de foto elegida por el usuario.
- Página Apple Music con artwork, metadata y controles básicos.
- Auto-dim y desplazamiento sutil de píxeles OLED.
- Cambio rápido de Space y controles de protección OLED.

## 0.3.1 — Landscape StandBy

- Modo horizontal de primera clase con grid adaptativo.
- Posiciones/tamaños independientes por orientación.
- Presets Adaptive, Duo, Quad y Focus.
- Edición horizontal con drag, snapping, resize, duplicación y configuración.

## 0.3.0 — Canvas natural y módulos útiles

- Posiciones explícitas de grid.
- Drag-to-resize con snapping.
- Timer, Calendario, Almacenamiento, Información del dispositivo y Progreso del día.
- Manejo de permisos de calendario.
- CI de build.

## 0.2.1 — corrección de compilación

- Corrige el switch no exhaustivo de `ModuleSize` en `ClockModuleView`.

## 0.2.0 — bases del canvas

- Edición directa por toolbar/long-press.
- Drag-to-reorder, resize, duplicar, borrar e inspector.
- Galería visual con búsqueda/categorías/preview.
- Ocho tamaños hasta 4×2.
- Layouts adaptativos y persistencia compatible.

## 0.1.0 — prototipo inicial

- Dashboard SwiftUI para iPhone/iPad.
- Reloj, fecha, batería y texto.
- Estilos, tamaños, persistencia local, fondos y keep-screen-awake.
