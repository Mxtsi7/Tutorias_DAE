-- UI.lua: helpers reutilizables con dibujo limpio (sin pixelado)
local UI = {}

-- Rect redondeado con sombra suave (sin line, solo fills)
function UI.card(x, y, w, h, r)
    r = r or 12
    love.graphics.setColor(0,0,0,0.05)
    love.graphics.rectangle("fill", x+2, y+3, w, h, r)
    love.graphics.setColor(Colors.card)
    love.graphics.rectangle("fill", x, y, w, h, r)
end

-- Borde simulado con dos rectangulos (evita pixelado de "line")
function UI.border(x, y, w, h, r, color, thick)
    thick = thick or 1.5
    local c = color or Colors.border
    love.graphics.setColor(c)
    love.graphics.rectangle("fill", x, y, w, h, r)
    love.graphics.setColor(Colors.bg)
    love.graphics.rectangle("fill", x+thick, y+thick, w-thick*2, h-thick*2, r-1)
end

-- Badge de estado: texto siempre en una sola línea, ancho automático
function UI.badge(x, y, label, color, font)
    font = font or Fonts.small
    love.graphics.setFont(font)
    local tw = font:getWidth(label)
    local bw = tw + 20
    local bh = 24
    love.graphics.setColor(color[1],color[2],color[3],0.15)
    love.graphics.rectangle("fill", x, y, bw, bh, bh/2)
    love.graphics.setColor(color)
    love.graphics.print(label, x + 10, y + 5)
    return bw
end

-- Botón simple
function UI.button(x, y, w, h, label, color, mx, my)
    local hov = mx>=x and mx<=x+w and my>=y and my<=y+h
    local c = color or Colors.accent
    love.graphics.setColor(c[1],c[2],c[3], hov and 0.85 or 1)
    love.graphics.rectangle("fill", x, y, w, h, 10)
    love.graphics.setColor(1,1,1)
    love.graphics.setFont(Fonts.body)
    love.graphics.printf(label, x, y + h/2 - 8, w, "center")
    return hov
end

-- Barra de progreso tricolor (bajo/medio/alto)
function UI.progressBar3(x, y, w, h, nivel)
    local segs = {"bajo","medio","alto"}
    local cols = {Colors.red, Colors.orange, Colors.green}
    local segW = (w - 8) / 3
    for i, nv in ipairs(segs) do
        local active = (nv == nivel)
        local filled = (nivel=="alto") or (nivel=="medio" and i<=2) or (i==1)
        local alpha = filled and 1 or 0.2
        love.graphics.setColor(cols[i][1],cols[i][2],cols[i][3],alpha)
        love.graphics.rectangle("fill", x+(i-1)*(segW+4), y, segW, h, h/2)
    end
end

-- Ícono de área (rect de color en lugar de emoji para evitar pixelado)
function UI.areaIcon(x, y, color)
    love.graphics.setColor(color[1],color[2],color[3],0.18)
    love.graphics.rectangle("fill", x, y, 38, 38, 8)
    love.graphics.setColor(color)
    -- librito simple: 3 líneas
    love.graphics.rectangle("fill", x+9,  y+10, 20, 18, 3)
    love.graphics.setColor(1,1,1)
    love.graphics.rectangle("fill", x+12, y+14, 14, 2, 1)
    love.graphics.rectangle("fill", x+12, y+18, 14, 2, 1)
    love.graphics.rectangle("fill", x+12, y+22, 10, 2, 1)
end

return UI
