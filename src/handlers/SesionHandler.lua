local EventTypes = require("src.events.EventTypes")
local SesionHandler = {}
function SesionHandler.register(EventBus)
    EventBus.subscribe(EventTypes.SESION_REGISTRADA, function(data)
        print("[SesionHandler] Sesión registrada — avance: " .. (data.avance or "?"))
    end)
end
return SesionHandler
