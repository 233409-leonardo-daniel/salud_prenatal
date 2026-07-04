# Prompt para Stitch — Vista Web: Reportes de Foro (Administrador)

Copia y pega el siguiente texto tal cual en Stitch (stitch.withgoogle.com):

---

Diseña, en formato de aplicación web de escritorio (no móvil, ancho ~1440px, con barra lateral de navegación), una única pantalla para el rol "Administrador(a)" de la app "Salud Prenatal": la gestión de publicaciones reportadas en el foro/comunidad de la app.

**Sistema de diseño a respetar (mismo de la app):**
- Color primario: magenta/rosa fuerte #D22E7E para acentos, botones principales y elementos activos.
- Fondo general: blanco roto #F9F9FB. Tarjetas y paneles: blancos #FFFFFF, esquinas muy redondeadas (~16-20px), sombra suave, sin bordes duros.
- Tipografía: títulos en serif elegante (gris oscuro #1A1A1E), texto de cuerpo en sans-serif gris (#757579).
- Badges de estado con colores semánticos suaves: rojo (#D32F2F sobre #FFEBEA) para "reportado/alto riesgo", ámbar (#E65100 sobre #FFF4E5) para "en revisión", verde (#00796B sobre #E0F2F1) para "resuelto/aprobado".
- Botones tipo píldora (bordes muy redondeados ~24-30px): magenta sólido para acciones principales, contorno o fondo rojo pálido para acciones destructivas.
- Avatares circulares con iniciales sobre fondo pastel cuando no hay foto.

**Layout general:**
- Barra lateral izquierda fija con el logo "Salud Prenatal" arriba y navegación del admin (Dashboard, Usuarios, Reportes de Foro [activo/resaltado en píldora magenta], Perfil).
- Barra superior con título de la sección "Reportes de Foro" y buscador rápido a la derecha.

**Contenido de la pantalla (lo esencial que se pide):**

1. **Tarjetas de resumen** en la parte superior: "Reportes Pendientes", "Publicaciones Eliminadas (mes)", "Reportes Resueltos".

2. **Filtros**: chips u tabs horizontales — "Pendientes", "Resueltos", "Todos" — y un selector de ordenamiento (más recientes / más reportados).

3. **Tabla o lista de tarjetas de reportes**, cada fila/tarjeta debe mostrar:
   - Avatar + alias del autor de la publicación reportada, con su rol (Paciente / Doctor(a)).
   - Extracto del contenido de la publicación (2-3 líneas de texto, truncado con "...").
   - Motivo del reporte (badge rojo, ej. "Contenido inapropiado", "Información médica falsa", "Acoso").
   - Quién reportó (alias) y fecha del reporte.
   - Contador si la misma publicación fue reportada por varias personas (ej. "Reportado 3 veces").
   - Tres acciones alineadas a la derecha: botón secundario "Ver publicación completa" (abre detalle), botón "Descartar reporte" (neutro, mantiene la publicación), botón destructivo "Eliminar publicación" (rojo).

4. **Panel o modal de detalle** al hacer clic en una fila: muestra la publicación completa con su contenido íntegro, la lista de todos los reportes recibidos sobre ella (motivo + quién + fecha por cada uno), y al pie los mismos botones "Descartar Reporte(s)" y "Eliminar Publicación".

5. **Modal de confirmación** para eliminar: tarjeta centrada, ícono de advertencia, texto breve indicando que la publicación y sus comentarios se eliminarán permanentemente, botón "Eliminar" en rojo sólido y "Cancelar" neutro.

Genera el diseño de alta fidelidad, listo para exportar como imagen o prototipo navegable, mostrando la tabla con al menos 4-5 reportes de ejemplo con datos variados (distintos motivos, distintos roles de autor, uno con múltiples reportes).
