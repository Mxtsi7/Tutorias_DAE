-- DashboardScreen: pantalla principal estilo TutorMate
-- Sidebar izquierdo + área principal con tarjetas de tutorías activas
local SM = require("src.screens.ScreenManager")
local UI = require("src.components.UI")
local data = require("src.data.tutorias")

local DashboardScreen = {}
local SIDEBAR_W = 240
local nav = {
    { label = "Dashboard",   screen = "dashboard",   active = true  },
    { label = "Mis Sesiones", screen = "sesion",      active = false },
    { label = "Solicitudes",  screen = "solicitud",   active = false },
    { label = "Seguimiento",  screen = "seguimiento", active = false },
    { label = "Asignación",   screen = "asignacion",  active = false },
}
local hovNav = {}
local hovCards = {}
local params = {}

function DashboardScreen.load(p)
    params = p or { rol = "estudiante" }
    hovNav   = {}
    hovCards = {}
end

local function nombreRol()
    if params.rol == "tutor" then return "Roberto Carlos"
    elseif params.rol == "coordinador" then return "Coordinador"
    else return "Valentina" end
end

local function avanceColor(nivel)
    if nivel == "alto" then return Colors.green
    elseif nivel == "medio" then return Colors.orange
    else return Colors.red end
end

function DashboardScreen.update(dt)
    local mx, my = love.mouse.getPosition()
    for i, n in ipairs(nav) do
        local y = 180 + (i-1)*56
        hovNav[i] = mx >= 0 and mx <= SIDEBAR_W and my >= y and my <= y+44
    end
    for i, t in ipairs(data) do
        local col = (i-1) % 3
        local row = math.floor((i-1) / 3)
        local cx = SIDEBAR_W + 24 + col * 278
        local cy = 340 + row * 220
        hovCards[i] = mx >= cx and mx <= cx+258 and my >= cy and my <= cy+190
    end
end

function DashboardScreen.draw()
    -- ── FONDO ──
    love.graphics.setColor(Colors.bg)
    love.graphics.rectangle("fill", 0, 0, 1100, 720)

    -- ── SIDEBAR ──
    love.graphics.setColor(Colors.sidebar)
    love.graphics.rectangle("fill", 0, 0, SIDEBAR_W, 720)
    love.graphics.setColor(Colors.border)
    love.graphics.rectangle("fill", SIDEBAR_W, 0, 1, 720)

    -- Logo
    love.graphics.setColor(Colors.accent)
    love.graphics.circle("fill", 32, 36, 14)
    love.graphics.setColor(1,1,1)
    love.graphics.setFont(Fonts.small)
    love.graphics.print("T", 27, 27)
    love.graphics.setColor(Colors.text)
    love.graphics.setFont(Fonts.body)
    love.graphics.print("TutorMate", 52, 26)

    -- Avatar usuario
    love.graphics.setColor(Colors.accentSoft)
    love.graphics.circle("fill", 32, 110, 22)
    love.graphics.setColor(Colors.accent)
    love.graphics.setFont(Fonts.body)
    local ini = string.upper(string.sub(nombreRol(), 1, 1))
    love.graphics.print(ini, 25, 100)
    love.graphics.setColor(Colors.text)
    love.graphics.setFont(Fonts.body)
    love.graphics.print(nombreRol(), 60, 100)
    love.graphics.setColor(Colors.textSub)
    love.graphics.setFont(Fonts.small)
    love.graphics.print(string.upper(params.rol or "estudiante"), 60, 118)

    -- Nav items
    for i, n in ipairs(nav) do
        local y = 180 + (i-1)*56
        if n.active then
            love.graphics.setColor(Colors.accentSoft)
            love.graphics.rectangle("fill", 8, y, SIDEBAR_W-16, 40, 10)
        elseif hovNav[i] then
            love.graphics.setColor(Colors.bg)
            love.graphics.rectangle("fill", 8, y, SIDEBAR_W-16, 40, 10)
        end
        love.graphics.setColor(n.active and Colors.accent or Colors.text)
        love.graphics.setFont(Fonts.body)
        love.graphics.print(n.label, 40, y+12)
    end

    -- Botón New Request
    love.graphics.setColor(Colors.accent)
    love.graphics.rectangle("fill", 16, 660, SIDEBAR_W-32, 40, 10)
    love.graphics.setColor(1,1,1)
    love.graphics.setFont(Fonts.body)
    love.graphics.printf("+ Nueva Solicitud", 16, 671, SIDEBAR_W-32, "center")

    -- ── ÁREA PRINCIPAL ──
    local mainX = SIDEBAR_W + 24
    -- Saludo
    love.graphics.setColor(Colors.text)
    love.graphics.setFont(Fonts.big)
    love.graphics.print("Bienvenido, " .. nombreRol() .. "!", mainX, 30)
    love.graphics.setFont(Fonts.body)
    love.graphics.setColor(Colors.textSub)
    love.graphics.print("Tienes " .. #data .. " tutorías activas.", mainX, 68)

    -- Banner próxima sesión
    love.graphics.setColor(Colors.greenSoft)
    love.graphics.rectangle("fill", mainX, 95, 830, 110, 16)
    love.graphics.setColor(Colors.green)
    love.graphics.setFont(Fonts.small)
    love.graphics.rectangle("fill", mainX+14, 115, 90, 22, 8)
    love.graphics.setColor(1,1,1)
    love.graphics.print("Próx. Sesión", mainX+18, 119)
    love.graphics.setColor(Colors.text)
    love.graphics.setFont(Fonts.title)
    love.graphics.print("Estadística Aplicada — Probabilidad", mainX+14, 145)
    love.graphics.setFont(Fonts.small)
    love.graphics.setColor(Colors.textSub)
    love.graphics.print("Hoy, 16:00 hs  ·  45 min", mainX+14, 173)
    -- botón join
    love.graphics.setColor(Colors.card)
    love.graphics.rectangle("fill", mainX+720, 125, 110, 36, 10)
    love.graphics.setColor(Colors.green)
    love.graphics.setFont(Fonts.small)
    love.graphics.printf("Unirse >", mainX+720, 136, 110, "center")

    -- Subtítulo tarjetas
    love.graphics.setColor(Colors.text)
    love.graphics.setFont(Fonts.title)
    love.graphics.print("Tus Tutorías Activas", mainX, 316)

    -- ── TARJETAS ──
    for i, t in ipairs(data) do
        local col = (i-1) % 3
        local row = math.floor((i-1) / 3)
        local cx = mainX + col * 278
        local cy = 346 + row * 220
        local cw, ch = 258, 190

        -- sombra
        love.graphics.setColor(0,0,0,0.05)
        love.graphics.rectangle("fill", cx+3, cy+3, cw, ch, 14)
        -- card
        love.graphics.setColor(hovCards[i] and {0.97,0.97,1} or Colors.card)
        love.graphics.rectangle("fill", cx, cy, cw, ch, 14)

        -- ícono área
        local ac = avanceColor(t.nivel_avance_actual)
        love.graphics.setColor(ac[1],ac[2],ac[3],0.15)
        love.graphics.rectangle("fill", cx+12, cy+14, 38, 38, 8)
        love.graphics.setColor(ac)
        love.graphics.setFont(Fonts.body)
        love.graphics.print("📚", cx+16, cy+20)

        -- nombre área y tutor
        love.graphics.setColor(Colors.text)
        love.graphics.setFont(Fonts.body)
        love.graphics.print(t.area or "Área", cx+58, cy+16)
        love.graphics.setColor(Colors.textSub)
        love.graphics.setFont(Fonts.small)
        love.graphics.print("Tutor ID: " .. t.tutor_id, cx+58, cy+36)

        -- separador
        love.graphics.setColor(Colors.border)
        love.graphics.rectangle("fill", cx+12, cy+60, cw-24, 1)

        -- nivel de avance
        love.graphics.setColor(Colors.textSub)
        love.graphics.setFont(Fonts.small)
        love.graphics.print("NIVEL DE AVANCE", cx+12, cy+70)
        love.graphics.setColor(ac)
        love.graphics.setFont(Fonts.body)
        love.graphics.print(string.upper(t.nivel_avance_actual or "bajo"), cx+12, cy+86)

        -- sesiones texto
        love.graphics.setColor(Colors.textSub)
        love.graphics.setFont(Fonts.small)
        local sesText = t.sesiones_realizadas .. " / 8 Sesiones"
        love.graphics.print(sesText, cx+130, cy+86)

        -- barra de progreso (3 segmentos: bajo / medio / alto)
        local progW = (cw - 24) / 3 - 4
        local niveles = {"bajo", "medio", "alto"}
        local progColors = {Colors.red, Colors.orange, Colors.green}
        local current = t.nivel_avance_actual
        local reached = false
        for pi, nv in ipairs(niveles) do
            local px = cx+12 + (pi-1)*(progW+4)
            local py = cy+110
            if nv == current then reached = true end
            if not reached or nv == current then
                love.graphics.setColor(progColors[pi][1], progColors[pi][2], progColors[pi][3], reached and 1 or 0.25)
            else
                love.graphics.setColor(Colors.border)
            end
            love.graphics.rectangle("fill", px, py, progW, 8, 4)
        end

        -- estado badge
        local badgeC = t.estado == "activa" and Colors.green
                    or t.estado == "activa_con_alerta" and Colors.orange
                    or Colors.textSub
        love.graphics.setColor(badgeC[1], badgeC[2], badgeC[3], 0.15)
        love.graphics.rectangle("fill", cx+12, cy+130, 90, 22, 8)
        love.graphics.setColor(badgeC)
        love.graphics.setFont(Fonts.small)
        love.graphics.printf(t.estado or "activa", cx+12, cy+135, 90, "center")

        -- ausencias si hay
        if t.ausencias_consecutivas and t.ausencias_consecutivas > 0 then
            love.graphics.setColor(Colors.red)
            love.graphics.setFont(Fonts.small)
            love.graphics.print("⚠ " .. t.ausencias_consecutivas .. " ausencia(s)", cx+110, cy+135)
        end
    end
end

function DashboardScreen.mousepressed(x, y, button)
    -- Nav
    for i, n in ipairs(nav) do
        local ny = 180 + (i-1)*56
        if x >= 0 and x <= SIDEBAR_W and y >= ny and y <= ny+44 then
            for j, _ in ipairs(nav) do nav[j].active = false end
            nav[i].active = true
            SM.load(n.screen, { rol = params.rol })
            return
        end
    end
    -- Botón Nueva Solicitud
    if x >= 16 and x <= SIDEBAR_W-16 and y >= 660 and y <= 700 then
        SM.load("solicitud", { rol = params.rol })
    end
end

return DashboardScreen
