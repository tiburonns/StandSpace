# StandSpace 0.4.3 — Plan de aceptación física

**Español** · [English](TESTING.md)

Esta lista valida la experiencia actual de `main` en un iPhone/iPad real. CI demuestra que el proyecto compila y que pasan las pruebas deterministas de layout e idioma; no puede demostrar permisos, ergonomía táctil, comportamiento multimedia, cambios de orientación, pantalla encendida ni persistencia durante uso prolongado.

## Entorno de prueba

Registra modelo de iPhone/iPad, versión de iOS/iPadOS, versión de Xcode, equipo de firma, commit probado y si el dispositivo usa pantalla OLED.

## 1. Instalación y arranque

1. Abre `StandSpace.xcodeproj`.
2. Selecciona el target StandSpace y un iPhone o iPad físico.
3. Selecciona un equipo de firma válido y ejecuta.
4. Fuerza el cierre y vuelve a abrir.

Aprobado: la app instala, abre sin cerrarse, restaura el Space seleccionado y no pierde el dashboard al relanzar.

## 2. Layout vertical y horizontal

1. Prueba vertical y horizontal.
2. Gira repetidamente mientras están visibles Dashboard, Reloj, Fotos, Música y Focus.
3. Comprueba áreas seguras, controles sin recorte y ausencia de módulos superpuestos.
4. En iPad, repite en al menos dos tamaños de ventana si hay multitarea disponible.

Aprobado: cada orientación sigue siendo utilizable, los módulos permanecen dentro del canvas y el paginador horizontal vuelve a una página válida tras girar.

## 3. Edición y cuadrícula

1. Entra en modo edición.
2. Arrastra cada tipo de módulo disponible.
3. Redimensiona usando varios tamaños compatibles.
4. Duplica y elimina módulos.
5. Abre el inspector y cambia estilo, título, texto, tamaño vertical y tamaño horizontal.
6. Relanza la app.

Aprobado: el snapping es predecible, no se pueden elegir tamaños incompatibles, los cambios persisten y los layouts vertical/horizontal siguen independientes.

## 4. Spaces y persistencia

1. Personaliza Escritorio, Noche, Trabajo y Cocina con módulos y fondos claramente distintos.
2. Cambia entre los cuatro Spaces.
3. Relanza.
4. Cambia mantener pantalla encendida, atenuación automática, protección OLED y fondo.
5. Relanza de nuevo.

Aprobado: cada Space conserva contenido/layout/fondo y las preferencias globales persisten sin sobrescribir otro Space.

## 5. Temporizador y suspensión

1. Inicia un temporizador.
2. Bloquea el dispositivo o sal de StandSpace durante varios minutos.
3. Regresa antes y después de la hora objetivo.
4. Pausa, reanuda y restablece.

Aprobado: el tiempo restante se calcula a partir de la fecha final guardada y no se pierde tiempo mientras la app está suspendida.

## 6. Calendario

1. Agrega el módulo Calendario.
2. Niega acceso una vez y comprueba un estado útil.
3. Concede acceso completo a eventos desde Ajustes.
4. Crea un evento próximo y vuelve a StandSpace.

Aprobado: el módulo maneja estados denegado/concedido sin cierres y muestra el siguiente evento elegible cuando obtiene permiso.

## 7. Batería, almacenamiento e información del dispositivo

1. Observa Batería cargando y desconectada.
2. Cambia el idioma entre Sistema, English y Español.
3. Compara Almacenamiento e Información del dispositivo con Ajustes de iOS cuando sea posible.

Aprobado: el estado de batería respeta el idioma elegido, los valores se actualizan de forma razonable y la información no disponible usa un placeholder claro.

## 8. Fotos

1. Abre la página horizontal Fotos.
2. Concede acceso y selecciona una imagen grande.
3. Relanza y gira repetidamente.
4. Sustituye la imagen seleccionada.

Aprobado: la foto persiste, carga sin picos visibles de memoria/cierres y la interfaz sigue respondiendo al girar.

## 9. Música

1. Abre Música sin reproducción activa.
2. Concede acceso a la biblioteca cuando se solicite.
3. Reproduce una canción de Apple Music/biblioteca.
4. Prueba reproducir/pausar, anterior y siguiente.
5. Envía StandSpace a segundo plano y regresa.

Aprobado: portada/metadatos se actualizan cuando están disponibles, los controles operan la cola activa donde iOS lo permita y los estados sin permiso/no disponibles se manejan correctamente.

## 10. Idioma y textos de permisos

1. Prueba Sistema, English y Español.
2. Revisa Ajustes, galería, inspector, estados de batería, aviso de migración, flujo de permiso de Calendario y flujo de Música.
3. Relanza después de cada idioma explícito.

Aprobado: los textos propios de la app siguen el idioma seleccionado y las descripciones de permisos del sistema aparecen en el idioma elegido por el sistema.

## 11. Cuidado OLED y pantalla encendida

1. Activa mantener pantalla encendida y deja el dashboard sin tocar para confirmar que permanece activo.
2. Activa atenuación automática y observa la transición por inactividad.
3. Activa protección OLED y observa el desplazamiento sutil de píxeles durante varios minutos.
4. Desactiva cada opción y confirma que su comportamiento se detiene.

Aprobado: cada opción afecta únicamente el comportamiento previsto y la app restaura el temporizador normal del sistema al abandonar la experiencia.

## 12. Seguridad de migración

Usa un fixture de desarrollo o una compilación anterior si está disponible.

1. Abre datos creados por un esquema anterior compatible y verifica reparación/migración.
2. Presenta datos marcados con un esquema más nuevo que el soportado por la app.

Aprobado: datos antiguos compatibles cargan; datos futuros desconocidos muestran el aviso localizado y no se sobrescriben silenciosamente hasta que el usuario restablece los Spaces explícitamente.

## Gate de release

StandSpace solo puede considerarse validado físicamente después de aprobar las secciones aplicables anteriores en hardware real. Compilar en simulador y tener CI en verde es necesario, pero no sustituye este gate.
