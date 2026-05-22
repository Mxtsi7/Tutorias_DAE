local Anim     = require("src.anim.Anim")
local EventBus = require("src.events.EventBus")
local EventTypes = require("src.events.EventTypes")

local S = {}
local campos = {
    { label="\xc3\x81rea Tem\xc3\xa1tica",       placeholder="Ej: Estad\xc3\xadstica Aplicada", value="", error=false },
    { label="Nivel de Urgencia",    placeholder="alta / media / baja",        value="", error=false },
    { label="Disponibilidad Horaria", placeholder="Ej: Martes y Jueves tarde", value="", error=false },
    { label="Modalidad Preferida",  placeholder="remota / presencial",        value="", error=false },
}
local campoA=1 local enviado=false local errorMsg=""
local fadeIn=nil local params={}

local function W() return love.graphics.getWidth() end
local function H() return love.graphics.getHeight() end
local PW=480
local function PX() return math.floor((W()-PW)/2) end
local PY=40

function S.load(p)
    params=p or {}
    for _,c in ipairs(campos) do c.value="" c.error=false end
    campoA=1 enviado=false errorMsg=""
    fadeIn=Anim.new(0,1,0.35,"easeOut")
end

function S.update(dt) fadeIn:update(dt) end

function S.draw()
    local a=fadeIn:value()
    local px=PX()
    local ph=74+#campos*108+110

    -- fondo oscuro
    love.graphics.setColor(0.08,0.08,0.14,0.4*a)
    love.graphics.rectangle("fill",0,0,W(),H())

    -- sombra del panel
    love.graphics.setColor(0,0,0,0.10*a)
    love.graphics.rectangle("fill",px+4,PY+6,PW,ph,18)
    -- panel blanco
    love.graphics.setColor(1,1,1,a)
    love.graphics.rectangle("fill",px,PY,PW,ph,18)

    -- header violeta
    love.graphics.setColor(Colors.accent[1],Colors.accent[2],Colors.accent[3],a)
    love.graphics.rectangle("fill",px,PY,PW,58,{18,18,0,0})
    love.graphics.setColor(1,1,1,a)
    love.graphics.setFont(Fonts.title)
    love.graphics.printf("Nueva Solicitud de Tutor\xc3\xada",px,PY+16,PW,"center")

    -- campos
    for i,c in ipairs(campos) do
        local fy=PY+66+(i-1)*108
        love.graphics.setColor(Colors.text[1],Colors.text[2],Colors.text[3],a)
        love.graphics.setFont(Fonts.body)
        love.graphics.print(c.label,px+22,fy)

        -- input: fondo gris claro
        local isFocus=(i==campoA)
        if isFocus then
            -- borde violeta: rect externo
            love.graphics.setColor(Colors.accent[1],Colors.accent[2],Colors.accent[3],a)
            love.graphics.rectangle("fill",px+22,fy+24,PW-44,44,12)
            love.graphics.setColor(0.97,0.96,1,a)
            love.graphics.rectangle("fill",px+24,fy+26,PW-48,40,10)
        elseif c.error then
            love.graphics.setColor(Colors.red[1],Colors.red[2],Colors.red[3],a)
            love.graphics.rectangle("fill",px+22,fy+24,PW-44,44,12)
            love.graphics.setColor(0.99,0.96,0.96,a)
            love.graphics.rectangle("fill",px+24,fy+26,PW-48,40,10)
        else
            love.graphics.setColor(Colors.bg[1],Colors.bg[2],Colors.bg[3],a)
            love.graphics.rectangle("fill",px+22,fy+24,PW-44,44,12)
            love.graphics.setColor(1,1,1,a)
            love.graphics.rectangle("fill",px+24,fy+26,PW-48,40,10)
        end

        -- texto del campo
        love.graphics.setFont(Fonts.body)
        if c.value~="" then
            love.graphics.setColor(Colors.text[1],Colors.text[2],Colors.text[3],a)
            love.graphics.print(c.value..(isFocus and "_" or ""),px+34,fy+36)
        else
            love.graphics.setColor(Colors.textSub[1],Colors.textSub[2],Colors.textSub[3],a)
            love.graphics.print(c.placeholder,px+34,fy+36)
        end

        -- error inline
        if c.error then
            love.graphics.setColor(Colors.red[1],Colors.red[2],Colors.red[3],a)
            love.graphics.setFont(Fonts.small)
            love.graphics.print("Campo obligatorio",px+34,fy+72)
        end
    end

    -- mensaje
    local my2=PY+66+#campos*108+6
    if enviado then
        love.graphics.setColor(Colors.greenSoft[1],Colors.greenSoft[2],Colors.greenSoft[3],a)
        love.graphics.rectangle("fill",px+22,my2,PW-44,40,10)
        love.graphics.setColor(Colors.green[1],Colors.green[2],Colors.green[3],a)
        love.graphics.setFont(Fonts.body)
        love.graphics.printf("Solicitud enviada correctamente",px+22,my2+11,PW-44,"center")
    elseif errorMsg~="" then
        love.graphics.setColor(0.99,0.94,0.94,a)
        love.graphics.rectangle("fill",px+22,my2,PW-44,40,10)
        love.graphics.setColor(Colors.red[1],Colors.red[2],Colors.red[3],a)
        love.graphics.setFont(Fonts.small)
        love.graphics.printf(errorMsg,px+22,my2+12,PW-44,"center")
    end

    -- botones
    local btnY=my2+50
    -- Cancelar
    love.graphics.setColor(Colors.border[1],Colors.border[2],Colors.border[3],a)
    love.graphics.rectangle("fill",px+22,btnY,130,42,10)
    love.graphics.setColor(Colors.text[1],Colors.text[2],Colors.text[3],a)
    love.graphics.setFont(Fonts.body)
    love.graphics.printf("Cancelar",px+22,btnY+12,130,"center")
    -- Enviar
    love.graphics.setColor(Colors.accent[1],Colors.accent[2],Colors.accent[3],a)
    love.graphics.rectangle("fill",px+PW-152,btnY,130,42,10)
    love.graphics.setColor(1,1,1,a)
    love.graphics.printf("Enviar",px+PW-152,btnY+12,130,"center")
end

function S.mousepressed(x,y,btn)
    local px=PX()
    for i,c in ipairs(campos) do
        local fy=PY+66+(i-1)*108
        if x>=px+22 and x<=px+PW-22 and y>=fy+24 and y<=fy+68 then
            campoA=i return
        end
    end
    local my2=PY+66+#campos*108+6
    local btnY=my2+50
    if x>=px+22 and x<=px+152 and y>=btnY and y<=btnY+42 then
        Nav.to("dashboard",{rol=params.rol},-1) return
    end
    if x>=px+PW-152 and x<=px+PW-22 and y>=btnY and y<=btnY+42 then
        errorMsg="" local valid=true
        for _,c in ipairs(campos) do
            c.error=(c.value=="") if c.error then valid=false end
        end
        if valid then
            EventBus.publish(EventTypes.SOLICITUD_ENVIADA,{campos=campos})
            enviado=true errorMsg=""
        else
            errorMsg="Completa todos los campos" enviado=false
        end
    end
end

function S.keypressed(key)
    if key=="tab" then campoA=(campoA%#campos)+1
    elseif key=="backspace" then
        local c=campos[campoA] if c then c.value=string.sub(c.value,1,-2) end
    end
end
function S.textinput(t)
    local c=campos[campoA] if c then c.value=c.value..t end
end

return S
