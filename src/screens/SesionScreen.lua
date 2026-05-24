local Anim        = require("src.anim.Anim")
local SesionRepo  = require("src.db.SesionRepo")
local TutoriaRepo = require("src.db.TutoriaRepo")
local Session     = require("src.session.Session")

local SS = {}
local oAvance = {"bajo","medio","alto"}
local oAsist  = {"Asistio","Ausencia just.","Ausencia injust."}
local campos  = {
    { label="Fecha de sesi\xc3\xb3n", value="", placeholder="Ej: 2026-05-22" },
    { label="Duraci\xc3\xb3n (min)",  value="", placeholder="Ej: 60" },
    { label="Temas tratados",          value="", placeholder="Describe los temas" },
}
local avSel=1 local asistSel=1 local campoA=1
local guardado=false local fadeIn=nil local params={}
local tutorias={} local tutoriaSel=1
local historial={} local scrollY=0

local MODO_FORM  = "nueva"
local MODO_LISTA = "lista"

local PW=500 local PY=40
local function W() return love.graphics.getWidth() end
local function H() return love.graphics.getHeight() end
local function PX() return math.floor((W()-PW)/2) end

function SS.load(p)
    params   = p or {}
    guardado = false
    campoA   = 1
    avSel    = 1
    asistSel = 1
    scrollY  = 0
    for _,c in ipairs(campos) do c.value="" end
    campos[1].value = os.date("%Y-%m-%d")

    local rol      = Session.rol or params.rol or "estudiante"
    local uid      = Session.usuario_id or params.usuario_id
    local modo     = params.modo or MODO_LISTA

    if modo == MODO_FORM then
        -- Solo las tutorias del tutor logueado
        if rol == "tutor" and uid then
            tutorias = TutoriaRepo.getByTutor(uid)
        else
            tutorias = TutoriaRepo.getAll()
        end
        tutoriaSel = 1
        historial  = {}
    elseif rol == "tutor" then
        historial = SesionRepo.getByTutor(uid or 1)
        tutorias  = {}
    else
        local ts = TutoriaRepo.getByEstudiante(uid or 1)
        historial = {}
        for _,t in ipairs(ts) do
            local ses = SesionRepo.getByTutoria(t.id)
            for _,s in ipairs(ses) do
                s._area  = t.area or "\xe2\x80\x94"
                s._tutor = t.tutor_nombre or "\xe2\x80\x94"
                historial[#historial+1] = s
            end
        end
        table.sort(historial, function(a,b) return (a.fecha or "") > (b.fecha or "") end)
    end
    fadeIn = Anim.new(0,1,0.4,"easeOut")
end

function SS.update(dt) fadeIn:update(dt) end

-- === FORMULARIO (tutor, modo nueva) ===
local function drawForm(a)
    local px = PX()
    local ph = 74 + #campos*110 + 230

    love.graphics.setColor(0.08,0.08,0.14,0.45*a)
    love.graphics.rectangle("fill",0,0,W(),H())
    love.graphics.setColor(0,0,0,0.08*a)
    love.graphics.rectangle("fill",px+5,PY+8,PW,ph,20)
    love.graphics.setColor(1,1,1,a)
    love.graphics.rectangle("fill",px,PY,PW,ph,20)

    love.graphics.setColor(Colors.green[1],Colors.green[2],Colors.green[3],a)
    love.graphics.rectangle("fill",px,PY,PW,62,20)
    love.graphics.rectangle("fill",px,PY+42,PW,20,0)
    love.graphics.setColor(1,1,1,a)
    love.graphics.setFont(Fonts.title)
    love.graphics.printf("Registrar Sesi\xc3\xb3n",px,PY+18,PW,"center")

    local selY = PY+68
    love.graphics.setColor(Colors.text[1],Colors.text[2],Colors.text[3],a)
    love.graphics.setFont(Fonts.small)
    love.graphics.print("Tutor\xc3\xada:",px+24,selY)

    local t = tutorias[tutoriaSel]
    local tname
    if #tutorias == 0 then
        tname = "Sin tutor\xc3\xadas asignadas"
    else
        -- Mostrar: Estudiante - Area
        local est = t.estudiante_nombre or "\xe2\x80\x94"
        local area = t.area or "\xe2\x80\x94"
        tname = est .. " (" .. area .. ")"
    end
    love.graphics.setColor(Colors.accent[1],Colors.accent[2],Colors.accent[3],a)
    love.graphics.setFont(Fonts.body)
    love.graphics.print("< "..tname.." >",px+90,selY-2)

    for i,c in ipairs(campos) do
        local fy = PY+96+(i-1)*110
        love.graphics.setColor(Colors.text[1],Colors.text[2],Colors.text[3],a)
        love.graphics.setFont(Fonts.body)
        love.graphics.print(c.label,px+24,fy)
        local focused = (i==campoA)
        local bc = focused and Colors.green or Colors.border
        love.graphics.setColor(bc[1],bc[2],bc[3],a)
        love.graphics.rectangle("fill",px+24,fy+24,PW-48,44,10)
        love.graphics.setColor(focused and 0.96 or 1, focused and 0.99 or 1, focused and 0.97 or 1, a)
        love.graphics.rectangle("fill",px+26,fy+26,PW-52,40,9)
        love.graphics.setFont(Fonts.body)
        if c.value ~= "" then
            love.graphics.setColor(Colors.text[1],Colors.text[2],Colors.text[3],a)
            love.graphics.print(c.value..(focused and "_" or ""),px+36,fy+36)
        else
            love.graphics.setColor(Colors.textSub[1],Colors.textSub[2],Colors.textSub[3],a)
            love.graphics.print(c.placeholder,px+36,fy+36)
        end
    end

    local sy    = PY+96+#campos*110
    local btnW3 = math.floor((PW-48-8)/3)
    local avColors = {Colors.red, Colors.orange, Colors.green}

    love.graphics.setColor(Colors.text[1],Colors.text[2],Colors.text[3],a)
    love.graphics.setFont(Fonts.body)
    love.graphics.print("Nivel de avance",px+24,sy)
    for i,op in ipairs(oAvance) do
        local bx  = px+24+(i-1)*(btnW3+4)
        local sel = avSel==i
        local c2  = avColors[i]
        love.graphics.setColor(sel and c2[1] or Colors.border[1], sel and c2[2] or Colors.border[2], sel and c2[3] or Colors.border[3], a)
        love.graphics.rectangle("fill",bx,sy+28,btnW3,36,10)
        love.graphics.setColor(sel and 1 or Colors.textSub[1], sel and 1 or Colors.textSub[2], sel and 1 or Colors.textSub[3], a)
        love.graphics.setFont(Fonts.small)
        love.graphics.printf(string.upper(op),bx,sy+37,btnW3,"center")
    end

    local ay = sy+88
    love.graphics.setColor(Colors.text[1],Colors.text[2],Colors.text[3],a)
    love.graphics.setFont(Fonts.body)
    love.graphics.print("Asistencia",px+24,ay)
    for i,op in ipairs(oAsist) do
        local bx  = px+24+(i-1)*(btnW3+4)
        local sel = asistSel==i
        local ac  = sel and Colors.accent or Colors.border
        love.graphics.setColor(ac[1],ac[2],ac[3],a)
        love.graphics.rectangle("fill",bx,ay+28,btnW3,36,10)
        love.graphics.setColor(sel and 1 or Colors.textSub[1], sel and 1 or Colors.textSub[2], sel and 1 or Colors.textSub[3], a)
        love.graphics.setFont(Fonts.small)
        love.graphics.printf(op,bx,ay+37,btnW3,"center")
    end

    local btnY = ay+82
    if guardado then
        love.graphics.setColor(Colors.greenSoft[1],Colors.greenSoft[2],Colors.greenSoft[3],a)
        love.graphics.rectangle("fill",px+24,btnY,PW-48,42,12)
        love.graphics.setColor(Colors.green[1],Colors.green[2],Colors.green[3],a)
        love.graphics.setFont(Fonts.body)
        love.graphics.printf("Sesi\xc3\xb3n registrada correctamente",px+24,btnY+12,PW-48,"center")
        btnY = btnY+50
    end
    love.graphics.setColor(Colors.border[1],Colors.border[2],Colors.border[3],a)
    love.graphics.rectangle("fill",px+24,btnY,130,46,12)
    love.graphics.setColor(Colors.text[1],Colors.text[2],Colors.text[3],a)
    love.graphics.setFont(Fonts.body)
    love.graphics.printf("Volver",px+24,btnY+13,130,"center")
    love.graphics.setColor(Colors.green[1],Colors.green[2],Colors.green[3],a)
    love.graphics.rectangle("fill",px+PW-154,btnY,130,46,12)
    love.graphics.setColor(1,1,1,a)
    love.graphics.printf("Guardar",px+PW-154,btnY+13,130,"center")
end

-- === HISTORIAL ===
local function drawHistorial(a, esTutor)
    local WW,HH = W(),H()
    love.graphics.setColor(Colors.bg)
    love.graphics.rectangle("fill",0,0,WW,HH)
    love.graphics.setColor(Colors.accent)
    love.graphics.rectangle("fill",0,0,WW,68)
    love.graphics.setColor(1,1,1)
    love.graphics.setFont(Fonts.title)
    love.graphics.printf(esTutor and "Mis Sesiones Registradas" or "Mis Sesiones",0,22,WW,"center")

    local margin = 40
    local TW     = WW - margin*2
    local ROW_H  = 68
    local startY = 86
    local cols   = esTutor
        and {"Fecha","Estudiante","\xc3\x81rea","Duraci\xc3\xb3n","Asistencia","Avance","Temas"}
        or  {"Fecha","\xc3\x81rea","Tutor","Duraci\xc3\xb3n","Asistencia","Avance","Temas"}
    local cw = math.floor(TW/#cols)

    love.graphics.setColor(Colors.textSub)
    love.graphics.setFont(Fonts.small)
    for i,h in ipairs(cols) do love.graphics.print(h, margin+(i-1)*cw, startY) end
    love.graphics.setColor(Colors.border)
    love.graphics.rectangle("fill",margin,startY+18,TW,1)

    if #historial == 0 then
        love.graphics.setColor(Colors.textSub[1],Colors.textSub[2],Colors.textSub[3],a)
        love.graphics.setFont(Fonts.body)
        love.graphics.printf("No hay sesiones registradas todav\xc3\xada.",0,HH/2-20,WW,"center")
    else
        local function avColor(n)
            return n=="alto" and Colors.green or n=="medio" and Colors.orange or Colors.red
        end
        local function asistColor(s)
            return s=="Asistio" and Colors.green or s=="Ausencia just." and Colors.orange or Colors.red
        end
        for idx,s in ipairs(historial) do
            local ry = startY + 24 + (idx-1)*ROW_H + scrollY
            if ry > startY and ry < HH-60 then
                local bg = idx%2==0 and Colors.bg or Colors.card
                love.graphics.setColor(bg[1],bg[2],bg[3],a)
                love.graphics.rectangle("fill",margin,ry,TW,ROW_H-6,8)
                love.graphics.setColor(Colors.text[1],Colors.text[2],Colors.text[3],a)
                love.graphics.setFont(Fonts.small)
                love.graphics.print(s.fecha or "\xe2\x80\x94", margin+0*cw+8, ry+12)
                local c2v = esTutor and (s._estudiante or "\xe2\x80\x94") or (s._area  or "\xe2\x80\x94")
                local c3v = esTutor and (s._area or "\xe2\x80\x94")       or (s._tutor or "\xe2\x80\x94")
                love.graphics.print(c2v, margin+1*cw+8, ry+12)
                love.graphics.print(c3v, margin+2*cw+8, ry+12)
                love.graphics.print((s.duracion or "\xe2\x80\x94").." min", margin+3*cw+8, ry+12)
                local ac  = asistColor(s.asistencia or "")
                local al  = s.asistencia or "\xe2\x80\x94"
                love.graphics.setColor(ac[1],ac[2],ac[3],0.15*a)
                love.graphics.rectangle("fill",margin+4*cw+8,ry+5,Fonts.small:getWidth(al)+14,22,6)
                love.graphics.setColor(ac[1],ac[2],ac[3],a)
                love.graphics.print(al, margin+4*cw+15, ry+12)
                local vc  = avColor(s.avance or "")
                local vl  = string.upper(s.avance or "\xe2\x80\x94")
                love.graphics.setColor(vc[1],vc[2],vc[3],0.15*a)
                love.graphics.rectangle("fill",margin+5*cw+8,ry+5,Fonts.small:getWidth(vl)+14,22,6)
                love.graphics.setColor(vc[1],vc[2],vc[3],a)
                love.graphics.print(vl, margin+5*cw+15, ry+12)
                local temas = s.temas or "\xe2\x80\x94"
                if #temas > 26 then temas = string.sub(temas,1,24)..".." end
                love.graphics.setColor(Colors.textSub[1],Colors.textSub[2],Colors.textSub[3],a)
                love.graphics.print(temas, margin+6*cw+8, ry+12)
            end
        end
    end

    love.graphics.setColor(Colors.accent)
    love.graphics.rectangle("fill",margin,HH-58,120,42,10)
    love.graphics.setColor(1,1,1)
    love.graphics.setFont(Fonts.body)
    love.graphics.printf("Volver",margin,HH-44,120,"center")
end

function SS.draw()
    local a   = fadeIn:value()
    local rol = Session.rol or params.rol or "estudiante"
    if params.modo == MODO_FORM then drawForm(a)
    else drawHistorial(a, rol == "tutor") end
end

function SS.mousepressed(x,y,btn)
    local rol = Session.rol or params.rol or "estudiante"
    local uid = Session.usuario_id or params.usuario_id
    local HH  = H()

    if params.modo == MODO_FORM then
        local px    = PX()
        local btnW3 = math.floor((PW-48-8)/3)
        local selY  = PY+68
        -- ciclar tutorias del tutor
        if x>=px+90 and x<=px+90+240 and y>=selY-4 and y<=selY+20 then
            tutoriaSel = (tutoriaSel % math.max(1,#tutorias)) + 1
            return
        end
        for i,c in ipairs(campos) do
            local fy = PY+96+(i-1)*110
            if x>=px+24 and x<=px+PW-24 and y>=fy+24 and y<=fy+68 then campoA=i return end
        end
        local sy = PY+96+#campos*110
        for i=1,3 do
            local bx=px+24+(i-1)*(btnW3+4)
            if x>=bx and x<=bx+btnW3 and y>=sy+28 and y<=sy+64 then avSel=i return end
        end
        local ay = sy+88
        for i=1,3 do
            local bx=px+24+(i-1)*(btnW3+4)
            if x>=bx and x<=bx+btnW3 and y>=ay+28 and y<=ay+64 then asistSel=i return end
        end
        local btnY = ay+82+(guardado and 50 or 0)
        if x>=px+24 and x<=px+154 and y>=btnY and y<=btnY+46 then
            Nav.to("sesion",{rol=rol,usuario_id=uid,nombre=Session.nombre},-1)
            return
        end
        if x>=px+PW-154 and x<=px+PW-24 and y>=btnY and y<=btnY+46 then
            local t = tutorias[tutoriaSel]
            if t then
                SesionRepo.crear(t.id, campos[1].value, campos[2].value, campos[3].value, oAsist[asistSel], oAvance[avSel])
                guardado  = true
                -- recargar solo las tutorias del tutor
                if rol == "tutor" and uid then
                    tutorias = TutoriaRepo.getByTutor(uid)
                else
                    tutorias = TutoriaRepo.getAll()
                end
            end
        end
    else
        if x>=40 and x<=160 and y>=HH-58 and y<=HH-16 then
            Nav.to("dashboard",{rol=rol,usuario_id=uid,nombre=Session.nombre},-1)
        end
    end
end

function SS.wheelmoved(x,y)
    if params.modo ~= MODO_FORM then
        scrollY = scrollY + y*30
        if scrollY > 0 then scrollY = 0 end
    end
end

function SS.keypressed(key)
    if params.modo ~= MODO_FORM then return end
    if key=="tab" then
        campoA = (campoA % #campos) + 1
    elseif key=="backspace" then
        local c = campos[campoA]
        if c then c.value = string.sub(c.value,1,-2) end
    end
end

function SS.textinput(t)
    if params.modo ~= MODO_FORM then return end
    local c = campos[campoA]
    if c then c.value = c.value..t end
end

return SS
