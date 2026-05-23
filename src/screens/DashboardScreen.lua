local SM   = require("src.screens.ScreenManager")
local Anim = require("src.anim.Anim")
local UI   = require("src.components.UI")
local data = require("src.data.tutorias")

local DS = {}
local SW = 240
local nav = {
    { label="Dashboard",    screen="dashboard",   active=true  },
    { label="Mis Sesiones", screen="sesion",      active=false },
    { label="Solicitudes",  screen="solicitud",   active=false },
    { label="Seguimiento",  screen="seguimiento", active=false },
    { label="Asignaci\xc3\xb3n",   screen="asignacion",  active=false },
}
local hovNav={} local hovCards={} local hovBtn=false
local stag={} local bannerA=nil local pulse=0 local params={}

local CARD_GAP = 16

local function W() return love.graphics.getWidth() end
local function H() return love.graphics.getHeight() end
local function MX() return SW + 28 end
local function CONTENT_W() return W() - MX() - 28 end

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

function DS.load(p)
    params = p or {rol="estudiante"}
    hovNav={} hovCards={} pulse=0
    stag    = Anim.staggerList(#data, 0.07, 0.5)
    bannerA = Anim.new(0, 1, 0.5, "easeOut")
end

function DS.update(dt)
    bannerA:update(dt)
    Anim.staggerUpdate(stag, dt)
    pulse = pulse + dt * 2.5
    local mx, my = love.mouse.getPosition()
    local WW, HH = W(), H()
    for i = 1, #nav do
        local ny = 210 + (i-1)*52
        hovNav[i] = mx>=0 and mx<=SW and my>=ny and my<=ny+44
    end
    -- calcular layout de tarjetas igual que en draw
    local cw = math.floor((CONTENT_W() - CARD_GAP*2) / 3)
    local ch = math.max(180, math.floor(HH * 0.30))
    for i = 1, #data do
        local col = (i-1) % 3
        local row = math.floor((i-1) / 3)
        local cx  = MX() + col*(cw + CARD_GAP)
        local cy  = math.floor(HH * 0.42) + row*(ch + CARD_GAP)
        hovCards[i] = mx>=cx and mx<=cx+cw and my>=cy and my<=cy+ch
    end
    hovBtn = mx>=12 and mx<=SW-12 and my>=HH-62 and my<=HH-14
end

function DS.draw()
    local WW, HH = W(), H()
    local ba  = bannerA:value()
    local mx2 = MX()
    local cw2 = CONTENT_W()

    -- FONDO
    love.graphics.setColor(Colors.bg)
    love.graphics.rectangle("fill", 0, 0, WW, HH)

    -- SIDEBAR
    love.graphics.setColor(Colors.sidebar)
    love.graphics.rectangle("fill", 0, 0, SW, HH)
    love.graphics.setColor(Colors.border)
    love.graphics.rectangle("fill", SW, 0, 1, HH)

    -- Logo
    love.graphics.setColor(Colors.accent)
    love.graphics.circle("fill", 32, 34, 14)
    love.graphics.setColor(1,1,1)
    love.graphics.setFont(Fonts.small)
    love.graphics.printf("T", 18, 27, 28, "center")
    love.graphics.setColor(Colors.text)
    love.graphics.setFont(Fonts.body)
    love.graphics.print("TutorMate", 54, 24)

    -- Avatar
    love.graphics.setColor(Colors.accentSoft)
    love.graphics.circle("fill", 34, 108, 24)
    love.graphics.setColor(Colors.accent)
    love.graphics.setFont(Fonts.body)
    love.graphics.printf(string.upper(string.sub(nombre(),1,1)), 10, 100, 48, "center")
    love.graphics.setColor(Colors.text)
    love.graphics.setFont(Fonts.body)
    love.graphics.print(nombre(), 68, 98)
    love.graphics.setColor(Colors.textSub)
    love.graphics.setFont(Fonts.small)
    love.graphics.print(string.upper(params.rol or "estudiante"), 68, 116)

    -- NAV
    for i, n in ipairs(nav) do
        local ny = 210 + (i-1)*52
        if n.active then
            love.graphics.setColor(Colors.accentSoft)
            love.graphics.rectangle("fill", 8, ny, SW-16, 42, 10)
        elseif hovNav[i] then
            love.graphics.setColor(Colors.bg)
            love.graphics.rectangle("fill", 8, ny, SW-16, 42, 10)
        end
        love.graphics.setColor(n.active and Colors.accent or Colors.text)
        love.graphics.setFont(Fonts.body)
        love.graphics.print(n.label, 38, ny+12)
    end

    -- Boton Nueva Solicitud
    local p2 = (math.sin(pulse)+1)/2
    love.graphics.setColor(Colors.accent[1], Colors.accent[2], Colors.accent[3], p2*0.15)
    love.graphics.rectangle("fill", 6, HH-70, SW-12, 56, 14)
    love.graphics.setColor(Colors.accent)
    love.graphics.rectangle("fill", 12, HH-62, SW-24, 44, 12)
    love.graphics.setColor(1,1,1)
    love.graphics.setFont(Fonts.body)
    love.graphics.printf("+ Nueva Solicitud", 12, HH-51, SW-24, "center")

    -- CONTENIDO PRINCIPAL
    -- Saludo
    love.graphics.setColor(Colors.text[1], Colors.text[2], Colors.text[3], ba)
    love.graphics.setFont(Fonts.big)
    love.graphics.print("Bienvenido, "..nombre().."!", mx2, 22)
    love.graphics.setFont(Fonts.body)
    love.graphics.setColor(Colors.textSub[1], Colors.textSub[2], Colors.textSub[3], ba)
    love.graphics.print("Tienes "..#data.." tutor\xc3\xadas activas.", mx2, 56)

    -- Banner proxima sesion
    local banH = math.max(90, math.floor(HH * 0.12))
    local banW = cw2
    love.graphics.setColor(Colors.greenSoft[1], Colors.greenSoft[2], Colors.greenSoft[3], ba)
    love.graphics.rectangle("fill", mx2, 76, banW, banH, 14)

    local dotPulse = (math.sin(pulse*1.5)+1)/2
    love.graphics.setColor(Colors.green[1], Colors.green[2], Colors.green[3], 0.4+dotPulse*0.5)
    love.graphics.circle("fill", mx2+18, 76+banH/2, 6)

    -- badge Prox Sesion
    love.graphics.setColor(Colors.green)
    love.graphics.rectangle("fill", mx2+34, 76+10, 118, 22, 8)
    love.graphics.setColor(1,1,1)
    love.graphics.setFont(Fonts.small)
    love.graphics.printf("Pr\xc3\xb3x. Sesi\xc3\xb3n", mx2+34, 76+14, 118, "center")

    -- texto banner
    love.graphics.setColor(Colors.text[1], Colors.text[2], Colors.text[3], ba)
    love.graphics.setFont(Fonts.body)
    love.graphics.print("Estad\xc3\xadstica Aplicada \xe2\x80\x94 Probabilidad", mx2+34, 76+38)
    love.graphics.setColor(Colors.textSub[1], Colors.textSub[2], Colors.textSub[3], ba)
    love.graphics.setFont(Fonts.small)
    love.graphics.print("Hoy, 16:00 hs  \xc2\xb7  45 min", mx2+34, 76+58)

    -- boton unirse
    love.graphics.setColor(Colors.card[1], Colors.card[2], Colors.card[3], ba)
    love.graphics.rectangle("fill", mx2+banW-120, 76+banH/2-18, 106, 36, 10)
    love.graphics.setColor(Colors.green[1], Colors.green[2], Colors.green[3], ba)
    love.graphics.setFont(Fonts.body)
    love.graphics.printf("Unirse >", mx2+banW-120, 76+banH/2-9, 106, "center")

    -- Subtitulo tarjetas
    local cardsY0 = 76 + banH + 22
    love.graphics.setColor(Colors.text[1], Colors.text[2], Colors.text[3], ba)
    love.graphics.setFont(Fonts.body)
    love.graphics.print("Tus Tutor\xc3\xadas Activas", mx2, cardsY0 - 28)

    -- TARJETAS
    local cw = math.floor((cw2 - CARD_GAP*2) / 3)
    local ch = math.max(180, math.floor(HH * 0.30))

    for i, t in ipairs(data) do
        local col = (i-1) % 3
        local row = math.floor((i-1) / 3)
        local cx  = mx2 + col*(cw + CARD_GAP)
        local cy  = cardsY0 + row*(ch + CARD_GAP)
        local offY, alpha = Anim.staggerValue(stag, i)
        cy = cy + offY
        local ac  = avColor(t.nivel_avance_actual)
        local isHov = hovCards[i]

        -- sombra
        love.graphics.setColor(0,0,0, isHov and 0.08*alpha or 0.04*alpha)
        love.graphics.rectangle("fill", cx+3, cy+4, cw, ch, 14)
        -- fondo card
        love.graphics.setColor(isHov and 0.97 or 1, isHov and 0.96 or 1, 1, alpha)
        love.graphics.rectangle("fill", cx, cy, cw, ch, 14)
        -- tira superior de color (radio uniforme 14, no tabla)
        love.graphics.setColor(ac[1], ac[2], ac[3], alpha)
        love.graphics.rectangle("fill", cx, cy, cw, 14, 14)   -- tira redondeada arriba
        love.graphics.rectangle("fill", cx, cy+7, cw, 7, 0)   -- rellenar esquinas inferiores de la tira

        -- icono area
        love.graphics.push()
        love.graphics.translate(cx+14, cy+22)
        UI.areaIcon(0, 0, ac)
        love.graphics.pop()

        -- nombre area
        love.graphics.setColor(Colors.text[1], Colors.text[2], Colors.text[3], alpha)
        love.graphics.setFont(Fonts.body)
        love.graphics.print(t.area or "\xc3\x81rea", cx+58, cy+24)
        love.graphics.setColor(Colors.textSub[1], Colors.textSub[2], Colors.textSub[3], alpha)
        love.graphics.setFont(Fonts.small)
        love.graphics.print("Tutor: "..t.tutor_id, cx+58, cy+42)

        -- separador
        love.graphics.setColor(Colors.border[1], Colors.border[2], Colors.border[3], alpha)
        love.graphics.rectangle("fill", cx+14, cy+70, cw-28, 1)

        -- nivel de avance
        love.graphics.setColor(Colors.textSub[1], Colors.textSub[2], Colors.textSub[3], alpha)
        love.graphics.setFont(Fonts.small)
        love.graphics.print("NIVEL DE AVANCE", cx+14, cy+80)
        love.graphics.setColor(ac[1], ac[2], ac[3], alpha)
        love.graphics.setFont(Fonts.body)
        love.graphics.print(string.upper(t.nivel_avance_actual or "bajo"), cx+14, cy+96)
        love.graphics.setColor(Colors.textSub[1], Colors.textSub[2], Colors.textSub[3], alpha)
        love.graphics.setFont(Fonts.small)
        love.graphics.print(t.sesiones_realizadas.." / 8", cx+cw-70, cy+98)

        -- barra progreso
        love.graphics.push()
        love.graphics.translate(cx+14, cy+122)
        UI.progressBar3(0, 0, cw-28, 7, t.nivel_avance_actual)
        love.graphics.pop()

        -- badge estado (ancho calculado, nunca se corta)
        local elabel = t.estado or "activa"
        local ecolor = (t.estado=="activa") and Colors.green
                    or (t.estado=="activa_con_alerta") and Colors.orange
                    or Colors.textSub
        local etw = Fonts.small:getWidth(elabel) + 20
        love.graphics.setColor(ecolor[1], ecolor[2], ecolor[3], 0.15*alpha)
        love.graphics.rectangle("fill", cx+14, cy+138, etw, 22, 8)
        love.graphics.setColor(ecolor[1], ecolor[2], ecolor[3], alpha)
        love.graphics.setFont(Fonts.small)
        love.graphics.print(elabel, cx+24, cy+142)

        -- ausencias
        if t.ausencias_consecutivas and t.ausencias_consecutivas > 0 then
            love.graphics.setColor(Colors.red[1], Colors.red[2], Colors.red[3], alpha)
            love.graphics.setFont(Fonts.small)
            love.graphics.print("! "..t.ausencias_consecutivas.." ausencia(s)", cx+14+etw+8, cy+142)
        end
    end
end

function DS.mousepressed(x, y, btn)
    local HH = H()
    for i, n in ipairs(nav) do
        local ny = 210 + (i-1)*52
        if x>=0 and x<=SW and y>=ny and y<=ny+44 then
            for j = 1, #nav do nav[j].active = false end
            nav[i].active = true
            Nav.to(n.screen, {rol=params.rol}, 1)
            return
        end
    end
    if x>=12 and x<=SW-12 and y>=HH-62 and y<=HH-14 then
        Nav.to("solicitud", {rol=params.rol}, 1)
    end
end

return DS
