-- Repositorio de usuarios y sesion activa
local DB = require("src.db.DB")

local R = {}

function R.getByRol(rol)
    return DB.query("SELECT * FROM usuarios WHERE rol=? LIMIT 1", {rol})
end

function R.getById(id)
    local rows = DB.query("SELECT * FROM usuarios WHERE id=?", {id})
    return rows[1]
end

return R
