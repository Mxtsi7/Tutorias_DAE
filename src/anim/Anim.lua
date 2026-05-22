-- Anim.lua: tweens simples para valores numéricos
-- Uso:
--   local a = Anim.new(0, 1, 0.4, "easeOut")
--   a:update(dt)
--   a:value()  → número interpolado
--   a:done()   → true cuando terminó

local Anim = {}
Anim.__index = Anim

local function easeOut(t)  return 1 - (1-t)^3 end
local function easeIn(t)   return t^3 end
local function easeInOut(t)
    if t < 0.5 then return 4*t^3 else return 1 - (-2*t+2)^3/2 end
end
local function linear(t) return t end

local curves = {
    easeOut = easeOut, easeIn = easeIn,
    easeInOut = easeInOut, linear = linear
}

function Anim.new(from, to, duration, curve)
    local self = setmetatable({}, Anim)
    self.from     = from
    self.to       = to
    self.duration = duration or 0.35
    self.curve    = curves[curve or "easeOut"]
    self.t        = 0
    self._done    = false
    return self
end

function Anim:update(dt)
    if self._done then return end
    self.t = math.min(self.t + dt / self.duration, 1)
    if self.t >= 1 then self._done = true end
end

function Anim:value()
    return self.from + (self.to - self.from) * self.curve(self.t)
end

function Anim:done() return self._done end

function Anim:reset()
    self.t = 0
    self._done = false
end

-- Utilidad: animar una lista de tarjetas entrando desde abajo (stagger)
function Anim.staggerList(n, delay, duration)
    local list = {}
    for i = 1, n do
        list[i] = { timer = -(i-1)*delay, duration = duration or 0.4 }
    end
    return list
end

function Anim.staggerUpdate(list, dt)
    for _, item in ipairs(list) do
        item.timer = item.timer + dt
    end
end

-- Devuelve offsetY y alpha para el elemento i de la lista stagger
function Anim.staggerValue(list, i)
    local item = list[i]
    if not item then return 0, 1 end
    local t = math.max(0, math.min(item.timer / item.duration, 1))
    t = 1 - (1-t)^3  -- easeOut
    return (1-t) * 40, t  -- offsetY, alpha
end

return Anim
