local ox_target = exports.ox_target
local isOnDuty = false -- Initially not on duty

-- Police Menu Configuration
local config = {
    toggle_duty = true,
    action_menu = true,
    search_player = true,
    citations_menu = true,
    jail_player = true
}

-- Function to check if the player is in a police job
function IsPoliceJob()
    local player = QBCore.Functions.GetPlayerData()
    return player.job.name == "police" or player.job.name == "ambulance"
end

-- Register Police Menu command
RegisterCommand('policeMenu', function()
    if IsPoliceJob() then
        local policeMenu = {
            id = 'police_menu',
            title = 'Police Menu',
            options = {
                { title = 'Clock In', event = 'toggle_onduty', enabled = config.toggle_duty },
                { title = 'Clock Out', event = 'toggle_offDuty', enabled = config.toggle_duty },
                { title = 'Actions', event = 'policemenu', enabled = config.action_menu },
                { title = 'Citations', event = 'citations_menu', enabled = config.citations_menu },
                { title = 'Jailer', event = 'jail_menu', enabled = config.jail_player },
                {
                    title = 'Traffic Control',
                    onSelect = function()
                        lib.showContext('menu:main')
                    end
                }
            }
        }
        lib.registerContext(policeMenu)
        lib.showContext('police_menu')
    else
        print("You do not have permission to access the police menu.")
    end
end, false)



CreateThread(function()
    while true do
        Wait(0)
        local letSleep = true
        local playerPed = PlayerPedId()
        if IsPedArmed(playerPed, 4) then
            local shouldAlert = not IsPedCurrentWeaponSilenced(playerPed)
            local currentWeapon = GetSelectedPedWeapon(playerPed)
            for k, v in pairs(Config.IgnoreWeapons) do
                if currentWeapon == v then
                    shouldAlert = false
                    break
                end
            end
            if shouldAlert then
                letSleep = false
                if IsPedShooting(playerPed) then
                    local playerPos = GetEntityCoords(playerPed)
                    local streetHash = GetStreetNameAtCoord(playerPos.x, playerPos.y, playerPos.z)
                    local streetName = GetStreetNameFromHashKey(streetHash)
                    if streetName then
                        TriggerServerEvent("stoicpm:shotspotter", playerPos, streetName)
                        Wait(30000)
                    end
                end
            end
        end
        if letSleep then
            Wait(500)
        end
    end
end)

-- Toggle On Duty Function with Input Dialog
RegisterNetEvent('toggle_onduty')
AddEventHandler('toggle_onduty', function()
    print("Toggle On Duty Event Triggered") -- Debug print to check event trigger
    -- Open an input dialog to toggle duty status
    lib.inputDialog('Toggle Duty', {
        { type = "checkbox", label = "On Duty", value = isOnDuty },
    }, function(data, menu)
        print("Toggle On Duty Dialog Opened") -- Debug print to check if the dialog opens
        -- Check if the data received is valid
        if data then
            -- Update isOnDuty based on the checkbox value
            isOnDuty = not isOnDuty -- Toggle isOnDuty between true and false

            -- Notify the player about the duty status change
            lib.notify({
                title = 'Duty Toggled',
                description = 'You are now ' .. (isOnDuty and 'on duty' or 'off duty'),
                type = 'info'
            })
            print("Duty Toggled: You are now " .. (isOnDuty and 'on duty' or 'off duty')) -- Debug print for duty status change

            -- If the player is now on duty, perform necessary actions
            if isOnDuty then
                local playerId = PlayerId() -- Get the player's ID
                GivePoliceItems(playerId)
                GiveEMSItems(playerId)
                print("Player is now on duty. Police and EMS items given.") -- Debug print for actions performed when on duty
            end
        end

        -- Close the input dialog menu
        menu.close()
        print("Toggle On Duty Dialog Closed") -- Debug print to check if the dialog closes
    end)
end)

-- Toggle Off Duty Function with Input Dialog
RegisterNetEvent('toggle_offDuty')
AddEventHandler('toggle_offDuty', function()
    print("Toggle Off Duty Event Triggered") -- Debug print to check event trigger
    -- Open an input dialog to toggle duty status
    lib.inputDialog('Clock off', {
        { type = "checkbox", label = "Off Duty", value = not isOnDuty }, -- Invert isOnDuty for the Off Duty dialog
    }, function(data, menu)
        print("Toggle Off Duty Dialog Opened") -- Debug print to check if the dialog opens
        -- Check if the data received is valid
        if data then
            -- Update isOnDuty based on the checkbox value
            isOnDuty = not isOnDuty -- Toggle isOnDuty between true and false

            -- Notify the player about the duty status change
            lib.notify({
                title = 'Duty Toggled',
                description = 'You are now ' .. (isOnDuty and 'on duty' or 'off duty'),
                type = 'info'
            })
            print("Duty Toggled: You are now " .. (isOnDuty and 'on duty' or 'off duty')) -- Debug print for duty status change

            -- If the player is now on duty, perform necessary actions
            if isOnDuty then
                local playerId = PlayerId() -- Get the player's ID
                GivePoliceItems(playerId)
                GiveEMSItems(playerId)
                print("Player is now on duty. Police and EMS items given.") -- Debug print for actions performed when on duty
            end
        end

        -- Close the input dialog menu
        menu.close()
        print("Toggle Off Duty Dialog Closed") -- Debug print to check if the dialog closes
    end)
end)


RegisterNetEvent('stoicpm:shotspotter')
AddEventHandler('stoicpm:shotspotter', function(location, streetName)
    local blip = nil


    -- Construct notification data for lib.notify
    local notificationData = {
        id = 'shotspotter_notification',
        title = Config.notification.titlePrefix,
        description = 'Shots fired on ' .. streetName,
        position = Config.notification.position, -- Position of the notification
        style = {
            backgroundColor = Config.notification.backgroundColor,
            color = Config.notification.textColor,
            ['.description'] = {
                color = Config.notification.descriptionColor
            }
        },
        icon = Config.notification.icon,
        iconColor = Config.notification.iconColor
    }
    lib.notify(notificationData)

    -- Play a frontend sound
    PlaySoundFrontend(-1, "QUIT", "HUD_FRONTEND_DEFAULT_SOUNDSET", true)

    -- Check if the blip doesn't exist, then create and manage it
    if not DoesBlipExist(blip) then
        blip = AddBlipForCoord(location)
        SetBlipSprite(blip, Config.shotspotter.blipSprite)
        SetBlipScale(blip, Config.shotspotter.blipScale)
        SetBlipColour(blip, Config.shotspotter.blipColour)

        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString(Config.shotspotter.blipName)
        EndTextCommandSetBlipName(blip)

        PulseBlip(blip)

        -- Wait for the defined pulse time before removing the blip
        Citizen.Wait(Config.shotspotter.pulseTime)
        RemoveBlip(blip)
    end
end)


-- Function to find the nearest player
function GetNearestPlayer()
    local myPed = GetPlayerPed(-1)
    local myPos = GetEntityCoords(myPed)

    local players = GetActivePlayers()
    local nearestPlayer = -1
    local nearestDistance = -1

    for _, player in ipairs(players) do
        if player ~= PlayerId() then
            local targetPed = GetPlayerPed(player)
            local targetPos = GetEntityCoords(targetPed)
            local distance = GetDistanceBetweenCoords(myPos.x, myPos.y, myPos.z, targetPos.x, targetPos.y, targetPos.z)

            if nearestDistance == -1 or distance < nearestDistance then
                nearestPlayer = player
                nearestDistance = distance
            end
        end
    end

    return nearestPlayer
end

-- Define options for opening the action menu
local actionMenuOptions = {
    {
        name = "openActionMenu",
        icon = "fa-solid fa-hand-holding-heart",
        label = "Open Action Menu",
        distance = 2.0,
        canInteract = function(entity, distance, coords, name)
            -- You can define custom conditions here if needed
            return true
        end,
        onSelect = function(data)
            local target = GetPlayerServerId(NetworkGetPlayerIndexFromPed(data.entity))
            TriggerEvent("openActionMenu", target)
            lib.showContext('policeactions')
        end
    }
}

-- Add global player interactions to open the action menu
ox_target:addGlobalPlayer(actionMenuOptions)
