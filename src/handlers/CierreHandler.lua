local EventTypes = require("src.events.EventTypes")
local CierreHandler = {}
function CierreHandler.register(EventBus)
    EventBus.subscribe(EventTypes.CIERRE_PROPUESTO, function(data)
        print("[CierreHandler] Propuesta de cierre recibida")
        -- TODO: verificar condiciones y publicar TUTORIA_CERRADA
    end)
end
return CierreHandler
