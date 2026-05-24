local EventTypes = require("src.events.EventTypes")
local DB         = require("src.db.DB")

local AsignacionHandler = {}

function AsignacionHandler.register(EventBus)
    EventBus.subscribe(EventTypes.TUTOR_ASIGNADO, function(data)
        local tutor = data.tutor
        if not tutor then return end
        print("[AsignacionHandler] Tutor asignado: " .. (tutor.nombre or "?"))
        local tutorDB = DB.find("tutores", function(r) return r.id == tutor.id end)
        if tutorDB then
            tutorDB.tutorados_activos = (tutorDB.tutorados_activos or 0) + 1
            DB.save()
        end
        if data.estudiante_id then
            DB.insert("tutorias", {
                estudiante_id     = data.estudiante_id,
                tutor_id          = tutor.id,
                area              = data.area or "",
                estado            = "activa",
                nivel_avance      = "bajo",
                sesiones          = 0,
                ausencias         = 0,
                tutor_nombre      = tutor.nombre,
                estudiante_nombre = data.estudiante_nombre or "",
                area_necesidad    = data.area or "",
                fecha_inicio      = os.date("%Y-%m-%d"),
            })
            DB.save()
        end
    end)

    EventBus.subscribe(EventTypes.TUTOR_RECHAZO, function(data)
        local tutor_id = data.tutor_id
        if not tutor_id then return end
        local t = DB.find("tutores", function(r) return r.id == tutor_id end)
        if t then
            t.incidentes = (t.incidentes or 0) + 1
            t.ultimo_rechazo = data.tacito and "rechazo_tacito" or "rechazo_explicito"
            DB.save()
        end
    end)

    EventBus.subscribe(EventTypes.TUTOR_DADO_DE_BAJA, function(data)
        local tutor_id = data.tutor_id
        if not tutor_id then return end
        local afectadas = DB.where("tutorias", function(r)
            return r.tutor_id == tutor_id and
                   (r.estado == "activa" or r.estado == "activa_con_alerta")
        end)
        for _, t in ipairs(afectadas) do
            t.estado = "pendiente_reasignacion"
        end
        local tutor = DB.find("tutores", function(r) return r.id == tutor_id end)
        if tutor then
            tutor.activo = false
            tutor.tutorados_activos = 0
        end
        DB.save()
        print("[AsignacionHandler] Tutor dado de baja - " ..
              #afectadas .. " tutorias pendientes de reasignacion")
    end)
end

return AsignacionHandler
