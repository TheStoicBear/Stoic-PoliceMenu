-- Citations Menu Function
RegisterNetEvent('citations_menu')
AddEventHandler('citations_menu', function()
    local citationsMenu = {
        id = 'citations_menu',
        title = 'Citations',
        options = {
            { title = 'Issue Fine', event = 'issue_fine' },
            { title = 'Issue Ticket', event = 'issue_ticket' },
            { title = 'Parking Citation', event = 'parking_citation' },
            { title = 'Impound Vehicle', event = 'impoundVehicle' },
            -- Add the "Back" button at the bottom
            {
                title = 'Back',
                onSelect = function()
                    lib.showContext('police_menu') -- Assuming you have an 'mdt_menu' context
                end,
                icon = 'arrow-left',
                description = 'Go back to Police Menu',
            },
        }
    }

    lib.registerContext(citationsMenu)
    lib.showContext('citations_menu')
end)

-- Issue Fine Function
RegisterNetEvent('issue_fine')
AddEventHandler('issue_fine', function()
    local fineInput = lib.inputDialog('Issue Fine', {
        { type = "input", label = "ID" },
        { type = "input", label = "Amount" },
        { type = "input", label = "Reason" }
    })

    -- Debug prints to check the structure of fineInput
    print("Fine Input:")
    for key, value in pairs(fineInput) do
        print(key, value)
    end

    local targetPlayerId = tonumber(fineInput[1])
    local amount = tonumber(fineInput[2])
    local reason = fineInput[3]

    -- Debug prints to check the extracted values
    print("Extracted Values:")
    print("Target Player ID:", targetPlayerId)
    print("Amount:", amount)
    print("Reason:", reason)

    -- Process the fine on the server side
    TriggerServerEvent('process_fine', targetPlayerId, amount, reason)
end)

-- Issue Ticket Function
RegisterNetEvent('issue_ticket')
AddEventHandler('issue_ticket', function()
    local ticketInput = lib.inputDialog('Issue Ticket', {
        { type = "input", label = "ID" },
        { type = "input", label = "Amount" },
        { type = "input", label = "Reason" }
    })

    local targetPlayerId = tonumber(ticketInput[1])
    local amount = tonumber(ticketInput[2])
    local reason = ticketInput[3]

    -- Process the ticket on the server side
    TriggerServerEvent('process_ticket', targetPlayerId, amount, reason)
end)

-- Parking Citation Function
RegisterNetEvent('parking_citation')
AddEventHandler('parking_citation', function()
    local parkingCitationInput = lib.inputDialog('Parking Citation', {
        { type = "input", label = "ID" },
        { type = "input", label = "Amount" },
        { type = "input", label = "Reason" }
    })

    local targetPlayerId = tonumber(parkingCitationInput[1])
    local amount = tonumber(parkingCitationInput[2])
    local reason = parkingCitationInput[3]

    -- Process the parking citation on the server side
    TriggerServerEvent('process_parking_citation', targetPlayerId, amount, reason)
end)

-- Impound Vehicle Function
RegisterNetEvent('impound_vehicle')
AddEventHandler('impound_vehicle', function()
    local impoundInput = lib.inputDialog('Impound Vehicle', {
        { type = "input", label = "ID" },
        { type = "input", label = "Reason" }
    })

    local targetPlayerId = tonumber(impoundInput[1])
    local reason = impoundInput[2]

    -- Process the vehicle impound on the server side
    TriggerServerEvent('process_impound_vehicle', targetPlayerId, reason)
end)



-- Impound Vehicle Event
RegisterNetEvent('impoundVehicle')
AddEventHandler('impoundVehicle', function()
    local playerPed = PlayerPedId()
    local x, y, z = table.unpack(GetEntityCoords(playerPed, true))
    local radius = 5.0
    local modelHash = 0
    
    local closestVehicle = GetClosestVehicle(x, y, z, radius, modelHash, 127)
    
    if DoesEntityExist(closestVehicle) then
        ImpoundClosestVehicle(closestVehicle)
    else
        NotifyImpoundError("No vehicle found nearby.")
    end
end)

-- Function to impound the closest vehicle
function ImpoundClosestVehicle(vehicle)
    local impoundLocations = Settings.Impound.ImpoundLocations
    local randomLocationIndex = math.random(1, #impoundLocations)
    local impoundLocation = impoundLocations[randomLocationIndex]
    local impoundX, impoundY, impoundZ, impoundHeading = impoundLocation.X, impoundLocation.Y, impoundLocation.Z, impoundLocation.H

    -- Check for collision with other vehicles
    local spawnFound = false
    local spawnX, spawnY, spawnZ = 0, 0, 0
    local offset = 2.0
    local angle = math.rad(impoundHeading)

    while not spawnFound do
        spawnX = impoundX + (offset * math.cos(angle))
        spawnY = impoundY + (offset * math.sin(angle))

        local isClear = true
        local nearbyVehicles = GetGamePool("CVehicle")

        for _, nearbyVehicle in ipairs(nearbyVehicles) do
            local vehiclePosition = GetEntityCoords(nearbyVehicle)
            local distance = #(vector3(spawnX, spawnY, impoundZ) - vehiclePosition)

            if distance < 5.0 then
                isClear = false
                break
            end
        end

        if isClear then
            spawnFound = true
        else
            offset = offset + 2.0 -- Increase offset if collision detected
        end
    end

    -- Impound the vehicle at the found spawn point
    SetEntityCoords(vehicle, spawnX, spawnY, impoundZ, true, true, true)
    SetEntityHeading(vehicle, impoundHeading)

    local title = "[Police] Impound"
    local message = "SUCCESS: The vehicle has been impounded."
    NotifyImpoundResult(title, message)
end

-- Function to notify impound result
function NotifyImpoundResult(title, message)
    if GetResourceState("ModernHUD") == "started" then
        NotifyWithModernHUD(title, message, "fa-solid fa-car-crash", "#FF0000")
    else
        TriggerEvent('chatMessage', title, { 255, 255, 255 }, message)
    end
end

-- Function to notify impound error
function NotifyImpoundError(message)
    local title = "[Police] Impound"
    NotifyImpoundResult(title, message)
end
