-- AsignacionHandler.lua: Maneja eventos de asignación y aceptación de tutores

local EventTypes = require("src.events.EventTypes")

local AsignacionHandler = {}

function AsignacionHandler.register(EventBus)
    -- TODO: suscribir a SOLICITUD_VALIDADA
    -- Al recibir: buscar tutor compatible, publicar TUTOR_ASIGNADO o SOLICITUD_EN_ESPERA

    -- TODO: suscribir a TUTOR_RECHAZO
    -- Al recibir: reiniciar búsqueda de tutor

    -- TODO: suscribir a TUTOR_DADO_DE_BAJA
    -- Al recibir: mover tutorías activas a pendiente_reasignacion
end

return AsignacionHandler
