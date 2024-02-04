function GivePoliceItems(playerId)
    local player = NDCore.getPlayer(playerId)
    local pdJob = player.getData("job")

    -- Check if the player has a police job
    for _, job in ipairs(Config.PoliceJobs) do
        if pdJob == job then
            -- Give items for police job
            for _, item in ipairs(Config.PoliceItems) do
                local success, response = exports.ox_inventory:AddItem(playerId, item, 1)
                if not success then
                    print("Failed to give item to police player: " .. response)
                end
            end
            return
        end
    end

    print("Player is not in a police job.")
end

function GiveEMSItems(playerId)
    local player = NDCore.getPlayer(playerId)
    local emsJob = player.getData("job")

    -- Check if the player has an EMS job
    for _, job in ipairs(Config.EMSJobs) do
        if emsJob == job then
            -- Give items for EMS job
            for _, item in ipairs(Config.EMSItems) do
                local success, response = exports.ox_inventory:AddItem(playerId, item, 1)
                if not success then
                    print("Failed to give item to EMS player: " .. response)
                end
            end
            return
        end
    end

    print("Player is not in an EMS job.")
end
