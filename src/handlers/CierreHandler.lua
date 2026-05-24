local EventTypes = require("src.events.EventTypes")
local DB         = require("src.db.DB")

local CierreHandler = {}

function CierreHandler.register(EventBus)
    EventBus.subscribe(EventTypes.CIERRE_PROPUESTO, function(data)
        local tutoria_id = data.tutoria_id
        if not tutoria_id then return end
        local t = DB.find("tutorias", function(r) return r.id == tutoria_id end)
        if not t then return end
        local sesiones = t.sesiones or 0
        local nivel    = t.nivel_avance or "bajo"
        local cumple = false
        if nivel == "alto"  and sesiones >= 4 then cumple = true end
        if nivel == "medio" and sesiones >= 6 then cumple = true end
        if cumple then
            t.estado       = "cerrada_exitosamente"
            t.fecha_cierre = os.date("%Y-%m-%d")
            if t.tutor_id then
                local tutor = DB.find("tutores", function(r) return r.id == t.tutor_id end)
                if tutor and (tutor.tutorados_activos or 0) > 0 then
                    tutor.tutorados_activos = tutor.tutorados_activos - 1
                end
            end
            DB.save()
            EventBus.publish(EventTypes.TUTORIA_CERRADA, { tutoria_id = tutoria_id })
            print("[CierreHandler] Tutoria " .. tutoria_id .. " cerrada exitosamente")
        else
            local falta = nivel == "alto" and math.max(0, 4 - sesiones)
                                          or math.max(0, 6 - sesiones)
            print("[CierreHandler] Cierre rechazado - faltan " .. falta .. " sesiones")
        end
    end)
end

return CierreHandler
