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
local TABLE_TOP = 162
local FOOTER_H  = 72

-- Dropdown de Opciones
-- openMenu = { tutoria_idx, x, y, items[] }
-- items[]  = { label, color, action }
local openMenu = nil
local hovMenu  = {}
local MENU_ITW = 170
local MENU_IH  = 36

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

local ESTADOS_FINALES = {
    cerrada_exitosamente            = true,
    cerrada_por_abandono            = true,
    cerrada_por_abandono_voluntario = true,
}

-- Construye la lista de items del dropdown segun estado de la tutoria
local function buildMenuItems(t)
    local e      = t.estado  or "activa"
    local ausNum = t.ausencias or 0
    local items  = {}

    -- Siempre: Ver detalle
    items[#items+1] = {
        label  = "Ver detalle",
        color  = Colors.accent,
        action = "detalle",
    }

    if ESTADOS_FINALES[e] then
        -- sin acciones adicionales
        return items
    end

    if e == "activa_con_advertencia_formal" or ausNum >= 2 then
        items[#items+1] = { label="Continuar tutoria", color=Colors.green,  action="continuar" }
        items[#items+1] = { label="Suspender tutoria", color=Colors.red,    action="suspender" }

    elseif e == "activa_con_alerta" then
        items[#items+1] = { label="Emitir advertencia", color=Colors.orange, action="advertir"  }
        items[#items+1] = { label="Suspender tutoria",  color=Colors.red,    action="suspender" }

    elseif e == "suspendida" then
        items[#items+1] = { label="Cierre por abandono", color=Colors.red,  action="abandono"  }

    else
        -- activa, activa_con_advertencia, etc.
        items[#items+1] = { label="Proponer cierre", color=Colors.green, action="cierre" }
    end

    return items
end

function Seg.load(p)
    params    = p or {}
    hover     = {}
    detalle   = nil
    openMenu  = nil
    hovMenu   = {}
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
    local mx, my = love.mouse.getPosition()
    local areaH  = tableAreaH()

    -- hover filas (solo si no hay modal ni menu abierto)
    if not detalle and not openMenu then
        for i in ipairs(tutorias) do
            local ry = TABLE_TOP + (i-1)*ROW_H - scrollY
            hover[i] = mx>=30 and mx<=W()-18
                   and my >= math.max(TABLE_TOP, ry)
                   and my <= math.min(TABLE_TOP+areaH, ry+ROW_H-6)
        end
    end

    -- hover items del menu abierto
    if openMenu then
        hovMenu = {}
        for j, item in ipairs(openMenu.items) do
            local iy = openMenu.y + (j-1)*MENU_IH
            hovMenu[j] = mx>=openMenu.x and mx<=openMenu.x+MENU_ITW
                     and my>=iy and my<=iy+MENU_IH
        end
    end
end

function Seg.wheelmoved(x, y)
    if detalle or openMenu then return end
    scrollY = scrollY - y * 36
    clampScroll()
end

local function eColor(e)
    if     e=="activa"                           then return Colors.green
    elseif e=="activa_con_alerta"                then return Colors.orange
    elseif e=="activa_con_advertencia_formal"    then return {0.9,0.45,0.1}
    elseif e=="activa_con_advertencia"           then return {0.9,0.55,0.1}
    elseif e=="suspendida"                       then return Colors.red
    elseif e=="pendiente_reasignacion"           then return {0.5,0.3,0.9}
    elseif e=="cerrada_exitosamente"             then return {0.3,0.7,0.4}
    elseif e=="cerrada_por_abandono"             then return {0.5,0.5,0.5}
    elseif e=="cerrada_por_abandono_voluntario" then return {0.6,0.6,0.6}
    else return Colors.textSub end
end

-- Ejecuta la accion seleccionada del menu
local function executeAction(action, t)
    local ausNum = t.ausencias or 0
    if action == "detalle" then
        detalle   = t
        accionMsg = ""
        accionOk  = false

    elseif action == "continuar" then
        EventBus.publish(EventTypes.TUTORIA_CONTINUA, { tutoria_id=t.id, ausencias=ausNum })
        t.ausencias=0 t.advertencia_formal=false t.estado="activa"
        NotificationManager.push("Tutoria continuada. Ausencias reseteadas.", "success")

    elseif action == "suspender" then
        EventBus.publish(EventTypes.TUTORIA_SUSPENDIDA, { tutoria_id=t.id })
        t.estado="suspendida"
        NotificationManager.push("Tutoria suspendida.", "warning")

    elseif action == "advertir" then
        local ok, msg = TutoriaRepo.resolverAusencias(t.id, "advertir")
        if ok then
            t.estado="activa_con_advertencia"
            t.advertencia_formal=true
            NotificationManager.push("Advertencia formal emitida.", "warning")
        else
            NotificationManager.push(msg or "Error al advertir.", "error")
        end

    elseif action == "abandono" then
        local ok, msg = TutoriaRepo.cerrarPorAbandono(t.id)
        if ok then
            t.estado="cerrada_por_abandono"
            NotificationManager.push("Tutoria cerrada por abandono.", "success")
        else
            NotificationManager.push(msg or "Error al cerrar.", "error")
        end

    elseif action == "cierre" then
        local ok, msg = TutoriaRepo.proponerCierre(t.id)
        if ok then
            t.estado="cerrada_exitosamente"
            NotificationManager.push("Cierre exitoso propuesto.", "success")
        else
            NotificationManager.push(msg or "Error al proponer cierre.", "error")
        end
    end
end

-- ---- MODAL (solo para Ver detalle) ----
local function drawModal(t)
    local WW, HH = W(), H()
    local mw, mh = 560, 420
    local mx = math.floor((WW-mw)/2)
    local my = math.floor((HH-mh)/2)

    love.graphics.setColor(0,0,0,0.5)
    love.graphics.rectangle("fill",0,0,WW,HH)
    love.graphics.setColor(Colors.card)
    love.graphics.rectangle("fill",mx,my,mw,mh,16)
    love.graphics.setColor(Colors.accent)
    love.graphics.rectangle("fill",mx,my,mw,58,16)
    love.graphics.rectangle("fill",mx,my+42,mw,16,0)
    love.graphics.setColor(1,1,1)
    love.graphics.setFont(Fonts.title)
    love.graphics.printf("Detalle de Tutoria",mx,my+17,mw,"center")

    local nivel  = t.nivel_avance or "bajo"
    local sesNum = t.sesiones     or 0
    local ausNum = t.ausencias    or 0
    local ac     = nivel=="alto" and Colors.green or nivel=="medio" and Colors.orange or Colors.red
    local ec     = eColor(t.estado)

    local rows = {
        { "Estudiante",        t.estudiante_nombre or "-" },
        { "Tutor",             t.tutor_nombre      or "-" },
        { "Area",              t.area              or "-" },
        { "Sesiones",          tostring(sesNum).." / 8" },
        { "Ausencias consec.", tostring(ausNum) },
        { "Nivel avance",      string.upper(nivel) },
        { "Estado",            t.estado or "-" },
        { "Advertencia",       t.advertencia_formal and "Si" or "No" },
        { "Alerta avance",     t.alerta_avance_bajo and "Reunion requerida" or "Sin alerta" },
    }
    for i, row in ipairs(rows) do
        local ry2 = my+66+(i-1)*28
        love.graphics.setColor(Colors.textSub)
        love.graphics.setFont(Fonts.small)
        love.graphics.print(row[1], mx+24, ry2)
        local vc = (row[1]=="Nivel avance" and ac)
                or (row[1]=="Estado"        and ec)
                or (row[1]=="Alerta avance" and t.alerta_avance_bajo and Colors.orange)
                or Colors.text
        love.graphics.setColor(vc)
        love.graphics.print(row[2], mx+230, ry2)
    end

    -- Boton cerrar centrado
    local btnY = my+mh-62
    love.graphics.setColor(Colors.border)
    love.graphics.rectangle("fill", mx+mw/2-80, btnY, 160, 40, 10)
    love.graphics.setColor(Colors.text)
    love.graphics.setFont(Fonts.body)
    love.graphics.printf("Cerrar", mx+mw/2-80, btnY+11, 160, "center")
end

-- ---- DROPDOWN MENU ----
local function drawDropdown()
    if not openMenu then return end
    local totalH = #openMenu.items * MENU_IH
    local mx2    = openMenu.x
    local my2    = openMenu.y

    -- Sombra
    love.graphics.setColor(0,0,0,0.12)
    love.graphics.rectangle("fill", mx2+3, my2+4, MENU_ITW, totalH, 10)
    -- Fondo panel
    love.graphics.setColor(Colors.card)
    love.graphics.rectangle("fill", mx2, my2, MENU_ITW, totalH, 10)
    -- Borde
    love.graphics.setColor(Colors.border)
    love.graphics.rectangle("line", mx2, my2, MENU_ITW, totalH, 10)

    for j, item in ipairs(openMenu.items) do
        local iy = my2 + (j-1)*MENU_IH
        -- Hover highlight
        if hovMenu[j] then
            love.graphics.setColor(item.color[1],item.color[2],item.color[3],0.10)
            love.graphics.rectangle("fill", mx2+2, iy+2, MENU_ITW-4, MENU_IH-4, 8)
        end
        -- Punto de color
        love.graphics.setColor(item.color)
        love.graphics.circle("fill", mx2+16, iy+MENU_IH/2, 4)
        -- Texto
        love.graphics.setColor(Colors.text)
        love.graphics.setFont(Fonts.small)
        love.graphics.print(item.label, mx2+28, iy+12)
        -- Separador (excepto ultimo)
        if j < #openMenu.items then
            love.graphics.setColor(Colors.border)
            love.graphics.rectangle("fill", mx2+8, iy+MENU_IH-1, MENU_ITW-16, 1)
        end
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
            or e=="activa_con_advertencia" or e=="activa_con_advertencia_formal" then nActivas=nActivas+1 end
        if e=="activa_con_alerta" or e=="suspendida"
            or e=="activa_con_advertencia" or e=="activa_con_advertencia_formal" then nAlertas=nAlertas+1 end
        if ESTADOS_FINALES[e] then nCerradas=nCerradas+1 end
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

    -- Cabecera tabla FIJA
    local SB     = 14
    local margin = 30
    local TW     = WW - margin*2 - SB
    -- 9 columnas: las 7 de datos + Detalle + Opciones
    local colW   = math.floor(TW/9)
    local headers = {"Estudiante","Area","Tutor","Sesiones","Avance","Estado","Ausencias","Detalle","Opciones"}
    local headerY = TABLE_TOP - 20
    love.graphics.setColor(Colors.textSub)
    love.graphics.setFont(Fonts.small)
    for i,h in ipairs(headers) do
        love.graphics.print(h, margin+(i-1)*colW, headerY)
    end
    love.graphics.setColor(Colors.border)
    love.graphics.rectangle("fill", margin, TABLE_TOP-4, TW, 1)

    -- Zona scrollable
    local areaH = tableAreaH()
    love.graphics.setScissor(0, TABLE_TOP, WW, areaH)

    for i,t in ipairs(tutorias) do
        local ry = TABLE_TOP + (i-1)*ROW_H - scrollY
        if ry+ROW_H < TABLE_TOP or ry > TABLE_TOP+areaH then goto continue end

        local _, alpha = Anim.staggerValue(stag, i)
        local nivel    = t.nivel_avance or "bajo"
        local sesNum   = t.sesiones     or 0
        local ausNum   = t.ausencias    or 0
        local ec       = eColor(t.estado)
        local el       = t.estado or "activa"
        local needsDec = (el=="activa_con_advertencia_formal") or (ausNum >= 2)

        -- Fondo fila
        if t.alerta_avance_bajo then
            love.graphics.setColor(1,0.97,0.88,alpha)
        elseif hover[i] then
            love.graphics.setColor(0.95,0.95,1,alpha)
        elseif i%2==0 then
            love.graphics.setColor(Colors.bg[1],Colors.bg[2],Colors.bg[3],alpha)
        else
            love.graphics.setColor(Colors.card[1],Colors.card[2],Colors.card[3],alpha)
        end
        love.graphics.rectangle("fill", margin, ry, TW, ROW_H-8, 8)

        -- Borde estado
        love.graphics.setColor(ec[1],ec[2],ec[3],alpha)
        love.graphics.rectangle("fill", margin, ry, 4, ROW_H-8, 4)

        -- Columnas de datos (c[1]..c[7])
        local c = {}
        for j=0,8 do c[j+1] = margin + j*colW end

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

        -- ---- Boton DETALLE (col 8) ----
        local dtw = colW - 12
        love.graphics.setColor(Colors.accentSoft[1],Colors.accentSoft[2],Colors.accentSoft[3],alpha)
        love.graphics.rectangle("fill", c[8]+4, ry+18, dtw, 24, 6)
        love.graphics.setColor(Colors.accent[1],Colors.accent[2],Colors.accent[3],alpha)
        love.graphics.setFont(Fonts.small)
        love.graphics.printf("Detalle", c[8]+4, ry+24, dtw, "center")

        -- ---- Boton OPCIONES (col 9) ----
        local otw = colW - 12
        -- color segun urgencia
        if needsDec then
            love.graphics.setColor(Colors.red[1],Colors.red[2],Colors.red[3],0.18*alpha)
            love.graphics.rectangle("fill", c[9]+4, ry+18, otw, 24, 6)
            love.graphics.setColor(Colors.red[1],Colors.red[2],Colors.red[3],alpha)
        else
            love.graphics.setColor(Colors.orange[1],Colors.orange[2],Colors.orange[3],0.15*alpha)
            love.graphics.rectangle("fill", c[9]+4, ry+18, otw, 24, 6)
            love.graphics.setColor(Colors.orange[1],Colors.orange[2],Colors.orange[3],alpha)
        end
        love.graphics.setFont(Fonts.small)
        love.graphics.printf("Opciones v", c[9]+4, ry+24, otw, "center")

        ::continue::
    end

    love.graphics.setScissor()

    -- Scrollbar
    local ms = maxScroll()
    if ms > 0 then
        local sbX  = WW - SB - 2
        local sbH  = areaH
        local barH = math.max(30, sbH*sbH/(ms+sbH))
        local barY = TABLE_TOP + (scrollY/ms)*(sbH-barH)
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

    -- Modal (sobre todo)
    if detalle then drawModal(detalle) end

    -- Dropdown (sobre todo, incluso modal cerrado)
    if openMenu then drawDropdown() end
end

function Seg.mousepressed(x, y, btn)
    if btn ~= 1 then return end
    local WW, HH = W(), H()
    local SB     = 14
    local margin = 30
    local TW     = WW - margin*2 - SB
    local colW   = math.floor(TW/9)

    -- ---- Cerrar modal ----
    if detalle then
        local mw, mh = 560, 420
        local mx2 = math.floor((WW-mw)/2)
        local my2 = math.floor((HH-mh)/2)
        local btnY = my2+mh-62
        if x>=mx2+mw/2-80 and x<=mx2+mw/2+80 and y>=btnY and y<=btnY+40 then
            detalle=nil accionMsg="" accionOk=false
            return
        end
        -- click fuera del modal -> cerrar
        if x<mx2 or x>mx2+mw or y<my2 or y>my2+mh then
            detalle=nil accionMsg="" accionOk=false
        end
        return
    end

    -- ---- Click sobre dropdown abierto ----
    if openMenu then
        local hit = false
        for j, item in ipairs(openMenu.items) do
            local iy = openMenu.y + (j-1)*MENU_IH
            if x>=openMenu.x and x<=openMenu.x+MENU_ITW
               and y>=iy and y<=iy+MENU_IH then
                local t = tutorias[openMenu.idx]
                openMenu = nil hovMenu = {}
                executeAction(item.action, t)
                hit = true
                break
            end
        end
        -- click fuera -> solo cerrar
        openMenu = nil hovMenu = {}
        return
    end

    -- ---- Volver ----
    if x>=30 and x<=160 and y>=HH-58 and y<=HH-16 then
        Nav.to("dashboard",{rol=params.rol,usuario_id=params.usuario_id,nombre=params.nombre},-1)
        return
    end

    -- ---- Clicks en filas ----
    local areaH = tableAreaH()
    for i,t in ipairs(tutorias) do
        local ry = TABLE_TOP + (i-1)*ROW_H - scrollY
        if ry+ROW_H < TABLE_TOP or ry > TABLE_TOP+areaH then goto skip end

        local c8 = margin + 7*colW   -- inicio col Detalle
        local c9 = margin + 8*colW   -- inicio col Opciones
        local dtw = colW - 12
        local otw = colW - 12

        -- Boton Detalle
        if x>=c8+4 and x<=c8+4+dtw and y>=ry+18 and y<=ry+42 then
            detalle=t accionMsg="" accionOk=false
            openMenu=nil
            return
        end

        -- Boton Opciones -> abrir dropdown
        if x>=c9+4 and x<=c9+4+otw and y>=ry+18 and y<=ry+42 then
            -- Calcular posicion del menu (ajustar si se sale de pantalla)
            local mx3 = c9 + 4
            local my3 = ry + 44 - scrollY  -- debajo del boton
            -- No usamos scrollY aqui porque ry ya lo descuenta
            local my3r = TABLE_TOP + (i-1)*ROW_H - scrollY + 44
            local totalMenuH = #buildMenuItems(t) * MENU_IH
            if my3r + totalMenuH > HH - FOOTER_H then
                my3r = TABLE_TOP + (i-1)*ROW_H - scrollY - totalMenuH - 4
            end
            if mx3 + MENU_ITW > WW - SB - 4 then
                mx3 = WW - SB - 4 - MENU_ITW
            end
            openMenu = {
                idx   = i,
                x     = mx3,
                y     = my3r,
                items = buildMenuItems(t),
            }
            hovMenu = {}
            return
        end

        ::skip::
    end
end

return Seg
