------------------------------------------------------------------------------[ VARIABLES ]------------------------------------------------------------------------------
PlayerJob = {}

local QBCore = exports['qb-core']:GetCoreObject()

local Casings = {}
local CurrentCasing = nil

local Blooddrops = {}
local CurrentBlooddrop = nil

local Fingerprints = {}
local CurrentFingerprint = 0

local Bullethole = {}
local CurrentBullethole = nil

local Fragments = {}
local CurrentVehicleFragment = nil

local currentTime = 0
local r, g, b = 0, 0, 0

local drawLine_r, drawLine_g, drawLine_b = 0, 0, 0
local FingerprintsList = {}

local WhitelistedWeapons = {
    `weapon_unarmed`,
    `weapon_snowball`,
    `weapon_stungun`,
    `weapon_petrolcan`,
    `weapon_hazardcan`,
    `weapon_fireextinguisher`
}

------------------------------------------------------------------------------[ FUNCTIONS ]------------------------------------------------------------------------------
local function DrawText3D(x, y, z, text)
    SetTextScale(0.30, 0.30)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 215)
    BeginTextCommandDisplayText('STRING')
    SetTextCentre(true)
    AddTextComponentSubstringPlayerName(text)
    SetDrawOrigin(x, y, z, 0)
    EndTextCommandDisplayText(0.0, 0.0)
    local factor = (string.len(text)) / 370
    DrawRect(0.0, 0.0 + 0.0125, 0.015 + factor, 0.03, 0, 0, 0, 68)
    ClearDrawOrigin()
end

local function WhitelistedWeapon(weapon)
    for i = 1, #WhitelistedWeapons do
        if WhitelistedWeapons[i] == weapon then
            return true
        end
    end
    return false
end

local function DropBulletCasing(weapon, ped, currentTime)
    if IsPedSwimming(ped) then return end
    local randX = math.random() + math.random(-1, 1)
    local randY = math.random() + math.random(-1, 1)
    local coords = GetOffsetFromEntityInWorldCoords(ped, randX, randY, 0)
    TriggerServerEvent('evidence:server:CreateCasing', weapon, coords, currentTime)
    Wait(350)
end

local function SendBulletHole(weapon, raycastcoords, pedcoords, heading, currentTime, entityHit, r, g, b)
    if raycastcoords ~= nil then
        if GetEntityType(entityHit) == 2 then
            TriggerServerEvent('evidence:server:CreateVehicleFragment', weapon, raycastcoords, pedcoords, heading, currentTime, entityHit, r, g, b)
        else
            TriggerServerEvent('evidence:server:CreateBullethole', weapon, raycastcoords, pedcoords, heading, currentTime)
        end
        Wait(350)
    end
end

local function DnaHash(s)
    local h = string.gsub(s, '.', function(c)
        return string.format('%02x', string.byte(c))
    end)
    return h
end

local function RotationToDirection(rotation)
	local adjustedRotation =
	{
		x = (math.pi / 180) * rotation.x,
		y = (math.pi / 180) * rotation.y,
		z = (math.pi / 180) * rotation.z
	}
	local direction =
	{
		x = -math.sin(adjustedRotation.z) * math.abs(math.cos(adjustedRotation.x)),
		y = math.cos(adjustedRotation.z) * math.abs(math.cos(adjustedRotation.x)),
		z = math.sin(adjustedRotation.x)
	}
	return direction
end

local function RayCastGamePlayCamera(distance)
    local playerPed = PlayerPedId()
    local cameraRotation = GetGameplayCamRot()
	local cameraCoord = GetGameplayCamCoord()
	local direction = RotationToDirection(cameraRotation)
	local destination =
	{
		x = cameraCoord.x + direction.x * distance,
		y = cameraCoord.y + direction.y * distance,
		z = cameraCoord.z + direction.z * distance
	}
	local result, hit, endCoords, _, entityHit = GetShapeTestResult(StartShapeTestRay(cameraCoord.x, cameraCoord.y, cameraCoord.z, destination.x, destination.y, destination.z, -1, PlayerPedId(), 0))
	return hit == 1, endCoords, entityHit
end

local function DrawLineDisableNotify()
    if Config.Notify == "qb" then
        QBCore.Functions.Notify(Lang:t('error.drawLine_disabled'), 'error')
    elseif Config.Notify == "ox" then
        lib.notify({ title = 'Evidence', description = Lang:t('error.error.drawLine_disabled'), duration = 5000, type = 'error' })
    else
        print(Lang:t('error.config_error'))
    end
end

------------------------------------------------------------------------------[ EVENTS ]------------------------------------------------------------------------------
AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        local player = QBCore.Functions.GetPlayerData()
        PlayerJob = player.job
    end
end)

AddEventHandler('QBCore:Client:OnPlayerLoaded', function()
    local player = QBCore.Functions.GetPlayerData()
    PlayerJob = player.job
    if GetResourceState('ox_inventory'):match("start") then
        exports.ox_inventory:displayMetadata({
            label = 'Label',
            type = 'Type',
            street = 'Street',
            ammolabel = 'Ammo Label',
            ammotype = 'Ammo Type',
            serie = 'Serial',
            dnalabel = 'DNA',
            bloodtype = 'Blood Type',
            fingerprint = 'Fingerprint',
            rgb = 'RGB',
        })
    end
end)

RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    PlayerJob = {}
    FingerprintsList = {}
end)

RegisterNetEvent('QBCore:Client:SetDuty', function(newDuty)
    PlayerJob.onduty = newDuty
end)

RegisterNetEvent('QBCore:Client:OnJobUpdate', function(JobInfo)
    PlayerJob = JobInfo
end)

RegisterNetEvent('evidence:client:PlayerPickUpAnimation', function()
    local playerPed = PlayerPedId()
    RequestAnimDict("pickup_object")
    while not HasAnimDictLoaded("pickup_object") do
        Wait(0)
    end
    TaskPlayAnim(playerPed, "pickup_object", "pickup_low", 8.0, -8.0, -1, 1, 0, false, false, false)
    Wait(2000)
    ClearPedTasks(playerPed)
end)

-----------------------------------------[ BLOOD ]-----------------------------------------
RegisterNetEvent('evidence:client:AddBlooddrop', function(bloodId, citizenid, bloodtype, coords)
    local ped = PlayerPedId()
    if IsPedSwimming(ped) then return end
    Blooddrops[bloodId] = {
        citizenid = citizenid,
        bloodtype = bloodtype,
        coords = {
            x = coords.x,
            y = coords.y,
            z = coords.z - 0.9
        },
        time = GetGameTimer()
    }
end)

RegisterNetEvent('evidence:client:RemoveBlooddrop', function(bloodId)
    Blooddrops[bloodId] = nil
    CurrentBlooddrop = 0
end)

RegisterNetEvent('evidence:client:ClearBlooddropsInArea', function()
    local pos = GetEntityCoords(PlayerPedId())
    local blooddropList = {}
    QBCore.Functions.Progressbar('clear_blooddrops', Lang:t('progressbar.blood_clear'), 5000, false, true, {
        disableMovement = false,
        disableCarMovement = false,
        disableMouse = false,
        disableCombat = true
    }, {}, {}, {}, function() -- Done
        if Blooddrops and next(Blooddrops) then
            for bloodId, _ in pairs(Blooddrops) do
                if #(pos -
                        vector3(Blooddrops[bloodId].coords.x, Blooddrops[bloodId].coords.y, Blooddrops[bloodId].coords.z)) <
                    10.0 then
                    blooddropList[#blooddropList + 1] = bloodId
                end
            end
            if Config.Notify == "qb" then
                QBCore.Functions.Notify(Lang:t('success.blood_clear'), 'success')
            elseif Config.Notify == "ox" then
                lib.notify({ title = 'Evidence', description = Lang:t('success.blood_clear'), duration = 5000, type = 'success' })
            else
                print(Lang:t('error.config_error'))
            end
            TriggerServerEvent('evidence:server:ClearBlooddrops', blooddropList)
        end
    end, function() -- Cancel
        if Config.Notify == "qb" then
            QBCore.Functions.Notify(Lang:t('error.blood_not_cleared'), 'error')
        elseif Config.Notify == "ox" then
            lib.notify({ title = 'Evidence', description = Lang:t('error.blood_not_cleared'), duration = 5000, type = 'error' })
        else
            print(Lang:t('error.config_error'))
        end
    end)
end)

-----------------------------------------[ FINGERPRINT ]-----------------------------------------
RegisterNetEvent('evidence:client:AddFingerPrint', function(fingerId, fingerprint, coords)
    local ped = PlayerPedId()
    if IsPedSwimming(ped) then return end
    Fingerprints[fingerId] = {
        fingerprint = fingerprint,
        coords = {
            x = coords.x,
            y = coords.y,
            z = coords.z - 0.9
        },
        time = GetGameTimer(),
    }
end)

RegisterNetEvent('evidence:client:RemoveFingerprint', function(fingerId)
    Fingerprints[fingerId] = nil
    CurrentFingerprint = 0
end)

-----------------------------------------[ CASSINGS ]-----------------------------------------
RegisterNetEvent('evidence:client:AddCasing', function(casingId, weapon, coords, serie, currentTime)
    Casings[casingId] = {
        type = weapon,
        serie = serie and serie or Lang:t('evidence.serial_not_visible'),
        coords = {
            x = coords.x,
            y = coords.y,
            z = coords.z - 0.9
        },
        time = currentTime
    }
end)

RegisterNetEvent('evidence:client:RemoveCasing', function(casingId)
    Casings[casingId] = nil
    CurrentCasing = 0
end)

RegisterNetEvent('evidence:client:ClearCasingsInArea', function()
    local pos = GetEntityCoords(PlayerPedId())
    local casingList = {}
    QBCore.Functions.Progressbar('clear_casings', Lang:t('progressbar.bullet_casing'), 5000, false, true, {
        disableMovement = false,
        disableCarMovement = false,
        disableMouse = false,
        disableCombat = true
    }, {}, {}, {}, function() -- Done
        if Casings and next(Casings) then
            for casingId, _ in pairs(Casings) do
                if #(pos - vector3(Casings[casingId].coords.x, Casings[casingId].coords.y, Casings[casingId].coords.z)) <
                    10.0 then
                    casingList[#casingList + 1] = casingId
                end
            end
            if Config.Notify == "qb" then
                QBCore.Functions.Notify(Lang:t('success.bullet_casing_removed'), 'success')
            elseif Config.Notify == "ox" then
                lib.notify({ title = 'Evidence', description = Lang:t('success.bullet_casing_removed'), duration = 5000, type = 'success' })
            else
                print(Lang:t('error.config_error'))
            end
            TriggerServerEvent('evidence:server:ClearCasings', casingList)
        end
    end, function() -- Cancel
        if Config.Notify == "qb" then
            QBCore.Functions.Notify(Lang:t('error.bullet_casing_not_removed'), 'error')
        elseif Config.Notify == "ox" then
            lib.notify({ title = 'Evidence', description = Lang:t('error.bullet_casing_not_removed'), duration = 5000, type = 'error' })
        else
            print(Lang:t('error.config_error'))
        end
    end)
end)

-----------------------------------------[ BULLETHOLE ]-----------------------------------------
RegisterNetEvent('evidence:client:AddBullethole', function(bulletholeId, weapon, raycastcoords, pedcoords, heading, currentTime, serie)
    if Config.PoliceCreatesEvidence and PlayerJob.type == 'leo' then
        drawLine_r = 0
        drawLine_g = 255
        drawLine_b = 0
    else
        drawLine_r = 255
        drawLine_g = 0
        drawLine_b = 0
    end
    Bullethole[bulletholeId] = {
        drawLine_r = drawLine_r,
        drawLine_g = drawLine_g,
        drawLine_b = drawLine_b,
        type = weapon,
        serie = serie and serie or Lang:t('evidence.serial_not_visible'),
        coords = {
            x = raycastcoords.x,
            y = raycastcoords.y,
            z = raycastcoords.z
        },
        pedcoord = {
            x = pedcoords.x,
            y = pedcoords.y,
            z = pedcoords.z,
            h = heading
        },
        time = currentTime
    }
end)

RegisterNetEvent('evidence:client:RemoveBullethole', function(bulletholeId)
    Bullethole[bulletholeId] = nil
    CurrentBullethole = 0
end)

RegisterNetEvent('evidence:client:ClearBulletholeInArea', function()
    local pos = GetEntityCoords(PlayerPedId())
    local bulletholeList = {}
    QBCore.Functions.Progressbar('clear_bullethole', Lang:t('progressbar.bullet_hole'), 5000, false, true, {
        disableMovement = false,
        disableCarMovement = false,
        disableMouse = false,
        disableCombat = true
    }, {}, {}, {}, function() -- Done
        if Bullethole and next(Bullethole) then
            for bulletholeId, _ in pairs(Bullethole) do
                if #(pos - vector3(Bullethole[bulletholeId].coords.x, Bullethole[bulletholeId].coords.y, Bullethole[bulletholeId].coords.z)) <
                    10.0 then
                        bulletholeList[#bulletholeList + 1] = bulletholeId
                end
            end
            if Config.Notify == "qb" then
                QBCore.Functions.Notify(Lang:t('success.bullet_hole_removed'), 'success')
            elseif Config.Notify == "ox" then
                lib.notify({ title = 'Evidence', description = Lang:t('success.bullet_hole_removed'), duration = 5000, type = 'success' })
            else
                print(Lang:t('error.config_error'))
            end
            TriggerServerEvent('evidence:server:ClearBullethole', bulletholeList)
        end
    end, function() -- Cancel
        if Config.Notify == "qb" then
            QBCore.Functions.Notify(Lang:t('error.bullet_hole_not_removed'), 'error')
        elseif Config.Notify == "ox" then
            lib.notify({ title = 'Evidence', description = Lang:t('error.bullet_hole_not_removed'), duration = 5000, type = 'error' })
        else
            print(Lang:t('error.config_error'))
        end
    end)
end)

-----------------------------------------[ VEHICLE FRAGEMENTS ]-----------------------------------------
RegisterNetEvent('evidence:client:AddVehicleFragment', function(vehiclefragmentId, weapon, raycastcoords, pedcoords, heading, currentTime, entityHit, r, g, b, serie)
    if Config.PoliceCreatesEvidence and PlayerJob.type == 'leo' then
        drawLine_r = 0
        drawLine_g = 255
        drawLine_b = 0
    else
        drawLine_r = 255
        drawLine_g = 0
        drawLine_b = 0
    end
    Fragments[vehiclefragmentId] = {
        coords = {
            x = raycastcoords.x,
            y = raycastcoords.y,
            z = raycastcoords.z
        },
        pedcoord = {
            x = pedcoords.x,
            y = pedcoords.y,
            z = pedcoords.z,
            h = heading
        },
        r = r,
        g = g,
        b = b,
        type = weapon,
        serie = serie and serie or Lang:t('evidence.serial_not_visible'),
        drawLine_r = drawLine_r,
        drawLine_g = drawLine_g,
        drawLine_b = drawLine_b,
        time = currentTime
    }
end)

RegisterNetEvent('evidence:client:RemoveVehicleFragment', function(vehiclefragmentId)
    Fragments[vehiclefragmentId] = nil
    CurrentVehicleFragment = 0
end)

RegisterNetEvent('evidence:client:ClearVehicleFragmentsInArea', function()
    local pos = GetEntityCoords(PlayerPedId())
    local vehiclefragmentList = {}
    QBCore.Functions.Progressbar('clear_fragments', Lang:t('progressbar.vehicle_fragments'), 5000, false, true, {
        disableMovement = false,
        disableCarMovement = false,
        disableMouse = false,
        disableCombat = true
    }, {}, {}, {}, function() -- Done
        if Fragments and next(Fragments) then
            for vehiclefragmentId, _ in pairs(Fragments) do
                if #(pos - vector3(Fragments[vehiclefragmentId].coords.x, Fragments[vehiclefragmentId].coords.y, Fragments[vehiclefragmentId].coords.z)) <
                    10.0 then
                        vehiclefragmentList[#vehiclefragmentList + 1] = vehiclefragmentId
                end
            end
            if Config.Notify == "qb" then
                QBCore.Functions.Notify(Lang:t('success.vehicle_fragment_removed'), 'success')
            elseif Config.Notify == "ox" then
                lib.notify({ title = 'Evidence', description = Lang:t('success.vehicle_fragment_removed'), duration = 5000, type = 'success' })
            else
                print(Lang:t('error.config_error'))
            end
            TriggerServerEvent('evidence:server:ClearVehicleFragments', vehiclefragmentList)
        end
    end, function() -- Cancel
        if Config.Notify == "qb" then
            QBCore.Functions.Notify(Lang:t('error.vehicle_fragments_not_removed'), 'error')
        elseif Config.Notify == "ox" then
            lib.notify({ title = 'Evidence', description = Lang:t('error.vehicle_fragments_not_removed'), duration = 5000, type = 'error' })
        else
            print(Lang:t('error.config_error'))
        end
    end)
end)

-----------------------------------------[ EVENTS FOR COMMANDS/ITEMS ]-----------------------------------------
RegisterNetEvent('evidence:client:ClearScene', function()
    local pos = GetEntityCoords(PlayerPedId())
    local bulletholeList = {}
    local casingList = {}
    local blooddropList = {}
    local fingerprintList = {}
    local vehiclefragmentList = {}
    QBCore.Functions.Progressbar('clear_scene', Lang:t('progressbar.crime_scene'), 5000, false, true, {
        disableMovement = false,
        disableCarMovement = false,
        disableMouse = false,
        disableCombat = true
    }, {}, {}, {}, function() -- Done
        if Bullethole and next(Bullethole) then
            for bulletholeId, _ in pairs(Bullethole) do
                if #(pos - vector3(Bullethole[bulletholeId].coords.x, Bullethole[bulletholeId].coords.y, Bullethole[bulletholeId].coords.z)) <
                    30.0 then
                        bulletholeList[#bulletholeList + 1] = bulletholeId
                end
            end
            TriggerServerEvent('evidence:server:ClearBullethole', bulletholeList)
        end
        if Casings and next(Casings) then
            for casingId, _ in pairs(Casings) do
                if #(pos - vector3(Casings[casingId].coords.x, Casings[casingId].coords.y, Casings[casingId].coords.z)) <
                    30.0 then
                    casingList[#casingList + 1] = casingId
                end
            end
            TriggerServerEvent('evidence:server:ClearCasings', casingList)
        end
        if Blooddrops and next(Blooddrops) then
            for bloodId, _ in pairs(Blooddrops) do
                if #(pos -
                        vector3(Blooddrops[bloodId].coords.x, Blooddrops[bloodId].coords.y, Blooddrops[bloodId].coords.z)) <
                        30.0 then
                    blooddropList[#blooddropList + 1] = bloodId
                end
            end
            TriggerServerEvent('evidence:server:ClearBlooddrops', blooddropList)
        end
        if Fingerprints and next(Fingerprints) then
            for fingerId, _ in pairs(Fingerprints) do
                if #(pos -
                        vector3(Fingerprints[fingerId].coords.x, Fingerprints[fingerId].coords.y, Fingerprints[fingerId].coords.z)) <
                        30.0 then
                            fingerprintList[#fingerprintList + 1] = fingerId
                end
            end
            TriggerServerEvent('evidence:server:ClearBlooddrops', fingerprintList)
        end
        if Fragments and next(Fragments) then
            for vehiclefragmentId, _ in pairs(Fragments) do
                if #(pos -
                        vector3(Fragments[vehiclefragmentId].coords.x, Fragments[vehiclefragmentId].coords.y, Fragments[vehiclefragmentId].coords.z)) <
                        30.0 then
                            vehiclefragmentList[#vehiclefragmentList + 1] = vehiclefragmentId
                end
            end
            TriggerServerEvent('evidence:server:ClearVehicleFragments', vehiclefragmentList)
        end
        if Config.Notify == "qb" then
            QBCore.Functions.Notify(Lang:t('success.crime_scene_removed'), 'success')
        elseif Config.Notify == "ox" then
            lib.notify({ title = 'Evidence', description = Lang:t('success.crime_scene_removed'), duration = 5000, type = 'success' })
        else
            print(Lang:t('error.config_error'))
        end
    end, function() -- Cancel
        if Config.Notify == "qb" then
            QBCore.Functions.Notify(Lang:t('error.scene_not_removed'), 'error')
        elseif Config.Notify == "ox" then
            lib.notify({ title = 'Evidence', description = Lang:t('error.scene_not_removed'), duration = 5000, type = 'error' })
        else
            print(Lang:t('error.config_error'))
        end
    end)
end)

RegisterNetEvent('evidence:client:ClearSceneCrime', function()
    local pos = GetEntityCoords(PlayerPedId())
    local bulletholeList = {}
    local casingList = {}
    local blooddropList = {}
    local fingerprintList = {}
    local vehiclefragmentList = {}
    QBCore.Functions.Progressbar('clear_scene', Lang:t('progressbar.crime_scene'), 3000, false, true, {
        disableMovement = false,
        disableCarMovement = false,
        disableMouse = false,
        disableCombat = true
    }, {}, {}, {}, function() -- Done
        if Bullethole and next(Bullethole) then
            for bulletholeId, _ in pairs(Bullethole) do
                if #(pos - vector3(Bullethole[bulletholeId].coords.x, Bullethole[bulletholeId].coords.y, Bullethole[bulletholeId].coords.z)) <
                    30.0 then
                        bulletholeList[#bulletholeList + 1] = bulletholeId
                end
            end
            TriggerServerEvent('evidence:server:ClearBullethole', bulletholeList)
        end
        if Casings and next(Casings) then
            for casingId, _ in pairs(Casings) do
                if #(pos - vector3(Casings[casingId].coords.x, Casings[casingId].coords.y, Casings[casingId].coords.z)) <
                    30.0 then
                    casingList[#casingList + 1] = casingId
                end
            end
            TriggerServerEvent('evidence:server:ClearCasings', casingList)
        end
        if Blooddrops and next(Blooddrops) then
            for bloodId, _ in pairs(Blooddrops) do
                if #(pos -
                        vector3(Blooddrops[bloodId].coords.x, Blooddrops[bloodId].coords.y, Blooddrops[bloodId].coords.z)) <
                        30.0 then
                    blooddropList[#blooddropList + 1] = bloodId
                end
            end
            TriggerServerEvent('evidence:server:ClearBlooddrops', blooddropList)
        end
        if Fingerprints and next(Fingerprints) then
            for fingerId, _ in pairs(Fingerprints) do
                if #(pos -
                        vector3(Fingerprints[fingerId].coords.x, Fingerprints[fingerId].coords.y, Fingerprints[fingerId].coords.z)) <
                        30.0 then
                            fingerprintList[#fingerprintList + 1] = fingerId
                end
            end
            TriggerServerEvent('evidence:server:ClearBlooddrops', fingerprintList)
        end
        if Fragments and next(Fragments) then
            for vehiclefragmentId, _ in pairs(Fragments) do
                if #(pos -
                        vector3(Fragments[vehiclefragmentId].coords.x, Fragments[vehiclefragmentId].coords.y, Fragments[vehiclefragmentId].coords.z)) <
                        30.0 then
                            vehiclefragmentList[#vehiclefragmentList + 1] = vehiclefragmentId
                end
            end
            TriggerServerEvent('evidence:server:ClearVehicleFragments', vehiclefragmentList)
        end
        if Config.Notify == "qb" then
            QBCore.Functions.Notify(Lang:t('success.crime_scene_removed'), 'success')
        elseif Config.Notify == "ox" then
            lib.notify({ title = 'Evidence', description = Lang:t('success.crime_scene_removed'), duration = 5000, type = 'success' })
        else
            print(Lang:t('error.config_error'))
        end
    end, function() -- Cancel
        if Config.Notify == "qb" then
            QBCore.Functions.Notify(Lang:t('error.scene_not_removed'), 'error')
        elseif Config.Notify == "ox" then
            lib.notify({ title = 'Evidence', description = Lang:t('error.scene_not_removed'), duration = 5000, type = 'error' })
        else
            print(Lang:t('error.config_error'))
        end
    end)
end)

------------------------------------------------------------------------------[ THREADS ]------------------------------------------------------------------------------

-----------------------------------------[ DROP EVIDENCE ]-----------------------------------------
CreateThread(function()
    while true do
        Wait(3)
        if PlayerJob.type == 'leo' and not Config.PoliceCreatesEvidence then return end
        local ped = PlayerPedId()
        if IsPedShooting(ped) then
            local pedcoords = GetEntityCoords(PlayerPedId())
            local heading = GetEntityHeading(PlayerPedId())

            local hit, raycastcoords, entityHit = RayCastGamePlayCamera(1000.0)
            local weapon = GetSelectedPedWeapon(ped)
            if not WhitelistedWeapon(weapon) then
                currentTime = GetGameTimer()
                r, g, b = GetVehicleColor(entityHit)

                SendBulletHole(weapon, raycastcoords, pedcoords, heading, currentTime, entityHit, r, g, b)
                DropBulletCasing(weapon, ped, currentTime)
            end
        end
    end
end)

-----------------------------------------[ REMOVE EVIDENCE AFTER 30 MINS ]-----------------------------------------
CreateThread(function()
    while true do
        Wait(60000)
        local bulletholeList = {}
        local casingList = {}
        local blooddropList = {}
        local fingerprintList = {}
        local vehiclefragmentList = {}
        local RemoveEvidence = Config.RemoveEvidence * 60 * 1000
        -----------------------------[ CASINGS ]-----------------------------
        if Casings and next(Casings) then
            for k, v in pairs(Casings) do
                CurrentCasing = k
                local timer = GetGameTimer()
                local currentTimer = Casings[CurrentCasing].time + RemoveEvidence
                if timer > Casings[CurrentCasing].time + RemoveEvidence and currentTimer ~= RemoveEvidence then
                    casingList[#casingList + 1] = CurrentCasing
                    TriggerServerEvent('evidence:server:ClearCasings', casingList)
                end
            end
        end
        -----------------------------[ BLOOD ]-----------------------------
        if Blooddrops and next(Blooddrops) then
            for k, v in pairs(Blooddrops) do
                CurrentBlooddrop = k
                local timer = GetGameTimer()
                local currentTimer = Blooddrops[CurrentBlooddrop].time + RemoveEvidence
                if timer > Blooddrops[CurrentBlooddrop].time + RemoveEvidence and currentTimer ~= RemoveEvidence then
                    blooddropList[#blooddropList + 1] = CurrentBlooddrop
                    TriggerServerEvent('evidence:server:ClearBlooddrops', blooddropList)
                end
            end
        end
        -----------------------------[ FINGERPRINTS ]-----------------------------
        if Fingerprints and next(Fingerprints) then
            for k, v in pairs(Fingerprints) do
                CurrentFingerprint = k
                local timer = GetGameTimer()
                local currentTimer = Fingerprints[CurrentFingerprint].time + RemoveEvidence
                if timer > Fingerprints[CurrentFingerprint].time + RemoveEvidence and currentTimer ~= RemoveEvidence then
                    fingerprintList[#fingerprintList + 1] = CurrentFingerprint
                    TriggerServerEvent('evidence:server:ClearFingerprints', fingerprintList)
                end
            end
        end
        -----------------------------[ BULLETHOLE ]-----------------------------
        if Bullethole and next(Bullethole) then
            for k, v in pairs(Bullethole) do
                CurrentBullethole = k
                local timer = GetGameTimer()
                local currentTimer = Bullethole[CurrentBullethole].time + RemoveEvidence
                if timer > Bullethole[CurrentBullethole].time + RemoveEvidence and currentTimer ~= RemoveEvidence then
                    bulletholeList[#bulletholeList + 1] = CurrentBullethole
                    TriggerServerEvent('evidence:server:ClearBullethole', bulletholeList)
                end
            end
        end
        -----------------------------[ VEHICLE FRAGEMENTS ]-----------------------------
        if Fragments and next(Fragments) then
            for k, v in pairs(Fragments) do
                CurrentVehicleFragment = k
                local timer = GetGameTimer()
                local currentTimer = Fragments[CurrentVehicleFragment].time + RemoveEvidence
                if timer > Fragments[CurrentVehicleFragment].time + RemoveEvidence and currentTimer ~= RemoveEvidence then
                    vehiclefragmentList[#vehiclefragmentList + 1] = CurrentVehicleFragment
                    TriggerServerEvent('evidence:server:ClearVehicleFragments', vehiclefragmentList)
                end
            end
        end
    end
end)

-----------------------------------------[ CHECK WITH FLASHLIGHT OR CAMERA ]-----------------------------------------
if Config.PoliceJob == "hi-dev" then
    CreateThread(function()
        while true do
            Wait(5)
            if LocalPlayer.state.isLoggedIn then
                if PlayerJob.type == 'leo' and PlayerJob.onduty then
                    if (IsPlayerFreeAiming(PlayerId()) and GetSelectedPedWeapon(PlayerPedId()) == `WEAPON_FLASHLIGHT`) or IsEntityPlayingAnim(PlayerPedId(), "amb@world_human_paparazzi@male@base", "base", 3) then
                        local pos = GetEntityCoords(PlayerPedId(), true)
                        local hit, coords = RayCastGamePlayCamera(1000.0)
                        if next(Casings) then
                            for k, v in pairs(Casings) do
                                local dist = #(pos - vector3(v.coords.x, v.coords.y, v.coords.z))
                                local raycastdist = #(coords - vector3(v.coords.x, v.coords.y, v.coords.z))
                                if dist < 20 then
                                    CurrentCasing = k
                                    DrawMarker(0, v.coords.x, v.coords.y, v.coords.z -0.1, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 0.15, 0.15, 0.1, Config.CasingMarkerRGBA.r, Config.CasingMarkerRGBA.g, Config.CasingMarkerRGBA.b, Config.CasingMarkerRGBA.a, false, false, false, true, false, false, false)
                                    if dist > 2.5 and dist < 10 then
                                        DrawText3D(v.coords.x, v.coords.y, v.coords.z +0.1, " ~b~Bullet Casing [ " ..Config.AmmoLabels[QBCore.Shared.Weapons[Casings[CurrentCasing].type]['ammotype']].. " ]~s~")
                                    elseif raycastdist < 0.25 and dist < 5 then
                                        DrawText3D(v.coords.x, v.coords.y, v.coords.z  -0.05, Lang:t('info.bullet_casing'))
                                        if IsControlJustReleased(0, 23) then
                                            local s1, s2 = GetStreetNameAtCoord(v.coords.x, v.coords.y, v.coords.z)
                                            local street1 = GetStreetNameFromHashKey(s1)
                                            local street2 = GetStreetNameFromHashKey(s2)
                                            local streetLabel = street1
                                            if street2 then
                                                streetLabel = streetLabel .. ' | ' .. street2
                                            end
                                            local info = {
                                                label = Lang:t('info.casing'),
                                                type = 'casing',
                                                street = streetLabel:gsub("%'", ''),
                                                ammolabel = Config.AmmoLabels[QBCore.Shared.Weapons[Casings[CurrentCasing].type]['ammotype']],
                                                ammotype = Lang:t('info.unknown'),
                                                ammotype2 = Casings[CurrentCasing].type,
                                                serie = Lang:t('info.unknown'),
                                                serie2 = Casings[CurrentCasing].serie
                                            }
                                            TriggerServerEvent('evidence:server:AddCasingToInventory', CurrentCasing, info)
                                        end
                                    end
                                end
                            end
                        end
                        if next(Blooddrops) then
                            local pos = GetEntityCoords(PlayerPedId(), true)
                            for k, v in pairs(Blooddrops) do
                                local dist = #(pos - vector3(v.coords.x, v.coords.y, v.coords.z))
                                local raycastdist = #(coords - vector3(v.coords.x, v.coords.y, v.coords.z))
                                if dist < 20 then
                                    CurrentBlooddrop = k
                                    DrawMarker(0, v.coords.x, v.coords.y, v.coords.z -0.1, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 0.15, 0.15, 0.1, Config.BloodMarkerRGBA.r, Config.BloodMarkerRGBA.g, Config.BloodMarkerRGBA.b, Config.BloodMarkerRGBA.a, false, false, false, true, false, false, false)
                                    if dist > 2.5 and dist < 10 then
                                        DrawText3D(v.coords.x, v.coords.y, v.coords.z +0.1, "~r~Blood [ "..DnaHash(Blooddrops[CurrentBlooddrop].citizenid).." ]~s~")
                                    elseif raycastdist < 0.25 and dist < 5 then
                                        DrawText3D(v.coords.x, v.coords.y, v.coords.z -0.05, Lang:t('info.blood_text', { value = DnaHash(Blooddrops[CurrentBlooddrop].citizenid) }))
                                        if IsControlJustReleased(0, 23) then
                                            local s1, s2 = GetStreetNameAtCoord(v.coords.x, v.coords.y, v.coords.z)
                                            local street1 = GetStreetNameFromHashKey(s1)
                                            local street2 = GetStreetNameFromHashKey(s2)
                                            local streetLabel = street1
                                            if street2 then
                                                streetLabel = streetLabel .. ' | ' .. street2
                                            end
                                            local info = {
                                                label = Lang:t('info.blood'),
                                                type = 'blood',
                                                street = streetLabel:gsub("%'", ''),
                                                dnalabel = Lang:t('info.unknown'),
                                                dnalabel2 = DnaHash(Blooddrops[CurrentBlooddrop].citizenid),
                                                bloodtype = Lang:t('info.unknown'),
                                                bloodtype2 = Blooddrops[CurrentBlooddrop].bloodtype
                                            }
                                            TriggerServerEvent('evidence:server:AddBlooddropToInventory', CurrentBlooddrop, info)
                                        end
                                    end
                                end
                            end
                        end
                        if next(Fingerprints) then
                            local pos = GetEntityCoords(PlayerPedId(), true)
                            for k, v in pairs(Fingerprints) do
                                local dist = #(pos - vector3(v.coords.x, v.coords.y, v.coords.z))
                                local raycastdist = #(coords - vector3(v.coords.x, v.coords.y, v.coords.z))
                                if dist < 20 then
                                    CurrentFingerprint = k
                                    DrawMarker(0, v.coords.x, v.coords.y, v.coords.z -0.1, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 0.15, 0.15, 0.1, Config.FingerprintMarkerRGBA.r, Config.FingerprintMarkerRGBA.g, Config.FingerprintMarkerRGBA.b, Config.FingerprintMarkerRGBA.a, false, false, false, true, false, false, false)
                                    if dist > 2.5 and dist < 10 then
                                        DrawText3D(v.coords.x, v.coords.y, v.coords.z +0.1, "~y~Fingerprint [ "..Fingerprints[CurrentFingerprint].fingerprint.." ]~s~")
                                    elseif raycastdist < 0.25 and dist < 5 then
                                        DrawText3D(v.coords.x, v.coords.y, v.coords.z -0.05, Lang:t('info.fingerprint_text'))
                                        if IsControlJustReleased(0, 23) then
                                            local s1, s2 = GetStreetNameAtCoord(v.coords.x, v.coords.y, v.coords.z)
                                            local street1 = GetStreetNameFromHashKey(s1)
                                            local street2 = GetStreetNameFromHashKey(s2)
                                            local streetLabel = street1
                                            if street2 then
                                                streetLabel = streetLabel .. ' | ' .. street2
                                            end
                                            local info = {
                                                label = Lang:t('info.fingerprint'),
                                                type = 'fingerprint',
                                                street = streetLabel:gsub("%'", ''),
                                                fingerprint = Lang:t('info.unknown'),
                                                fingerprint2 = Fingerprints[CurrentFingerprint].fingerprint
                                            }
                                            TriggerServerEvent('evidence:server:AddFingerprintToInventory', CurrentFingerprint, info)
                                        end
                                    end
                                end
                            end
                        end
                        if next(Bullethole) then
                            local pos = GetEntityCoords(PlayerPedId(), true)
                            for k, v in pairs(Bullethole) do
                                local dist = #(pos - vector3(v.coords.x, v.coords.y, v.coords.z))
                                local raycastdist = #(coords - vector3(v.coords.x, v.coords.y, v.coords.z))
                                if dist < 20 then
                                    CurrentBullethole = k
                                    if pos.z < v.coords.z then
                                        DrawMarker(6, v.coords.x, v.coords.y, v.coords.z -0.05, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.1, 0.5, 0.1, Config.BulletholeMarkerRGBA.r, Config.BulletholeMarkerRGBA.g, Config.BulletholeMarkerRGBA.b, Config.BulletholeMarkerRGBA.a, false, true, 2, nil, nil, false)
                                    else
                                        DrawMarker(0, v.coords.x, v.coords.y, v.coords.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.15, 0.15, 0.1, Config.BulletholeMarkerRGBA.r, Config.BulletholeMarkerRGBA.g, Config.BulletholeMarkerRGBA.b, Config.BulletholeMarkerRGBA.a, false, true, 2, nil, nil, false)
                                    end
                                    if raycastdist < 0.25 and dist < 2.5 then
                                        DrawText3D(v.coords.x, v.coords.y, v.coords.z  -0.05, Lang:t('info.bullet_casing'))
                                        if IsControlJustReleased(0, 23) then
                                            local s1, s2 = GetStreetNameAtCoord(v.coords.x, v.coords.y, v.coords.z)
                                            local street1 = GetStreetNameFromHashKey(s1)
                                            local street2 = GetStreetNameFromHashKey(s2)
                                            local streetLabel = street1
                                            if street2 then
                                                streetLabel = streetLabel .. ' | ' .. street2
                                            end
                                            local info = {
                                                label = Lang:t('info.bullet'),
                                                type = 'bullet',
                                                street = streetLabel:gsub("%'", ''),
                                                ammolabel = Config.AmmoLabels[QBCore.Shared.Weapons[Casings[CurrentCasing].type]['ammotype']],
                                                ammotype = Lang:t('info.unknown'),
                                                ammotype2 = Bullethole[CurrentBullethole].type,
                                                serie = Lang:t('info.unknown'),
                                                serie2 = Bullethole[CurrentBullethole].serie

                                            }
                                            TriggerServerEvent('evidence:server:AddBulletToInventory', CurrentBullethole, info)
                                        end
                                    end
                                end
                            end
                        end
                        if next(Fragments) then
                            local pos = GetEntityCoords(PlayerPedId(), true)
                            for k, v in pairs(Fragments) do
                                local dist = #(pos - vector3(v.coords.x, v.coords.y, v.coords.z))
                                local raycastdist = #(coords - vector3(v.coords.x, v.coords.y, v.coords.z))
                                if dist < 20 then
                                    CurrentVehicleFragment = k
                                    if GetEntityType(entityHit) then
                                        if dist < 7.5 and dist > 1.5 then
                                            DrawText3D(v.coords.x, v.coords.y, v.coords.z +0.05, Lang:t('info.vehicle_fragment'))
                                        end
                                        DrawMarker(36, v.coords.x, v.coords.y, v.coords.z -0.05, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.2, 0.3, 0.2, v.r, v.g, v.b, 220, false, true, 2, nil, nil, false)
                                    end
                                    if dist < 1.5 then
                                        DrawText3D(v.coords.x, v.coords.y, v.coords.z  -0.05, Lang:t('info.bullet_casing'))
                                        if IsControlJustReleased(0, 23) then
                                            local s1, s2 = GetStreetNameAtCoord(v.coords.x, v.coords.y, v.coords.z)
                                            local street1 = GetStreetNameFromHashKey(s1)
                                            local street2 = GetStreetNameFromHashKey(s2)
                                            local streetLabel = street1
                                            if street2 then
                                                streetLabel = streetLabel .. ' | ' .. street2
                                            end
                                            local info = {
                                                label = Lang:t('info.vehicle_fragment'),
                                                type = 'vehiclefragment',
                                                street = streetLabel:gsub("%'", ''),
                                                rgb = Lang:t('info.unknown'),
                                                rgb2 = "R: " ..v.r.. " / G: " ..v.g.. " / B: " ..v.b,
                                                ammotype = Lang:t('info.unknown'),
                                                ammotype2 = Fragments[CurrentVehicleFragment].type,
                                                serie = Lang:t('info.unknown'),
                                                serie2 = Fragments[CurrentVehicleFragment].serie,
                                            }
                                            TriggerServerEvent('evidence:server:AddFragmentToInventory', CurrentVehicleFragment, info)
                                        end
                                    end
                                end
                            end
                        end
                    else
                        Wait(1000)
                    end
                else
                    Wait(5000)
                end
            end
        end
    end)
elseif Config.PoliceJob == "qb" then
    CreateThread(function()
        while true do
            Wait(5)
            if LocalPlayer.state.isLoggedIn then
                if PlayerJob.type == 'leo' and PlayerJob.onduty then
                    if (IsPlayerFreeAiming(PlayerId()) and GetSelectedPedWeapon(PlayerPedId()) == `WEAPON_FLASHLIGHT`) or IsEntityPlayingAnim(PlayerPedId(), "amb@world_human_paparazzi@male@base", "base", 3) then
                        local pos = GetEntityCoords(PlayerPedId(), true)
                        local hit, coords = RayCastGamePlayCamera(1000.0)
                        if next(Casings) then
                            for k, v in pairs(Casings) do
                                local dist = #(pos - vector3(v.coords.x, v.coords.y, v.coords.z))
                                local raycastdist = #(coords - vector3(v.coords.x, v.coords.y, v.coords.z))
                                if dist < 20 then
                                    CurrentCasing = k
                                    DrawMarker(0, v.coords.x, v.coords.y, v.coords.z -0.1, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 0.15, 0.15, 0.1, Config.CasingMarkerRGBA.r, Config.CasingMarkerRGBA.g, Config.CasingMarkerRGBA.b, Config.CasingMarkerRGBA.a, false, false, false, true, false, false, false)
                                    if dist > 2.5 and dist < 10 then
                                        DrawText3D(v.coords.x, v.coords.y, v.coords.z +0.1, " ~b~Bullet Casing [ " ..Config.AmmoLabels[QBCore.Shared.Weapons[Casings[CurrentCasing].type]['ammotype']].. " ]~s~")
                                    elseif raycastdist < 0.25 and dist < 5 then
                                        DrawText3D(v.coords.x, v.coords.y, v.coords.z  -0.05, Lang:t('info.bullet_casing'))
                                        if IsControlJustReleased(0, 23) then
                                            local s1, s2 = GetStreetNameAtCoord(v.coords.x, v.coords.y, v.coords.z)
                                            local street1 = GetStreetNameFromHashKey(s1)
                                            local street2 = GetStreetNameFromHashKey(s2)
                                            local streetLabel = street1
                                            if street2 then
                                                streetLabel = streetLabel .. ' | ' .. street2
                                            end
                                            local info = {
                                                label = Lang:t('info.casing'),
                                                type = 'casing',
                                                street = streetLabel:gsub("%'", ''),
                                                ammolabel = Config.AmmoLabels[QBCore.Shared.Weapons[Casings[CurrentCasing].type]['ammotype']],
                                                ammotype = Casings[CurrentCasing].type,
                                                serie = Casings[CurrentCasing].serie
                                            }
                                            TriggerServerEvent('evidence:server:AddCasingToInventory', CurrentCasing, info)
                                        end
                                    end
                                end
                            end
                        end
                        if next(Blooddrops) then
                            local pos = GetEntityCoords(PlayerPedId(), true)
                            for k, v in pairs(Blooddrops) do
                                local dist = #(pos - vector3(v.coords.x, v.coords.y, v.coords.z))
                                local raycastdist = #(coords - vector3(v.coords.x, v.coords.y, v.coords.z))
                                if dist < 20 then
                                    CurrentBlooddrop = k
                                    DrawMarker(0, v.coords.x, v.coords.y, v.coords.z -0.1, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 0.15, 0.15, 0.1, Config.BloodMarkerRGBA.r, Config.BloodMarkerRGBA.g, Config.BloodMarkerRGBA.b, Config.BloodMarkerRGBA.a, false, false, false, true, false, false, false)
                                    if dist > 2.5 and dist < 10 then
                                        DrawText3D(v.coords.x, v.coords.y, v.coords.z +0.1, "~r~Blood [ "..DnaHash(Blooddrops[CurrentBlooddrop].citizenid).." ]~s~")
                                    elseif raycastdist < 0.25 and dist < 5 then
                                        DrawText3D(v.coords.x, v.coords.y, v.coords.z -0.05, Lang:t('info.blood_text', { value = DnaHash(Blooddrops[CurrentBlooddrop].citizenid) }))
                                        if IsControlJustReleased(0, 23) then
                                            local s1, s2 = GetStreetNameAtCoord(v.coords.x, v.coords.y, v.coords.z)
                                            local street1 = GetStreetNameFromHashKey(s1)
                                            local street2 = GetStreetNameFromHashKey(s2)
                                            local streetLabel = street1
                                            if street2 then
                                                streetLabel = streetLabel .. ' | ' .. street2
                                            end
                                            local info = {
                                                label = Lang:t('info.blood'),
                                                type = 'blood',
                                                street = streetLabel:gsub("%'", ''),
                                                dnalabel = DnaHash(Blooddrops[CurrentBlooddrop].citizenid),
                                                bloodtype = Blooddrops[CurrentBlooddrop].bloodtype
                                            }
                                            TriggerServerEvent('evidence:server:AddBlooddropToInventory', CurrentBlooddrop, info)
                                        end
                                    end
                                end
                            end
                        end
                        if next(Fingerprints) then
                            local pos = GetEntityCoords(PlayerPedId(), true)
                            for k, v in pairs(Fingerprints) do
                                local dist = #(pos - vector3(v.coords.x, v.coords.y, v.coords.z))
                                local raycastdist = #(coords - vector3(v.coords.x, v.coords.y, v.coords.z))
                                if dist < 20 then
                                    CurrentFingerprint = k
                                    DrawMarker(0, v.coords.x, v.coords.y, v.coords.z -0.1, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 0.15, 0.15, 0.1, Config.FingerprintMarkerRGBA.r, Config.FingerprintMarkerRGBA.g, Config.FingerprintMarkerRGBA.b, Config.FingerprintMarkerRGBA.a, false, false, false, true, false, false, false)
                                    if dist > 2.5 and dist < 10 then
                                        DrawText3D(v.coords.x, v.coords.y, v.coords.z +0.1, "~y~Fingerprint [ "..Fingerprints[CurrentFingerprint].fingerprint.." ]~s~")
                                    elseif raycastdist < 0.25 and dist < 5 then
                                        DrawText3D(v.coords.x, v.coords.y, v.coords.z -0.05, Lang:t('info.fingerprint_text'))
                                        if IsControlJustReleased(0, 23) then
                                            local s1, s2 = GetStreetNameAtCoord(v.coords.x, v.coords.y, v.coords.z)
                                            local street1 = GetStreetNameFromHashKey(s1)
                                            local street2 = GetStreetNameFromHashKey(s2)
                                            local streetLabel = street1
                                            if street2 then
                                                streetLabel = streetLabel .. ' | ' .. street2
                                            end
                                            local info = {
                                                label = Lang:t('info.fingerprint'),
                                                type = 'fingerprint',
                                                street = streetLabel:gsub("%'", ''),
                                                fingerprint = Fingerprints[CurrentFingerprint].fingerprint
                                            }
                                            TriggerServerEvent('evidence:server:AddFingerprintToInventory', CurrentFingerprint, info)
                                        end
                                    end
                                end
                            end
                        end
                        if next(Bullethole) then
                            local pos = GetEntityCoords(PlayerPedId(), true)
                            for k, v in pairs(Bullethole) do
                                local dist = #(pos - vector3(v.coords.x, v.coords.y, v.coords.z))
                                local raycastdist = #(coords - vector3(v.coords.x, v.coords.y, v.coords.z))
                                if dist < 20 then
                                    CurrentBullethole = k
                                    if pos.z < v.coords.z then
                                        DrawMarker(6, v.coords.x, v.coords.y, v.coords.z -0.05, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.1, 0.5, 0.1, Config.BulletholeMarkerRGBA.r, Config.BulletholeMarkerRGBA.g, Config.BulletholeMarkerRGBA.b, Config.BulletholeMarkerRGBA.a, false, true, 2, nil, nil, false)
                                    else
                                        DrawMarker(0, v.coords.x, v.coords.y, v.coords.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.15, 0.15, 0.1, Config.BulletholeMarkerRGBA.r, Config.BulletholeMarkerRGBA.g, Config.BulletholeMarkerRGBA.b, Config.BulletholeMarkerRGBA.a, false, true, 2, nil, nil, false)
                                    end
                                    if raycastdist < 0.25 and dist < 2.5 then
                                        DrawText3D(v.coords.x, v.coords.y, v.coords.z  -0.05, Lang:t('info.bullet_casing'))
                                        if IsControlJustReleased(0, 23) then
                                            local s1, s2 = GetStreetNameAtCoord(v.coords.x, v.coords.y, v.coords.z)
                                            local street1 = GetStreetNameFromHashKey(s1)
                                            local street2 = GetStreetNameFromHashKey(s2)
                                            local streetLabel = street1
                                            if street2 then
                                                streetLabel = streetLabel .. ' | ' .. street2
                                            end
                                            local info = {
                                                label = Lang:t('info.bullet'),
                                                type = 'bullet',
                                                street = streetLabel:gsub("%'", ''),
                                                ammolabel = Config.AmmoLabels[QBCore.Shared.Weapons[Casings[CurrentCasing].type]['ammotype']],
                                                ammotype = Bullethole[CurrentBullethole].type,
                                                serie = Bullethole[CurrentBullethole].serie

                                            }
                                            TriggerServerEvent('evidence:server:AddBulletToInventory', CurrentBullethole, info)
                                        end
                                    end
                                end
                            end
                        end
                        if next(Fragments) then
                            local pos = GetEntityCoords(PlayerPedId(), true)
                            for k, v in pairs(Fragments) do
                                local dist = #(pos - vector3(v.coords.x, v.coords.y, v.coords.z))
                                local raycastdist = #(coords - vector3(v.coords.x, v.coords.y, v.coords.z))
                                if dist < 20 then
                                    CurrentVehicleFragment = k
                                    if GetEntityType(entityHit) then
                                        if dist < 7.5 and dist > 1.5 then
                                            DrawText3D(v.coords.x, v.coords.y, v.coords.z +0.05, Lang:t('info.vehicle_fragment'))
                                        end
                                        DrawMarker(36, v.coords.x, v.coords.y, v.coords.z -0.05, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.2, 0.3, 0.2, v.r, v.g, v.b, 220, false, true, 2, nil, nil, false)
                                    end
                                    if dist < 1.5 then
                                        DrawText3D(v.coords.x, v.coords.y, v.coords.z  -0.05, Lang:t('info.bullet_casing'))
                                        if IsControlJustReleased(0, 23) then
                                            local s1, s2 = GetStreetNameAtCoord(v.coords.x, v.coords.y, v.coords.z)
                                            local street1 = GetStreetNameFromHashKey(s1)
                                            local street2 = GetStreetNameFromHashKey(s2)
                                            local streetLabel = street1
                                            if street2 then
                                                streetLabel = streetLabel .. ' | ' .. street2
                                            end
                                            local info = {
                                                label = Lang:t('info.vehicle_fragment'),
                                                type = 'vehiclefragment',
                                                street = streetLabel:gsub("%'", ''),
                                                rgb = "R: " ..v.r.. " / G: " ..v.g.. " / B: " ..v.b,
                                                ammotype = Fragments[CurrentVehicleFragment].type,
                                                serie = Fragments[CurrentVehicleFragment].serie,
                                            }
                                            TriggerServerEvent('evidence:server:AddFragmentToInventory', CurrentVehicleFragment, info)
                                        end
                                    end
                                end
                            end
                        end
                    else
                        Wait(1000)
                    end
                else
                    Wait(5000)
                end
            end
        end
    end)
end
------------------------------------------------------------------------------[ toggleDrawLine Stuff ( Credits to ByBlackDeath ) ]------------------------------------------------------------------------------
local toggleDrawLine = false

RegisterNetEvent('evidence:client:toggleDrawLine', function()
    toggleDrawLine = not toggleDrawLine

    if toggleDrawLine then
        if Config.Notify == "qb" then
            QBCore.Functions.Notify(Lang:t('error.drawLine_enabled'), 'success')
        elseif Config.Notify == "ox" then
            lib.notify({ title = 'Evidence', description = Lang:t('error.error.drawLine_drawLine_enabled'), duration = 5000, type = 'success' })
        else
            print(Lang:t('error.config_error'))
        end
    else
        DrawLineDisableNotify()
    end

    CreateThread(function()
        while toggleDrawLine do
            Wait(5)
            if LocalPlayer.state.isLoggedIn then
                if PlayerJob.type == 'leo' and PlayerJob.onduty then
                    local selectedWeapon = GetSelectedPedWeapon(PlayerPedId())
                    if selectedWeapon ~= GetHashKey('weapon_unarmed') then
                        if selectedWeapon ~= GetHashKey('weapon_flashlight') then
                            if Config.Notify == "qb" then
                                QBCore.Functions.Notify(Lang:t('error.drawLine_weapon_in_hand'), 'error')
                            elseif Config.Notify == "ox" then
                                lib.notify({ title = 'Evidence', description = Lang:t('error.error.drawLine_weapon_in_hand'), duration = 5000, type = 'error' })
                            else
                                print(Lang:t('error.config_error'))
                            end

                            toggleDrawLine = false
                            break
                        end
                    end
                    if next(Bullethole) then
                        local pos = GetEntityCoords(PlayerPedId(), true)
                        for k, v in pairs(Bullethole) do
                            local dist = #(pos - vector3(v.coords.x, v.coords.y, v.coords.z))
                            if dist < 20 then
                                CurrentBullethole = k
                                DrawLine(v.coords.x, v.coords.y, v.coords.z -0.05, v.pedcoord.x, v.pedcoord.y, v.pedcoord.z, v.drawLine_r, v.drawLine_g, v.drawLine_b, 255)
                            elseif dist > 20 then
                                if Config.Notify == "qb" then
                                    QBCore.Functions.Notify(Lang:t('error.drawLine_too_far_away'), 'error')
                                elseif Config.Notify == "ox" then
                                    lib.notify({ title = 'Evidence', description = Lang:t('error.error.drawLine_too_far_away'), duration = 5000, type = 'error' })
                                else
                                    print(Lang:t('error.config_error'))
                                end
                                toggleDrawLine = false
                                break
                            end
                        end
                    end
                    if next(Fragments) then
                        local pos = GetEntityCoords(PlayerPedId(), true)
                        for k, v in pairs(Fragments) do
                            local dist = #(pos - vector3(v.coords.x, v.coords.y, v.coords.z))
                            if dist < 20 then
                                CurrentVehicleFragment = k
                                DrawLine(v.coords.x, v.coords.y, v.coords.z -0.05, v.pedcoord.x, v.pedcoord.y, v.pedcoord.z, v.drawLine_r, v.drawLine_g, v.drawLine_b, 255)
                            end
                        end
                    end
                else
                    DrawLineDisableNotify()
                    toggleDrawLine = false
                    break
                end
            end
        end
    end)
end)