local SM = require("src.screens.ScreenManager")
local T = {}
T.active=false T.alpha=0 T.dir=1 T.speed=2.8
T.nextName=nil T.nextParams=nil T.slideX=0 T.slideDir=0

function T.to(screenName, params, slideDir)
    if T.active then return end
    T.active=true T.alpha=0 T.dir=1
    T.nextName=screenName T.nextParams=params
    T.slideDir=slideDir or 1 T.slideX=0
end

function T.update(dt)
    if not T.active then return end
    T.alpha = T.alpha + T.dir * T.speed * dt
    T.slideX = T.slideX + T.dir * T.slideDir * 700 * dt
    if T.dir==1 and T.alpha>=1 then
        T.alpha=1 T.dir=-1 T.slideX=-T.slideDir*50
        SM.load(T.nextName, T.nextParams)
    elseif T.dir==-1 and T.alpha<=0 then
        T.alpha=0 T.active=false T.slideX=0
    end
end

function T.draw(W, H)
    W = W or love.graphics.getWidth()
    H = H or love.graphics.getHeight()
    if T.alpha<=0 then return end
    love.graphics.setColor(0.08,0.08,0.14, math.min(T.alpha,1))
    love.graphics.rectangle("fill",0,0,W,H)
end

function T.offsetX() return T.active and T.slideX or 0 end

return T
