-- DB.lua: persistencia simple usando love.filesystem (JSON-like via tablas Lua)
-- Sin dependencias externas, funciona en Windows/Mac/Linux con LOVE 11+

local DB = {}
DB._data = {}
DB._FILE = "tutorias_data.lua"

-- Serializa tabla Lua a string (sin dependencias)
local function serialize(val, indent)
    indent = indent or ""
    local t = type(val)
    if t == "number"  then return tostring(val)
    elseif t == "boolean" then return tostring(val)
    elseif t == "string"  then return string.format("%q", val)
    elseif t == "table" then
        local inner = indent .. "  "
        local parts = {}
        local isArr = #val > 0
        if isArr then
            for _, v in ipairs(val) do
                parts[#parts+1] = inner .. serialize(v, inner)
            end
            return "{\n" .. table.concat(parts, ",\n") .. "\n" .. indent .. "}"
        else
            for k, v in pairs(val) do
                parts[#parts+1] = inner .. "[" .. string.format("%q", tostring(k)) .. "] = " .. serialize(v, inner)
            end
            return "{\n" .. table.concat(parts, ",\n") .. "\n" .. indent .. "}"
        end
    end
    return "nil"
end

function DB.open()
    if love.filesystem.getInfo(DB._FILE) then
        local chunk = love.filesystem.read(DB._FILE)
        local fn, err = load("return " .. chunk)
        if fn then
            DB._data = fn() or {}
        else
            DB._data = {}
        end
    else
        DB._data = {}
    end
    -- Inicializar tablas si no existen
    local tables = {"usuarios","tutores","estudiantes","tutorias","sesiones","solicitudes"}
    for _, tbl in ipairs(tables) do
        if not DB._data[tbl] then DB._data[tbl] = {} end
        if not DB._data["_seq_"..tbl] then DB._data["_seq_"..tbl] = 0 end
    end
    require("src.db.Seed").run()
    DB.save()
end

function DB.save()
    love.filesystem.write(DB._FILE, serialize(DB._data))
end

function DB.close()
    DB.save()
end

-- Inserta un registro en una tabla y retorna el id generado
function DB.insert(tbl, record)
    DB._data["_seq_"..tbl] = (DB._data["_seq_"..tbl] or 0) + 1
    record.id = DB._data["_seq_"..tbl]
    DB._data[tbl][#DB._data[tbl]+1] = record
    return record.id
end

-- Retorna todos los registros de una tabla
function DB.all(tbl)
    return DB._data[tbl] or {}
end

-- Retorna registros que cumplen filtro (funcion predicado)
function DB.where(tbl, predicate)
    local result = {}
    for _, row in ipairs(DB._data[tbl] or {}) do
        if predicate(row) then result[#result+1] = row end
    end
    return result
end

-- Retorna primer registro que cumple filtro
function DB.find(tbl, predicate)
    for _, row in ipairs(DB._data[tbl] or {}) do
        if predicate(row) then return row end
    end
    return nil
end

-- Actualiza registros que cumplen filtro
function DB.update(tbl, predicate, changes)
    for _, row in ipairs(DB._data[tbl] or {}) do
        if predicate(row) then
            for k, v in pairs(changes) do row[k] = v end
        end
    end
end

return DB
