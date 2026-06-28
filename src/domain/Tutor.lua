-- Tutor.lua
-- Tutor:esElegible() usa comparación exacta entre solicitud.area_id
-- y cada elemento del array areas_competencia del tutor (ids de areas.lua).

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

-- Verifica elegibilidad contra una solicitud.
-- Requiere solicitud.area_id  (id exacto de areas.lua)
-- Usa comparación exacta: no string.find, no lower().
function Tutor:esElegible(solicitud)
    if not self:tieneCupo() then return false end

    -- Matching exacto por area_id
    local areaOk = false
    local areaId = solicitud.area_id or ""
    for _, competencia in ipairs(self.areas_competencia) do
        if competencia == areaId then
            areaOk = true
            break
        end
    end
    if not areaOk then return false end

    -- Matching de disponibilidad (sigue siendo flexible por texto libre)
    local horarioOk = false
    local dispBuscar = string.lower(solicitud.disponibilidad or "")
    for _, dia in ipairs(self.disponibilidad) do
        if string.find(dispBuscar, string.lower(dia)) then
            horarioOk = true
            break
        end
    end
    if not horarioOk then return false end

    if self.incidentes > 1 then return false end
    return true
end

return Tutor
