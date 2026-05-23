-- Repositorio de sesiones
local DB = require("src.db.DB")
local TutoriaRepo = require("src.db.TutoriaRepo")

local R = {}

function R.crear(tutoria_id, fecha, duracion, temas, asistencia, avance)
    DB.query(
        "INSERT INTO sesiones(tutoria_id,fecha,duracion,temas,asistencia,avance) VALUES(?,?,?,?,?,?)",
        {tutoria_id, fecha, tonumber(duracion) or 0, temas, asistencia, avance}
    )
    TutoriaRepo.registrarSesion(tutoria_id, avance, asistencia)
    return DB.lastId()
end

function R.getByTutoria(tutoria_id)
    return DB.query(
        "SELECT * FROM sesiones WHERE tutoria_id=? ORDER BY fecha DESC",
        {tutoria_id}
    )
end

return R
