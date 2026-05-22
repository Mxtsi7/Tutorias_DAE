local Anim = require("src.anim.Anim")
local EventBus   = require("src.events.EventBus")
local EventTypes = require("src.events.EventTypes")

local SolicitudScreen = {}
local campos = {
    { label="Área Temática",        placeholder="Ej: Estadística Aplicada",  value="", error=false },
    { label="Nivel de Urgencia",    placeholder="alta / media / baja",         value="", error=false },
    { label="Disponibilidad Horaria", placeholder="Ej: Martes y Jueves tarde", value="", error=false },
    { label="Modalidad Preferida",  placeholder="remota / presencial",         value="", error=false },
}
local campoActivo = 1
local enviado  = false
local errorMsg = ""
local fadeIn   = nil
local params   = {}

local PX,PY,PW = 740, 80, 440

function SolicitudScreen.load(p)
    params = p or {}
    for _,c in ipairs(campos) do c.value="" c.error=false end
    campoActivo=1 enviado=false errorMsg=""
    fadeIn = Anim.new(0,1,0.4,"easeOut")
end

function SolicitudScreen.update(dt)
    fadeIn:update(dt)
end

function SolicitudScreen.draw()
    local a = fadeIn:value()
    -- fondo semitransparente
    love.graphics.setColor(0.08,0.08,0.14, 0.45*a)
    love.graphics.rectangle("fill",0,0,1920,1080)

    local ph = 120 + #campos*115 + 120
    love.graphics.setColor(0,0,0,0.08*a)
    love.graphics.rectangle("fill",PX+5,PY+8,PW,ph,20)
    love.graphics.setColor(1,1,1,a)
    love.graphics.rectangle("fill",PX,PY,PW,ph,20)

    -- header
    love.graphics.setColor(Colors.accent[1],Colors.accent[2],Colors.accent[3],a)
    love.graphics.rectangle("fill",PX,PY,PW,64,{20,20,0,0})
    love.graphics.setColor(1,1,1,a)
    love.graphics.setFont(Fonts.title)
    love.graphics.printf("Nueva Solicitud",PX,PY+18,PW,"center")

    for i,c in ipairs(campos) do
        local fy = PY+78+(i-1)*115
        love.graphics.setColor(Colors.text[1],Colors.text[2],Colors.text[3],a)
        love.graphics.setFont(Fonts.body)
        love.graphics.print(c.label,PX+24,fy)
        local bc = i==campoActivo and Colors.accent or (c.error and Colors.red or Colors.border)
        love.graphics.setColor(bc[1],bc[2],bc[3],a)
        love.graphics.rectangle("line",PX+24,fy+28,PW-48,46,12)
        love.graphics.setColor(Colors.bg[1],Colors.bg[2],Colors.bg[3],a)
        love.graphics.rectangle("fill",PX+25,fy+29,PW-50,44,11)
        love.graphics.setFont(Fonts.body)
        if c.value~="" then
            love.graphics.setColor(Colors.text[1],Colors.text[2],Colors.text[3],a)
            love.graphics.print(c.value..(i==campoActivo and "_" or ""),PX+36,fy+40)
        else
            love.graphics.setColor(Colors.textSub[1],Colors.textSub[2],Colors.textSub[3],a)
            love.graphics.print(c.placeholder,PX+36,fy+40)
        end
        if c.error then
            love.graphics.setColor(Colors.red[1],Colors.red[2],Colors.red[3],a)
            love.graphics.setFont(Fonts.small)
            love.graphics.print("Campo obligatorio",PX+36,fy+80)
        end
    end

    local by = PY + 78 + #campos*115 + 10
    if enviado then
        love.graphics.setColor(Colors.greenSoft[1],Colors.greenSoft[2],Colors.greenSoft[3],a)
        love.graphics.rectangle("fill",PX+24,by,PW-48,48,12)
        love.graphics.setColor(Colors.green[1],Colors.green[2],Colors.green[3],a)
        love.graphics.setFont(Fonts.body)
        love.graphics.printf("✓ Solicitud enviada",PX+24,by+14,PW-48,"center")
    elseif errorMsg~="" then
        love.graphics.setColor(0.98,0.92,0.92,a)
        love.graphics.rectangle("fill",PX+24,by,PW-48,48,12)
        love.graphics.setColor(Colors.red[1],Colors.red[2],Colors.red[3],a)
        love.graphics.setFont(Fonts.small)
        love.graphics.printf(errorMsg,PX+24,by+14,PW-48,"center")
    end

    local btnY = by + 60
    love.graphics.setColor(Colors.border[1],Colors.border[2],Colors.border[3],a)
    love.graphics.rectangle("fill",PX+24,btnY,130,46,12)
    love.graphics.setColor(Colors.text[1],Colors.text[2],Colors.text[3],a)
    love.graphics.setFont(Fonts.body)
    love.graphics.printf("Cancelar",PX+24,btnY+13,130,"center")
    love.graphics.setColor(Colors.accent[1],Colors.accent[2],Colors.accent[3],a)
    love.graphics.rectangle("fill",PX+PW-154,btnY,130,46,12)
    love.graphics.setColor(1,1,1,a)
    love.graphics.printf("Enviar",PX+PW-154,btnY+13,130,"center")
end

function SolicitudScreen.mousepressed(x,y,btn)
    local ph = 120+#campos*115+120
    for i,c in ipairs(campos) do
        local fy=PY+78+(i-1)*115
        if x>=PX+24 and x<=PX+PW-24 and y>=fy+28 and y<=fy+74 then
            campoActivo=i return
        end
    end
    local by=PY+78+#campos*115+10
    local btnY=by+60
    if x>=PX+24 and x<=PX+154 and y>=btnY and y<=btnY+46 then
        Nav.to("dashboard",{rol=params.rol},-1) return
    end
    if x>=PX+PW-154 and x<=PX+PW-24 and y>=btnY and y<=btnY+46 then
        errorMsg="" local valid=true
        for _,c in ipairs(campos) do
            c.error=(c.value=="")
            if c.error then valid=false end
        end
        if valid then
            EventBus.publish(EventTypes.SOLICITUD_ENVIADA,{campos=campos})
            enviado=true errorMsg=""
        else
            errorMsg="Completa todos los campos" enviado=false
        end
    end
end

function SolicitudScreen.keypressed(key)
    if key=="tab" then campoActivo=(campoActivo%#campos)+1
    elseif key=="backspace" then
        local c=campos[campoActivo]
        if c then c.value=string.sub(c.value,1,-2) end
    end
end

function SolicitudScreen.textinput(text)
    local c=campos[campoActivo]
    if c then c.value=c.value..text end
end

return SolicitudScreen
