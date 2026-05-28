local EventTypes = require("src.events.EventTypes")
local DB         = require("src.db.DB")

local AsignacionHandler = {}

function AsignacionHandler.register(EventBus)

    -- TUTOR_ASIGNADO: el coordinador propone un tutor.
    -- La tutoria NO se crea aun; la solicitud pasa a 'asignacion_propuesta'
    -- y se guarda la fecha para detectar rechazo tacito.
    EventBus.subscribe(EventTypes.TUTOR_ASIGNADO, function(data)
        local tutor = data.tutor
        if not tutor then return end
        print("[AsignacionHandler] Propuesta enviada al tutor: " .. (tutor.nombre or "?"))

        if data.solicitud_id then
            local sol = DB.find("solicitudes", function(s) return s.id == data.solicitud_id end)
            if sol then
                sol.estado          = "asignacion_propuesta"
                sol.tutor_propuesto = tutor.id
                sol.fecha_propuesta = os.time()   -- timestamp UNIX para calcular 48h
                DB.save()
            end
        end
    end)

    -- TUTOR_ACEPTO: el tutor acepta la propuesta.
    -- Solo aqui se crea la tutoria como 'activa' y se descuenta el cupo.
    EventBus.subscribe(EventTypes.TUTOR_ACEPTO, function(data)
        local tutor = data.tutor
        if not tutor or not data.estudiante_id then return end
        print("[AsignacionHandler] Tutor acepto: " .. (tutor.nombre or "?"))

        -- Actualizar cupo del tutor
        local tutorDB = DB.find("tutores", function(r) return r.id == tutor.id end)
        if tutorDB then
            tutorDB.tutorados_activos = (tutorDB.tutorados_activos or 0) + 1
            DB.save()
        end

        -- Crear tutoria activa
        DB.insert("tutorias", {
            estudiante_id      = data.estudiante_id,
            tutor_id           = tutor.id,
            area               = data.area or "",
            estado             = "activa",
            nivel_avance       = "bajo",
            sesiones           = 0,
            ausencias          = 0,
            historial_avance   = {},
            tutor_nombre       = tutor.nombre,
            estudiante_nombre  = data.estudiante_nombre or "",
            area_necesidad     = data.area or "",
            fecha_inicio       = os.date("%Y-%m-%d"),
            advertencia_formal = false,
            alerta_avance_bajo = false,
        })
        DB.save()
    end)

    -- TUTOR_RECHAZO: rechazo explicito o tacito.
    -- Registra incidente y devuelve la solicitud a 'pendiente' para reasignar.
    EventBus.subscribe(EventTypes.TUTOR_RECHAZO, function(data)
        local tutor_id = data.tutor_id
        if not tutor_id then return end
        local t = DB.find("tutores", function(r) return r.id == tutor_id end)
        if t then
            t.incidentes   = (t.incidentes or 0) + 1
            t.ultimo_rechazo = data.tacito and "rechazo_tacito" or "rechazo_explicito"
            DB.save()
        end
        -- Devolver solicitud a 'pendiente' para que el coordinador reasigne
        if data.solicitud_id then
            local sol = DB.find("solicitudes", function(s) return s.id == data.solicitud_id end)
            if sol and sol.estado == "asignacion_propuesta" then
                sol.estado          = "pendiente"
                sol.tutor_propuesto = nil
                sol.fecha_propuesta = nil
                DB.save()
            end
        end
        local tipo = data.tacito and "rechazo_tacito" or "rechazo_explicito"
        print("[AsignacionHandler] " .. tipo .. " registrado para tutor " .. tutor_id)
    end)

    -- VERIFICAR_TACITOS: publicar periodicamente desde main.lua update().
    -- Detecta solicitudes en 'asignacion_propuesta' que superaron 48h sin respuesta.
    EventBus.subscribe(EventTypes.VERIFICAR_TACITOS, function(_)
        local LIMITE_SEGUNDOS = 48 * 60 * 60   -- 48 horas
        local ahora = os.time()
        local propuestas = DB.where("solicitudes", function(s)
            return s.estado == "asignacion_propuesta"
        end)
        for _, sol in ipairs(propuestas) do
            if sol.fecha_propuesta and (ahora - sol.fecha_propuesta) >= LIMITE_SEGUNDOS then
                print("[AsignacionHandler] Rechazo tacito detectado - solicitud " .. tostring(sol.id))
                EventBus.publish(EventTypes.TUTOR_RECHAZO, {
                    tutor_id     = sol.tutor_propuesto,
                    solicitud_id = sol.id,
                    tacito       = true,
                })
            end
        end
    end)

    -- TUTOR_DADO_DE_BAJA: mueve todas sus tutorias activas a pendiente_reasignacion.
    EventBus.subscribe(EventTypes.TUTOR_DADO_DE_BAJA, function(data)
        local tutor_id = data.tutor_id
        if not tutor_id then return end
        local afectadas = DB.where("tutorias", function(r)
            return r.tutor_id == tutor_id and
                   (r.estado == "activa" or r.estado == "activa_con_alerta"
                    or r.estado == "activa_con_advertencia_formal")
        end)
        for _, t in ipairs(afectadas) do
            t.estado         = "pendiente_reasignacion"
            t.tutor_anterior = t.tutor_id
        end
        local tutor = DB.find("tutores", function(r) return r.id == tutor_id end)
        if tutor then
            tutor.activo            = false
            tutor.estado            = "inactivo"
            tutor.tutorados_activos = 0
        end
        DB.save()
        print("[AsignacionHandler] Tutor dado de baja - " ..
              #afectadas .. " tutorias pendientes de reasignacion")
    end)
end

return AsignacionHandler
