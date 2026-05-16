-- SolicitudScreen.lua: Pantalla para crear y enviar ficha de solicitud
-- Campos requeridos: area_tematica, nivel_urgencia, disponibilidad, modalidad

local SolicitudScreen = {}

function SolicitudScreen:load()
    -- TODO: inicializar formulario con los 4 campos obligatorios
end

function SolicitudScreen:update(dt)
    -- TODO: actualizar estado de inputs y validaciones visuales
end

function SolicitudScreen:draw()
    -- TODO: dibujar formulario, labels, inputs y botón de envío
end

function SolicitudScreen:mousepressed(x, y, button)
    -- TODO: detectar clic en botón enviar y publicar SOLICITUD_ENVIADA
end

function SolicitudScreen:textinput(text)
    -- TODO: capturar texto ingresado en el campo activo
end

return SolicitudScreen
