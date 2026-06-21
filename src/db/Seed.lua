-- Seed.lua  –  datos de prueba para el prototipo DAE 2026
-- Se ejecuta una sola vez al inicializar la app (guard: tabla usuarios vacia).
-- Cubre los 3 actores + los 3 casos del informe MPN.

local DB = require("src.db.DB")

local Seed = {}

function Seed.run()
    -- Guard: si ya hay usuarios, la BD ya fue inicializada
    if #DB.all("usuarios") > 0 then return end

    -- --------------------------------------------------------
    -- USUARIOS  (el login toma el 1er usuario de cada rol)
    -- --------------------------------------------------------
    local u_valentina = DB.insert("usuarios", {nombre="Valentina Torres",  rol="estudiante"})
    local u_ana       = DB.insert("usuarios", {nombre="Ana Garcia",        rol="estudiante"})
    local u_diego     = DB.insert("usuarios", {nombre="Diego Ramirez",     rol="estudiante"})
    local u_sofia     = DB.insert("usuarios", {nombre="Sofia Munoz",       rol="estudiante"})

    local u_roberto   = DB.insert("usuarios", {nombre="Roberto Campos",    rol="tutor"})
    local u_carolina  = DB.insert("usuarios", {nombre="Carolina Vega",     rol="tutor"})
    local u_miguel    = DB.insert("usuarios", {nombre="Miguel Fuentes",    rol="tutor"})
    local u_laura     = DB.insert("usuarios", {nombre="Laura Sepulveda",   rol="tutor"})
    local u_felipe    = DB.insert("usuarios", {nombre="Felipe Ortiz",      rol="tutor"})

    local u_coord     = DB.insert("usuarios", {nombre="Coordinador DAE",   rol="coordinador"})

    -- --------------------------------------------------------
    -- TUTORES
    -- --------------------------------------------------------
    local t_roberto  = DB.insert("tutores", {
        usuario_id=u_roberto,  nombre="Roberto Campos",
        areas="Estadistica,Matematicas,Calculo",
        disponibilidad="martes,jueves",
        tutorados_activos=2, limite=5, incidentes=0,
        activo=true, estado="disponible",
    })
    local t_carolina = DB.insert("tutores", {
        usuario_id=u_carolina, nombre="Carolina Vega",
        areas="Gestion de Proyectos,Administracion,PMO",
        disponibilidad="lunes,miercoles",
        tutorados_activos=1, limite=5, incidentes=0,
        activo=true, estado="disponible",
    })
    local t_miguel   = DB.insert("tutores", {
        usuario_id=u_miguel,   nombre="Miguel Fuentes",
        areas="Gestion de Proyectos,Liderazgo",
        disponibilidad="martes,viernes",
        tutorados_activos=2, limite=5, incidentes=1,
        activo=true, estado="disponible",
    })
    local t_laura    = DB.insert("tutores", {
        usuario_id=u_laura,    nombre="Laura Sepulveda",
        areas="Comunicacion Oral,Habilidades Blandas",
        disponibilidad="lunes,jueves,viernes",
        tutorados_activos=0, limite=5, incidentes=0,
        activo=true, estado="disponible",
    })
    local t_felipe   = DB.insert("tutores", {
        usuario_id=u_felipe,   nombre="Felipe Ortiz",
        areas="Comunicacion Oral,Presentaciones",
        disponibilidad="miercoles,viernes",
        tutorados_activos=0, limite=5, incidentes=0,
        activo=false, estado="inactivo",
    })

    -- --------------------------------------------------------
    -- ESTUDIANTES
    -- --------------------------------------------------------
    local e_valentina = DB.insert("estudiantes", {
        usuario_id=u_valentina, nombre="Valentina Torres",
        area_necesidad="Estadistica Aplicada",
    })
    local e_ana       = DB.insert("estudiantes", {
        usuario_id=u_ana,       nombre="Ana Garcia",
        area_necesidad="Estadistica Aplicada",
    })
    local e_diego     = DB.insert("estudiantes", {
        usuario_id=u_diego,     nombre="Diego Ramirez",
        area_necesidad="Gestion de Proyectos",
    })
    local e_sofia     = DB.insert("estudiantes", {
        usuario_id=u_sofia,     nombre="Sofia Munoz",
        area_necesidad="Comunicacion Oral",
    })

    -- --------------------------------------------------------
    -- CASO 1: Flujo ideal  –  Valentina + Roberto
    -- 8 sesiones realizadas, progresion bajo->medio->alto
    -- --------------------------------------------------------
    local tut1 = DB.insert("tutorias", {
        estudiante_id=e_valentina, tutor_id=t_roberto,
        tutor_nombre="Roberto Campos", estudiante_nombre="Valentina Torres",
        area="Estadistica Aplicada", area_necesidad="Estadistica Aplicada",
        estado="activa", nivel_avance="alto",
        sesiones=8, ausencias=0,
        fecha_inicio="2026-04-14",
        advertencia_formal=false, alerta_avance_bajo=false,
        historial_avance={"bajo","bajo","medio","medio","medio","medio","alto","alto"},
    })
    local sesiones_c1 = {
        {"2026-04-17","Estadistica descriptiva",              "bajo",  "presente",60},
        {"2026-04-24","Medidas de tendencia central",          "bajo",  "presente",60},
        {"2026-05-06","Varianza y desviacion estandar",        "medio", "presente",75},
        {"2026-05-13","Probabilidad condicional",              "medio", "presente",75},
        {"2026-05-20","Distribucion normal",                  "medio", "presente",75},
        {"2026-05-27","Intervalos de confianza",               "medio", "presente",75},
        {"2026-06-03","Prueba de hipotesis t-Student",         "alto",  "presente",90},
        {"2026-06-10","Regresion lineal y correlacion",        "alto",  "presente",90},
    }
    for _, s in ipairs(sesiones_c1) do
        DB.insert("sesiones", {
            tutoria_id=tut1, fecha=s[1], temas=s[2],
            nivel_avance=s[3], asistencia=s[4], duracion_min=s[5], registrada=true,
        })
    end
    DB.insert("solicitudes", {
        estudiante_id=e_valentina, estudiante_nombre="Valentina Torres",
        area="Estadistica Aplicada", urgencia="alta",
        disponibilidad="martes y jueves tarde", modalidad="remota",
        estado="asignada", fecha_solicitud="2026-04-10",
    })

    -- --------------------------------------------------------
    -- CASO 2: Error intermedio  –  Diego + Miguel
    -- 2 ausencias injustificadas -> activa_con_alerta
    -- --------------------------------------------------------
    local tut2 = DB.insert("tutorias", {
        estudiante_id=e_diego, tutor_id=t_miguel,
        tutor_nombre="Miguel Fuentes", estudiante_nombre="Diego Ramirez",
        area="Gestion de Proyectos", area_necesidad="Gestion de Proyectos",
        estado="activa_con_alerta", nivel_avance="medio",
        sesiones=4, ausencias=2, ausencias_consec=2,
        fecha_inicio="2026-04-21",
        advertencia_formal=false, alerta_avance_bajo=false,
        historial_avance={"medio","medio","ausente","ausente"},
    })
    local sesiones_c2 = {
        {"2026-04-24","Fundamentos PMI",        "medio","presente",             60},
        {"2026-05-01","Ciclo de vida",           "medio","presente",             60},
        {"2026-05-08","Gestion de riesgos",      "bajo", "ausente_injustificada",60},
        {"2026-05-15","Gestion de stakeholders", "bajo", "ausente_injustificada",60},
    }
    for _, s in ipairs(sesiones_c2) do
        DB.insert("sesiones", {
            tutoria_id=tut2, fecha=s[1], temas=s[2],
            nivel_avance=s[3], asistencia=s[4], duracion_min=s[5], registrada=true,
        })
    end
    DB.insert("solicitudes", {
        estudiante_id=e_diego, estudiante_nombre="Diego Ramirez",
        area="Gestion de Proyectos", urgencia="media",
        disponibilidad="martes y viernes manana", modalidad="presencial",
        estado="asignada", fecha_solicitud="2026-04-17",
    })

    -- --------------------------------------------------------
    -- CASO 3: Falla critica  –  Sofia + Felipe (dado de baja)
    -- Tutoria en pendiente_reasignacion
    -- --------------------------------------------------------
    local tut3 = DB.insert("tutorias", {
        estudiante_id=e_sofia, tutor_id=t_felipe,
        tutor_nombre="Felipe Ortiz", estudiante_nombre="Sofia Munoz",
        area="Comunicacion Oral", area_necesidad="Comunicacion Oral",
        estado="pendiente_reasignacion", nivel_avance="bajo",
        sesiones=3, ausencias=0,
        tutor_anterior=t_felipe,
        fecha_inicio="2026-04-28",
        advertencia_formal=false, alerta_avance_bajo=true,
        historial_avance={"bajo","bajo","bajo"},
    })
    for _, s in ipairs({
        {"2026-05-05","Estructura de presentacion oral","bajo","presente",60},
        {"2026-05-12","Tecnicas de voz",               "bajo","presente",60},
        {"2026-05-19","Manejo del nerviosismo",         "bajo","presente",60},
    }) do
        DB.insert("sesiones", {
            tutoria_id=tut3, fecha=s[1], temas=s[2],
            nivel_avance=s[3], asistencia=s[4], duracion_min=s[5], registrada=true,
        })
    end
    DB.insert("solicitudes", {
        estudiante_id=e_sofia, estudiante_nombre="Sofia Munoz",
        area="Comunicacion Oral", urgencia="alta",
        disponibilidad="lunes y viernes tarde", modalidad="presencial",
        estado="asignada", fecha_solicitud="2026-04-24",
    })

    -- --------------------------------------------------------
    -- FLUJO LIMPIO  –  Ana Garcia
    -- Solicitud pendiente para demostrar el flujo completo en vivo
    -- --------------------------------------------------------
    DB.insert("solicitudes", {
        estudiante_id=e_ana, estudiante_nombre="Ana Garcia",
        area="Estadistica Aplicada", urgencia="alta",
        disponibilidad="lunes y miercoles tarde", modalidad="remota",
        estado="pendiente", fecha_solicitud="2026-06-18",
    })

    print("[Seed] BD SQLite inicializada: 3 casos MPN + flujo limpio Ana Garcia.")
end

return Seed
