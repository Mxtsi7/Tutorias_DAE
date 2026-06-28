-- AsignacionScreen.lua
-- Sin selector de modalidad (eliminado).
-- Scroll independiente en columna solicitudes y tutores.
-- Badges de incidentes en tarjetas de tutores.

local Anim          = require("src.anim.Anim")
local EventBus      = require("src.events.EventBus")
local EventTypes    = require("src.events.EventTypes")
local DB            = require("src.db.DB")
local Areas         = require("src.data.areas")

local AS = {}
local selTutor      = nil
local selSolicitud  = nil
local hover         = {}
local stag          = {}
local propuesto     = false
local msgError      = ""
local params        = {}
local tutores       = {}
local solicitudes   = {}
local scrollSol     = 0
local scrollTut     = 0

local function W() return love.graphics.getWidth() end
local function H() return love.graphics.getHeight() end
local MARGIN   = 50
local ROW_H    = 90
local ROW_GAP  = 12
local LIST_TOP = 148
local FOOTER_H = 70   -- solo botones, sin modalidad

local function esTutorElegible(tutor, solicitud)
    local activos = tutor.tutorados_activos or 0
    local limite  = tutor.limite or 5
    if activos >= limite then
        return false, "Sin cupo ("..activos.."/"..limite.." tutorados)"
    end
    if (tutor.incidentes or 0) > 1 then
        return false, "M\xc3\xa1s de 1 incidente reciente"
    end
    if tutor.estado == "inactivo" then
        return false, "Tutor inactivo (dado de baja)"
    end
    if solicitud and solicitud.area_id then
        local compat = false
        for _, comp in ipairs(tutor.areas_competencia or {}) do
            if comp == solicitud.area_id then compat = true break end
        end
        if not compat then
            return true, "\xe2\x9a\xa0 Sin compatibilidad de \xc3\xa1rea (advertencia)"
        end
    end
    return true, nil
end

local function cargarDatos()
    solicitudes = DB.where("solicitudes", function(s)
        return s.estado == "pendiente" or s.estado == "en_espera"
    end)
    for _, sol in ipairs(solicitudes) do
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

    local allTutores = DB.all("tutores")
    tutores = {}
    for _, t in ipairs(allTutores) do
        if not t.nombre then
            local usr = DB.find("usuarios", function(u) return u.id == t.usuario_id end)
            t.nombre = usr and usr.nombre or "Tutor"
        end
        if t.areas_competencia and #t.areas_competencia > 0 then
            local labs = {}
            for _, aid in ipairs(t.areas_competencia) do
                labs[#labs+1] = Areas.getLabel(aid)
            end
            t._areasLabel = table.concat(labs, ", ")
        else
            t._areasLabel = t.areas or "\xe2\x80\x94"
        end
        tutores[#tutores+1] = t
    end
end

function AS.load(p)
    params        = p or {}
    selTutor      = nil
    selSolicitud  = nil
    propuesto     = false
    msgError      = ""
    hover         = {}
    scrollSol     = 0
    scrollTut     = 0
    cargarDatos()
    stag = Anim.staggerList(math.max(#solicitudes, #tutores), 0.06, 0.4)
end

function AS.update(dt)
    Anim.staggerUpdate(stag, dt)
    local mx, my = love.mouse.getPosition()
    local WW, HH = W(), H()
    local RW     = WW - MARGIN * 2
    local mitad  = math.floor(RW / 2) - 10
    local col2x  = MARGIN + mitad + 20
    local listH  = HH - LIST_TOP - FOOTER_H

    for i in ipairs(solicitudes) do
        local ry = LIST_TOP + (i-1)*(ROW_H+ROW_GAP) + scrollSol
        hover["s"..i] = mx>=MARGIN and mx<=MARGIN+mitad-10
            and my>=LIST_TOP and my<=LIST_TOP+listH
            and my>=ry and my<=ry+ROW_H
    end
    for i in ipairs(tutores) do
        local ry = LIST_TOP + (i-1)*(ROW_H+ROW_GAP) + scrollTut
        hover["t"..i] = mx>=col2x and mx<=WW-MARGIN
            and my>=LIST_TOP and my<=LIST_TOP+listH
            and my>=ry and my<=ry+ROW_H
    end
end

local function drawScrollbar(x, y, w, h, totalItems, scroll, color)
    local totalH = totalItems * (ROW_H + ROW_GAP)
    if totalH <= h then return end
    local barH  = math.max(24, h * h / totalH)
    local track = h - barH
    local maxScr = -(totalH - h)
    local ratio = maxScr ~= 0 and (-scroll / -maxScr) or 0
    local barY  = y + ratio * track
    love.graphics.setColor(color[1], color[2], color[3], 0.30)
    love.graphics.rectangle("fill", x + w - 6, barY, 5, barH, 3)
end

function AS.draw()
    local WW, HH = W(), H()
    local RW     = WW - MARGIN * 2
    local mitad  = math.floor(RW / 2) - 10
    local col2x  = MARGIN + mitad + 20
    local listH  = HH - LIST_TOP - FOOTER_H

    love.graphics.setColor(Colors.bg)
    love.graphics.rectangle("fill", 0, 0, WW, HH)

    -- Header
    love.graphics.setColor(Colors.accent)
    love.graphics.rectangle("fill", 0, 0, WW, 68)
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(Fonts.title)
    love.graphics.printf("Asignaci\xc3\xb3n de Tutor", 0, 20, WW, "center")

    love.graphics.setColor(Colors.accentSoft)
    love.graphics.rectangle("fill", MARGIN, 74, RW, 22, 6)
    love.graphics.setColor(Colors.accent)
    love.graphics.setFont(Fonts.small)
    love.graphics.printf(
        "Flujo 2 etapas: Coordinador propone  \xe2\x86\x92  Tutor acepta/rechaza (48h)  \xe2\x86\x92  Tutor\xc3\xada activa",
        MARGIN, 79, RW, "center")

    -- Encabezados columnas
    love.graphics.setColor(Colors.text)
    love.graphics.setFont(Fonts.body)
    love.graphics.print("Solicitudes pendientes", MARGIN, 106)
    love.graphics.print("Tutores disponibles",     col2x, 106)
    love.graphics.setColor(Colors.textSub)
    love.graphics.setFont(Fonts.small)
    love.graphics.print("Selecciona una solicitud",                    MARGIN, 128)
    love.graphics.print("Verde = elegible  |  Gris = no elegible",     col2x, 128)

    -- Divisor vertical
    love.graphics.setColor(Colors.border)
    love.graphics.rectangle("fill", MARGIN + mitad + 8, 100, 2, HH - 110)

    -- ======== COLUMNA SOLICITUDES ========
    love.graphics.setScissor(MARGIN, LIST_TOP, mitad, listH)
    if #solicitudes == 0 then
        love.graphics.setColor(Colors.textSub)
        love.graphics.setFont(Fonts.small)
        love.graphics.print("No hay solicitudes pendientes", MARGIN, LIST_TOP + 10)
    end
    for i, sol in ipairs(solicitudes) do
        local ry    = LIST_TOP + (i-1)*(ROW_H+ROW_GAP) + scrollSol
        local sel   = selSolicitud == i
        local isHov = hover["s"..i]
        local _, alpha = Anim.staggerValue(stag, i)

        local bgColor = sel and Colors.accentSoft
            or (isHov and {0.95,0.95,1} or Colors.card)
        love.graphics.setColor(bgColor[1], bgColor[2], bgColor[3], alpha)
        love.graphics.rectangle("fill", MARGIN, ry, mitad-4, ROW_H, 12)
        if sel then
            love.graphics.setColor(Colors.accent[1], Colors.accent[2], Colors.accent[3], alpha)
            love.graphics.rectangle("line", MARGIN+1, ry+1, mitad-6, ROW_H-2, 12)
        end
        love.graphics.setColor(Colors.text[1], Colors.text[2], Colors.text[3], alpha)
        love.graphics.setFont(Fonts.body)
        love.graphics.print(sol.estudiante_nombre or "\xe2\x80\x94", MARGIN+14, ry+10)
        love.graphics.setColor(Colors.textSub[1], Colors.textSub[2], Colors.textSub[3], alpha)
        love.graphics.setFont(Fonts.small)
        local aLabel = sol.area or (sol.area_id and Areas.getLabel(sol.area_id)) or "\xe2\x80\x94"
        love.graphics.print("\xc3\x81rea: "..aLabel,                   MARGIN+14, ry+32)
        love.graphics.print("Urgencia: "..(sol.urgencia or "\xe2\x80\x94"), MARGIN+14, ry+50)
        local estadoBadge = sol.estado == "en_espera" and "En espera" or "Pendiente"
        local ec = sol.estado == "en_espera" and Colors.orange or Colors.green
        love.graphics.setColor(ec[1], ec[2], ec[3], 0.18*alpha)
        love.graphics.rectangle("fill", MARGIN+14, ry+66, Fonts.small:getWidth(estadoBadge)+12, 18, 5)
        love.graphics.setColor(ec[1], ec[2], ec[3], alpha)
        love.graphics.print(estadoBadge, MARGIN+20, ry+69)
    end
    drawScrollbar(MARGIN, LIST_TOP, mitad, listH, #solicitudes, scrollSol, Colors.accent)
    love.graphics.setScissor()

    -- ======== COLUMNA TUTORES ========
    local cw = WW - MARGIN - col2x
    love.graphics.setScissor(col2x, LIST_TOP, cw, listH)
    local sol_sel = selSolicitud and solicitudes[selSolicitud] or nil
    if #tutores == 0 then
        love.graphics.setColor(Colors.textSub)
        love.graphics.setFont(Fonts.small)
        love.graphics.print("No hay tutores registrados", col2x, LIST_TOP + 10)
    end
    for i, t in ipairs(tutores) do
        local ry    = LIST_TOP + (i-1)*(ROW_H+ROW_GAP) + scrollTut
        local sel   = selTutor == i
        local isHov = hover["t"..i]
        local _, alpha = Anim.staggerValue(stag, i)
        local elegible, motivo = esTutorElegible(t, sol_sel)

        local bgColor
        if sel then
            bgColor = elegible and Colors.greenSoft or {0.98,0.94,0.94}
        elseif isHov then
            bgColor = elegible and {0.95,1,0.96} or {0.98,0.97,0.97}
        else
            bgColor = elegible and Colors.card or {0.93,0.93,0.93}
        end
        love.graphics.setColor(bgColor[1], bgColor[2], bgColor[3], alpha)
        love.graphics.rectangle("fill", col2x, ry, cw-4, ROW_H, 12)
        if sel then
            local bc = elegible and Colors.green or Colors.red
            love.graphics.setColor(bc[1], bc[2], bc[3], alpha)
            love.graphics.rectangle("line", col2x+1, ry+1, cw-6, ROW_H-2, 12)
        end
        love.graphics.setColor(Colors.text[1], Colors.text[2], Colors.text[3], alpha)
        love.graphics.setFont(Fonts.body)
        love.graphics.print(t.nombre or "Tutor", col2x+14, ry+10)
        love.graphics.setColor(Colors.textSub[1], Colors.textSub[2], Colors.textSub[3], alpha)
        love.graphics.setFont(Fonts.small)
        love.graphics.print("Tutorados: "..(t.tutorados_activos or 0).."/"..(t.limite or 5), col2x+14, ry+32)
        love.graphics.print("\xc3\x81reas: "..(t._areasLabel or "\xe2\x80\x94"), col2x+14, ry+50)

        local inc = t.incidentes or 0
        if inc == 1 then
            local bl  = "\xe2\x9a\xa0 1 incidente"
            local bw2 = Fonts.small:getWidth(bl) + 14
            love.graphics.setColor(0.98, 0.82, 0.10, 0.22*alpha)
            love.graphics.rectangle("fill", col2x+cw-bw2-14, ry+6, bw2, 20, 5)
            love.graphics.setColor(0.80, 0.60, 0.00, alpha)
            love.graphics.print(bl, col2x+cw-bw2-8, ry+9)
        elseif inc > 1 then
            local bl  = "No elegible"
            local bw2 = Fonts.small:getWidth(bl) + 14
            love.graphics.setColor(Colors.red[1], Colors.red[2], Colors.red[3], 0.20*alpha)
            love.graphics.rectangle("fill", col2x+cw-bw2-14, ry+6, bw2, 20, 5)
            love.graphics.setColor(Colors.red[1], Colors.red[2], Colors.red[3], alpha)
            love.graphics.print(bl, col2x+cw-bw2-8, ry+9)
        end

        if elegible then
            love.graphics.setColor(Colors.green[1], Colors.green[2], Colors.green[3], alpha)
            love.graphics.print(motivo and ("\xe2\x9a\xa0 "..motivo) or "\xe2\x9c\x93 Elegible", col2x+14, ry+68)
        else
            love.graphics.setColor(Colors.red[1], Colors.red[2], Colors.red[3], alpha)
            love.graphics.print("\xe2\x9c\x95 "..(motivo or "No elegible"), col2x+14, ry+68)
        end
    end
    drawScrollbar(col2x, LIST_TOP, cw, listH, #tutores, scrollTut, Colors.green)
    love.graphics.setScissor()

    -- ======== FOOTER (solo botones) ========
    local footerY = HH - FOOTER_H

    if propuesto then
        love.graphics.setColor(Colors.greenSoft)
        love.graphics.rectangle("fill", MARGIN, footerY - 40, RW, 32, 8)
        love.graphics.setColor(Colors.green)
        love.graphics.setFont(Fonts.small)
        love.graphics.printf(
            "\xe2\x9c\x93 Propuesta enviada. El tutor tiene 48h para aceptar o rechazar.",
            MARGIN, footerY - 33, RW, "center")
    elseif msgError ~= "" then
        love.graphics.setColor(0.99, 0.94, 0.94)
        love.graphics.rectangle("fill", MARGIN, footerY - 36, RW, 28, 8)
        love.graphics.setColor(Colors.red)
        love.graphics.setFont(Fonts.small)
        love.graphics.printf(msgError, MARGIN, footerY - 30, RW, "center")
    end

    local btnY = HH - 56
    love.graphics.setColor(Colors.border)
    love.graphics.rectangle("fill", MARGIN, btnY, 130, 44, 12)
    love.graphics.setColor(Colors.text)
    love.graphics.setFont(Fonts.body)
    love.graphics.printf("Volver", MARGIN, btnY+12, 130, "center")

    local puedeAsignar = selTutor and selSolicitud
    love.graphics.setColor(puedeAsignar and Colors.accent or {0.75,0.75,0.85})
    love.graphics.rectangle("fill", WW-MARGIN-160, btnY, 160, 44, 12)
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("Proponer tutor", WW-MARGIN-160, btnY+12, 160, "center")
end

function AS.wheelmoved(x, y)
    local WW, HH = W(), H()
    local RW     = WW - MARGIN * 2
    local mitad  = math.floor(RW / 2) - 10
    local col2x  = MARGIN + mitad + 20
    local listH  = HH - LIST_TOP - FOOTER_H
    local mx     = love.mouse.getX()

    if mx >= MARGIN and mx <= MARGIN + mitad then
        local totalH = #solicitudes * (ROW_H + ROW_GAP)
        if totalH > listH then
            local maxScroll = -(totalH - listH)
            scrollSol = math.max(maxScroll, math.min(0, scrollSol + y*30))
        end
    elseif mx >= col2x and mx <= WW - MARGIN then
        local totalH = #tutores * (ROW_H + ROW_GAP)
        if totalH > listH then
            local maxScroll = -(totalH - listH)
            scrollTut = math.max(maxScroll, math.min(0, scrollTut + y*30))
        end
    end
end

function AS.mousepressed(x, y, btn)
    if btn ~= 1 then return end
    local WW, HH = W(), H()
    local RW     = WW - MARGIN * 2
    local mitad  = math.floor(RW / 2) - 10
    local col2x  = MARGIN + mitad + 20
    local listH  = HH - LIST_TOP - FOOTER_H
    local btnY   = HH - 56

    -- Volver
    if x>=MARGIN and x<=MARGIN+130 and y>=btnY and y<=btnY+44 then
        Nav.to("dashboard", {
            rol=params.rol, usuario_id=params.usuario_id, nombre=params.nombre
        }, -1)
        return
    end

    -- Proponer tutor
    if x>=WW-MARGIN-160 and x<=WW-MARGIN and y>=btnY and y<=btnY+44 then
        if not selTutor or not selSolicitud then
            msgError = "Debes seleccionar una solicitud y un tutor"
            return
        end
        local sol   = solicitudes[selSolicitud]
        local tutor = tutores[selTutor]
        local elegible, motivo = esTutorElegible(tutor, sol)
        if not elegible then
            msgError = "No se puede proponer: "..(motivo or "tutor no elegible")
            return
        end
        EventBus.publish(EventTypes.TUTOR_ASIGNADO, {
            tutor        = tutor,
            solicitud_id = sol.id,
            modalidad    = "Presencial",  -- valor por defecto neutral
        })
        propuesto    = true
        msgError     = ""
        selTutor     = nil
        selSolicitud = nil
        cargarDatos()
        return
    end

    -- Seleccion solicitud
    if x>=MARGIN and x<=MARGIN+mitad-10 and y>=LIST_TOP and y<=LIST_TOP+listH then
        for i in ipairs(solicitudes) do
            local ry = LIST_TOP + (i-1)*(ROW_H+ROW_GAP) + scrollSol
            if y>=ry and y<=ry+ROW_H then
                selSolicitud = i
                propuesto    = false
                msgError     = ""
                return
            end
        end
    end

    -- Seleccion tutor
    if x>=col2x and x<=WW-MARGIN and y>=LIST_TOP and y<=LIST_TOP+listH then
        for i in ipairs(tutores) do
            local ry = LIST_TOP + (i-1)*(ROW_H+ROW_GAP) + scrollTut
            if y>=ry and y<=ry+ROW_H then
                selTutor  = i
                propuesto = false
                msgError  = ""
                return
            end
        end
    end
end

return AS
