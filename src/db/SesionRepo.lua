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

function R.getByTutor(usuario_id)
    -- Buscar el tutor por usuario_id
    local tutor = DB.find("tutores", function(t) return t.usuario_id == usuario_id end)
    if not tutor then return {} end
    -- Tutorias del tutor
    local tutorias = DB.where("tutorias", function(t) return t.tutor_id == tutor.id end)
    local result = {}
    for _, tut in ipairs(tutorias) do
        local ses = DB.where("sesiones", function(s) return s.tutoria_id == tut.id end)
        for _, s in ipairs(ses) do
            s._area       = tut.area or "\xe2\x80\x94"
            s._estudiante = tut.estudiante_nombre or "\xe2\x80\x94"
            result[#result+1] = s
        end
    end
    table.sort(result, function(a,b) return (a.fecha or "") > (b.fecha or "") end)
    return result
end

return R
