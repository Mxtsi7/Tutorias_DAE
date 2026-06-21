-- DB.lua  –  persistencia con love.filesystem
-- Guarda y lee un archivo Lua serializado en el directorio de saves de LOVE.
-- API publica identica para todos los Repos, Handlers y Screens:
--   DB.open()                        abre / crea la BD en memoria
--   DB.insert(tbl, record) -> id     inserta y retorna el id generado
--   DB.all(tbl)            -> []     todos los registros de la tabla
--   DB.where(tbl, fn)      -> []     registros que cumplen predicado
--   DB.find(tbl, fn)       -> row    primer registro que cumple predicado
--   DB.update(tbl, fn, changes)      actualiza registros que cumplen predicado
--   DB.save()                        persiste al archivo
--   DB.close()                       guarda y libera

local DB = {}
DB._data = {}
DB._FILE = "tutorias_data.lua"

-- ----------------------------------------------------------------
-- Serializacion Lua (sin dependencias externas)
-- ----------------------------------------------------------------
local function serialize(val, indent)
    indent = indent or ""
    local t = type(val)
    if t == "number"  then return tostring(val)
    elseif t == "boolean" then return tostring(val)
    elseif t == "string"  then return string.format("%q", val)
    elseif t == "table" then
        local inner = indent .. "  "
        local parts = {}
        local isArr = (#val > 0)
        if isArr then
            for _, v in ipairs(val) do
                parts[#parts+1] = inner .. serialize(v, inner)
            end
        else
            for k, v in pairs(val) do
                parts[#parts+1] = inner ..
                    "[" .. string.format("%q", tostring(k)) .. "] = " ..
                    serialize(v, inner)
            end
        end
        return "{\n" .. table.concat(parts, ",\n") .. "\n" .. indent .. "}"
    end
    return "nil"
end

-- ----------------------------------------------------------------
-- Tablas que maneja la app
-- ----------------------------------------------------------------
local TABLES = {
    "usuarios", "tutores", "estudiantes",
    "tutorias", "sesiones", "solicitudes",
}

-- ----------------------------------------------------------------
-- DB.open()  –  carga el archivo o crea la estructura vacia
-- ----------------------------------------------------------------
function DB.open()
    if love.filesystem.getInfo(DB._FILE) then
        local chunk = love.filesystem.read(DB._FILE)
        local fn, err = load("return " .. chunk)
        if fn then
            local ok, data = pcall(fn)
            DB._data = (ok and data) or {}
        else
            print("[DB] Error al leer archivo: " .. tostring(err))
            DB._data = {}
        end
    else
        DB._data = {}
    end

    -- Inicializar tablas y secuencias si no existen
    for _, tbl in ipairs(TABLES) do
        if not DB._data[tbl]           then DB._data[tbl]            = {} end
        if not DB._data["_seq_"..tbl]  then DB._data["_seq_"..tbl]  = 0  end
    end

    require("src.db.Seed").run()
    DB.save()
end

-- ----------------------------------------------------------------
-- DB.save()  –  persiste al archivo
-- ----------------------------------------------------------------
function DB.save()
    love.filesystem.write(DB._FILE, serialize(DB._data))
end

-- ----------------------------------------------------------------
-- DB.close()
-- ----------------------------------------------------------------
function DB.close()
    DB.save()
end

-- ----------------------------------------------------------------
-- DB.insert(tbl, record) -> id
-- ----------------------------------------------------------------
function DB.insert(tbl, record)
    DB._data["_seq_"..tbl] = (DB._data["_seq_"..tbl] or 0) + 1
    record.id = DB._data["_seq_"..tbl]
    DB._data[tbl][#DB._data[tbl]+1] = record
    return record.id
end

-- ----------------------------------------------------------------
-- DB.all(tbl) -> tabla
-- ----------------------------------------------------------------
function DB.all(tbl)
    return DB._data[tbl] or {}
end

-- ----------------------------------------------------------------
-- DB.where(tbl, predicate) -> tabla
-- ----------------------------------------------------------------
function DB.where(tbl, predicate)
    local result = {}
    for _, row in ipairs(DB._data[tbl] or {}) do
        if predicate(row) then result[#result+1] = row end
    end
    return result
end

-- ----------------------------------------------------------------
-- DB.find(tbl, predicate) -> fila o nil
-- ----------------------------------------------------------------
function DB.find(tbl, predicate)
    for _, row in ipairs(DB._data[tbl] or {}) do
        if predicate(row) then return row end
    end
    return nil
end

-- ----------------------------------------------------------------
-- DB.update(tbl, fn, changes)
-- ----------------------------------------------------------------
function DB.update(tbl, predicate, changes)
    for _, row in ipairs(DB._data[tbl] or {}) do
        if predicate(row) then
            for k, v in pairs(changes) do row[k] = v end
        end
    end
end

return DB
