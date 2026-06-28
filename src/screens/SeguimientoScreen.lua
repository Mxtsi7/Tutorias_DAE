local Anim        = require("src.anim.Anim")
local TutoriaRepo = require("src.db.TutoriaRepo")
local DB          = require("src.db.DB")
local EventBus    = require("src.events.EventBus")
local EventTypes  = require("src.events.EventTypes")

local Seg = {}
local hover    = {} local stag = {} local params = {}
local tutorias = {} local nEspera = 0
local detalle  = nil
local accionMsg = ""
local accionOk  = false

-- Scroll
local scrollY   = 0
local ROW_H     = 88
local TABLE_TOP = 162   -- justo debajo de headers fijos
local FOOTER_H  = 72

local function W() return love.graphics.getWidth() end
local function H() return love.graphics.getHeight() end
local function tableAreaH() return H() - TABLE_TOP - FOOTER_H end
local function maxScroll()
    return math.max(0, #tutorias * ROW_H - tableAreaH())
end
local function clampScroll()
    scrollY = math.max(0, math.min(maxScroll(), scrollY))
end

local function enriquecer(t)
    if not t.estudiante_nombre then
        local est = DB.find("estudiantes", function(e) return e.id == t.estudiante_id end)
        if est then
            local usr = DB.find("usuarios", function(u) return u.id == est.usuario_id end)
            t.estudiante_nombre = usr and usr.nombre or "-"
        else
            t.estudiante_nombre = "-"
        end
    end
    if not t.tutor_nombre and t.tutor_id then
        local tut = DB.find("tutores", function(tt) return tt.id == t.tutor_id end)
        if tut then
            local usr2 = DB.find("usuarios", function(u) return u.id == tut.usuario_id end)
            t.tutor_nombre = usr2 and usr2.nombre or "-"
        end
    end
    return t
end

function Seg.load(p)
    params    = p or {}
    hover     = {}
    detalle   = nil
    accionMsg = ""
    accionOk  = false
    scrollY   = 0
    local raw = TutoriaRepo.getAll()
    tutorias  = {}
    for _, t in ipairs(raw) do
        tutorias[#tutorias+1] = enriquecer(t)
    end
    local sols = DB.where("solicitudes", function(s)
        return s.estado == "pendiente" or s.estado == "en_espera"
    end)
    nEspera = #sols
    stag = Anim.staggerList(#tutorias, 0.06, 0.4)
end

function Seg.update(dt)
    Anim.staggerUpdate(stag, dt)
    if detalle then return end
    local mx, my = love.mouse.getPosition()
    local areaH  = tableAreaH()
    for i in ipairs(tutorias) do
        local ry = TABLE_TOP + (i-1)*ROW_H - scrollY
        hover[i] = mx>=30 and mx<=W()-18
               and my>=math.max(TABLE_TOP, ry)
               and my<=math.min(TABLE_TOP+areaH, ry+ROW_H-6)
    end
end

-- Scroll con rueda del mouse
function Seg.wheelmoved(x, y)
    if detalle then return end
    scrollY = scrollY - y * 36
    clampScroll()
end

local function eColor(e)
    if     e == "activa"                              then return Colors.green
    elseif e == "activa_con_alerta"                  then return Colors.orange
    elseif e == "activa_con_advertencia_formal"      then return {0.9, 0.45, 0.1}
    elseif e == "activa_con_advertencia"             then return {0.9, 0.55, 0.1}
    elseif e == "suspendida"                         then return Colors.red
    elseif e == "pendiente_reasignacion"             then return {0.5, 0.3, 0.9}
    elseif e == "cerrada_exitosamente"               then return {0.3, 0.7, 0.4}
    elseif e == "cerrada_por_abandono"               then return {0.5, 0.5, 0.5}
    elseif e == "cerrada_por_abandono_voluntario"    then return {0.6, 0.6, 0.6}
    else return Colors.textSub end
end

-- Estados finales: no permiten ninguna accion
local ESTADOS_FINALES = {
    cerrada_exitosamente            = true,
    cerrada_por_abandono            = true,
    cerrada_por_abandono_voluntario = true,
}

-- -------------------------------------------------------
-- MODAL
-- -------------------------------------------------------
local function drawModal(t)
    local WW, HH = W(), H()
    local mw, mh = 560, 460
    local mx = math.floor((WW-mw)/2)
    local my = math.floor((HH-mh)/2)

    -- overlay
    love.graphics.setColor(0,0,0,0.5)
    love.graphics.rectangle("fill",0,0,WW,HH)

    -- card
    love.graphics.setColor(Colors.card)
    love.graphics.rectangle("fill",mx,my,mw,mh,16)
    love.graphics.setColor(Colors.accent)
    love.graphics.rectangle("fill",mx,my,mw,58,16)
    love.graphics.rectangle("fill",mx,my+42,mw,16,0)
    love.graphics.setColor(1,1,1)
    love.graphics.setFont(Fonts.title)
    love.graphics.printf("Detalle de Tutoria",mx,my+17,mw,"center")

    -- datos
    local nivel  = t.nivel_avance or "bajo"
    local sesNum = t.sesiones     or 0
    local ausNum = t.ausencias    or 0
    local ac     = nivel=="alto" and Colors.green or nivel=="medio" and Colors.orange or Colors.red
    local ec     = eColor(t.estado)

    local rows = {
        { "Estudiante",         t.estudiante_nombre or "-" },
        { "Tutor",              t.tutor_nombre      or "-" },
        { "Area",               t.area              or "-" },
        { "Sesiones",           tostring(sesNum).." / 8" },
        { "Ausencias consec.",  tostring(ausNum) },
        { "Nivel avance",       string.upper(nivel) },
        { "Estado",             t.estado or "-" },
        { "Advertencia formal", (t.advertencia_formal) and "Si" or "No" },
        { "Alerta avance bajo", (t.alerta_avance_bajo) and "Reunion requerida" or "Sin alerta" },
    }
    for i, row in ipairs(rows) do
        local ry2 = my+66+(i-1)*28
        love.graphics.setColor(Colors.textSub)
        love.graphics.setFont(Fonts.small)
        love.graphics.print(row[1], mx+24, ry2)
        local vc = (row[1]=="Nivel avance"      and ac)
                or (row[1]=="Estado"             and ec)
                or (row[1]=="Alerta avance bajo" and t.alerta_avance_bajo and Colors.orange)
                or Colors.text
        love.graphics.setColor(vc)
        love.graphics.print(row[2], mx+230, ry2)
    end

    -- ----- BOTONES -----
    local btnY = my + mh - 78
    local btnX = mx + 20
    local btnW = 148
    local btnH = 38
    local gap  = 14
    local bpos = btnX

    -- Cerrar (siempre presente, esquina derecha)
    love.graphics.setColor(Colors.border)
    love.graphics.rectangle("fill", mx+mw-168, btnY, 148, btnH, 10)
    love.graphics.setColor(Colors.text)
    love.graphics.setFont(Fonts.body)
    love.graphics.printf("Cerrar", mx+mw-168, btnY+10, 148, "center")

    if ESTADOS_FINALES[t.estado] then
        love.graphics.setColor(Colors.textSub)
        love.graphics.setFont(Fonts.small)
        love.graphics.printf("Esta tutoria ya fue cerrada.", btnX, btnY+12, mw-200, "center")

    elseif t.estado == "activa_con_advertencia_formal"
        or (t.ausencias and t.ausencias >= 2) then
        -- DECISION FORMAL: Continuar o Suspender
        love.graphics.setColor(Colors.green)
        love.graphics.rectangle("fill", bpos, btnY, btnW, btnH, 10)
        love.graphics.setColor(1,1,1)
        love.graphics.setFont(Fonts.body)
        love.graphics.printf("Continuar", bpos, btnY+10, btnW, "center")
        bpos = bpos + btnW + gap

        love.graphics.setColor(Colors.red)
        love.graphics.rectangle("fill", bpos, btnY, btnW, btnH, 10)
        love.graphics.setColor(1,1,1)
        love.graphics.printf("Suspender", bpos, btnY+10, btnW, "center")

    elseif t.estado == "activa_con_alerta" then
        love.graphics.setColor(Colors.orange)
        love.graphics.rectangle("fill", bpos, btnY, btnW, btnH, 10)
        love.graphics.setColor(1,1,1)
        love.graphics.setFont(Fonts.body)
        love.graphics.printf("Advertir", bpos, btnY+10, btnW, "center")
        bpos = bpos + btnW + gap

        love.graphics.setColor(Colors.red)
        love.graphics.rectangle("fill", bpos, btnY, btnW, btnH, 10)
        love.graphics.setColor(1,1,1)
        love.graphics.printf("Suspender", bpos, btnY+10, btnW, "center")

    elseif t.estado == "suspendida" then
        love.graphics.setColor(Colors.red)
        love.graphics.rectangle("fill", bpos, btnY, btnW+20, btnH, 10)
        love.graphics.setColor(1,1,1)
        love.graphics.setFont(Fonts.body)
        love.graphics.printf("Cierre por abandono", bpos, btnY+10, btnW+20, "center")

    else
        love.graphics.setColor(Colors.green)
        love.graphics.rectangle("fill", bpos, btnY, btnW+20, btnH, 10)
        love.graphics.setColor(1,1,1)
        love.graphics.setFont(Fonts.body)
        love.graphics.printf("Proponer cierre", bpos, btnY+10, btnW+20, "center")
    end

    -- Mensaje resultado
    if accionMsg ~= "" then
        local mc = accionOk and Colors.greenSoft or {0.99,0.94,0.94}
        local tc = accionOk and Colors.green     or Colors.red
        love.graphics.setColor(mc)
        love.graphics.rectangle("fill", mx+20, btnY-52, mw-40, 36, 8)
        love.graphics.setColor(tc)
        love.graphics.setFont(Fonts.small)
        love.graphics.printf(accionMsg, mx+20, btnY-42, mw-40, "center")
    end
end

function Seg.draw()
    local WW, HH = W(), H()
    love.graphics.setColor(Colors.bg)
    love.graphics.rectangle("fill",0,0,WW,HH)

    -- Header
    love.graphics.setColor(Colors.accent)
    love.graphics.rectangle("fill",0,0,WW,68)
    love.graphics.setColor(1,1,1)
    love.graphics.setFont(Fonts.title)
    love.graphics.printf("Seguimiento Semanal - Coordinador",0,22,WW,"center")

    -- KPIs
    local nActivas, nAlertas, nCerradas = 0, 0, 0
    for _,t in ipairs(tutorias) do
        local e = t.estado or ""
        if e=="activa" or e=="activa_con_alerta"
            or e=="activa_con_advertencia" or e=="activa_con_advertencia_formal" then
            nActivas = nActivas+1
        end
        if e=="activa_con_alerta" or e=="suspendida"
            or e=="activa_con_advertencia" or e=="activa_con_advertencia_formal" then
            nAlertas = nAlertas+1
        end
        if ESTADOS_FINALES[e] then nCerradas = nCerradas+1 end
    end
    local kpis = {
        { label="Tutorias Activas",      value=nActivas,  color=Colors.green },
        { label="Con Alertas",           value=nAlertas,  color=Colors.orange },
        { label="Solicitudes en Espera", value=nEspera,   color=Colors.textSub },
        { label="Cerradas",              value=nCerradas, color={0.5,0.5,0.5} },
    }
    local kw = math.floor((WW-70)/4)
    for i,k in ipairs(kpis) do
        local kx = 30+(i-1)*(kw+8)
        love.graphics.setColor(Colors.card)
        love.graphics.rectangle("fill",kx,78,kw,68,12)
        love.graphics.setColor(k.color)
        love.graphics.rectangle("fill",kx,78,5,68,4)
        love.graphics.setColor(Colors.text)
        love.graphics.setFont(Fonts.big)
        love.graphics.print(tostring(k.value),kx+18,82)
        love.graphics.setColor(Colors.textSub)
        love.graphics.setFont(Fonts.small)
        love.graphics.print(k.label,kx+18,118)
    end

    -- Cabecera tabla (FIJA, fuera del scissor)
    local SB      = 14
    local margin  = 30
    local TW      = WW - margin*2 - SB
    local colW    = math.floor(TW/8)
    local headers = {"Estudiante","Area","Tutor","Sesiones","Avance","Estado","Ausencias","Accion"}
    local headerY = TABLE_TOP - 20
    love.graphics.setColor(Colors.textSub)
    love.graphics.setFont(Fonts.small)
    for i,h in ipairs(headers) do
        love.graphics.print(h, margin+(i-1)*colW, headerY)
    end
    love.graphics.setColor(Colors.border)
    love.graphics.rectangle("fill", margin, TABLE_TOP-4, TW, 1)

    -- SCISSOR: zona scrollable
    local areaH = tableAreaH()
    love.graphics.setScissor(0, TABLE_TOP, WW, areaH)

    for i,t in ipairs(tutorias) do
        local ry     = TABLE_TOP + (i-1)*ROW_H - scrollY
        if ry+ROW_H < TABLE_TOP or ry > TABLE_TOP+areaH then goto continue end

        local _, alpha = Anim.staggerValue(stag, i)
        local nivel    = t.nivel_avance or "bajo"
        local sesNum   = t.sesiones     or 0
        local ausNum   = t.ausencias    or 0
        local ec       = eColor(t.estado)

        -- Fondo fila
        if t.alerta_avance_bajo then
            love.graphics.setColor(1, 0.97, 0.88, alpha)
        elseif hover[i] then
            love.graphics.setColor(0.95,0.95,1,alpha)
        elseif i%2==0 then
            love.graphics.setColor(Colors.bg[1],Colors.bg[2],Colors.bg[3],alpha)
        else
            love.graphics.setColor(Colors.card[1],Colors.card[2],Colors.card[3],alpha)
        end
        love.graphics.rectangle("fill", margin, ry, TW, ROW_H-8, 8)

        -- Borde izquierdo color estado
        love.graphics.setColor(ec[1],ec[2],ec[3],alpha)
        love.graphics.rectangle("fill", margin, ry, 4, ROW_H-8, 4)

        local c={}
        for j=0,7 do c[j+1]=margin+(j*colW) end

        love.graphics.setColor(Colors.text[1],Colors.text[2],Colors.text[3],alpha)
        love.graphics.setFont(Fonts.small)
        love.graphics.print(t.estudiante_nombre or "-", c[1]+8, ry+24)
        love.graphics.print(t.area              or "-", c[2]+4, ry+24)
        love.graphics.print(t.tutor_nombre      or "-", c[3]+4, ry+24)
        love.graphics.print(tostring(sesNum).." / 8",   c[4]+4, ry+24)

        local ac2 = nivel=="alto" and Colors.green or nivel=="medio" and Colors.orange or Colors.red
        love.graphics.setColor(ac2[1],ac2[2],ac2[3],alpha)
        love.graphics.print(string.upper(nivel), c[5]+4, ry+24)

        -- Badge estado
        local el  = t.estado or "activa"
        local etw = Fonts.small:getWidth(el)+14
        love.graphics.setColor(ec[1],ec[2],ec[3],0.15*alpha)
        love.graphics.rectangle("fill", c[6]+4, ry+16, etw, 22, 5)
        love.graphics.setColor(ec[1],ec[2],ec[3],alpha)
        love.graphics.print(el, c[6]+11, ry+22)

        -- Ausencias
        local ausColor = ausNum>=2 and Colors.red or (ausNum==1 and Colors.orange or Colors.textSub)
        love.graphics.setColor(ausColor[1],ausColor[2],ausColor[3],alpha)
        love.graphics.printf(tostring(ausNum), c[7], ry+24, colW-4, "center")
        if t.alerta_avance_bajo then
            love.graphics.setColor(Colors.orange[1],Colors.orange[2],Colors.orange[3],alpha)
            love.graphics.print("!", c[7]-16, ry+24)
        end

        -- Boton Detalle (rojo si necesita decision urgente)
        local needsDecision = (el=="activa_con_advertencia_formal") or (ausNum >= 2)
        local dtw = 64
        if needsDecision then
            love.graphics.setColor(Colors.red[1],Colors.red[2],Colors.red[3],0.18*alpha)
            love.graphics.rectangle("fill", c[8]+4, ry+16, dtw, 22, 5)
            love.graphics.setColor(Colors.red[1],Colors.red[2],Colors.red[3],alpha)
        else
            love.graphics.setColor(Colors.accentSoft[1],Colors.accentSoft[2],Colors.accentSoft[3],alpha)
            love.graphics.rectangle("fill", c[8]+4, ry+16, dtw, 22, 5)
            love.graphics.setColor(Colors.accent[1],Colors.accent[2],Colors.accent[3],alpha)
        end
        love.graphics.setFont(Fonts.small)
        love.graphics.printf("Detalle", c[8]+4, ry+22, dtw, "center")

        ::continue::
    end

    love.graphics.setScissor()

    -- SCROLLBAR
    local ms = maxScroll()
    if ms > 0 then
        local sbX  = WW - SB - 2
        local sbH  = areaH
        local barH = math.max(30, sbH * sbH / (ms + sbH))
        local barY = TABLE_TOP + (scrollY / ms) * (sbH - barH)
        love.graphics.setColor(Colors.border)
        love.graphics.rectangle("fill", sbX, TABLE_TOP, SB-4, sbH, 4)
        love.graphics.setColor(Colors.accent)
        love.graphics.rectangle("fill", sbX, barY, SB-4, barH, 4)
    end

    -- Boton Volver
    love.graphics.setColor(Colors.accent)
    love.graphics.rectangle("fill", 30, HH-58, 130, 42, 10)
    love.graphics.setColor(1,1,1)
    love.graphics.setFont(Fonts.body)
    love.graphics.printf("Volver", 30, HH-45, 130, "center")

    if detalle then drawModal(detalle) end
end

function Seg.mousepressed(x, y, btn)
    if btn ~= 1 then return end
    local WW, HH = W(), H()
    local SB     = 14
    local margin = 30
    local TW     = WW - margin*2 - SB
    local colW   = math.floor(TW/8)

    -- MODAL abierto
    if detalle then
        local mw, mh = 560, 460
        local mx2 = math.floor((WW-mw)/2)
        local my2 = math.floor((HH-mh)/2)
        local btnY = my2 + mh - 78
        local btnX = mx2 + 20
        local btnW = 148
        local gap  = 14

        -- Cerrar
        if x>=mx2+mw-168 and x<=mx2+mw-20 and y>=btnY and y<=btnY+38 then
            detalle=nil accionMsg="" accionOk=false
            Seg.load(params)
            return
        end

        local e = detalle.estado or ""
        local ausNum = detalle.ausencias or 0

        -- Decision formal
        if e=="activa_con_advertencia_formal" or ausNum>=2 then
            if x>=btnX and x<=btnX+btnW and y>=btnY and y<=btnY+38 then
                EventBus.publish(EventTypes.TUTORIA_CONTINUA, { tutoria_id=detalle.id, ausencias=ausNum })
                detalle.ausencias=0 detalle.advertencia_formal=false detalle.estado="activa"
                accionMsg="Tutoria continuada. Ausencias reseteadas a 0."
                accionOk=true
                return
            end
            if x>=btnX+btnW+gap and x<=btnX+btnW*2+gap and y>=btnY and y<=btnY+38 then
                EventBus.publish(EventTypes.TUTORIA_SUSPENDIDA, { tutoria_id=detalle.id })
                detalle.estado="suspendida"
                accionMsg="Tutoria suspendida correctamente."
                accionOk=true
                return
            end
        end

        -- Advertir
        if e=="activa_con_alerta" then
            if x>=btnX and x<=btnX+btnW and y>=btnY and y<=btnY+38 then
                local ok, msg = TutoriaRepo.resolverAusencias(detalle.id, "advertir")
                accionMsg=msg accionOk=ok
                if ok then detalle.estado="activa_con_advertencia" detalle.advertencia_formal=true end
                return
            end
            if x>=btnX+btnW+gap and x<=btnX+btnW*2+gap and y>=btnY and y<=btnY+38 then
                EventBus.publish(EventTypes.TUTORIA_SUSPENDIDA, { tutoria_id=detalle.id })
                detalle.estado="suspendida"
                accionMsg="Tutoria suspendida."
                accionOk=true
                return
            end
        end

        -- Cierre por abandono
        if e=="suspendida" then
            if x>=btnX and x<=btnX+btnW+20 and y>=btnY and y<=btnY+38 then
                local ok, msg = TutoriaRepo.cerrarPorAbandono(detalle.id)
                accionMsg=msg accionOk=ok
                if ok then detalle.estado="cerrada_por_abandono" end
                return
            end
        end

        -- Proponer cierre exitoso
        if not ESTADOS_FINALES[e] and e~="activa_con_alerta"
            and e~="activa_con_advertencia_formal" and e~="suspendida"
            and ausNum < 2 then
            if x>=btnX and x<=btnX+btnW+20 and y>=btnY and y<=btnY+38 then
                local ok, msg = TutoriaRepo.proponerCierre(detalle.id)
                accionMsg=msg accionOk=ok
                if ok then detalle.estado="cerrada_exitosamente" end
                return
            end
        end
        return
    end

    -- Volver
    if x>=30 and x<=160 and y>=HH-58 and y<=HH-16 then
        Nav.to("dashboard",{rol=params.rol,usuario_id=params.usuario_id,nombre=params.nombre},-1)
        return
    end

    -- Click fila -> abrir modal
    local areaH = tableAreaH()
    for i,t in ipairs(tutorias) do
        local ry  = TABLE_TOP + (i-1)*ROW_H - scrollY
        if ry+ROW_H < TABLE_TOP or ry > TABLE_TOP+areaH then goto skip end
        local c8  = margin + colW*7
        if x>=c8+4 and x<=c8+68 and y>=ry+16 and y<=ry+38 then
            detalle=t accionMsg="" accionOk=false
            return
        end
        ::skip::
    end
end

return Seg
