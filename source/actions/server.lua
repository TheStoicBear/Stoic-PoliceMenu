
RegisterNetEvent("refreshscriptperms")
AddEventHandler("refreshscriptperms", Access)
--End *Handles all permissions*


--Action server sync
RegisterServerEvent('cuffplayer')
AddEventHandler('cuffplayer', function(player)
	TriggerClientEvent('cuffplayer', player)
end)

RegisterServerEvent('dragplayer')
AddEventHandler('dragplayer', function(player)
	TriggerClientEvent('dragplayer', player, source)
end)

RegisterServerEvent('forceplayerintovehicle')
AddEventHandler('forceplayerintovehicle', function(player)
	TriggerClientEvent('forceplayerintovehicle', player)
end)

RegisterServerEvent('removeplayerfromvehicle')
AddEventHandler('removeplayerfromvehicle', function(player)
	TriggerClientEvent('removeplayerfromvehicle', player)
end)

RegisterServerEvent('searchplayer')
AddEventHandler('searchplayer', function(player)
	TriggerClientEvent('searchplayer', player, source)
end)

RegisterServerEvent('removeplayerweapons')
AddEventHandler('removeplayerweapons', function(player)
	TriggerClientEvent("removeplayerweapons", player)
end)
--End *Action server sync*