-- DashboardScreen 1920x1080 con animaciones stagger en tarjetas
local SM   = require("src.screens.ScreenManager")
local Anim = require("src.anim.Anim")
local data = require("src.data.tutorias")

local DashboardScreen = {}
local SW = 300   -- sidebar width
local nav = {
    { label = "Dashboard",    screen = "dashboard",   active = true  },
    { label = "Mis Sesiones", screen = "sesion",      active = false },
    { label = "Solicitudes",  screen = "solicitud",   active = false },
    { label = "Seguimiento",  screen = "seguimiento", active = false },
    { label = "Asignación",   screen = "asignacion",  active = false },
}
local hovNav   = {}
local hovCards = {}
local hovBtn   = false
local stag     = {}
local bannerA  = nil   -- alpha banner próxima sesión
local params   = {}
local pulse    = 0     -- para el dot animado del banner

local function mainX() return SW + 40 end
local CARD_W, CARD_H = 380, 240
local CARD_Y = 520

function DashboardScreen.load(p)
    params   = p or { rol = "estudiante" }
    hovNav   = {}
    hovCards = {}
    stag     = Anim.staggerList(#data, 0.07, 0.5)
    bannerA  = Anim.new(0, 1, 0.5, "easeOut")
    pulse    = 0
end

local function nombre()
    if params.rol=="tutor" then return "Roberto Carlos"
    elseif params.rol=="coordinador" then return "Coordinador"
    else return "Valentina" end
end

local function avColor(n)
    if n=="alto"  then return Colors.green
    elseif n=="medio" then return Colors.orange
    else return Colors.red end
end

function DashboardScreen.update(dt)
    bannerA:update(dt)
    Anim.staggerUpdate(stag, dt)
    pulse = pulse + dt * 2.5
    local mx,my = love.mouse.getPosition()
    for i,n in ipairs(nav) do
        local ny = 260+(i-1)*70
        hovNav[i] = mx>=0 and mx<=SW and my>=ny and my<=ny+54
    end
    for i,t in ipairs(data) do
        local col = (i-1)%3
        local row = math.floor((i-1)/3)
        local cx = mainX()+col*(CARD_W+30)
        local cy = CARD_Y+row*(CARD_H+24)
        hovCards[i] = mx>=cx and mx<=cx+CARD_W and my>=cy and my<=cy+CARD_H
    end
    hovBtn = mx>=18 and mx<=SW-18 and my>=1010 and my<=1060
end

function DashboardScreen.draw()
    -- Fondo
    love.graphics.setColor(Colors.bg)
    love.graphics.rectangle("fill",0,0,1920,1080)

    -- ── SIDEBAR ──
    love.graphics.setColor(Colors.sidebar)
    love.graphics.rectangle("fill",0,0,SW,1080)
    love.graphics.setColor(Colors.border)
    love.graphics.rectangle("fill",SW,0,1,1080)

    -- Logo
    love.graphics.setColor(Colors.accent)
    love.graphics.circle("fill",42,52,18)
    love.graphics.setColor(1,1,1)
    love.graphics.setFont(Fonts.body)
    love.graphics.print("T",35,41)
    love.graphics.setColor(Colors.text)
    love.graphics.setFont(Fonts.title)
    love.graphics.print("TutorMate",70,38)

    -- Avatar
    love.graphics.setColor(Colors.accentSoft)
    love.graphics.circle("fill",44,160,30)
    love.graphics.setColor(Colors.accent)
    love.graphics.setFont(Fonts.title)
    love.graphics.print(string.upper(string.sub(nombre(),1,1)),34,146)
    love.graphics.setColor(Colors.text)
    love.graphics.setFont(Fonts.body)
    love.graphics.print(nombre(),84,148)
    love.graphics.setColor(Colors.textSub)
    love.graphics.setFont(Fonts.small)
    love.graphics.print(string.upper(params.rol or "estudiante"),84,172)

    -- Nav
    for i,n in ipairs(nav) do
        local ny = 260+(i-1)*70
        if n.active then
            love.graphics.setColor(Colors.accentSoft)
            love.graphics.rectangle("fill",12,ny,SW-24,50,12)
        elseif hovNav[i] then
            love.graphics.setColor(Colors.bg)
            love.graphics.rectangle("fill",12,ny,SW-24,50,12)
        end
        love.graphics.setColor(n.active and Colors.accent or Colors.text)
        love.graphics.setFont(Fonts.body)
        love.graphics.print(n.label,50,ny+16)
    end

    -- Botón Nueva Solicitud con pulso
    local btnAlpha = hovBtn and 0.88 or 1
    love.graphics.setColor(Colors.accent[1],Colors.accent[2],Colors.accent[3],btnAlpha)
    love.graphics.rectangle("fill",18,1010,SW-36,54,14)
    -- halo pulso
    local p = (math.sin(pulse)+1)/2
    love.graphics.setColor(Colors.accent[1],Colors.accent[2],Colors.accent[3], p*0.18)
    love.graphics.rectangle("fill",10,1002,SW-20,70,18)
    love.graphics.setColor(1,1,1)
    love.graphics.setFont(Fonts.body)
    love.graphics.printf("+ Nueva Solicitud",18,1028,SW-36,"center")

    -- ── ÁREA PRINCIPAL ──
    local mx = mainX()
    -- Saludo con fade
    local ba = bannerA:value()
    love.graphics.setColor(Colors.text[1],Colors.text[2],Colors.text[3],ba)
    love.graphics.setFont(Fonts.big)
    love.graphics.print("Bienvenido, "..nombre().." ✨", mx, 36)
    love.graphics.setFont(Fonts.body)
    love.graphics.setColor(Colors.textSub[1],Colors.textSub[2],Colors.textSub[3],ba)
    love.graphics.print("Tienes "..#data.." tutorías activas.", mx, 84)

    -- Banner próxima sesión
    love.graphics.setColor(Colors.greenSoft[1],Colors.greenSoft[2],Colors.greenSoft[3],ba)
    love.graphics.rectangle("fill",mx,115,1580,130,20)
    -- dot pulsante
    local dp = (math.sin(pulse*1.5)+1)/2
    love.graphics.setColor(Colors.green[1],Colors.green[2],Colors.green[3],0.4+dp*0.6)
    love.graphics.circle("fill",mx+24,115+65,9)
    love.graphics.setColor(Colors.green[1],Colors.green[2],Colors.green[3],ba)
    love.graphics.rectangle("fill",mx+42,127,130,28,10)
    love.graphics.setColor(1,1,1,ba)
    love.graphics.setFont(Fonts.small)
    love.graphics.printf("Próx. Sesión",mx+42,133,130,"center")
    love.graphics.setColor(Colors.text[1],Colors.text[2],Colors.text[3],ba)
    love.graphics.setFont(Fonts.title)
    love.graphics.print("Estadística Aplicada — Probabilidad",mx+42,165)
    love.graphics.setFont(Fonts.small)
    love.graphics.setColor(Colors.textSub[1],Colors.textSub[2],Colors.textSub[3],ba)
    love.graphics.print("Hoy, 16:00 hs  ·  45 min",mx+42,199)
    -- botón unirse
    love.graphics.setColor(Colors.card[1],Colors.card[2],Colors.card[3],ba)
    love.graphics.rectangle("fill",mx+1440,140,140,52,12)
    love.graphics.setColor(Colors.green[1],Colors.green[2],Colors.green[3],ba)
    love.graphics.setFont(Fonts.body)
    love.graphics.printf("Unirse →",mx+1440,158,140,"center")

    -- Subtítulo tarjetas
    love.graphics.setColor(Colors.text[1],Colors.text[2],Colors.text[3],ba)
    love.graphics.setFont(Fonts.title)
    love.graphics.print("Tus Tutorías Activas",mx,478)

    -- ── TARJETAS con stagger ──
    for i,t in ipairs(data) do
        local col = (i-1)%3
        local row = math.floor((i-1)/3)
        local cx = mx + col*(CARD_W+30)
        local cy = CARD_Y + row*(CARD_H+24)
        local offY, alpha = Anim.staggerValue(stag, i)
        cy = cy + offY
        local ac = avColor(t.nivel_avance_actual)
        local isHov = hovCards[i]

        -- sombra
        love.graphics.setColor(0,0,0, isHov and 0.10*alpha or 0.05*alpha)
        love.graphics.rectangle("fill",cx+4,cy+6,CARD_W,CARD_H,16)
        -- card
        love.graphics.setColor(isHov and {0.97,0.96,1} or Colors.card)
        love.graphics.setColor((isHov and {0.97,0.96,1} or Colors.card)[1],
                               (isHov and {0.97,0.96,1} or Colors.card)[2] or 1,
                               (isHov and {0.97,0.96,1} or Colors.card)[3] or 1, alpha)
        love.graphics.rectangle("fill",cx,cy,CARD_W,CARD_H,16)
        -- línea superior de color
        love.graphics.setColor(ac[1],ac[2],ac[3],alpha)
        love.graphics.rectangle("fill",cx,cy,CARD_W,5,{0,0,16,16})

        -- icono área
        love.graphics.setColor(ac[1],ac[2],ac[3],0.15*alpha)
        love.graphics.rectangle("fill",cx+16,cy+18,46,46,10)
        love.graphics.setColor(ac[1],ac[2],ac[3],alpha)
        love.graphics.setFont(Fonts.body)
        love.graphics.print("📚",cx+20,cy+24)

        -- nombre área
        love.graphics.setColor(Colors.text[1],Colors.text[2],Colors.text[3],alpha)
        love.graphics.setFont(Fonts.body)
        love.graphics.print(t.area or "Área",cx+72,cy+20)
        love.graphics.setColor(Colors.textSub[1],Colors.textSub[2],Colors.textSub[3],alpha)
        love.graphics.setFont(Fonts.small)
        love.graphics.print("Tutor ID: "..t.tutor_id,cx+72,cy+44)

        -- separador
        love.graphics.setColor(Colors.border[1],Colors.border[2],Colors.border[3],alpha)
        love.graphics.rectangle("fill",cx+16,cy+78,CARD_W-32,1)

        -- nivel
        love.graphics.setColor(Colors.textSub[1],Colors.textSub[2],Colors.textSub[3],alpha)
        love.graphics.setFont(Fonts.small)
        love.graphics.print("NIVEL DE AVANCE",cx+16,cy+90)
        love.graphics.setColor(ac[1],ac[2],ac[3],alpha)
        love.graphics.setFont(Fonts.body)
        love.graphics.print(string.upper(t.nivel_avance_actual or "bajo"),cx+16,cy+110)
        love.graphics.setColor(Colors.textSub[1],Colors.textSub[2],Colors.textSub[3],alpha)
        love.graphics.setFont(Fonts.small)
        love.graphics.print(t.sesiones_realizadas.." / 8 Sesiones",cx+190,cy+110)

        -- barra de progreso tricolor
        local segW = (CARD_W-32)/3 - 5
        local niveles = {"bajo","medio","alto"}
        local pColors = {Colors.red, Colors.orange, Colors.green}
        for pi,nv in ipairs(niveles) do
            local px2 = cx+16+(pi-1)*(segW+5)
            local active = (nv == t.nivel_avance_actual)
            local prev   = (pi == 1 and t.nivel_avance_actual ~= "bajo") or
                           (pi == 2 and t.nivel_avance_actual == "alto")
            local opacity = (active or prev) and alpha or alpha*0.2
            love.graphics.setColor(pColors[pi][1],pColors[pi][2],pColors[pi][3],opacity)
            love.graphics.rectangle("fill",px2,cy+140,segW,10,5)
        end

        -- badge estado
        local sc = t.estado=="activa" and Colors.green
                or t.estado=="activa_con_alerta" and Colors.orange
                or Colors.textSub
        love.graphics.setColor(sc[1],sc[2],sc[3],0.15*alpha)
        love.graphics.rectangle("fill",cx+16,cy+165,120,28,10)
        love.graphics.setColor(sc[1],sc[2],sc[3],alpha)
        love.graphics.setFont(Fonts.small)
        love.graphics.printf(t.estado or "activa",cx+16,cy+170,120,"center")

        -- alerta ausencias
        if t.ausencias_consecutivas and t.ausencias_consecutivas>0 then
            love.graphics.setColor(Colors.red[1],Colors.red[2],Colors.red[3],alpha)
            love.graphics.setFont(Fonts.small)
            love.graphics.print("⚠ "..t.ausencias_consecutivas.." ausencia(s)",cx+148,cy+170)
        end
    end
end

function DashboardScreen.mousepressed(x,y,btn)
    for i,n in ipairs(nav) do
        local ny=260+(i-1)*70
        if x>=0 and x<=SW and y>=ny and y<=ny+54 then
            for j,_ in ipairs(nav) do nav[j].active=false end
            nav[i].active=true
            Nav.to(n.screen,{rol=params.rol},1)
            return
        end
    end
    if x>=18 and x<=SW-18 and y>=1010 and y<=1064 then
        Nav.to("solicitud",{rol=params.rol},1)
    end
end

return DashboardScreen
