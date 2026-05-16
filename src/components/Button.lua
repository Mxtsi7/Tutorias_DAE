-- Button.lua: Componente reutilizable de botón con animación hover

local Button = {}
Button.__index = Button

function Button.new(x, y, ancho, alto, texto, callback)
    -- TODO: crear botón en posición (x,y) con tamaño, texto y función al hacer clic
end

function Button:update(dt)
    -- TODO: detectar hover del mouse y animar color/tamaño
end

function Button:draw()
    -- TODO: dibujar rectángulo redondeado, texto centrado y efecto hover
end

function Button:click(mx, my)
    -- TODO: verificar si el clic cae dentro del botón y ejecutar callback
end

return Button
