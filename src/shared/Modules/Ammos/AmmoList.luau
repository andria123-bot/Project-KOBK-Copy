local AmmoList = {
    ["5.56x45 T"] = {
        name = "5.56x45 T",
        tracer = true,
        damage = 28.6,
        headshot = 67.67,

        muzzleVelocity = 880,       -- studs/second
        dragCoefficient = 0.00022,  -- Air resistance
        gravity = 0.5,              -- Drop multiplier

        hipSpread = 0.7,            -- Degrees when not aiming
        aimingSpread = 0.1,         -- Degrees when ADS
        spreadRecovery = 0.1,       -- Seconds to reset

        armorPen = 1.4,              -- High armor pen
        penetrationPower = 4,        -- Goes through more walls
    },

    ["5.56x45 AP"] = {
        name = "5.56x45 AP",
        tracer = false,
        damage = 24.67,            
        headshot = 55.53,
        
        muzzleVelocity = 890,
        dragCoefficient = 0.00020,
        gravity = 0.5,
        
        hipSpread = 0.9,      
        aimingSpread = 0.15,
        spreadRecovery = 0.12,
        
        armorPen = 3.0,            
        penetrationPower = 4,      
    },
}

return AmmoList