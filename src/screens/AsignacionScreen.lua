local Anim       = require("src.anim.Anim")
local EventBus   = require("src.events.EventBus")
local EventTypes = require("src.events.EventTypes")
local tutores    = require("src.data.tutores")

local AS = {}
local selec=nil local hover={} local stag={}
local asig=false local params={}

local function W() return love.graphics.getWidth() end
local function H() return love.graphics.getHeight() end
local MARGIN=60
local ROW_H=92

function AS.load(p)
    params=p or {} selec=nil asig=false hover={}
    stag=Anim.staggerList(#tutores,0.07,0.4)
end

function AS.update(dt)
    Anim.staggerUpdate(stag,dt)
    local mx,my=love.mouse.getPosition()
    local WW=W()
    for i in ipairs(tutores) do
        local ry=180+(i-1)*(ROW_H+18)
        hover[i]=mx>=MARGIN and mx<=WW-MARGIN and my>=ry and my<=ry+ROW_H
    end
end

function AS.draw()
    local WW,HH=W(),H()
    local RW=WW-MARGIN*2

    love.graphics.setColor(Colors.bg)
    love.graphics.rectangle("fill",0,0,WW,HH)

    -- Header
    love.graphics.setColor(Colors.accent)
    love.graphics.rectangle("fill",0,0,WW,72)
    love.graphics.setColor(1,1,1)
    love.graphics.setFont(Fonts.title)
    love.graphics.printf("Asignaci\xc3\xb3n de Tutor",0,22,WW,"center")

    love.graphics.setColor(Colors.text)
    love.graphics.setFont(Fonts.body)
    love.graphics.print("Selecciona un tutor compatible:",MARGIN,98)
    love.graphics.setColor(Colors.textSub)
    love.graphics.setFont(Fonts.small)
    love.graphics.print("Solo tutores que cumplen las 4 condiciones de elegibilidad.",MARGIN,122)

    -- Filas de tutores
    for i,t in ipairs(tutores) do
        local ry=180+(i-1)*(ROW_H+18)
        local offY,alpha=Anim.staggerValue(stag,i)
        ry=ry+offY
        local sel=selec==i
        local ac=t.tutorados_activos<3 and Colors.green or Colors.orange

        -- fondo fila
        if sel then
            love.graphics.setColor(Colors.accentSoft[1],Colors.accentSoft[2],Colors.accentSoft[3],alpha)
        elseif hover[i] then
            love.graphics.setColor(0.96,0.96,1,alpha)
        else
            love.graphics.setColor(Colors.card[1],Colors.card[2],Colors.card[3],alpha)
        end
        love.graphics.rectangle("fill",MARGIN,ry,RW,ROW_H,14)

        -- borde seleccionado: fill doble (sin rectangle line)
        if sel then
            love.graphics.setColor(Colors.accent[1],Colors.accent[2],Colors.accent[3],alpha)
            love.graphics.rectangle("fill",MARGIN,ry,RW,ROW_H,14)
            love.graphics.setColor(Colors.accentSoft[1],Colors.accentSoft[2],Colors.accentSoft[3],alpha)
            love.graphics.rectangle("fill",MARGIN+2,ry+2,RW-4,ROW_H-4,12)
        end

        -- avatar
        local iconCX=MARGIN+44
        local iconCY=ry+ROW_H/2
        love.graphics.setColor(ac[1],ac[2],ac[3],0.2*alpha)
        love.graphics.circle("fill",iconCX,iconCY,28)
        love.graphics.setColor(ac[1],ac[2],ac[3],alpha)
        love.graphics.setFont(Fonts.body)
        love.graphics.printf(string.upper(string.sub(t.nombre,1,1)),iconCX-14,iconCY-10,28,"center")

        -- textos
        local tx=MARGIN+86
        love.graphics.setColor(Colors.text[1],Colors.text[2],Colors.text[3],alpha)
        love.graphics.setFont(Fonts.body)
        love.graphics.print(t.nombre,tx,ry+14)
        love.graphics.setColor(Colors.textSub[1],Colors.textSub[2],Colors.textSub[3],alpha)
        love.graphics.setFont(Fonts.small)
        love.graphics.print("\xc3\x81reas: "..table.concat(t.areas_competencia,", "),tx,ry+38)
        love.graphics.print("Disponibilidad: "..table.concat(t.disponibilidad,", "),tx,ry+58)

        -- carga y estado (columna derecha, proporcional)
        local rx2=MARGIN+RW-200
        love.graphics.setColor(ac[1],ac[2],ac[3],alpha)
        love.graphics.setFont(Fonts.small)
        love.graphics.print(t.tutorados_activos.." / "..t.limite.." tutorados",rx2,ry+28)
        local sinInc=t.incidentes_recientes==0
        love.graphics.setColor(sinInc and Colors.green or Colors.red)
        love.graphics.print(sinInc and "Sin incidentes" or t.incidentes_recientes.." incidente(s)",rx2,ry+52)
    end

    -- Botones (posición dinámica)
    local btnY=HH-72
    love.graphics.setColor(Colors.border)
    love.graphics.rectangle("fill",MARGIN,btnY,140,48,12)
    love.graphics.setColor(Colors.text)
    love.graphics.setFont(Fonts.body)
    love.graphics.printf("Volver",MARGIN,btnY+14,140,"center")

    local bc=selec and Colors.accent or {0.8,0.7,0.95}
    love.graphics.setColor(bc)
    love.graphics.rectangle("fill",WW-MARGIN-140,btnY,140,48,12)
    love.graphics.setColor(1,1,1)
    love.graphics.printf("Asignar",WW-MARGIN-140,btnY+14,140,"center")

    if asig then
        local mw=math.min(500,WW*0.38)
        local mx2=math.floor((WW-mw)/2)
        love.graphics.setColor(Colors.greenSoft)
        love.graphics.rectangle("fill",mx2,btnY-4,mw,52,14)
        love.graphics.setColor(Colors.green)
        love.graphics.setFont(Fonts.body)
        love.graphics.printf("Tutor asignado. Notificacion enviada.",mx2,btnY+12,mw,"center")
    end
end

function AS.mousepressed(x,y,btn)
    local WW,HH=W(),H()
    local RW=WW-MARGIN*2
    local btnY=HH-72
    for i in ipairs(tutores) do
        local ry=180+(i-1)*(ROW_H+18)
        if x>=MARGIN and x<=MARGIN+RW and y>=ry and y<=ry+ROW_H then selec=i return end
    end
    if x>=MARGIN and x<=MARGIN+140 and y>=btnY and y<=btnY+48 then
        Nav.to("dashboard",{rol=params.rol},-1) return
    end
    if x>=WW-MARGIN-140 and x<=WW-MARGIN and y>=btnY and y<=btnY+48 and selec then
        EventBus.publish(EventTypes.TUTOR_ASIGNADO,{tutor=tutores[selec]})
        asig=true
    end
end

return AS
