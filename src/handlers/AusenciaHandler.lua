local EventTypes = require("src.events.EventTypes")
local AusenciaHandler = {}
function AusenciaHandler.register(EventBus)
    EventBus.subscribe(EventTypes.SESION_AUSENCIA_INJUST, function(data)
        print("[AusenciaHandler] Ausencia injustificada registrada")
        -- TODO: contar consecutivas y publicar AUSENCIA_DETECTADA si llegan a 2
    end)
end
return AusenciaHandler
