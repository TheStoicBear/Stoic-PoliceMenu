local player, access = nil, false
local cuffed, dragged, isdragging, plhplayer = false, false, false, 0

lib.registerContext(
    {
        id = "policemenu",
        title = "Police Menu",
        canClose = true,
        options = {
            {
                title = "Actions",
                onSelect = function()
                    lib.showContext("policeactions")
                end
            }
        }
    }
)
if Config.UseThirdEye then
    lib.registerContext({
        id = "policeactions",
        title = "Police Actions",
        canClose = true,
        options = {
            {
                title = "Cuff Suspect",
                onSelect = function()
                    ToggleCuffs()
                end
            },
            {
                title = "Drag Suspect",
                onSelect = function()
                    local source = GetPlayerPed(-1) -- Get the source player
                    ToggleDrag(source) -- Pass the source player to ToggleDrag
                end
            },
            {
                title = "Place in Vehicle",
                onSelect = function()
                    local source = GetPlayerPed(-1) -- Get the source player
                    PutInVehicle(source) -- Pass the source player to ToggleDrag
                end
            },
            {
                title = "Remove From Vehicle",
                onSelect = function()
                    UnseatVehicle()
                end
            },
            {
                title = "Remove Weapons",
                onSelect = function()
                    RemoveWeapons()
                end
            },
            {
                title = "Test for GSR",
                event = "gsr",
                enabled = config.search_player
            },
            {
                title = "Search Nearest Player",
                event = "search_player",
                enabled = config.search_player
            },
            {
                title = "Back",
                onSelect = function()
                    lib.showContext("police_menu")
                end,
                icon = "arrow-left",
                description = "Go back to Police menu"
            }
        }
    })
end

-- Register the main police actions radial menu
if Config.UseRadialMenu then
    lib.registerRadial(
        {
            id = "policeactions",
            items = {
                {
                    id = "cuff_suspect",
                    icon = "cuff",
                    label = "Cuff\nSuspect",
                    onSelect = function()
                        ToggleCuffs()
                    end
                },
                {
                    id = "drag_suspect",
                    icon = "drag",
                    label = "Drag\nSuspect",
                    onSelect = function()
                        ToggleDrag()
                    end
                },
                {
                    id = "place_in_vehicle",
                    icon = "place_vehicle",
                    label = "Place in\nVehicle",
                    onSelect = function()
                        PutInVehicle()
                    end
                },
                {
                    id = "remove_from_vehicle",
                    icon = "remove_vehicle",
                    label = "Remove From\nVehicle",
                    onSelect = function()
                        UnseatVehicle()
                    end
                },
                {
                    id = "remove_weapons",
                    icon = "remove_weapons",
                    label = "Remove\nWeapons",
                    onSelect = function()
                        RemoveWeapons()
                    end
                },
                {
                    id = "test_gsr",
                    icon = "gsr",
                    label = "Test for\nGSR",
                    onSelect = function()
                        TriggerEvent("gsr")
                    end,
                    enabled = config.search_player
                },
                {
                    id = "search_nearest_player",
                    icon = "search",
                    label = "Search\nNearest Player",
                    onSelect = function()
                        TriggerEvent("search_player")
                    end,
                    enabled = config.search_player
                },
                {
                    id = "back_to_police_menu",
                    icon = "arrow-left",
                    label = "Back",
                    onSelect = function()
                        lib.showContext("police_menu")
                    end,
                    description = "Go back to Police menu"
                }
            }
        }
    )
end

RegisterNetEvent("accessresponse")
AddEventHandler(
    "accessresponse",
    function(toggle)
        access = toggle
    end
)

Citizen.CreateThread(
    function()
        while not NetworkIsPlayerActive(PlayerId()) do
            Wait(0)
        end
        RefreshPerms()

        while true do
            AllMenu()
            Wait(0)
        end
    end
)

Citizen.CreateThread(
    function()
        while true do
            Wait(0)
            player = PlayerPedId()
            HandleDrag()
        end
    end
)

function AllMenu()
    if access then
        if lib.showContext("policemenu") then
            if lib.showContext("policeloadouts") then
                HandleLoadouts()
            elseif lib.showContext("policeactions") then
                HandleActions()
            end
        end
    end
end

function RefreshPerms()
    if NetworkIsPlayerActive(PlayerId()) then
        TriggerServerEvent("refreshscriptperms")
    end
end
-- Actions Menu Function
RegisterNetEvent("policemenu")
AddEventHandler(
    "policemenu",
    function()
        lib.showContext("policeactions")
    end
)

RegisterCommand(
    "openpm",
    function()
        lib.showContext("policemenu")
    end
)

--Actions
function PlayerCuffed()
    if not cuffed then
        ShowNotification("Player Cuffed")
        TaskPlayAnim(player, "mp_arrest_paired", "crook_p2_back_right", 8.0, -8, 3750, 2, 0, 0, 0, 0)
        Citizen.Wait(4000)
        cuffed = true
    else
        ShowNotification("Player Uncuffed")
        dragged = false
        cuffed = false
        Citizen.Wait(100)
        ClearPedTasksImmediately(player)
    end
end

RegisterNetEvent("dragplayer")
AddEventHandler(
    "dragplayer",
    function(otherplayer)
        if cuffed then
            isdragging = not isdragging
            plhplayer = tonumber(otherplayer)
            if isdragging then
                ShowNotification("Dragging Player")
            else
                -- Stop dragging, clear tasks and animations for the source ped
                ClearPedTasksImmediately(PlayerPedId())
                
                ShowNotification("Dragging Player Stopped")
            end
        else
            ShowNotification("Error: Not Cuffed")
        end
    end
)


RegisterNetEvent("removeplayerweapons")
AddEventHandler(
    "removeplayerweapons",
    function()
        RemoveAllPedWeapons(player, true)
    end
)

RegisterNetEvent("forceplayerintovehicle")
AddEventHandler(
    "forceplayerintovehicle",
    function()
        if cuffed then
            local pos = GetEntityCoords(player)
            local playercoords = GetOffsetFromEntityInWorldCoords(player, 0.0, 20.0, 0.0)

            local rayHandle =
                CastRayPointToPoint(
                pos.x,
                pos.y,
                pos.z,
                playercoords.x,
                playercoords.y,
                playercoords.z,
                10,
                GetPlayerPed(-1),
                0
            )
            local _, _, _, _, vehicleHandle = GetRaycastResult(rayHandle)

            if vehicleHandle ~= nil then
                SetPedIntoVehicle(player, vehicleHandle, 2)
            end
        end
    end
)

RegisterNetEvent("removeplayerfromvehicle")
AddEventHandler(
    "removeplayerfromvehicle",
    function(otherplayer)
        local ped = GetPlayerPed(otherplayer)
        ClearPedTasksImmediately(ped)
        playercoords = GetEntityCoords(player, true)
        local xnew = playercoords.x + 2
        local ynew = playercoords.y + 2

        SetEntityCoords(player, xnew, ynew, playercoords.z)
    end
)

RegisterNetEvent("cuffplayer")
AddEventHandler("cuffplayer", PlayerCuffed)

function DisableControls()
    DisableControlAction(1, 140, true)
    DisableControlAction(1, 141, true)
    DisableControlAction(1, 142, true)
    --SetPedPathCanUseLadders(player, false)
end

function PlayerUncuffing()
    ExecuteCommand("e uncuff")
end

function PlayerCancelEmote()
    ExecuteCommand("e c")
end

function HandleDrag(source)
    while cuffed or dragged or isdragging do
        Citizen.Wait(0)

        if cuffed then
            RequestAnimDict("mp_arresting")
            while not HasAnimDictLoaded("mp_arresting") do
                Citizen.Wait(0)
            end

            while IsPedBeingStunned(player, false) do
                ClearPedTasksImmediately(player)
            end
            TaskPlayAnim(player, "mp_arresting", "idle", 8.0, -8, -1, 16, 0, 0, 0, 0)
            DisableControls()
        end

        if IsPlayerDead(PlayerPedId()) then
            cuffed = false
            isdragging = false
            dragged = false
        end

        if isdragging then
            local draggedPlayerPed = GetPlayerPed(GetPlayerFromServerId(plhplayer))
            local draggingPlayerPed = PlayerPedId()

            -- Attach the dragging player's ped to the dragged player's ped
            AttachEntityToEntity(
                draggingPlayerPed,
                draggedPlayerPed,
                4103,
                11816,
                0.48,
                0.00,
                0.0,
                0.0,
                0.0,
                0.0,
                false,
                false,
                false,
                false,
                2,
                true
            )
            dragged = true
        else
            if not IsPedInParachuteFreeFall(player) and dragged then
                dragged = false
                DetachEntity(PlayerPedId(), true, false)
                ClearPedTasks(PlayerPedId())
                ClearPedTasksImmediately(PlayerPedId())
            end
        end

    end
end

function GetPlayers()
    local players = {}
    for i, player in ipairs(GetActivePlayers()) do
        local ped = GetPlayerPed(player)
        table.insert(players, player)
    end
    return players
end

function GetClosestPlayer()
    local players = GetPlayers()
    local closestDistance, closestPlayer = -1, -1
    local playercoords = GetEntityCoords(player, 0)

    for i, value in ipairs(players) do
        local target = GetPlayerPed(value)
        if (target ~= player) then
            local targetCoords = GetEntityCoords(GetPlayerPed(value), 0)
            local distance =
                Vdist(
                targetCoords["x"],
                targetCoords["y"],
                targetCoords["z"],
                playercoords.x,
                playercoords.y,
                playercoords.z
            )
            if (closestDistance == -1 or closestDistance > distance) then
                closestPlayer = value
                closestDistance = distance
            end
        end
    end
    return closestPlayer, closestDistance
end

function RemoveWeapons()
    local closeplayer, distance = GetClosestPlayer()
    if (distance ~= -1 and distance < 3) then
        TriggerServerEvent("removeplayerweapons", GetPlayerServerId(closeplayer))
    else
        ShowNotification("Error: No Player Near")
    end
end

function ToggleCuffs()
    local closeplayer, distance = GetClosestPlayer()
    if (distance ~= -1 and distance < 3) then
        RequestAnimDict("mp_arrest_paired")
        while not HasAnimDictLoaded("mp_arrest_paired") do
            Wait(0)
        end
        TaskPlayAnim(player, "mp_arrest_paired", "crook_p2_back_right", 8.0, -8, 3750, 2, 0, 0, 0, 0)
        TriggerServerEvent("cuffplayer", GetPlayerServerId(closeplayer))
        ShowNotification("Player Cuffed")
        RequestAnimDict("mp_arrest_paired")
        while not HasAnimDictLoaded("mp_arrest_paired") do
            Wait(0)
        end
        TaskPlayAnim(GetPlayerPed(-1), "mp_arrest_paired", "cop_p2_back_right", 8.0, -8, 3750, 2, 0, 0, 0, 0)
    else
        ShowNotification("Error: No Player Near")
    end
end

function ToggleDrag(source)
    local closeplayer, distance = GetClosestPlayer()
    if distance ~= -1 and distance < 3 then
        TriggerServerEvent("dragplayer", GetPlayerServerId(closeplayer))
        
        if not animPlaying then
            -- Request and play animation for the source player
            RequestAnimDict("switch@trevor@escorted_out")
            while not HasAnimDictLoaded("switch@trevor@escorted_out") do
                Citizen.Wait(0)
            end
            TaskPlayAnim(
                source, -- Source player Ped
                "switch@trevor@escorted_out",
                "001215_02_trvs_12_escorted_out_idle_guard2",
                8.0,
                1.0,
                -1,
                49,
                0,
                0,
                0,
                0
            )
            animPlaying = true
        else
            -- If animation is already playing, stop it
            ClearPedTasksImmediately(source)
            animPlaying = false
        end
    else
        ShowNotification("Error: No Player Near")
    end
end


function PutInVehicle(source)
    local closeplayer, distance = GetClosestPlayer()
    if (distance ~= -1 and distance < 3) then
        TriggerServerEvent("forceplayerintovehicle", GetPlayerServerId(closeplayer))
        ClearPedTasksImmediately(source)
    else
        ShowNotification("Error: No Player Near")
    end
end

function UnseatVehicle()
    local closeplayer, distance = GetClosestPlayer()
    if (distance ~= -1 and distance < 3) then
        TriggerServerEvent("removeplayerfromvehicle", GetPlayerServerId(closeplayer))
    else
        ShowNotification("Error: No Player Near")
    end
end

RegisterCommand(
    "traffic",
    function()
        lib.showContext("menu:main")
    end
)

function ShowNotification(data)
    -- Trigger notification
    lib.notify(data)
end

local sz = nil

lib.registerContext(
    {
        id = "menu:main",
        title = "Traffic Menu",
        canClose = true,
        options = {
            {
                title = "Slow Traffic",
                onSelect = function()
                    if sz ~= nil then
                        RemoveSpeedZone(sz)
                        ShowNotification(
                            {
                                title = "Traffic Resumed",
                                type = "success"
                            }
                        )
                        sz = nil
                        RemoveBlip(tcblip)
                    else
                        ShowNotification(
                            {
                                title = "Traffic Slowed",
                                type = "warning"
                            }
                        )
                        tcblip = AddBlipForRadius(GetEntityCoords(GetPlayerPed(-1)), 40.0)
                        SetBlipAlpha(tcblip, 80)
                        SetBlipColour(tcblip, 5)
                        sz = AddSpeedZoneForCoord(GetEntityCoords(GetPlayerPed(-1)), 40.0, 5.0, false)
                    end
                end,
                icon = "car",
                description = "Slow down traffic in the area."
            },
            {
                title = "Resume Traffic",
                onSelect = function()
                    if sz ~= nil then
                        RemoveSpeedZone(sz)
                        ShowNotification(
                            {
                                title = "Traffic Resumed",
                                type = "success"
                            }
                        )
                        sz = nil
                        RemoveBlip(tcblip)
                    end
                end,
                icon = "play",
                description = "Resume normal traffic flow."
            },
            {
                title = "Stop Traffic",
                onSelect = function()
                    if sz ~= nil then
                        RemoveSpeedZone(sz)
                        ShowNotification(
                            {
                                title = "Traffic Resumed",
                                type = "success"
                            }
                        )
                        sz = nil
                        RemoveBlip(tcblip)
                    else
                        ShowNotification(
                            {
                                title = "Traffic Stopped",
                                type = "error"
                            }
                        )
                        tcblip = AddBlipForRadius(GetEntityCoords(GetPlayerPed(-1)), 50.0)
                        sz = AddSpeedZoneForCoord(GetEntityCoords(GetPlayerPed(-1)), 50.0, 0.0, false)
                        SetBlipAlpha(tcblip, 80)
                        SetBlipColour(tcblip, 1)
                    end
                end,
                icon = "stop",
                description = "Completely stop traffic in the area."
            }
        }
    }
)
