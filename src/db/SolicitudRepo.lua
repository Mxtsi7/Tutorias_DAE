-- Repositorio de solicitudes
local DB = require("src.db.DB")

local R = {}

function R.crear(estudiante_usuario_id, area, urgencia, disponibilidad, modalidad)
    -- obtener estudiante_id
    local rows = DB.query("SELECT id FROM estudiantes WHERE usuario_id=?", {estudiante_usuario_id})
    local eid = rows[1] and rows[1].id or 1
    local fecha = os.date("%Y-%m-%d")
    DB.query(
        "INSERT INTO solicitudes(estudiante_id,area,urgencia,disponibilidad,modalidad,estado,fecha) VALUES(?,?,?,?,?,'pendiente',?)",
        {eid, area, urgencia, disponibilidad, modalidad, fecha}
    )
    return DB.lastId()
end

function R.getAll()
    return DB.query([[
        SELECT s.*, e.nombre as estudiante_nombre
        FROM solicitudes s
        JOIN estudiantes e ON e.id = s.estudiante_id
        ORDER BY s.id DESC
    ]])
end

return R
