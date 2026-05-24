local Button = {}
Button.__index = Button

function Button.new(x, y, ancho, alto, texto, callback, color)
    local self = setmetatable({}, Button)
    self.x        = x
    self.y        = y
    self.ancho    = ancho
    self.alto     = alto
    self.texto    = texto
    self.callback = callback
    self.color    = color or Colors.accent
    self.hover    = false
    return self
end

function Button:update(dt)
    local mx, my = love.mouse.getPosition()
    self.hover = mx >= self.x and mx <= self.x + self.ancho and
                 my >= self.y and my <= self.y + self.alto
end

function Button:draw()
    local c = self.color
    love.graphics.setColor(0, 0, 0, self.hover and 0.10 or 0.05)
    love.graphics.rectangle("fill", self.x+2, self.y+3, self.ancho, self.alto, 10)
    love.graphics.setColor(c[1], c[2], c[3], self.hover and 0.85 or 1.0)
    love.graphics.rectangle("fill", self.x, self.y, self.ancho, self.alto, 10)
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(Fonts.body)
    love.graphics.printf(self.texto, self.x, self.y + self.alto/2 - 8, self.ancho, "center")
end

function Button:click(mx, my)
    if mx >= self.x and mx <= self.x + self.ancho and
       my >= self.y and my <= self.y + self.alto then
        if self.callback then self.callback() end
        return true
    end
    return false
end

return Button
