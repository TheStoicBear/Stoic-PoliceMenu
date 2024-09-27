local ox_target = exports.ox_target
local isOnDuty = false -- Initially not on duty
local NDCore = exports["ND_Core"]

-- Police Menu Configuration
local config = {
    toggle_duty = true,
    action_menu = true,
    search_player = true,
    citations_menu = true,
    jail_player = true
}

-- Define options for opening the action menu
local actionMenuOptions = {
    {
        name = "openActionMenu",
        icon = Config.ThirdEyeIcon,
        label = Config.ThirdEyeMenuName,
        iconColor = Config.ThirdEyeIconColor,
        distance = Config.ThirdEyeDistance,
        onSelect = function(data)
            local target = GetPlayerServerId(NetworkGetPlayerIndexFromPed(data.entity))
            TriggerEvent("openActionMenu", target)
            lib.showContext('policeactions')
        end
    }
}

RegisterKeyMapping('DisplayPoliceMenu', 'Open Police Menu', 'keyboard', 'F7')

-- Improved IsPoliceJob function that logs the outcome and errors
function IsPoliceJob(player)
    local player = NDCore.getPlayer(source) -- Fetch player data
    if player and player.job then
        for _, jobIdentifier in ipairs(Config.jobIdentifiers) do
            if player.job == jobIdentifier then
                return true
            end
        end
    else
        print("Player job not available or player data not fetched properly.")
    end
    return false
end

-- Function to ensure the player is in a police job and update the menu accordingly
function UpdatePoliceJobState(player)
    local isPolice = IsPoliceJob(player)
    if ox_target then
        if isPolice then
            ox_target:addGlobalPlayer(actionMenuOptions)
        else
            ox_target:removeGlobalPlayer(actionMenuOptions)
        end
    else
        print("ox_target not available.")
    end
end

-- Events to handle player data loading and updates
AddEventHandler("ND:characterLoaded", function(character)
    print("Character loaded:", character.firstname, character.lastname)
    UpdatePoliceJobState(character)
end)

AddEventHandler("ND:updateCharacter", function(character)
    print("Character updated:", character.firstname, character.lastname)
    UpdatePoliceJobState(character)
end)

-- Command to open the police menu
RegisterCommand('policeMenu', function()
    local player = NDCore.getPlayer(source)
    if player and IsPoliceJob(player) then
        DisplayPoliceMenu()
    else
        print("You do not have permission to access the police menu.")
    end
end, false)

function DisplayPoliceMenu()
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
end

RegisterNetEvent('stoicpm:shotspotter')
AddEventHandler('stoicpm:shotspotter', function(location, streetName)
    local xPlayer = NDCore.getPlayer()
    local job = xPlayer.job
    if xPlayer and job then
        for _, jobIdentifier in ipairs(Config.jobIdentifiers) do
            if job == jobIdentifier then
                -- Only notify if the job matches
                local notificationData = {
                    id = 'shotspotter_notification',
                    title = Config.notification.titlePrefix,
                    description = 'Shots fired on ' .. streetName,
                    position = Config.notification.position,
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

                PlaySoundFrontend(-1, "QUIT", "HUD_FRONTEND_DEFAULT_SOUNDSET", true)

                CreateShotSpotterBlip(location)

                -- Break out of the loop once the job is found
                break
            end
        end
    end
end)


function CreateShotSpotterBlip(location)
    local blip = AddBlipForCoord(location)
    SetBlipSprite(blip, Config.shotspotter.blipSprite)
    SetBlipScale(blip, Config.shotspotter.blipScale)
    SetBlipColour(blip, Config.shotspotter.blipColour)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(Config.shotspotter.blipName)
    EndTextCommandSetBlipName(blip)
    PulseBlip(blip)
    Citizen.Wait(Config.shotspotter.pulseTime)
    RemoveBlip(blip)
end

CreateThread(function()
    while true do
        Wait(0)
        local playerPed = PlayerPedId()
        if IsPedArmed(playerPed, 4) and ShouldAlert(playerPed) then
            local playerPos = GetEntityCoords(playerPed)
            if IsPedShooting(playerPed) then
                TriggerServerEvent("stoicpm:shotspotter", playerPos, GetStreetNameFromHashKey(GetStreetNameAtCoord(playerPos.x, playerPos.y, playerPos.z)))
                Wait(30000)
            else
                Wait(500)
            end
        else
            Wait(500)
        end
    end
end)

function ShouldAlert(playerPed)
    local currentWeapon = GetSelectedPedWeapon(playerPed)
    if Config.IgnoreWeapons[currentWeapon] then
        return false
    end
    return not IsPedCurrentWeaponSilenced(playerPed)
end

function GetNearestPlayer()
    local myPos = GetEntityCoords(GetPlayerPed(-1))
    local nearestPlayer, nearestDistance = nil, math.huge
    for _, player in ipairs(GetActivePlayers()) do
        local targetPos = GetEntityCoords(GetPlayerPed(player))
        local distance = GetDistanceBetweenCoords(myPos.x, myPos.y, myPos.z, targetPos.x, targetPos.y, targetPos.z, true)
        if distance < nearestDistance then
            nearestPlayer, nearestDistance = player, distance
        end
    end
    return nearestPlayer
end