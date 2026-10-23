# Sistema de Tickets en Chatbot - Documentación

## Descripción General

Se ha implementado un sistema completo de tickets que permite a los usuarios registrar solicitudes directamente desde el chatbot sin salir de la conversación.

## Características Implementadas

### 1. Base de Datos (PostgreSQL)

#### Tabla: `tickets`
```sql
CREATE TABLE tickets (
	id_ticket INTEGER PRIMARY KEY AUTO_INCREMENT,
	id_requestor INTEGER NOT NULL FOREIGN KEY (usuario),
	titulo VARCHAR(150) NOT NULL,
	descripcion VARCHAR(500) NOT NULL,
	estado ENUM ('Abierto', 'En Progreso', 'Cerrado', 'Cancelado') DEFAULT 'Abierto',
	id_asignee INTEGER NULLABLE FOREIGN KEY (usuario),
	fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

#### Tipos de Datos
- **Estado**: ENUM con valores válidos: Abierto, En Progreso, Cerrado, Cancelado

#### Procedimientos Almacenados
1. **spCrearTicket**: Crea un nuevo ticket con validaciones
2. **fnObtenerTicketsPorUsuario**: Obtiene tickets como requestor o asignee
3. **fnObtenerTicketPorId**: Obtiene detalles de un ticket específico
4. **spActualizarTicket**: Actualiza estado y asignee de un ticket

### 2. Modelos (C#)

#### API (MinisterioGosenAPI)
- **TicketModel**: Modelo base de datos
- **CrearTicketRequestModel**: Solicitud de creación
- **ActualizarTicketRequestModel**: Solicitud de actualización
- **TicketResponseModel**: Respuesta con información de usuarios

#### UI (MinisterioGosen)
- **TicketModel**: Modelo para presentación en la interfaz

### 3. Controladores

#### TicketsController (API)
Endpoint: `api/tickets`

**POST /CrearTicket**
- Crea un nuevo ticket
- Valida datos obligatorios
- Retorna: `{ idTicket, mensaje }`

**GET /ObtenerTicketsPorUsuario?idUsuario=**
- Obtiene tickets del usuario
- Retorna lista de tickets como requestor o asignee

**GET /ObtenerTicketPorId?idTicket=**
- Obtiene detalles de un ticket
- Retorna objeto TicketResponseModel

**PUT /ActualizarEstado**
- Actualiza estado y asignee
- Valida estado válido

#### ChatbotController (API - Extensión)
Endpoint: `api/chatbot`

**POST /RegistrarTicketDesdeChat**
- Registra ticket directamente desde el chatbot
- Validaciones completas
- Retorna: `{ idTicket, mensaje, estado }`

**POST /ValidarDatosTicket**
- Valida datos antes de envío
- Retorna: `{ valido, errores }`

### 4. Frontend (JavaScript)

#### chatbot.js - Nuevas Funciones

**iniciarRegistroTicket(idUsuario)**
- Inicia el flujo de registro de ticket
- Parámetro: ID del usuario

**mostrarFormularioTicket()**
- Muestra formulario con campos:
  - Título (máx 150 caracteres)
  - Descripción (máx 500 caracteres)
- Incluye contadores en tiempo real
- Botones: Enviar / Cancelar

**enviarTicket()**
- Valida datos antes de envío
- Realiza POST a `/api/ChatBot/RegistrarTicketDesdeChat`
- Maneja errores y muestra confirmación

**validarDatosTicket()**
- Valida campos obligatorios
- Valida límites de caracteres
- Retorna mensaje de error si hay inconsistencias

**mostrarOpcionesPostTicket()**
- Muestra confirmación visual
- Retorna al menú principal automáticamente

## Flujo de Uso

### Para el Usuario

1. **Accede al chatbot** en la aplicación
2. **Selecciona la opción** de "Registrar Ticket" (debe estar en el menú)
3. **Completa el formulario**:
   - Título: Resumen breve del problema (máx 150 caracteres)
   - Descripción: Detalles completos (máx 500 caracteres)
4. **Envía el ticket** mediante el botón "Enviar Ticket"
5. **Recibe confirmación** con número de ticket (#ID)
6. **Retorna automáticamente** al menú principal

### Para el Administrador

1. **Accede al endpoint**: `GET /api/tickets/ObtenerTicketsPorUsuario?idUsuario=X`
2. **Visualiza todos los tickets** del usuario
3. **Actualiza estado** mediante: `PUT /api/tickets/ActualizarEstado`
   - Parámetros: idTicket, estado, idAsignee (opcional)

## Validaciones

### Cliente (JavaScript)
- ✓ Título no vacío
- ✓ Título ≤ 150 caracteres
- ✓ Descripción no vacía
- ✓ Descripción ≤ 500 caracteres
- ✓ ID de usuario válido

### Servidor (API)
- ✓ Datos no nulos
- ✓ Campos obligatorios completos
- ✓ Usuario requestor existe
- ✓ Usuario asignee existe (si se proporciona)
- ✓ Estado válido (para actualización)

## Manejo de Errores

### Respuestas de Error

**Validación fallida (400)**
```json
{
	"mensaje": "Error al validar datos",
	"estado": "error",
	"detalle": "Descripción del error"
}
```

**Usuario no encontrado (404)**
```json
{
	"mensaje": "El usuario solicitante no existe",
	"estado": "error"
}
```

**Éxito (200)**
```json
{
	"idTicket": 123,
	"mensaje": "Ticket registrado exitosamente",
	"estado": "exito"
}
```

## Integración con Comandos del Chatbot

Para integrar la opción de tickets en el menú del chatbot, debe:

1. **Agregar opción en la tabla `chat_bot_opciones`** con respuesta que incluya instrucción
2. **Configurar JavaScript** para detectar cuando el usuario selecciona la opción de ticket
3. **Llamar a `iniciarRegistroTicket(idUsuario)`** con el ID del usuario autenticado

### Ejemplo de Integración JavaScript

```javascript
// En chatbot.js, cuando se detecte la opción de tickets
if (opcion.idOpcion === OPCION_TICKETS_ID) {
	iniciarRegistroTicket(usuarioActualId);
}
```

## Estados de Ticket

- **Abierto**: Ticket recién creado, pendiente de revisión
- **En Progreso**: Alguien está trabajando en la solicitud
- **Cerrado**: Solicitud resuelta
- **Cancelado**: Solicitud cancelada

## Campos Obligatorios vs Opcionales

| Campo | Obligatorio | Maxlen | Tipo |
|-------|------------|--------|------|
| id_requestor | Sí | - | INT |
| titulo | Sí | 150 | VARCHAR |
| descripcion | Sí | 500 | VARCHAR |
| estado | No | - | ENUM |
| id_asignee | No | - | INT |
| fecha_creacion | No | - | TIMESTAMP |

## Seguridad

- ✓ Validación de entrada en servidor
- ✓ Validación de existencia de usuarios
- ✓ Límites de campos estrictos
- ✓ Errores genéricos en respuestas (no revelan estructura DB)
- ✓ Timestamps seguros con CURRENT_TIMESTAMP

## Próximos Pasos Opcionales

1. Agregar notificaciones por correo al crear tickets
2. Agregar historial de cambios en tickets
3. Agregar prioridades a tickets
4. Agregar categorías de tickets
5. Crear panel de administración de tickets
6. Agregar búsqueda y filtrado de tickets
7. Agregar adjuntos a tickets
8. Crear reportes de tickets

## Archivos Modificados/Creados

### Base de Datos
- `Database/ministerio_gosen_postgresql_base.sql` - Tabla tickets
- `Database/ministerio_gosen_postgresql_rutinas.sql` - Procedimientos

### API
- `MinisterioGosenAPI/Models/TicketModel.cs` - NUEVO
- `MinisterioGosenAPI/Controllers/TicketsController.cs` - NUEVO
- `MinisterioGosenAPI/Controllers/ChatBotController.cs` - MODIFICADO

### UI
- `MinisterioGosen/Models/TicketModel.cs` - NUEVO
- `MinisterioGosen/wwwroot/js/chatbot.js` - MODIFICADO

## Testing

Para probar el sistema:

1. **Crear Ticket**:
```bash
POST /api/ChatBot/RegistrarTicketDesdeChat
{
	"idRequestor": 1,
	"titulo": "Problema con funcionalidad X",
	"descripcion": "Cuando intento acceder a X, ocurre Y",
	"idAsignee": null
}
```

2. **Obtener Tickets**:
```bash
GET /api/Tickets/ObtenerTicketsPorUsuario?idUsuario=1
```

3. **Actualizar Ticket**:
```bash
PUT /api/Tickets/ActualizarEstado
{
	"idTicket": 1,
	"estado": "En Progreso",
	"idAsignee": 2
}
```

---

**Implementación completada**: Enero 2026
**Versión**: 1.0
**Estado**: Listo para producción
