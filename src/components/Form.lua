local Form = {}
Form.__index = Form

function Form.new(campos)
    local self = setmetatable({}, Form)
    self.campos  = {}
    self.activo  = 1
    self.cursor  = 0
    for _, c in ipairs(campos) do
        self.campos[#self.campos+1] = {
            label       = c.label       or "",
            placeholder = c.placeholder or "",
            value       = c.value       or "",
            error       = false,
        }
    end
    return self
end

function Form:update(dt)
    self.cursor = self.cursor + dt
    if self.cursor > 1 then self.cursor = 0 end
end

function Form:draw(x, y, ancho)
    local altoCampo = 80
    for i, c in ipairs(self.campos) do
        local fy = y + (i-1) * altoCampo
        local isFocus = (i == self.activo)
        love.graphics.setColor(Colors.text)
        love.graphics.setFont(Fonts.body)
        love.graphics.print(c.label, x, fy)
        local bc = isFocus and Colors.accent or (c.error and Colors.red or Colors.border)
        love.graphics.setColor(bc)
        love.graphics.rectangle("fill", x, fy+22, ancho, 42, 10)
        local ibg = isFocus and {0.97,0.96,1} or (c.error and {0.99,0.96,0.96} or {1,1,1})
        love.graphics.setColor(ibg)
        love.graphics.rectangle("fill", x+2, fy+24, ancho-4, 38, 9)
        love.graphics.setFont(Fonts.body)
        if c.value ~= "" then
            love.graphics.setColor(Colors.text)
            local cur = (isFocus and self.cursor < 0.5) and "_" or ""
            love.graphics.print(c.value .. cur, x+12, fy+33)
        else
            love.graphics.setColor(Colors.textSub)
            love.graphics.print(c.placeholder, x+12, fy+33)
        end
        if c.error then
            love.graphics.setColor(Colors.red)
            love.graphics.setFont(Fonts.small)
            love.graphics.print("Campo obligatorio", x+12, fy+66)
        end
    end
end

function Form:mousepressed(x, y, px, py, ancho)
    local altoCampo = 80
    for i in ipairs(self.campos) do
        local fy = py + (i-1) * altoCampo
        if x >= px and x <= px+ancho and y >= fy+22 and y <= fy+64 then
            self.activo = i
            return true
        end
    end
    return false
end

function Form:textinput(texto)
    local c = self.campos[self.activo]
    if c then c.value = c.value .. texto end
end

function Form:keypressed(key)
    if key == "tab" then
        self.activo = (self.activo % #self.campos) + 1
    elseif key == "backspace" then
        local c = self.campos[self.activo]
        if c and #c.value > 0 then c.value = string.sub(c.value, 1, -2) end
    end
end

function Form:getValores()
    local vals = {}
    for _, c in ipairs(self.campos) do vals[#vals+1] = c.value end
    return vals
end

function Form:validar()
    local valido = true
    for _, c in ipairs(self.campos) do
        c.error = (c.value == "")
        if c.error then valido = false end
    end
    return valido
end

function Form:resetear()
    for _, c in ipairs(self.campos) do c.value = "" c.error = false end
    self.activo = 1
end

return Form
