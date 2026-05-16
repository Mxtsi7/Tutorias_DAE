-- ScreenManager.lua: Gestiona el cambio entre pantallas de la aplicación

local ScreenManager = {}
ScreenManager.current = nil
ScreenManager.screens = {}

function ScreenManager.load(nombre)
    -- TODO: cargar la pantalla correspondiente al nombre
    -- Ejemplo: "menu" -> MenuScreen, "solicitud" -> SolicitudScreen
end

function ScreenManager.update(dt)
    -- TODO: llamar current:update(dt) si existe
end

function ScreenManager.draw()
    -- TODO: llamar current:draw() si existe
end

function ScreenManager.keypressed(key)
    -- TODO: delegar keypressed a la pantalla actual
end

function ScreenManager.mousepressed(x, y, button)
    -- TODO: delegar click a la pantalla actual
end

function ScreenManager.textinput(text)
    -- TODO: delegar input de texto a la pantalla actual
end

return ScreenManager
