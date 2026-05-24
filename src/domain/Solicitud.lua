local Solicitud = {}
Solicitud.__index = Solicitud

function Solicitud.new(datos)
    local self = setmetatable({}, Solicitud)
    self.area_tematica   = datos.area_tematica   or ""
    self.nivel_urgencia  = datos.nivel_urgencia  or ""
    self.disponibilidad  = datos.disponibilidad  or ""
    self.modalidad       = datos.modalidad       or ""
    self.estado          = datos.estado          or "borrador"
    self.historial       = {}
    self.fecha_creacion  = os.date("%Y-%m-%d")
    return self
end

function Solicitud:validar()
    local faltantes = {}
    if self.area_tematica  == "" then faltantes[#faltantes+1] = "area_tematica"  end
    if self.nivel_urgencia == "" then faltantes[#faltantes+1] = "nivel_urgencia" end
    if self.disponibilidad == "" then faltantes[#faltantes+1] = "disponibilidad" end
    if self.modalidad      == "" then faltantes[#faltantes+1] = "modalidad"      end
    return #faltantes == 0, faltantes
end

function Solicitud:cambiarEstado(nuevoEstado)
    local anterior = self.estado
    self.estado = nuevoEstado
    self.historial[#self.historial+1] = {
        de = anterior, a = nuevoEstado, when = os.date("%Y-%m-%d %H:%M:%S"),
    }
end

return Solicitud
