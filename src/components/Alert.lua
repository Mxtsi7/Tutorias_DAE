local Alert = {}
Alert.__index = Alert

function Alert.new(mensaje, tipo)
    local self = setmetatable({}, Alert)
    self.mensaje  = mensaje or ""
    self.tipo     = tipo    or "info"
    self.timer    = 3.5
    self.alpha    = 0
    self.expirada = false
    self.colores  = {
        info    = Colors and Colors.accent  or {0.494,0.165,1},
        success = Colors and Colors.green   or {0.133,0.773,0.525},
        warning = Colors and Colors.orange  or {1,0.596,0.196},
        error   = Colors and Colors.red     or {0.898,0.224,0.224},
    }
    return self
end

function Alert:update(dt)
    if self.expirada then return end
    self.timer = self.timer - dt
    if self.timer > 3.0 then
        self.alpha = math.min(1, self.alpha + dt * 4)
    elseif self.timer < 0.5 then
        self.alpha = math.max(0, self.alpha - dt * 4)
    end
    if self.timer <= 0 then self.expirada = true end
end

function Alert:draw(x, y, w)
    if self.expirada or self.alpha <= 0 then return end
    local c = self.colores[self.tipo] or self.colores.info
    love.graphics.setColor(c[1], c[2], c[3], 0.15 * self.alpha)
    love.graphics.rectangle("fill", x, y, w, 44, 10)
    love.graphics.setColor(c[1], c[2], c[3], self.alpha)
    love.graphics.rectangle("fill", x, y, 4, 44, 4)
    love.graphics.setFont(Fonts.body)
    love.graphics.printf(self.mensaje, x + 16, y + 14, w - 24, "left")
end

return Alert
