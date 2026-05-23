local DB = require("src.db.DB")
local R  = {}

function R.crear(usuario_id, area, urgencia, disponibilidad, modalidad)
    local est = DB.find("estudiantes", function(e) return e.usuario_id == usuario_id end)
    local eid = est and est.id or 0
    local id = DB.insert("solicitudes", {
        estudiante_id = eid,
        area          = area,
        urgencia      = urgencia,
        disponibilidad= disponibilidad,
        modalidad     = modalidad,
        estado        = "pendiente",
        fecha         = os.date("%Y-%m-%d"),
    })
    DB.save()
    return id
end

function R.getAll()
    return DB.all("solicitudes")
end

return R
