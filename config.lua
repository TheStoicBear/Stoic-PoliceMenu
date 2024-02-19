config = {
    toggle_duty = true,
    active_calls = true,
    citations_menu = true,
    bolos_menu = true,
    search_player = true,
    jail_player = true,
    mdt = true,
}

Config = {}
Config.UseThirdEye = true -- WIP To use Third Eye instead of Radial Menu
Config.ThirdEyeIcon = "fa-solid fa-handcuffs" -- Third Eye Font Awesome ICON
Config.ThirdEyeIconColor = "#0702fa" -- Third Eye Color for the Icon
Config.ThirdEyeMenuName = "Police Action Menu" -- Name of the ThirdEye Label.
Config.ThirdEyeDistance = 2.0
Config.UseRadialMenu = true -- WIP To use Radial Menu instead of Third Eye
Config.NotifySubject = true -- Set this to false if you want the person being tested to get a chat notification that they are being tested
Config.EnableCleanGSR = true -- Set this to false if you dont want people to be able to clean gsr off them
Config.GSRAutoClean = 900 -- (IN SECONDS) Ammount Of Time Before GSR Auto Cleans [Default Is 15 Minutes]
Config.GSRTestDistance = 3 -- Maximum Distance That You Can Be To Test For GSR ***I Recomend Leaving This Low***
Config.TestGSR = "gsr" -- Command To Test For GSR
Config.CleanGSR = "cleangsr" -- Command To Clean GSR
Config.jobIdentifiers = {
        "sasp", -- Example police job identifier 1
        "lscso", -- Example police job identifier 2
        "doa" -- Example police job identifier 3
}

Config.Actions = {
		cuffing = true,--Toggles actions true/false
		dragging = true,  --Toggles actions true/false
		removefromvehicle = true, --Toggles actions true/false
		removeweapons = true --Toggles actions true/false
}

Config.Text = {
        GettingTestedMsg = "You Have Been Tested For GSR By: ", -- The Message That Is Sent To The Person That Is Getting Tested
        TestedPositive = "Subject Tested Positive GSR", -- The Message The Tester Is Sent When Test Comes Back Positive
        TestedNegative = "Subject Tested Negative GSR", -- The Message The Tester Is Sent When Test Comes Back Negative
        AlreadyClean = "You Are Already Clean", -- The Message The Subject Gets If They Are Aleady Clean [NotifySubject] Must Be Set To True
        TCleaningGSR = "You Cleaned Gunshot Residue Off Your Hands", -- The Message The Subject Gets When They Are Cleaning Themselfs [NotifySubject] Must Be Set To True
        NoSubjectError = "Could Not Find Subject",
        FailedSkillCheck = "You have failed to clean yourself, try again!"
}

Config.IgnoreWeapons = { -- Weapons to ignore with the shot spotter.
        `WEAPON_BZGAS`,
        `WEAPON_FLARE`,
        `WEAPON_STUNGUN`,
        `WEAPON_SNOWBALL`,
        `WEAPON_PETROLCAN`,
        `WEAPON_SMOKEGRENADE`,
        `WEAPON_FIREEXTINGUISHER`
}

Config.Impound = {
    Toggle = true,
    ImpoundLocations = {
        {X = 404.24, Y = -1631.18, Z = 29.29, H = 310.91}, -- First impound location
        {X = 397.54, Y = -1642.8, Z = 29.29, H = 324.64}, -- First impound location
        {X = 400.09, Y = -1644.92, Z = 29.29, H = 316.55}, -- First impound location
        {X = 402.27, Y = -1646.92, Z = 29.29, H = 326.7}, -- First impound location
    -- Add more impound locations here
      }
}

-- Notification configuration
Config.notification = {
        titlePrefix = 'ShotSpotter', -- Customize the notification title prefix
        position = 'top', -- Customize the notification position
        backgroundColor = '#141517',
        textColor = '#C1C2C5',
        descriptionColor = '#909296',
        icon = 'exclamation-circle', -- Font Awesome 6 icon name
        iconColor = '#ff0000', -- Red color for the icon
        duration = 60000 -- Duration in milliseconds
}

-- Shotspotter configuration
Config.shotspotter = {
        blipSprite = 161,
        blipScale = 2.0,
        blipColour = 21,
        blipName = "Detected Shots Fired",
        pulseTime = 60000 -- Pulse time in milliseconds
}

-- Police job names
Config.PoliceJobs = {
    "LSPD",
    "BCSO",
    -- Add more police job names here
}

-- EMS job names
Config.EMSJobs = {
    "SAFD",
    -- Add more EMS job names here
}

-- Define the items you want to give to players for each job
Config.PoliceItems = {
    "pistol",
    "handcuffs",
    -- Add more items for police here
}

Config.EMSItems = {
    "firstaidkit",
    "defibrillator",
    -- Add more items for EMS here
}
    
Settings = {
    Impound = {
        Toggle = true,
        Command = "impound",
        MaxValue = 0, -- Set to 0 for no fines
        ImpoundLocations = {
            {X = 404.24, Y = -1631.18, Z = 29.29, H = 310.91}, -- First impound location
            {X = 397.54, Y = -1642.8, Z = 29.29, H = 324.64}, -- First impound location
            {X = 400.09, Y = -1644.92, Z = 29.29, H = 316.55}, -- First impound location
            {X = 402.27, Y = -1646.92, Z = 29.29, H = 326.7} -- First impound location
            -- Add more impound locations here
        }
    }
}

--Shows notification
function ShowNotification( text )
	SetNotificationTextEntry( "STRING" )
	AddTextComponentString( text )
	DrawNotification( false, false )
end
