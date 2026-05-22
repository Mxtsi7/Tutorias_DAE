local EventTypes = require("src.events.EventTypes")
local SolicitudHandler = {}
function SolicitudHandler.register(EventBus)
    EventBus.subscribe(EventTypes.SOLICITUD_ENVIADA, function(data)
        -- Validación ya ocurre en la pantalla; aquí se registraría en BD real
        print("[SolicitudHandler] Solicitud recibida")
    end)
end
return SolicitudHandler
