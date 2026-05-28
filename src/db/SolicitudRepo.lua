local DB = require("src.db.DB")
local R  = {}

-- Valores válidos por campo
local MODALIDADES_VALIDAS = { remota=true, presencial=true }
local URGENCIAS_VALIDAS   = { alta=true, media=true, baja=true }

-- Valida los 4 campos obligatorios. Retorna ok, tabla de errores por campo
function R.validar(area, urgencia, disponibilidad, modalidad)
    local errores = {}
    if not area or area == "" then
        errores.area = "El área temática es obligatoria"
    end
    if not urgencia or urgencia == "" then
        errores.urgencia = "El nivel de urgencia es obligatorio"
    elseif not URGENCIAS_VALIDAS[string.lower(urgencia)] then
        errores.urgencia = "Urgencia debe ser: alta, media o baja"
    end
    if not disponibilidad or disponibilidad == "" then
        errores.disponibilidad = "La disponibilidad horaria es obligatoria"
    end
    if not modalidad or modalidad == "" then
        errores.modalidad = "La modalidad preferida es obligatoria"
    elseif not MODALIDADES_VALIDAS[string.lower(modalidad)] then
        errores.modalidad = "Modalidad debe ser: remota o presencial"
    end
    local ok = next(errores) == nil
    return ok, errores
end

-- Crea la solicitud. Si los datos son inválidos la guarda como "borrador" con errores.
function R.crear(usuario_id, area, urgencia, disponibilidad, modalidad)
    local est = DB.find("estudiantes", function(e) return e.usuario_id == usuario_id end)
    local eid = est and est.id or 0

    local ok, errores = R.validar(area, urgencia, disponibilidad, modalidad)
    local estado = ok and "pendiente" or "borrador"

    local id = DB.insert("solicitudes", {
        estudiante_id  = eid,
        area           = area,
        urgencia       = urgencia,
        disponibilidad = disponibilidad,
        modalidad      = modalidad,
        estado         = estado,
        fecha          = os.date("%Y-%m-%d"),
        errores_campo  = not ok and errores or nil,
    })
    DB.save()
    return id, ok, errores
end

-- Permite corregir y reenviar una solicitud en borrador
function R.corregir(solicitud_id, area, urgencia, disponibilidad, modalidad)
    local sol = DB.find("solicitudes", function(s) return s.id == solicitud_id end)
    if not sol then return false, {}, "Solicitud no encontrada" end
    if sol.estado ~= "borrador" then return false, {}, "Solo se pueden corregir solicitudes en borrador" end

    local ok, errores = R.validar(area, urgencia, disponibilidad, modalidad)
    sol.area           = area
    sol.urgencia       = urgencia
    sol.disponibilidad = disponibilidad
    sol.modalidad      = modalidad
    sol.estado         = ok and "pendiente" or "borrador"
    sol.errores_campo  = not ok and errores or nil
    DB.save()
    return ok, errores
end

-- Retiro voluntario de solicitud (estado pendiente o en_espera)
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
