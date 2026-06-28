-- SolicitudRepo.lua
-- crear() ahora acepta descripcion y area_id además de los campos originales.
local DB = require("src.db.DB")
local R  = {}

local URGENCIAS_VALIDAS = { alta=true, media=true, baja=true }

-- Valida campos obligatorios. area_id obligatorio; area (label) es opcional.
function R.validar(area_id, urgencia, disponibilidad, descripcion)
    local errores = {}
    if not area_id or area_id == "" then
        errores.area_id = "Debes seleccionar un área"
    end
    if not urgencia or urgencia == "" then
        errores.urgencia = "El nivel de urgencia es obligatorio"
    elseif not URGENCIAS_VALIDAS[string.lower(urgencia)] then
        errores.urgencia = "Urgencia debe ser: alta, media o baja"
    end
    if not disponibilidad or disponibilidad == "" then
        errores.disponibilidad = "La disponibilidad horaria es obligatoria"
    end
    if not descripcion or descripcion == "" then
        errores.descripcion = "Describe brevemente lo que necesitas"
    end
    local ok = next(errores) == nil
    return ok, errores
end

-- Crea la solicitud con descripcion libre + area_id para matching.
function R.crear(usuario_id, area_id, area_label, descripcion, urgencia, disponibilidad, modalidad)
    local est = DB.find("estudiantes", function(e) return e.usuario_id == usuario_id end)
    local eid = est and est.id or 0

    local ok, errores = R.validar(area_id, urgencia, disponibilidad, descripcion)
    local estado = ok and "pendiente" or "borrador"

    local id = DB.insert("solicitudes", {
        estudiante_id  = eid,
        area_id        = area_id,
        area           = area_label or area_id,   -- label legible para vistas
        descripcion    = descripcion,
        urgencia       = urgencia       or "",
        disponibilidad = disponibilidad or "",
        modalidad      = modalidad      or "",
        estado         = estado,
        fecha          = os.date("%Y-%m-%d"),
        errores_campo  = not ok and errores or nil,
    })
    DB.save()
    return id, ok, errores
end

-- Permite corregir y reenviar una solicitud en borrador
function R.corregir(solicitud_id, area_id, area_label, descripcion, urgencia, disponibilidad, modalidad)
    local sol = DB.find("solicitudes", function(s) return s.id == solicitud_id end)
    if not sol then return false, {}, "Solicitud no encontrada" end
    if sol.estado ~= "borrador" then return false, {}, "Solo se pueden corregir solicitudes en borrador" end

    local ok, errores = R.validar(area_id, urgencia, disponibilidad, descripcion)
    sol.area_id        = area_id
    sol.area           = area_label or area_id
    sol.descripcion    = descripcion
    sol.urgencia       = urgencia
    sol.disponibilidad = disponibilidad
    sol.modalidad      = modalidad
    sol.estado         = ok and "pendiente" or "borrador"
    sol.errores_campo  = not ok and errores or nil
    DB.save()
    return ok, errores
end

function R.retirar(solicitud_id)
    local sol = DB.find("solicitudes", function(s) return s.id == solicitud_id end)
    if not sol then return false, "Solicitud no encontrada" end
    if sol.estado == "asignada" or sol.estado == "borrador" then
        return false, "No se puede retirar una solicitud en estado: " .. sol.estado
    end
    sol.estado = "retirada"
    DB.save()
    return true, "Solicitud retirada"
end

function R.getAll()
    local all = DB.all("solicitudes")
    for _, sol in ipairs(all) do
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
