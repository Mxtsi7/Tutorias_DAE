local Anim        = require("src.anim.Anim")
local TutoriaRepo = require("src.db.TutoriaRepo")

local Seg={}
local hover={} local stag={} local params={}
local tutorias={}

local function W() return love.graphics.getWidth() end
local function H() return love.graphics.getHeight() end

function Seg.load(p)
    params=p or {} hover={}
    tutorias=TutoriaRepo.getAll()
    stag=Anim.staggerList(#tutorias,0.06,0.4)
end

function Seg.update(dt)
    Anim.staggerUpdate(stag,dt)
    local mx,my=love.mouse.getPosition()
    for i in ipairs(tutorias) do
        local ry=240+(i-1)*94
        hover[i]=mx>=30 and mx<=W()-30 and my>=ry and my<=ry+82
    end
end

local function eColor(e)
    if e=="activa" then return Colors.green
    elseif e=="activa_con_alerta" then return Colors.orange
    else return Colors.red end
end

function Seg.draw()
    local WW,HH=W(),H()
    love.graphics.setColor(Colors.bg)
    love.graphics.rectangle("fill",0,0,WW,HH)

    love.graphics.setColor(Colors.accent)
    love.graphics.rectangle("fill",0,0,WW,68)
    love.graphics.setColor(1,1,1)
    love.graphics.setFont(Fonts.title)
    love.graphics.printf("Seguimiento Semanal \xe2\x80\x94 Coordinador",0,22,WW,"center")

    -- contar alertas
    local nActivas,nAlertas=0,0
    for _,t in ipairs(tutorias) do
        if t.estado=="activa" or t.estado=="activa_con_alerta" then nActivas=nActivas+1 end
        if t.estado=="activa_con_alerta" or t.estado=="suspendida" then nAlertas=nAlertas+1 end
    end
    local kpis={
        {label="Tutor\xc3\xadas Activas",value=nActivas, color=Colors.green},
        {label="Con Alertas",           value=nAlertas, color=Colors.orange},
        {label="En Espera",             value=0,        color=Colors.textSub},
    }
    local kw=math.floor((WW-60)/3)
    for i,k in ipairs(kpis) do
        local kx=30+(i-1)*(kw+10)
        love.graphics.setColor(Colors.card)
        love.graphics.rectangle("fill",kx,78,kw,78,12)
        love.graphics.setColor(k.color)
        love.graphics.rectangle("fill",kx,78,6,78,4)
        love.graphics.setColor(Colors.text)
        love.graphics.setFont(Fonts.big)
        love.graphics.print(tostring(k.value),kx+22,84)
        love.graphics.setColor(Colors.textSub)
        love.graphics.setFont(Fonts.small)
        love.graphics.print(k.label,kx+22,130)
    end

    local margin=30 local TW=WW-margin*2 local colW=math.floor(TW/8)
    local headers={"Estudiante","\xc3\x81rea","Tutor","Sesiones","Avance","Estado","Ausencias","Acci\xc3\xb3n"}
    love.graphics.setColor(Colors.textSub)
    love.graphics.setFont(Fonts.small)
    for i,h in ipairs(headers) do
        love.graphics.print(h,margin+(i-1)*colW,222)
    end
    love.graphics.setColor(Colors.border)
    love.graphics.rectangle("fill",margin,236,TW,1)

    for i,t in ipairs(tutorias) do
        local ry=240+(i-1)*94
        local offY,alpha=Anim.staggerValue(stag,i)
        ry=ry+offY
        if hover[i] then love.graphics.setColor(0.95,0.95,1,alpha)
        elseif i%2==0 then love.graphics.setColor(Colors.bg[1],Colors.bg[2],Colors.bg[3],alpha)
        else love.graphics.setColor(Colors.card[1],Colors.card[2],Colors.card[3],alpha) end
        love.graphics.rectangle("fill",margin,ry,TW,82,8)

        local c1=margin local c2=margin+colW local c3=margin+colW*2
        local c4=margin+colW*3 local c5=margin+colW*4
        local c6=margin+colW*5 local c7=margin+colW*6 local c8=margin+colW*7

        love.graphics.setColor(Colors.text[1],Colors.text[2],Colors.text[3],alpha)
        love.graphics.setFont(Fonts.body)
        love.graphics.print(t.estudiante_nombre or "\xe2\x80\x94",c1+8,ry+14)
        love.graphics.setColor(Colors.textSub[1],Colors.textSub[2],Colors.textSub[3],alpha)
        love.graphics.setFont(Fonts.small)
        love.graphics.print(t.area_necesidad or "\xe2\x80\x94",c1+8,ry+38)

        love.graphics.setColor(Colors.text[1],Colors.text[2],Colors.text[3],alpha)
        love.graphics.setFont(Fonts.body)
        love.graphics.print(t.area or "\xe2\x80\x94",c2+4,ry+26)
        love.graphics.print(t.tutor_nombre or "\xe2\x80\x94",c3+4,ry+26)
        love.graphics.print(t.sesiones_realizadas.." / 8",c4+4,ry+26)

        local ac=t.nivel_avance_actual=="alto" and Colors.green
                or t.nivel_avance_actual=="medio" and Colors.orange or Colors.red
        love.graphics.setColor(ac[1],ac[2],ac[3],alpha)
        love.graphics.print(t.nivel_avance_actual or "bajo",c5+4,ry+26)

        local sc=eColor(t.estado)
        local el=t.estado or "activa"
        local etw=Fonts.small:getWidth(el)+18
        love.graphics.setColor(sc[1],sc[2],sc[3],0.15*alpha)
        love.graphics.rectangle("fill",c6+4,ry+18,etw,26,6)
        love.graphics.setColor(sc[1],sc[2],sc[3],alpha)
        love.graphics.setFont(Fonts.small)
        love.graphics.print(el,c6+13,ry+24)

        love.graphics.setColor((t.ausencias_consecutivas or 0)>0 and Colors.red or Colors.textSub)
        love.graphics.setFont(Fonts.body)
        love.graphics.printf(tostring(t.ausencias_consecutivas or 0),c7,ry+26,colW-4,"center")

        local dtw=Fonts.small:getWidth("Detalle")+18
        love.graphics.setColor(Colors.accentSoft[1],Colors.accentSoft[2],Colors.accentSoft[3],alpha)
        love.graphics.rectangle("fill",c8+4,ry+18,dtw,26,6)
        love.graphics.setColor(Colors.accent[1],Colors.accent[2],Colors.accent[3],alpha)
        love.graphics.setFont(Fonts.small)
        love.graphics.print("Detalle",c8+13,ry+24)
    end

    love.graphics.setColor(Colors.accent)
    love.graphics.rectangle("fill",margin,HH-64,130,44,10)
    love.graphics.setColor(1,1,1)
    love.graphics.setFont(Fonts.body)
    love.graphics.printf("Volver",margin,HH-50,130,"center")
end

function Seg.mousepressed(x,y,btn)
    if x>=30 and x<=160 and y>=H()-64 and y<=H()-20 then
        Nav.to("dashboard",{rol=params.rol,usuario_id=params.usuario_id,nombre=params.nombre},-1)
    end
end

return Seg
