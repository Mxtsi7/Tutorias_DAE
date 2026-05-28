local EventTypes = require("src.events.EventTypes")
local DB         = require("src.db.DB")

local AusenciaHandler = {}

function AusenciaHandler.register(EventBus)

    -- SESION_AUSENCIA_INJUST:
    -- 1ra ausencia -> activa_con_alerta   (notificacion leve al coordinador)
    -- 2da ausencia -> activa_con_advertencia_formal  (advertencia formal)
    -- 3ra ausencia -> coordinador puede cerrar por abandono
    EventBus.subscribe(EventTypes.SESION_AUSENCIA_INJUST, function(data)
        local tutoria_id = data.tutoria_id
        if not tutoria_id then return end
        local t = DB.find("tutorias", function(r) return r.id == tutoria_id end)
        if not t then return end

        -- No procesar si la tutoria ya esta en estado final
        local estadosFinales = {
            cerrada_exitosamente = true,
            cerrada_por_abandono = true,
            cerrada_por_abandono_voluntario = true,
        }
        if estadosFinales[t.estado] then return end

        local ausencias = (t.ausencias or 0) + 1
        t.ausencias = ausencias

        if ausencias == 1 then
            -- Primera ausencia injustificada: alerta temprana
            t.estado = "activa_con_alerta"
            EventBus.publish(EventTypes.ALERTA_COORDINADOR, {
                tipo      = "ausencia_primera",
                tutoria_id = tutoria_id,
                mensaje   = "Alerta: " .. (t.estudiante_nombre or "Estudiante") ..
                            " registr\xc3\xb3 su 1\xc2\xaa ausencia injustificada",
            })
            print("[AusenciaHandler] 1ra ausencia - activa_con_alerta")

        elseif ausencias == 2 then
            -- Segunda ausencia: advertencia formal (Decision 5 del MPN)
            t.estado             = "activa_con_advertencia_formal"
            t.advertencia_formal = true
            EventBus.publish(EventTypes.ALERTA_COORDINADOR, {
                tipo       = "advertencia_formal",
                tutoria_id = tutoria_id,
                mensaje    = "ADVERTENCIA FORMAL: " .. (t.estudiante_nombre or "Estudiante") ..
                             " acumula 2 ausencias injustificadas consecutivas",
            })
            print("[AusenciaHandler] 2da ausencia - activa_con_advertencia_formal")

        elseif ausencias >= 3 then
            -- Tercera ausencia: alerta critica, coordinador puede cerrar por abandono
            EventBus.publish(EventTypes.ALERTA_COORDINADOR, {
                tipo       = "abandono_potencial",
                tutoria_id = tutoria_id,
                mensaje    = "CRITICO: " .. (t.estudiante_nombre or "Estudiante") ..
                             " lleva " .. ausencias .. " ausencias injustificadas" ..
                             " - posible abandono. Requiere decisi\xc3\xb3n del coordinador.",
            })
            print("[AusenciaHandler] " .. ausencias .. " ausencias - alerta critica")
        end

        DB.save()
    end)

    -- SESION_AUSENCIA_JUST: ausencia justificada -> resetear contador de consecutivas
    EventBus.subscribe(EventTypes.SESION_AUSENCIA_JUST, function(data)
        local tutoria_id = data.tutoria_id
        if not tutoria_id then return end
        local t = DB.find("tutorias", function(r) return r.id == tutoria_id end)
        if not t then return end

        t.ausencias = 0
        -- Bajar estado solo si no tenia advertencia formal previa
        if t.estado == "activa_con_alerta" then
            t.estado = "activa"
        end
        DB.save()
        print("[AusenciaHandler] Ausencia justificada - contador reseteado")
    end)
end

return AusenciaHandler
