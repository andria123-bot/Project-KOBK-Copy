local SpringV2 = {}

local math_exp = math.exp
local math_cos = math.cos
local math_sin = math.sin
local math_sqrt = math.sqrt

local Spring = {}
Spring.__index = Spring

function Spring.new(initialPos, initialVel, target, angularFrequency, dampingRatio)
    return setmetatable({
        p = initialPos or 0,
        v = initialVel or 0,
        target = target or 0,
        w = angularFrequency or 10,
        d = dampingRatio or 1,
    }, Spring)
end

function Spring:update(dt)
    if self.w < 1e-4 then
        return self.p
    end
    
    local w = self.w
    local d = self.d
    local target = self.target
    local p = self.p - target
    local v = self.v
    
    if d < 0 then
        d = 0
    end
    
    if d > 1.0001 then
        local r1 = -w * d
        local r2 = w * math_sqrt(d * d - 1)
        local a1 = r1 - r2
        local a2 = r1 + r2
        
        local exp_a1 = math_exp(a1 * dt)
        local exp_a2 = math_exp(a2 * dt)
        
        local c1 = (v - p * a2) / (-2 * r2)
        local c2 = p - c1
        
        self.p = target + c1 * exp_a1 + c2 * exp_a2
        self.v = c1 * a1 * exp_a1 + c2 * a2 * exp_a2
        
    elseif d > 0.9999 then
        local exp = math_exp(-w * dt)
        local c = v + w * p
        local p2 = (c * dt + p) * exp
        
        self.p = target + p2
        self.v = c * exp - p2 * w
        
    else
        local wr = w * math_sqrt(1 - d * d)
        local exp = math_exp(-w * d * dt)
        local cos = math_cos(wr * dt)
        local sin = math_sin(wr * dt)
        
        local c = (v + w * d * p) / wr
        
        self.p = target + exp * (p * cos + c * sin)
        self.v = -exp * ((p * w * d - c * wr) * cos + (p * wr + c * w * d) * sin)
    end
    
    return self.p
end

function Spring:shove(force)
    self.v = self.v + force
end

function Spring:setTarget(target)
    self.target = target
end

function Spring:reset()
    self.p = 0
    self.v = 0
    self.target = 0
end

local VectorSpring = {}
VectorSpring.__index = VectorSpring

function VectorSpring.new(initialPos, initialVel, target, angularFrequency, dampingRatio)
    return setmetatable({
        x = Spring.new(initialPos and initialPos.X or 0, initialVel and initialVel.X or 0, target and target.X or 0, angularFrequency, dampingRatio),
        y = Spring.new(initialPos and initialPos.Y or 0, initialVel and initialVel.Y or 0, target and target.Y or 0, angularFrequency, dampingRatio),
        z = Spring.new(initialPos and initialPos.Z or 0, initialVel and initialVel.Z or 0, target and target.Z or 0, angularFrequency, dampingRatio),
    }, VectorSpring)
end

function VectorSpring:update(dt)
    return Vector3.new(
        self.x:update(dt),
        self.y:update(dt),
        self.z:update(dt)
    )
end

function VectorSpring:shove(force)
    self.x.v = self.x.v + force.X
    self.y.v = self.y.v + force.Y
    self.z.v = self.z.v + force.Z
end

function VectorSpring:setTarget(target)
    self.x.target = target.X
    self.y.target = target.Y
    self.z.target = target.Z
end

function VectorSpring:reset()
    self.x:reset()
    self.y:reset()
    self.z:reset()
end

function SpringV2.create(initialPos, initialVel, target, angularFrequency, dampingRatio)
    if type(initialPos) == "Vector3" then
        return VectorSpring.new(initialPos, initialVel, target, angularFrequency, dampingRatio)
    end
    return Spring.new(initialPos, initialVel, target, angularFrequency, dampingRatio)
end

return SpringV2