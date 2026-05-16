-- conf.lua: Configuración de la ventana LÖVE2D

function love.conf(t)
    t.title = "Sistema de Tutorías DAE"
    t.version = "11.4"
    t.window.width = 1024
    t.window.height = 768
    t.window.resizable = false
    t.window.vsync = 1
end
