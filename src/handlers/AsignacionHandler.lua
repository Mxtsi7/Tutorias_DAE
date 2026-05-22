local EventTypes = require("src.events.EventTypes")
local AsignacionHandler = {}
function AsignacionHandler.register(EventBus)
    EventBus.subscribe(EventTypes.TUTOR_ASIGNADO, function(data)
        print("[AsignacionHandler] Tutor asignado: " .. (data.tutor and data.tutor.nombre or "?"))
    end)
end
return AsignacionHandler
