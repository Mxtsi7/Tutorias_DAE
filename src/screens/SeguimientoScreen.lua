local Anim     = require("src.anim.Anim")
local tutorias = require("src.data.tutorias")
local tutores  = require("src.data.tutores")
local estud    = require("src.data.estudiantes")

local SeguimientoScreen = {}
local hover={} local stag={} local params={}

function SeguimientoScreen.load(p)
    params=p or {} hover={}
    stag=Anim.staggerList(#tutorias,0.06,0.4)
end

function SeguimientoScreen.update(dt)
    Anim.staggerUpdate(stag,dt)
    local mx,my=love.mouse.getPosition()
    for i,t in ipairs(tutorias) do
        local ry=280+(i-1)*100
        hover[i]=mx>=40 and mx<=1880 and my>=ry and my<=ry+88
    end
end

local function eColor(e)
    if e=="activa" then return Colors.green
    elseif e=="activa_con_alerta" then return Colors.orange
    elseif e=="suspendida" then return Colors.red
    else return Colors.textSub end
end

function SeguimientoScreen.draw()
    love.graphics.setColor(Colors.bg)
    love.graphics.rectangle("fill",0,0,1920,1080)
    love.graphics.setColor(Colors.accent)
    love.graphics.rectangle("fill",0,0,1920,80)
    love.graphics.setColor(1,1,1)
    love.graphics.setFont(Fonts.title)
    love.graphics.printf("Seguimiento Semanal — Coordinador",0,24,1920,"center")

    -- KPIs
    local kpis={
        {label="Tutorías Activas",value=#tutorias,color=Colors.green},
        {label="Con Alertas",     value=1,         color=Colors.orange},
        {label="En Espera",       value=0,         color=Colors.textSub},
    }
    for i,k in ipairs(kpis) do
        local kx=40+(i-1)*460
        love.graphics.setColor(Colors.card)
        love.graphics.rectangle("fill",kx,90,420,90,14)
        love.graphics.setColor(k.color)
        love.graphics.rectangle("fill",kx,90,8,90,{4,0,0,4})
        love.graphics.setColor(Colors.text)
        love.graphics.setFont(Fonts.big)
        love.graphics.print(tostring(k.value),kx+28,96)
        love.graphics.setColor(Colors.textSub)
        love.graphics.setFont(Fonts.small)
        love.graphics.print(k.label,kx+28,144)
    end

    -- headers tabla
    local cols={40,300,620,940,1150,1360,1580,1760}
    local headers={"Estudiante","Área","Tutor","Sesiones","Avance","Estado","Ausencias","Acción"}
    love.graphics.setColor(Colors.text)
    love.graphics.setFont(Fonts.small)
    for i,h in ipairs(headers) do
        love.graphics.print(h,cols[i],256)
    end
    love.graphics.setColor(Colors.border)
    love.graphics.rectangle("fill",40,272,1840,1)

    for i,t in ipairs(tutorias) do
        local ry=280+(i-1)*100
        local offY,alpha=Anim.staggerValue(stag,i)
        ry=ry+offY
        love.graphics.setColor(hover[i] and {0.95,0.95,1} or (i%2==0 and Colors.bg or Colors.card))
        love.graphics.setColor(
            (hover[i] and {0.95,0.95,1} or (i%2==0 and Colors.bg or Colors.card))[1],
            (hover[i] and {0.95,0.95,1} or (i%2==0 and Colors.bg or Colors.card))[2] or 1,
            (hover[i] and {0.95,0.95,1} or (i%2==0 and Colors.bg or Colors.card))[3] or 1,
            alpha)
        love.graphics.rectangle("fill",40,ry,1840,88,10)
        local e=estud[t.estudiante_id] or {nombre="—"}
        local tu=tutores[t.tutor_id]  or {nombre="—"}
        love.graphics.setColor(Colors.text[1],Colors.text[2],Colors.text[3],alpha)
        love.graphics.setFont(Fonts.body)
        love.graphics.print(e.nombre,cols[1],ry+22)
        love.graphics.print(t.area or "—",cols[2],ry+22)
        love.graphics.print(tu.nombre,cols[3],ry+22)
        love.graphics.print(t.sesiones_realizadas.." / 8",cols[4],ry+22)
        local ac=t.nivel_avance_actual=="alto" and Colors.green
                or t.nivel_avance_actual=="medio" and Colors.orange or Colors.red
        love.graphics.setColor(ac[1],ac[2],ac[3],alpha)
        love.graphics.print(t.nivel_avance_actual or "bajo",cols[5],ry+22)
        local sc=eColor(t.estado)
        love.graphics.setColor(sc[1],sc[2],sc[3],0.15*alpha)
        love.graphics.rectangle("fill",cols[6],ry+18,120,32,8)
        love.graphics.setColor(sc[1],sc[2],sc[3],alpha)
        love.graphics.setFont(Fonts.small)
        love.graphics.printf(t.estado or "activa",cols[6],ry+26,120,"center")
        love.graphics.setColor(t.ausencias_consecutivas>0 and Colors.red or Colors.textSub)
        love.graphics.setFont(Fonts.body)
        love.graphics.print(tostring(t.ausencias_consecutivas),cols[7]+50,ry+22)
        love.graphics.setColor(Colors.accentSoft[1],Colors.accentSoft[2],Colors.accentSoft[3],alpha)
        love.graphics.rectangle("fill",cols[8],ry+18,110,32,8)
        love.graphics.setColor(Colors.accent[1],Colors.accent[2],Colors.accent[3],alpha)
        love.graphics.setFont(Fonts.small)
        love.graphics.printf("Detalle",cols[8],ry+26,110,"center")
    end

    love.graphics.setColor(Colors.accent)
    love.graphics.rectangle("fill",40,1016,160,46,12)
    love.graphics.setColor(1,1,1)
    love.graphics.setFont(Fonts.body)
    love.graphics.printf("Volver",40,1030,160,"center")
end

function SeguimientoScreen.mousepressed(x,y,btn)
    if x>=40 and x<=200 and y>=1016 and y<=1062 then
        Nav.to("dashboard",{rol=params.rol},-1)
    end
end

return SeguimientoScreen
