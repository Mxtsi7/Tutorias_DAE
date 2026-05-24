local EventTypes = require("src.events.EventTypes")
local DB         = require("src.db.DB")

local SesionHandler = {}

function SesionHandler.register(EventBus)
    EventBus.subscribe(EventTypes.SESION_REGISTRADA, function(data)
        local tutoria_id = data.tutoria_id
        local avance     = data.avance     or "bajo"
        local asistencia = data.asistencia or "asistio"
        print("[SesionHandler] Sesion registrada - avance: " .. avance ..
              " - asistencia: " .. asistencia)
        if not tutoria_id then return end
        if asistencia == "Ausencia injust." or asistencia == "ausencia_injustificada" then
            EventBus.publish(EventTypes.SESION_AUSENCIA_INJUST, {
                tutoria_id = tutoria_id, avance = avance,
            })
        elseif asistencia == "Ausencia just." or asistencia == "ausencia_justificada" then
            EventBus.publish(EventTypes.SESION_AUSENCIA_JUST, {
                tutoria_id = tutoria_id,
            })
        end
        local t = DB.find("tutorias", function(r) return r.id == tutoria_id end)
        if t then
            t.nivel_avance = avance
            DB.save()
        end
    end)
end

return SesionHandler
