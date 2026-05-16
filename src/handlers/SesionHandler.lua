-- SesionHandler.lua: Maneja eventos de registro de sesiones

local EventTypes = require("src.events.EventTypes")

local SesionHandler = {}

function SesionHandler.register(EventBus)
    -- TODO: suscribir a SESION_REGISTRADA
    -- Al recibir: actualizar historial de tutoría, calcular nivel de avance

    -- TODO: verificar si el tutor registró dentro de las 24 horas
    -- Si no: publicar ALERTA_TUTOR
    -- Si pasan 48 horas: publicar ALERTA_COORDINADOR
end

return SesionHandler
