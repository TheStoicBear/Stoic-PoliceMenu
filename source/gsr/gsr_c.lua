local gsrTimer = 0
local gsrPositive = false
local plyPed = PlayerPedId()
local gsrTestDistance = 5

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(1)
        GSRThread()
    end
end)

if Config.EnableCleanGSR then
    RegisterCommand(Config.CleanGSR, function()
        if lib.skillCheckActive() then
            lib.notify({ title = 'GSR', description = Config.Text.SkillCheckInProgress, type = 'error' })
            return
        end

        local skillCheckDifficulties = {'easy', 'easy', {areaSize = 60, speedMultiplier = 3}, 'hard'}
        local skillCheckInputs = {'w', 'a', 's', 'd', 'p'}

        local success = lib.skillCheck(skillCheckDifficulties, skillCheckInputs)

        if success then
            if gsrPositive then
                gsrPositive = false
                gsrTimer = 0
                lib.notify({ title = 'GSR', description = Config.Text.TCleaningGSR, type = 'success' })
            else
                lib.notify({ title = 'GSR', description = Config.Text.AlreadyClean, type = 'inform' })
            end
            print('Cleaned GSR')
        else
            lib.notify({ title = 'GSR', description = Config.Text.FailedSkillCheck, type = 'error' })
        end
    end)
end

RegisterCommand(Config.TestGSR, function()
    local playerCoords = GetEntityCoords(plyPed)
    for _, player in ipairs(GetActivePlayers()) do
        local targetPed = GetPlayerPed(player)
        local targetId = GetPlayerServerId(player)
        local distance = #(playerCoords-GetEntityCoords(targetPed))
        if targetPed ~= plyPed then
            if distance <= gsrTestDistance then
                print('GSR Tested: ' .. targetId)
                TriggerServerEvent('GSR:TestPlayer', targetId)
            else
                lib.notify({ title = 'GSR', description = tostring(Config.Text.NoSubjectError), type = 'error' })
            end
        end
    end
end)

-- RegisterCommand('gsrs', function()
--     if gsrPositive then
--         Notify('You Tested ^1Positive')
--     elseif not gsrPositive then
--         Notify('You Tested ^2Negative')
--     end
-- end)

RegisterNetEvent("GSR:TestNotify")
AddEventHandler("GSR:TestNotify", function(notHandler)
    lib.notify({ title = 'GSR', description = notHandler, type = 'inform' })
end)

RegisterNetEvent("GSR:TestHandler")
AddEventHandler("GSR:TestHandler", function(tester)
    if gsrPositive then
        TriggerServerEvent("GSR:TestCallback", tester, true)
    elseif not gsrPositive then
        TriggerServerEvent("GSR:TestCallback", tester, false)
    end
end)

function GSRThread()
    plyPed = PlayerPedId()
    if IsPedShooting(plyPed) then
        if gsrPositive then
            gsrTimer = Config.GSRAutoClean
        else
            gsrPositive = true
            gsrTimer = Config.GSRAutoClean
            Citizen.CreateThread(GSRThreadTimer)
        end
    end
end

function GSRThreadTimer()
    while gsrPositive do
        Citizen.Wait(1000)
        if gsrTimer == 0 then
            gsrPositive = false
        else
            gsrTimer = gsrTimer - 1
        end
    end
end

function Notify(text)
    lib.notify({ title = 'GSR', description = text, type = 'inform' })
end

