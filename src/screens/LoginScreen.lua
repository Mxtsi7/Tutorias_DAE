local Anim        = require("src.anim.Anim")
local UsuarioRepo = require("src.db.UsuarioRepo")
local Session     = require("src.session.Session")

local LoginScreen = {}
local ROLES = {
    { label="Soy Estudiante",  sub="Ver tus tutor\xc3\xadas activas",     icon="E", color={0.494,0.165,1},     rol="estudiante" },
    { label="Soy Tutor",       sub="Registrar sesiones y avance",          icon="T", color={0.133,0.773,0.525}, rol="tutor" },
    { label="Soy Coordinador", sub="Gestionar y asignar tutor\xc3\xadas",  icon="C", color={1,0.596,0.196},    rol="coordinador" },
}
local hover  = {}
local stag   = {}
local titleA = nil

local function W() return love.graphics.getWidth() end
local function H() return love.graphics.getHeight() end

local function cardSize()
    local ww  = W()
    local gap = math.floor(ww * 0.02)
    local cw  = math.floor((ww * 0.80) / #ROLES - gap)
    local ch  = math.max(90, math.floor(H() * 0.13))
    return cw, ch, gap
end

local function startX()
    local cw, ch, gap = cardSize()
    local total = #ROLES * cw + (#ROLES-1)*gap
    return math.floor((W() - total) / 2)
end

local function cardY()
    return math.floor(H() * 0.62)
end

function LoginScreen.load()
    hover  = {}
    stag   = Anim.staggerList(#ROLES, 0.08, 0.45)
    titleA = Anim.new(0, 1, 0.6, "easeOut")
end

function LoginScreen.update(dt)
    titleA:update(dt)
    Anim.staggerUpdate(stag, dt)
    local mx, my   = love.mouse.getPosition()
    local cw,ch,gap = cardSize()
    local sx       = startX()
    local cy       = cardY()
    for i = 1, #ROLES do
        local cx = sx + (i-1)*(cw+gap)
        hover[i] = mx>=cx and mx<=cx+cw and my>=cy and my<=cy+ch
    end
end

function LoginScreen.draw()
    local ww,hh    = W(),H()
    local lAlpha   = titleA:value()
    local cw,ch,gap = cardSize()
    local sx       = startX()
    local cy       = cardY()

    love.graphics.setColor(0.941,0.945,0.961)
    love.graphics.rectangle("fill",0,0,ww,hh)
    love.graphics.setColor(0.494,0.165,1,0.04)
    love.graphics.rectangle("fill",0,0,ww,hh*0.5)
    love.graphics.setColor(0.494,0.165,1,0.06)
    love.graphics.circle("fill",ww*0.12,hh*0.22,ww*0.17)
    love.graphics.setColor(0.133,0.773,0.525,0.05)
    love.graphics.circle("fill",ww*0.88,hh*0.82,ww*0.13)

    local logoY = math.floor(hh*0.22)
    local logoR = math.floor(math.min(ww,hh)*0.045)
    love.graphics.setColor(0.494,0.165,1,lAlpha)
    love.graphics.circle("fill",ww/2,logoY,logoR)
    love.graphics.setColor(1,1,1,lAlpha)
    love.graphics.setFont(Fonts.title)
    love.graphics.printf("T",ww/2-logoR,logoY-logoR*0.55,logoR*2,"center")

    local titleY = math.floor(hh*0.37)
    love.graphics.setColor(Colors.text[1],Colors.text[2],Colors.text[3],lAlpha)
    love.graphics.setFont(Fonts.huge)
    love.graphics.printf("TutorMate",0,titleY,ww,"center")
    love.graphics.setFont(Fonts.body)
    love.graphics.setColor(Colors.textSub[1],Colors.textSub[2],Colors.textSub[3],lAlpha)
    love.graphics.printf("Sistema de Gesti\xc3\xb3n de Tutor\xc3\xadas DAE",0,titleY+58,ww,"center")
    love.graphics.printf("Selecciona tu rol para continuar",0,titleY+82,ww,"center")

    for i,r in ipairs(ROLES) do
        local cx      = sx+(i-1)*(cw+gap)
        local offY,alpha = Anim.staggerValue(stag,i)
        local ty      = cy+offY
        love.graphics.setColor(0,0,0,0.07*alpha)
        love.graphics.rectangle("fill",cx+3,ty+5,cw,ch,16)
        love.graphics.setColor(1,1,1,alpha)
        love.graphics.rectangle("fill",cx,ty,cw,ch,16)
        love.graphics.setColor(r.color[1],r.color[2],r.color[3],alpha)
        love.graphics.rectangle("fill",cx,ty,6,ch,5)
        if hover[i] then
            love.graphics.setColor(r.color[1],r.color[2],r.color[3],0.07)
            love.graphics.rectangle("fill",cx,ty,cw,ch,16)
        end
        local iconR  = math.floor(ch*0.28)
        local iconCX = cx+24+iconR
        local iconCY = ty+ch/2
        love.graphics.setColor(r.color[1],r.color[2],r.color[3],0.15*alpha)
        love.graphics.circle("fill",iconCX,iconCY,iconR)
        love.graphics.setColor(r.color[1],r.color[2],r.color[3],alpha)
        love.graphics.setFont(Fonts.body)
        love.graphics.printf(r.icon,cx+24,iconCY-9,iconR*2,"center")
        local tx = cx+24+iconR*2+14
        love.graphics.setColor(Colors.text[1],Colors.text[2],Colors.text[3],alpha)
        love.graphics.setFont(Fonts.body)
        love.graphics.print(r.label,tx,ty+math.floor(ch*0.22))
        love.graphics.setColor(Colors.textSub[1],Colors.textSub[2],Colors.textSub[3],alpha)
        love.graphics.setFont(Fonts.small)
        love.graphics.print(r.sub,tx,ty+math.floor(ch*0.56))
        love.graphics.setColor(r.color[1],r.color[2],r.color[3],hover[i] and alpha or alpha*0.35)
        love.graphics.setFont(Fonts.body)
        love.graphics.print(">",cx+cw-28,ty+ch/2-9)
    end

    love.graphics.setColor(Colors.textSub)
    love.graphics.setFont(Fonts.small)
    love.graphics.printf("v1.0  \xc2\xb7  DAE 2026",0,hh-28,ww,"center")
end

function LoginScreen.mousepressed(x,y,btn)
    local cw,ch,gap = cardSize()
    local sx = startX()
    local cy = cardY()
    for i,r in ipairs(ROLES) do
        local cx = sx+(i-1)*(cw+gap)
        if x>=cx and x<=cx+cw and y>=cy and y<=cy+ch then
            -- Buscar primer usuario con ese rol en la BD
            local rows = UsuarioRepo.getByRol(r.rol)
            local uid  = rows[1] and rows[1].id or 1
            local nombre = rows[1] and rows[1].nombre or r.label
            Session.set(uid, nombre, r.rol)
            Nav.to("dashboard", { rol=r.rol, usuario_id=uid, nombre=nombre }, 1)
        end
    end
end

return LoginScreen
