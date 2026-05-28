local DB = require("src.db.DB")
local R  = {}

-- Estados válidos según MPN
-- activa | activa_con_alerta | activa_con_advertencia
-- suspendida | pendiente_reasignacion | en_espera
-- cerrada_exitosamente | cerrada_por_abandono | cerrada_por_abandono_voluntario

function R.getAll()
    return DB.all("tutorias")
end

function R.getByEstudiante(usuario_id)
    local est = DB.find("estudiantes", function(e) return e.usuario_id == usuario_id end)
    if not est then return {} end
    return DB.where("tutorias", function(t) return t.estudiante_id == est.id end)
end

function R.getByTutor(usuario_id)
    local tutor = DB.find("tutores", function(t) return t.usuario_id == usuario_id end)
    if not tutor then return {} end
    local rows = DB.where("tutorias", function(t) return t.tutor_id == tutor.id end)
    for _, t in ipairs(rows) do
        if not t.estudiante_nombre then
            local est = DB.find("estudiantes", function(e) return e.id == t.estudiante_id end)
            if est then
                local usr = DB.find("usuarios", function(u) return u.id == est.usuario_id end)
                t.estudiante_nombre = usr and usr.nombre or "\xe2\x80\x94"
            else
                t.estudiante_nombre = "\xe2\x80\x94"
            end
        end
    end
    return rows
end

function R.getById(id)
    return DB.find("tutorias", function(t) return t.id == id end)
end

-- Registra una sesión con asistencia y nivel de avance.
-- Aplica Decisión 4 (asistencia), Decisión 5 (ausencias) y Decisión 6 (avance bajo sostenido)
function R.registrarSesion(tutoria_id, avance, asistencia)
    local t = DB.find("tutorias", function(r) return r.id == tutoria_id end)
    if not t then
        print("[TutoriaRepo] Tutoria no encontrada: " .. tostring(tutoria_id))
        return
    end

    local sesiones  = t.sesiones  or 0
    local ausencias = t.ausencias or 0

    -- Decision 4: registro de asistencia
    if asistencia == "Asistio" then
        sesiones  = sesiones + 1
        ausencias = 0  -- se resetean las consecutivas
    elseif asistencia == "Ausencia injust." then
        ausencias = ausencias + 1
    elseif asistencia == "Ausencia just." then
        ausencias = 0  -- justificada no acumula
    end

    -- Registrar historial de avance por sesión (para Decisión 6)
    local historial = t.historial_avance or {}
    historial[#historial+1] = avance or "bajo"
    t.historial_avance = historial

    -- Decision 5: acumulacion de ausencias (solo injustificadas consecutivas)
    local estado = t.estado or "activa"
    -- No sobrescribir estados de cierre o suspensión ya definitivos
    local estadosFinales = {
        cerrada_exitosamente=true, cerrada_por_abandono=true,
        cerrada_por_abandono_voluntario=true
    }
    if not estadosFinales[estado] then
        if ausencias >= 2 then
            estado = "activa_con_alerta"   -- Coordinador decide si suspender
        elseif ausencias == 1 then
            estado = "activa_con_alerta"
        else
            -- Mantener advertencia_formal si ya existía, no bajarla a activa
            if estado ~= "activa_con_advertencia" then
                estado = "activa"
            end
        end
    end

    -- Decision 6: avance bajo sostenido = 3 sesiones consecutivas en "bajo"
    local alertaAvanceBajo = false
    if #historial >= 3 then
        local ult3 = { historial[#historial-2], historial[#historial-1], historial[#historial] }
        if ult3[1]=="bajo" and ult3[2]=="bajo" and ult3[3]=="bajo" then
            alertaAvanceBajo = true
        end
    end
    t.alerta_avance_bajo = alertaAvanceBajo

    t.sesiones     = sesiones
    t.ausencias    = ausencias
    t.nivel_avance = avance or t.nivel_avance
    t.estado       = estado
    DB.save()
    return alertaAvanceBajo
end

-- Coordinador decide qué hacer tras 2 ausencias consecutivas
-- accion: "advertir" -> activa_con_advertencia | "suspender" -> suspendida
function R.resolverAusencias(tutoria_id, accion)
    local t = DB.find("tutorias", function(r) return r.id == tutoria_id end)
    if not t then return false, "Tutoria no encontrada" end
    if accion == "advertir" then
        t.estado = "activa_con_advertencia"
        t.advertencia_formal = true
        DB.save()
        return true, "Advertencia formal registrada"
    elseif accion == "suspender" then
        t.estado = "suspendida"
        DB.save()
        return true, "Tutoria suspendida por inasistencia"
    end
    return false, "Accion invalida"
end

-- Estudiante no responde en 5 días tras suspensión -> cierre por abandono
function R.cerrarPorAbandono(tutoria_id)
    local t = DB.find("tutorias", function(r) return r.id == tutoria_id end)
    if not t then return false, "Tutoria no encontrada" end
    t.estado = "cerrada_por_abandono"
    t.fecha_cierre = os.date("%Y-%m-%d")
    R._liberarTutor(t)
    DB.save()
    return true, "Tutoria cerrada por abandono"
end

-- Estudiante retira voluntariamente la tutoria activa
function R.cerrarVoluntariamente(tutoria_id)
    local t = DB.find("tutorias", function(r) return r.id == tutoria_id end)
    if not t then return false, "Tutoria no encontrada" end
    t.estado = "cerrada_por_abandono_voluntario"
    t.fecha_cierre = os.date("%Y-%m-%d")
    R._liberarTutor(t)
    DB.save()
    return true, "Tutoria cerrada por abandono voluntario"
end

-- Baja del tutor durante tutorias activas (Excepcion 1 del MPN)
-- Mueve todas sus tutorias activas a pendiente_reasignacion
function R.bajaTutor(tutor_id)
    local afectadas = DB.where("tutorias", function(t)
        return t.tutor_id == tutor_id and
               (t.estado == "activa" or t.estado == "activa_con_alerta" or t.estado == "activa_con_advertencia")
    end)
    for _, t in ipairs(afectadas) do
        t.estado        = "pendiente_reasignacion"
        t.tutor_anterior = t.tutor_id  -- conservar historial del tutor saliente
    end
    -- Marcar tutor como inactivo
    local tutor = DB.find("tutores", function(r) return r.id == tutor_id end)
    if tutor then
        tutor.estado = "inactivo"
        tutor.tutorados_activos = 0
    end
    DB.save()
    return #afectadas
end

-- Propuesta de cierre por el tutor (Decision 7 del MPN)
function R.proponerCierre(tutoria_id)
    local t = DB.find("tutorias", function(r) return r.id == tutoria_id end)
    if not t then return false, "Tutoria no encontrada" end
    local sesiones = t.sesiones or 0
    local nivel    = t.nivel_avance or "bajo"
    local cumple   = false
    if nivel == "alto"  and sesiones >= 4 then cumple = true end
    if nivel == "medio" and sesiones >= 6 then cumple = true end
    -- nivel bajo no tiene condicion de cierre exitoso
    if cumple then
        t.estado       = "cerrada_exitosamente"
        t.fecha_cierre = os.date("%Y-%m-%d")
        R._liberarTutor(t)
        DB.save()
        return true, "Tutoria cerrada exitosamente"
    else
        local falta = 0
        if nivel == "alto"  then falta = math.max(0, 4 - sesiones) end
        if nivel == "medio" then falta = math.max(0, 6 - sesiones) end
        if nivel == "bajo"  then return false, "Nivel de avance bajo no permite cierre exitoso" end
        return false, "Faltan " .. falta .. " sesion(es) para nivel " .. nivel
    end
end

-- Libera el cupo del tutor al cerrar una tutoria
function R._liberarTutor(t)
    if t.tutor_id then
        local tutor = DB.find("tutores", function(r) return r.id == t.tutor_id end)
        if tutor and (tutor.tutorados_activos or 0) > 0 then
            tutor.tutorados_activos = tutor.tutorados_activos - 1
        end
    end
end

function R.cambiarEstado(tutoria_id, nuevoEstado)
    local t = DB.find("tutorias", function(r) return r.id == tutoria_id end)
    if not t then return end
    t.estado = nuevoEstado
    DB.save()
end

return R
