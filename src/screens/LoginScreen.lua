-- LoginScreen centrado dinámico (sin hardcode de 1920/1080)
local Anim = require("src.anim.Anim")

local LoginScreen = {}
local ROLES = {
    { label = "Soy Estudiante",  sub = "Ver tus tutorías activas",      icon = "E", color = {0.494,0.165,1},     rol = "estudiante" },
    { label = "Soy Tutor",       sub = "Registrar sesiones y avance",   icon = "T", color = {0.133,0.773,0.525}, rol = "tutor" },
    { label = "Soy Coordinador", sub = "Gestionar y asignar tutorías",  icon = "C", color = {1,0.596,0.196},    rol = "coordinador" },
}
local hover  = {}
local stag   = {}
local titleA = nil

local function W() return love.graphics.getWidth() end
local function H() return love.graphics.getHeight() end

-- Tamaño de tarjeta proporcional al ancho disponible
local function cardSize()
    local ww = W()
    local gap = math.floor(ww * 0.02)
    local cw  = math.floor((ww * 0.80) / #ROLES - gap)
    local ch  = math.max(90, math.floor(H() * 0.13))
    return cw, ch, gap
end

local function startX()
    local cw, ch, gap = cardSize()
    local total = #ROLES * cw + (#ROLES-1)*gap
    return math.floor((W() - total) / 2)
end

local function cardY()
    return math.floor(H() * 0.62)
end

function LoginScreen.load()
    hover  = {}
    stag   = Anim.staggerList(#ROLES, 0.08, 0.45)
    titleA = Anim.new(0, 1, 0.6, "easeOut")
end

function LoginScreen.update(dt)
    titleA:update(dt)
    Anim.staggerUpdate(stag, dt)
    local mx, my = love.mouse.getPosition()
    local cw, ch, gap = cardSize()
    local sx = startX()
    local cy = cardY()
    for i = 1, #ROLES do
        local cx = sx + (i-1)*(cw+gap)
        hover[i] = mx>=cx and mx<=cx+cw and my>=cy and my<=cy+ch
    end
end

function LoginScreen.draw()
    local ww, hh = W(), H()
    local lAlpha = titleA:value()
    local cw, ch, gap = cardSize()
    local sx = startX()
    local cy = cardY()

    -- Fondo
    love.graphics.setColor(0.941, 0.945, 0.961)
    love.graphics.rectangle("fill", 0, 0, ww, hh)
    love.graphics.setColor(0.494, 0.165, 1, 0.04)
    love.graphics.rectangle("fill", 0, 0, ww, hh*0.5)

    -- Círculos decorativos (proporcionales)
    love.graphics.setColor(0.494, 0.165, 1, 0.06)
    love.graphics.circle("fill", ww*0.12, hh*0.22, ww*0.17)
    love.graphics.setColor(0.133, 0.773, 0.525, 0.05)
    love.graphics.circle("fill", ww*0.88, hh*0.82, ww*0.13)

    -- Logo
    local logoY = math.floor(hh * 0.22)
    local logoR = math.floor(math.min(ww, hh) * 0.045)
    love.graphics.setColor(0.494, 0.165, 1, lAlpha)
    love.graphics.circle("fill", ww/2, logoY, logoR)
    love.graphics.setColor(1, 1, 1, lAlpha)
    love.graphics.setFont(Fonts.title)
    love.graphics.printf("T", ww/2 - logoR, logoY - logoR*0.55, logoR*2, "center")

    -- Título
    local titleY = math.floor(hh * 0.37)
    love.graphics.setColor(Colors.text[1], Colors.text[2], Colors.text[3], lAlpha)
    love.graphics.setFont(Fonts.huge)
    love.graphics.printf("TutorMate", 0, titleY, ww, "center")

    love.graphics.setFont(Fonts.body)
    love.graphics.setColor(Colors.textSub[1], Colors.textSub[2], Colors.textSub[3], lAlpha)
    love.graphics.printf("Sistema de Gestión de Tutorías DAE", 0, titleY + 58, ww, "center")
    love.graphics.printf("Selecciona tu rol para continuar",   0, titleY + 82, ww, "center")

    -- Tarjetas
    for i, r in ipairs(ROLES) do
        local cx  = sx + (i-1)*(cw+gap)
        local offY, alpha = Anim.staggerValue(stag, i)
        local ty  = cy + offY

        -- sombra
        love.graphics.setColor(0, 0, 0, 0.07*alpha)
        love.graphics.rectangle("fill", cx+3, ty+5, cw, ch, 16)
        -- fondo card
        love.graphics.setColor(1, 1, 1, alpha)
        love.graphics.rectangle("fill", cx, ty, cw, ch, 16)
        -- borde color izquierdo
        love.graphics.setColor(r.color[1], r.color[2], r.color[3], alpha)
        love.graphics.rectangle("fill", cx, ty, 6, ch, 5)
        -- hover
        if hover[i] then
            love.graphics.setColor(r.color[1], r.color[2], r.color[3], 0.07)
            love.graphics.rectangle("fill", cx, ty, cw, ch, 16)
        end
        -- círculo icono
        local iconR  = math.floor(ch * 0.28)
        local iconCX = cx + 24 + iconR
        local iconCY = ty + ch/2
        love.graphics.setColor(r.color[1], r.color[2], r.color[3], 0.15*alpha)
        love.graphics.circle("fill", iconCX, iconCY, iconR)
        love.graphics.setColor(r.color[1], r.color[2], r.color[3], alpha)
        love.graphics.setFont(Fonts.body)
        love.graphics.printf(r.icon, cx+24, iconCY - 9, iconR*2, "center")
        -- textos
        local tx = cx + 24 + iconR*2 + 14
        love.graphics.setColor(Colors.text[1], Colors.text[2], Colors.text[3], alpha)
        love.graphics.setFont(Fonts.body)
        love.graphics.print(r.label, tx, ty + math.floor(ch*0.22))
        love.graphics.setColor(Colors.textSub[1], Colors.textSub[2], Colors.textSub[3], alpha)
        love.graphics.setFont(Fonts.small)
        love.graphics.print(r.sub, tx, ty + math.floor(ch*0.56))
        -- flecha
        love.graphics.setColor(r.color[1], r.color[2], r.color[3], hover[i] and alpha or alpha*0.35)
        love.graphics.setFont(Fonts.body)
        love.graphics.print(">", cx + cw - 28, ty + ch/2 - 9)
    end

    -- versión
    love.graphics.setColor(Colors.textSub)
    love.graphics.setFont(Fonts.small)
    love.graphics.printf("v1.0  ·  DAE 2026", 0, hh - 28, ww, "center")
end

function LoginScreen.mousepressed(x, y, btn)
    local cw, ch, gap = cardSize()
    local sx = startX()
    local cy = cardY()
    for i, r in ipairs(ROLES) do
        local cx = sx + (i-1)*(cw+gap)
        if x>=cx and x<=cx+cw and y>=cy and y<=cy+ch then
            CurrentRol = r.rol
            Nav.to("dashboard", { rol = r.rol }, 1)
        end
    end
end

return LoginScreen
