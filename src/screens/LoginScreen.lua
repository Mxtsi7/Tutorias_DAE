-- LoginScreen.lua  (rediseño sin autenticación)
-- Paso 1: elegir actor (Estudiante / Tutor / Coordinador)
-- Paso 2: lista de usuarios de ese rol + crear uno nuevo con solo nombre
-- Al seleccionar un usuario la app inicia sesión y navega al dashboard.

local Anim        = require("src.anim.Anim")
local UsuarioRepo = require("src.db.UsuarioRepo")
local Session     = require("src.session.Session")
local DB          = require("src.db.DB")

local LS = {}

-- Estado interno
local paso        = 1        -- 1 = elegir actor | 2 = elegir/crear usuario
local rolActivo   = nil      -- "estudiante" | "tutor" | "coordinador"
local usuarios    = {}       -- lista filtrada por rol
local inputNombre = ""      -- campo de texto para nuevo usuario
local inputFocus  = false
local hover       = {}
local stag        = {}
local msgError    = ""
local pulse       = 0

local ROLES = {
    { rol="estudiante",  label="Estudiante",  sub="Ver y solicitar tutor\xc3\xadas",       icono="E", color={0.494,0.165,1}      },
    { rol="tutor",       label="Tutor",        sub="Registrar sesiones y avance",          icono="T", color={0.133,0.773,0.525} },
    { rol="coordinador", label="Coordinador",  sub="Gestionar y asignar tutor\xc3\xadas",  icono="C", color={1,0.596,0.196}     },
}

local ROL_COLOR = {}
for _, r in ipairs(ROLES) do ROL_COLOR[r.rol] = r.color end

local function W() return love.graphics.getWidth()  end
local function H() return love.graphics.getHeight() end
local MARGIN = 60

-- ----------------------------------------------------------------
-- helpers de layout
-- ----------------------------------------------------------------
local function rolColor()
    return ROL_COLOR[rolActivo] or {0.494,0.165,1}
end

local function recargarUsuarios()
    if rolActivo then
        usuarios = UsuarioRepo.getByRol(rolActivo)
    else
        usuarios = {}
    end
    stag = Anim.staggerList(#usuarios, 0.06, 0.3)
end

-- ----------------------------------------------------------------
-- ciclo de vida
-- ----------------------------------------------------------------
function LS.load()
    paso        = 1
    rolActivo   = nil
    usuarios    = {}
    inputNombre = ""
    inputFocus  = false
    hover       = {}
    msgError    = ""
    pulse       = 0
    stag        = Anim.staggerList(#ROLES, 0.08, 0.4)
end

function LS.update(dt)
    pulse = pulse + dt * 2
    Anim.staggerUpdate(stag, dt)
    local mx, my = love.mouse.getPosition()
    hover = {}

    if paso == 1 then
        -- hover sobre cards de rol
        local WW   = W()
        local cardW = math.floor((WW - MARGIN*2 - 32) / 3)
        local cardH = 130
        local cardY = math.floor(H() * 0.42)
        for i = 1, #ROLES do
            local cx = MARGIN + (i-1)*(cardW+16)
            hover["rol"..i] = mx>=cx and mx<=cx+cardW and my>=cardY and my<=cardY+cardH
        end

    else -- paso 2
        -- hover sobre filas de usuario
        local listX = MARGIN
        local listW = W() - MARGIN*2
        for i = 1, #usuarios do
            local ry = 180 + (i-1)*58
            hover["u"..i] = mx>=listX and mx<=listX+listW and my>=ry and my<=ry+50
        end
        -- hover sobre boton crear
        local btnY = H() - 78
        hover.crear = mx>=MARGIN and mx<=MARGIN+160 and my>=btnY and my<=btnY+44
        -- hover sobre volver
        hover.volver = mx>=W()-MARGIN-130 and mx<=W()-MARGIN and my>=btnY and my<=btnY+44
    end
end

-- ----------------------------------------------------------------
-- PASO 1: dibuja la pantalla de elección de actor
-- ----------------------------------------------------------------
local function drawPaso1()
    local WW, HH = W(), H()

    -- Fondo
    love.graphics.setColor(0.941, 0.945, 0.961)
    love.graphics.rectangle("fill", 0, 0, WW, HH)

    -- Decoración de fondo suave
    love.graphics.setColor(0.494, 0.165, 1, 0.04)
    love.graphics.rectangle("fill", 0, 0, WW, HH*0.5)

    -- Logo
    local logoY = math.floor(HH * 0.18)
    love.graphics.setColor(0.494, 0.165, 1)
    love.graphics.circle("fill", WW/2, logoY, 22)
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(Fonts.body)
    love.graphics.printf("T", WW/2-22, logoY-10, 44, "center")

    -- Título
    love.graphics.setColor(Colors.text)
    love.graphics.setFont(Fonts.huge)
    love.graphics.printf("TutorMate", 0, math.floor(HH*0.28), WW, "center")
    love.graphics.setFont(Fonts.body)
    love.graphics.setColor(Colors.textSub)
    love.graphics.printf("Sistema de Gesti\xc3\xb3n de Tutor\xc3\xadas DAE", 0, math.floor(HH*0.28)+58, WW, "center")

    -- Etiqueta de paso
    love.graphics.setColor(Colors.textSub)
    love.graphics.setFont(Fonts.small)
    love.graphics.printf("\xc2\xbfQui\xc3\xa9n eres?", 0, math.floor(HH*0.38), WW, "center")

    -- Cards de rol
    local cardW = math.floor((WW - MARGIN*2 - 32) / 3)
    local cardH = 130
    local cardY = math.floor(HH * 0.42)

    for i, r in ipairs(ROLES) do
        local cx     = MARGIN + (i-1)*(cardW+16)
        local isHov  = hover["rol"..i]
        local _, alpha = Anim.staggerValue(stag, i)

        -- Sombra
        love.graphics.setColor(0, 0, 0, 0.06 * alpha)
        love.graphics.rectangle("fill", cx+3, cardY+4, cardW, cardH, 16)
        -- Fondo card
        local bg = isHov and {0.97,0.97,1} or {1,1,1}
        love.graphics.setColor(bg[1], bg[2], bg[3], alpha)
        love.graphics.rectangle("fill", cx, cardY, cardW, cardH, 16)
        -- Acento lateral
        love.graphics.setColor(r.color[1], r.color[2], r.color[3], alpha)
        love.graphics.rectangle("fill", cx, cardY, 5, cardH, 5)

        -- Ícono circular
        local icR  = 22
        local icCX = cx + 30 + icR
        local icCY = cardY + cardH/2
        love.graphics.setColor(r.color[1], r.color[2], r.color[3], 0.14*alpha)
        love.graphics.circle("fill", icCX, icCY, icR)
        love.graphics.setColor(r.color[1], r.color[2], r.color[3], alpha)
        love.graphics.setFont(Fonts.title)
        love.graphics.printf(r.icono, cx+30, icCY-12, icR*2, "center")

        -- Texto
        local tx = cx + 30 + icR*2 + 14
        local tw = cardW - (30 + icR*2 + 14) - 10
        love.graphics.setColor(Colors.text[1], Colors.text[2], Colors.text[3], alpha)
        love.graphics.setFont(Fonts.body)
        love.graphics.print(r.label, tx, cardY + math.floor(cardH*0.28))
        love.graphics.setColor(Colors.textSub[1], Colors.textSub[2], Colors.textSub[3], alpha)
        love.graphics.setFont(Fonts.small)
        love.graphics.printf(r.sub, tx, cardY + math.floor(cardH*0.56), tw, "left")

        -- Flecha hover
        love.graphics.setColor(r.color[1], r.color[2], r.color[3],
            isHov and alpha or alpha*0.3)
        love.graphics.setFont(Fonts.body)
        love.graphics.print(">", cx+cardW-22, icCY-9)
    end

    -- Footer
    love.graphics.setColor(Colors.textSub)
    love.graphics.setFont(Fonts.small)
    love.graphics.printf("Modo demo  \xc2\xb7  Sin autenticaci\xc3\xb3n  \xc2\xb7  DAE 2026",
        0, HH-28, WW, "center")
end

-- ----------------------------------------------------------------
-- PASO 2: dibuja la lista de usuarios + formulario de creación
-- ----------------------------------------------------------------
local function drawPaso2()
    local WW, HH = W(), H()
    local rc      = rolColor()
    local listW   = WW - MARGIN*2

    -- Fondo
    love.graphics.setColor(0.941, 0.945, 0.961)
    love.graphics.rectangle("fill", 0, 0, WW, HH)

    -- Header de color
    love.graphics.setColor(rc)
    love.graphics.rectangle("fill", 0, 0, WW, 68)
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(Fonts.title)
    local rolLabel = rolActivo and (string.upper(string.sub(rolActivo,1,1)) ..
        string.sub(rolActivo,2)) or ""
    love.graphics.printf("Seleccionar " .. rolLabel, 0, 20, WW, "center")

    -- Subtitulo
    love.graphics.setColor(Colors.textSub)
    love.graphics.setFont(Fonts.small)
    love.graphics.printf(
        "Elige un usuario de prueba o crea uno nuevo solo con su nombre",
        0, 78, WW, "center")

    -- ---- LISTA DE USUARIOS ----
    love.graphics.setColor(Colors.text)
    love.graphics.setFont(Fonts.body)
    love.graphics.print("Usuarios disponibles:", MARGIN, 110)

    if #usuarios == 0 then
        love.graphics.setColor(Colors.textSub)
        love.graphics.setFont(Fonts.small)
        love.graphics.print("No hay " .. (rolActivo or "") ..
            "s registrados. Crea uno abajo.", MARGIN, 148)
    else
        Anim.staggerUpdate(stag, 0)  -- ya actualizado en update()
        for i, u in ipairs(usuarios) do
            local ry      = 140 + (i-1)*58
            local isHov   = hover["u"..i]
            local _, alpha = Anim.staggerValue(stag, i)

            -- Fondo fila
            local bg = isHov and {0.95,0.95,1} or {1,1,1}
            love.graphics.setColor(bg[1], bg[2], bg[3], alpha)
            love.graphics.rectangle("fill", MARGIN, ry, listW, 50, 12)
            love.graphics.setColor(rc[1], rc[2], rc[3], 0.5*alpha)
            love.graphics.rectangle("fill", MARGIN, ry, 4, 50, 4)

            -- Avatar inicial
            love.graphics.setColor(rc[1], rc[2], rc[3], 0.15*alpha)
            love.graphics.circle("fill", MARGIN+26, ry+25, 16)
            love.graphics.setColor(rc[1], rc[2], rc[3], alpha)
            love.graphics.setFont(Fonts.body)
            love.graphics.printf(
                string.upper(string.sub(u.nombre or "?", 1, 1)),
                MARGIN+10, ry+16, 32, "center")

            -- Nombre e ID
            love.graphics.setColor(Colors.text[1], Colors.text[2], Colors.text[3], alpha)
            love.graphics.setFont(Fonts.body)
            love.graphics.print(u.nombre or "Sin nombre", MARGIN+52, ry+10)
            love.graphics.setColor(Colors.textSub[1], Colors.textSub[2], Colors.textSub[3], alpha)
            love.graphics.setFont(Fonts.small)
            love.graphics.print("ID #" .. tostring(u.id) ..
                "  \xc2\xb7  " .. (u.rol or rolActivo or ""),
                MARGIN+52, ry+28)

            -- Boton seleccionar
            local bw = 100
            local bx = MARGIN + listW - bw - 12
            if isHov then
                love.graphics.setColor(rc[1], rc[2], rc[3], 0.9*alpha)
                love.graphics.rectangle("fill", bx, ry+10, bw, 30, 8)
                love.graphics.setColor(1, 1, 1, alpha)
            else
                love.graphics.setColor(rc[1], rc[2], rc[3], 0.15*alpha)
                love.graphics.rectangle("fill", bx, ry+10, bw, 30, 8)
                love.graphics.setColor(rc[1], rc[2], rc[3], alpha)
            end
            love.graphics.setFont(Fonts.small)
            love.graphics.printf("Usar este >", bx, ry+17, bw, "center")
        end
    end

    -- ---- FORMULARIO NUEVO USUARIO ----
    local formY = math.max(140 + #usuarios*58 + 20,
        math.floor(HH * 0.55))

    love.graphics.setColor(rc[1], rc[2], rc[3], 0.08)
    love.graphics.rectangle("fill", MARGIN, formY, listW, 110, 14)
    love.graphics.setColor(rc[1], rc[2], rc[3], 0.4)
    love.graphics.rectangle("line", MARGIN+1, formY+1, listW-2, 108, 14)

    love.graphics.setColor(Colors.text)
    love.graphics.setFont(Fonts.body)
    love.graphics.print("+ Agregar nuevo " .. (rolActivo or ""),
        MARGIN+16, formY+14)

    -- Campo de texto nombre
    local fieldX = MARGIN + 16
    local fieldY = formY + 42
    local fieldW = listW - 32 - 180
    local fieldH = 36
    local bgField = inputFocus
        and {1,1,1} or {0.96,0.96,0.98}
    love.graphics.setColor(bgField)
    love.graphics.rectangle("fill", fieldX, fieldY, fieldW, fieldH, 8)
    love.graphics.setColor(inputFocus and rc or Colors.border)
    love.graphics.rectangle("line", fieldX+0.5, fieldY+0.5,
        fieldW-1, fieldH-1, 8)

    if inputNombre == "" and not inputFocus then
        love.graphics.setColor(Colors.textSub)
        love.graphics.setFont(Fonts.body)
        love.graphics.print("Nombre del usuario", fieldX+10, fieldY+9)
    else
        love.graphics.setColor(Colors.text)
        love.graphics.setFont(Fonts.body)
        love.graphics.print(inputNombre, fieldX+10, fieldY+9)
        -- cursor parpadeante
        if inputFocus and math.floor(pulse) % 2 == 0 then
            local cx2 = fieldX + 10 + Fonts.body:getWidth(inputNombre)
            love.graphics.setColor(rc)
            love.graphics.rectangle("fill", cx2+2, fieldY+8, 2, 20)
        end
    end

    -- Boton Crear
    local btnCX = fieldX + fieldW + 16
    local btnCW = listW - 32 - fieldW - 16
    local isHovCrear = hover.crear
    love.graphics.setColor(
        isHovCrear and rc
        or {rc[1]*0.85, rc[2]*0.85, rc[3]*0.85})
    love.graphics.rectangle("fill", btnCX, fieldY, btnCW, fieldH, 8)
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(Fonts.body)
    love.graphics.printf("Crear y usar", btnCX, fieldY+9, btnCW, "center")

    -- Mensaje error
    if msgError ~= "" then
        love.graphics.setColor(Colors.red)
        love.graphics.setFont(Fonts.small)
        love.graphics.print(msgError, MARGIN+16, formY+86)
    end

    -- ---- BOTON VOLVER ----
    local btnY = HH - 78
    love.graphics.setColor(hover.volver
        and Colors.border
        or {Colors.border[1]*0.9, Colors.border[2]*0.9, Colors.border[3]*0.9})
    love.graphics.rectangle("fill", W()-MARGIN-130, btnY, 130, 44, 12)
    love.graphics.setColor(Colors.text)
    love.graphics.setFont(Fonts.body)
    love.graphics.printf("\xe2\x86\x90 Volver", W()-MARGIN-130, btnY+13, 130, "center")
end

-- ----------------------------------------------------------------
-- API pública
-- ----------------------------------------------------------------
function LS.draw()
    if paso == 1 then drawPaso1()
    else              drawPaso2() end
end

local function usarUsuario(u)
    Session.set(u.id, u.nombre, u.rol)
    Nav.to("dashboard", {
        rol        = u.rol,
        usuario_id = u.id,
        nombre     = u.nombre,
    }, 1)
end

local function crearYUsar()
    local nombre = inputNombre:match("^%s*(.-)%s*$")  -- trim
    if nombre == "" then
        msgError = "Escribe un nombre para continuar"
        return
    end
    -- Insertar usuario
    local uid = DB.insert("usuarios", {nombre=nombre, rol=rolActivo})
    -- Si es estudiante o tutor, crear entidad correspondiente
    if rolActivo == "estudiante" then
        DB.insert("estudiantes", {
            usuario_id     = uid,
            nombre         = nombre,
            area_necesidad = "",
        })
    elseif rolActivo == "tutor" then
        DB.insert("tutores", {
            usuario_id        = uid,
            nombre            = nombre,
            areas             = "",
            disponibilidad    = "",
            tutorados_activos = 0,
            limite            = 5,
            incidentes        = 0,
            activo            = true,
            estado            = "disponible",
        })
    end
    DB.save()
    local u = {id=uid, nombre=nombre, rol=rolActivo}
    usarUsuario(u)
end

function LS.keypressed(key)
    if paso == 2 and inputFocus then
        if key == "backspace" then
            inputNombre = string.sub(inputNombre, 1, -2)
            msgError = ""
        elseif key == "return" or key == "kpenter" then
            crearYUsar()
        end
    end
end

function LS.textinput(text)
    if paso == 2 and inputFocus then
        -- Limitar a 40 caracteres
        if #inputNombre < 40 then
            inputNombre = inputNombre .. text
            msgError    = ""
        end
    end
end

function LS.mousepressed(x, y, btn)
    if btn ~= 1 then return end
    local WW, HH = W(), H()

    if paso == 1 then
        local cardW = math.floor((WW - MARGIN*2 - 32) / 3)
        local cardH = 130
        local cardY = math.floor(HH * 0.42)
        for i, r in ipairs(ROLES) do
            local cx = MARGIN + (i-1)*(cardW+16)
            if x>=cx and x<=cx+cardW and y>=cardY and y<=cardY+cardH then
                rolActivo   = r.rol
                paso        = 2
                inputNombre = ""
                inputFocus  = false
                msgError    = ""
                recargarUsuarios()
                return
            end
        end

    else -- paso 2
        local listW = WW - MARGIN*2

        -- Click en fila de usuario
        for i, u in ipairs(usuarios) do
            local ry = 140 + (i-1)*58
            if x>=MARGIN and x<=MARGIN+listW and y>=ry and y<=ry+50 then
                usarUsuario(u)
                return
            end
        end

        -- Click en campo de texto
        local formY = math.max(140 + #usuarios*58 + 20,
            math.floor(HH * 0.55))
        local fieldX = MARGIN + 16
        local fieldY = formY + 42
        local fieldW = listW - 32 - 180
        local fieldH = 36
        if x>=fieldX and x<=fieldX+fieldW
            and y>=fieldY and y<=fieldY+fieldH then
            inputFocus = true
            return
        else
            inputFocus = false
        end

        -- Click en boton Crear y usar
        local btnCX = fieldX + fieldW + 16
        local btnCW = listW - 32 - fieldW - 16
        if x>=btnCX and x<=btnCX+btnCW
            and y>=fieldY and y<=fieldY+fieldH then
            crearYUsar()
            return
        end

        -- Click en Volver
        local btnY = HH - 78
        if x>=WW-MARGIN-130 and x<=WW-MARGIN
            and y>=btnY and y<=btnY+44 then
            paso        = 1
            rolActivo   = nil
            inputNombre = ""
            inputFocus  = false
            msgError    = ""
            stag = Anim.staggerList(#ROLES, 0.08, 0.4)
            return
        end
    end
end

return LS
