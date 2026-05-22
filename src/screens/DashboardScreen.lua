local SM   = require("src.screens.ScreenManager")
local Anim = require("src.anim.Anim")
local UI   = require("src.components.UI")
local data = require("src.data.tutorias")

local DS = {}
local SW = 260
local nav = {
    { label="Dashboard",    screen="dashboard",   active=true  },
    { label="Mis Sesiones", screen="sesion",      active=false },
    { label="Solicitudes",  screen="solicitud",   active=false },
    { label="Seguimiento",  screen="seguimiento", active=false },
    { label="Asignaci\xc3\xb3n",   screen="asignacion",  active=false },
}
local hovNav={} local hovCards={} local hovBtn=false
local stag={} local bannerA=nil local pulse=0 local params={}

local CARD_W=300 local CARD_H=220 local CARD_GAP=20

local function W() return love.graphics.getWidth() end
local function H() return love.graphics.getHeight() end
local function MX() return SW+30 end

local function nombre()
    if params.rol=="tutor" then return "Roberto Carlos"
    elseif params.rol=="coordinador" then return "Coordinador"
    else return "Valentina" end
end

local function avColor(n)
    if n=="alto" then return Colors.green
    elseif n=="medio" then return Colors.orange
    else return Colors.red end
end

function DS.load(p)
    params=p or {rol="estudiante"}
    hovNav={} hovCards={} pulse=0
    stag=Anim.staggerList(#data,0.07,0.5)
    bannerA=Anim.new(0,1,0.5,"easeOut")
end

function DS.update(dt)
    bannerA:update(dt)
    Anim.staggerUpdate(stag,dt)
    pulse=pulse+dt*2.5
    local mx,my=love.mouse.getPosition()
    local WW,HH=W(),H()
    for i,n in ipairs(nav) do
        local ny=220+(i-1)*58
        hovNav[i]=mx>=0 and mx<=SW and my>=ny and my<=ny+46
    end
    for i,t in ipairs(data) do
        local col=(i-1)%3
        local row=math.floor((i-1)/3)
        local cx=MX()+col*(CARD_W+CARD_GAP)
        local cy=430+row*(CARD_H+CARD_GAP)
        hovCards[i]=mx>=cx and mx<=cx+CARD_W and my>=cy and my<=cy+CARD_H
    end
    hovBtn=mx>=16 and mx<=SW-16 and my>=HH-68 and my<=HH-16
end

function DS.draw()
    local WW,HH=W(),H()
    local ba=bannerA:value()
    local mx2=MX()

    -- Fondo
    love.graphics.setColor(Colors.bg)
    love.graphics.rectangle("fill",0,0,WW,HH)

    -- SIDEBAR
    love.graphics.setColor(Colors.sidebar)
    love.graphics.rectangle("fill",0,0,SW,HH)
    love.graphics.setColor(Colors.border)
    love.graphics.rectangle("fill",SW,0,1,HH)

    -- Logo
    love.graphics.setColor(Colors.accent)
    love.graphics.circle("fill",34,38,15)
    love.graphics.setColor(1,1,1)
    love.graphics.setFont(Fonts.small)
    love.graphics.printf("T",20,31,28,"center")
    love.graphics.setColor(Colors.text)
    love.graphics.setFont(Fonts.title)
    love.graphics.print("TutorMate",56,27)

    -- Avatar
    love.graphics.setColor(Colors.accentSoft)
    love.graphics.circle("fill",36,118,26)
    love.graphics.setColor(Colors.accent)
    love.graphics.setFont(Fonts.title)
    love.graphics.printf(string.upper(string.sub(nombre(),1,1)),10,108,52,"center")
    love.graphics.setColor(Colors.text)
    love.graphics.setFont(Fonts.body)
    love.graphics.print(nombre(),72,110)
    love.graphics.setColor(Colors.textSub)
    love.graphics.setFont(Fonts.small)
    love.graphics.print(string.upper(params.rol or "estudiante"),72,128)

    -- Nav items
    for i,n in ipairs(nav) do
        local ny=220+(i-1)*58
        if n.active then
            love.graphics.setColor(Colors.accentSoft)
            love.graphics.rectangle("fill",10,ny,SW-20,44,10)
        elseif hovNav[i] then
            love.graphics.setColor(Colors.bg)
            love.graphics.rectangle("fill",10,ny,SW-20,44,10)
        end
        love.graphics.setColor(n.active and Colors.accent or Colors.text)
        love.graphics.setFont(Fonts.body)
        love.graphics.print(n.label,44,ny+13)
    end

    -- Botón Nueva Solicitud
    local p2=(math.sin(pulse)+1)/2
    love.graphics.setColor(Colors.accent[1],Colors.accent[2],Colors.accent[3],p2*0.15)
    love.graphics.rectangle("fill",8,HH-76,SW-16,60,14)
    love.graphics.setColor(Colors.accent)
    love.graphics.rectangle("fill",16,HH-68,SW-32,46,12)
    love.graphics.setColor(1,1,1)
    love.graphics.setFont(Fonts.body)
    love.graphics.printf("+ Nueva Solicitud",16,HH-57,SW-32,"center")

    -- ÁREA PRINCIPAL
    -- Saludo
    love.graphics.setColor(Colors.text[1],Colors.text[2],Colors.text[3],ba)
    love.graphics.setFont(Fonts.big)
    love.graphics.print("Bienvenido, "..nombre().."!",mx2,28)
    love.graphics.setFont(Fonts.body)
    love.graphics.setColor(Colors.textSub[1],Colors.textSub[2],Colors.textSub[3],ba)
    love.graphics.print("Tienes "..#data.." tutor\xc3\xadas activas.",mx2,62)

    -- Banner próxima sesión
    local banW=WW-mx2-30
    love.graphics.setColor(Colors.greenSoft[1],Colors.greenSoft[2],Colors.greenSoft[3],ba)
    love.graphics.rectangle("fill",mx2,84,banW,110,14)
    -- dot pulsante
    local dp=(math.sin(pulse*1.5)+1)/2
    love.graphics.setColor(Colors.green[1],Colors.green[2],Colors.green[3],0.4+dp*0.5)
    love.graphics.circle("fill",mx2+20,84+55,7)
    -- badge
    love.graphics.setColor(Colors.green)
    love.graphics.rectangle("fill",mx2+36,100,120,24,8)
    love.graphics.setColor(1,1,1)
    love.graphics.setFont(Fonts.small)
    love.graphics.printf("Pr\xc3\xb3x. Sesi\xc3\xb3n",mx2+36,105,120,"center")
    -- texto
    love.graphics.setColor(Colors.text[1],Colors.text[2],Colors.text[3],ba)
    love.graphics.setFont(Fonts.title)
    love.graphics.print("Estad\xc3\xadstica Aplicada \xe2\x80\x94 Probabilidad",mx2+36,132)
    love.graphics.setFont(Fonts.small)
    love.graphics.setColor(Colors.textSub[1],Colors.textSub[2],Colors.textSub[3],ba)
    love.graphics.print("Hoy, 16:00 hs  \xc2\xb7  45 min",mx2+36,158)
    -- botón unirse
    love.graphics.setColor(Colors.card[1],Colors.card[2],Colors.card[3],ba)
    love.graphics.rectangle("fill",mx2+banW-130,104,110,46,10)
    love.graphics.setColor(Colors.green[1],Colors.green[2],Colors.green[3],ba)
    love.graphics.setFont(Fonts.body)
    love.graphics.printf("Unirse >",mx2+banW-130,120,110,"center")

    -- Subtítulo
    love.graphics.setColor(Colors.text[1],Colors.text[2],Colors.text[3],ba)
    love.graphics.setFont(Fonts.title)
    love.graphics.print("Tus Tutor\xc3\xadas Activas",mx2,212)

    -- TARJETAS
    for i,t in ipairs(data) do
        local col=(i-1)%3
        local row=math.floor((i-1)/3)
        local cx=mx2+col*(CARD_W+CARD_GAP)
        local cy=240+row*(CARD_H+CARD_GAP)
        local offY,alpha=Anim.staggerValue(stag,i)
        cy=cy+offY
        local ac=avColor(t.nivel_avance_actual)
        local isHov=hovCards[i]

        -- sombra
        love.graphics.setColor(0,0,0,isHov and 0.08*alpha or 0.04*alpha)
        love.graphics.rectangle("fill",cx+3,cy+4,CARD_W,CARD_H,14)
        -- card
        love.graphics.setColor(isHov and 0.97 or 1, isHov and 0.96 or 1, isHov and 1 or 1, alpha)
        love.graphics.rectangle("fill",cx,cy,CARD_W,CARD_H,14)
        -- tira superior de color
        love.graphics.setColor(ac[1],ac[2],ac[3],alpha)
        love.graphics.rectangle("fill",cx,cy,CARD_W,4,{0,0,14,14})

        -- ícono de área (sin emoji)
        love.graphics.push()
        love.graphics.translate(cx+14,cy+14)
        UI.areaIcon(0,0,ac)
        love.graphics.pop()

        -- nombre área (con alpha)
        love.graphics.setColor(Colors.text[1],Colors.text[2],Colors.text[3],alpha)
        love.graphics.setFont(Fonts.body)
        love.graphics.print(t.area or "\xc3\x81rea",cx+60,cy+16)
        love.graphics.setColor(Colors.textSub[1],Colors.textSub[2],Colors.textSub[3],alpha)
        love.graphics.setFont(Fonts.small)
        love.graphics.print("Tutor: "..t.tutor_id,cx+60,cy+36)

        -- separador
        love.graphics.setColor(Colors.border[1],Colors.border[2],Colors.border[3],alpha)
        love.graphics.rectangle("fill",cx+14,cy+62,CARD_W-28,1)

        -- nivel de avance
        love.graphics.setColor(Colors.textSub[1],Colors.textSub[2],Colors.textSub[3],alpha)
        love.graphics.setFont(Fonts.small)
        love.graphics.print("NIVEL DE AVANCE",cx+14,cy+72)
        love.graphics.setColor(ac[1],ac[2],ac[3],alpha)
        love.graphics.setFont(Fonts.body)
        love.graphics.print(string.upper(t.nivel_avance_actual or "bajo"),cx+14,cy+90)
        love.graphics.setColor(Colors.textSub[1],Colors.textSub[2],Colors.textSub[3],alpha)
        love.graphics.setFont(Fonts.small)
        love.graphics.print(t.sesiones_realizadas.." / 8 Sesiones",cx+140,cy+92)

        -- barra de progreso
        love.graphics.push()
        love.graphics.translate(cx+14,cy+118)
        UI.progressBar3(0,0,CARD_W-28,8,t.nivel_avance_actual)
        love.graphics.pop()

        -- badge estado (ancho auto, nunca se corta)
        love.graphics.push()
        love.graphics.translate(cx+14,cy+138)
        local estadoLabel = t.estado or "activa"
        local estadoColor = t.estado=="activa" and Colors.green
                         or t.estado=="activa_con_alerta" and Colors.orange
                         or Colors.textSub
        love.graphics.setColor(estadoColor[1],estadoColor[2],estadoColor[3],0.15*alpha)
        local tw=Fonts.small:getWidth(estadoLabel)
        local bw=tw+20
        love.graphics.rectangle("fill",0,0,bw,22,11)
        love.graphics.setColor(estadoColor[1],estadoColor[2],estadoColor[3],alpha)
        love.graphics.setFont(Fonts.small)
        love.graphics.print(estadoLabel,10,4)
        love.graphics.pop()

        -- ausencias
        if t.ausencias_consecutivas and t.ausencias_consecutivas>0 then
            love.graphics.setColor(Colors.red[1],Colors.red[2],Colors.red[3],alpha)
            love.graphics.setFont(Fonts.small)
            -- no usamos emoji, usamos "!" como prefijo
            local bw2=Fonts.small:getWidth(estadoLabel)+20
            love.graphics.print("! "..t.ausencias_consecutivas.." ausencia(s)",cx+14+bw2+10,cy+140)
        end
    end
end

function DS.mousepressed(x,y,btn)
    local HH=H()
    for i,n in ipairs(nav) do
        local ny=220+(i-1)*58
        if x>=0 and x<=SW and y>=ny and y<=ny+46 then
            for j,_ in ipairs(nav) do nav[j].active=false end
            nav[i].active=true
            Nav.to(n.screen,{rol=params.rol},1)
            return
        end
    end
    if x>=16 and x<=SW-16 and y>=HH-68 and y<=HH-16 then
        Nav.to("solicitud",{rol=params.rol},1)
    end
end

return DS
