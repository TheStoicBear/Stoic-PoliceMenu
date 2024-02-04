-- Function to send notifications or chat messages
function SendCitationHandler(playerId, title, message, cost)
    QBCore.Functions.Notify(message, 'inform', 5000)
end

-- Function to deduct fines and send a message to the target player
function DeductFine(targetPlayerId, amount, reason)
    QBCore.Functions.GetPlayer(targetPlayerId, function(player)
        if player then
            player.Functions.RemoveMoney('bank', amount, 'Player Citations')
            local message = 'You have been fined: $' .. amount .. ' for: ' .. reason
            SendCitationHandler(targetPlayerId, "Fine:", message, amount)
        else
            print("Invalid player object for targetPlayerId:", targetPlayerId)
        end
    end)
end

-- Function to issue a ticket and send a message to the target player
function IssueTicket(targetPlayerId, amount, reason)
    QBCore.Functions.GetPlayer(targetPlayerId, function(player)
        if player then
            player.Functions.RemoveMoney('bank', amount, 'Player Citations')
            local message = 'You have been issued a ticket: $' .. amount .. ' for: ' .. reason
            SendCitationHandler(targetPlayerId, "Ticket:", message, amount)
        else
            print("Invalid player object for targetPlayerId:", targetPlayerId)
        end
    end)
end

-- Function to issue a parking citation and send a message to the target player
function IssueParkingCitation(targetPlayerId, amount, reason)
    QBCore.Functions.GetPlayer(targetPlayerId, function(player)
        if player then
            player.Functions.RemoveMoney('bank', amount, 'Player Citations')
            local message = 'You have been issued a parking citation: $' .. amount .. ' for: ' .. reason
            SendCitationHandler(targetPlayerId, "Parking Citation:", message, amount)
        else
            print("Invalid player object for targetPlayerId:", targetPlayerId)
        end
    end)
end

-- Function to impound a vehicle and send a message to the target player
function ImpoundVehicle(targetPlayerId)
    local message = "Your vehicle has been impounded."
    SendCitationHandler(targetPlayerId, "Impound:", message, 0)  -- Assuming impound has no cost
end

-- RegisterServerEvent for handling fines
RegisterServerEvent('process_fine')
AddEventHandler('process_fine', function(targetPlayerId, amount, reason)
    DeductFine(targetPlayerId, amount, reason)
end)

-- RegisterServerEvent for handling tickets
RegisterServerEvent('process_ticket')
AddEventHandler('process_ticket', function(targetPlayerId, amount, reason)
    IssueTicket(targetPlayerId, amount, reason)
end)

-- RegisterServerEvent for handling parking citations
RegisterServerEvent('process_parking_citation')
AddEventHandler('process_parking_citation', function(targetPlayerId, amount, reason)
    IssueParkingCitation(targetPlayerId, amount, reason)
end)

-- RegisterServerEvent for handling impounding vehicles
RegisterServerEvent('process_impound_vehicle')
AddEventHandler('process_impound_vehicle', function(targetPlayerId)
    ImpoundVehicle(targetPlayerId)
end)
