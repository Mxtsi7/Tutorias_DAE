local EventTypes = require("src.events.EventTypes")
local DB         = require("src.db.DB")

local AusenciaHandler = {}

function AusenciaHandler.register(EventBus)
    EventBus.subscribe(EventTypes.SESION_AUSENCIA_INJUST, function(data)
        local tutoria_id = data.tutoria_id
        if not tutoria_id then return end
        local t = DB.find("tutorias", function(r) return r.id == tutoria_id end)
        if not t then return end
        local ausencias = (t.ausencias or 0) + 1
        t.ausencias = ausencias
        if ausencias >= 2 then
            t.estado = "activa_con_alerta"
            EventBus.publish(EventTypes.ALERTA_COORDINADOR, {
                tipo    = "ausencias",
                mensaje = "Alerta: " .. (t.estudiante_nombre or "Estudiante") ..
                          " acumulo 2 ausencias consecutivas",
            })
        end
        DB.save()
        print("[AusenciaHandler] Ausencias consecutivas: " .. ausencias)
    end)

    EventBus.subscribe(EventTypes.SESION_AUSENCIA_JUST, function(data)
        local tutoria_id = data.tutoria_id
        if not tutoria_id then return end
        local t = DB.find("tutorias", function(r) return r.id == tutoria_id end)
        if t then
            t.ausencias = 0
            DB.save()
        end
        print("[AusenciaHandler] Ausencia justificada - contador reseteado")
    end)
end

return AusenciaHandler
