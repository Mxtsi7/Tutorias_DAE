local Anim          = require("src.anim.Anim")
local SolicitudRepo = require("src.db.SolicitudRepo")
local TutoriaRepo   = require("src.db.TutoriaRepo")
local DB            = require("src.db.DB")

local AS = {}
local selTutor    = nil
local selSolicitud = nil
local hover       = {}
local stag        = {}
local asig        = false
local msgError    = ""
local params      = {}
local tutores     = {}
local solicitudes = {}

local function W() return love.graphics.getWidth() end
local function H() return love.graphics.getHeight() end
local MARGIN = 50
local ROW_H  = 80

local function cargarDatos()
    -- Solicitudes pendientes
    solicitudes = DB.where("solicitudes", function(s) return s.estado == "pendiente" end)
    -- Enriquecer con nombre estudiante
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
    -- Tutores disponibles (con cupo)
    local allTutores = DB.all("tutores")
    tutores = {}
    for _,t in ipairs(allTutores) do
        if (t.tutorados_activos or 0) < (t.limite or 3) then
            -- enriquecer con nombre
            if not t.nombre then
                local usr = DB.find("usuarios", function(u) return u.id == t.usuario_id end)
                t.nombre = usr and usr.nombre or "Tutor"
            end
            tutores[#tutores+1] = t
        end
    end
end

function AS.load(p)
    params      = p or {}
    selTutor    = nil
    selSolicitud = nil
    asig        = false
    msgError    = ""
    hover       = {}
    cargarDatos()
    stag = Anim.staggerList(math.max(#solicitudes, #tutores), 0.06, 0.4)
end

function AS.update(dt)
    Anim.staggerUpdate(stag, dt)
    local mx, my = love.mouse.getPosition()
    local WW = W()
    local mitad = math.floor((WW - MARGIN*2) / 2)
    -- hover solicitudes (columna izquierda)
    for i in ipairs(solicitudes) do
        local ry = 168 + (i-1)*(ROW_H+12)
        hover["s"..i] = mx>=MARGIN and mx<=MARGIN+mitad-10 and my>=ry and my<=ry+ROW_H
    end
    -- hover tutores (columna derecha)
    for i in ipairs(tutores) do
        local ry = 168 + (i-1)*(ROW_H+12)
        hover["t"..i] = mx>=MARGIN+mitad+10 and mx<=WW-MARGIN and my>=ry and my<=ry+ROW_H
    end
end

function AS.draw()
    local WW, HH = W(), H()
    local RW     = WW - MARGIN*2
    local mitad  = math.floor(RW/2) - 10
    local col2x  = MARGIN + mitad + 20

    love.graphics.setColor(Colors.bg)
    love.graphics.rectangle("fill", 0, 0, WW, HH)

    -- Header
    love.graphics.setColor(Colors.accent)
    love.graphics.rectangle("fill", 0, 0, WW, 68)
    love.graphics.setColor(1,1,1)
    love.graphics.setFont(Fonts.title)
    love.graphics.printf("Asignaci\xc3\xb3n de Tutor", 0, 20, WW, "center")

    -- Titulos columnas
    love.graphics.setColor(Colors.text)
    love.graphics.setFont(Fonts.body)
    love.graphics.print("Solicitudes pendientes", MARGIN, 86)
    love.graphics.print("Tutores disponibles", col2x, 86)
    love.graphics.setColor(Colors.textSub)
    love.graphics.setFont(Fonts.small)
    love.graphics.print("Selecciona una solicitud", MARGIN, 108)
    love.graphics.print("Selecciona un tutor", col2x, 108)

    -- separador vertical
    love.graphics.setColor(Colors.border)
    love.graphics.rectangle("fill", MARGIN+mitad+8, 80, 2, HH-160)

    -- SOLICITUDES
    if #solicitudes == 0 then
        love.graphics.setColor(Colors.textSub)
        love.graphics.setFont(Fonts.small)
        love.graphics.print("No hay solicitudes pendientes", MARGIN, 180)
    end
    for i, sol in ipairs(solicitudes) do
        local ry     = 168 + (i-1)*(ROW_H+12)
        local sel    = selSolicitud == i
        local isHov  = hover["s"..i]
        local _,alpha = Anim.staggerValue(stag, i)

        if sel then
            love.graphics.setColor(Colors.accentSoft[1],Colors.accentSoft[2],Colors.accentSoft[3],alpha)
            love.graphics.rectangle("fill", MARGIN, ry, mitad, ROW_H, 12)
            love.graphics.setColor(Colors.accent[1],Colors.accent[2],Colors.accent[3],alpha)
            love.graphics.rectangle("fill", MARGIN, ry, mitad, ROW_H, 12)
            love.graphics.setColor(Colors.accentSoft[1],Colors.accentSoft[2],Colors.accentSoft[3],alpha)
            love.graphics.rectangle("fill", MARGIN+2, ry+2, mitad-4, ROW_H-4, 10)
        elseif isHov then
            love.graphics.setColor(0.95, 0.95, 1, alpha)
            love.graphics.rectangle("fill", MARGIN, ry, mitad, ROW_H, 12)
        else
            love.graphics.setColor(Colors.card[1],Colors.card[2],Colors.card[3],alpha)
            love.graphics.rectangle("fill", MARGIN, ry, mitad, ROW_H, 12)
        end

        love.graphics.setColor(Colors.text[1],Colors.text[2],Colors.text[3],alpha)
        love.graphics.setFont(Fonts.body)
        love.graphics.print(sol.estudiante_nombre or "\xe2\x80\x94", MARGIN+14, ry+12)
        love.graphics.setColor(Colors.textSub[1],Colors.textSub[2],Colors.textSub[3],alpha)
        love.graphics.setFont(Fonts.small)
        love.graphics.print("\xc3\x81rea: "..(sol.area or "\xe2\x80\x94"), MARGIN+14, ry+34)
        love.graphics.print("Urgencia: "..(sol.urgencia or "\xe2\x80\x94"), MARGIN+14, ry+52)
    end

    -- TUTORES
    if #tutores == 0 then
        love.graphics.setColor(Colors.textSub)
        love.graphics.setFont(Fonts.small)
        love.graphics.print("No hay tutores con cupo disponible", col2x, 180)
    end
    for i, t in ipairs(tutores) do
        local ry    = 168 + (i-1)*(ROW_H+12)
        local sel   = selTutor == i
        local isHov = hover["t"..i]
        local _,alpha = Anim.staggerValue(stag, i)
        local cw    = WW - MARGIN - col2x

        if sel then
            love.graphics.setColor(Colors.greenSoft[1],Colors.greenSoft[2],Colors.greenSoft[3],alpha)
            love.graphics.rectangle("fill", col2x, ry, cw, ROW_H, 12)
            love.graphics.setColor(Colors.green[1],Colors.green[2],Colors.green[3],alpha)
            love.graphics.rectangle("fill", col2x, ry, cw, ROW_H, 12)
            love.graphics.setColor(Colors.greenSoft[1],Colors.greenSoft[2],Colors.greenSoft[3],alpha)
            love.graphics.rectangle("fill", col2x+2, ry+2, cw-4, ROW_H-4, 10)
        elseif isHov then
            love.graphics.setColor(0.95, 1, 0.96, alpha)
            love.graphics.rectangle("fill", col2x, ry, cw, ROW_H, 12)
        else
            love.graphics.setColor(Colors.card[1],Colors.card[2],Colors.card[3],alpha)
            love.graphics.rectangle("fill", col2x, ry, cw, ROW_H, 12)
        end

        love.graphics.setColor(Colors.text[1],Colors.text[2],Colors.text[3],alpha)
        love.graphics.setFont(Fonts.body)
        love.graphics.print(t.nombre or "Tutor", col2x+14, ry+12)
        love.graphics.setColor(Colors.textSub[1],Colors.textSub[2],Colors.textSub[3],alpha)
        love.graphics.setFont(Fonts.small)
        love.graphics.print("Tutorados: "..(t.tutorados_activos or 0).." / "..(t.limite or 3), col2x+14, ry+34)
        love.graphics.setColor(Colors.green[1],Colors.green[2],Colors.green[3],alpha)
        love.graphics.print("Con cupo disponible", col2x+14, ry+52)
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

    -- Botones
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

    -- Volver
    if x>=MARGIN and x<=MARGIN+130 and y>=btnY and y<=btnY+46 then
        Nav.to("dashboard", {rol=params.rol, usuario_id=params.usuario_id, nombre=params.nombre}, -1)
        return
    end

    -- Asignar
    if x>=WW-MARGIN-130 and x<=WW-MARGIN and y>=btnY and y<=btnY+46 then
        if not selTutor or not selSolicitud then
            msgError = "Debes seleccionar una solicitud y un tutor"
            return
        end
        local sol   = solicitudes[selSolicitud]
        local tutor = tutores[selTutor]
        -- 1. Buscar estudiante_id desde solicitud
        local est = DB.find("estudiantes", function(e) return e.id == sol.estudiante_id end)
        if not est then msgError = "Error: estudiante no encontrado" return end
        -- 2. Crear tutoria nueva
        DB.insert("tutorias", {
            estudiante_id  = est.id,
            tutor_id       = tutor.id,
            tutor_nombre   = tutor.nombre,
            area           = sol.area,
            estado         = "activa",
            sesiones       = 0,
            ausencias      = 0,
            nivel_avance   = "bajo",
            fecha_inicio   = os.date("%Y-%m-%d"),
        })
        -- 3. Cambiar estado solicitud a asignada
        sol.estado = "asignada"
        -- 4. Sumar tutorado al tutor
        tutor.tutorados_activos = (tutor.tutorados_activos or 0) + 1
        DB.save()
        asig      = true
        msgError  = ""
        -- Recargar para reflejar cambios
        selTutor     = nil
        selSolicitud = nil
        cargarDatos()
        return
    end

    -- Click solicitud
    for i in ipairs(solicitudes) do
        local ry = 168 + (i-1)*(ROW_H+12)
        if x>=MARGIN and x<=MARGIN+mitad and y>=ry and y<=ry+ROW_H then
            selSolicitud = i
            asig = false msgError = ""
            return
        end
    end

    -- Click tutor
    local cw = WW - MARGIN - col2x
    for i in ipairs(tutores) do
        local ry = 168 + (i-1)*(ROW_H+12)
        if x>=col2x and x<=col2x+cw and y>=ry and y<=ry+ROW_H then
            selTutor = i
            asig = false msgError = ""
            return
        end
    end
end

return AS
