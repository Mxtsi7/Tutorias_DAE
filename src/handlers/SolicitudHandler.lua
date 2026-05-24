local EventTypes    = require("src.events.EventTypes")
local SolicitudRepo = require("src.db.SolicitudRepo")

local SolicitudHandler = {}

function SolicitudHandler.register(EventBus)
    EventBus.subscribe(EventTypes.SOLICITUD_ENVIADA, function(data)
        local campos = { data.area, data.urgencia, data.disponibilidad, data.modalidad }
        local valido = true
        for _, v in ipairs(campos) do
            if not v or v == "" then valido = false break end
        end
        if valido then
            EventBus.publish(EventTypes.SOLICITUD_VALIDADA, data)
            print("[SolicitudHandler] Solicitud valida")
        else
            EventBus.publish(EventTypes.SOLICITUD_RECHAZADA, {
                motivo = "Campos obligatorios incompletos", data = data,
            })
            print("[SolicitudHandler] Solicitud rechazada - campos incompletos")
        end
    end)

    EventBus.subscribe(EventTypes.SOLICITUD_VALIDADA, function(data)
        if data.usuario_id then
            SolicitudRepo.crear(
                data.usuario_id, data.area, data.urgencia,
                data.disponibilidad, data.modalidad
            )
        end
    end)
end

return SolicitudHandler
