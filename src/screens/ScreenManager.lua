local ScreenManager = {}
ScreenManager.current     = nil
ScreenManager.currentName = ""

local registry = {
    login       = "src.screens.LoginScreen",
    dashboard   = "src.screens.DashboardScreen",
    solicitud   = "src.screens.SolicitudScreen",
    asignacion  = "src.screens.AsignacionScreen",
    sesion      = "src.screens.SesionScreen",
    seguimiento = "src.screens.SeguimientoScreen",
}

function ScreenManager.load(name, params)
    local path = registry[name]
    if not path then return end
    local Screen = require(path)
    ScreenManager.current     = Screen
    ScreenManager.currentName = name
    if Screen.load then Screen.load(params) end
end

function ScreenManager.update(dt)
    if ScreenManager.current and ScreenManager.current.update then
        ScreenManager.current.update(dt)
    end
end

function ScreenManager.draw()
    if ScreenManager.current and ScreenManager.current.draw then
        ScreenManager.current.draw()
    end
end

function ScreenManager.keypressed(key)
    if ScreenManager.current and ScreenManager.current.keypressed then
        ScreenManager.current.keypressed(key)
    end
end

function ScreenManager.mousepressed(x, y, button)
    if ScreenManager.current and ScreenManager.current.mousepressed then
        ScreenManager.current.mousepressed(x, y, button)
    end
end

function ScreenManager.textinput(text)
    if ScreenManager.current and ScreenManager.current.textinput then
        ScreenManager.current.textinput(text)
    end
end

return ScreenManager
