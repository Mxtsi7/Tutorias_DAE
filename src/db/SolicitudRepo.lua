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
    local all = DB.all("solicitudes")
    -- enriquecer con nombre del estudiante
    for _,sol in ipairs(all) do
        if not sol.estudiante_nombre then
            local est = DB.find("estudiantes", function(e) return e.id == sol.estudiante_id end)
            if est then
                local usr = DB.find("usuarios", function(u) return u.id == est.usuario_id end)
                sol.estudiante_nombre = usr and usr.nombre or "\xe2\x80\x94"
            else
                sol.estudiante_nombre = "\xe2\x80\x94"
            end
        end
    end
    return all
end

function R.getByEstudiante(usuario_id)
    local est = DB.find("estudiantes", function(e) return e.usuario_id == usuario_id end)
    if not est then return {} end
    return DB.where("solicitudes", function(s) return s.estudiante_id == est.id end)
end

return R
