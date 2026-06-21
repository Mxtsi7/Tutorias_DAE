local DB = require("src.db.DB")

local Seed = {}

-- ============================================================
-- SEED DE DATOS DE PRUEBA  –  Grupo 29 DAE 2026
-- Cubre los 3 casos del informe MPN más un flujo limpio.
--
-- Caso 1 (Flujo ideal)   : Valentina Torres  + Roberto Campos
--   8 sesiones con progresión bajo→medio→alto, listo para cierre.
-- Caso 2 (Error intermedio): Diego Ramírez   + Miguel Fuentes
--   2 ausencias injustificadas consecutivas → activa_con_alerta.
-- Caso 3 (Falla crítica) : Sofía Muñoz      + Felipe (dado de baja)
--   Tutoría en pendiente_reasignacion. Reasignar a Laura.
-- Extra (Flujo limpio)   : Ana García        → solicitud pendiente
--   Para demostrar: envío de solicitud → propuesta coordinador
--   → aceptación tutor (48h) → tutoría activa.
-- ============================================================

function Seed.run()
    if #DB.all("usuarios") > 0 then return end

    -- ----------------------------------------------------------
    -- USUARIOS  (login por rol: toma el primero de cada tipo)
    -- ----------------------------------------------------------
    -- Estudiantes
    local u_valentina = DB.insert("usuarios", {nombre="Valentina Torres",  rol="estudiante"})
    local u_diego     = DB.insert("usuarios", {nombre="Diego Ramirez",     rol="estudiante"})
    local u_sofia     = DB.insert("usuarios", {nombre="Sofia Munoz",       rol="estudiante"})
    local u_ana       = DB.insert("usuarios", {nombre="Ana Garcia",        rol="estudiante"})
    -- Tutores
    local u_roberto   = DB.insert("usuarios", {nombre="Roberto Campos",    rol="tutor"})
    local u_carolina  = DB.insert("usuarios", {nombre="Carolina Vega",     rol="tutor"})
    local u_miguel    = DB.insert("usuarios", {nombre="Miguel Fuentes",    rol="tutor"})
    local u_laura     = DB.insert("usuarios", {nombre="Laura Sepulveda",   rol="tutor"})
    local u_felipe    = DB.insert("usuarios", {nombre="Felipe Ortiz",      rol="tutor"})
    -- Coordinador
    local u_coord     = DB.insert("usuarios", {nombre="Coordinador DAE",   rol="coordinador"})

    -- ----------------------------------------------------------
    -- TUTORES
    -- ----------------------------------------------------------
    -- Roberto: elegible, área Estadística, 2/5 tutorados, 0 incidentes
    local t_roberto  = DB.insert("tutores", {
        usuario_id        = u_roberto,
        nombre            = "Roberto Campos",
        areas             = "Estadistica,Matematicas,Calculo",
        disponibilidad    = "martes,jueves",
        tutorados_activos = 2,
        limite            = 5,
        incidentes        = 0,
        activo            = true,
        estado            = "disponible",
    })
    -- Carolina: elegible, área Gestión, 1/5 tutorados
    local t_carolina = DB.insert("tutores", {
        usuario_id        = u_carolina,
        nombre            = "Carolina Vega",
        areas             = "Gestion de Proyectos,Administracion,PMO",
        disponibilidad    = "lunes,miercoles",
        tutorados_activos = 1,
        limite            = 5,
        incidentes        = 0,
        activo            = true,
        estado            = "disponible",
    })
    -- Miguel: elegible, 1 incidente (dentro del límite), área Gestión
    local t_miguel   = DB.insert("tutores", {
        usuario_id        = u_miguel,
        nombre            = "Miguel Fuentes",
        areas             = "Gestion de Proyectos,Liderazgo",
        disponibilidad    = "martes,viernes",
        tutorados_activos = 2,
        limite            = 5,
        incidentes        = 1,
        activo            = true,
        estado            = "disponible",
    })
    -- Laura: elegible, 0 incidentes, disponible para reasignación Caso 3
    local t_laura    = DB.insert("tutores", {
        usuario_id        = u_laura,
        nombre            = "Laura Sepulveda",
        areas             = "Comunicacion Oral,Habilidades Blandas",
        disponibilidad    = "lunes,jueves,viernes",
        tutorados_activos = 0,
        limite            = 5,
        incidentes        = 0,
        activo            = true,
        estado            = "disponible",
    })
    -- Felipe: DADO DE BAJA (Caso 3)
    local t_felipe   = DB.insert("tutores", {
        usuario_id        = u_felipe,
        nombre            = "Felipe Ortiz",
        areas             = "Comunicacion Oral,Presentaciones",
        disponibilidad    = "miercoles,viernes",
        tutorados_activos = 0,
        limite            = 5,
        incidentes        = 0,
        activo            = false,
        estado            = "inactivo",
    })

    -- ----------------------------------------------------------
    -- ESTUDIANTES
    -- ----------------------------------------------------------
    local e_valentina = DB.insert("estudiantes", {
        usuario_id    = u_valentina,
        nombre        = "Valentina Torres",
        area_necesidad = "Estadistica Aplicada",
    })
    local e_diego     = DB.insert("estudiantes", {
        usuario_id    = u_diego,
        nombre        = "Diego Ramirez",
        area_necesidad = "Gestion de Proyectos",
    })
    local e_sofia     = DB.insert("estudiantes", {
        usuario_id    = u_sofia,
        nombre        = "Sofia Munoz",
        area_necesidad = "Comunicacion Oral",
    })
    local e_ana       = DB.insert("estudiantes", {
        usuario_id    = u_ana,
        nombre        = "Ana Garcia",
        area_necesidad = "Estadistica Aplicada",
    })

    -- ----------------------------------------------------------
    -- CASO 1: FLUJO IDEAL  –  Valentina + Roberto
    -- 8 sesiones realizadas, progresión bajo→medio→alto
    -- Nivel actual: alto → Coordinador puede validar cierre
    -- Condiciones cierre cumplidas: min 4 sesiones con avance alto ✓
    -- ----------------------------------------------------------
    local tut1 = DB.insert("tutorias", {
        estudiante_id      = e_valentina,
        tutor_id           = t_roberto,
        tutor_nombre       = "Roberto Campos",
        estudiante_nombre  = "Valentina Torres",
        area               = "Estadistica Aplicada",
        area_necesidad     = "Estadistica Aplicada",
        estado             = "activa",
        nivel_avance       = "alto",
        sesiones           = 8,
        ausencias          = 0,
        fecha_inicio       = "2026-04-14",
        advertencia_formal = false,
        alerta_avance_bajo = false,
        historial_avance   = {"bajo","bajo","medio","medio","medio","medio","alto","alto"},
    })
    -- Sesiones del Caso 1 (todas realizadas, asistencia perfecta)
    local sesiones_c1 = {
        {fecha="2026-04-17", temas="Introduccion a estadistica descriptiva",       nivel="bajo",  asistencia="presente", duracion=60},
        {fecha="2026-04-24", temas="Medidas de tendencia central",                  nivel="bajo",  asistencia="presente", duracion=60},
        {fecha="2026-05-06", temas="Varianza, desviacion estandar y distribucion", nivel="medio", asistencia="presente", duracion=75},
        {fecha="2026-05-13", temas="Probabilidad condicional e independencia",     nivel="medio", asistencia="presente", duracion=75},
        {fecha="2026-05-20", temas="Distribucion normal y estandarizacion",        nivel="medio", asistencia="presente", duracion=75},
        {fecha="2026-05-27", temas="Intervalos de confianza",                      nivel="medio", asistencia="presente", duracion=75},
        {fecha="2026-06-03", temas="Prueba de hipotesis t-Student",                nivel="alto",  asistencia="presente", duracion=90},
        {fecha="2026-06-10", temas="Regresion lineal y correlacion",               nivel="alto",  asistencia="presente", duracion=90},
    }
    for _, s in ipairs(sesiones_c1) do
        DB.insert("sesiones", {
            tutoria_id   = tut1,
            fecha        = s.fecha,
            temas        = s.temas,
            nivel_avance = s.nivel,
            asistencia   = s.asistencia,
            duracion_min = s.duracion,
            registrada   = true,
        })
    end

    -- Solicitud de Valentina: ya asignada (tutoría activa)
    DB.insert("solicitudes", {
        estudiante_id    = e_valentina,
        estudiante_nombre = "Valentina Torres",
        area             = "Estadistica Aplicada",
        urgencia         = "alta",
        disponibilidad   = "martes y jueves tarde",
        modalidad        = "remota",
        estado           = "asignada",
        fecha_solicitud  = "2026-04-10",
    })

    -- ----------------------------------------------------------
    -- CASO 2: ERROR INTERMEDIO  –  Diego + Miguel
    -- 2 ausencias injustificadas consecutivas → activa_con_alerta
    -- El coordinador debe decidir: continuar (advertencia) o suspender
    -- ----------------------------------------------------------
    local tut2 = DB.insert("tutorias", {
        estudiante_id      = e_diego,
        tutor_id           = t_miguel,
        tutor_nombre       = "Miguel Fuentes",
        estudiante_nombre  = "Diego Ramirez",
        area               = "Gestion de Proyectos",
        area_necesidad     = "Gestion de Proyectos",
        estado             = "activa_con_alerta",
        nivel_avance       = "medio",
        sesiones           = 4,
        ausencias          = 2,
        ausencias_consec   = 2,
        fecha_inicio       = "2026-04-21",
        advertencia_formal = false,
        alerta_avance_bajo = false,
        historial_avance   = {"medio","medio","ausente","ausente"},
    })
    local sesiones_c2 = {
        {fecha="2026-04-24", temas="Fundamentos de gestion de proyectos PMI",    nivel="medio",  asistencia="presente",              registrada=true},
        {fecha="2026-05-01", temas="Ciclo de vida del proyecto y entregables",   nivel="medio",  asistencia="presente",              registrada=true},
        {fecha="2026-05-08", temas="Gestion de riesgos",                          nivel="bajo",   asistencia="ausente_injustificada", registrada=true},
        {fecha="2026-05-15", temas="Gestion de stakeholders",                     nivel="bajo",   asistencia="ausente_injustificada", registrada=true},
    }
    for _, s in ipairs(sesiones_c2) do
        DB.insert("sesiones", {
            tutoria_id   = tut2,
            fecha        = s.fecha,
            temas        = s.temas,
            nivel_avance = s.nivel,
            asistencia   = s.asistencia,
            duracion_min = 60,
            registrada   = s.registrada,
        })
    end
    -- Solicitud de Diego: ya asignada
    DB.insert("solicitudes", {
        estudiante_id    = e_diego,
        estudiante_nombre = "Diego Ramirez",
        area             = "Gestion de Proyectos",
        urgencia         = "media",
        disponibilidad   = "martes y viernes manana",
        modalidad        = "presencial",
        estado           = "asignada",
        fecha_solicitud  = "2026-04-17",
    })

    -- ----------------------------------------------------------
    -- CASO 3: FALLA CRÍTICA  –  Sofía + Felipe (dado de baja)
    -- Tutoría en pendiente_reasignacion
    -- 3 sesiones con avance bajo (Decisión 6 debió activarse)
    -- El coordinador reasigna a Laura Sepúlveda
    -- ----------------------------------------------------------
    local tut3 = DB.insert("tutorias", {
        estudiante_id      = e_sofia,
        tutor_id           = t_felipe,
        tutor_nombre       = "Felipe Ortiz",
        estudiante_nombre  = "Sofia Munoz",
        area               = "Comunicacion Oral",
        area_necesidad     = "Comunicacion Oral",
        estado             = "pendiente_reasignacion",
        nivel_avance       = "bajo",
        sesiones           = 3,
        ausencias          = 0,
        tutor_anterior     = t_felipe,
        fecha_inicio       = "2026-04-28",
        advertencia_formal = false,
        alerta_avance_bajo = true,   -- Decisión 6: 3 sesiones consecutivas bajo
        historial_avance   = {"bajo","bajo","bajo"},
    })
    local sesiones_c3 = {
        {fecha="2026-05-05", temas="Estructura de una presentacion oral",      nivel="bajo", asistencia="presente"},
        {fecha="2026-05-12", temas="Tecnicas de voz y lenguaje no verbal",     nivel="bajo", asistencia="presente"},
        {fecha="2026-05-19", temas="Manejo del nerviosismo y contacto visual", nivel="bajo", asistencia="presente"},
    }
    for _, s in ipairs(sesiones_c3) do
        DB.insert("sesiones", {
            tutoria_id   = tut3,
            fecha        = s.fecha,
            temas        = s.temas,
            nivel_avance = s.nivel,
            asistencia   = s.asistencia,
            duracion_min = 60,
            registrada   = true,
        })
    end
    -- Solicitud de Sofía: estado reasignacion_pendiente
    DB.insert("solicitudes", {
        estudiante_id    = e_sofia,
        estudiante_nombre = "Sofia Munoz",
        area             = "Comunicacion Oral",
        urgencia         = "alta",
        disponibilidad   = "lunes y viernes tarde",
        modalidad        = "presencial",
        estado           = "asignada",
        fecha_solicitud  = "2026-04-24",
    })

    -- ----------------------------------------------------------
    -- FLUJO LIMPIO  –  Ana García
    -- Solicitud PENDIENTE lista para que el coordinador proponga tutor
    -- Permite demostrar en vivo: solicitud → propuesta → aceptación 48h
    -- ----------------------------------------------------------
    DB.insert("solicitudes", {
        estudiante_id    = e_ana,
        estudiante_nombre = "Ana Garcia",
        area             = "Estadistica Aplicada",
        urgencia         = "alta",
        disponibilidad   = "lunes y miercoles tarde",
        modalidad        = "remota",
        estado           = "pendiente",
        fecha_solicitud  = "2026-06-18",
    })

    print("[Seed] Datos de prueba insertados: 3 casos MPN + flujo limpio Ana Garcia.")
end

return Seed
