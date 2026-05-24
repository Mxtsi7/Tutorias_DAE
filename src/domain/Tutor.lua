local Tutor = {}
Tutor.__index = Tutor

function Tutor.new(datos)
    local self = setmetatable({}, Tutor)
    self.id                = datos.id                or 0
    self.nombre            = datos.nombre            or ""
    self.areas_competencia = datos.areas_competencia or {}
    self.disponibilidad    = datos.disponibilidad    or {}
    self.tutorados_activos = datos.tutorados_activos or 0
    self.limite            = datos.limite            or 5
    self.incidentes        = datos.incidentes        or 0
    return self
end

function Tutor:tieneCupo()
    return self.tutorados_activos < self.limite
end

function Tutor:esElegible(solicitud)
    if not self:tieneCupo() then return false end
    local areaOk = false
    local areaBuscar = string.lower(solicitud.area_tematica or solicitud.area or "")
    for _, area in ipairs(self.areas_competencia) do
        if string.find(string.lower(area), areaBuscar) or
           string.find(areaBuscar, string.lower(area)) then
            areaOk = true break
        end
    end
    if not areaOk then return false end
    local horarioOk = false
    local dispBuscar = string.lower(solicitud.disponibilidad or "")
    for _, dia in ipairs(self.disponibilidad) do
        if string.find(dispBuscar, string.lower(dia)) then
            horarioOk = true break
        end
    end
    if not horarioOk then return false end
    if self.incidentes > 1 then return false end
    return true
end

return Tutor
