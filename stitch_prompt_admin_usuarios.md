# Prompt para Stitch — Vista de Administrador(a) "Salud Prenatal"

Copia y pega el siguiente texto tal cual en Stitch (stitch.withgoogle.com):

---

Diseña las pantallas de un rol nuevo, "Administrador(a)", para la app móvil de salud "Salud Prenatal", manteniendo EXACTAMENTE el mismo lenguaje visual que el resto de la app (no es una app nueva, es un rol adicional dentro de la misma app).

**Sistema de diseño a respetar:**
- Color primario: magenta/rosa fuerte #D22E7E, usado en botones tipo píldora (bordes muy redondeados, ~30px), en el tab activo de la barra inferior y en acentos de texto.
- Fondo general: blanco roto / gris muy claro #F9F9FB. Tarjetas: blancas #FFFFFF, esquinas muy redondeadas (~20-24px), sombra suave, sin bordes duros.
- Fondo secundario suave: rosa pálido #FFF0F6 para tarjetas de contexto o destacadas.
- Tipografía: títulos en serif elegante en negro/gris oscuro (#1A1A1E), texto de cuerpo en sans-serif gris (#75757 9).
- Encabezado superior: avatar circular a la izquierda, saludo ("Buenos días, [Rol] [Nombre]") en dos líneas, campana de notificaciones circular a la derecha.
- Barra de navegación inferior: 4 iconos redondeados, el activo resaltado en píldora magenta con texto blanco, los inactivos en gris.
- Badges de estado con colores semánticos suaves: verde (#00796B sobre fondo #E0F2F1) para "activo/estable", ámbar (#E65100 sobre #FFF4E5) para "pendiente/medio riesgo", rojo (#D32F2F sobre #FFEBEA) para "alerta/alto riesgo/suspendido".
- Avatares con iniciales en círculo cuando no hay foto de perfil, con fondo pastel (rosa, durazno, etc.) según el rol.

**Contexto funcional (para que las pantallas tengan sentido, no son texto literal a poner en el diseño):**
El backend ya expone estos datos por usuario: nombre completo, correo, teléfono, rol (paciente, doctor, recepcionista, admin), estado activo/inactivo (booleano), foto de perfil, fecha de registro. El administrador puede ver el listado completo de usuarios del sistema, filtrarlos, entrar al detalle de uno, suspenderlo (desactivar su cuenta sin borrar sus datos) o eliminarlo definitivamente si incurrió en mal uso de la app.

**Pantallas a generar:**

1. **Dashboard del Administrador** (home al iniciar sesión como admin)
   - Encabezado con saludo "Buenos días, Admin [Nombre]" + campana de notificaciones.
   - Fila de tarjetas de métricas (mismo estilo que las tarjetas "Total Pacientes / Citas Hoy" del dashboard de doctora): "Total Usuarios", "Doctores Activos", "Pacientes Activas", "Cuentas Suspendidas" (esta última con borde/acento rojo como la tarjeta de alertas).
   - Sección "Actividad Reciente" o "Usuarios Reportados": lista de tarjetas compactas mostrando usuario + motivo breve + botón "Revisar".
   - Barra inferior con 4 tabs: Dashboard, Usuarios, Reportes, Perfil (tab "Dashboard" activo).

2. **Gestión de Usuarios** (pantalla principal solicitada)
   - Título "Usuarios del Sistema" con contador total (estilo "Mis Pacientes (24)").
   - Barra de búsqueda por nombre, correo o ID.
   - Chips de filtro horizontales por rol: Todos, Pacientes, Doctores, Recepcionistas, Admins.
   - Chips o toggle secundario de estado: Activos, Suspendidos.
   - Lista de tarjetas de usuario, cada una con: avatar/iniciales, nombre completo, badge de rol, badge de estado (Activo en verde / Suspendido en rojo), correo, fecha de registro.
   - En cada tarjeta, dos botones de acción: uno primario "Ver Detalle" (píldora magenta) y uno secundario de advertencia "Suspender" o "Reactivar" según el estado (píldora en tono rosa pálido u rojo pálido).
   - Paginación al pie, igual que en la lista de pacientes.

3. **Detalle de Usuario**
   - Encabezado con foto/avatar grande, nombre, rol y estado.
   - Datos de contacto (correo, teléfono, fecha de registro).
   - Si aplica: resumen de actividad o reportes recibidos sobre este usuario (lista simple de incidentes con fecha y descripción breve).
   - Dos botones de acción claramente diferenciados al pie: "Suspender Cuenta" (advertencia, color ámbar/rojo suave) y "Eliminar Usuario" (destructivo, texto rojo fuerte, con apariencia de que abre una confirmación).

4. **Modal de confirmación** para suspender/eliminar: tarjeta centrada, ícono de advertencia, texto breve explicando la consecuencia, botón destructivo rojo y botón "Cancelar" neutro.

Genera las 4 pantallas en formato mockup de app móvil (misma proporción que las pantallas de referencia, ~360x780), listas para exportar como imágenes de alta fidelidad.
