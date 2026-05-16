-- Sesion.lua: Entidad que representa cada sesión registrada
-- Estados: programada, realizada, ausencia_justificada, ausencia_injustificada, no_verificable

local Sesion = {}
Sesion.__index = Sesion

function Sesion.new(datos)
    -- TODO: crear sesión con fecha, duracion, temas, nivel_avance, asistencia, estado
end

function Sesion:registrar(informe)
    -- TODO: registrar informe del tutor dentro de las 24 horas
end

return Sesion
