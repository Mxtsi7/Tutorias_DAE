-- AsignacionScreen.lua: Pantalla para gestionar asignación de tutores
-- Vista del Coordinador: ver solicitudes pendientes y asignar tutores

local AsignacionScreen = {}

function AsignacionScreen:load()
    -- TODO: cargar lista de solicitudes pendientes y tutores disponibles
end

function AsignacionScreen:update(dt)
    -- TODO: actualizar lista en tiempo real con eventos recibidos
end

function AsignacionScreen:draw()
    -- TODO: mostrar tabla de solicitudes y panel de tutores elegibles
end

function AsignacionScreen:mousepressed(x, y, button)
    -- TODO: detectar selección de tutor y publicar TUTOR_ASIGNADO
end

return AsignacionScreen
