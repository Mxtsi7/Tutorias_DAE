local EventBus = {}
EventBus.listeners = {}

function EventBus.subscribe(eventType, callback)
    if not EventBus.listeners[eventType] then
        EventBus.listeners[eventType] = {}
    end
    table.insert(EventBus.listeners[eventType], callback)
end

function EventBus.publish(eventType, data)
    if EventBus.listeners[eventType] then
        for _, cb in ipairs(EventBus.listeners[eventType]) do
            cb(data)
        end
    end
end

return EventBus
