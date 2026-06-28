-- areas.lua
-- Catálogo único de áreas académicas del sistema.
-- Todas las referencias (solicitudes.area_id y tutores.areas_competencia)
-- deben usar los 'id' de esta tabla para garantizar matching exacto.

local areas = {
    { id = "matematicas",         label = "Matemáticas" },
    { id = "estadistica",         label = "Estadística" },
    { id = "programacion",        label = "Programación" },
    { id = "base_de_datos",       label = "Base de Datos" },
    { id = "gestion_proyectos",   label = "Gestión de Proyectos" },
    { id = "administracion",      label = "Administración" },
    { id = "contabilidad",        label = "Contabilidad" },
    { id = "comunicacion",        label = "Comunicación" },
    { id = "liderazgo",           label = "Liderazgo" },
    { id = "ingles",              label = "Inglés" },
}

-- Utilidad: obtener label desde id
function areas.getLabel(id)
    for _, a in ipairs(areas) do
        if a.id == id then return a.label end
    end
    return id
end

return areas
