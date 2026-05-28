local Anim          = require("src.anim.Anim")
local SolicitudRepo = require("src.db.SolicitudRepo")
local TutoriaRepo   = require("src.db.TutoriaRepo")
local DB            = require("src.db.DB")

local AS = {}
local selTutor     = nil
local selSolicitud = nil
local hover        = {}
local stag         = {}
local asig         = false
local msgError     = ""
local params       = {}
local tutores      = {}
local solicitudes  = {}
local infoTutor    = nil   -- info detallada del tutor hovereado

local function W() return love.graphics.getWidth() end
local function H() return love.graphics.getHeight() end
local MARGIN = 50
local ROW_H  = 90

-- Regla 2 del MPN: verifica las 4 condiciones para elegibilidad del tutor
local function esTutorElegible(tutor, solicitud)
    local razon = nil
    -- Condicion 1: cupo disponible (max 5 tutorados activos)
    local activos = tutor.tutorados_activos or 0
    local limite  = tutor.limite or 5
    if activos >= limite then
        return false, "Sin cupo (" .. activos .. "/" .. limite .. " tutorados)"
    end
    -- Condicion 2: compatibilidad de area
    if solicitud and solicitud.area then
        local areas = string.lower(tutor.areas or "")
        local sol_area = string.lower(solicitud.area)
        local compatibe = false
        for word in sol_area:gmatch("%S+") do
            if areas:find(word, 1, true) then
                compatibe = true
                break
            end
        end
        if not compatibe then
            razon = "Sin compatibilidad de \xc3\xa1rea"
            -- No bloqueamos (el coordinador puede forzar), solo advertimos
        end
    end
    -- Condicion 3: sin incidentes graves (>1 incidente en los ultimos 6 meses)
    if (tutor.incidentes or 0) > 1 then
        return false, "M\xc3\xa1s de 1 incidente reciente"
    end
    -- Condicion 4: tutor no inactivo
    if tutor.estado == "inactivo" then
        return false, "Tutor inactivo (dado de baja)"
    end
    return true, razon  -- razon puede ser advertencia de area
end

local function cargarDatos()
    -- Solicitudes pendientes (excluir borradores y retiradas)
    solicitudes = DB.where("solicitudes", function(s)
        return s.estado == "pendiente" or s.estado == "en_espera"
    end)
    for _,sol in ipairs(solicitudes) do
        if not sol.estudiante_nombre then
            local est = DB.find("estudiantes", function(e) return e.id == sol.estudiante_id end)
            if est then
                local usr = DB.find("usuarios", function(u) return u.id == est.usuario_id end)
                sol.estudiante_nombre = usr and usr.nombre or "\xe2\x80\x94"
            else
                sol.estudiante_nombre = "\xe2\x80\x94"
            end
        end
    end

    -- Tutores: mostrar todos con su elegibilidad calculada
    local allTutores = DB.all("tutores")
    tutores = {}
    for _,t in ipairs(allTutores) do
        if not t.nombre then
            local usr = DB.find("usuarios", function(u) return u.id == t.usuario_id end)
            t.nombre = usr and usr.nombre or "Tutor"
        end
        -- calcular elegibilidad base (sin solicitud especifica)
        local elegible, motivo = esTutorElegible(t, nil)
        t._elegible = elegible
        t._motivo   = motivo
        tutores[#tutores+1] = t
    end
end

function AS.load(p)
    params       = p or {}
    selTutor     = nil
    selSolicitud = nil
    asig         = false
    msgError     = ""
    hover        = {}
    infoTutor    = nil
    cargarDatos()
    stag = Anim.staggerList(math.max(#solicitudes, #tutores), 0.06, 0.4)
end

function AS.update(dt)
    Anim.staggerUpdate(stag, dt)
    local mx, my = love.mouse.getPosition()
    local WW = W()
    local mitad = math.floor((WW - MARGIN*2) / 2)
    for i in ipairs(solicitudes) do
        local ry = 168 + (i-1)*(ROW_H+12)
        hover["s"..i] = mx>=MARGIN and mx<=MARGIN+mitad-10 and my>=ry and my<=ry+ROW_H
    end
    for i in ipairs(tutores) do
        local ry = 168 + (i-1)*(ROW_H+12)
        local col2x = MARGIN + mitad + 20
        hover["t"..i] = mx>=col2x and mx<=W()-MARGIN and my>=ry and my<=ry+ROW_H
    end
end

function AS.draw()
    local WW, HH = W(), H()
    local RW     = WW - MARGIN*2
    local mitad  = math.floor(RW/2) - 10
    local col2x  = MARGIN + mitad + 20

    love.graphics.setColor(Colors.bg)
    love.graphics.rectangle("fill", 0, 0, WW, HH)

    love.graphics.setColor(Colors.accent)
    love.graphics.rectangle("fill", 0, 0, WW, 68)
    love.graphics.setColor(1,1,1)
    love.graphics.setFont(Fonts.title)
    love.graphics.printf("Asignaci\xc3\xb3n de Tutor", 0, 20, WW, "center")

    love.graphics.setColor(Colors.text)
    love.graphics.setFont(Fonts.body)
    love.graphics.print("Solicitudes pendientes", MARGIN, 86)
    love.graphics.print("Tutores disponibles", col2x, 86)
    love.graphics.setColor(Colors.textSub)
    love.graphics.setFont(Fonts.small)
    love.graphics.print("Selecciona una solicitud", MARGIN, 108)
    love.graphics.print("Verde = elegible  |  Gris = no elegible", col2x, 108)

    love.graphics.setColor(Colors.border)
    love.graphics.rectangle("fill", MARGIN+mitad+8, 80, 2, HH-160)

    -- SOLICITUDES
    if #solicitudes == 0 then
        love.graphics.setColor(Colors.textSub)
        love.graphics.setFont(Fonts.small)
        love.graphics.print("No hay solicitudes pendientes", MARGIN, 180)
    end
    for i, sol in ipairs(solicitudes) do
        local ry    = 168 + (i-1)*(ROW_H+12)
        local sel   = selSolicitud == i
        local isHov = hover["s"..i]
        local _,alpha = Anim.staggerValue(stag, i)

        local bgColor = sel and Colors.accentSoft or (isHov and {0.95,0.95,1} or Colors.card)
        love.graphics.setColor(bgColor[1],bgColor[2],bgColor[3],alpha)
        love.graphics.rectangle("fill", MARGIN, ry, mitad, ROW_H, 12)
        if sel then
            love.graphics.setColor(Colors.accent[1],Colors.accent[2],Colors.accent[3],alpha)
            love.graphics.rectangle("line", MARGIN+1, ry+1, mitad-2, ROW_H-2, 12)
        end

        love.graphics.setColor(Colors.text[1],Colors.text[2],Colors.text[3],alpha)
        love.graphics.setFont(Fonts.body)
        love.graphics.print(sol.estudiante_nombre or "\xe2\x80\x94", MARGIN+14, ry+10)
        love.graphics.setColor(Colors.textSub[1],Colors.textSub[2],Colors.textSub[3],alpha)
        love.graphics.setFont(Fonts.small)
        love.graphics.print("\xc3\x81rea: "..(sol.area or "\xe2\x80\x94"), MARGIN+14, ry+32)
        love.graphics.print("Urgencia: "..(sol.urgencia or "\xe2\x80\x94"), MARGIN+14, ry+50)
        -- badge de estado de la solicitud
        local estadoBadge = sol.estado == "en_espera" and "En espera" or "Pendiente"
        local ec = sol.estado == "en_espera" and Colors.orange or Colors.green
        love.graphics.setColor(ec[1],ec[2],ec[3],0.18*alpha)
        love.graphics.rectangle("fill", MARGIN+14, ry+66, Fonts.small:getWidth(estadoBadge)+12, 18, 5)
        love.graphics.setColor(ec[1],ec[2],ec[3],alpha)
        love.graphics.print(estadoBadge, MARGIN+20, ry+69)
    end

    -- TUTORES
    if #tutores == 0 then
        love.graphics.setColor(Colors.textSub)
        love.graphics.setFont(Fonts.small)
        love.graphics.print("No hay tutores registrados", col2x, 180)
    end
    local sol_sel = selSolicitud and solicitudes[selSolicitud] or nil
    for i, t in ipairs(tutores) do
        local ry    = 168 + (i-1)*(ROW_H+12)
        local sel   = selTutor == i
        local isHov = hover["t"..i]
        local _,alpha = Anim.staggerValue(stag, i)
        local cw    = WW - MARGIN - col2x

        -- Recalcular elegibilidad con la solicitud seleccionada
        local elegible, motivo = esTutorElegible(t, sol_sel)

        local bgColor
        if sel then
            bgColor = elegible and Colors.greenSoft or {0.98, 0.94, 0.94}
        elseif isHov then
            bgColor = elegible and {0.95, 1, 0.96} or {0.98, 0.97, 0.97}
        else
            bgColor = elegible and Colors.card or {0.93, 0.93, 0.93}
        end
        love.graphics.setColor(bgColor[1],bgColor[2],bgColor[3],alpha)
        love.graphics.rectangle("fill", col2x, ry, cw, ROW_H, 12)
        if sel then
            local bc = elegible and Colors.green or Colors.red
            love.graphics.setColor(bc[1],bc[2],bc[3],alpha)
            love.graphics.rectangle("line", col2x+1, ry+1, cw-2, ROW_H-2, 12)
        end

        love.graphics.setColor(Colors.text[1],Colors.text[2],Colors.text[3],alpha)
        love.graphics.setFont(Fonts.body)
        love.graphics.print(t.nombre or "Tutor", col2x+14, ry+10)
        love.graphics.setColor(Colors.textSub[1],Colors.textSub[2],Colors.textSub[3],alpha)
        love.graphics.setFont(Fonts.small)
        local activos = t.tutorados_activos or 0
        local limite  = t.limite or 5
        love.graphics.print("Tutorados: "..activos.." / "..limite, col2x+14, ry+32)
        love.graphics.print("\xc3\x81reas: "..(t.areas or "\xe2\x80\x94"), col2x+14, ry+50)
        -- indicador elegibilidad
        if elegible then
            love.graphics.setColor(Colors.green[1],Colors.green[2],Colors.green[3],alpha)
            love.graphics.print(motivo and ("\xe2\x9a\xa0 "..motivo) or "\xe2\x9c\x93 Elegible", col2x+14, ry+68)
        else
            love.graphics.setColor(Colors.red[1],Colors.red[2],Colors.red[3],alpha)
            love.graphics.print("\xe2\x9c\x95 ".. (motivo or "No elegible"), col2x+14, ry+68)
        end
    end

    -- Mensaje resultado
    if asig then
        love.graphics.setColor(Colors.greenSoft)
        love.graphics.rectangle("fill", MARGIN, HH-118, RW, 38, 10)
        love.graphics.setColor(Colors.green)
        love.graphics.setFont(Fonts.body)
        love.graphics.printf("\xe2\x9c\x93 Tutor asignado correctamente. Tutor\xc3\xada creada.", MARGIN, HH-107, RW, "center")
    elseif msgError ~= "" then
        love.graphics.setColor(0.99, 0.94, 0.94)
        love.graphics.rectangle("fill", MARGIN, HH-118, RW, 38, 10)
        love.graphics.setColor(Colors.red)
        love.graphics.setFont(Fonts.small)
        love.graphics.printf(msgError, MARGIN, HH-107, RW, "center")
    end

    local btnY = HH - 68
    love.graphics.setColor(Colors.border)
    love.graphics.rectangle("fill", MARGIN, btnY, 130, 46, 12)
    love.graphics.setColor(Colors.text)
    love.graphics.setFont(Fonts.body)
    love.graphics.printf("Volver", MARGIN, btnY+13, 130, "center")

    local puedeAsignar = selTutor and selSolicitud
    local bc = puedeAsignar and Colors.accent or {0.75,0.75,0.85}
    love.graphics.setColor(bc)
    love.graphics.rectangle("fill", WW-MARGIN-130, btnY, 130, 46, 12)
    love.graphics.setColor(1,1,1)
    love.graphics.printf("Asignar", WW-MARGIN-130, btnY+13, 130, "center")
end

function AS.mousepressed(x, y, btn)
    local WW, HH = W(), H()
    local RW     = WW - MARGIN*2
    local mitad  = math.floor(RW/2) - 10
    local col2x  = MARGIN + mitad + 20
    local btnY   = HH - 68

    if x>=MARGIN and x<=MARGIN+130 and y>=btnY and y<=btnY+46 then
        Nav.to("dashboard", {rol=params.rol, usuario_id=params.usuario_id, nombre=params.nombre}, -1)
        return
    end

    if x>=WW-MARGIN-130 and x<=WW-MARGIN and y>=btnY and y<=btnY+46 then
        if not selTutor or not selSolicitud then
            msgError = "Debes seleccionar una solicitud y un tutor"
            return
        end
        local sol   = solicitudes[selSolicitud]
        local tutor = tutores[selTutor]

        -- Validar reglas de negocio antes de asignar
        local elegible, motivo = esTutorElegible(tutor, sol)
        if not elegible then
            msgError = "No se puede asignar: " .. (motivo or "tutor no elegible")
            return
        end

        local est = DB.find("estudiantes", function(e) return e.id == sol.estudiante_id end)
        if not est then msgError = "Error: estudiante no encontrado" return end

        DB.insert("tutorias", {
            estudiante_id      = est.id,
            tutor_id           = tutor.id,
            tutor_nombre       = tutor.nombre,
            estudiante_nombre  = sol.estudiante_nombre,
            area               = sol.area,
            estado             = "activa",
            sesiones           = 0,
            ausencias          = 0,
            nivel_avance       = "bajo",
            historial_avance   = {},
            fecha_inicio       = os.date("%Y-%m-%d"),
            advertencia_formal = false,
            alerta_avance_bajo = false,
        })
        sol.estado = "asignada"
        tutor.tutorados_activos = (tutor.tutorados_activos or 0) + 1
        DB.save()
        asig      = true
        msgError  = ""
        selTutor     = nil
        selSolicitud = nil
        cargarDatos()
        return
    end

    for i in ipairs(solicitudes) do
        local ry = 168 + (i-1)*(ROW_H+12)
        if x>=MARGIN and x<=MARGIN+math.floor((W()-MARGIN*2)/2)-10 and y>=ry and y<=ry+ROW_H then
            selSolicitud = i
            asig = false msgError = ""
            return
        end
    end

    local cw = WW - MARGIN - (MARGIN + math.floor((WW-MARGIN*2)/2) - 10 + 20)
    for i in ipairs(tutores) do
        local ry    = 168 + (i-1)*(ROW_H+12)
        local col2x2 = MARGIN + math.floor((WW-MARGIN*2)/2) - 10 + 20
        if x>=col2x2 and x<=WW-MARGIN and y>=ry and y<=ry+ROW_H then
            selTutor = i
            asig = false msgError = ""
            return
        end
    end
end

return AS
