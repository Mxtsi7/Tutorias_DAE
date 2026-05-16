-- AusenciaHandler.lua: Maneja detección de ausencias consecutivas

local EventTypes = require("src.events.EventTypes")

local AusenciaHandler = {}

function AusenciaHandler.register(EventBus)
    -- TODO: suscribir a SESION_AUSENCIA_INJUST
    -- Al recibir: contar ausencias consecutivas de la tutoría
    -- Si llegan a 2: publicar AUSENCIA_DETECTADA y ALERTA_COORDINADOR
end

return AusenciaHandler
