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

function R.getByTutor(usuario_id)
    local tutor = DB.find("tutores", function(t) return t.usuario_id == usuario_id end)
    if not tutor then return {} end
    local rows = DB.where("tutorias", function(t) return t.tutor_id == tutor.id end)
    -- enriquecer con nombre del estudiante para el selector del formulario
    for _, t in ipairs(rows) do
        if not t.estudiante_nombre then
            local est = DB.find("estudiantes", function(e) return e.id == t.estudiante_id end)
            if est then
                local usr = DB.find("usuarios", function(u) return u.id == est.usuario_id end)
                t.estudiante_nombre = usr and usr.nombre or "\xe2\x80\x94"
            else
                t.estudiante_nombre = "\xe2\x80\x94"
            end
        end
    end
    return rows
end

function R.getById(id)
    return DB.find("tutorias", function(t) return t.id == id end)
end

function R.registrarSesion(tutoria_id, avance, asistencia)
    local t = DB.find("tutorias", function(r) return r.id == tutoria_id end)
    if not t then
        print("[TutoriaRepo] Tutoria no encontrada: " .. tostring(tutoria_id))
        return
    end
    local sesiones  = t.sesiones  or 0
    local ausencias = t.ausencias or 0
    if asistencia == "Asistio" then
        sesiones  = sesiones + 1
        ausencias = 0
    elseif asistencia == "Ausencia injust." then
        ausencias = ausencias + 1
    elseif asistencia == "Ausencia just." then
        ausencias = 0
    end
    local estado = t.estado or "activa"
    if ausencias >= 2 then
        estado = "suspendida"
    elseif ausencias == 1 then
        estado = "activa_con_alerta"
    else
        estado = "activa"
    end
    t.sesiones     = sesiones
    t.ausencias    = ausencias
    t.nivel_avance = avance or t.nivel_avance
    t.estado       = estado
    DB.save()
end

function R.cambiarEstado(tutoria_id, nuevoEstado)
    local t = DB.find("tutorias", function(r) return r.id == tutoria_id end)
    if not t then return end
    t.estado = nuevoEstado
    DB.save()
end

function R.proponerCierre(tutoria_id)
    local t = DB.find("tutorias", function(r) return r.id == tutoria_id end)
    if not t then return false, "Tutoria no encontrada" end
    local sesiones = t.sesiones or 0
    local nivel    = t.nivel_avance or "bajo"
    local cumple   = false
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
        return true, "Tutoria cerrada exitosamente"
    else
        local falta = nivel == "alto" and math.max(0, 4 - sesiones)
                                      or math.max(0, 6 - sesiones)
        return false, "Faltan " .. falta .. " sesion(es) para nivel " .. nivel
    end
end

return R
