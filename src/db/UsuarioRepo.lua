local DB = require("src.db.DB")
local R  = {}

function R.getByRol(rol)
    return DB.where("usuarios", function(u) return u.rol == rol end)
end

function R.getById(id)
    return DB.find("usuarios", function(u) return u.id == id end)
end

return R
