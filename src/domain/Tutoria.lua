-- Tutoria.lua: Entidad que representa una tutoría activa
-- Estados: activa, suspendida, pendiente_reasignacion, cerrada_exitosa, cerrada_abandono

local Tutoria = {}
Tutoria.__index = Tutoria

function Tutoria.new(estudiante, tutor)
    -- TODO: inicializar tutoría con estudiante, tutor, fecha_inicio, estado, sesiones=[]
end

function Tutoria:agregarSesion(sesion)
    -- TODO: agregar sesión al historial y actualizar contadores
end

function Tutoria:contarAusenciasConsecutivas()
    -- TODO: recorrer sesiones y contar ausencias injustificadas consecutivas
end

function Tutoria:puedecerrarse()
    -- TODO: verificar condiciones de cierre según nivel de avance
    -- avance alto: mínimo 4 sesiones, avance medio: mínimo 6 sesiones
end

return Tutoria
