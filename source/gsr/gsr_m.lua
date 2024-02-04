-- Register a context menu for the "jail" command
lib.registerContext({
    id = "gsr_menu",
    title = "GSR Test Menu",
    canClose = true,
    options = {
        { title = "GSR Test Player", onSelect = function() TriggerEvent('GSRTestPlayer') end },
        { title = "Close Menu", onSelect = function() lib.hideContext(true) end }
    }
})

-- Show input dialog for the "Jail Player" option
RegisterNetEvent('GSRTestPlayer')
AddEventHandler('GSRTestPlayer', function()
    local commandString = "gsr"
    TriggerEvent('chatMessage', 'SYSTEM', {255, 255, 255}, 'Running command: ' .. commandString)
    ExecuteCommand(commandString)

    -- Close the input dialog
    lib.closeInputDialog()
end)

-- Toggle Duty Function with Input Dialog
RegisterNetEvent('gsr')
AddEventHandler('gsr', function()
    lib.showContext('gsr_menu')
end)