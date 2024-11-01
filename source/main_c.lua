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
            local player = NDCore.getPlayer(source)

            if IsPoliceJob(player) then
                TriggerEvent("openActionMenu", target)
                lib.showContext('policeactions')
            else
                print("You do not have permission to access the police menu.")
            end
        end 
    } 
}

-- Function to check if the player has a police job 
function IsPoliceJob(player) 
    local player = NDCore.getPlayer(source) -- Fetch player data 
    if player and player.job then 
        for _, jobIdentifier in ipairs(Config.jobIdentifiers) do 
            if player.job == jobIdentifier then 
                return true 
            end 
        end 
    end
    return false 
end

-- Add the target menu for all players globally 
CreateThread(function() 
    ox_target:addGlobalPlayer(actionMenuOptions)

    -- Continuously check for the key press
    while true do
        Wait(0) -- Wait for a frame
        if IsControlJustReleased(0, 168) then -- 168 corresponds to F7
            local player = NDCore.getPlayer(source)
            if player and IsPoliceJob(player) then 
                DisplayPoliceMenu() 
            else 
                print("You do not have permission to access the police menu.") 
            end 
        end
    end
end)

-- Event when character is loaded
AddEventHandler("ND:characterLoaded", function(character) 
    print("Character loaded:", character.firstname, character.lastname) 
end)

-- Event when character is updated 
AddEventHandler("ND:updateCharacter", function(character) 
    print("Character updated:", character.firstname, character.lastname) 
end)

-- Event when character is unloaded 
AddEventHandler("ND:characterUnloaded", function(character) 
    print("Character unloaded:", character.firstname, character.lastname) 
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
