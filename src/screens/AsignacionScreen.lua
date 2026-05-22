local SM     = require("src.screens.ScreenManager")
local Anim   = require("src.anim.Anim")
local EventBus   = require("src.events.EventBus")
local EventTypes = require("src.events.EventTypes")
local tutores    = require("src.data.tutores")

local AsignacionScreen = {}
local selec  = nil
local hover  = {}
local stag   = {}
local asig   = false
local params = {}

function AsignacionScreen.load(p)
    params=p or {} selec=nil asig=false hover={}
    stag=Anim.staggerList(#tutores,0.07,0.4)
end

function AsignacionScreen.update(dt)
    Anim.staggerUpdate(stag,dt)
    local mx,my=love.mouse.getPosition()
    for i,t in ipairs(tutores) do
        local ry=200+(i-1)*110
        hover[i]=mx>=80 and mx<=1840 and my>=ry and my<=ry+92
    end
end

function AsignacionScreen.draw()
    love.graphics.setColor(Colors.bg)
    love.graphics.rectangle("fill",0,0,1920,1080)
    love.graphics.setColor(Colors.accent)
    love.graphics.rectangle("fill",0,0,1920,80)
    love.graphics.setColor(1,1,1)
    love.graphics.setFont(Fonts.title)
    love.graphics.printf("Asignación de Tutor",0,24,1920,"center")

    love.graphics.setColor(Colors.text)
    love.graphics.setFont(Fonts.body)
    love.graphics.print("Selecciona un tutor compatible:",80,110)
    love.graphics.setColor(Colors.textSub)
    love.graphics.setFont(Fonts.small)
    love.graphics.print("Solo tutores que cumplen las 4 condiciones de elegibilidad.",80,136)

    for i,t in ipairs(tutores) do
        local ry=200+(i-1)*110
        local offY,alpha=Anim.staggerValue(stag,i)
        ry=ry+offY
        local sel=selec==i
        local ac=t.tutorados_activos<3 and Colors.green or Colors.orange
        love.graphics.setColor(sel and Colors.accentSoft or (hover[i] and {0.96,0.96,1} or Colors.card))
        love.graphics.setColor(
            (sel and Colors.accentSoft or (hover[i] and {0.96,0.96,1} or Colors.card))[1],
            (sel and Colors.accentSoft or (hover[i] and {0.96,0.96,1} or Colors.card))[2] or 1,
            (sel and Colors.accentSoft or (hover[i] and {0.96,0.96,1} or Colors.card))[3] or 1,
            alpha)
        love.graphics.rectangle("fill",80,ry,1760,92,14)
        if sel then
            love.graphics.setColor(Colors.accent[1],Colors.accent[2],Colors.accent[3],alpha)
            love.graphics.rectangle("line",80,ry,1760,92,14)
        end
        love.graphics.setColor(ac[1],ac[2],ac[3],0.2*alpha)
        love.graphics.circle("fill",130,ry+46,28)
        love.graphics.setColor(ac[1],ac[2],ac[3],alpha)
        love.graphics.setFont(Fonts.title)
        love.graphics.print(string.upper(string.sub(t.nombre,1,1)),118,ry+28)
        love.graphics.setColor(Colors.text[1],Colors.text[2],Colors.text[3],alpha)
        love.graphics.setFont(Fonts.body)
        love.graphics.print(t.nombre,172,ry+16)
        love.graphics.setColor(Colors.textSub[1],Colors.textSub[2],Colors.textSub[3],alpha)
        love.graphics.setFont(Fonts.small)
        love.graphics.print("Áreas: "..table.concat(t.areas_competencia,", "),172,ry+42)
        love.graphics.print("Disponibilidad: "..table.concat(t.disponibilidad,", "),172,ry+62)
        love.graphics.setColor(ac[1],ac[2],ac[3],alpha)
        love.graphics.setFont(Fonts.small)
        love.graphics.print(t.tutorados_activos.." / "..t.limite.." tutorados",1600,ry+36)
        love.graphics.setColor(t.incidentes_recientes==0 and Colors.green or Colors.red)
        love.graphics.print(t.incidentes_recientes==0 and "Sin incidentes" or t.incidentes_recientes.." incidente(s)",1600,ry+56)
    end

    -- Botones
    love.graphics.setColor(Colors.border)
    love.graphics.rectangle("fill",80,1000,150,50,12)
    love.graphics.setColor(Colors.text)
    love.graphics.setFont(Fonts.body)
    love.graphics.printf("Volver",80,1016,150,"center")
    local bc=selec and Colors.accent or {0.8,0.7,0.95}
    love.graphics.setColor(bc)
    love.graphics.rectangle("fill",1690,1000,150,50,12)
    love.graphics.setColor(1,1,1)
    love.graphics.printf("Asignar",1690,1016,150,"center")
    if asig then
        love.graphics.setColor(Colors.greenSoft)
        love.graphics.rectangle("fill",660,990,600,54,14)
        love.graphics.setColor(Colors.green)
        love.graphics.setFont(Fonts.body)
        love.graphics.printf("✓ Tutor asignado. Notificación enviada.",660,1010,600,"center")
    end
end

function AsignacionScreen.mousepressed(x,y,btn)
    for i,t in ipairs(tutores) do
        local ry=200+(i-1)*110
        if x>=80 and x<=1840 and y>=ry and y<=ry+92 then selec=i return end
    end
    if x>=80 and x<=230 and y>=1000 and y<=1050 then Nav.to("dashboard",{rol=params.rol},-1) end
    if x>=1690 and x<=1840 and y>=1000 and y<=1050 and selec then
        EventBus.publish(EventTypes.TUTOR_ASIGNADO,{tutor=tutores[selec]})
        asig=true
    end
end

return AsignacionScreen
