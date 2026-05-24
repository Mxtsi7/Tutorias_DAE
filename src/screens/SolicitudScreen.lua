local Anim          = require("src.anim.Anim")
local SolicitudRepo = require("src.db.SolicitudRepo")
local Session       = require("src.session.Session")

local S = {}

-- Estado formulario (usado solo cuando params.modo=="nueva")
local campos = {
    { label="\xc3\x81rea Tem\xc3\xa1tica",         placeholder="Ej: Estad\xc3\xadstica Aplicada", value="", error=false },
    { label="Nivel de Urgencia",      placeholder="alta / media / baja",        value="", error=false },
    { label="Disponibilidad Horaria", placeholder="Ej: Martes y Jueves tarde",  value="", error=false },
    { label="Modalidad Preferida",    placeholder="remota / presencial",        value="", error=false },
}
local campoA=1 local enviado=false local errorMsg=""
local fadeIn=nil local params={}
local solicitudes={} local scrollY=0

local PW=480 local PY=40
local function W() return love.graphics.getWidth() end
local function H() return love.graphics.getHeight() end
local function PX() return math.floor((W()-PW)/2) end

local MODO_FORM   = "nueva"   -- acceso desde boton + Nueva Solicitud
local MODO_LISTA  = "lista"   -- acceso desde nav sidebar

function S.load(p)
    params   = p or {}
    enviado  = false
    errorMsg = ""
    campoA   = 1
    scrollY  = 0
    for _,c in ipairs(campos) do c.value="" c.error=false end
    fadeIn = Anim.new(0,1,0.35,"easeOut")

    -- Cargar solicitudes segun rol
    local rol = Session.rol or params.rol or "estudiante"
    if rol == "estudiante" then
        solicitudes = SolicitudRepo.getByEstudiante(Session.usuario_id or 1)
    elseif rol == "coordinador" then
        solicitudes = SolicitudRepo.getAll()
    else
        solicitudes = {}
    end
end

function S.update(dt) fadeIn:update(dt) end

-- ── VISTA FORMULARIO (modo "nueva") ──────────────────────────────────────────
local function drawForm(a)
    local px=PX() local ww,hh=W(),H()
    local ph=74+#campos*108+110

    love.graphics.setColor(0.08,0.08,0.14,0.4*a)
    love.graphics.rectangle("fill",0,0,ww,hh)
    love.graphics.setColor(0,0,0,0.10*a)
    love.graphics.rectangle("fill",px+4,PY+6,PW,ph,18)
    love.graphics.setColor(1,1,1,a)
    love.graphics.rectangle("fill",px,PY,PW,ph,18)

    love.graphics.setColor(Colors.accent[1],Colors.accent[2],Colors.accent[3],a)
    love.graphics.rectangle("fill",px,PY,PW,60,18)
    love.graphics.rectangle("fill",px,PY+40,PW,20,0)
    love.graphics.setColor(1,1,1,a)
    love.graphics.setFont(Fonts.title)
    love.graphics.printf("Nueva Solicitud de Tutor\xc3\xada",px,PY+16,PW,"center")

    for i,c in ipairs(campos) do
        local fy=PY+68+(i-1)*108
        love.graphics.setColor(Colors.text[1],Colors.text[2],Colors.text[3],a)
        love.graphics.setFont(Fonts.body)
        love.graphics.print(c.label,px+22,fy)
        local isFocus=(i==campoA)
        local bc=isFocus and Colors.accent or (c.error and Colors.red or Colors.border)
        love.graphics.setColor(bc[1],bc[2],bc[3],a)
        love.graphics.rectangle("fill",px+22,fy+24,PW-44,44,12)
        local ibg=isFocus and {0.97,0.96,1} or (c.error and {0.99,0.96,0.96} or {1,1,1})
        love.graphics.setColor(ibg[1],ibg[2],ibg[3],a)
        love.graphics.rectangle("fill",px+24,fy+26,PW-48,40,10)
        love.graphics.setFont(Fonts.body)
        if c.value~="" then
            love.graphics.setColor(Colors.text[1],Colors.text[2],Colors.text[3],a)
            love.graphics.print(c.value..(isFocus and "_" or ""),px+34,fy+36)
        else
            love.graphics.setColor(Colors.textSub[1],Colors.textSub[2],Colors.textSub[3],a)
            love.graphics.print(c.placeholder,px+34,fy+36)
        end
        if c.error then
            love.graphics.setColor(Colors.red[1],Colors.red[2],Colors.red[3],a)
            love.graphics.setFont(Fonts.small)
            love.graphics.print("Campo obligatorio",px+34,fy+72)
        end
    end

    local my2=PY+68+#campos*108+6
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

    local btnY=my2+50
    love.graphics.setColor(Colors.border[1],Colors.border[2],Colors.border[3],a)
    love.graphics.rectangle("fill",px+22,btnY,130,42,10)
    love.graphics.setColor(Colors.text[1],Colors.text[2],Colors.text[3],a)
    love.graphics.setFont(Fonts.body)
    love.graphics.printf("Cancelar",px+22,btnY+12,130,"center")
    love.graphics.setColor(Colors.accent[1],Colors.accent[2],Colors.accent[3],a)
    love.graphics.rectangle("fill",px+PW-152,btnY,130,42,10)
    love.graphics.setColor(1,1,1,a)
    love.graphics.printf("Enviar",px+PW-152,btnY+12,130,"center")
end

-- ── VISTA LISTA (modo "lista") ───────────────────────────────────────────────
local function estadoColor(e)
    if e=="pendiente" then return Colors.orange
    elseif e=="aceptada" or e=="asignada" then return Colors.green
    else return Colors.red end
end

local function drawLista(a)
    local WW,HH = W(),H()
    local rol    = Session.rol or params.rol or "estudiante"
    local titulo = rol=="coordinador" and "Solicitudes — Coordinador" or "Mis Solicitudes"

    love.graphics.setColor(Colors.bg)
    love.graphics.rectangle("fill",0,0,WW,HH)

    love.graphics.setColor(Colors.accent)
    love.graphics.rectangle("fill",0,0,WW,68)
    love.graphics.setColor(1,1,1)
    love.graphics.setFont(Fonts.title)
    love.graphics.printf(titulo,0,22,WW,"center")

    local margin = 40
    local TW     = WW - margin*2
    local ROW_H  = 66
    local startY = 86
    local cols   = rol=="coordinador"
        and {"Estudiante","\xc3\x81rea","Urgencia","Disponibilidad","Modalidad","Estado"}
        or  {"\xc3\x81rea","Urgencia","Disponibilidad","Modalidad","Estado"}
    local ncols  = #cols
    local cw     = math.floor(TW/ncols)

    love.graphics.setColor(Colors.textSub)
    love.graphics.setFont(Fonts.small)
    for i,h in ipairs(cols) do
        love.graphics.print(h, margin+(i-1)*cw, startY)
    end
    love.graphics.setColor(Colors.border)
    love.graphics.rectangle("fill",margin,startY+18,TW,1)

    if #solicitudes == 0 then
        love.graphics.setColor(Colors.textSub[1],Colors.textSub[2],Colors.textSub[3],a)
        love.graphics.setFont(Fonts.body)
        love.graphics.printf("No hay solicitudes todav\xc3\xada.",0,HH/2,WW,"center")
    else
        for idx,sol in ipairs(solicitudes) do
            local ry = startY + 24 + (idx-1)*ROW_H + scrollY
            if ry > startY and ry < HH - 60 then
                local bg = idx%2==0 and Colors.bg or Colors.card
                love.graphics.setColor(bg[1],bg[2],bg[3],a)
                love.graphics.rectangle("fill",margin,ry,TW,ROW_H-6,8)

                love.graphics.setColor(Colors.text[1],Colors.text[2],Colors.text[3],a)
                love.graphics.setFont(Fonts.small)

                local offset = 0
                if rol=="coordinador" then
                    love.graphics.print(sol.estudiante_nombre or "\xe2\x80\x94", margin+0*cw+8, ry+14)
                    offset = 1
                end
                love.graphics.print(sol.area             or "\xe2\x80\x94", margin+(0+offset)*cw+8, ry+14)
                love.graphics.print(sol.urgencia         or "\xe2\x80\x94", margin+(1+offset)*cw+8, ry+14)
                love.graphics.print(sol.disponibilidad   or "\xe2\x80\x94", margin+(2+offset)*cw+8, ry+14)
                love.graphics.print(sol.modalidad        or "\xe2\x80\x94", margin+(3+offset)*cw+8, ry+14)

                -- badge estado
                local ec  = estadoColor(sol.estado or "pendiente")
                local el  = sol.estado or "pendiente"
                local etw = Fonts.small:getWidth(el)+14
                love.graphics.setColor(ec[1],ec[2],ec[3],0.15*a)
                love.graphics.rectangle("fill",margin+(4+offset)*cw+8,ry+7,etw,22,6)
                love.graphics.setColor(ec[1],ec[2],ec[3],a)
                love.graphics.print(el, margin+(4+offset)*cw+15, ry+14)
            end
        end
    end

    -- Boton volver
    love.graphics.setColor(Colors.accent)
    love.graphics.rectangle("fill",margin,HH-60,120,42,10)
    love.graphics.setColor(1,1,1)
    love.graphics.setFont(Fonts.body)
    love.graphics.printf("Volver",margin,HH-46,120,"center")
end

function S.draw()
    local a = fadeIn:value()
    if params.modo == MODO_FORM then
        drawForm(a)
    else
        drawLista(a)
    end
end

-- ── INPUT ───────────────────────────────────────────────────────────────────
function S.mousepressed(x,y,btn)
    local rol = Session.rol or params.rol or "estudiante"
    local HH  = H()

    if params.modo == MODO_FORM then
        local px = PX()
        for i,c in ipairs(campos) do
            local fy=PY+68+(i-1)*108
            if x>=px+22 and x<=px+PW-22 and y>=fy+24 and y<=fy+68 then campoA=i return end
        end
        local my2 = PY+68+#campos*108+6
        local btnY = my2+50
        if x>=px+22 and x<=px+152 and y>=btnY and y<=btnY+42 then
            Nav.to("solicitud",{rol=rol,usuario_id=params.usuario_id,nombre=Session.nombre},- 1) return
        end
        if x>=px+PW-152 and x<=px+PW-22 and y>=btnY and y<=btnY+42 then
            errorMsg="" local valid=true
            for _,c in ipairs(campos) do
                c.error=(c.value=="") if c.error then valid=false end
            end
            if valid then
                SolicitudRepo.crear(
                    Session.usuario_id or 1,
                    campos[1].value, campos[2].value,
                    campos[3].value, campos[4].value
                )
                enviado=true errorMsg=""
            else
                errorMsg="Completa todos los campos" enviado=false
            end
        end
    else
        -- lista: solo volver
        if x>=40 and x<=160 and y>=HH-60 and y<=HH-18 then
            Nav.to("dashboard",{rol=rol,usuario_id=params.usuario_id,nombre=Session.nombre},-1)
        end
    end
end

function S.wheelmoved(x,y)
    if params.modo ~= MODO_FORM then
        scrollY = scrollY + y*30
        if scrollY > 0 then scrollY = 0 end
    end
end

function S.keypressed(key)
    if params.modo ~= MODO_FORM then return end
    if key=="tab" then campoA=(campoA%#campos)+1
    elseif key=="backspace" then
        local c=campos[campoA] if c then c.value=string.sub(c.value,1,-2) end
    end
end
function S.textinput(t)
    if params.modo ~= MODO_FORM then return end
    local c=campos[campoA] if c then c.value=c.value..t end
end

return S
