-- DB.lua  –  capa de persistencia SQLite3
-- Reemplaza love.filesystem por lsqlite3 manteniendo la misma API
-- publica que usan todos los Repos, Handlers y Screens:
--   DB.open()                        abre / crea la BD
--   DB.insert(tbl, record) -> id     inserta y retorna el id
--   DB.all(tbl)            -> []     todos los registros
--   DB.where(tbl, fn)      -> []     filtro por predicado
--   DB.find(tbl, fn)       -> row    primer match
--   DB.update(tbl, fn, changes)      actualiza en memoria + BD
--   DB.save()                        no-op (compatibilidad)
--   DB.close()                       cierra la conexion

local sqlite3 = require("lsqlite3")

local DB = {}
DB._db    = nil     -- conexion SQLite
DB._cache = {}      -- cache en memoria: DB._cache[tbl] = { {id=N, ...}, ... }

-- ----------------------------------------------------------------
-- Serializacion / deserializacion  (sin dependencias externas)
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

local function deserialize(str)
    if not str or str == "" then return {} end
    local fn, err = load("return " .. str)
    if fn then
        local ok, val = pcall(fn)
        if ok then return val end
    end
    return {}
end

-- ----------------------------------------------------------------
-- Tablas que maneja la app
-- ----------------------------------------------------------------
local TABLES = {
    "usuarios", "tutores", "estudiantes",
    "tutorias", "sesiones", "solicitudes",
}

-- ----------------------------------------------------------------
-- DB.open()  –  abre la BD, crea tablas si no existen, carga cache
-- ----------------------------------------------------------------
function DB.open()
    -- love.filesystem.getSaveDirectory() da la ruta persistente de LOVE
    local path = love.filesystem.getSaveDirectory() .. "/tutorias.db"
    DB._db = sqlite3.open(path)
    assert(DB._db, "No se pudo abrir la base de datos SQLite: " .. path)

    -- Una sola tabla generica por entidad:
    --   id   INTEGER PRIMARY KEY AUTOINCREMENT
    --   data TEXT    (registro completo serializado como string Lua)
    -- Indices opcionales para las consultas mas frecuentes se agregan abajo.
    for _, tbl in ipairs(TABLES) do
        DB._db:exec(string.format(
            [[CREATE TABLE IF NOT EXISTS "%s" (
                id   INTEGER PRIMARY KEY AUTOINCREMENT,
                data TEXT NOT NULL DEFAULT '{}'
            )]],
            tbl
        ))
        DB._cache[tbl] = {}
    end

    -- Cargar cache desde la BD
    for _, tbl in ipairs(TABLES) do
        local stmt = DB._db:prepare(
            string.format('SELECT id, data FROM "%s" ORDER BY id', tbl))
        if stmt then
            for row in stmt:nrows() do
                local rec = deserialize(row.data)
                rec.id = row.id
                DB._cache[tbl][#DB._cache[tbl]+1] = rec
            end
            stmt:finalize()
        end
    end

    -- Ejecutar seed solo si la BD esta vacia
    require("src.db.Seed").run()
end

-- ----------------------------------------------------------------
-- DB.insert(tbl, record) -> id
-- ----------------------------------------------------------------
function DB.insert(tbl, record)
    -- Serializar sin el id (lo asigna SQLite)
    local tmp = {}
    for k, v in pairs(record) do tmp[k] = v end
    tmp.id = nil
    local data = serialize(tmp)

    local stmt = DB._db:prepare(
        string.format('INSERT INTO "%s" (data) VALUES (?)', tbl))
    assert(stmt, "[DB.insert] prepare fallo en tabla: " .. tbl)
    stmt:bind(1, data)
    stmt:step()
    stmt:finalize()

    local id = DB._db:last_insert_rowid()
    record.id = id

    -- Actualizar data con el id ya conocido y hacer UPDATE
    local data2 = serialize(record)
    local stmt2 = DB._db:prepare(
        string.format('UPDATE "%s" SET data=? WHERE id=?', tbl))
    stmt2:bind(1, data2)
    stmt2:bind(2, id)
    stmt2:step()
    stmt2:finalize()

    DB._cache[tbl][#DB._cache[tbl]+1] = record
    return id
end

-- ----------------------------------------------------------------
-- DB.all(tbl) -> tabla
-- ----------------------------------------------------------------
function DB.all(tbl)
    return DB._cache[tbl] or {}
end

-- ----------------------------------------------------------------
-- DB.where(tbl, predicate) -> tabla
-- ----------------------------------------------------------------
function DB.where(tbl, predicate)
    local result = {}
    for _, row in ipairs(DB._cache[tbl] or {}) do
        if predicate(row) then result[#result+1] = row end
    end
    return result
end

-- ----------------------------------------------------------------
-- DB.find(tbl, predicate) -> fila o nil
-- ----------------------------------------------------------------
function DB.find(tbl, predicate)
    for _, row in ipairs(DB._cache[tbl] or {}) do
        if predicate(row) then return row end
    end
    return nil
end

-- ----------------------------------------------------------------
-- DB.update(tbl, predicate, changes)
-- Modifica en cache y persiste cada fila afectada
-- ----------------------------------------------------------------
function DB.update(tbl, predicate, changes)
    local stmt = DB._db:prepare(
        string.format('UPDATE "%s" SET data=? WHERE id=?', tbl))
    for _, row in ipairs(DB._cache[tbl] or {}) do
        if predicate(row) then
            for k, v in pairs(changes) do row[k] = v end
            stmt:bind(1, serialize(row))
            stmt:bind(2, row.id)
            stmt:step()
            stmt:reset()
        end
    end
    stmt:finalize()
end

-- ----------------------------------------------------------------
-- DB.save()  –  persiste TODOS los registros en cache a SQLite
-- Se llama desde Repos y Handlers que modifican registros
-- directamente (row.campo = valor) en lugar de usar DB.update.
-- ----------------------------------------------------------------
function DB.save()
    if not DB._db then return end
    DB._db:exec("BEGIN")
    for _, tbl in ipairs(TABLES) do
        local stmt = DB._db:prepare(
            string.format('UPDATE "%s" SET data=? WHERE id=?', tbl))
        if stmt then
            for _, row in ipairs(DB._cache[tbl] or {}) do
                if row.id then
                    stmt:bind(1, serialize(row))
                    stmt:bind(2, row.id)
                    stmt:step()
                    stmt:reset()
                end
            end
            stmt:finalize()
        end
    end
    DB._db:exec("COMMIT")
end

-- ----------------------------------------------------------------
-- DB.close()
-- ----------------------------------------------------------------
function DB.close()
    DB.save()
    if DB._db then
        DB._db:close()
        DB._db = nil
    end
end

return DB
