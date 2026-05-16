-- main.lua: Punto de entrada principal de la aplicación
-- Inicializa el EventBus, registra los handlers y carga la primera pantalla

local EventBus = require("src.events.EventBus")
local ScreenManager = require("src.screens.ScreenManager")
local SolicitudHandler = require("src.handlers.SolicitudHandler")
local AsignacionHandler = require("src.handlers.AsignacionHandler")
local SesionHandler = require("src.handlers.SesionHandler")
local AusenciaHandler = require("src.handlers.AusenciaHandler")
local CierreHandler = require("src.handlers.CierreHandler")

function love.load()
    -- Configuración visual base
    love.graphics.setBackgroundColor(0.1, 0.1, 0.15)

    -- Registrar todos los handlers en el EventBus
    SolicitudHandler.register(EventBus)
    AsignacionHandler.register(EventBus)
    SesionHandler.register(EventBus)
    AusenciaHandler.register(EventBus)
    CierreHandler.register(EventBus)

    -- Cargar pantalla inicial
    ScreenManager.load("menu")
end

function love.update(dt)
    ScreenManager.update(dt)
end

function love.draw()
    ScreenManager.draw()
end

function love.keypressed(key)
    if key == "escape" then
        love.event.quit()
    end
    ScreenManager.keypressed(key)
end

function love.mousepressed(x, y, button)
    ScreenManager.mousepressed(x, y, button)
end

function love.textinput(text)
    ScreenManager.textinput(text)
end
