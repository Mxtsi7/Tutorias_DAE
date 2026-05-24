local Modal = {}
Modal.__index = Modal

function Modal.new(titulo, contenido, opciones)
    local self = setmetatable({}, Modal)
    self.titulo    = titulo    or ""
    self.contenido = contenido or ""
    self.opciones  = opciones  or {}
    self.visible   = false
    self.alpha     = 0
    self.hover     = {}
    return self
end

function Modal:show()
    self.visible = true
    self.alpha   = 0
end

function Modal:hide()
    self.visible = false
end

function Modal:update(dt)
    if not self.visible then return end
    self.alpha = math.min(1, self.alpha + dt * 6)
    local mx, my = love.mouse.getPosition()
    local WW = love.graphics.getWidth()
    local HH = love.graphics.getHeight()
    local mw = 440
    local mh = 180 + #self.opciones * 52
    local mx0 = math.floor((WW - mw) / 2)
    local my0 = math.floor((HH - mh) / 2)
    for i in ipairs(self.opciones) do
        local bx = mx0 + 24 + (i-1) * 148
        local by = my0 + mh - 64
        self.hover[i] = mx >= bx and mx <= bx+124 and my >= by and my <= by+40
    end
end

function Modal:draw()
    if not self.visible then return end
    local a  = self.alpha
    local WW = love.graphics.getWidth()
    local HH = love.graphics.getHeight()
    local mw = 440
    local mh = 180 + #self.opciones * 52
    local mx0 = math.floor((WW - mw) / 2)
    local my0 = math.floor((HH - mh) / 2)
    love.graphics.setColor(0, 0, 0, 0.45 * a)
    love.graphics.rectangle("fill", 0, 0, WW, HH)
    love.graphics.setColor(0, 0, 0, 0.10 * a)
    love.graphics.rectangle("fill", mx0+4, my0+6, mw, mh, 16)
    love.graphics.setColor(1, 1, 1, a)
    love.graphics.rectangle("fill", mx0, my0, mw, mh, 16)
    love.graphics.setColor(Colors.accent[1], Colors.accent[2], Colors.accent[3], a)
    love.graphics.rectangle("fill", mx0, my0, mw, 56, 16)
    love.graphics.rectangle("fill", mx0, my0+36, mw, 20, 0)
    love.graphics.setColor(1, 1, 1, a)
    love.graphics.setFont(Fonts.title)
    love.graphics.printf(self.titulo, mx0, my0+16, mw, "center")
    love.graphics.setColor(Colors.text[1], Colors.text[2], Colors.text[3], a)
    love.graphics.setFont(Fonts.body)
    love.graphics.printf(self.contenido, mx0+24, my0+72, mw-48, "left")
    for i, op in ipairs(self.opciones) do
        local bx = mx0 + 24 + (i-1) * 148
        local by = my0 + mh - 64
        local c  = op.color or Colors.accent
        love.graphics.setColor(c[1], c[2], c[3], self.hover[i] and 0.8*a or a)
        love.graphics.rectangle("fill", bx, by, 124, 40, 10)
        love.graphics.setColor(1, 1, 1, a)
        love.graphics.setFont(Fonts.body)
        love.graphics.printf(op.label, bx, by+11, 124, "center")
    end
end

function Modal:mousepressed(x, y)
    if not self.visible then return false end
    local WW = love.graphics.getWidth()
    local HH = love.graphics.getHeight()
    local mw = 440
    local mh = 180 + #self.opciones * 52
    local mx0 = math.floor((WW - mw) / 2)
    local my0 = math.floor((HH - mh) / 2)
    for i, op in ipairs(self.opciones) do
        local bx = mx0 + 24 + (i-1) * 148
        local by = my0 + mh - 64
        if x >= bx and x <= bx+124 and y >= by and y <= by+40 then
            if op.callback then op.callback() end
            self:hide()
            return true
        end
    end
    return false
end

return Modal
