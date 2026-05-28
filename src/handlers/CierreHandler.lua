local EventTypes = require("src.events.EventTypes")
local DB         = require("src.db.DB")

local CierreHandler = {}

local function liberarCupoTutor(tutoria)
    if tutoria.tutor_id then
        local tutor = DB.find("tutores", function(r) return r.id == tutoria.tutor_id end)
        if tutor and (tutor.tutorados_activos or 0) > 0 then
            tutor.tutorados_activos = tutor.tutorados_activos - 1
        end
    end
end

function CierreHandler.register(EventBus)

    EventBus.subscribe(EventTypes.CIERRE_PROPUESTO, function(data)
        local tutoria_id = data.tutoria_id
        if not tutoria_id then return end
        local t = DB.find("tutorias", function(r) return r.id == tutoria_id end)
        if not t then return end

        -- CASO 1: Cierre por abandono.
        -- Requiere advertencia_formal activa y 3+ ausencias injustificadas.
        if t.advertencia_formal and (t.ausencias or 0) >= 3 then
            t.estado       = "cerrada_por_abandono"
            t.fecha_cierre = os.date("%Y-%m-%d")
            liberarCupoTutor(t)
            DB.save()
            EventBus.publish(EventTypes.TUTORIA_CERRADA, {
                tutoria_id = tutoria_id,
                motivo     = "abandono",
            })
            EventBus.publish(EventTypes.ALERTA_COORDINADOR, {
                tipo       = "cierre_abandono",
                tutoria_id = tutoria_id,
                mensaje    = "Tutor\xc3\xada cerrada por abandono: " ..
                             (t.estudiante_nombre or "Estudiante") ..
                             " (3+ ausencias injustificadas con advertencia formal)",
            })
            print("[CierreHandler] Tutoria " .. tutoria_id .. " cerrada por abandono")
            return
        end

        -- CASO 2: Cierre exitoso.
        -- Requiere nivel de avance adecuado y minimo de sesiones.
        local sesiones = t.sesiones  or 0
        local nivel    = t.nivel_avance or "bajo"
        local cumple   = false
        if nivel == "alto"  and sesiones >= 4 then cumple = true end
        if nivel == "medio" and sesiones >= 6 then cumple = true end
        -- nivel 'bajo' no tiene condicion de cierre exitoso

        if cumple then
            t.estado       = "cerrada_exitosamente"
            t.fecha_cierre = os.date("%Y-%m-%d")
            liberarCupoTutor(t)
            DB.save()
            EventBus.publish(EventTypes.TUTORIA_CERRADA, {
                tutoria_id = tutoria_id,
                motivo     = "exitoso",
            })
            print("[CierreHandler] Tutoria " .. tutoria_id .. " cerrada exitosamente")
        else
            -- Informar cuantas sesiones faltan
            local falta = 0
            if nivel == "alto"  then falta = math.max(0, 4 - sesiones) end
            if nivel == "medio" then falta = math.max(0, 6 - sesiones) end
            local msg = nivel == "bajo"
                and "Nivel de avance bajo no permite cierre exitoso"
                or  "Faltan " .. falta .. " sesion(es) para nivel '" .. nivel .. "'"
            print("[CierreHandler] Cierre rechazado - " .. msg)
            EventBus.publish(EventTypes.NOTIFICACION_MOSTRAR, {
                tipo    = "error",
                mensaje = msg,
            })
        end
    end)
end

return CierreHandler
