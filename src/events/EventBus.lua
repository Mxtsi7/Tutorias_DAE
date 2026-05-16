-- EventBus.lua: Bus central de eventos (publicador/suscriptor)
-- Todos los módulos se comunican a través de este archivo

local EventBus = {}
EventBus.listeners = {}

-- Suscribir una función a un tipo de evento
function EventBus.subscribe(eventType, callback)
    -- TODO: agregar callback a la lista de listeners del eventType
end

-- Publicar un evento con datos opcionales
function EventBus.publish(eventType, data)
    -- TODO: recorrer listeners[eventType] y llamar cada callback con data
end

return EventBus
