local Anim        = require("src.anim.Anim")
local TutoriaRepo = require("src.db.TutoriaRepo")
local DB          = require("src.db.DB")

local Seg = {}
local hover    = {} local stag = {} local params = {}
local tutorias = {} local nEspera = 0
local detalle  = nil  -- tutoria seleccionada para modal
local accionMsg = ""
local accionOk  = false

local function W() return love.graphics.getWidth() end
local function H() return love.graphics.getHeight() end

local function enriquecer(t)
    if not t.estudiante_nombre then
        local est = DB.find("estudiantes", function(e) return e.id == t.estudiante_id end)
        if est then
            local usr = DB.find("usuarios", function(u) return u.id == est.usuario_id end)
            t.estudiante_nombre = usr and usr.nombre or "\xe2\x80\x94"
        else
            t.estudiante_nombre = "\xe2\x80\x94"
        end
    end
    if not t.tutor_nombre and t.tutor_id then
        local tut = DB.find("tutores", function(tt) return tt.id == t.tutor_id end)
        if tut then
            local usr2 = DB.find("usuarios", function(u) return u.id == tut.usuario_id end)
            t.tutor_nombre = usr2 and usr2.nombre or "\xe2\x80\x94"
        end
    end
    return t
end

function Seg.load(p)
    params     = p or {}
    hover      = {}
    detalle    = nil
    accionMsg  = ""
    accionOk   = false
    local raw  = TutoriaRepo.getAll()
    tutorias   = {}
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
    for i in ipairs(tutorias) do
        local ry = 240 + (i-1)*94
        hover[i] = mx>=30 and mx<=W()-30 and my>=ry and my<=ry+82
    end
end

-- Colores por estado (todos los estados del MPN)
local function eColor(e)
    if e == "activa"                        then return Colors.green
    elseif e == "activa_con_alerta"         then return Colors.orange
    elseif e == "activa_con_advertencia"    then return {0.9, 0.55, 0.1}
    elseif e == "suspendida"                then return Colors.red
    elseif e == "pendiente_reasignacion"    then return {0.5, 0.3, 0.9}
    elseif e == "cerrada_exitosamente"      then return {0.3, 0.7, 0.4}
    elseif e == "cerrada_por_abandono"      then return {0.5, 0.5, 0.5}
    elseif e == "cerrada_por_abandono_voluntario" then return {0.6, 0.6, 0.6}
    else return Colors.textSub end
end

-- Modal con ACCIONES del Coordinador segun estado
local function drawModal(t)
    local WW, HH = W(), H()
    local mw, mh = 520, 400
    local mx = math.floor((WW-mw)/2)
    local my = math.floor((HH-mh)/2)

    love.graphics.setColor(0,0,0,0.45)
    love.graphics.rectangle("fill",0,0,WW,HH)
    love.graphics.setColor(Colors.card)
    love.graphics.rectangle("fill",mx,my,mw,mh,16)
    love.graphics.setColor(Colors.accent)
    love.graphics.rectangle("fill",mx,my,mw,60,16)
    love.graphics.rectangle("fill",mx,my+44,mw,16,0)
    love.graphics.setColor(1,1,1)
    love.graphics.setFont(Fonts.title)
    love.graphics.printf("Detalle de Tutor\xc3\xada",mx,my+18,mw,"center")

    local nivel  = t.nivel_avance or "bajo"
    local sesNum = t.sesiones     or 0
    local ausNum = t.ausencias    or 0
    local ac     = nivel=="alto" and Colors.green or nivel=="medio" and Colors.orange or Colors.red
    local ec     = eColor(t.estado)

    local rows = {
        {"Estudiante",  t.estudiante_nombre or "\xe2\x80\x94"},
        {"Tutor",       t.tutor_nombre      or "\xe2\x80\x94"},
        {"\xc3\x81rea", t.area              or "\xe2\x80\x94"},
        {"Sesiones",    sesNum.." / 8"},
        {"Ausencias consec.", tostring(ausNum)},
        {"Nivel avance",string.upper(nivel)},
        {"Estado",      t.estado            or "\xe2\x80\x94"},
        {"Advertencia", t.advertencia_formal and "S\xc3\xad" or "No"},
        {"Alerta avance bajo", t.alerta_avance_bajo and "\xe2\x9a\xa0 Reunion requerida" or "Sin alerta"},
    }
    for i,row in ipairs(rows) do
        local ry = my+68+(i-1)*28
        love.graphics.setColor(Colors.textSub)
        love.graphics.setFont(Fonts.small)
        love.graphics.print(row[1],mx+24,ry)
        local vc = (row[1]=="Nivel avance" and ac)
                or (row[1]=="Estado"        and ec)
                or (row[1]=="Alerta avance bajo" and t.alerta_avance_bajo and Colors.orange)
                or Colors.text
        love.graphics.setColor(vc)
        love.graphics.setFont(Fonts.small)
        love.graphics.print(row[2],mx+210,ry)
    end

    -- ACCIONES disponibles segun estado
    local btnX = mx+20
    local btnY = my+mh-72
    local btnW = 140
    local btnH = 36

    -- Siempre: Cerrar modal
    love.graphics.setColor(Colors.border)
    love.graphics.rectangle("fill",mx+mw-160,btnY,140,btnH,10)
    love.graphics.setColor(Colors.text)
    love.graphics.setFont(Fonts.small)
    love.graphics.printf("Cerrar",mx+mw-160,btnY+10,140,"center")

    -- Accion segun estado
    if t.estado == "activa_con_alerta" then
        -- Advertir o Suspender
        love.graphics.setColor(Colors.orange)
        love.graphics.rectangle("fill",btnX,btnY,btnW,btnH,10)
        love.graphics.setColor(1,1,1)
        love.graphics.printf("Advertir",btnX,btnY+10,btnW,"center")

        love.graphics.setColor(Colors.red)
        love.graphics.rectangle("fill",btnX+btnW+14,btnY,btnW,btnH,10)
        love.graphics.setColor(1,1,1)
        love.graphics.printf("Suspender",btnX+btnW+14,btnY+10,btnW,"center")
    elseif t.estado == "suspendida" then
        -- Cerrar por abandono
        love.graphics.setColor(Colors.red)
        love.graphics.rectangle("fill",btnX,btnY,btnW+20,btnH,10)
        love.graphics.setColor(1,1,1)
        love.graphics.printf("Cierre por abandono",btnX,btnY+10,btnW+20,"center")
    elseif t.estado == "activa" or t.estado == "activa_con_advertencia" then
        -- Proponer cierre exitoso
        love.graphics.setColor(Colors.green)
        love.graphics.rectangle("fill",btnX,btnY,btnW+20,btnH,10)
        love.graphics.setColor(1,1,1)
        love.graphics.printf("Proponer cierre",btnX,btnY+10,btnW+20,"center")
    end

    -- Mostrar resultado de accion
    if accionMsg ~= "" then
        local mc = accionOk and Colors.greenSoft or {0.99, 0.94, 0.94}
        local tc = accionOk and Colors.green or Colors.red
        love.graphics.setColor(mc)
        love.graphics.rectangle("fill",mx+20,btnY-46,mw-40,34,8)
        love.graphics.setColor(tc)
        love.graphics.setFont(Fonts.small)
        love.graphics.printf(accionMsg,mx+20,btnY-36,mw-40,"center")
    end
end

function Seg.draw()
    local WW, HH = W(), H()
    love.graphics.setColor(Colors.bg)
    love.graphics.rectangle("fill",0,0,WW,HH)

    love.graphics.setColor(Colors.accent)
    love.graphics.rectangle("fill",0,0,WW,68)
    love.graphics.setColor(1,1,1)
    love.graphics.setFont(Fonts.title)
    love.graphics.printf("Seguimiento Semanal \xe2\x80\x94 Coordinador",0,22,WW,"center")

    local nActivas, nAlertas, nCerradas = 0, 0, 0
    for _,t in ipairs(tutorias) do
        if t.estado=="activa" or t.estado=="activa_con_alerta" or t.estado=="activa_con_advertencia" then
            nActivas=nActivas+1
        end
        if t.estado=="activa_con_alerta" or t.estado=="suspendida" or t.estado=="activa_con_advertencia" then
            nAlertas=nAlertas+1
        end
        if t.estado=="cerrada_exitosamente" or t.estado=="cerrada_por_abandono" or t.estado=="cerrada_por_abandono_voluntario" then
            nCerradas=nCerradas+1
        end
    end
    local kpis = {
        { label="Tutor\xc3\xadas Activas", value=nActivas,  color=Colors.green },
        { label="Con Alertas",             value=nAlertas,  color=Colors.orange },
        { label="Solicitudes en Espera",   value=nEspera,   color=Colors.textSub },
        { label="Cerradas",                value=nCerradas, color={0.5,0.5,0.5} },
    }
    local kw = math.floor((WW-70)/4)
    for i,k in ipairs(kpis) do
        local kx = 30+(i-1)*(kw+8)
        love.graphics.setColor(Colors.card)
        love.graphics.rectangle("fill",kx,78,kw,72,12)
        love.graphics.setColor(k.color)
        love.graphics.rectangle("fill",kx,78,5,72,4)
        love.graphics.setColor(Colors.text)
        love.graphics.setFont(Fonts.big)
        love.graphics.print(tostring(k.value),kx+18,84)
        love.graphics.setColor(Colors.textSub)
        love.graphics.setFont(Fonts.small)
        love.graphics.print(k.label,kx+18,122)
    end

    local margin=30 local TW=WW-margin*2 local colW=math.floor(TW/8)
    local headers={"Estudiante","\xc3\x81rea","Tutor","Sesiones","Avance","Estado","Ausencias","Acci\xc3\xb3n"}
    love.graphics.setColor(Colors.textSub)
    love.graphics.setFont(Fonts.small)
    for i,h in ipairs(headers) do
        love.graphics.print(h, margin+(i-1)*colW, 216)
    end
    love.graphics.setColor(Colors.border)
    love.graphics.rectangle("fill",margin,230,TW,1)

    for i,t in ipairs(tutorias) do
        local ry = 234+(i-1)*88
        local offY,alpha = Anim.staggerValue(stag,i)
        ry = ry+offY
        local nivel  = t.nivel_avance or "bajo"
        local sesNum = t.sesiones     or 0
        local ausNum = t.ausencias    or 0

        -- Resaltar filas con alertas
        if t.alerta_avance_bajo then
            love.graphics.setColor(1, 0.97, 0.88, alpha)
        elseif hover[i] then
            love.graphics.setColor(0.95,0.95,1,alpha)
        elseif i%2==0 then
            love.graphics.setColor(Colors.bg[1],Colors.bg[2],Colors.bg[3],alpha)
        else
            love.graphics.setColor(Colors.card[1],Colors.card[2],Colors.card[3],alpha)
        end
        love.graphics.rectangle("fill",margin,ry,TW,80,8)

        -- Borde izquierdo de color segun estado
        local ec = eColor(t.estado)
        love.graphics.setColor(ec[1],ec[2],ec[3],alpha)
        love.graphics.rectangle("fill",margin,ry,4,80,4)

        local c1=margin+8   local c2=margin+colW   local c3=margin+colW*2
        local c4=margin+colW*3 local c5=margin+colW*4 local c6=margin+colW*5
        local c7=margin+colW*6 local c8=margin+colW*7

        love.graphics.setColor(Colors.text[1],Colors.text[2],Colors.text[3],alpha)
        love.graphics.setFont(Fonts.small)
        love.graphics.print(t.estudiante_nombre or "\xe2\x80\x94", c1, ry+22)
        love.graphics.print(t.area or "\xe2\x80\x94",              c2+4, ry+22)
        love.graphics.print(t.tutor_nombre or "\xe2\x80\x94",      c3+4, ry+22)
        love.graphics.print(tostring(sesNum).." / 8",              c4+4, ry+22)

        local ac2 = nivel=="alto" and Colors.green or nivel=="medio" and Colors.orange or Colors.red
        love.graphics.setColor(ac2[1],ac2[2],ac2[3],alpha)
        love.graphics.print(string.upper(nivel), c5+4, ry+22)

        -- Badge estado
        local el  = t.estado or "activa"
        local etw = Fonts.small:getWidth(el)+14
        love.graphics.setColor(ec[1],ec[2],ec[3],0.15*alpha)
        love.graphics.rectangle("fill",c6+4,ry+14,etw,22,5)
        love.graphics.setColor(ec[1],ec[2],ec[3],alpha)
        love.graphics.setFont(Fonts.small)
        love.graphics.print(el, c6+11, ry+20)

        -- Ausencias
        local ausColor = ausNum >= 2 and Colors.red or (ausNum == 1 and Colors.orange or Colors.textSub)
        love.graphics.setColor(ausColor[1],ausColor[2],ausColor[3],alpha)
        love.graphics.printf(tostring(ausNum), c7, ry+22, colW-4, "center")

        -- Icono alerta avance bajo
        if t.alerta_avance_bajo then
            love.graphics.setColor(Colors.orange[1],Colors.orange[2],Colors.orange[3],alpha)
            love.graphics.setFont(Fonts.small)
            love.graphics.print("\xe2\x9a\xa0", c7-18, ry+22)
        end

        -- Boton Detalle/Accion
        local dtw = Fonts.small:getWidth("Detalle")+18
        love.graphics.setColor(Colors.accentSoft[1],Colors.accentSoft[2],Colors.accentSoft[3],alpha)
        love.graphics.rectangle("fill",c8+4,ry+14,dtw,22,5)
        love.graphics.setColor(Colors.accent[1],Colors.accent[2],Colors.accent[3],alpha)
        love.graphics.setFont(Fonts.small)
        love.graphics.print("Detalle", c8+11, ry+20)
    end

    love.graphics.setColor(Colors.accent)
    love.graphics.rectangle("fill",30,HH-60,130,42,10)
    love.graphics.setColor(1,1,1)
    love.graphics.setFont(Fonts.body)
    love.graphics.printf("Volver",30,HH-47,130,"center")

    if detalle then drawModal(detalle) end
end

function Seg.mousepressed(x, y, btn)
    local WW, HH = W(), H()
    local margin  = 30
    local TW      = WW - margin*2
    local colW    = math.floor(TW/8)

    -- Interaccion con modal abierto
    if detalle then
        local mw, mh = 520, 400
        local mx2 = math.floor((WW-mw)/2)
        local my2 = math.floor((HH-mh)/2)
        local btnY = my2+mh-72
        local btnX = mx2+20
        local btnW = 140

        -- Cerrar modal
        if x>=mx2+mw-160 and x<=mx2+mw-20 and y>=btnY and y<=btnY+36 then
            detalle = nil accionMsg = "" accionOk = false
            Seg.load(params)  -- recargar para reflejar cambios
            return
        end

        -- Advertir
        if detalle.estado == "activa_con_alerta" then
            if x>=btnX and x<=btnX+btnW and y>=btnY and y<=btnY+36 then
                local ok, msg = TutoriaRepo.resolverAusencias(detalle.id, "advertir")
                accionMsg = msg accionOk = ok
                if ok then detalle.estado = "activa_con_advertencia" detalle.advertencia_formal = true end
                return
            end
            if x>=btnX+btnW+14 and x<=btnX+btnW*2+14 and y>=btnY and y<=btnY+36 then
                local ok, msg = TutoriaRepo.resolverAusencias(detalle.id, "suspender")
                accionMsg = msg accionOk = ok
                if ok then detalle.estado = "suspendida" end
                return
            end
        end

        -- Cierre por abandono (estado suspendida)
        if detalle.estado == "suspendida" then
            if x>=btnX and x<=btnX+btnW+20 and y>=btnY and y<=btnY+36 then
                local ok, msg = TutoriaRepo.cerrarPorAbandono(detalle.id)
                accionMsg = msg accionOk = ok
                if ok then detalle.estado = "cerrada_por_abandono" end
                return
            end
        end

        -- Proponer cierre exitoso
        if detalle.estado == "activa" or detalle.estado == "activa_con_advertencia" then
            if x>=btnX and x<=btnX+btnW+20 and y>=btnY and y<=btnY+36 then
                local ok, msg = TutoriaRepo.proponerCierre(detalle.id)
                accionMsg = msg accionOk = ok
                if ok then detalle.estado = "cerrada_exitosamente" end
                return
            end
        end
        return
    end

    -- Volver
    if x>=margin and x<=margin+130 and y>=HH-60 and y<=HH-18 then
        Nav.to("dashboard",{rol=params.rol,usuario_id=params.usuario_id,nombre=params.nombre},-1)
        return
    end

    -- Click fila: abrir modal
    for i,t in ipairs(tutorias) do
        local ry  = 234+(i-1)*88
        local c8  = margin+colW*7
        local dtw = Fonts.small:getWidth("Detalle")+18
        if x>=c8+4 and x<=c8+4+dtw and y>=ry+14 and y<=ry+36 then
            detalle   = t
            accionMsg = ""
            accionOk  = false
            return
        end
    end
end

return Seg
