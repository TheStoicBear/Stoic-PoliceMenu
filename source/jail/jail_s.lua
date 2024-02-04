QBCore.Functions.CreateCallback('getPlayerList', function(source, cb)
    local playerCoords = GetEntityCoords(GetPlayerPed(source))
    local players = QBCore.Functions.GetPlayers()
    local playerData = {}

    for _, playerId in ipairs(players) do
        local player = QBCore.Functions.GetPlayer(playerId)
        local playerPed = GetPlayerPed(playerId)
        local playerCoords = GetEntityCoords(playerPed)
        local distance = #(playerCoords - playerCoords)

        if distance <= 30 then
            playerData[#playerData + 1] = {
                name = player.PlayerData.charinfo.firstname .. " " .. player.PlayerData.charinfo.lastname,
                id = player.PlayerData.citizenid
            }
        end
    end

    print("Server-side playerData:", json.encode(playerData))

    cb(playerData)
end)

RegisterServerEvent('jailPlayer')
AddEventHandler('jailPlayer', function(selectedPlayerId, jailTime, jailReason, fineAmount)
    print("Received 'jailPlayer' event with the following parameters:")
    print("Server: Player ID:", selectedPlayerId, "Jail Time:", jailTime, "Reason:", jailReason, "Fine:", fineAmount)

    local jailedPlayer = QBCore.Functions.GetPlayer(selectedPlayerId)
    if not jailedPlayer then
        print("Failed to retrieve jailed player's information.")
        return
    end

    local jailedPlayerName = jailedPlayer.PlayerData.charinfo.firstname .. " " .. jailedPlayer.PlayerData.charinfo.lastname
    local success = jailedPlayer.Functions.RemoveMoney("bank", fineAmount, "Jail Fine")

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
    local unjailCoords = vector3(1848.86, 2602.36, 45.60)
    TriggerClientEvent('unjailPlayer', src, unjailCoords)
    TriggerClientEvent('setJailedStatus', src, false, 0)
end)
