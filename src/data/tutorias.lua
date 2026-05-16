-- tutorias.lua: Datos ficticios de tutorías activas para el PMN

local tutorias = {
    {
        id = 1,
        estudiante_id = 1,
        tutor_id = 1,
        estado = "activa",
        fecha_inicio = "2026-04-01",
        sesiones_realizadas = 6,
        nivel_avance_actual = "medio",
        ausencias_consecutivas = 0
    },
    {
        id = 2,
        estudiante_id = 2,
        tutor_id = 3,
        estado = "activa_con_alerta",
        fecha_inicio = "2026-04-10",
        sesiones_realizadas = 3,
        nivel_avance_actual = "bajo",
        ausencias_consecutivas = 1
    },
}

return tutorias
