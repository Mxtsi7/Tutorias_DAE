local Anim      = require("src.anim.Anim")
local SesionRepo = require("src.db.SesionRepo")
local TutoriaRepo = require("src.db.TutoriaRepo")
local Session   = require("src.session.Session")

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

local PW=460 local PY=40
local function W() return love.graphics.getWidth() end
local function H() return love.graphics.getHeight() end
local function PX() return math.floor((W()-PW)/2) end

function SS.load(p)
    params=p or {}
    for _,c in ipairs(campos) do c.value="" end
    avSel=1 asistSel=1 campoA=1 guardado=false
    -- Pre-llenar fecha de hoy
    campos[1].value = os.date("%Y-%m-%d")
    -- Cargar tutorias del tutor o del estudiante
    if Session.rol=="tutor" then
        tutorias = TutoriaRepo.getAll()
    else
        tutorias = TutoriaRepo.getByEstudiante(Session.usuario_id or 1)
    end
    tutoriaSel = 1
    fadeIn = Anim.new(0,1,0.4,"easeOut")
end

function SS.update(dt) fadeIn:update(dt) end

function SS.draw()
    local a=fadeIn:value()
    local ww,hh=W(),H()
    local px=PX()
    local ph=74+#campos*110+230

    love.graphics.setColor(0.08,0.08,0.14,0.45*a)
    love.graphics.rectangle("fill",0,0,ww,hh)
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

    -- Selector de tutoria
    local selY=PY+68
    love.graphics.setColor(Colors.text[1],Colors.text[2],Colors.text[3],a)
    love.graphics.setFont(Fonts.small)
    love.graphics.print("Tutor\xc3\xada:",px+24,selY)
    local tname = tutorias[tutoriaSel] and
        (tutorias[tutoriaSel].area or "Sin tutor\xc3\xadas") or "Sin tutor\xc3\xadas"
    love.graphics.setColor(Colors.accent[1],Colors.accent[2],Colors.accent[3],a)
    love.graphics.setFont(Fonts.body)
    love.graphics.print("< "..tname.." >",px+90,selY-2)

    for i,c in ipairs(campos) do
        local fy=PY+96+(i-1)*110
        love.graphics.setColor(Colors.text[1],Colors.text[2],Colors.text[3],a)
        love.graphics.setFont(Fonts.body)
        love.graphics.print(c.label,px+24,fy)
        local focused=(i==campoA)
        local bc=focused and Colors.green or Colors.border
        love.graphics.setColor(bc[1],bc[2],bc[3],a)
        love.graphics.rectangle("fill",px+24,fy+24,PW-48,44,10)
        love.graphics.setColor(focused and 0.96 or 1,focused and 0.99 or 1,focused and 0.97 or 1,a)
        love.graphics.rectangle("fill",px+26,fy+26,PW-52,40,9)
        love.graphics.setFont(Fonts.body)
        if c.value~="" then
            love.graphics.setColor(Colors.text[1],Colors.text[2],Colors.text[3],a)
            love.graphics.print(c.value..(focused and "_" or ""),px+36,fy+36)
        else
            love.graphics.setColor(Colors.textSub[1],Colors.textSub[2],Colors.textSub[3],a)
            love.graphics.print(c.placeholder,px+36,fy+36)
        end
    end

    local sy=PY+96+#campos*110
    love.graphics.setColor(Colors.text[1],Colors.text[2],Colors.text[3],a)
    love.graphics.setFont(Fonts.body)
    love.graphics.print("Nivel de avance",px+24,sy)
    local avColors={Colors.red,Colors.orange,Colors.green}
    local btnW3=math.floor((PW-48-8)/3)
    for i,op in ipairs(oAvance) do
        local bx=px+24+(i-1)*(btnW3+4)
        local sel=avSel==i
        local c=avColors[i]
        love.graphics.setColor(sel and c[1] or Colors.border[1],sel and c[2] or Colors.border[2],sel and c[3] or Colors.border[3],a)
        love.graphics.rectangle("fill",bx,sy+28,btnW3,36,10)
        love.graphics.setColor(sel and 1 or Colors.textSub[1],sel and 1 or Colors.textSub[2],sel and 1 or Colors.textSub[3],a)
        love.graphics.setFont(Fonts.small)
        love.graphics.printf(string.upper(op),bx,sy+37,btnW3,"center")
    end

    local ay=sy+88
    love.graphics.setColor(Colors.text[1],Colors.text[2],Colors.text[3],a)
    love.graphics.setFont(Fonts.body)
    love.graphics.print("Asistencia",px+24,ay)
    for i,op in ipairs(oAsist) do
        local bx=px+24+(i-1)*(btnW3+4)
        local sel=asistSel==i
        love.graphics.setColor(sel and Colors.accent[1] or Colors.border[1],sel and Colors.accent[2] or Colors.border[2],sel and Colors.accent[3] or Colors.border[3],a)
        love.graphics.rectangle("fill",bx,ay+28,btnW3,36,10)
        love.graphics.setColor(sel and 1 or Colors.textSub[1],sel and 1 or Colors.textSub[2],sel and 1 or Colors.textSub[3],a)
        love.graphics.setFont(Fonts.small)
        love.graphics.printf(op,bx,ay+37,btnW3,"center")
    end

    local btnY=ay+82
    if guardado then
        love.graphics.setColor(Colors.greenSoft[1],Colors.greenSoft[2],Colors.greenSoft[3],a)
        love.graphics.rectangle("fill",px+24,btnY,PW-48,42,12)
        love.graphics.setColor(Colors.green[1],Colors.green[2],Colors.green[3],a)
        love.graphics.setFont(Fonts.body)
        love.graphics.printf("Sesion registrada en la BD",px+24,btnY+12,PW-48,"center")
        btnY=btnY+50
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

function SS.mousepressed(x,y,btn)
    local px=PX()
    local btnW3=math.floor((PW-48-8)/3)
    -- selector tutoria
    local selY=PY+68
    if x>=px+90 and x<=px+90+100 and y>=selY-4 and y<=selY+20 then
        tutoriaSel=(tutoriaSel%math.max(1,#tutorias))+1
        return
    end
    for i,c in ipairs(campos) do
        local fy=PY+96+(i-1)*110
        if x>=px+24 and x<=px+PW-24 and y>=fy+24 and y<=fy+68 then campoA=i return end
    end
    local sy=PY+96+#campos*110
    for i=1,3 do
        local bx=px+24+(i-1)*(btnW3+4)
        if x>=bx and x<=bx+btnW3 and y>=sy+28 and y<=sy+64 then avSel=i return end
    end
    local ay=sy+88
    for i=1,3 do
        local bx=px+24+(i-1)*(btnW3+4)
        if x>=bx and x<=bx+btnW3 and y>=ay+28 and y<=ay+64 then asistSel=i return end
    end
    local btnY=ay+82+(guardado and 50 or 0)
    if x>=px+24 and x<=px+154 and y>=btnY and y<=btnY+46 then
        Nav.to("dashboard",{rol=params.rol,usuario_id=params.usuario_id,nombre=Session.nombre},-1) return
    end
    if x>=px+PW-154 and x<=px+PW-24 and y>=btnY and y<=btnY+46 then
        local t=tutorias[tutoriaSel]
        if t then
            SesionRepo.crear(
                t.id,
                campos[1].value, campos[2].value, campos[3].value,
                oAsist[asistSel], oAvance[avSel]
            )
            guardado=true
            -- recargar tutorias para reflejar cambio
            if Session.rol=="tutor" then
                tutorias=TutoriaRepo.getAll()
            else
                tutorias=TutoriaRepo.getByEstudiante(Session.usuario_id or 1)
            end
        end
    end
end

function SS.keypressed(key)
    if key=="tab" then campoA=(campoA%#campos)+1
    elseif key=="backspace" then
        local c=campos[campoA] if c then c.value=string.sub(c.value,1,-2) end
    end
end
function SS.textinput(t)
    local c=campos[campoA] if c then c.value=c.value..t end
end

return SS
