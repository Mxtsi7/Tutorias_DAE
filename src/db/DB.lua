-- DB.lua: abre/crea tutorias.db y expone exec/query
local ffi = require("ffi")

ffi.cdef[[
    typedef struct sqlite3 sqlite3;
    typedef struct sqlite3_stmt sqlite3_stmt;
    int    sqlite3_open(const char *filename, sqlite3 **ppDb);
    int    sqlite3_close(sqlite3 *db);
    int    sqlite3_exec(sqlite3*, const char *sql, void*, void*, char **);
    int    sqlite3_prepare_v2(sqlite3*, const char *zSql, int nByte,
                              sqlite3_stmt **ppStmt, const char **pzTail);
    int    sqlite3_step(sqlite3_stmt*);
    int    sqlite3_finalize(sqlite3_stmt*);
    int    sqlite3_column_count(sqlite3_stmt*);
    const char *sqlite3_column_name(sqlite3_stmt*, int iCol);
    int    sqlite3_column_type(sqlite3_stmt*, int iCol);
    int    sqlite3_column_int(sqlite3_stmt*, int iCol);
    double sqlite3_column_double(sqlite3_stmt*, int iCol);
    const char *sqlite3_column_text(sqlite3_stmt*, int iCol);
    int    sqlite3_bind_text(sqlite3_stmt*, int, const char*, int, void*);
    int    sqlite3_bind_int(sqlite3_stmt*, int, int);
    int    sqlite3_bind_double(sqlite3_stmt*, int, double);
    int    sqlite3_reset(sqlite3_stmt*);
    long long sqlite3_last_insert_rowid(sqlite3*);
    const char *sqlite3_errmsg(sqlite3*);
]]

local sqlite3
local ok, lib = pcall(ffi.load, "sqlite3")
if ok then sqlite3 = lib
else
    ok, lib = pcall(ffi.load, "libsqlite3.so.0")
    if ok then sqlite3 = lib
    else error("No se pudo cargar sqlite3: "..tostring(lib)) end
end

local SQLITE_ROW  = 100
local SQLITE_DONE = 101
local SQLITE_TRANSIENT = ffi.cast("void*", -1)

local DB = {}
DB._db = nil

function DB.open()
    local path = love.filesystem.getSaveDirectory() .. "/tutorias.db"
    local dbptr = ffi.new("sqlite3*[1]")
    local rc = sqlite3.sqlite3_open(path, dbptr)
    if rc ~= 0 then error("No se pudo abrir BD: "..path) end
    DB._db = dbptr[0]
    DB._initSchema()
    require("src.db.Seed").run()
end

function DB.close()
    if DB._db then sqlite3.sqlite3_close(DB._db) DB._db = nil end
end

-- Ejecuta SQL sin retorno (CREATE, INSERT, UPDATE, DELETE)
function DB.exec(sql)
    local rc = sqlite3.sqlite3_exec(DB._db, sql, nil, nil, nil)
    if rc ~= 0 then
        error("DB.exec error: "..ffi.string(sqlite3.sqlite3_errmsg(DB._db)).."\nSQL: "..sql)
    end
end

-- Ejecuta SQL con parametros y retorna filas como lista de tablas
-- params = lista ordenada de valores (string, number)
function DB.query(sql, params)
    params = params or {}
    local stmtptr = ffi.new("sqlite3_stmt*[1]")
    local rc = sqlite3.sqlite3_prepare_v2(DB._db, sql, -1, stmtptr, nil)
    if rc ~= 0 then
        error("DB.query prepare error: "..ffi.string(sqlite3.sqlite3_errmsg(DB._db)))
    end
    local stmt = stmtptr[0]
    for i, v in ipairs(params) do
        if type(v) == "string" then
            sqlite3.sqlite3_bind_text(stmt, i, v, #v, SQLITE_TRANSIENT)
        elseif type(v) == "number" then
            if math.type and math.type(v)=="float" then
                sqlite3.sqlite3_bind_double(stmt, i, v)
            else
                sqlite3.sqlite3_bind_int(stmt, i, v)
            end
        end
    end
    local rows = {}
    local ncols = sqlite3.sqlite3_column_count(stmt)
    while sqlite3.sqlite3_step(stmt) == SQLITE_ROW do
        local row = {}
        for c = 0, ncols-1 do
            local name = ffi.string(sqlite3.sqlite3_column_name(stmt, c))
            local ctype = sqlite3.sqlite3_column_type(stmt, c)
            if ctype == 1 then
                row[name] = sqlite3.sqlite3_column_int(stmt, c)
            elseif ctype == 2 then
                row[name] = sqlite3.sqlite3_column_double(stmt, c)
            elseif ctype == 3 then
                local txt = sqlite3.sqlite3_column_text(stmt, c)
                row[name] = txt ~= nil and ffi.string(txt) or ""
            else
                row[name] = nil
            end
        end
        rows[#rows+1] = row
    end
    sqlite3.sqlite3_finalize(stmt)
    return rows
end

-- Retorna el id del ultimo INSERT
function DB.lastId()
    return tonumber(sqlite3.sqlite3_last_insert_rowid(DB._db))
end

function DB._initSchema()
    DB.exec([[
        PRAGMA foreign_keys = ON;

        CREATE TABLE IF NOT EXISTS usuarios (
            id      INTEGER PRIMARY KEY AUTOINCREMENT,
            nombre  TEXT NOT NULL,
            rol     TEXT NOT NULL CHECK(rol IN ('estudiante','tutor','coordinador'))
        );

        CREATE TABLE IF NOT EXISTS tutores (
            id                   INTEGER PRIMARY KEY AUTOINCREMENT,
            usuario_id           INTEGER REFERENCES usuarios(id),
            nombre               TEXT NOT NULL,
            areas_competencia    TEXT NOT NULL,
            disponibilidad       TEXT NOT NULL,
            tutorados_activos    INTEGER DEFAULT 0,
            limite               INTEGER DEFAULT 3,
            incidentes_recientes INTEGER DEFAULT 0
        );

        CREATE TABLE IF NOT EXISTS estudiantes (
            id             INTEGER PRIMARY KEY AUTOINCREMENT,
            usuario_id     INTEGER REFERENCES usuarios(id),
            nombre         TEXT NOT NULL,
            area_necesidad TEXT
        );

        CREATE TABLE IF NOT EXISTS tutorias (
            id                      INTEGER PRIMARY KEY AUTOINCREMENT,
            estudiante_id           INTEGER REFERENCES estudiantes(id),
            tutor_id                INTEGER REFERENCES tutores(id),
            area                    TEXT NOT NULL,
            estado                  TEXT DEFAULT 'activa',
            nivel_avance_actual     TEXT DEFAULT 'bajo',
            sesiones_realizadas     INTEGER DEFAULT 0,
            ausencias_consecutivas  INTEGER DEFAULT 0,
            fecha_inicio            TEXT
        );

        CREATE TABLE IF NOT EXISTS sesiones (
            id          INTEGER PRIMARY KEY AUTOINCREMENT,
            tutoria_id  INTEGER REFERENCES tutorias(id),
            fecha       TEXT,
            duracion    INTEGER,
            temas       TEXT,
            asistencia  TEXT,
            avance      TEXT
        );

        CREATE TABLE IF NOT EXISTS solicitudes (
            id           INTEGER PRIMARY KEY AUTOINCREMENT,
            estudiante_id INTEGER REFERENCES estudiantes(id),
            area         TEXT,
            urgencia     TEXT,
            disponibilidad TEXT,
            modalidad    TEXT,
            estado       TEXT DEFAULT 'pendiente',
            fecha        TEXT
        );
    ]])
end

return DB
