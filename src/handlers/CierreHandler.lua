-- CierreHandler.lua: Maneja eventos de cierre de tutoría

local EventTypes = require("src.events.EventTypes")

local CierreHandler = {}

function CierreHandler.register(EventBus)
    -- TODO: suscribir a CIERRE_PROPUESTO
    -- Al recibir: verificar condiciones (sesiones mínimas, conformidad estudiante)
    -- Si cumple: publicar TUTORIA_CERRADA
    -- Si no cumple: publicar ALERTA_COORDINADOR con motivo
end

return CierreHandler
