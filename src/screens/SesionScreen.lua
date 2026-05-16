-- SesionScreen.lua: Pantalla para registrar informes de sesión
-- Vista del Tutor: registrar asistencia, temas y nivel de avance

local SesionScreen = {}

function SesionScreen:load()
    -- TODO: cargar tutoría activa del tutor y sesiones pendientes de registro
end

function SesionScreen:update(dt)
    -- TODO: actualizar contadores de tiempo para alertas de 24 horas
end

function SesionScreen:draw()
    -- TODO: mostrar formulario de informe: fecha, duración, temas, avance, asistencia
end

function SesionScreen:mousepressed(x, y, button)
    -- TODO: detectar envío de informe y publicar SESION_REGISTRADA
end

return SesionScreen
