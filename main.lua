local EventBus      = require("src.events.EventBus")
local EventTypes    = require("src.events.EventTypes")
local ScreenManager = require("src.screens.ScreenManager")
local SolicitudHandler  = require("src.handlers.SolicitudHandler")
local AsignacionHandler = require("src.handlers.AsignacionHandler")
local SesionHandler     = require("src.handlers.SesionHandler")
local AusenciaHandler   = require("src.handlers.AusenciaHandler")
local CierreHandler     = require("src.handlers.CierreHandler")

Colors = {
    bg         = {0.941, 0.945, 0.961},
    sidebar    = {1, 1, 1},
    accent     = {0.494, 0.165, 1},
    accentSoft = {0.914, 0.859, 1},
    green      = {0.133, 0.773, 0.525},
    greenSoft  = {0.859, 0.969, 0.925},
    orange     = {1, 0.596, 0.196},
    card       = {1, 1, 1},
    text       = {0.133, 0.133, 0.2},
    textSub    = {0.553, 0.553, 0.620},
    red        = {0.898, 0.224, 0.224},
    border     = {0.878, 0.878, 0.910},
}

Nav = require("src.anim.Transition")

-- Estado de pantalla completa
Fullscreen = false

function love.load()
    love.graphics.setBackgroundColor(Colors.bg)
    love.graphics.setDefaultFilter("linear", "linear")  -- fix pixelado

    Fonts = {
        title  = love.graphics.newFont(20),
        body   = love.graphics.newFont(14),
        small  = love.graphics.newFont(11),
        big    = love.graphics.newFont(30),
        huge   = love.graphics.newFont(44),
    }

    SolicitudHandler.register(EventBus)
    AsignacionHandler.register(EventBus)
    SesionHandler.register(EventBus)
    AusenciaHandler.register(EventBus)
    CierreHandler.register(EventBus)

    ScreenManager.load("login")
end

function love.update(dt)
    Nav.update(dt)
    ScreenManager.update(dt)
end

function love.draw()
    local W, H = love.graphics.getDimensions()
    local ox = Nav.offsetX()
    if ox ~= 0 then
        love.graphics.push()
        love.graphics.translate(ox, 0)
    end
    ScreenManager.draw()
    if ox ~= 0 then love.graphics.pop() end
    Nav.draw(W, H)

    -- Botón pantalla completa (esquina superior derecha)
    local bx = W - 44
    local mx, my = love.mouse.getPosition()
    local hovFS = mx >= bx and mx <= bx+34 and my >= 6 and my <= 6+34
    love.graphics.setColor(0, 0, 0, hovFS and 0.12 or 0.06)
    love.graphics.rectangle("fill", bx, 6, 34, 34, 6)
    love.graphics.setColor(Colors.text)
    love.graphics.setFont(Fonts.small)
    love.graphics.printf(Fullscreen and "[□]" or "[ ]", bx, 15, 34, "center")
end

function love.keypressed(key)
    if key == "f11" then
        Fullscreen = not Fullscreen
        love.window.setFullscreen(Fullscreen, "desktop")
        return
    end
    if key == "escape" then
        if Fullscreen then
            Fullscreen = false
            love.window.setFullscreen(false)
            return
        end
        if ScreenManager.currentName ~= "login" then
            Nav.to("login", nil, -1)
        else
            love.event.quit()
        end
        return
    end
    ScreenManager.keypressed(key)
end

function love.mousepressed(x, y, button)
    if Nav.active then return end
    -- clic en botón pantalla completa
    local W = love.graphics.getWidth()
    local bx = W - 44
    if x >= bx and x <= bx+34 and y >= 6 and y <= 40 then
        Fullscreen = not Fullscreen
        love.window.setFullscreen(Fullscreen, "desktop")
        return
    end
    ScreenManager.mousepressed(x, y, button)
end

function love.textinput(text)
    ScreenManager.textinput(text)
end
