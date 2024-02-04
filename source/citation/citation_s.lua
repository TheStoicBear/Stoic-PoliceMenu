-- Function to send notifications or chat messages
function SendCitationHandler(playerId, title, message, cost)
    local data = {
        id = playerId,  -- Use playerId as a unique identifier
        title = title,
        description = message,
        duration = 5000,  -- Default duration is 5000 milliseconds (5 seconds)
        position = 'bottom', --Middle center-bottom
        type = 'inform',
        style = {},  -- You can customize the style if needed
        icon = 'fas fa-info-circle',  -- Use Font Awesome 6 icon name for inform type
        iconColor = '#ffffff',  -- Customize icon color if needed
        iconAnimation = 'fade',  -- Choose an icon animation if needed
        alignIcon = 'center'  -- Default is center
    }

    TriggerClientEvent('ox_lib:notify', playerId, data)
end

-- Function to deduct fines and send a message to the target player
function DeductFine(targetPlayerId, amount, reason)
    local player = NDCore.getPlayer(targetPlayerId)

    -- Check if the player object is valid before proceeding
    if player then
        player.deductMoney("bank", amount, "Player Citations")
        local message = ' You have been fined: $' .. amount .. ' for: ' .. reason
        SendCitationHandler(targetPlayerId, "Fine:", message, amount)
    else
        print("Invalid player object for targetPlayerId:", targetPlayerId)
    end
end

-- Function to issue a ticket and send a message to the target player
function IssueTicket(targetPlayerId, amount, reason)
    local player = NDCore.getPlayer(targetPlayerId)
    player.deductMoney("bank", amount, "Player Citations")
    local message = ' You have been issued a ticket: $' .. amount .. ' for: ' .. reason
    SendCitationHandler(targetPlayerId, "Ticket:", message, amount)
end

-- Function to issue a parking citation and send a message to the target player
function IssueParkingCitation(targetPlayerId, amount, reason)
    local player = NDCore.getPlayer(targetPlayerId)
    player.deductMoney("bank", amount, "Player Citations")
    local message = ' You have been issued a parking citation: $' .. amount .. ' for: ' .. reason
    SendCitationHandler(targetPlayerId, "Parking Citation:", message, amount)
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
