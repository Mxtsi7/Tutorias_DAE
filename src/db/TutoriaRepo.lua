-- Repositorio de tutorias
local DB = require("src.db.DB")

local R = {}

-- Todas las tutorias (con datos de estudiante y tutor)
function R.getAll()
    return DB.query([[
        SELECT t.*, e.nombre as estudiante_nombre, e.area_necesidad,
               tu.nombre as tutor_nombre
        FROM tutorias t
        JOIN estudiantes e  ON e.id = t.estudiante_id
        JOIN tutores tu      ON tu.id = t.tutor_id
        ORDER BY t.id
    ]])
end

-- Tutorias de un estudiante por usuario_id
function R.getByEstudiante(usuario_id)
    return DB.query([[
        SELECT t.*, tu.nombre as tutor_nombre
        FROM tutorias t
        JOIN estudiantes e ON e.id = t.estudiante_id
        JOIN tutores tu     ON tu.id = t.tutor_id
        WHERE e.usuario_id = ?
        ORDER BY t.id
    ]], {usuario_id})
end

-- Actualiza nivel_avance y sesiones_realizadas
function R.registrarSesion(tutoria_id, avance, asistencia)
    -- actualizar ausencias_consecutivas segun asistencia
    local ausencias_delta = 0
    if asistencia == "Ausencia injust." then
        ausencias_delta = 1
    end

    -- leer estado actual
    local rows = DB.query("SELECT ausencias_consecutivas, sesiones_realizadas FROM tutorias WHERE id=?", {tutoria_id})
    if #rows == 0 then return end
    local cur = rows[1]

    local nuevas_aus = asistencia == "Asistio" and 0
                    or asistencia == "Ausencia just." and cur.ausencias_consecutivas
                    or cur.ausencias_consecutivas + 1

    local nuevo_estado = "activa"
    if nuevas_aus >= 3 then nuevo_estado = "suspendida"
    elseif nuevas_aus >= 1 then nuevo_estado = "activa_con_alerta" end

    local nuevas_ses = asistencia == "Asistio" and cur.sesiones_realizadas + 1 or cur.sesiones_realizadas

    DB.exec(string.format(
        "UPDATE tutorias SET nivel_avance_actual='%s', sesiones_realizadas=%d, ausencias_consecutivas=%d, estado='%s' WHERE id=%d",
        avance, nuevas_ses, nuevas_aus, nuevo_estado, tutoria_id
    ))
end

-- Asignar tutor a una tutoria existente o crear nueva
function R.asignarTutor(tutoria_id, tutor_id)
    DB.exec(string.format("UPDATE tutorias SET tutor_id=%d WHERE id=%d", tutor_id, tutoria_id))
    DB.exec(string.format("UPDATE tutores SET tutorados_activos=tutorados_activos+1 WHERE id=%d", tutor_id))
end

return R
