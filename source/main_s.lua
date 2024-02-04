LEO = {
    GSRList = {},
    DutyPlayers = {}
}

RegisterNetEvent("stoicpm:shotspotter", function(location, streetName)
    local src = source
    LEO.GSRList[src] = os.time()
    TriggerClientEvent("stoicpm:shotspotter", -1, location, streetName)
end)


function ConvertToTime(value)
    local hours = string.format("%02.f", math.floor(value/3600))
    local minutes = string.format("%02.f", math.floor(value/60 - (hours*60)))
    local seconds = string.format("%02.f", math.floor(value - hours*3600 - minutes *60))
    return hours .. ":" .. minutes .. ":" .. seconds
end