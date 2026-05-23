-- Sesion activa del usuario logueado
local Session = {
    usuario_id = nil,
    nombre     = nil,
    rol        = nil,
}

function Session.set(usuario_id, nombre, rol)
    Session.usuario_id = usuario_id
    Session.nombre     = nombre
    Session.rol        = rol
end

function Session.clear()
    Session.usuario_id = nil
    Session.nombre     = nil
    Session.rol        = nil
end

return Session
