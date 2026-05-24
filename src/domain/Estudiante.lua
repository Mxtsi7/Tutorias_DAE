local Estudiante = {}
Estudiante.__index = Estudiante

function Estudiante.new(datos)
    local self = setmetatable({}, Estudiante)
    self.id               = datos.id               or 0
    self.nombre           = datos.nombre           or ""
    self.perfil_academico = datos.perfil_academico or ""
    self.area_necesidad   = datos.area_necesidad   or ""
    self.nivel_avance     = datos.nivel_avance     or "bajo"
    return self
end

return Estudiante
