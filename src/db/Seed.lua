local DB = require("src.db.DB")

local Seed = {}

function Seed.run()
    if #DB.all("usuarios") > 0 then return end  -- ya tiene datos

    -- Usuarios
    local u1 = DB.insert("usuarios", {nombre="Valentina Torres", rol="estudiante"})
    local u2 = DB.insert("usuarios", {nombre="Diego Ramirez",    rol="estudiante"})
    local u3 = DB.insert("usuarios", {nombre="Sofia Munoz",      rol="estudiante"})
    local u4 = DB.insert("usuarios", {nombre="Roberto Campos",   rol="tutor"})
    local u5 = DB.insert("usuarios", {nombre="Carolina Vega",    rol="tutor"})
    local u6 = DB.insert("usuarios", {nombre="Miguel Fuentes",   rol="tutor"})
    DB.insert("usuarios", {nombre="Coordinador DAE", rol="coordinador"})

    -- Tutores
    local t1 = DB.insert("tutores", {usuario_id=u4, nombre="Roberto Campos",
        areas="Estadistica,Matematicas", disponibilidad="martes,jueves",
        tutorados_activos=2, limite=3, incidentes=0})
    local t2 = DB.insert("tutores", {usuario_id=u5, nombre="Carolina Vega",
        areas="Gestion de Proyectos,Administracion", disponibilidad="lunes,miercoles",
        tutorados_activos=1, limite=3, incidentes=0})
    local t3 = DB.insert("tutores", {usuario_id=u6, nombre="Miguel Fuentes",
        areas="Gestion de Proyectos,Liderazgo", disponibilidad="martes,viernes",
        tutorados_activos=2, limite=3, incidentes=1})

    -- Estudiantes
    local e1 = DB.insert("estudiantes", {usuario_id=u1, nombre="Valentina Torres", area_necesidad="Estadistica Aplicada"})
    local e2 = DB.insert("estudiantes", {usuario_id=u2, nombre="Diego Ramirez",    area_necesidad="Gestion de Proyectos"})
    local e3 = DB.insert("estudiantes", {usuario_id=u3, nombre="Sofia Munoz",       area_necesidad="Comunicacion Oral"})

    -- Tutorias
    DB.insert("tutorias", {
        estudiante_id=e1, tutor_id=t1,
        area="Estadistica Aplicada", estado="activa",
        nivel_avance="medio", sesiones=5, ausencias=0,
        tutor_nombre="Roberto Campos", estudiante_nombre="Valentina Torres",
        area_necesidad="Estadistica Aplicada",
    })
    DB.insert("tutorias", {
        estudiante_id=e2, tutor_id=t3,
        area="Gestion de Proyectos", estado="activa_con_alerta",
        nivel_avance="bajo", sesiones=3, ausencias=1,
        tutor_nombre="Miguel Fuentes", estudiante_nombre="Diego Ramirez",
        area_necesidad="Gestion de Proyectos",
    })
    DB.insert("tutorias", {
        estudiante_id=e3, tutor_id=t2,
        area="Comunicacion Oral", estado="activa",
        nivel_avance="bajo", sesiones=2, ausencias=0,
        tutor_nombre="Carolina Vega", estudiante_nombre="Sofia Munoz",
        area_necesidad="Comunicacion Oral",
    })

    print("[Seed] Datos iniciales insertados.")
end

return Seed
