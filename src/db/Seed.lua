-- Seed: inserta datos iniciales solo si la BD esta vacia
local DB = require("src.db.DB")

local Seed = {}

function Seed.run()
    local rows = DB.query("SELECT COUNT(*) as n FROM usuarios")
    if rows[1] and rows[1].n > 0 then return end  -- ya tiene datos

    DB.exec("BEGIN TRANSACTION")

    -- Usuarios
    DB.exec("INSERT INTO usuarios(nombre,rol) VALUES('Valentina Torres','estudiante')")
    local uid_val = DB.lastId()
    DB.exec("INSERT INTO usuarios(nombre,rol) VALUES('Diego Ramirez','estudiante')")
    local uid_diego = DB.lastId()
    DB.exec("INSERT INTO usuarios(nombre,rol) VALUES('Sofia Munoz','estudiante')")
    local uid_sofia = DB.lastId()
    DB.exec("INSERT INTO usuarios(nombre,rol) VALUES('Roberto Campos','tutor')")
    local uid_rob = DB.lastId()
    DB.exec("INSERT INTO usuarios(nombre,rol) VALUES('Carolina Vega','tutor')")
    local uid_car = DB.lastId()
    DB.exec("INSERT INTO usuarios(nombre,rol) VALUES('Miguel Fuentes','tutor')")
    local uid_mig = DB.lastId()
    DB.exec("INSERT INTO usuarios(nombre,rol) VALUES('Coordinador DAE','coordinador')")
    local uid_coord = DB.lastId()

    -- Tutores
    DB.exec(string.format(
        "INSERT INTO tutores(usuario_id,nombre,areas_competencia,disponibilidad,tutorados_activos,limite,incidentes_recientes) VALUES(%d,'Roberto Campos','Estadistica,Matematicas','martes,jueves',2,3,0)",
        uid_rob))
    local tid1 = DB.lastId()
    DB.exec(string.format(
        "INSERT INTO tutores(usuario_id,nombre,areas_competencia,disponibilidad,tutorados_activos,limite,incidentes_recientes) VALUES(%d,'Carolina Vega','Gestion de Proyectos,Administracion','lunes,miercoles',1,3,0)",
        uid_car))
    local tid2 = DB.lastId()
    DB.exec(string.format(
        "INSERT INTO tutores(usuario_id,nombre,areas_competencia,disponibilidad,tutorados_activos,limite,incidentes_recientes) VALUES(%d,'Miguel Fuentes','Gestion de Proyectos,Liderazgo','martes,viernes',2,3,1)",
        uid_mig))
    local tid3 = DB.lastId()

    -- Estudiantes
    DB.exec(string.format("INSERT INTO estudiantes(usuario_id,nombre,area_necesidad) VALUES(%d,'Valentina Torres','Estadistica Aplicada')", uid_val))
    local eid1 = DB.lastId()
    DB.exec(string.format("INSERT INTO estudiantes(usuario_id,nombre,area_necesidad) VALUES(%d,'Diego Ramirez','Gestion de Proyectos')", uid_diego))
    local eid2 = DB.lastId()
    DB.exec(string.format("INSERT INTO estudiantes(usuario_id,nombre,area_necesidad) VALUES(%d,'Sofia Munoz','Comunicacion Oral')", uid_sofia))
    local eid3 = DB.lastId()

    -- Tutorias
    DB.exec(string.format(
        "INSERT INTO tutorias(estudiante_id,tutor_id,area,estado,nivel_avance_actual,sesiones_realizadas,ausencias_consecutivas,fecha_inicio) VALUES(%d,%d,'Estadistica Aplicada','activa','medio',5,0,'2026-03-10')",
        eid1, tid1))
    DB.exec(string.format(
        "INSERT INTO tutorias(estudiante_id,tutor_id,area,estado,nivel_avance_actual,sesiones_realizadas,ausencias_consecutivas,fecha_inicio) VALUES(%d,%d,'Gestion de Proyectos','activa_con_alerta','bajo',3,1,'2026-03-15')",
        eid2, tid3))
    DB.exec(string.format(
        "INSERT INTO tutorias(estudiante_id,tutor_id,area,estado,nivel_avance_actual,sesiones_realizadas,ausencias_consecutivas,fecha_inicio) VALUES(%d,%d,'Comunicacion Oral','activa','bajo',2,0,'2026-04-01')",
        eid3, tid2))

    DB.exec("COMMIT")
    print("[Seed] Datos iniciales insertados correctamente.")
end

return Seed
