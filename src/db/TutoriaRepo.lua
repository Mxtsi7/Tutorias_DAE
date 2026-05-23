local DB = require("src.db.DB")
local R  = {}

function R.getAll()
    return DB.all("tutorias")
end

function R.getByEstudiante(usuario_id)
    local est = DB.find("estudiantes", function(e) return e.usuario_id == usuario_id end)
    if not est then return {} end
    return DB.where("tutorias", function(t) return t.estudiante_id == est.id end)
end

function R.registrarSesion(tutoria_id, avance, asistencia)
    DB.update("tutorias", function(t) return t.id == tutoria_id end, function()
    end)
    local t = DB.find("tutorias", function(t) return t.id == tutoria_id end)
    if not t then return end

    if asistencia == "Asistio" then
        t.sesiones   = (t.sesiones or 0) + 1
        t.ausencias  = 0
    elseif asistencia == "Ausencia injust." then
        t.ausencias  = (t.ausencias or 0) + 1
    end
    t.nivel_avance = avance

    if t.ausencias >= 3 then t.estado = "suspendida"
    elseif t.ausencias >= 1 then t.estado = "activa_con_alerta"
    else t.estado = "activa" end

    DB.save()
end

return R
