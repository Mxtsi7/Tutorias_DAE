-- Alert.lua: Componente de alerta/notificación temporal en pantalla
-- Aparece automáticamente al recibir eventos de alerta del EventBus

local Alert = {}
Alert.__index = Alert

function Alert.new(mensaje, tipo)
    -- TODO: crear alerta con mensaje, tipo (info/warning/error) y timer de duración
end

function Alert:update(dt)
    -- TODO: reducir timer y marcar como expirada cuando llega a 0
end

function Alert:draw()
    -- TODO: dibujar notificación con color según tipo y animación de aparición
end

return Alert
