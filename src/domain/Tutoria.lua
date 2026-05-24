local Tutoria = {}
Tutoria.__index = Tutoria

function Tutoria.new(estudiante, tutor)
    local self = setmetatable({}, Tutoria)
    self.estudiante   = estudiante
    self.tutor        = tutor
    self.fecha_inicio = os.date("%Y-%m-%d")
    self.estado       = "activa"
    self.sesiones     = {}
    self.ausencias_consecutivas = 0
    self.nivel_avance = "bajo"
    return self
end

function Tutoria:agregarSesion(sesion)
    self.sesiones[#self.sesiones+1] = sesion
    if sesion.avance then self.nivel_avance = sesion.avance end
    if sesion.asistencia == "ausencia_injustificada" then
        self.ausencias_consecutivas = self.ausencias_consecutivas + 1
    elseif sesion.asistencia == "asistio" then
        self.ausencias_consecutivas = 0
    end
    if self.ausencias_consecutivas >= 2 then
        self.estado = "activa_con_alerta"
    end
end

function Tutoria:contarAusenciasConsecutivas()
    local count = 0
    for i = #self.sesiones, 1, -1 do
        local s = self.sesiones[i]
        if s.asistencia == "ausencia_injustificada" then
            count = count + 1
        else
            break
        end
    end
    return count
end

function Tutoria:puedeCerrarse()
    local total = #self.sesiones
    local nivel = self.nivel_avance
    if nivel == "alto"  and total >= 4 then return true end
    if nivel == "medio" and total >= 6 then return true end
    return false
end

return Tutoria
