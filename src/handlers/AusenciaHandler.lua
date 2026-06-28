local EventTypes = require("src.events.EventTypes")
local DB         = require("src.db.DB")

local AusenciaHandler = {}

function AusenciaHandler.register(EventBus)

    -- SESION_AUSENCIA_INJUST:
    -- 1ra ausencia -> activa_con_alerta
    -- 2da ausencia -> activa_con_advertencia_formal  (Decision coordinador)
    -- 3ra+ ausencia -> abandono_potencial
    EventBus.subscribe(EventTypes.SESION_AUSENCIA_INJUST, function(data)
        local tutoria_id = data.tutoria_id
        if not tutoria_id then return end
        local t = DB.find("tutorias", function(r) return r.id == tutoria_id end)
        if not t then return end

        local estadosFinales = {
            cerrada_exitosamente            = true,
            cerrada_por_abandono            = true,
            cerrada_por_abandono_voluntario = true,
            suspendida                      = true,
        }
        if estadosFinales[t.estado] then return end

        local ausencias = (t.ausencias or 0) + 1
        t.ausencias = ausencias

        if ausencias == 1 then
            t.estado = "activa_con_alerta"
            EventBus.publish(EventTypes.ALERTA_COORDINADOR, {
                tipo       = "ausencia_primera",
                tutoria_id = tutoria_id,
                estudiante = t.estudiante_nombre or "Estudiante",
                ausencias  = ausencias,
                mensaje    = "Alerta: " .. (t.estudiante_nombre or "Estudiante") ..
                             " registro su 1ra ausencia injustificada",
            })
            print("[AusenciaHandler] 1ra ausencia - activa_con_alerta")

        elseif ausencias == 2 then
            t.estado             = "activa_con_advertencia_formal"
            t.advertencia_formal = true
            EventBus.publish(EventTypes.ALERTA_COORDINADOR, {
                tipo       = "advertencia_formal",
                tutoria_id = tutoria_id,
                estudiante = t.estudiante_nombre or "Estudiante",
                ausencias  = ausencias,
                mensaje    = "ADVERTENCIA FORMAL: " .. (t.estudiante_nombre or "Estudiante") ..
                             " acumula 2 ausencias injustificadas consecutivas",
            })
            print("[AusenciaHandler] 2da ausencia - activa_con_advertencia_formal")

        elseif ausencias >= 3 then
            EventBus.publish(EventTypes.ALERTA_COORDINADOR, {
                tipo       = "abandono_potencial",
                tutoria_id = tutoria_id,
                estudiante = t.estudiante_nombre or "Estudiante",
                ausencias  = ausencias,
                mensaje    = "CRITICO: " .. (t.estudiante_nombre or "Estudiante") ..
                             " lleva " .. ausencias .. " ausencias injustificadas" ..
                             " - posible abandono.",
            })
            print("[AusenciaHandler] " .. ausencias .. " ausencias - alerta critica")
        end

        DB.save()
    end)

    -- SESION_AUSENCIA_JUST: resetear contador de consecutivas
    EventBus.subscribe(EventTypes.SESION_AUSENCIA_JUST, function(data)
        local tutoria_id = data.tutoria_id
        if not tutoria_id then return end
        local t = DB.find("tutorias", function(r) return r.id == tutoria_id end)
        if not t then return end

        t.ausencias = 0
        if t.estado == "activa_con_alerta" then
            t.estado = "activa"
        end
        DB.save()
        print("[AusenciaHandler] Ausencia justificada - contador reseteado")
    end)

    -- TUTORIA_CONTINUA: coordinador decide continuar pese a advertencia formal.
    -- Resetea ausencias a 0 y devuelve estado a "activa".
    EventBus.subscribe(EventTypes.TUTORIA_CONTINUA, function(data)
        local tutoria_id = data.tutoria_id
        if not tutoria_id then return end
        local t = DB.find("tutorias", function(r) return r.id == tutoria_id end)
        if not t then return end

        t.ausencias          = 0
        t.advertencia_formal = false
        t.estado             = "activa"
        DB.save()
        print("[AusenciaHandler] TUTORIA_CONTINUA - ausencias reseteadas, estado -> activa")
    end)

    -- TUTORIA_SUSPENDIDA: coordinador decide suspender.
    -- Cambia estado a "suspendida" y registra fecha.
    EventBus.subscribe(EventTypes.TUTORIA_SUSPENDIDA, function(data)
        local tutoria_id = data.tutoria_id
        if not tutoria_id then return end
        local t = DB.find("tutorias", function(r) return r.id == tutoria_id end)
        if not t then return end

        t.estado            = "suspendida"
        t.fecha_suspension  = os.date("%Y-%m-%d")
        DB.save()
        print("[AusenciaHandler] TUTORIA_SUSPENDIDA - estado -> suspendida en " .. t.fecha_suspension)
    end)
end

return AusenciaHandler
