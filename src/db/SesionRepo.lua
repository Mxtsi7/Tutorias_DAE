local DB          = require("src.db.DB")
local TutoriaRepo = require("src.db.TutoriaRepo")
local R = {}

function R.crear(tutoria_id, fecha, duracion, temas, asistencia, avance)
    local id = DB.insert("sesiones", {
        tutoria_id = tutoria_id,
        fecha      = fecha,
        duracion   = tonumber(duracion) or 0,
        temas      = temas,
        asistencia = asistencia,
        avance     = avance,
    })
    TutoriaRepo.registrarSesion(tutoria_id, avance, asistencia)
    DB.save()
    return id
end

function R.getByTutoria(tutoria_id)
    return DB.where("sesiones", function(s) return s.tutoria_id == tutoria_id end)
end

return R
