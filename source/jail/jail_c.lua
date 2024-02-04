local jailedPlayers = {}


lib.registerContext({
    id = "jail_menu",
    title = "Jail Command Context Menu",
    canClose = true,
    options = {
        {
            title = "Jail Player",
            onSelect = function()
                playerList()
            end
        },
        { title = "Close Menu", onSelect = function() lib.hideContext(true) end },
        {
            title = 'Back',
            onSelect = function()
                lib.showContext('mdt_menu')
            end,
            icon = 'arrow-left',
            description = 'Go back to the main menu',
        }
    }
})

function playerList()
    local playerOptions = lib.callback.await("getPlayerList", false)
    local formattedPlayerOptions = {}

    if type(playerOptions) == 'table' and next(playerOptions) then
        for _, option in ipairs(playerOptions) do
            if option.name and option.id then
                table.insert(formattedPlayerOptions, {
                    label = option.name,
                    value = option.id
                })
            end
        end
    end

    if #formattedPlayerOptions > 0 then
        openJailDialog(formattedPlayerOptions)
    else
        print("No players found nearby to display.")
    end
end

function openJailDialog(formattedPlayerOptions)
    if type(formattedPlayerOptions) ~= 'table' then
        return
    end

    for i, option in ipairs(formattedPlayerOptions) do
        if not option.label or not option.value then
            return
        end
    end

    local input = lib.inputDialog('Jailer Processing', {
        { type = 'select', label = 'Select Player', options = formattedPlayerOptions, required = true },
        { type = 'number', label = 'Time (in minutes)', required = true, min = 1, max = 1440, step = 1 },
        { type = 'textarea', label = 'Reason', required = true, min = 1, max = 100, autosize = true },
        { type = 'number', label = 'Fine Amount', required = false, min = 0, step = 1 }
    }, {
        allowCancel = true
    })

    if not input then
        print("Jail command was canceled.")
        return
    end

    local playerId = input[1]
    local jailTime = tonumber(input[2]) * 60
    local jailReason = input[3]
    local fineAmount = tonumber(input[4] or 0)

    TriggerServerEvent('jailPlayer', playerId, jailTime, jailReason, fineAmount)
end


RegisterNetEvent('jail_menu')
AddEventHandler('jail_menu', function()
    lib.showContext('jail_menu')
end)

local jailed = false
local controlsDisabled = false
local remainingJailTime = 0
local isTextDisplayed = false

function teleportPlayer(coords)
    local playerPed = PlayerPedId()

    DoScreenFadeOut(800)
    while not IsScreenFadedOut() do
        Citizen.Wait(50)
    end

    SetEntityCoords(playerPed, coords.x, coords.y, coords.z)
    while not HasCollisionLoadedAroundEntity(playerPed) do
        Citizen.Wait(0)
    end
    
    DoScreenFadeIn(800)
end

function UpdateRemainingJailTime(time)
    remainingJailTime = time
end

function canAccessJailer(playerJob, allowedGroups)
    for _, job in ipairs(allowedGroups) do
        if playerJob == job then
            return true
        end
    end
    return false
end




RegisterNetEvent('teleportToJail')
AddEventHandler('teleportToJail', function()
    local jailCoords = vector3(1680.23, 2513.08, 45.56)
    local playerPed = GetPlayerPed(-1)

    RemoveAllPedWeapons(playerPed, true)
    SetEntityCoordsNoOffset(playerPed, jailCoords.x, jailCoords.y, jailCoords.z, true, true, true)

    if not jailed then
        lib.disableControls:Add({288, 289, 170, 244})
    end
end)

RegisterNetEvent('setJailedStatus')
AddEventHandler('setJailedStatus', function(status, jailTime)
    jailed = status
    remainingJailTime = jailTime

    Citizen.CreateThread(function()
        while true do
            Citizen.Wait(0)

            if jailed then
                if not controlsDisabled then
                    lib.disableControls:Add({288, 289, 170, 244})
                    controlsDisabled = true
                end

                lib.disableControls()

                if remainingJailTime > 0 then
                    Citizen.Wait(1000)
                    remainingJailTime = remainingJailTime - 1
                    UpdateRemainingJailTime(remainingJailTime)
                else
                    jailed = false
                    isTextDisplayed = false
                end
            elseif controlsDisabled then
                lib.disableControls:Clear({288, 289, 170, 244})
                controlsDisabled = false
            end
        end
    end)
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        
        if jailed then
            lib.disableControls()

            local remainingMinutes = math.floor(remainingJailTime / 60)
            local remainingSeconds = remainingJailTime % 60

            if remainingMinutes <= 0 and remainingSeconds <= 0 then
                if isTextDisplayed then
                    isTextDisplayed = false
                    DrawAdvancedText("", 0.5, 0.95, 0.4)
                end
            else
                isTextDisplayed = true
                DrawAdvancedText("~r~Remaining Jail Time: ~w~" .. remainingMinutes .. " Minutes, " .. remainingSeconds .. " Seconds", 0.5, 0.95, 0.4)
            end
        end
    end
end)

function DrawAdvancedText(text, x, y, sc)
    SetTextScale(0.35, 0.35)
    SetTextFont(10)
    SetTextProportional(1)
    SetTextColour(255, 255, 0, 255)
    SetTextEntry("STRING")
    AddTextComponentString(text)
    DrawText(x, y)
end

RegisterNetEvent('unjailPlayer')
AddEventHandler('unjailPlayer', function(unjailCoords)
    if unjailCoords then
        local playerPed = PlayerPedId()

        DoScreenFadeOut(800)
        while not IsScreenFadedOut() do
            Citizen.Wait(50)
        end

        SetEntityCoords(playerPed, unjailCoords.x, unjailCoords.y, unjailCoords.z)

        while not HasCollisionLoadedAroundEntity(playerPed) do
            Citizen.Wait(0)
        end

        DoScreenFadeIn(800)
    else
        print("Error: Unjail coordinates were not provided.")
    end
end)

