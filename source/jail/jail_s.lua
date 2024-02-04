lib.callback.register("getPlayerList", function(source)
    local playerCoords = GetEntityCoords(GetPlayerPed(source))
    local players = lib.getNearbyPlayers(playerCoords, 30, false)
    local playerData = {}

    for i=1, #players do
        local ply = players[i]
        local player = NDCore.getPlayer(ply.id)
        playerData[#playerData+1] = {
            name = player.fullname,
            id = ply.id
        }
    end

    print("Server-side playerData:", json.encode(playerData))

    return playerData
end)

RegisterServerEvent('jailPlayer')
AddEventHandler('jailPlayer', function(selectedPlayerId, jailTime, jailReason, fineAmount)
    print("Received 'jailPlayer' event with the following parameters:")
    print("Server: Player ID:", selectedPlayerId, "Jail Time:", jailTime, "Reason:", jailReason, "Fine:", fineAmount)

    local jailedPlayer = NDCore.getPlayer(selectedPlayerId)
    if not jailedPlayer then
        print("Failed to retrieve jailed player's information.")
        return
    end

    local jailedPlayerName = jailedPlayer.firstname .. " " .. jailedPlayer.lastname
    local success = jailedPlayer.deductMoney("bank", fineAmount, "Jail Fine")

    if not success then
        print("Failed to deduct fine from player's bank account.")
        return
    end

    local jailCoords = vector3(1680.23, 2513.08, 45.56)
    TriggerClientEvent('teleportToJail', selectedPlayerId, jailCoords)
    TriggerClientEvent('setJailedStatus', selectedPlayerId, true, jailTime)

    TriggerClientEvent('chat:addMessage', selectedPlayerId, {
        color = {255, 0, 0},
        multiline = true,
        args = {"Jail System", "You have been jailed for " .. jailTime .. " seconds. Reason: " .. jailReason .. ". Fine: $" .. fineAmount}
    })

    TriggerClientEvent('chat:addMessage', source, {
        color = {0, 255, 0},
        multiline = true,
        args = {"Jail System", "Player ID (" .. selectedPlayerId .. ") " .. jailedPlayerName .. " has been successfully jailed for " .. jailReason}
    })
end)


RegisterServerEvent('unjailPlayer')
AddEventHandler('unjailPlayer', function()
    local src = source
    local unjailCoords = {x = 1848.86, y = 2602.36, z = 45.60}
    TriggerClientEvent('unjailPlayer', src, unjailCoords)
    TriggerClientEvent('setJailedStatus', src, false, 0)
end)