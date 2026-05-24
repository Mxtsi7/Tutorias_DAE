local Anim        = require("src.anim.Anim")
local TutoriaRepo = require("src.db.TutoriaRepo")
local DB          = require("src.db.DB")

local Seg = {}
local hover  = {} local stag = {} local params = {}
local tutorias = {} local nEspera = 0
local detalle  = nil  -- tutoria seleccionada para modal

local function W() return love.graphics.getWidth() end
local function H() return love.graphics.getHeight() end

local function enriquecer(t)
    -- nombre estudiante
    if not t.estudiante_nombre then
        local est = DB.find("estudiantes", function(e) return e.id == t.estudiante_id end)
        if est then
            local usr = DB.find("usuarios", function(u) return u.id == est.usuario_id end)
            t.estudiante_nombre = usr and usr.nombre or "\xe2\x80\x94"
        else
            t.estudiante_nombre = "\xe2\x80\x94"
        end
    end
    -- nombre tutor
    if not t.tutor_nombre and t.tutor_id then
        local usr2 = DB.find("usuarios", function(u)
            local tut = DB.find("tutores", function(tt) return tt.id == t.tutor_id end)
            return tut and u.id == tut.usuario_id
        end)
        t.tutor_nombre = usr2 and usr2.nombre or "\xe2\x80\x94"
    end
    return t
end

function Seg.load(p)
    params   = p or {}
    hover    = {}
    detalle  = nil
    local raw = TutoriaRepo.getAll()
    tutorias  = {}
    for _, t in ipairs(raw) do
        tutorias[#tutorias+1] = enriquecer(t)
    end
    -- KPI solicitudes en espera
    local sols = DB.where("solicitudes", function(s) return s.estado == "pendiente" end)
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

local function eColor(e)
    if e == "activa"           then return Colors.green
    elseif e == "activa_con_alerta" then return Colors.orange
    else return Colors.red end
end

local function drawModal(t)
    local WW, HH = W(), H()
    local mw, mh = 480, 340
    local mx = math.floor((WW-mw)/2)
    local my = math.floor((HH-mh)/2)

    love.graphics.setColor(0,0,0,0.45)
    love.graphics.rectangle("fill",0,0,WW,HH)
    love.graphics.setColor(Colors.card)
    love.graphics.rectangle("fill",mx,my,mw,mh,16)
    love.graphics.setColor(Colors.accent)
    love.graphics.rectangle("fill",mx,my,mw,58,16)
    love.graphics.rectangle("fill",mx,my+42,mw,16,0)
    love.graphics.setColor(1,1,1)
    love.graphics.setFont(Fonts.title)
    love.graphics.printf("Detalle de Tutor\xc3\xada",mx,my+16,mw,"center")

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
        {"Ausencias",   tostring(ausNum)},
        {"Nivel avance",string.upper(nivel)},
        {"Estado",      t.estado            or "\xe2\x80\x94"},
        {"Inicio",      t.fecha_inicio      or "\xe2\x80\x94"},
    }
    for i,row in ipairs(rows) do
        local ry = my+68+(i-1)*30
        love.graphics.setColor(Colors.textSub)
        love.graphics.setFont(Fonts.small)
        love.graphics.print(row[1],mx+24,ry)
        local vc = (row[1]=="Nivel avance" and ac)
                or (row[1]=="Estado"        and ec)
                or Colors.text
        love.graphics.setColor(vc)
        love.graphics.setFont(Fonts.body)
        love.graphics.print(row[2],mx+180,ry-2)
    end

    love.graphics.setColor(Colors.accent)
    love.graphics.rectangle("fill",mx+mw-140,my+mh-58,116,38,10)
    love.graphics.setColor(1,1,1)
    love.graphics.setFont(Fonts.body)
    love.graphics.printf("Cerrar",mx+mw-140,my+mh-45,116,"center")
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

    local nActivas, nAlertas = 0, 0
    for _,t in ipairs(tutorias) do
        if t.estado=="activa" or t.estado=="activa_con_alerta" then nActivas=nActivas+1 end
        if t.estado=="activa_con_alerta" or t.estado=="suspendida" then nAlertas=nAlertas+1 end
    end
    local kpis = {
        { label="Tutor\xc3\xadas Activas", value=nActivas, color=Colors.green },
        { label="Con Alertas",             value=nAlertas, color=Colors.orange },
        { label="Solicitudes en Espera",   value=nEspera,  color=Colors.textSub },
    }
    local kw = math.floor((WW-60)/3)
    for i,k in ipairs(kpis) do
        local kx = 30+(i-1)*(kw+10)
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
        love.graphics.print(h, margin+(i-1)*colW, 222)
    end
    love.graphics.setColor(Colors.border)
    love.graphics.rectangle("fill",margin,236,TW,1)

    for i,t in ipairs(tutorias) do
        local ry = 240+(i-1)*94
        local offY,alpha = Anim.staggerValue(stag,i)
        ry = ry+offY
        local nivel  = t.nivel_avance or "bajo"
        local sesNum = t.sesiones     or 0
        local ausNum = t.ausencias    or 0

        if hover[i] then love.graphics.setColor(0.95,0.95,1,alpha)
        elseif i%2==0 then love.graphics.setColor(Colors.bg[1],Colors.bg[2],Colors.bg[3],alpha)
        else love.graphics.setColor(Colors.card[1],Colors.card[2],Colors.card[3],alpha) end
        love.graphics.rectangle("fill",margin,ry,TW,82,8)

        local c1=margin        local c2=margin+colW   local c3=margin+colW*2
        local c4=margin+colW*3 local c5=margin+colW*4 local c6=margin+colW*5
        local c7=margin+colW*6 local c8=margin+colW*7

        love.graphics.setColor(Colors.text[1],Colors.text[2],Colors.text[3],alpha)
        love.graphics.setFont(Fonts.body)
        love.graphics.print(t.estudiante_nombre or "\xe2\x80\x94", c1+8, ry+26)
        love.graphics.print(t.area or "\xe2\x80\x94",              c2+4, ry+26)
        love.graphics.print(t.tutor_nombre or "\xe2\x80\x94",      c3+4, ry+26)
        love.graphics.print(tostring(sesNum).." / 8",              c4+4, ry+26)

        local ac = nivel=="alto" and Colors.green or nivel=="medio" and Colors.orange or Colors.red
        love.graphics.setColor(ac[1],ac[2],ac[3],alpha)
        love.graphics.setFont(Fonts.body)
        love.graphics.print(nivel, c5+4, ry+26)

        local sc  = eColor(t.estado)
        local el  = t.estado or "activa"
        local etw = Fonts.small:getWidth(el)+18
        love.graphics.setColor(sc[1],sc[2],sc[3],0.15*alpha)
        love.graphics.rectangle("fill",c6+4,ry+18,etw,26,6)
        love.graphics.setColor(sc[1],sc[2],sc[3],alpha)
        love.graphics.setFont(Fonts.small)
        love.graphics.print(el, c6+13, ry+24)

        love.graphics.setColor(ausNum>0 and Colors.red or Colors.textSub)
        love.graphics.setFont(Fonts.body)
        love.graphics.printf(tostring(ausNum), c7, ry+26, colW-4, "center")

        -- Boton Detalle funcional
        local dtw = Fonts.small:getWidth("Detalle")+18
        love.graphics.setColor(Colors.accentSoft[1],Colors.accentSoft[2],Colors.accentSoft[3],alpha)
        love.graphics.rectangle("fill",c8+4,ry+18,dtw,26,6)
        love.graphics.setColor(Colors.accent[1],Colors.accent[2],Colors.accent[3],alpha)
        love.graphics.setFont(Fonts.small)
        love.graphics.print("Detalle", c8+13, ry+24)
    end

    love.graphics.setColor(Colors.accent)
    love.graphics.rectangle("fill",margin,HH-64,130,44,10)
    love.graphics.setColor(1,1,1)
    love.graphics.setFont(Fonts.body)
    love.graphics.printf("Volver",margin,HH-50,130,"center")

    if detalle then drawModal(detalle) end
end

function Seg.mousepressed(x, y, btn)
    local WW, HH = W(), H()
    local margin = 30
    local TW     = WW - margin*2
    local colW   = math.floor(TW/8)

    -- Cerrar modal
    if detalle then
        local mw,mh = 480,340
        local mx2   = math.floor((WW-mw)/2)
        local my2   = math.floor((HH-mh)/2)
        if x>=mx2+mw-140 and x<=mx2+mw-24 and y>=my2+mh-58 and y<=my2+mh-20 then
            detalle = nil
        end
        return
    end

    -- Volver
    if x>=margin and x<=margin+130 and y>=HH-64 and y<=HH-20 then
        Nav.to("dashboard",{rol=params.rol,usuario_id=params.usuario_id,nombre=params.nombre},-1)
        return
    end

    -- Click en fila: boton Detalle
    for i,t in ipairs(tutorias) do
        local ry  = 240+(i-1)*94
        local c8  = margin+colW*7
        local dtw = Fonts.small:getWidth("Detalle")+18
        if x>=c8+4 and x<=c8+4+dtw and y>=ry+18 and y<=ry+44 then
            detalle = t
            return
        end
    end
end

return Seg
