-- Search Player Function
RegisterNetEvent('search_player')
AddEventHandler('search_player', function()
    local closestPlayer, closestDistance = QBCore.Functions.GetClosestPlayer()

    if closestPlayer ~= -1 and closestDistance <= 3.0 then
        TriggerServerEvent('qb-inventory:server:openInventory', GetPlayerServerId(closestPlayer), 'otherplayer', closestPlayer)
    else
        QBCore.Functions.Notify('No players nearby to search.', 'error')
    end
end)
