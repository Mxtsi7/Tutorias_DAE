local Anim        = require("src.anim.Anim")
local UI          = require("src.components.UI")
local TutoriaRepo = require("src.db.TutoriaRepo")
local Session     = require("src.session.Session")
local DB          = require("src.db.DB")
local EventBus    = require("src.events.EventBus")
local EventTypes  = require("src.events.EventTypes")

local DS = {}
local SW = 240

local NAV_POR_ROL = {
    estudiante  = {
        { label="Dashboard",   screen="dashboard" },
        { label="Mis Sesiones",screen="sesion" },
        { label="Solicitudes", screen="solicitud" },
    },
    tutor = {
        { label="Dashboard",   screen="dashboard" },
        { label="Mis Sesiones",screen="sesion" },
        { label="Propuestas",  screen="aceptacion_tutor", badge=true },
    },
    coordinador = {
        { label="Dashboard",   screen="dashboard" },
        { label="Solicitudes", screen="solicitud" },
        { label="Seguimiento", screen="seguimiento" },
        { label="Asignacion",  screen="asignacion" },
    },
}
local BTN_POR_ROL = {
    estudiante  = "+ Nueva Solicitud",
    tutor       = "+ Registrar Sesion",
    coordinador = "+ Asignar Tutor",
}
local BTN_SCREEN = {
    estudiante  = "solicitud",
    tutor       = "sesion",
    coordinador = "asignacion",
}
local BTN_EXTRA = {
    estudiante  = { modo="nueva" },
    tutor       = { modo="nueva" },
    coordinador = {},
}

local nav = {}
local hovNav={} local hovCards={} local stag={}
local bannerA=nil local pulse=0 local params={}
local tutorias={}
local nPropuestas = 0

-- Cola de alertas de coordinador pendientes de decision
-- Cada entrada: { tipo, tutoria_id, estudiante, ausencias, mensaje, animA }
local alertas = {}
local hovAlertaBtn = {}   -- hover[alerta_idx]["continuar"|"suspender"]

local CARD_GAP=16
local function W() return love.graphics.getWidth() end
local function H() return love.graphics.getHeight() end
local function MX() return SW+28 end
local function CONTENT_W() return W()-MX()-28 end

local function avColor(n)
    if n=="alto"  then return Colors.green
    elseif n=="medio" then return Colors.orange
    else return Colors.red end
end

local function contarPropuestastutor(uid)
    if not uid then return 0 end
    local tutor = DB.find("tutores", function(t) return t.usuario_id == uid end)
    if not tutor then return 0 end
    local lista = DB.where("solicitudes", function(s)
        return s.estado == "asignacion_propuesta"
               and s.tutor_propuesto == tutor.id
    end)
    return #lista
end

-- Suscripcion a ALERTA_COORDINADOR (solo se registra una vez)
local _alertaSuscrita = false
local function suscribirAlertas()
    if _alertaSuscrita then return end
    _alertaSuscrita = true
    EventBus.subscribe(EventTypes.ALERTA_COORDINADOR, function(data)
        -- Solo acumulamos advertencia_formal y abandono_potencial como tarjetas de decision.
        -- ausencia_primera es solo informativa (no requiere accion inmediata).
        if data.tipo == "advertencia_formal" or data.tipo == "abandono_potencial" then
            -- Evitar duplicados para la misma tutoria
            for _, a in ipairs(alertas) do
                if a.tutoria_id == data.tutoria_id then
                    a.ausencias = data.ausencias or a.ausencias
                    a.mensaje   = data.mensaje   or a.mensaje
                    a.tipo      = data.tipo
                    return
                end
            end
            alertas[#alertas+1] = {
                tipo       = data.tipo,
                tutoria_id = data.tutoria_id,
                estudiante = data.estudiante or "Estudiante",
                ausencias  = data.ausencias  or 0,
                mensaje    = data.mensaje    or "",
                animA      = Anim.new(0, 1, 0.4, "easeOut"),
            }
        end
    end)
end

function DS.load(p)
    params = p or {rol="estudiante"}
    hovNav={} hovCards={} hovAlertaBtn={} pulse=0
    local rol = params.rol or "estudiante"
    nav = {}
    for i,item in ipairs(NAV_POR_ROL[rol] or NAV_POR_ROL.estudiante) do
        nav[i] = {
            label  = item.label,
            screen = item.screen,
            active = (i==1),
            badge  = item.badge or false,
        }
    end
    local uid = Session.usuario_id or params.usuario_id
    if rol=="estudiante" and uid then
        tutorias = TutoriaRepo.getByEstudiante(uid)
    elseif rol=="tutor" and uid then
        tutorias = TutoriaRepo.getByTutor(uid)
        nPropuestas = contarPropuestastutor(uid)
    else
        tutorias = TutoriaRepo.getAll()
        nPropuestas = 0
    end
    stag    = Anim.staggerList(#tutorias,0.07,0.5)
    bannerA = Anim.new(0,1,0.5,"easeOut")
    suscribirAlertas()
end

function DS.update(dt)
    bannerA:update(dt)
    Anim.staggerUpdate(stag,dt)
    pulse=pulse+dt*2.5
    for _, a in ipairs(alertas) do
        if a.animA then a.animA:update(dt) end
    end
    local mx,my=love.mouse.getPosition()
    for i=1,#nav do
        local ny=210+(i-1)*52
        hovNav[i]=mx>=0 and mx<=SW and my>=ny and my<=ny+44
    end
    local cw=math.floor((CONTENT_W()-CARD_GAP*2)/3)
    local ch=math.max(180,math.floor(H()*0.30))
    for i=1,#tutorias do
        local col=(i-1)%3
        local row=math.floor((i-1)/3)
        local cx=MX()+col*(cw+CARD_GAP)
        local cy=math.floor(H()*0.38)+row*(ch+CARD_GAP)
        hovCards[i]=mx>=cx and mx<=cx+cw and my>=cy and my<=cy+ch
    end
    -- Hover botones alertas
    hovAlertaBtn = {}
    local rol = params.rol or "estudiante"
    if rol == "coordinador" then
        local WW = W()
        local alertW = CONTENT_W()
        local alertX = MX()
        for i, a in ipairs(alertas) do
            local ay = 76 + (i-1) * 114
            local btnY = ay + 62
            hovAlertaBtn[i] = {
                continuar  = mx>=alertX+12    and mx<=alertX+130   and my>=btnY and my<=btnY+34,
                suspender  = mx>=alertX+150   and mx<=alertX+290   and my>=btnY and my<=btnY+34,
            }
        end
    end
end

local function nombre()
    return Session.nombre or params.nombre or "Usuario"
end

-- Dibuja la zona de alertas para coordinador (devuelve la Y donde termino)
local function drawAlertas(startY, alertW, alertX, ba)
    if #alertas == 0 then return startY end
    local curY = startY
    for i, a in ipairs(alertas) do
        local alpha = (a.animA and a.animA:value() or 1) * ba
        local cardH = 104
        local isFormal    = a.tipo == "advertencia_formal"
        local isAbandono  = a.tipo == "abandono_potencial"
        local borderColor = isAbandono and Colors.red or Colors.orange
        local bgColor     = isAbandono and {0.99,0.95,0.95} or {0.99,0.97,0.92}

        -- Sombra
        love.graphics.setColor(0,0,0,0.07*alpha)
        love.graphics.rectangle("fill", alertX+3, curY+4, alertW, cardH, 12)
        -- Fondo tarjeta
        love.graphics.setColor(bgColor[1], bgColor[2], bgColor[3], alpha)
        love.graphics.rectangle("fill", alertX, curY, alertW, cardH, 12)
        -- Borde lateral
        love.graphics.setColor(borderColor[1], borderColor[2], borderColor[3], alpha)
        love.graphics.rectangle("fill", alertX, curY, 5, cardH, 5)

        -- Icono de alerta
        love.graphics.setColor(borderColor[1], borderColor[2], borderColor[3], alpha)
        love.graphics.setFont(Fonts.title)
        love.graphics.print(isAbandono and "!" or "!", alertX+18, curY+12)

        -- Texto: nombre estudiante y ausencias
        love.graphics.setColor(Colors.text[1], Colors.text[2], Colors.text[3], alpha)
        love.graphics.setFont(Fonts.body)
        local titulo = isAbandono
            and "Abandono potencial - " .. a.estudiante
            or  "Advertencia formal - " .. a.estudiante
        love.graphics.print(titulo, alertX+42, curY+14)
        love.graphics.setColor(Colors.textSub[1], Colors.textSub[2], Colors.textSub[3], alpha)
        love.graphics.setFont(Fonts.small)
        love.graphics.print(
            a.ausencias .. " ausencia(s) injustificada(s)  |  Tutoria #" .. tostring(a.tutoria_id),
            alertX+42, curY+36)
        love.graphics.print("Accion requerida: decide si la tutoria continua o se suspende.",
            alertX+42, curY+52)

        -- Boton Continuar
        local btnY = curY + 64
        local hC   = hovAlertaBtn[i] and hovAlertaBtn[i].continuar
        love.graphics.setColor(
            hC and Colors.green[1] or Colors.green[1]*0.85,
            hC and Colors.green[2] or Colors.green[2]*0.85,
            hC and Colors.green[3] or Colors.green[3]*0.85, alpha)
        love.graphics.rectangle("fill", alertX+12, btnY, 120, 32, 8)
        love.graphics.setColor(1,1,1,alpha)
        love.graphics.setFont(Fonts.body)
        love.graphics.printf("Continuar", alertX+12, btnY+8, 120, "center")

        -- Boton Suspender
        local hS = hovAlertaBtn[i] and hovAlertaBtn[i].suspender
        love.graphics.setColor(
            hS and Colors.red[1] or Colors.red[1]*0.85,
            hS and Colors.red[2] or Colors.red[2]*0.85,
            hS and Colors.red[3] or Colors.red[3]*0.85, alpha)
        love.graphics.rectangle("fill", alertX+150, btnY, 140, 32, 8)
        love.graphics.setColor(1,1,1,alpha)
        love.graphics.printf("Suspender", alertX+150, btnY+8, 140, "center")

        curY = curY + cardH + 10
    end
    return curY + 8
end

function DS.draw()
    local WW,HH=W(),H()
    local ba=bannerA:value()
    local mx2=MX()
    local cw2=CONTENT_W()
    local rol = params.rol or "estudiante"

    love.graphics.setColor(Colors.bg)
    love.graphics.rectangle("fill",0,0,WW,HH)
    love.graphics.setColor(Colors.sidebar)
    love.graphics.rectangle("fill",0,0,SW,HH)
    love.graphics.setColor(Colors.border)
    love.graphics.rectangle("fill",SW,0,1,HH)

    -- Logo
    love.graphics.setColor(Colors.accent)
    love.graphics.circle("fill",32,34,14)
    love.graphics.setColor(1,1,1)
    love.graphics.setFont(Fonts.small)
    love.graphics.printf("T",18,27,28,"center")
    love.graphics.setColor(Colors.text)
    love.graphics.setFont(Fonts.body)
    love.graphics.print("TutorMate",54,24)

    -- Avatar
    love.graphics.setColor(Colors.accentSoft)
    love.graphics.circle("fill",34,108,24)
    love.graphics.setColor(Colors.accent)
    love.graphics.setFont(Fonts.body)
    love.graphics.printf(string.upper(string.sub(nombre(),1,1)),10,100,48,"center")
    love.graphics.setColor(Colors.text)
    love.graphics.setFont(Fonts.body)
    love.graphics.print(nombre(),68,98)
    love.graphics.setColor(Colors.textSub)
    love.graphics.setFont(Fonts.small)
    love.graphics.print(string.upper(rol),68,116)

    -- Nav items
    for i,n in ipairs(nav) do
        local ny=210+(i-1)*52
        if n.active then
            love.graphics.setColor(Colors.accentSoft)
            love.graphics.rectangle("fill",8,ny,SW-16,42,10)
        elseif hovNav[i] then
            love.graphics.setColor(Colors.bg)
            love.graphics.rectangle("fill",8,ny,SW-16,42,10)
        end
        love.graphics.setColor(n.active and Colors.accent or Colors.text)
        love.graphics.setFont(Fonts.body)
        love.graphics.print(n.label,38,ny+12)

        if n.badge and nPropuestas > 0 then
            local pulse2 = (math.sin(pulse * 1.8) + 1) / 2
            local bx = SW - 30
            local by = ny + 11
            love.graphics.setColor(
                Colors.red[1], Colors.red[2], Colors.red[3],
                0.75 + pulse2 * 0.25)
            love.graphics.circle("fill", bx, by, 10)
            love.graphics.setColor(1,1,1)
            love.graphics.setFont(Fonts.small)
            love.graphics.printf(tostring(nPropuestas), bx-10, by-7, 20, "center")
        end
    end

    -- Boton inferior
    local btnLabel = BTN_POR_ROL[rol] or "+ Accion"
    local p2=(math.sin(pulse)+1)/2
    love.graphics.setColor(Colors.accent[1],Colors.accent[2],Colors.accent[3],p2*0.15)
    love.graphics.rectangle("fill",6,HH-70,SW-12,56,14)
    love.graphics.setColor(Colors.accent)
    love.graphics.rectangle("fill",12,HH-62,SW-24,44,12)
    love.graphics.setColor(1,1,1)
    love.graphics.setFont(Fonts.body)
    love.graphics.printf(btnLabel,12,HH-51,SW-24,"center")

    -- Saludo
    love.graphics.setColor(Colors.text[1],Colors.text[2],Colors.text[3],ba)
    love.graphics.setFont(Fonts.big)
    love.graphics.print("Bienvenido, "..nombre().."!",mx2,22)

    -- Subtitulo
    love.graphics.setFont(Fonts.body)
    love.graphics.setColor(Colors.textSub[1],Colors.textSub[2],Colors.textSub[3],ba)
    local subtitulo
    if rol == "coordinador" then
        local nPend = #DB.where("solicitudes", function(s) return s.estado=="pendiente" end)
        local nAlertas = #alertas
        subtitulo = nPend .. " solicitud(es) pendiente(s)  |  " .. #tutorias .. " tutorias activas"
        if nAlertas > 0 then
            subtitulo = subtitulo .. "  |  " .. nAlertas .. " alerta(s) requieren decision"
        end
    elseif rol == "tutor" then
        local extra = nPropuestas > 0
            and ("  |  " .. nPropuestas .. " propuesta(s) esperando respuesta")
            or ""
        subtitulo = "Tienes "..#tutorias.." tutoria(s) asignada(s)."..extra
    else
        subtitulo = "Tienes "..#tutorias.." tutoria(s) activa(s)."
    end
    love.graphics.print(subtitulo, mx2, 56)

    -- Banner / Alertas segun rol
    local banH    = math.max(90, math.floor(HH*0.12))
    local banW    = cw2
    local cardsY0

    if rol == "coordinador" then
        -- Para coordinador: mostrar tarjetas de alerta arriba si las hay
        local afterAlertas = drawAlertas(76, banW, mx2, ba)
        cardsY0 = afterAlertas + 8
    else
        -- Banner proxima sesion para estudiante/tutor
        love.graphics.setColor(Colors.greenSoft[1],Colors.greenSoft[2],Colors.greenSoft[3],ba)
        love.graphics.rectangle("fill",mx2,76,banW,banH,14)
        local dp=(math.sin(pulse*1.5)+1)/2
        love.graphics.setColor(Colors.green[1],Colors.green[2],Colors.green[3],0.4+dp*0.5)
        love.graphics.circle("fill",mx2+18,76+banH/2,6)
        love.graphics.setColor(Colors.green)
        love.graphics.rectangle("fill",mx2+34,76+10,118,22,8)
        love.graphics.setColor(1,1,1)
        love.graphics.setFont(Fonts.small)
        love.graphics.printf("Prox. Sesion",mx2+34,76+14,118,"center")
        love.graphics.setColor(Colors.text[1],Colors.text[2],Colors.text[3],ba)
        love.graphics.setFont(Fonts.body)
        local proxArea = tutorias[1] and (tutorias[1].area or "Sin sesiones") or "Sin sesiones"
        local proxLabel = rol=="tutor"
            and (proxArea.." - "..(tutorias[1] and tutorias[1].estudiante_nombre or "Sin tutorias"))
            or  (proxArea.." - Sesion pendiente")
        love.graphics.print(proxLabel,mx2+34,76+38)
        love.graphics.setColor(Colors.textSub[1],Colors.textSub[2],Colors.textSub[3],ba)
        love.graphics.setFont(Fonts.small)
        love.graphics.print("Hoy, 16:00 hs  |  45 min",mx2+34,76+58)
        love.graphics.setColor(Colors.card[1],Colors.card[2],Colors.card[3],ba)
        love.graphics.rectangle("fill",mx2+banW-120,76+banH/2-18,106,36,10)
        love.graphics.setColor(Colors.green[1],Colors.green[2],Colors.green[3],ba)
        love.graphics.setFont(Fonts.body)
        love.graphics.printf("Unirse >",mx2+banW-120,76+banH/2-9,106,"center")
        cardsY0 = 76+banH+22
    end

    -- Titulo cards
    local cardsLabel = rol=="coordinador" and "Tutorias en curso" or "Tus Tutorias Activas"
    love.graphics.setColor(Colors.text[1],Colors.text[2],Colors.text[3],ba)
    love.graphics.setFont(Fonts.body)
    love.graphics.print(cardsLabel, mx2, cardsY0-28)

    local cw=math.floor((cw2-CARD_GAP*2)/3)
    local ch=math.max(180,math.floor(HH*0.30))

    for i,t in ipairs(tutorias) do
        local col=(i-1)%3
        local row=math.floor((i-1)/3)
        local cx=mx2+col*(cw+CARD_GAP)
        local cy=cardsY0+row*(ch+CARD_GAP)
        local offY,alpha=Anim.staggerValue(stag,i)
        cy=cy+offY
        local nivel  = t.nivel_avance or t.nivel_avance_actual or "bajo"
        local sesNum = t.sesiones     or t.sesiones_realizadas  or 0
        local ausNum = t.ausencias    or t.ausencias_consecutivas or 0
        local ac=avColor(nivel)
        local isHov=hovCards[i]

        love.graphics.setColor(0,0,0,isHov and 0.08*alpha or 0.04*alpha)
        love.graphics.rectangle("fill",cx+3,cy+4,cw,ch,14)
        love.graphics.setColor(isHov and 0.97 or 1,isHov and 0.96 or 1,1,alpha)
        love.graphics.rectangle("fill",cx,cy,cw,ch,14)
        love.graphics.setColor(ac[1],ac[2],ac[3],alpha)
        love.graphics.rectangle("fill",cx,cy,cw,14,14)
        love.graphics.rectangle("fill",cx,cy+7,cw,7,0)

        love.graphics.push()
        love.graphics.translate(cx+14,cy+22)
        UI.areaIcon(0,0,ac)
        love.graphics.pop()

        love.graphics.setColor(Colors.text[1],Colors.text[2],Colors.text[3],alpha)
        love.graphics.setFont(Fonts.body)
        love.graphics.print(t.area or "Area",cx+58,cy+24)
        love.graphics.setColor(Colors.textSub[1],Colors.textSub[2],Colors.textSub[3],alpha)
        love.graphics.setFont(Fonts.small)
        local subInfo = rol=="coordinador"
            and "Est: "..(t.estudiante_nombre or "-")
            or  "Tutor: "..(t.tutor_nombre or "-")
        love.graphics.print(subInfo, cx+58, cy+42)

        love.graphics.setColor(Colors.border[1],Colors.border[2],Colors.border[3],alpha)
        love.graphics.rectangle("fill",cx+14,cy+70,cw-28,1)

        love.graphics.setColor(Colors.textSub[1],Colors.textSub[2],Colors.textSub[3],alpha)
        love.graphics.setFont(Fonts.small)
        love.graphics.print("NIVEL DE AVANCE",cx+14,cy+80)
        love.graphics.setColor(ac[1],ac[2],ac[3],alpha)
        love.graphics.setFont(Fonts.body)
        love.graphics.print(string.upper(nivel),cx+14,cy+96)
        love.graphics.setColor(Colors.textSub[1],Colors.textSub[2],Colors.textSub[3],alpha)
        love.graphics.setFont(Fonts.small)
        love.graphics.print(tostring(sesNum).." / 8",cx+cw-70,cy+98)

        love.graphics.push()
        love.graphics.translate(cx+14,cy+122)
        UI.progressBar3(0,0,cw-28,7,nivel)
        love.graphics.pop()

        local elabel=t.estado or "activa"
        local ecolor=(t.estado=="activa") and Colors.green
                  or (t.estado=="activa_con_alerta") and Colors.orange
                  or Colors.red
        local etw=Fonts.small:getWidth(elabel)+20
        love.graphics.setColor(ecolor[1],ecolor[2],ecolor[3],0.15*alpha)
        love.graphics.rectangle("fill",cx+14,cy+138,etw,22,8)
        love.graphics.setColor(ecolor[1],ecolor[2],ecolor[3],alpha)
        love.graphics.setFont(Fonts.small)
        love.graphics.print(elabel,cx+24,cy+142)

        if ausNum > 0 then
            love.graphics.setColor(Colors.red[1],Colors.red[2],Colors.red[3],alpha)
            love.graphics.setFont(Fonts.small)
            love.graphics.print("! "..ausNum.." ausencia(s)",cx+14+etw+8,cy+142)
        end
    end
end

function DS.mousepressed(x,y,btn)
    if btn ~= 1 then return end
    local HH=H()
    local rol = params.rol or "estudiante"

    -- Botones de alertas (solo coordinador)
    if rol == "coordinador" then
        local alertX = MX()
        local alertW = CONTENT_W()
        local removeIdx = nil
        for i, a in ipairs(alertas) do
            local ay   = 76 + (i-1) * 114
            local btnY = ay + 64
            -- Continuar
            if x>=alertX+12 and x<=alertX+132 and y>=btnY and y<=btnY+32 then
                EventBus.publish(EventTypes.TUTORIA_CONTINUA, {
                    tutoria_id = a.tutoria_id,
                    ausencias  = a.ausencias,
                })
                removeIdx = i
                break
            end
            -- Suspender
            if x>=alertX+150 and x<=alertX+290 and y>=btnY and y<=btnY+32 then
                EventBus.publish(EventTypes.TUTORIA_SUSPENDIDA, {
                    tutoria_id = a.tutoria_id,
                })
                removeIdx = i
                break
            end
        end
        if removeIdx then
            table.remove(alertas, removeIdx)
            -- Recargar tutorias para reflejar cambio de estado
            tutorias = TutoriaRepo.getAll()
            stag = Anim.staggerList(#tutorias, 0.07, 0.5)
            return
        end
    end

    -- Nav items
    for i,n in ipairs(nav) do
        local ny=210+(i-1)*52
        if x>=0 and x<=SW and y>=ny and y<=ny+44 then
            for j=1,#nav do nav[j].active=false end
            nav[i].active=true
            Nav.to(n.screen,{rol=rol,usuario_id=params.usuario_id,nombre=params.nombre},1)
            return
        end
    end
    if x>=12 and x<=SW-12 and y>=HH-62 and y<=HH-14 then
        local dest  = BTN_SCREEN[rol] or "solicitud"
        local extra = BTN_EXTRA[rol]  or {}
        local p = {rol=rol, usuario_id=params.usuario_id, nombre=params.nombre}
        for k,v in pairs(extra) do p[k]=v end
        Nav.to(dest, p, 1)
    end
end

return DS
