local Sesion = {}
Sesion.__index = Sesion

function Sesion.new(datos)
    local self = setmetatable({}, Sesion)
    self.fecha        = datos.fecha        or os.date("%Y-%m-%d")
    self.duracion     = datos.duracion     or 0
    self.temas        = datos.temas        or ""
    self.nivel_avance = datos.nivel_avance or "bajo"
    self.asistencia   = datos.asistencia   or "asistio"
    self.estado       = datos.estado       or "programada"
    self.observaciones= datos.observaciones or ""
    self.registrado   = false
    return self
end

function Sesion:registrar(informe)
    self.temas        = informe.temas         or self.temas
    self.nivel_avance = informe.avance        or self.nivel_avance
    self.asistencia   = informe.asistencia    or self.asistencia
    self.duracion     = informe.duracion      or self.duracion
    self.observaciones= informe.observaciones or ""
    self.registrado   = true
    if self.asistencia == "asistio" then
        self.estado = "realizada"
    elseif self.asistencia == "ausencia_justificada" then
        self.estado = "ausencia_justificada"
    elseif self.asistencia == "ausencia_injustificada" then
        self.estado = "ausencia_injustificada"
    end
end

return Sesion
