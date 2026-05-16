-- Solicitud.lua: Entidad que representa una solicitud de tutoría
-- Estados posibles: borrador, pendiente, en_espera, asignada, retirada

local Solicitud = {}
Solicitud.__index = Solicitud

function Solicitud.new(datos)
    -- TODO: crear nueva solicitud con campos:
    -- area_tematica, nivel_urgencia, disponibilidad, modalidad, estado
end

function Solicitud:validar()
    -- TODO: verificar que los 4 campos obligatorios estén completos
    -- retornar true/false y lista de campos faltantes
end

function Solicitud:cambiarEstado(nuevoEstado)
    -- TODO: actualizar self.estado y registrar timestamp del cambio
end

return Solicitud
