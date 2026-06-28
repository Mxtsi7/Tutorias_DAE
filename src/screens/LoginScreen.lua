-- LoginScreen.lua
-- Paso 1: elegir actor (Estudiante / Tutor / Coordinador)
-- Paso 2: lista de usuarios + crear nuevo.
--   Si el rol es "tutor" se muestra ademas un multiselect de especialidades
--   (areas_competencia) usando los ids de areas.lua.
-- Scroll con rueda del mouse en la lista de usuarios.

local Anim        = require("src.anim.Anim")
local UsuarioRepo = require("src.db.UsuarioRepo")
local Session     = require("src.session.Session")
local DB          = require("src.db.DB")
local Areas       = require("src.data.areas")

local LS = {}

local paso          = 1
local rolActivo     = nil
local usuarios      = {}
local inputNombre   = ""
local inputFocus    = false
local hover         = {}
local stag          = {}
local msgError      = ""
local pulse         = 0
local scrollY       = 0          -- scroll lista usuarios
local selAreas      = {}         -- set: selAreas[id] = true

local ROLES = {
    { rol="estudiante",  label="Estudiante",  sub="Ver y solicitar tutor\xc3\xadas",      icono="E", color={0.494,0.165,1}      },
    { rol="tutor",       label="Tutor",        sub="Registrar sesiones y avance",         icono="T", color={0.133,0.773,0.525} },
    { rol="coordinador", label="Coordinador",  sub="Gestionar y asignar tutor\xc3\xadas", icono="C", color={1,0.596,0.196}     },
}

local ROL_COLOR = {}
for _, r in ipairs(ROLES) do ROL_COLOR[r.rol] = r.color end

local function W() return love.graphics.getWidth()  end
local function H() return love.graphics.getHeight() end
local MARGIN = 60

local function rolColor()
    return ROL_COLOR[rolActivo] or {0.494,0.165,1}
end

local function recargarUsuarios()
    if rolActivo then
        usuarios = UsuarioRepo.getByRol(rolActivo)
    else
        usuarios = {}
    end
    stag    = Anim.staggerList(#usuarios, 0.06, 0.3)
    scrollY = 0
end

local function getAreasSeleccionadas()
    local lista = {}
    for _, a in ipairs(Areas) do
        if selAreas[a.id] then lista[#lista+1] = a.id end
    end
    return lista
end

-- layout constantes para paso 2
local LIST_TOP   = 148   -- y inicial de la lista de usuarios
local ROW_U      = 58    -- alto por fila de usuario
local FORM_EXTRA = 20    -- gap entre lista y formulario

-- altura total del panel de creacion (sin especialidades)
local BASE_FORM_H   = 110
-- alto extra del multiselect de especialidades
local AREA_GRID_H   = math.ceil(#Areas / 3) * 34 + 44
local FORM_H_TUTOR  = BASE_FORM_H + AREA_GRID_H
local FORM_H_OTHER  = BASE_FORM_H

local function formH()
    return rolActivo == "tutor" and FORM_H_TUTOR or FORM_H_OTHER
end

local function formY()
    -- El formulario se ubica justo debajo de la lista visible
    local listaH  = #usuarios * ROW_U
    local natural = LIST_TOP + listaH + FORM_EXTRA + scrollY
    local minY    = math.floor(H() * 0.55)
    return math.max(natural, minY)
end

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
    scrollY     = 0
    selAreas    = {}
    stag        = Anim.staggerList(#ROLES, 0.08, 0.4)
end

function LS.update(dt)
    pulse = pulse + dt * 2
    Anim.staggerUpdate(stag, dt)
    local mx, my = love.mouse.getPosition()
    hover = {}

    if paso == 1 then
        local WW    = W()
        local cardW = math.floor((WW - MARGIN*2 - 32) / 3)
        local cardH = 130
        local cardY = math.floor(H() * 0.42)
        for i = 1, #ROLES do
            local cx = MARGIN + (i-1)*(cardW+16)
            hover["rol"..i] = mx>=cx and mx<=cx+cardW and my>=cardY and my<=cardY+cardH
        end
    else
        local listX = MARGIN
        local listW = W() - MARGIN*2
        for i = 1, #usuarios do
            local ry = LIST_TOP + (i-1)*ROW_U + scrollY
            hover["u"..i] = mx>=listX and mx<=listX+listW and my>=ry and my<=ry+ROW_U-8
        end
        local btnY = H() - 78
        hover.volver = mx>=W()-MARGIN-130 and mx<=W()-MARGIN and my>=btnY and my<=btnY+44
    end
end

-- ----------------------------------------------------------------
-- PASO 1
-- ----------------------------------------------------------------
local function drawPaso1()
    local WW, HH = W(), H()

    love.graphics.setColor(0.941, 0.945, 0.961)
    love.graphics.rectangle("fill", 0, 0, WW, HH)
    love.graphics.setColor(0.494, 0.165, 1, 0.04)
    love.graphics.rectangle("fill", 0, 0, WW, HH*0.5)

    local logoY = math.floor(HH * 0.18)
    love.graphics.setColor(0.494, 0.165, 1)
    love.graphics.circle("fill", WW/2, logoY, 22)
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(Fonts.body)
    love.graphics.printf("T", WW/2-22, logoY-10, 44, "center")

    love.graphics.setColor(Colors.text)
    love.graphics.setFont(Fonts.huge)
    love.graphics.printf("TutorMate", 0, math.floor(HH*0.28), WW, "center")
    love.graphics.setFont(Fonts.body)
    love.graphics.setColor(Colors.textSub)
    love.graphics.printf("Sistema de Gesti\xc3\xb3n de Tutor\xc3\xadas DAE", 0, math.floor(HH*0.28)+58, WW, "center")
    love.graphics.setFont(Fonts.small)
    love.graphics.printf("\xc2\xbfQui\xc3\xa9n eres?", 0, math.floor(HH*0.38), WW, "center")

    local cardW = math.floor((WW - MARGIN*2 - 32) / 3)
    local cardH = 130
    local cardY = math.floor(HH * 0.42)

    for i, r in ipairs(ROLES) do
        local cx    = MARGIN + (i-1)*(cardW+16)
        local isHov = hover["rol"..i]
        local _, alpha = Anim.staggerValue(stag, i)

        love.graphics.setColor(0, 0, 0, 0.06 * alpha)
        love.graphics.rectangle("fill", cx+3, cardY+4, cardW, cardH, 16)
        local bg = isHov and {0.97,0.97,1} or {1,1,1}
        love.graphics.setColor(bg[1], bg[2], bg[3], alpha)
        love.graphics.rectangle("fill", cx, cardY, cardW, cardH, 16)
        love.graphics.setColor(r.color[1], r.color[2], r.color[3], alpha)
        love.graphics.rectangle("fill", cx, cardY, 5, cardH, 5)

        local icR  = 22
        local icCX = cx + 30 + icR
        local icCY = cardY + cardH/2
        love.graphics.setColor(r.color[1], r.color[2], r.color[3], 0.14*alpha)
        love.graphics.circle("fill", icCX, icCY, icR)
        love.graphics.setColor(r.color[1], r.color[2], r.color[3], alpha)
        love.graphics.setFont(Fonts.title)
        love.graphics.printf(r.icono, cx+30, icCY-12, icR*2, "center")

        local tx = cx + 30 + icR*2 + 14
        local tw = cardW - (30 + icR*2 + 14) - 10
        love.graphics.setColor(Colors.text[1], Colors.text[2], Colors.text[3], alpha)
        love.graphics.setFont(Fonts.body)
        love.graphics.print(r.label, tx, cardY + math.floor(cardH*0.28))
        love.graphics.setColor(Colors.textSub[1], Colors.textSub[2], Colors.textSub[3], alpha)
        love.graphics.setFont(Fonts.small)
        love.graphics.printf(r.sub, tx, cardY + math.floor(cardH*0.56), tw, "left")
        love.graphics.setColor(r.color[1], r.color[2], r.color[3], isHov and alpha or alpha*0.3)
        love.graphics.setFont(Fonts.body)
        love.graphics.print(">", cx+cardW-22, icCY-9)
    end

    love.graphics.setColor(Colors.textSub)
    love.graphics.setFont(Fonts.small)
    love.graphics.printf("Modo demo  |  Sin autenticacion  |  DAE 2026", 0, HH-28, WW, "center")
end

-- ----------------------------------------------------------------
-- PASO 2
-- ----------------------------------------------------------------
local function drawPaso2()
    local WW, HH = W(), H()
    local rc      = rolColor()
    local listW   = WW - MARGIN*2

    love.graphics.setColor(0.941, 0.945, 0.961)
    love.graphics.rectangle("fill", 0, 0, WW, HH)

    -- Header
    love.graphics.setColor(rc)
    love.graphics.rectangle("fill", 0, 0, WW, 68)
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(Fonts.title)
    local rolLabel = rolActivo and (string.upper(string.sub(rolActivo,1,1)) ..
        string.sub(rolActivo,2)) or ""
    love.graphics.printf("Seleccionar " .. rolLabel, 0, 20, WW, "center")

    love.graphics.setColor(Colors.textSub)
    love.graphics.setFont(Fonts.small)
    love.graphics.printf(
        "Elige un usuario de prueba o crea uno nuevo",
        0, 78, WW, "center")

    love.graphics.setColor(Colors.text)
    love.graphics.setFont(Fonts.body)
    love.graphics.print("Usuarios disponibles:", MARGIN, 110)

    -- Scissor para recortar la lista con scroll
    local listAreaTop = LIST_TOP - 4
    local listAreaH   = HH - listAreaTop - 90
    love.graphics.setScissor(MARGIN, listAreaTop, listW, listAreaH)

    if #usuarios == 0 then
        love.graphics.setColor(Colors.textSub)
        love.graphics.setFont(Fonts.small)
        love.graphics.print("No hay " .. (rolActivo or "") ..
            "s registrados. Crea uno abajo.", MARGIN, LIST_TOP + scrollY)
    else
        for i, u in ipairs(usuarios) do
            local ry      = LIST_TOP + (i-1)*ROW_U + scrollY
            local isHov   = hover["u"..i]
            local _, alpha = Anim.staggerValue(stag, i)

            local bg = isHov and {0.95,0.95,1} or {1,1,1}
            love.graphics.setColor(bg[1], bg[2], bg[3], alpha)
            love.graphics.rectangle("fill", MARGIN, ry, listW, ROW_U-8, 12)
            love.graphics.setColor(rc[1], rc[2], rc[3], 0.5*alpha)
            love.graphics.rectangle("fill", MARGIN, ry, 4, ROW_U-8, 4)

            love.graphics.setColor(rc[1], rc[2], rc[3], 0.15*alpha)
            love.graphics.circle("fill", MARGIN+26, ry+25, 16)
            love.graphics.setColor(rc[1], rc[2], rc[3], alpha)
            love.graphics.setFont(Fonts.body)
            love.graphics.printf(
                string.upper(string.sub(u.nombre or "?", 1, 1)),
                MARGIN+10, ry+16, 32, "center")

            love.graphics.setColor(Colors.text[1], Colors.text[2], Colors.text[3], alpha)
            love.graphics.setFont(Fonts.body)
            love.graphics.print(u.nombre or "Sin nombre", MARGIN+52, ry+8)

            love.graphics.setColor(Colors.textSub[1], Colors.textSub[2], Colors.textSub[3], alpha)
            love.graphics.setFont(Fonts.small)
            -- Mostrar especialidades si es tutor
            local infoExtra = "ID #" .. tostring(u.id) .. " | " .. (u.rol or rolActivo or "")
            if rolActivo == "tutor" and u.areas_competencia and #u.areas_competencia > 0 then
                local labs = {}
                for _, aid in ipairs(u.areas_competencia) do
                    labs[#labs+1] = Areas.getLabel(aid)
                end
                infoExtra = infoExtra .. "  |  " .. table.concat(labs, ", ")
            end
            love.graphics.print(infoExtra, MARGIN+52, ry+26)

            local bw = 100
            local bx = MARGIN + listW - bw - 12
            if isHov then
                love.graphics.setColor(rc[1], rc[2], rc[3], 0.9*alpha)
                love.graphics.rectangle("fill", bx, ry+8, bw, 30, 8)
                love.graphics.setColor(1, 1, 1, alpha)
            else
                love.graphics.setColor(rc[1], rc[2], rc[3], 0.15*alpha)
                love.graphics.rectangle("fill", bx, ry+8, bw, 30, 8)
                love.graphics.setColor(rc[1], rc[2], rc[3], alpha)
            end
            love.graphics.setFont(Fonts.small)
            love.graphics.printf("Usar este >", bx, ry+15, bw, "center")
        end
    end

    -- Barra de scroll visual (derecha)
    local totalH = #usuarios * ROW_U
    if totalH > listAreaH then
        local barH     = math.max(30, listAreaH * listAreaH / totalH)
        local barTrack = listAreaH - barH
        local maxScr   = -(totalH - listAreaH)
        local ratio    = maxScr ~= 0 and (-scrollY / -maxScr) or 0
        local barY     = listAreaTop + ratio * barTrack
        love.graphics.setColor(rc[1], rc[2], rc[3], 0.35)
        love.graphics.rectangle("fill", WW - 10, barY, 5, barH, 3)
    end

    love.graphics.setScissor()   -- quitar scissor

    -- ---- Formulario nuevo usuario ----
    local fy     = formY()
    local fh     = formH()

    love.graphics.setColor(rc[1], rc[2], rc[3], 0.08)
    love.graphics.rectangle("fill", MARGIN, fy, listW, fh, 14)
    love.graphics.setColor(rc[1], rc[2], rc[3], 0.4)
    love.graphics.rectangle("line", MARGIN+1, fy+1, listW-2, fh-2, 14)

    love.graphics.setColor(Colors.text)
    love.graphics.setFont(Fonts.body)
    love.graphics.print("+ Agregar nuevo " .. (rolActivo or ""), MARGIN+16, fy+14)

    -- Campo nombre
    local fieldX = MARGIN + 16
    local fieldY = fy + 42
    local fieldW = listW - 32 - 180
    local fieldH = 36
    local bgField = inputFocus and {1,1,1} or {0.96,0.96,0.98}
    love.graphics.setColor(bgField)
    love.graphics.rectangle("fill", fieldX, fieldY, fieldW, fieldH, 8)
    love.graphics.setColor(inputFocus and rc or Colors.border)
    love.graphics.rectangle("line", fieldX+0.5, fieldY+0.5, fieldW-1, fieldH-1, 8)

    if inputNombre == "" and not inputFocus then
        love.graphics.setColor(Colors.textSub)
        love.graphics.setFont(Fonts.body)
        love.graphics.print("Nombre del usuario", fieldX+10, fieldY+9)
    else
        love.graphics.setColor(Colors.text)
        love.graphics.setFont(Fonts.body)
        love.graphics.print(inputNombre, fieldX+10, fieldY+9)
        if inputFocus and math.floor(pulse) % 2 == 0 then
            local cx2 = fieldX + 10 + Fonts.body:getWidth(inputNombre)
            love.graphics.setColor(rc)
            love.graphics.rectangle("fill", cx2+2, fieldY+8, 2, 20)
        end
    end

    -- Boton crear
    local btnCX = fieldX + fieldW + 16
    local btnCW = listW - 32 - fieldW - 16
    love.graphics.setColor(
        hover.crear and rc or {rc[1]*0.85, rc[2]*0.85, rc[3]*0.85})
    love.graphics.rectangle("fill", btnCX, fieldY, btnCW, fieldH, 8)
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(Fonts.body)
    love.graphics.printf("Crear y usar", btnCX, fieldY+9, btnCW, "center")

    -- ---- Multiselect de especialidades (solo tutor) ----
    if rolActivo == "tutor" then
        local areaTop = fieldY + fieldH + 18
        love.graphics.setColor(Colors.text)
        love.graphics.setFont(Fonts.body)
        love.graphics.print("Especialidades del tutor:", fieldX, areaTop)
        love.graphics.setColor(Colors.textSub)
        love.graphics.setFont(Fonts.small)
        love.graphics.print("(selecciona una o varias)", fieldX + 200, areaTop + 4)

        local cols      = 3
        local chipW     = math.floor((listW - 32 - (cols-1)*8) / cols)
        local chipH     = 28
        local chipGapY  = 6
        for j, area in ipairs(Areas) do
            local col   = (j-1) % cols
            local row   = math.floor((j-1) / cols)
            local cx    = fieldX + col * (chipW + 8)
            local cy    = areaTop + 26 + row * (chipH + chipGapY)
            local activ = selAreas[area.id]

            if activ then
                love.graphics.setColor(rc[1], rc[2], rc[3], 1)
                love.graphics.rectangle("fill", cx, cy, chipW, chipH, 8)
                love.graphics.setColor(1, 1, 1)
            else
                love.graphics.setColor(Colors.border)
                love.graphics.rectangle("fill", cx, cy, chipW, chipH, 8)
                love.graphics.setColor(1, 1, 1)
                love.graphics.rectangle("fill", cx+1, cy+1, chipW-2, chipH-2, 7)
                love.graphics.setColor(Colors.text)
            end
            love.graphics.setFont(Fonts.small)
            love.graphics.printf(area.label, cx, cy+7, chipW, "center")
        end
    end

    if msgError ~= "" then
        love.graphics.setColor(Colors.red)
        love.graphics.setFont(Fonts.small)
        love.graphics.print(msgError, MARGIN+16, fy + fh - 22)
    end

    -- Boton Volver
    local btnY = H() - 78
    love.graphics.setColor(hover.volver
        and Colors.border
        or {Colors.border[1]*0.9, Colors.border[2]*0.9, Colors.border[3]*0.9})
    love.graphics.rectangle("fill", W()-MARGIN-130, btnY, 130, 44, 12)
    love.graphics.setColor(Colors.text)
    love.graphics.setFont(Fonts.body)
    love.graphics.printf("< Volver", W()-MARGIN-130, btnY+13, 130, "center")
end

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
    local nombre = inputNombre:match("^%s*(.-)%s*$")
    if nombre == "" then
        msgError = "Escribe un nombre para continuar"
        return
    end
    local uid = DB.insert("usuarios", {nombre=nombre, rol=rolActivo})
    if rolActivo == "estudiante" then
        DB.insert("estudiantes", {
            usuario_id     = uid,
            nombre         = nombre,
            area_necesidad = "",
        })
    elseif rolActivo == "tutor" then
        local areasSelec = getAreasSeleccionadas()
        DB.insert("tutores", {
            usuario_id        = uid,
            nombre            = nombre,
            areas_competencia = areasSelec,
            areas             = table.concat(areasSelec, ","),
            disponibilidad    = {},
            tutorados_activos = 0,
            limite            = 5,
            incidentes        = 0,
            activo            = true,
            estado            = "disponible",
        })
    end
    DB.save()
    usarUsuario({id=uid, nombre=nombre, rol=rolActivo})
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
        if #inputNombre < 40 then
            inputNombre = inputNombre .. text
            msgError    = ""
        end
    end
end

function LS.wheelmoved(x, y)
    if paso == 2 then
        local totalH    = #usuarios * ROW_U
        local listAreaH = H() - (LIST_TOP - 4) - 90
        if totalH > listAreaH then
            local maxScroll = -(totalH - listAreaH)
            scrollY = math.max(maxScroll, math.min(0, scrollY + y * 30))
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
                selAreas    = {}
                recargarUsuarios()
                return
            end
        end

    else
        local listW = WW - MARGIN*2

        -- Clicks en lista de usuarios
        for i, u in ipairs(usuarios) do
            local ry = LIST_TOP + (i-1)*ROW_U + scrollY
            if x>=MARGIN and x<=MARGIN+listW and y>=ry and y<=ry+ROW_U-8 then
                usarUsuario(u)
                return
            end
        end

        -- Clicks en formulario
        local fy     = formY()
        local fieldX = MARGIN + 16
        local fieldY = fy + 42
        local fieldW = listW - 32 - 180
        local fieldH = 36

        -- Foco campo nombre
        if x>=fieldX and x<=fieldX+fieldW and y>=fieldY and y<=fieldY+fieldH then
            inputFocus = true
            return
        else
            inputFocus = false
        end

        -- Boton crear
        local btnCX = fieldX + fieldW + 16
        local btnCW = listW - 32 - fieldW - 16
        if x>=btnCX and x<=btnCX+btnCW and y>=fieldY and y<=fieldY+fieldH then
            crearYUsar()
            return
        end

        -- Chips de especialidades (solo tutor)
        if rolActivo == "tutor" then
            local areaTop = fieldY + fieldH + 18
            local cols    = 3
            local chipW   = math.floor((listW - 32 - (cols-1)*8) / cols)
            local chipH   = 28
            local chipGY  = 6
            for j, area in ipairs(Areas) do
                local col = (j-1) % cols
                local row = math.floor((j-1) / cols)
                local cx  = fieldX + col * (chipW + 8)
                local cy  = areaTop + 26 + row * (chipH + chipGY)
                if x>=cx and x<=cx+chipW and y>=cy and y<=cy+chipH then
                    selAreas[area.id] = not selAreas[area.id] or nil
                    return
                end
            end
        end

        -- Boton volver
        local btnY = HH - 78
        if x>=WW-MARGIN-130 and x<=WW-MARGIN and y>=btnY and y<=btnY+44 then
            paso        = 1
            rolActivo   = nil
            inputNombre = ""
            inputFocus  = false
            msgError    = ""
            scrollY     = 0
            selAreas    = {}
            stag = Anim.staggerList(#ROLES, 0.08, 0.4)
            return
        end
    end
end

return LS
