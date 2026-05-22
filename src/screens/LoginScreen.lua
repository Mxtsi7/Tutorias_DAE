-- LoginScreen: selector de rol con estilo TutorMate
local SM = require("src.screens.ScreenManager")
local UI = require("src.components.UI")

local LoginScreen = {}
local roles = {
    { label = "Soy Estudiante",   icon = "E", color = {0.494,0.165,1},   screen = "dashboard", rol = "estudiante" },
    { label = "Soy Tutor",        icon = "T", color = {0.133,0.773,0.525}, screen = "dashboard", rol = "tutor" },
    { label = "Soy Coordinador",  icon = "C", color = {1,0.596,0.196},   screen = "dashboard", rol = "coordinador" },
}
local hover = {}

function LoginScreen.load()
    hover = {}
end

function LoginScreen.update(dt)
    local mx, my = love.mouse.getPosition()
    for i, r in ipairs(roles) do
        local x, y, w, h = 400, 200 + (i-1)*120, 300, 90
        hover[i] = mx >= x and mx <= x+w and my >= y and my <= y+h
    end
end

function LoginScreen.draw()
    -- Fondo
    love.graphics.setColor(Colors.bg)
    love.graphics.rectangle("fill", 0, 0, 1100, 720)

    -- Título
    love.graphics.setColor(Colors.text)
    love.graphics.setFont(Fonts.big)
    love.graphics.printf("TutorMate", 0, 120, 1100, "center")
    love.graphics.setFont(Fonts.body)
    love.graphics.setColor(Colors.textSub)
    love.graphics.printf("Sistema de Gestión de Tutorías DAE", 0, 165, 1100, "center")

    -- Tarjetas de rol
    for i, r in ipairs(roles) do
        local x, y, w, h = 400, 200 + (i-1)*120, 300, 90
        local alpha = hover[i] and 1 or 0.85
        -- sombra suave
        love.graphics.setColor(0,0,0,0.06)
        love.graphics.rectangle("fill", x+3, y+3, w, h, 16)
        -- card
        love.graphics.setColor(Colors.card)
        love.graphics.rectangle("fill", x, y, w, h, 16)
        -- borde izquierdo de color
        love.graphics.setColor(r.color)
        love.graphics.rectangle("fill", x, y, 6, h, 4)
        -- ícono círculo
        love.graphics.setColor(r.color[1], r.color[2], r.color[3], 0.15)
        love.graphics.circle("fill", x+46, y+45, 24)
        love.graphics.setColor(r.color)
        love.graphics.setFont(Fonts.title)
        love.graphics.print(r.icon, x+38, y+30)
        -- texto
        love.graphics.setColor(Colors.text)
        love.graphics.setFont(Fonts.title)
        love.graphics.print(r.label, x+82, y+30)
        love.graphics.setFont(Fonts.small)
        love.graphics.setColor(Colors.textSub)
        love.graphics.print("Ingresar como " .. r.rol, x+82, y+56)
        -- hover highlight
        if hover[i] then
            love.graphics.setColor(r.color[1], r.color[2], r.color[3], 0.08)
            love.graphics.rectangle("fill", x, y, w, h, 16)
        end
    end

    love.graphics.setFont(Fonts.small)
    love.graphics.setColor(Colors.textSub)
    love.graphics.printf("Haz clic en tu rol para continuar", 0, 590, 1100, "center")
end

function LoginScreen.mousepressed(x, y, button)
    for i, r in ipairs(roles) do
        local rx, ry, rw, rh = 400, 200 + (i-1)*120, 300, 90
        if x >= rx and x <= rx+rw and y >= ry and y <= ry+rh then
            -- guardar rol actual en global
            CurrentRol = r.rol
            SM.load("dashboard", { rol = r.rol })
        end
    end
end

return LoginScreen
