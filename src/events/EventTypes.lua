-- EventTypes.lua: Constantes de todos los tipos de eventos del sistema

local EventTypes = {
    -- Solicitudes
    SOLICITUD_ENVIADA      = "solicitud_enviada",
    SOLICITUD_VALIDADA     = "solicitud_validada",
    SOLICITUD_RECHAZADA    = "solicitud_rechazada",
    SOLICITUD_EN_ESPERA    = "solicitud_en_espera",

    -- Asignación de tutor
    TUTOR_ASIGNADO         = "tutor_asignado",
    TUTOR_ACEPTO           = "tutor_acepto",
    TUTOR_RECHAZO          = "tutor_rechazo",
    TUTOR_DADO_DE_BAJA     = "tutor_dado_de_baja",

    -- Sesiones
    SESION_REGISTRADA      = "sesion_registrada",
    SESION_AUSENCIA_JUST   = "sesion_ausencia_justificada",
    SESION_AUSENCIA_INJUST = "sesion_ausencia_injustificada",
    SESION_NO_VERIFICABLE  = "sesion_no_verificable",

    -- Ausencias y alertas
    AUSENCIA_DETECTADA     = "ausencia_detectada",
    ALERTA_TUTOR           = "alerta_tutor",
    ALERTA_COORDINADOR     = "alerta_coordinador",

    -- Cierre
    CIERRE_PROPUESTO       = "cierre_propuesto",
    TUTORIA_CERRADA        = "tutoria_cerrada",
    TUTORIA_ABANDONADA     = "tutoria_abandonada",

    -- UI
    PANTALLA_CAMBIAR       = "pantalla_cambiar",
    NOTIFICACION_MOSTRAR   = "notificacion_mostrar",
}

return EventTypes
