-- SolicitudHandler.lua: Maneja eventos relacionados a solicitudes de tutoría

local EventTypes = require("src.events.EventTypes")

local SolicitudHandler = {}

function SolicitudHandler.register(EventBus)
    -- TODO: suscribir a SOLICITUD_ENVIADA
    -- Al recibir: validar campos, publicar SOLICITUD_VALIDADA o SOLICITUD_RECHAZADA
end

return SolicitudHandler
