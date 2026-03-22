local data = {
    aimFOVs = {
        [5]  = 12,   -- 5x
        [10] = 5,    -- 10x
        [15] = 3,    -- 15x
        -- Usage: local fov = data.aimFOVs[currentMagnification]
        --[[
            1) detect button click to change scope zoom
            2) call function and pass argument on pattern: (5, 10, 15)
            3) apply pattern to scope zoom using data.aimFOVs[currentMagnification]
        ]]
    } 
}

return data