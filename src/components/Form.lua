-- Form.lua: Componente reutilizable de formulario con campos de texto

local Form = {}
Form.__index = Form

function Form.new(campos)
    -- TODO: inicializar lista de campos con label, placeholder y valor
end

function Form:update(dt)
    -- TODO: manejar campo activo y cursor de texto
end

function Form:draw()
    -- TODO: dibujar cada campo con label, input y borde de validación
end

function Form:textinput(text)
    -- TODO: agregar texto al campo actualmente activo
end

function Form:getValores()
    -- TODO: retornar tabla con todos los valores ingresados
end

return Form
