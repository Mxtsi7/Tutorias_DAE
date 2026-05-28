local EventTypes = {
    SOLICITUD_ENVIADA      = "solicitud_enviada",
    SOLICITUD_VALIDADA     = "solicitud_validada",
    SOLICITUD_RECHAZADA    = "solicitud_rechazada",
    SOLICITUD_EN_ESPERA    = "solicitud_en_espera",
    ASIGNACION_PROPUESTA   = "asignacion_propuesta",   -- fase1: propuesta enviada al tutor
    VERIFICAR_TACITOS      = "verificar_tacitos",       -- fase1: detectar rechazos tácitos 48h
    TUTOR_ASIGNADO         = "tutor_asignado",
    TUTOR_ACEPTO           = "tutor_acepto",
    TUTOR_RECHAZO          = "tutor_rechazo",
    TUTOR_DADO_DE_BAJA     = "tutor_dado_de_baja",
    SESION_REGISTRADA      = "sesion_registrada",
    SESION_AUSENCIA_JUST   = "sesion_ausencia_justificada",
    SESION_AUSENCIA_INJUST = "sesion_ausencia_injustificada",
    AUSENCIA_DETECTADA     = "ausencia_detectada",
    ALERTA_COORDINADOR     = "alerta_coordinador",
    CIERRE_PROPUESTO       = "cierre_propuesto",
    TUTORIA_CERRADA        = "tutoria_cerrada",
    PANTALLA_CAMBIAR       = "pantalla_cambiar",
    NOTIFICACION_MOSTRAR   = "notificacion_mostrar",
}
return EventTypes
