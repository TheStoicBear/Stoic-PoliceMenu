-- Search Player Function
RegisterNetEvent('search_player')
AddEventHandler('search_player', function()
    local nearestPlayer = GetNearestPlayer()

    if nearestPlayer ~= -1 then
        exports.ox_inventory:openNearbyInventory(nearestPlayer)
    else
        lib.notify({
            title = 'No Players Nearby',
            description = 'No players are nearby to search.',
            type = 'info'
        })
    end
end)