-- UI.lua: helpers de dibujo reutilizables
local UI = {}

-- Dibuja rectángulo redondeado con sombra suave
function UI.card(x, y, w, h, r)
    r = r or 14
    love.graphics.setColor(0,0,0,0.05)
    love.graphics.rectangle("fill", x+3, y+3, w, h, r)
    love.graphics.setColor(Colors.card)
    love.graphics.rectangle("fill", x, y, w, h, r)
end

-- Botón con hover
function UI.button(x, y, w, h, label, color, mx, my)
    local isHov = mx >= x and mx <= x+w and my >= y and my <= y+h
    local c = color or Colors.accent
    love.graphics.setColor(c[1], c[2], c[3], isHov and 0.85 or 1)
    love.graphics.rectangle("fill", x, y, w, h, 10)
    love.graphics.setColor(1,1,1)
    love.graphics.setFont(Fonts.body)
    love.graphics.printf(label, x, y + h/2 - 8, w, "center")
    return isHov
end

-- Badge de estado
function UI.badge(x, y, label, color)
    love.graphics.setColor(color[1],color[2],color[3],0.15)
    love.graphics.rectangle("fill", x, y, 90, 22, 8)
    love.graphics.setColor(color)
    love.graphics.setFont(Fonts.small)
    love.graphics.printf(label, x, y+4, 90, "center")
end

-- Barra de progreso
function UI.progressBar(x, y, w, h, value, maxValue, color)
    love.graphics.setColor(Colors.border)
    love.graphics.rectangle("fill", x, y, w, h, h/2)
    love.graphics.setColor(color)
    local fillW = math.max(0, math.min(w, w * (value/maxValue)))
    love.graphics.rectangle("fill", x, y, fillW, h, h/2)
end

return UI
