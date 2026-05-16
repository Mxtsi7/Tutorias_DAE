-- Tutor.lua: Entidad que representa al tutor/mentor
-- Regla de negocio: máximo 5 tutorados activos simultáneos

local Tutor = {}
Tutor.__index = Tutor

function Tutor.new(datos)
    -- TODO: crear tutor con nombre, areas_competencia, disponibilidad, tutorados_activos=0, limite=5
end

function Tutor:tieneCupo()
    -- TODO: retornar true si tutorados_activos < limite
end

function Tutor:esElegible(solicitud)
    -- TODO: verificar las 4 condiciones: perfil, horario, cupo disponible, sin incidentes recientes
end

return Tutor
