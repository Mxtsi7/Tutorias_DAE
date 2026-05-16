-- tutores.lua: Datos ficticios de tutores para el PMN

local tutores = {
    {
        id = 1,
        nombre = "Roberto Campos",
        areas_competencia = {"Estadística", "Matemáticas"},
        disponibilidad = {"martes", "jueves"},
        tutorados_activos = 2,
        limite = 5,
        incidentes_recientes = 0
    },
    {
        id = 2,
        nombre = "Carolina Vega",
        areas_competencia = {"Gestión de Proyectos", "Administración"},
        disponibilidad = {"lunes", "miércoles"},
        tutorados_activos = 4,
        limite = 5,
        incidentes_recientes = 0
    },
    {
        id = 3,
        nombre = "Miguel Fuentes",
        areas_competencia = {"Gestión de Proyectos", "Liderazgo"},
        disponibilidad = {"martes", "viernes"},
        tutorados_activos = 1,
        limite = 5,
        incidentes_recientes = 0
    },
}

return tutores
