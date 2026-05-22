-- LoginScreen 1920x1080 con animación de entrada stagger
local Anim = require("src.anim.Anim")

local LoginScreen = {}
local ROLES = {
    { label = "Soy Estudiante",  sub = "Ver tus tutorías activas",      icon = "E", color = {0.494,0.165,1},     rol = "estudiante" },
    { label = "Soy Tutor",       sub = "Registrar sesiones y avance",   icon = "T", color = {0.133,0.773,0.525}, rol = "tutor" },
    { label = "Soy Coordinador", sub = "Gestionar y asignar tutorías",  icon = "C", color = {1,0.596,0.196},    rol = "coordinador" },
}
local hover  = {}
local stag   = {}
local titleA = nil  -- anim para el título
local logoRot = 0

local CW, CH = 440, 110   -- card width / height
local TOTAL_W = #ROLES * CW + (#ROLES-1)*30
local START_X = (1920 - TOTAL_W) / 2
local CARD_Y  = 540

function LoginScreen.load()
    hover  = {}
    stag   = Anim.staggerList(#ROLES, 0.08, 0.45)
    titleA = Anim.new(0, 1, 0.6, "easeOut")
    logoRot = 0
end

function LoginScreen.update(dt)
    titleA:update(dt)
    Anim.staggerUpdate(stag, dt)
    logoRot = logoRot + dt * 40  -- rotación suave del logo
    local mx, my = love.mouse.getPosition()
    for i = 1, #ROLES do
        local cx = START_X + (i-1)*(CW+30)
        hover[i] = mx>=cx and mx<=cx+CW and my>=CARD_Y and my<=CARD_Y+CH
    end
end

function LoginScreen.draw()
    -- Fondo con gradiente simulado (dos rectángulos)
    love.graphics.setColor(0.941,0.945,0.961)
    love.graphics.rectangle("fill",0,0,1920,1080)
    love.graphics.setColor(0.494,0.165,1, 0.04)
    love.graphics.rectangle("fill",0,0,1920,540)

    -- Círculo decorativo fondo
    love.graphics.setColor(0.494,0.165,1, 0.06)
    love.graphics.circle("fill", 200, 200, 320)
    love.graphics.setColor(0.133,0.773,0.525, 0.05)
    love.graphics.circle("fill", 1720, 880, 280)

    -- Logo animado
    local lAlpha = titleA:value()
    love.graphics.setColor(0.494,0.165,1, lAlpha)
    love.graphics.circle("fill", 960, 260, 52)
    love.graphics.setColor(1,1,1, lAlpha)
    love.graphics.setFont(Fonts.title)
    love.graphics.printf("T", 935, 238, 52, "center")

    -- Título con fade
    love.graphics.setColor(Colors.text[1],Colors.text[2],Colors.text[3], lAlpha)
    love.graphics.setFont(Fonts.huge)
    love.graphics.printf("TutorMate", 0, 330, 1920, "center")
    love.graphics.setFont(Fonts.body)
    love.graphics.setColor(Colors.textSub[1],Colors.textSub[2],Colors.textSub[3], lAlpha)
    love.graphics.printf("Sistema de Gestión de Tutorías DAE", 0, 400, 1920, "center")
    love.graphics.printf("Selecciona tu rol para continuar", 0, 432, 1920, "center")

    -- Tarjetas con stagger
    for i, r in ipairs(ROLES) do
        local cx = START_X + (i-1)*(CW+30)
        local offY, alpha = Anim.staggerValue(stag, i)
        local cy = CARD_Y + offY
        local sc = hover[i] and 1.03 or 1.0  -- escala hover

        -- sombra
        love.graphics.setColor(0,0,0, 0.07*alpha)
        love.graphics.rectangle("fill", cx+4, cy+6, CW, CH, 18)
        -- card
        love.graphics.setColor(1,1,1, alpha)
        love.graphics.rectangle("fill", cx, cy, CW, CH, 18)
        -- borde color izquierdo
        love.graphics.setColor(r.color[1],r.color[2],r.color[3], alpha)
        love.graphics.rectangle("fill", cx, cy, 7, CH, 5)
        -- hover highlight
        if hover[i] then
            love.graphics.setColor(r.color[1],r.color[2],r.color[3], 0.07)
            love.graphics.rectangle("fill", cx, cy, CW, CH, 18)
        end
        -- círculo icono
        love.graphics.setColor(r.color[1],r.color[2],r.color[3], 0.15*alpha)
        love.graphics.circle("fill", cx+54, cy+CH/2, 28)
        love.graphics.setColor(r.color[1],r.color[2],r.color[3], alpha)
        love.graphics.setFont(Fonts.title)
        love.graphics.print(r.icon, cx+42, cy+CH/2-16)
        -- textos
        love.graphics.setColor(Colors.text[1],Colors.text[2],Colors.text[3], alpha)
        love.graphics.setFont(Fonts.title)
        love.graphics.print(r.label, cx+100, cy+26)
        love.graphics.setColor(Colors.textSub[1],Colors.textSub[2],Colors.textSub[3], alpha)
        love.graphics.setFont(Fonts.small)
        love.graphics.print(r.sub, cx+100, cy+62)
        -- flecha
        love.graphics.setColor(r.color[1],r.color[2],r.color[3], hover[i] and alpha or alpha*0.4)
        love.graphics.setFont(Fonts.body)
        love.graphics.print("→", cx+CW-44, cy+CH/2-10)
    end

    -- versión
    love.graphics.setColor(Colors.textSub)
    love.graphics.setFont(Fonts.small)
    love.graphics.printf("v1.0  ·  DAE 2026", 0, 1040, 1920, "center")
end

function LoginScreen.mousepressed(x, y, btn)
    for i, r in ipairs(ROLES) do
        local cx = START_X + (i-1)*(CW+30)
        if x>=cx and x<=cx+CW and y>=CARD_Y and y<=CARD_Y+CH then
            CurrentRol = r.rol
            Nav.to("dashboard", { rol = r.rol }, 1)
        end
    end
end

return LoginScreen
