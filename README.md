# Tutorias DAE — Sistema de Gestión de Tutorías

Proyecto desarrollado con **Lua + LÖVE2D** usando **Arquitectura Orientada a Eventos**.

---

## 📁 Estructura del Proyecto

```
Tutorias_DAE/
├── main.lua                  # Punto de entrada principal
├── conf.lua                  # Configuración de la ventana LÖVE2D
├── README.md
│
├── src/
│   ├── events/               # Sistema de eventos (bus central)
│   │   ├── EventBus.lua      # Publicador/suscriptor de eventos
│   │   └── EventTypes.lua    # Constantes de tipos de eventos
│   │
│   ├── domain/               # Lógica de negocio y reglas
│   │   ├── Solicitud.lua     # Entidad Solicitud
│   │   ├── Tutoria.lua       # Entidad Tutoría
│   │   ├── Sesion.lua        # Entidad Sesión
│   │   ├── Estudiante.lua    # Entidad Estudiante
│   │   └── Tutor.lua         # Entidad Tutor
│   │
│   ├── handlers/             # Manejadores de eventos
│   │   ├── SolicitudHandler.lua
│   │   ├── AsignacionHandler.lua
│   │   ├── SesionHandler.lua
│   │   ├── AusenciaHandler.lua
│   │   └── CierreHandler.lua
│   │
│   ├── screens/              # Pantallas de la interfaz (LÖVE2D)
│   │   ├── ScreenManager.lua # Gestor de pantallas
│   │   ├── MenuScreen.lua    # Pantalla principal
│   │   ├── SolicitudScreen.lua
│   │   ├── AsignacionScreen.lua
│   │   ├── SesionScreen.lua
│   │   └── SeguimientoScreen.lua
│   │
│   ├── components/           # Componentes UI reutilizables
│   │   ├── Button.lua
│   │   ├── Form.lua
│   │   ├── Modal.lua
│   │   └── Alert.lua
│   │
│   └── data/                 # Datos simulados (ficticios para PMN)
│       ├── estudiantes.lua
│       ├── tutores.lua
│       └── tutorias.lua
```

---

## 🚀 Instalación

### 1. Instalar LÖVE2D

**Windows:**
1. Ve a [https://love2d.org](https://love2d.org)
2. Descarga el instalador para Windows (64-bit recomendado)
3. Instala normalmente y asegúrate de agregar LÖVE al PATH del sistema

**macOS:**
```bash
brew install love
```

**Linux (Ubuntu/Debian):**
```bash
sudo apt install love
```

---

### 2. Instalar VS Code + extensiones

1. Descarga VS Code desde [https://code.visualstudio.com](https://code.visualstudio.com)
2. Instala las siguientes extensiones desde el marketplace:
   - **Lua** (sumneko) — autocompletado e intellisense
   - **Local Lua Debugger** — para depurar
   - **Love2D Support** — soporte específico para LÖVE2D

---

### 3. Clonar el repositorio

```bash
git clone https://github.com/Mxtsi7/Tutorias_DAE.git
cd Tutorias_DAE
```

---

### 4. Ejecutar el proyecto

**Opción A — Arrastrar carpeta:**
Arrastra la carpeta `Tutorias_DAE` directamente sobre el ejecutable de LÖVE2D.

**Opción B — Terminal:**
```bash
love .
```
(Ejecutar desde dentro de la carpeta del proyecto)

**Opción C — VS Code integrado:**
Configura el task runner de VS Code con:
```json
{
  "version": "2.0.0",
  "tasks": [
    {
      "label": "Run LÖVE2D",
      "type": "shell",
      "command": "love .",
      "group": { "kind": "build", "isDefault": true }
    }
  ]
}
```
Luego usa `Ctrl+Shift+B` para ejecutar.

---

## ⚡ Arquitectura Orientada a Eventos

El sistema usa un **EventBus** central. Cuando ocurre algo importante, se publica un evento y los handlers reaccionan automáticamente.

**Ejemplo de flujo:**
```
Estudiante envía ficha
  → evento: SOLICITUD_ENVIADA
    → SolicitudHandler valida campos
      → evento: SOLICITUD_VALIDADA o SOLICITUD_RECHAZADA
        → pantalla actualiza estado
```

**Eventos principales del sistema:**
- `SOLICITUD_ENVIADA` — estudiante envía ficha
- `SOLICITUD_VALIDADA` — sistema aprueba ficha
- `TUTOR_ASIGNADO` — coordinador asigna tutor
- `TUTOR_ACEPTO` — tutor acepta en 48 hrs
- `SESION_REGISTRADA` — tutor registra sesión
- `AUSENCIA_DETECTADA` — 2 ausencias consecutivas
- `TUTORIA_CERRADA` — coordinador aprueba cierre

---

## 👥 Integrantes
- Maximiliano Sáez
- Christopher Solís

**Profesor:** Gastón Contreras  
**Ramo:** Desarrollo de Aplicaciones Empresariales
