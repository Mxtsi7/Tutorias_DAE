local Anim       = require("src.anim.Anim")
local EventBus   = require("src.events.EventBus")
local EventTypes = require("src.events.EventTypes")

local SesionScreen = {}
local oAvance = {"bajo","medio","alto"}
local oAsist  = {"Asistió","Ausencia justificada","Ausencia injustificada"}
local campos  = {
    { label="Fecha de sesión",  value="", placeholder="Ej: 2026-05-22" },
    { label="Duración (min)",   value="", placeholder="Ej: 60" },
    { label="Temas tratados",   value="", placeholder="Describe los temas" },
}
local avSel=1 local asistSel=1 local campoA=1
local guardado=false local fadeIn=nil local params={}
local PX,PY,PW=740,50,440

function SesionScreen.load(p)
    params=p or {}
    for _,c in ipairs(campos) do c.value="" end
    avSel=1 asistSel=1 campoA=1 guardado=false
    fadeIn=Anim.new(0,1,0.4,"easeOut")
end

function SesionScreen.update(dt) fadeIn:update(dt) end

function SesionScreen.draw()
    local a=fadeIn:value()
    love.graphics.setColor(0.08,0.08,0.14,0.45*a)
    love.graphics.rectangle("fill",0,0,1920,1080)
    local ph=80+#campos*110+220
    love.graphics.setColor(0,0,0,0.08*a)
    love.graphics.rectangle("fill",PX+5,PY+8,PW,ph,20)
    love.graphics.setColor(1,1,1,a)
    love.graphics.rectangle("fill",PX,PY,PW,ph,20)
    love.graphics.setColor(Colors.green[1],Colors.green[2],Colors.green[3],a)
    love.graphics.rectangle("fill",PX,PY,PW,60,{20,20,0,0})
    love.graphics.setColor(1,1,1,a)
    love.graphics.setFont(Fonts.title)
    love.graphics.printf("Registrar Sesión",PX,PY+16,PW,"center")

    for i,c in ipairs(campos) do
        local fy=PY+72+(i-1)*110
        love.graphics.setColor(Colors.text[1],Colors.text[2],Colors.text[3],a)
        love.graphics.setFont(Fonts.body)
        love.graphics.print(c.label,PX+24,fy)
        local bc=i==campoA and Colors.green or Colors.border
        love.graphics.setColor(bc[1],bc[2],bc[3],a)
        love.graphics.rectangle("line",PX+24,fy+26,PW-48,44,10)
        love.graphics.setColor(Colors.bg[1],Colors.bg[2],Colors.bg[3],a)
        love.graphics.rectangle("fill",PX+25,fy+27,PW-50,42,9)
        if c.value~="" then
            love.graphics.setColor(Colors.text[1],Colors.text[2],Colors.text[3],a)
            love.graphics.setFont(Fonts.body)
            love.graphics.print(c.value..(i==campoA and "_" or ""),PX+36,fy+38)
        else
            love.graphics.setColor(Colors.textSub[1],Colors.textSub[2],Colors.textSub[3],a)
            love.graphics.setFont(Fonts.body)
            love.graphics.print(c.placeholder,PX+36,fy+38)
        end
    end

    local sy=PY+72+#campos*110
    love.graphics.setColor(Colors.text[1],Colors.text[2],Colors.text[3],a)
    love.graphics.setFont(Fonts.body)
    love.graphics.print("Nivel de avance",PX+24,sy)
    local avColors={Colors.red,Colors.orange,Colors.green}
    for i,op in ipairs(oAvance) do
        local bx=PX+24+(i-1)*136
        local sel=avSel==i
        local c=avColors[i]
        love.graphics.setColor(sel and c[1] or Colors.border[1],
                               sel and c[2] or Colors.border[2],
                               sel and c[3] or Colors.border[3],a)
        love.graphics.rectangle("fill",bx,sy+28,126,38,10)
        love.graphics.setColor(sel and 1 or Colors.textSub[1],
                               sel and 1 or Colors.textSub[2],
                               sel and 1 or Colors.textSub[3],a)
        love.graphics.setFont(Fonts.body)
        love.graphics.printf(string.upper(op),bx,sy+38,126,"center")
    end

    local ay=sy+90
    love.graphics.setColor(Colors.text[1],Colors.text[2],Colors.text[3],a)
    love.graphics.setFont(Fonts.body)
    love.graphics.print("Asistencia",PX+24,ay)
    for i,op in ipairs(oAsist) do
        local bx=PX+24+(i-1)*138
        local sel=asistSel==i
        love.graphics.setColor(sel and Colors.accent[1] or Colors.border[1],
                               sel and Colors.accent[2] or Colors.border[2],
                               sel and Colors.accent[3] or Colors.border[3],a)
        love.graphics.rectangle("fill",bx,ay+28,128,36,10)
        love.graphics.setColor(sel and 1 or Colors.textSub[1],
                               sel and 1 or Colors.textSub[2],
                               sel and 1 or Colors.textSub[3],a)
        love.graphics.setFont(Fonts.small)
        love.graphics.printf(op,bx,ay+38,128,"center")
    end

    local btnY=ay+82
    if guardado then
        love.graphics.setColor(Colors.greenSoft[1],Colors.greenSoft[2],Colors.greenSoft[3],a)
        love.graphics.rectangle("fill",PX+24,btnY,PW-48,44,12)
        love.graphics.setColor(Colors.green[1],Colors.green[2],Colors.green[3],a)
        love.graphics.setFont(Fonts.body)
        love.graphics.printf("✓ Sesión registrada",PX+24,btnY+12,PW-48,"center")
        btnY=btnY+52
    end
    love.graphics.setColor(Colors.border[1],Colors.border[2],Colors.border[3],a)
    love.graphics.rectangle("fill",PX+24,btnY,130,46,12)
    love.graphics.setColor(Colors.text[1],Colors.text[2],Colors.text[3],a)
    love.graphics.setFont(Fonts.body)
    love.graphics.printf("Volver",PX+24,btnY+13,130,"center")
    love.graphics.setColor(Colors.green[1],Colors.green[2],Colors.green[3],a)
    love.graphics.rectangle("fill",PX+PW-154,btnY,130,46,12)
    love.graphics.setColor(1,1,1,a)
    love.graphics.printf("Guardar",PX+PW-154,btnY+13,130,"center")
end

function SesionScreen.mousepressed(x,y,btn)
    for i,c in ipairs(campos) do
        local fy=PY+72+(i-1)*110
        if x>=PX+24 and x<=PX+PW-24 and y>=fy+26 and y<=fy+70 then campoA=i return end
    end
    local sy=PY+72+#campos*110
    for i=1,3 do
        local bx=PX+24+(i-1)*136
        if x>=bx and x<=bx+126 and y>=sy+28 and y<=sy+66 then avSel=i return end
    end
    local ay=sy+90
    for i=1,3 do
        local bx=PX+24+(i-1)*138
        if x>=bx and x<=bx+128 and y>=ay+28 and y<=ay+64 then asistSel=i return end
    end
    local btnY=ay+82+(guardado and 52 or 0)
    if x>=PX+24 and x<=PX+154 and y>=btnY and y<=btnY+46 then Nav.to("dashboard",{rol=params.rol},-1) end
    if x>=PX+PW-154 and x<=PX+PW-24 and y>=btnY and y<=btnY+46 then
        local ev=oAsist[asistSel]=="Asistió" and EventTypes.SESION_REGISTRADA
                or oAsist[asistSel]=="Ausencia justificada" and EventTypes.SESION_AUSENCIA_JUST
                or EventTypes.SESION_AUSENCIA_INJUST
        EventBus.publish(ev,{avance=oAvance[avSel],campos=campos})
        guardado=true
    end
end

function SesionScreen.keypressed(key)
    if key=="tab" then campoA=(campoA%#campos)+1
    elseif key=="backspace" then
        local c=campos[campoA] if c then c.value=string.sub(c.value,1,-2) end
    end
end
function SesionScreen.textinput(t)
    local c=campos[campoA] if c then c.value=c.value..t end
end

return SesionScreen
