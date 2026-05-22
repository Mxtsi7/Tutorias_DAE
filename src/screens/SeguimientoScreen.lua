local Anim    = require("src.anim.Anim")
local tutorias= require("src.data.tutorias")
local tutores = require("src.data.tutores")
local estud   = require("src.data.estudiantes")

local Seg={}
local hover={} local stag={} local params={}

local function W() return love.graphics.getWidth() end
local function H() return love.graphics.getHeight() end

function Seg.load(p)
    params=p or {} hover={}
    stag=Anim.staggerList(#tutorias,0.06,0.4)
end

function Seg.update(dt)
    Anim.staggerUpdate(stag,dt)
    local mx,my=love.mouse.getPosition()
    for i,t in ipairs(tutorias) do
        local ry=240+(i-1)*94
        hover[i]=mx>=30 and mx<=W()-30 and my>=ry and my<=ry+82
    end
end

local function eColor(e)
    if e=="activa" then return Colors.green
    elseif e=="activa_con_alerta" then return Colors.orange
    elseif e=="suspendida" then return Colors.red
    else return Colors.textSub end
end

function Seg.draw()
    local WW,HH=W(),H()
    love.graphics.setColor(Colors.bg)
    love.graphics.rectangle("fill",0,0,WW,HH)

    -- Header
    love.graphics.setColor(Colors.accent)
    love.graphics.rectangle("fill",0,0,WW,68)
    love.graphics.setColor(1,1,1)
    love.graphics.setFont(Fonts.title)
    love.graphics.printf("Seguimiento Semanal \xe2\x80\x94 Coordinador",0,22,WW,"center")

    -- KPIs
    local kpis={
        {label="Tutor\xc3\xadas Activas",value=#tutorias,color=Colors.green},
        {label="Con Alertas",      value=1,            color=Colors.orange},
        {label="En Espera",        value=0,            color=Colors.textSub},
    }
    local kw=math.floor((WW-60)/3)
    for i,k in ipairs(kpis) do
        local kx=30+(i-1)*(kw+10)
        love.graphics.setColor(Colors.card)
        love.graphics.rectangle("fill",kx,78,kw,78,12)
        love.graphics.setColor(k.color)
        love.graphics.rectangle("fill",kx,78,6,78,{4,0,0,4})
        love.graphics.setColor(Colors.text)
        love.graphics.setFont(Fonts.big)
        love.graphics.print(tostring(k.value),kx+22,84)
        love.graphics.setColor(Colors.textSub)
        love.graphics.setFont(Fonts.small)
        love.graphics.print(k.label,kx+22,130)
    end

    -- Encabezados de tabla (proporcionales al ancho)
    local cw=math.floor((WW-60)/8)
    local cols={}
    for i=1,8 do cols[i]=30+(i-1)*cw end
    local headers={"Estudiante","\xc3\x81rea","Tutor","Sesiones","Avance","Estado","Ausencias","Acci\xc3\xb3n"}
    love.graphics.setColor(Colors.textSub)
    love.graphics.setFont(Fonts.small)
    for i,h in ipairs(headers) do
        love.graphics.print(h,cols[i],222)
    end
    love.graphics.setColor(Colors.border)
    love.graphics.rectangle("fill",30,236,WW-60,1)

    -- Filas
    for i,t in ipairs(tutorias) do
        local ry=240+(i-1)*94
        local offY,alpha=Anim.staggerValue(stag,i)
        ry=ry+offY
        -- fondo fila
        if hover[i] then
            love.graphics.setColor(0.95,0.95,1,alpha)
        elseif i%2==0 then
            love.graphics.setColor(Colors.bg[1],Colors.bg[2],Colors.bg[3],alpha)
        else
            love.graphics.setColor(Colors.card[1],Colors.card[2],Colors.card[3],alpha)
        end
        love.graphics.rectangle("fill",30,ry,WW-60,82,8)

        local e=estud[t.estudiante_id] or {nombre="\xe2\x80\x94",area_necesidad="\xe2\x80\x94"}
        local tu=tutores[t.tutor_id]   or {nombre="\xe2\x80\x94"}

        love.graphics.setColor(Colors.text[1],Colors.text[2],Colors.text[3],alpha)
        love.graphics.setFont(Fonts.body)
        love.graphics.print(e.nombre,     cols[1],ry+14)
        love.graphics.setFont(Fonts.small)
        love.graphics.setColor(Colors.textSub[1],Colors.textSub[2],Colors.textSub[3],alpha)
        love.graphics.print(e.area_necesidad or "\xe2\x80\x94",cols[1],ry+36)

        love.graphics.setColor(Colors.text[1],Colors.text[2],Colors.text[3],alpha)
        love.graphics.setFont(Fonts.body)
        love.graphics.print(t.area or "\xe2\x80\x94",cols[2],ry+26)
        love.graphics.print(tu.nombre,   cols[3],ry+26)
        love.graphics.print(t.sesiones_realizadas.." / 8",cols[4],ry+26)

        -- avance con color
        local ac=t.nivel_avance_actual=="alto" and Colors.green
                or t.nivel_avance_actual=="medio" and Colors.orange or Colors.red
        love.graphics.setColor(ac[1],ac[2],ac[3],alpha)
        love.graphics.print(t.nivel_avance_actual or "bajo",cols[5],ry+26)

        -- badge estado (ancho automático)
        local sc=eColor(t.estado)
        local elabel=t.estado or "activa"
        local etw=Fonts.small:getWidth(elabel)
        love.graphics.setColor(sc[1],sc[2],sc[3],0.15*alpha)
        love.graphics.rectangle("fill",cols[6],ry+18,etw+18,26,6)
        love.graphics.setColor(sc[1],sc[2],sc[3],alpha)
        love.graphics.setFont(Fonts.small)
        love.graphics.print(elabel,cols[6]+9,ry+24)

        -- ausencias
        love.graphics.setColor(t.ausencias_consecutivas>0 and Colors.red or Colors.textSub)
        love.graphics.setFont(Fonts.body)
        love.graphics.printf(tostring(t.ausencias_consecutivas),cols[7],ry+26,cw-4,"center")

        -- boton detalle
        local atw=Fonts.small:getWidth("Detalle")
        love.graphics.setColor(Colors.accentSoft[1],Colors.accentSoft[2],Colors.accentSoft[3],alpha)
        love.graphics.rectangle("fill",cols[8],ry+18,atw+18,26,6)
        love.graphics.setColor(Colors.accent[1],Colors.accent[2],Colors.accent[3],alpha)
        love.graphics.setFont(Fonts.small)
        love.graphics.print("Detalle",cols[8]+9,ry+24)
    end

    -- Botón Volver
    love.graphics.setColor(Colors.accent)
    love.graphics.rectangle("fill",30,HH-64,130,44,10)
    love.graphics.setColor(1,1,1)
    love.graphics.setFont(Fonts.body)
    love.graphics.printf("Volver",30,HH-50,130,"center")
end

function Seg.mousepressed(x,y,btn)
    local HH=H()
    if x>=30 and x<=160 and y>=HH-64 and y<=HH-20 then
        Nav.to("dashboard",{rol=params.rol},-1)
    end
end

return Seg
