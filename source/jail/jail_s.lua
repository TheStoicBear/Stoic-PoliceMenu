-- Function to get player list within a radius
lib.callback.register("getPlayerList", function(source)
    local Framework = exports[Config.FrameworkName].getServerFunctions()
    local playerCoords = GetEntityCoords(GetPlayerPed(source))
    local players = lib.getNearbyPlayers(playerCoords, 30, false)
    local playerData = {}

    for i = 1, #players do
        local ply = players[i]
        local player = Framework.getPlayer(ply.id)
        playerData[#playerData + 1] = {
            name = player.fullname,
            id = ply.id
        }
    end

    print("Server-side playerData:", json.encode(playerData))

    return playerData
end)

-- Event handler for jailing a player
RegisterServerEvent('jailPlayer')
AddEventHandler('jailPlayer', function(selectedPlayerId, jailTime, jailReason, fineAmount)
    local Framework = exports[Config.FrameworkName].getServerFunctions()
    local player = Framework.getPlayer(selectedPlayerId)
    
    if not player then
        print("Failed to retrieve jailed player's information.")
        return
    end

    -- Get account info and deduct fine
    local accountInfo = exports['money']:getaccount(selectedPlayerId)
    if accountInfo then
        local newBankBalance = (accountInfo.bank or 0) - fineAmount
        if newBankBalance < 0 then
            newBankBalance = 0  -- Prevent negative bank balance
        end
        local updatedAccount = {
            cash = accountInfo.cash or 0,
            bank = newBankBalance
        }
        local success = exports['money']:updateaccount(selectedPlayerId, updatedAccount)
        if not success then
            print("Failed to deduct fine from player's bank account.")
            return
        end
    else
        print("Failed to retrieve account information for selectedPlayerId:", selectedPlayerId)
        return
    end

    local jailCoords = vector3(1680.23, 2513.08, 45.56)
    TriggerClientEvent('teleportToJail', selectedPlayerId, jailCoords)
    TriggerClientEvent('setJailedStatus', selectedPlayerId, true, jailTime)

    TriggerClientEvent('chatMessage', selectedPlayerId, "Jail System", "You have been jailed for " .. jailTime .. " seconds. Reason: " .. jailReason .. ". Fine: $" .. fineAmount)

    TriggerClientEvent('chatMessage', source, "Jail System", "Player ID (" .. selectedPlayerId .. ") " .. player.firstname .. " " .. player.lastname .. " has been successfully jailed for " .. jailReason)
end)

-- Event handler for unjailing a player
RegisterServerEvent('unjailPlayer')
AddEventHandler('unjailPlayer', function()
    local Framework = exports[Config.FrameworkName].getServerFunctions()
    local src = source
    local unjailCoords = {x = 1848.86, y = 2602.36, z = 45.60}
    TriggerClientEvent('unjailPlayer', src, unjailCoords)
    TriggerClientEvent('setJailedStatus', src, false, 0)
end)
