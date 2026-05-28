local EventTypes = require("src.events.EventTypes")
local DB         = require("src.db.DB")

local SesionHandler = {}

function SesionHandler.register(EventBus)

    EventBus.subscribe(EventTypes.SESION_REGISTRADA, function(data)
        local tutoria_id = data.tutoria_id
        local avance     = data.avance     or "bajo"
        local asistencia = data.asistencia or "Asistio"
        print("[SesionHandler] Sesion registrada - avance: " .. avance ..
              " - asistencia: " .. asistencia)
        if not tutoria_id then return end

        local t = DB.find("tutorias", function(r) return r.id == tutoria_id end)
        if not t then return end

        -- Actualizar nivel_avance actual
        t.nivel_avance = avance

        -- Mantener historial de avance por sesion (Decision 6 del MPN)
        local historial = t.historial_avance or {}
        table.insert(historial, avance)
        t.historial_avance = historial

        -- Detectar avance bajo sostenido en las ultimas 3 sesiones
        if #historial >= 3 then
            local ult3 = {
                historial[#historial - 2],
                historial[#historial - 1],
                historial[#historial],
            }
            local todo_bajo = ult3[1]=="bajo" and ult3[2]=="bajo" and ult3[3]=="bajo"

            if todo_bajo and not t.alerta_avance_bajo then
                -- Primera vez que se detecta la racha baja
                t.alerta_avance_bajo = true
                EventBus.publish(EventTypes.ALERTA_COORDINADOR, {
                    tipo       = "avance_bajo_sostenido",
                    tutoria_id = tutoria_id,
                    mensaje    = (t.estudiante_nombre or "Estudiante") ..
                                 " lleva 3 sesiones consecutivas con avance BAJO",
                })
                print("[SesionHandler] Alerta: avance bajo sostenido en 3 sesiones")
            elseif not todo_bajo then
                -- Si mejora, limpiar la alerta para que pueda dispararse de nuevo
                t.alerta_avance_bajo = false
            end
        end

        DB.save()

        -- Delegar logica de asistencia a AusenciaHandler via eventos
        if asistencia == "Ausencia injust." or asistencia == "ausencia_injustificada" then
            EventBus.publish(EventTypes.SESION_AUSENCIA_INJUST, {
                tutoria_id = tutoria_id,
                avance     = avance,
            })
        elseif asistencia == "Ausencia just." or asistencia == "ausencia_justificada" then
            EventBus.publish(EventTypes.SESION_AUSENCIA_JUST, {
                tutoria_id = tutoria_id,
            })
        end
    end)
end

return SesionHandler
