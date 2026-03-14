-- ============================================================
--  ZeyMenu — Macho Edition V2
--  Interface clavier identique a ZeyMenu (fleches / entree / backspace)
--  Moteur de menu custom dessine avec DrawRect + DrawText
--  MachoHookNative + MachoInjectResource2 + MachoOnKeyDown
-- ============================================================

-- ============================================================
-- VARIABLES
-- ============================================================

local killmenu          = false
local SafeMode          = false
local selectedPlayer    = 0
local farmGhostVeh      = nil
local carjackCooldown   = false
local noclipping        = false
local thermalvision     = false
local nightvision       = false
local VehicleSnatcher   = false
local policeheadlights  = false
local isSpectatingTarget= false
local PVAutoDriving     = false
local spawninsidevehicle= true
local TazeLoop          = false
local TazeLoopingPlayer = nil
local rgbhud            = false
local personalVehicle   = nil

_G._ZeyAntiTP = false

local Vars = {
    AntiCheat = {
        SeedBlocked=false, SafeModeSeed=false,
        BadgerAC=false, TigoAC=false, VAC=false,
        AntiCheese=false, ChocoHax=false,
    },
    Self = {
        invisiblitity=false, godmode=false, AutoHealthRefil=false,
        infstamina=false, noragdoll=false, FreezeWantedLevel=false,
        playercoords=false, forceradar=false,
        MoonWalk=false, superjump=false, superrun=false,
        InfiniteCombatRoll=false, AntiHeadshot=false,
        disableobjectcollisions=false, disablepedcollisions=false,
    },
    Vehicle = {
        FullUnlockVehicle=true, vehgodmode=false, speedboost=false,
        Waterproof=false, InstantBreaks=false, ZeyMenuplate=false,
        rainbowcar=false, speedometer=false, EasyHandling=false,
        DriveOnWater=false, AlwaysWheelie=false, AutoClean=false,
        forcelauncontrol=false, activetorquemulr=false, activeenignemulr=false,
        NoBikeFall=false, rainbowCarR=255, rainbowCarG=0, rainbowCarB=0,
        curractivetorqueIndex=1, curractiveenignemulrIndex=1,
        vehenginemultiplier={"x2","x4","x8","x16","x32","x64","x128","x256","x512","x1024"},
        AutoPilot={CruiseSpeed=50.0, DrivingStyle=6},
    },
    Farm = {
        Carjack=false, CarjackDist=false, CarjackDistV2=false,
        SoloSession=false, SoloSessionV2=false, VoirJoueur=false,
        VehicleInvisible=false, AutoInvisible=false, PassagerVisible=false,
        CollisionVehicule=true, FDescendreJoueur=false,
        AntiTP=false, KickVehicule=false,
    },
    Weapon = {
        ExplosiveAmmo=false, TriggerBot=false, RapidFire=false,
        Crosshair=false, NoRecoil=false, Tracers=false,
        RageBot=false, Spinbot=false, InfAmmo=false,
        NoReload=false, OneShot=false,
        BulletEnabled=false, BulletIndex=1,
        Bullets={"WEAPON_REVOLVER","WEAPON_HEAVYSNIPER","WEAPON_RPG","WEAPON_FIREWORK","WEAPON_RAYPISTOL"},
        BulletNames={"Revolver","Heavy Sniper","RPG","Firework","Ray Pistol"},
        AimBot={
            Enabled=false, Bone="SKEL_HEAD", BoneIndex=1,
            ThroughWalls=false, DrawFOV=true, ShowTarget=false,
            FOV=0.50, OnlyPlayers=false, IgnoreFriends=true,
            Distance=1000.0, InvisibilityCheck=true,
        },
    },
    Misc = {
        ESPBox=true, ESPName=false, ESPLines=false,
        ESPBones=false, ESPBlips=false, ESPDistance=1000.0,
        UnlockAllVehicles=false, FlyingCars=false,
    },
    Script = {
        blocktakehostage=false, BlockBlackScreen=false,
        blockbeingcarried=false, BlockPeacetime=false,
        GGACBypass=false, SSBBypass=false, vault_doors=false,
    },
    Server={ESXServer=false, VRPServer=false},
    Teleport = {
        smoothteleport=false, OceanV2=false, lastOceanIndex=nil,
        oceanDestinations={
            {nom="Fete foraine",   x=-1653.00, y=-1125.00, z=13.00},
            {nom="Paleto Bay",     x=-442.00,  y=6024.00,  z=31.00},
            {nom="Sandy Shores",   x=1953.00,  y=3745.00,  z=32.00},
            {nom="Les Docks",      x=120.00,   y=-3215.00, z=5.00},
            {nom="Observatoire",   x=-438.0,   y=1076.0,   z=352.41},
            {nom="Del Perro Pier", x=-1850.0,  y=-1231.0,  z=13.02},
            {nom="Grapeseed",      x=1698.0,   y=4924.0,   z=42.06},
            {nom="Fort Zancudo",   x=-2047.0,  y=3132.0,   z=32.81},
        },
        locations={
            {"Mission Row PD",   440.22,  -982.21,  30.69},
            {"Sandy Shores PD",  1857.48, 3677.88,  33.73},
            {"Paleto Bay PD",    -434.34, 6020.89,  31.50},
        },
    },
    Player = {
        ExplosionType=1, TrackingPlayer=nil,
        attachtoplayer=false, attatchedplayer=nil,
        playertofreeze=nil, freezeplayer=false,
        ExplosionLoop=false, ExplodingPlayer=nil,
        FlingingPlayer=false, cargoplaneloop=false,
    },
    AllPlayers = {
        IncludeSelf=true, freezeserver=false,
        ExplodisionLoop=false, busingserverloop=false,
        cargoplaneserverloop=false, tugboatrainoverplayers=false,
    },
    MenuOptions={Watermark=false},
}

-- ============================================================
-- DETECTION RESOURCES
-- ============================================================

local function GetResources()
    local r={}
    for i=1,GetNumResources() do r[i]=GetResourceByFindIndex(i) end
    return r
end
local Resources = GetResources()
for _,res in ipairs(Resources) do
    local r=string.lower(res)
    if string.find(r,"badger") and string.find(r,"anti") then Vars.AntiCheat.BadgerAC=true
    elseif string.find(r,"tigo") then Vars.AntiCheat.TigoAC=true
    elseif string.find(r,"vac") then Vars.AntiCheat.VAC=true
    elseif string.find(r,"cheese") then Vars.AntiCheat.AntiCheese=true
    elseif string.find(r,"choco") then Vars.AntiCheat.ChocoHax=true
    elseif string.find(r,"esx") then Vars.Server.ESXServer=true
    elseif string.find(r,"vrp") then Vars.Server.VRPServer=true
    end
end

-- ============================================================
-- MACHO NATIVE HOOKS
-- ============================================================

-- [CACHER] GetPlayerName
MachoHookNative(0x6D0DE6A7B5DA71F8, function(player_id)
    if player_id == PlayerId() then
        return false, "Player_"..tostring(GetPlayerServerId(player_id))
    end
    return true
end)

-- [CACHER] GET_ENTITY_COORDS en SafeMode
MachoHookNative(0x3FEF770D40960D5A, function(entity, alive)
    if SafeMode and entity == PlayerPedId() then
        local r = GetEntityCoords(entity, alive)
        return false, r.x, r.y, r.z
    end
    return true
end)

-- [BLOQUER] Plaque masquee
MachoHookNative(0x7CE1CCB9B293020E, function(vehicle)
    local myVeh = GetVehiclePedIsIn(PlayerPedId(), false)
    if vehicle == myVeh and myVeh ~= 0 then
        return false, "ZEYMENU"
    end
    return true
end)

-- [BLOQUER] Vitesse plafonnee si speedboost
MachoHookNative(0x6D5BCA5B13E72F3B, function(entity)
    local myVeh = GetVehiclePedIsIn(PlayerPedId(), false)
    if (entity == PlayerPedId() or entity == myVeh) and Vars.Vehicle.speedboost then
        local real = GetEntitySpeed(entity)
        if real > 50.0 then return false, 30.0 end
    end
    return true
end)

-- [BLOQUER] NETWORK_IS_HOST
MachoHookNative(0x764B79499032D916, function()
    return false, true
end)

-- [BLOQUER] Seed toujours missing
MachoHookNative(0xFDEBD59D3C09C26C, function(resourceName)
    if resourceName and string.find(string.lower(tostring(resourceName)),"seed") then
        return false, "missing"
    end
    return true
end)

-- [ANTI-TP] SET_ENTITY_COORDS
MachoHookNative(0x06843DA7060A026B, function(entity, x, y, z)
    if Vars.Farm.AntiTP and entity == PlayerPedId() then
        local c = GetEntityCoords(entity)
        if #(c - vector3(x,y,z)) > 5.0 then
            MachoMenuNotification("Anti-TP","TP bloque")
            return false
        end
    end
    return true
end)

-- [ANTI-TP] SET_ENTITY_COORDS_NO_OFFSET
MachoHookNative(0x239A3351AC1DA385, function(entity, x, y, z)
    if Vars.Farm.AntiTP and entity == PlayerPedId() then
        local c = GetEntityCoords(entity)
        if #(c - vector3(x,y,z)) > 5.0 then return false end
    end
    return true
end)

-- [ANTI-TP] NETWORK_RESURRECT_LOCAL_PLAYER
MachoHookNative(0x2959F695A6D1A7E5, function(x, y, z)
    if Vars.Farm.AntiTP then
        local c = GetEntityCoords(PlayerPedId())
        if #(c - vector3(x,y,z)) > 5.0 then
            MachoMenuNotification("Anti-TP","Resurrect bloque")
            return false
        end
    end
    return true
end)

-- [ANTI-TP] TASK_GO_TO_COORD_ANY_MEANS
MachoHookNative(0x5BC448CB78FA3E88, function(ped)
    if Vars.Farm.AntiTP and ped == PlayerPedId() then
        return false
    end
    return true
end)

-- [ANTI-TP] FREEZE_ENTITY_POSITION externe
MachoHookNative(0x428CA6DBD1094446, function(entity, toggle)
    if Vars.Farm.AntiTP and entity == PlayerPedId() and toggle == true then
        MachoMenuNotification("Anti-TP","Freeze externe bloque")
        return false
    end
    return true
end)

-- [ANTI-TP] SET_PED_COORDS_KEEP_VEHICLE
MachoHookNative(0x9AFEFF481A85AB2E, function(ped, x, y, z)
    if Vars.Farm.AntiTP and ped == PlayerPedId() then
        local c = GetEntityCoords(ped)
        if #(c - vector3(x,y,z)) > 5.0 then return false end
    end
    return true
end)

-- ============================================================
-- MACHO INJECT au demarrage
-- ============================================================

MachoInjectResource2(3, "any", [[
    AddEventHandler("screenshot_basic:requestScreenshot", function() CancelEvent() end)
    AddEventHandler("EasyAdmin:CaptureScreenshot", function()
        TriggerServerEvent("EasyAdmin:TookScreenshot","ERROR"); CancelEvent()
    end)
    AddEventHandler("requestScreenshot", function() CancelEvent() end)
    AddEventHandler("requestScreenshotUpload", function() CancelEvent() end)
    AddEventHandler("screenshot-basic", function() CancelEvent() end)
    AddEventHandler("EasyAdmin:FreezePlayer", function()
        TriggerEvent("EasyAdmin:FreezePlayer", false)
    end)
]])

MachoInjectResource2(3, "any", [[
    local tpPatterns = {"teleport","setcoords","set_coords","stafftp","staff_tp",
        "adminteleport","forcetp","force_tp","rollback","anticheat:tp","easyAdmin:tp"}
    local _origAEH = AddEventHandler
    AddEventHandler = function(eventName, cb)
        if eventName then
            local evLow = string.lower(tostring(eventName))
            for _, p in ipairs(tpPatterns) do
                if string.find(evLow, p) then
                    return _origAEH(eventName, function(...)
                        if not _G._ZeyAntiTP then cb(...) end
                    end)
                end
            end
        end
        return _origAEH(eventName, cb)
    end
]])

-- ============================================================
-- MOTEUR DE MENU CLAVIER
-- Navigation identique a ZeyMenu:
--   Fleche Haut/Bas = naviguer
--   Entree          = selectionner / activer
--   Backspace       = retour menu parent
--   F11             = ouvrir / fermer
-- ============================================================

local Menu = {
    open        = false,
    currentMenu = nil,
    cursorIndex = 1,  -- index de l'option selectionnee
    scroll      = 0,  -- decalage de scroll
    maxVisible  = 14, -- options visibles a l'ecran

    -- Position et tailles (normalisees 0..1)
    x           = 0.75,
    y           = 0.025,
    width       = 0.225,
    titleH      = 0.11,
    itemH       = 0.038,
    textScale   = 0.325,

    -- Couleur RGB (cycling)
    rgb         = {r=30, g=144, b=255},
}

-- Structure d'un menu: {id, titre, parent, items=[]}
-- Structure d'un item:
--   {type="button"|"checkbox"|"submenu", label, subtext, checked, action, submenuId}

local Menus = {}   -- table[id] = {titre, parent, items}
local breadcrumb = {} -- pile de navigation

local function CreateMenu(id, title, parent)
    Menus[id] = {title=title, parent=parent, items={}}
end

local function AddItem(menuId, item)
    table.insert(Menus[menuId].items, item)
end

-- Helpers
local function MB(menuId, label, subtext, action)
    AddItem(menuId, {type="button", label=label, subtext=subtext or "", action=action})
end
local function MC(menuId, label, varTable, varKey, onEnable, onDisable)
    -- varTable est directement la référence à la table (ex: Vars.Farm), varKey est la clé (ex: "AntiTP")
    AddItem(menuId, {type="checkbox", label=label, varTable=varTable, varKey=varKey,
        onEnable=onEnable, onDisable=onDisable})
end
local function MS(menuId, label, subtext, targetId)
    AddItem(menuId, {type="submenu", label=label, subtext=subtext or "", targetId=targetId})
end

-- ============================================================
-- CONSTRUCTION DES MENUS
-- ============================================================

-- MAIN
CreateMenu("main", "ZeyMenu", nil)
MS("main", "New",                   "Collision / Anti-TP / Kick Veh",   "new")
MS("main", "Farm",                  "Carjack / Solo Session / Ghost",   "farm")
MS("main", "Online Player Options", "Individual / All Players",         "players")
MS("main", "Self Options",          "Godmode / Super Powers",           "self")
MS("main", "Vehicle Options",       "Spawn / Godmode / Rainbow",        "vehicle")
MS("main", "Teleport Options",      "Waypoint / Ocean / Coords",        "teleport")
MS("main", "Weapon Options",        "Ammo / AimBot / Explosive",        "weapon")
MS("main", "World Options",         "Weather / Time / Flying Cars",     "world")
MS("main", "Misc Options",          "ESP / AntiCheat / Script",         "misc")
MS("main", "Settings",              "Watermark / Kill Menu",            "settings")

-- NEW
CreateMenu("new", "New", "main")
MC("new","Collision Vehicule",Vars.Farm,"CollisionVehicule",
    function() Vars.Farm.CollisionVehicule=true end,
    function() Vars.Farm.CollisionVehicule=false end)
MC("new","F Descendre Joueur",Vars.Farm,"FDescendreJoueur",
    function() Vars.Farm.FDescendreJoueur=true end,
    function() Vars.Farm.FDescendreJoueur=false end)
MC("new","Anti-TP",Vars.Farm,"AntiTP",
    function() Vars.Farm.AntiTP=true; _G._ZeyAntiTP=true
        MachoMenuNotification("Anti-TP","Actif") end,
    function() Vars.Farm.AntiTP=false; _G._ZeyAntiTP=false
        MachoMenuNotification("Anti-TP","Desactive") end)
MC("new","Kick Vehicule [E]",Vars.Farm,"KickVehicule",
    function() Vars.Farm.KickVehicule=true
        MachoMenuNotification("Kick Veh","E pour prendre le vehicule du joueur") end,
    function() Vars.Farm.KickVehicule=false end)

-- FARM
CreateMenu("farm", "Farm", "main")
MC("farm","Carjack",Vars.Farm,"Carjack",
    function() Vars.Farm.Carjack=true end,
    function() Vars.Farm.Carjack=false end)
MC("farm","Carjack Distance [E] PNJ+Joueurs",Vars.Farm,"CarjackDist",
    function() Vars.Farm.CarjackDist=true; Vars.Farm.CarjackDistV2=false
        MachoMenuNotification("Carjack Dist","E pour declencher") end,
    function() Vars.Farm.CarjackDist=false end)
MC("farm","Carjack Distance V2 [E] Joueurs",Vars.Farm,"CarjackDistV2",
    function() Vars.Farm.CarjackDistV2=true; Vars.Farm.CarjackDist=false
        MachoMenuNotification("Carjack Dist V2","E pour declencher") end,
    function() Vars.Farm.CarjackDistV2=false end)
MC("farm","Solo Session",Vars.Farm,"SoloSession",
    function()
        Vars.Farm.SoloSession=true
        MachoMenuNotification("Solo Session","Changement instance...")
        Citizen.Wait(1000); NetworkBail()
    end,
    function()
        Vars.Farm.SoloSession=false; Vars.Farm.VoirJoueur=false
        MachoMenuNotification("Solo Session","Recherche session...")
        Citizen.CreateThread(function()
            local t=0
            while t<10 do
                NetworkBail(); t=t+1; Citizen.Wait(6000)
                if #GetActivePlayers()>1 then
                    MachoMenuNotification("Solo Session","Session trouvee !")
                    for _,pid in ipairs(GetActivePlayers()) do
                        if pid~=PlayerId() then
                            local op=GetPlayerPed(pid)
                            if DoesEntityExist(op) then
                                SetEntityVisible(op,true,false)
                                local ov=GetVehiclePedIsIn(op,false)
                                if ov~=0 then SetEntityVisible(ov,true,false) end
                            end
                        end
                    end
                    return
                end
            end
        end)
    end)
MC("farm","Solo Session V2",Vars.Farm,"SoloSessionV2",
    function()
        Vars.Farm.SoloSessionV2=true
        -- Bloquer les nouveaux joueurs via hook natif sur CAN_PLAYER_JOIN
        MachoHookNative(0xBEFD9C32C7F4A7B3, function()
            if Vars.Farm.SoloSessionV2 then
                return false, false
            end
            return true
        end)
        -- Expulser tous les joueurs actuels via texture corrupte réseau
        Citizen.CreateThread(function()
            for _,pid in ipairs(GetActivePlayers()) do
                if pid ~= PlayerId() then
                    local op = GetPlayerPed(pid)
                    if DoesEntityExist(op) then
                        SetEntityVisible(op, false, false)
                        local ov = GetVehiclePedIsIn(op, false)
                        if ov ~= 0 then SetEntityVisible(ov, false, false) end
                    end
                    -- Forcer la déconnexion réseau du joueur
                    NetworkFadeOutEntity(GetPlayerPed(pid), true, false)
                end
            end
            Citizen.Wait(500)
            -- Bloquer les connexions entrantes au niveau réseau
            MachoInjectResource2(3, "any", [[
                local _origCB = AddEventHandler
                AddEventHandler = function(n, cb)
                    if n == "playerJoining" or n == "onPlayerJoining" then
                        return _origCB(n, function(...) end)
                    end
                    return _origCB(n, cb)
                end
            ]])
            MachoMenuNotification("Solo Session V2", "Session solo active")
        end)
    end,
    function()
        Vars.Farm.SoloSessionV2=false
        -- Remettre les joueurs visibles
        for _,pid in ipairs(GetActivePlayers()) do
            if pid ~= PlayerId() then
                local op = GetPlayerPed(pid)
                if DoesEntityExist(op) then
                    SetEntityVisible(op, true, false)
                    local ov = GetVehiclePedIsIn(op, false)
                    if ov ~= 0 then SetEntityVisible(ov, true, false) end
                end
            end
        end
        MachoMenuNotification("Solo Session V2", "Desactive")
    end)
MS("farm","Options Solo Session","Voir Joueur","solosession")
MC("farm","Vehicule Invisible",Vars.Farm,"VehicleInvisible",
    function()
        Vars.Farm.VehicleInvisible=true
        -- Le thread s'occupe de rendre le véhicule invisible
    end,
    function()
        Vars.Farm.VehicleInvisible=false
        -- Le thread s'occupe de rendre le véhicule visible
    end)
MS("farm","Options Vehicule Invisible","Auto / Passager","ghostopts")

CreateMenu("solosession","Options Solo Session","farm")
MC("solosession","Voir Joueur",Vars.Farm,"VoirJoueur",
    function()
        if Vars.Farm.SoloSession then Vars.Farm.VoirJoueur=true
        else MachoMenuNotification("Solo","Activer Solo Session d abord") end
    end,
    function() Vars.Farm.VoirJoueur=false end)

CreateMenu("ghostopts","Options Vehicule Invisible","farm")
MC("ghostopts","Auto Invisible",Vars.Farm,"AutoInvisible",
    function() Vars.Farm.AutoInvisible=true end,
    function() Vars.Farm.AutoInvisible=false end)
MC("ghostopts","Passager Visible",Vars.Farm,"PassagerVisible",
    function() Vars.Farm.PassagerVisible=true end,
    function() Vars.Farm.PassagerVisible=false end)

-- PLAYERS
CreateMenu("players","Online Player Options","main")
MS("players","All Player Options","Tous les joueurs","allplayers")
MB("players","[Entree] Selectionner Joueur","Server ID ci-dessous", function()
    -- handled separately via input
end)
MB("players","Semi-Godmode Joueur","", function()
    local t=GetPlayerPed(selectedPlayer)
    if DoesEntityExist(t) then SetEntityInvincible(t,true) end
end)
MB("players","TP Sur Joueur","", function()
    local t=GetPlayerPed(selectedPlayer)
    if DoesEntityExist(t) then
        local c=GetEntityCoords(t)
        SetEntityCoords(PlayerPedId(),c.x+1,c.y,c.z,false,false,false,false)
    end
end)
MB("players","TP Joueur Sur Moi","", function()
    local myC=GetEntityCoords(PlayerPedId())
    SetEntityCoords(GetPlayerPed(selectedPlayer),myC.x+1,myC.y,myC.z,false,false,false,false)
end)
MC("players","Spectate","",nil,
    function()
        isSpectatingTarget=true
        NetworkSetInSpectatorMode(true,GetPlayerPed(selectedPlayer))
    end,
    function()
        isSpectatingTarget=false
        NetworkSetInSpectatorMode(false,PlayerPedId())
    end)
MB("players","Tuer Joueur","", function() SetEntityHealth(GetPlayerPed(selectedPlayer),0) end)
MB("players","Exploser Joueur","", function()
    local c=GetEntityCoords(GetPlayerPed(selectedPlayer))
    AddExplosion(c.x,c.y,c.z,2,10.0,true,false,0.0)
end)
MC("players","Explosion Loop","",nil,
    function() Vars.Player.ExplosionLoop=true; Vars.Player.ExplodingPlayer=selectedPlayer end,
    function() Vars.Player.ExplosionLoop=false end)
MB("players","Flinguer Joueur","", function()
    SetEntityVelocity(GetPlayerPed(selectedPlayer),0,0,50.0)
end)
MC("players","Freeze Joueur","",nil,
    function() Vars.Player.freezeplayer=true; Vars.Player.playertofreeze=GetPlayerPed(selectedPlayer) end,
    function() Vars.Player.freezeplayer=false end)
MC("players","Attach a Joueur","",nil,
    function()
        Vars.Player.attachtoplayer=true
        AttachEntityToEntity(PlayerPedId(),GetPlayerPed(selectedPlayer),0,0,0,0.5,0,0,0,false,false,false,false,0,true)
    end,
    function()
        Vars.Player.attachtoplayer=false
        DetachEntity(PlayerPedId(),true,true)
    end)
MB("players","Copier Ped Joueur","", function()
    local model=GetEntityModel(GetPlayerPed(selectedPlayer))
    RequestModel(model)
    Citizen.CreateThread(function()
        while not HasModelLoaded(model) do Citizen.Wait(100) end
        SetPlayerModel(PlayerId(),model); SetModelAsNoLongerNeeded(model)
    end)
end)
MB("players","Donner Toutes Armes","", function()
    local t=GetPlayerPed(selectedPlayer)
    for _,w in ipairs({"WEAPON_PISTOL","WEAPON_SMG","WEAPON_ASSAULTRIFLE","WEAPON_RPG","WEAPON_GRENADE"}) do
        GiveWeaponToPed(t,GetHashKey(w),9999,false,false)
    end
end)
MB("players","Retirer Toutes Armes","", function()
    RemoveAllPedWeapons(GetPlayerPed(selectedPlayer),true)
end)
MB("players","Bus Joueur","~y~Native", function()
    local c=GetEntityCoords(GetPlayerPed(selectedPlayer))
    local hash=GetHashKey("bus"); RequestModel(hash)
    Citizen.CreateThread(function()
        while not HasModelLoaded(hash) do Citizen.Wait(100) end
        local bus=CreateVehicle(hash,c.x+2,c.y,c.z,0,true,false)
        SetEntityVelocity(bus,0,50,0); SetModelAsNoLongerNeeded(hash)
    end)
end)
MB("players","Cage Joueur","", function()
    local c=GetEntityCoords(GetPlayerPed(selectedPlayer))
    local hash=GetHashKey("prop_gold_cont_01"); RequestModel(hash)
    Citizen.CreateThread(function()
        while not HasModelLoaded(hash) do Citizen.Wait(100) end
        CreateObject(hash,c.x,c.y,c.z,true,true,false); SetModelAsNoLongerNeeded(hash)
    end)
end)

CreateMenu("allplayers","All Player Options","players")
MC("allplayers","Include Self","",nil,
    function() Vars.AllPlayers.IncludeSelf=true end,
    function() Vars.AllPlayers.IncludeSelf=false end)
MB("allplayers","Exploser Tout le Monde","~y~Native", function()
    for _,pid in ipairs(GetActivePlayers()) do
        if pid~=PlayerId() or Vars.AllPlayers.IncludeSelf then
            local c=GetEntityCoords(GetPlayerPed(pid))
            AddExplosion(c.x,c.y,c.z,2,10.0,true,false,0.0)
        end
    end
end)
MC("allplayers","Explosion Loop Serveur","",nil,
    function() Vars.AllPlayers.ExplodisionLoop=true end,
    function() Vars.AllPlayers.ExplodisionLoop=false end)
MC("allplayers","Freeze Serveur","",nil,
    function() Vars.AllPlayers.freezeserver=true end,
    function() Vars.AllPlayers.freezeserver=false end)
MB("allplayers","Flinguer Tout le Monde","", function()
    for _,pid in ipairs(GetActivePlayers()) do
        if pid~=PlayerId() then SetEntityVelocity(GetPlayerPed(pid),0,0,50.0) end
    end
end)
MB("allplayers","Donner Armes Tous","~y~Risque", function()
    for _,pid in ipairs(GetActivePlayers()) do
        local t=GetPlayerPed(pid)
        for _,w in ipairs({"WEAPON_PISTOL","WEAPON_SMG","WEAPON_ASSAULTRIFLE","WEAPON_RPG"}) do
            GiveWeaponToPed(t,GetHashKey(w),9999,false,false)
        end
    end
end)
MB("allplayers","Retirer Armes Tous","", function()
    for _,pid in ipairs(GetActivePlayers()) do RemoveAllPedWeapons(GetPlayerPed(pid),true) end
end)
MB("allplayers","Ejecter Tous des Vehicules","", function()
    for _,pid in ipairs(GetActivePlayers()) do
        local t=GetPlayerPed(pid)
        local v=GetVehiclePedIsIn(t,false)
        if v~=0 then TaskLeaveVehicle(t,v,262144) end
    end
end)
MC("allplayers","Bus Serveur Loop","",nil,
    function() Vars.AllPlayers.busingserverloop=true end,
    function() Vars.AllPlayers.busingserverloop=false end)
MC("allplayers","Cargo Plane Loop","",nil,
    function() Vars.AllPlayers.cargoplaneserverloop=true end,
    function() Vars.AllPlayers.cargoplaneserverloop=false end)
MC("allplayers","Tug Boats sur Joueurs","",nil,
    function() Vars.AllPlayers.tugboatrainoverplayers=true end,
    function() Vars.AllPlayers.tugboatrainoverplayers=false end)

-- SELF
CreateMenu("self","Self Options","main")
MC("self","Invisible",Vars.Self,"invisiblitity",
    function() Vars.Self.invisiblitity=true end,
    function() Vars.Self.invisiblitity=false; SetEntityVisible(PlayerPedId(),true,false) end)
MC("self","Godmode",Vars.Self,"godmode",
    function() Vars.Self.godmode=true end,
    function() Vars.Self.godmode=false; SetEntityInvincible(PlayerPedId(),false); SetPlayerInvincible(PlayerId(),false) end)
MC("self","Semi-Godmode",Vars.Self,"AutoHealthRefil",
    function() Vars.Self.AutoHealthRefil=true end,
    function() Vars.Self.AutoHealthRefil=false end)
MC("self","Infinite Stamina",Vars.Self,"infstamina",
    function() Vars.Self.infstamina=true end,
    function() Vars.Self.infstamina=false end)
MC("self","No Ragdoll",Vars.Self,"noragdoll",
    function() Vars.Self.noragdoll=true end,
    function() Vars.Self.noragdoll=false; SetPedCanRagdoll(PlayerPedId(),true) end)
MC("self","Never Wanted",Vars.Self,"FreezeWantedLevel",
    function() Vars.Self.FreezeWantedLevel=true end,
    function() Vars.Self.FreezeWantedLevel=false end)
MC("self","Player Coords",Vars.Self,"playercoords",
    function() Vars.Self.playercoords=true end,
    function() Vars.Self.playercoords=false end)
MC("self","Force Radar",Vars.Self,"forceradar",
    function() Vars.Self.forceradar=true end,
    function() Vars.Self.forceradar=false end)
MC("self","Super Jump",Vars.Self,"superjump",
    function() Vars.Self.superjump=true end,
    function() Vars.Self.superjump=false end)
MC("self","Super Run",Vars.Self,"superrun",
    function() Vars.Self.superrun=true end,
    function() Vars.Self.superrun=false end)
MC("self","Moon Walk",Vars.Self,"MoonWalk",
    function() Vars.Self.MoonWalk=true end,
    function() Vars.Self.MoonWalk=false; ResetPedMoveRateOverride(PlayerPedId()) end)
MC("self","Infinite Combat Roll",Vars.Self,"InfiniteCombatRoll",
    function() Vars.Self.InfiniteCombatRoll=true end,
    function() Vars.Self.InfiniteCombatRoll=false end)
MC("self","Anti Headshot",Vars.Self,"AntiHeadshot",
    function() Vars.Self.AntiHeadshot=true end,
    function() Vars.Self.AntiHeadshot=false; SetPedSuffersCriticalHits(PlayerPedId(),true) end)
MC("self","Thermal Vision","",nil,
    function() SetSeethrough(true) end,
    function() SetSeethrough(false) end)
MC("self","Night Vision","",nil,
    function() SetNightvision(true) end,
    function() SetNightvision(false) end)
MB("self","Toggle Noclip","", function()
    noclipping=not noclipping
    MachoMenuNotification("Noclip",noclipping and "Active" or "Desactive")
end)
MB("self","Refill Health","", function() SetEntityHealth(PlayerPedId(),200) end)
MB("self","Refill Armour","", function() SetPedArmour(PlayerPedId(),100) end)
MB("self","Force Revive","", function()
    local c=GetEntityCoords(PlayerPedId())
    NetworkResurrectLocalPlayer(c,GetEntityHeading(PlayerPedId()),true,false)
end)
MB("self","Suicide","", function() SetEntityHealth(PlayerPedId(),0) end)
MB("self","Clear Animation","", function()
    ClearPedTasks(PlayerPedId()); ClearPedSecondaryTask(PlayerPedId())
end)
MB("self","Freeze/Unfreeze Self","", function()
    FreezeEntityPosition(PlayerPedId(), not IsEntityPositionFrozen(PlayerPedId()))
end)
MC("self","Disable Object Collisions",Vars.Self,"disableobjectcollisions",
    function() Vars.Self.disableobjectcollisions=true end,
    function() Vars.Self.disableobjectcollisions=false end)
MC("self","Disable Ped Collisions",Vars.Self,"disablepedcollisions",
    function() Vars.Self.disablepedcollisions=true end,
    function() Vars.Self.disablepedcollisions=false end)

-- VEHICLE
CreateMenu("vehicle","Vehicle Options","main")
MC("vehicle","Full Unlock Vehicule",Vars.Vehicle,"FullUnlockVehicle",
    function() Vars.Vehicle.FullUnlockVehicle=true end,
    function() Vars.Vehicle.FullUnlockVehicle=false end)
MS("vehicle","Spawn Vehicles","Spawner","spawnveh")
MS("vehicle","Open Vehicle Doors","Portes","doorsv")
MS("vehicle","Vehicle Tricks","Tricks","tricks")
MS("vehicle","Auto Pilot","Auto Pilot","autopilot")
MB("vehicle","Repair Vehicle","", function()
    local v=GetVehiclePedIsIn(PlayerPedId(),false)
    if v~=0 then SetVehicleFixed(v); SetVehicleDirtLevel(v,0.0) end
end)
MB("vehicle","Flip Vehicle","", function()
    local v=GetVehiclePedIsIn(PlayerPedId(),false)
    if v~=0 then SetEntityRotation(v,0,0,GetEntityHeading(v),2,true) end
end)
MB("vehicle","Toggle Engine","", function()
    local v=GetVehiclePedIsIn(PlayerPedId(),false)
    if v~=0 then SetVehicleEngineOn(v,not GetIsVehicleEngineRunning(v),true,true) end
end)
MB("vehicle","Delete Vehicle","", function()
    local v=GetVehiclePedIsIn(PlayerPedId(),false)
    if v~=0 then TaskLeaveVehicle(PlayerPedId(),v,0); Citizen.Wait(1000); DeleteVehicle(v) end
end)
MB("vehicle","Max Out Vehicle","", function()
    local v=GetVehiclePedIsIn(PlayerPedId(),false)
    if v~=0 then
        SetVehicleModKit(v,0)
        for m=0,50 do SetVehicleMod(v,m,GetNumVehicleMods(v,m)-1,false) end
        ToggleVehicleMod(v,18,true); ToggleVehicleMod(v,22,true)
    end
end)
MB("vehicle","Boost","", function()
    local v=GetVehiclePedIsIn(PlayerPedId(),false)
    if v~=0 then
        local r=math.rad(GetEntityHeading(v))
        SetEntityVelocity(v,-math.sin(r)*50,math.cos(r)*50,0)
    end
end)
MC("vehicle","Vehicle Godmode",Vars.Vehicle,"vehgodmode",
    function() Vars.Vehicle.vehgodmode=true end,
    function() Vars.Vehicle.vehgodmode=false end)
MC("vehicle","Always Clean",Vars.Vehicle,"AutoClean",
    function() Vars.Vehicle.AutoClean=true end,
    function() Vars.Vehicle.AutoClean=false end)
MC("vehicle","Speed Boost on Horn",Vars.Vehicle,"speedboost",
    function() Vars.Vehicle.speedboost=true end,
    function() Vars.Vehicle.speedboost=false end)
MC("vehicle","Waterproof",Vars.Vehicle,"Waterproof",
    function() Vars.Vehicle.Waterproof=true end,
    function() Vars.Vehicle.Waterproof=false end)
MC("vehicle","Rainbow Car",Vars.Vehicle,"rainbowcar",
    function() Vars.Vehicle.rainbowcar=true end,
    function() Vars.Vehicle.rainbowcar=false end)
MC("vehicle","Always Wheelie",Vars.Vehicle,"AlwaysWheelie",
    function() Vars.Vehicle.AlwaysWheelie=true end,
    function() Vars.Vehicle.AlwaysWheelie=false end)
MC("vehicle","Easy Handling",Vars.Vehicle,"EasyHandling",
    function() Vars.Vehicle.EasyHandling=true end,
    function() Vars.Vehicle.EasyHandling=false end)
MC("vehicle","Drive On Water",Vars.Vehicle,"DriveOnWater",
    function() Vars.Vehicle.DriveOnWater=true end,
    function() Vars.Vehicle.DriveOnWater=false end)
MC("vehicle","No Bike Fall",Vars.Vehicle,"NoBikeFall",
    function() Vars.Vehicle.NoBikeFall=true end,
    function() Vars.Vehicle.NoBikeFall=false end)
MC("vehicle","Force Launch Control",Vars.Vehicle,"forcelauncontrol",
    function() Vars.Vehicle.forcelauncontrol=true end,
    function() Vars.Vehicle.forcelauncontrol=false end)
MC("vehicle","Speedometre",Vars.Vehicle,"speedometer",
    function() Vars.Vehicle.speedometer=true end,
    function() Vars.Vehicle.speedometer=false end)
MC("vehicle","ZeyMenu Plate",Vars.Vehicle,"ZeyMenuplate",
    function() Vars.Vehicle.ZeyMenuplate=true end,
    function() Vars.Vehicle.ZeyMenuplate=false end)
MC("vehicle","Vehicle Snatcher","",nil,
    function() VehicleSnatcher=true end,
    function() VehicleSnatcher=false end)

CreateMenu("spawnveh","Spawn Vehicles","vehicle")
MC("spawnveh","Spawn Inside","",nil,
    function() spawninsidevehicle=true end,
    function() spawninsidevehicle=false end)
MB("spawnveh","[Entree] Spawner par nom","Taper le nom dans chat", function()
    MachoMenuNotification("Spawn","Entrez le nom du vehicule dans le chat puis /spawn")
end)
for _,fv in ipairs({{"UFO","hydra"},{"T20 Ramp","rcbandito"},{"Armoured Banshee","banshee2"},{"Boombox Car","wastelander"},{"Cargo Plane","cargoplane"}}) do
    local label,model=fv[1],fv[2]
    MB("spawnveh",label,"", function()
        local hash=GetHashKey(model); RequestModel(hash)
        Citizen.CreateThread(function()
            while not HasModelLoaded(hash) do Citizen.Wait(100) end
            local c=GetEntityCoords(PlayerPedId())
            local v=CreateVehicle(hash,c.x+3,c.y,c.z,GetEntityHeading(PlayerPedId()),true,false)
            if spawninsidevehicle then SetPedIntoVehicle(PlayerPedId(),v,-1) end
            SetModelAsNoLongerNeeded(hash)
            MachoMenuNotification("Spawn",label.." spawne !")
        end)
    end)
end

CreateMenu("doorsv","Vehicle Doors","vehicle")
MB("doorsv","Open All Doors","", function()
    local v=GetVehiclePedIsIn(PlayerPedId(),false)
    if v~=0 then for d=0,5 do SetVehicleDoorOpen(v,d,false,false) end end
end)
MB("doorsv","Close All Doors","", function()
    local v=GetVehiclePedIsIn(PlayerPedId(),false)
    if v~=0 then for d=0,5 do SetVehicleDoorShut(v,d,false) end end
end)
MB("doorsv","Break All Doors","", function()
    local v=GetVehiclePedIsIn(PlayerPedId(),false)
    if v~=0 then for d=0,5 do SetVehicleDoorBroken(v,d,true) end end
end)

CreateMenu("tricks","Vehicle Tricks","vehicle")
MB("tricks","Kick Flip","", function()
    local v=GetVehiclePedIsIn(PlayerPedId(),false)
    if v~=0 then SetEntityVelocity(v,0,0,20) end
end)
MB("tricks","Back Flip","", function()
    local v=GetVehiclePedIsIn(PlayerPedId(),false)
    if v~=0 then
        local vel=GetEntityVelocity(v)
        SetEntityVelocity(v,vel.x,vel.y,vel.z+15)
        SetEntityRotation(v,-90,0,GetEntityHeading(v),2,true)
    end
end)
MB("tricks","Jump","", function()
    local v=GetVehiclePedIsIn(PlayerPedId(),false)
    if v~=0 then SetEntityVelocity(v,0,0,30) end
end)

CreateMenu("autopilot","Auto Pilot","vehicle")
MB("autopilot","Drive To Waypoint","", function()
    local v=GetVehiclePedIsIn(PlayerPedId(),false)
    if v~=0 then
        local blip=GetFirstBlipInfoId(8)
        if DoesBlipExist(blip) then
            local c=GetBlipInfoIdCoord(blip)
            TaskVehicleDriveToCoordLongrange(PlayerPedId(),v,c.x,c.y,c.z,Vars.Vehicle.AutoPilot.CruiseSpeed,Vars.Vehicle.AutoPilot.DrivingStyle,5.0)
            PVAutoDriving=true
        end
    end
end)
MB("autopilot","Cancel Auto Pilot","", function()
    ClearPedTasks(PlayerPedId()); PVAutoDriving=false
end)

-- TELEPORT
CreateMenu("teleport","Teleport Options","main")
MC("teleport","Smooth Teleport",Vars.Teleport,"smoothteleport",
    function() Vars.Teleport.smoothteleport=true end,
    function() Vars.Teleport.smoothteleport=false end)
MB("teleport","Teleport To Waypoint","", function()
    local blip=GetFirstBlipInfoId(8)
    if DoesBlipExist(blip) then
        local c=GetBlipInfoIdCoord(blip)
        if Vars.Teleport.smoothteleport then DoScreenFadeOut(500); Citizen.Wait(500) end
        SetEntityCoords(PlayerPedId(),c.x,c.y,c.z+3,false,false,false,false)
        if Vars.Teleport.smoothteleport then DoScreenFadeIn(500) end
    end
end)
MB("teleport","Teleport Forward","", function()
    local ped=PlayerPedId(); local c=GetEntityCoords(ped)
    local r=math.rad(GetEntityHeading(ped))
    SetEntityCoords(ped,c.x-math.sin(r)*10,c.y+math.cos(r)*10,c.z,false,false,false,false)
end)
MB("teleport","TP Ocean Aleatoire","2 etapes bypass AC", function()
    local ped=PlayerPedId(); local veh=GetVehiclePedIsIn(ped,false)
    local wp={x=-7000.0,y=-7000.0,z=0.0}
    if veh~=0 then SetEntityCoords(veh,wp.x,wp.y,wp.z,false,false,false,false)
    else SetEntityCoords(ped,wp.x,wp.y,wp.z,false,false,false,false) end
    Citizen.Wait(math.random(80,150))
    local dests=Vars.Teleport.oceanDestinations
    local idx=math.random(1,#dests)
    if Vars.Teleport.lastOceanIndex then
        repeat idx=math.random(1,#dests) until idx~=Vars.Teleport.lastOceanIndex
    end
    Vars.Teleport.lastOceanIndex=idx
    local d=dests[idx]
    SetEntityCoords(ped,d.x,d.y,d.z,false,false,false,false)
    MachoMenuNotification("TP Ocean","Arrive a "..d.nom.." !")
end)
MC("teleport","TP Ocean V2 [W] Avec Vehicule",Vars.Teleport,"OceanV2",
    function()
        Vars.Teleport.OceanV2=true
        MachoMenuNotification("TP Ocean V2","W pour voler vehicule + TP ocean")
    end,
    function() Vars.Teleport.OceanV2=false end)
MB("teleport","Mission Row PD","", function()
    SetEntityCoords(PlayerPedId(),440.22,-982.21,30.69,false,false,false,false)
end)
MB("teleport","Sandy Shores PD","", function()
    SetEntityCoords(PlayerPedId(),1857.48,3677.88,33.73,false,false,false,false)
end)
MB("teleport","Paleto Bay PD","", function()
    SetEntityCoords(PlayerPedId(),-434.34,6020.89,31.50,false,false,false,false)
end)

-- WEAPON
CreateMenu("weapon","Weapon Options","main")
MS("weapon","Aimbot","Settings aimbot","aimbot")
MS("weapon","Bullet Options","Remplacer balles","bulletopts")
MB("weapon","Get All Weapons","", function()
    for _,w in ipairs({"WEAPON_PISTOL","WEAPON_COMBATPISTOL","WEAPON_MICROSMG","WEAPON_SMG","WEAPON_ASSAULTRIFLE","WEAPON_CARBINERIFLE","WEAPON_MG","WEAPON_COMBATMG","WEAPON_HEAVYSNIPER","WEAPON_RPG","WEAPON_GRENADE","WEAPON_STICKYBOMB","WEAPON_KNIFE","WEAPON_BAT"}) do
        GiveWeaponToPed(PlayerPedId(),GetHashKey(w),9999,false,false)
    end
    MachoMenuNotification("Armes","Toutes donnees !")
end)
MB("weapon","Remove All Weapons","", function() RemoveAllPedWeapons(PlayerPedId(),true) end)
MB("weapon","Refill All Ammo","", function()
    for _,w in ipairs({"WEAPON_PISTOL","WEAPON_SMG","WEAPON_ASSAULTRIFLE","WEAPON_MG","WEAPON_HEAVYSNIPER","WEAPON_RPG"}) do
        SetPedAmmo(PlayerPedId(),GetHashKey(w),9999)
    end
end)
MC("weapon","Infinite Ammo",Vars.Weapon,"InfAmmo",
    function() Vars.Weapon.InfAmmo=true end,
    function() Vars.Weapon.InfAmmo=false end)
MC("weapon","No Reload",Vars.Weapon,"NoReload",
    function() Vars.Weapon.NoReload=true end,
    function() Vars.Weapon.NoReload=false end)
MC("weapon","Explosive Ammo",Vars.Weapon,"ExplosiveAmmo",
    function() Vars.Weapon.ExplosiveAmmo=true end,
    function() Vars.Weapon.ExplosiveAmmo=false end)
MC("weapon","Rapid Fire",Vars.Weapon,"RapidFire",
    function() Vars.Weapon.RapidFire=true end,
    function() Vars.Weapon.RapidFire=false end)
MC("weapon","Trigger Bot",Vars.Weapon,"TriggerBot",
    function() Vars.Weapon.TriggerBot=true end,
    function() Vars.Weapon.TriggerBot=false end)
MC("weapon","No Recoil",Vars.Weapon,"NoRecoil",
    function() Vars.Weapon.NoRecoil=true end,
    function() Vars.Weapon.NoRecoil=false end)
MC("weapon","Crosshair",Vars.Weapon,"Crosshair",
    function() Vars.Weapon.Crosshair=true end,
    function() Vars.Weapon.Crosshair=false end)
MC("weapon","Bullet Tracers",Vars.Weapon,"Tracers",
    function() Vars.Weapon.Tracers=true end,
    function() Vars.Weapon.Tracers=false end)
MC("weapon","Spinbot",Vars.Weapon,"Spinbot",
    function() Vars.Weapon.Spinbot=true end,
    function() Vars.Weapon.Spinbot=false end)
MC("weapon","Ragebot",Vars.Weapon,"RageBot",
    function() Vars.Weapon.RageBot=true end,
    function() Vars.Weapon.RageBot=false end)
MC("weapon","One Shot",Vars.Weapon,"OneShot",
    function() Vars.Weapon.OneShot=true end,
    function() Vars.Weapon.OneShot=false end)

CreateMenu("aimbot","Aimbot","weapon")
MC("aimbot","Aimbot",Vars.Weapon.AimBot,"Enabled",
    function() Vars.Weapon.AimBot.Enabled=true end,
    function() Vars.Weapon.AimBot.Enabled=false end)
MC("aimbot","Through Walls",Vars.Weapon.AimBot,"ThroughWalls",
    function() Vars.Weapon.AimBot.ThroughWalls=true end,
    function() Vars.Weapon.AimBot.ThroughWalls=false end)
MC("aimbot","Draw FOV",Vars.Weapon.AimBot,"DrawFOV",
    function() Vars.Weapon.AimBot.DrawFOV=true end,
    function() Vars.Weapon.AimBot.DrawFOV=false end)
MC("aimbot","Only Target Players",Vars.Weapon.AimBot,"OnlyPlayers",
    function() Vars.Weapon.AimBot.OnlyPlayers=true end,
    function() Vars.Weapon.AimBot.OnlyPlayers=false end)
MC("aimbot","Ignore Friends",Vars.Weapon.AimBot,"IgnoreFriends",
    function() Vars.Weapon.AimBot.IgnoreFriends=true end,
    function() Vars.Weapon.AimBot.IgnoreFriends=false end)
MC("aimbot","Visibility Check",Vars.Weapon.AimBot,"InvisibilityCheck",
    function() Vars.Weapon.AimBot.InvisibilityCheck=true end,
    function() Vars.Weapon.AimBot.InvisibilityCheck=false end)
MB("aimbot","Bone: Head","", function() Vars.Weapon.AimBot.Bone="SKEL_HEAD" end)
MB("aimbot","Bone: Chest","", function() Vars.Weapon.AimBot.Bone="SKEL_SPINE3" end)
MB("aimbot","Bone: Pelvis","", function() Vars.Weapon.AimBot.Bone="SKEL_Pelvis" end)

CreateMenu("bulletopts","Bullet Options","weapon")
MC("bulletopts","Bullet Replace",Vars.Weapon,"BulletEnabled",
    function() Vars.Weapon.BulletEnabled=true end,
    function() Vars.Weapon.BulletEnabled=false end)
for i,name in ipairs({"Revolver","Heavy Sniper","RPG","Firework","Ray Pistol"}) do
    local idx=i
    MB("bulletopts",name,"", function()
        Vars.Weapon.BulletIndex=idx
        MachoMenuNotification("Bullet","Bullet: "..name)
    end)
end

-- WORLD
CreateMenu("world","World Options","main")
MS("world","Weather Options","Changer la meteo","weather")
MS("world","Time Options","Changer l heure","time")
MC("world","Flying Cars",Vars.Misc,"FlyingCars",
    function() Vars.Misc.FlyingCars=true end,
    function() Vars.Misc.FlyingCars=false end)
MC("world","Unlock All Vehicles",Vars.Misc,"UnlockAllVehicles",
    function() Vars.Misc.UnlockAllVehicles=true end,
    function() Vars.Misc.UnlockAllVehicles=false end)
MB("world","Quit Game","", function() ForceSocialClubUpdate() end)

CreateMenu("weather","Weather Options","world")
for _,w in ipairs({"EXTRASUNNY","CLEAR","CLOUDS","SMOG","FOGGY","OVERCAST","RAIN","THUNDER","CLEARING","NEUTRAL","SNOW","BLIZZARD","SNOWLIGHT","XMAS","HALLOWEEN"}) do
    local wname=w
    MB("weather",wname,"", function()
        SetWeatherTypePersist(wname); SetWeatherTypeNow(wname); SetWeatherTypeNowPersist(wname)
    end)
end

CreateMenu("time","Time Options","world")
for _,h in ipairs({0,6,8,12,15,18,20,22}) do
    local hour=h
    MB("time",string.format("%02dh00",hour),"", function()
        NetworkOverrideClockTime(hour,0,0)
    end)
end

-- MISC
CreateMenu("misc","Misc Options","main")
MS("misc","Anticheat Options","Seed / SafeMode / Detection","anticheat")
MS("misc","ESP Options","Box / Nom / Lignes","esp")
MS("misc","Script Options","Hostage / Carry / Peacetime","scriptopts")
MS("misc","Server Options","ESX / VRP","serveropts")

CreateMenu("anticheat","Anticheat Options","misc")
MC("anticheat","Safe Mode Seed",Vars.AntiCheat,"SafeModeSeed",
    function()
        Vars.AntiCheat.SafeModeSeed=true
        local sr=nil
        for _,res in ipairs(GetResources()) do
            if string.find(string.lower(res),"seed") then sr=res; break end
        end
        if sr then
            TriggerEvent("__cfx_internal:removeAllEventHandlers",sr)
            MachoMenuNotification("Safe Mode Seed","Actif: "..sr)
        else Vars.AntiCheat.SafeModeSeed=false end
    end,
    function() Vars.AntiCheat.SafeModeSeed=false end)
if not Vars.AntiCheat.SeedBlocked then
    MB("anticheat","SEED Destruction Totale","~r~IRREVERSIBLE", function()
        MachoSetLoggerState(0)
        local found={}
        for _,res in ipairs(GetResources()) do
            local rL=string.lower(res)
            if string.find(rL,"seed") then table.insert(found,res)
            else
                local mf=LoadResourceFile(res,"fxmanifest.lua") or LoadResourceFile(res,"__resource.lua") or ""
                if string.find(string.lower(mf),"seed") then table.insert(found,res) end
            end
        end
        if #found==0 then
            MachoMenuNotification("Seed","Aucune resource Seed detectee")
            MachoSetLoggerState(1); return
        end
        Vars.AntiCheat.SeedBlocked=true
        for _,sr in ipairs(found) do
            MachoMenuNotification("Seed TARGET",sr)
            if MachoResourceInjectable(sr) then
                MachoInjectResource2(3,sr,[[
                    for _,g in ipairs({"SeedAC","Seed","seedac","SeedCheck","SeedAntiCheat","BanPlayer","KickPlayer","ReportPlayer"}) do
                        _G[g]=type(_G[g])=="function" and function() end or nil
                    end
                    if _G.detections then _G.detections={} end
                    if _G.violations then _G.violations={} end
                ]])
            end
            MachoInjectResource2(3,"any",[[
                local _oTSE=TriggerServerEvent
                TriggerServerEvent=function(n,...) if n and string.find(string.lower(tostring(n)),"seed") then return end return _oTSE(n,...) end
                local _oTE=TriggerEvent
                TriggerEvent=function(n,...) if n and string.find(string.lower(tostring(n)),"seed") then return end return _oTE(n,...) end
                local _oAEH=AddEventHandler
                AddEventHandler=function(n,cb) if n and string.find(string.lower(tostring(n)),"seed") then return end return _oAEH(n,cb) end
                local _oGRS=GetResourceState
                GetResourceState=function(n) if n and string.find(string.lower(tostring(n)),"seed") then return "missing" end return _oGRS(n) end
            ]])
            for i=1,20 do TriggerEvent("__cfx_internal:removeAllEventHandlers",sr) end
            for i=1,30 do TriggerServerEvent("__cfx_internal:stopResource",sr) end
            MachoResourceStop(sr)
            MachoInjectResource2(0,"any",[[
                Citizen.CreateThread(function()
                    while true do Citizen.Wait(300)
                        for i=1,GetNumResources() do
                            local r=GetResourceByFindIndex(i)
                            if r and string.find(string.lower(r),"seed") then
                                for j=1,20 do TriggerServerEvent("__cfx_internal:stopResource",r) end
                                TriggerEvent("__cfx_internal:removeAllEventHandlers",r)
                            end
                        end
                    end
                end)
            ]])
        end
        MachoSetLoggerState(1)
        MachoMenuNotification("Seed DETRUIT","Verrou permanent actif")
    end)
end
MC("anticheat","Safe Mode Global","",nil,
    function() SafeMode=true; MachoMenuNotification("Safe Mode","Actif") end,
    function() SafeMode=false end)
local function acS(k) return Vars.AntiCheat[k] and "~g~DETECTE~s~" or "Non detecte" end
MB("anticheat","BadgerAC: "..acS("BadgerAC"),"",nil)
MB("anticheat","TigoAC: "..acS("TigoAC"),"",nil)
MB("anticheat","VAC: "..acS("VAC"),"",nil)
MB("anticheat","ChocoHax: "..acS("ChocoHax"),"",nil)

CreateMenu("esp","ESP Options","misc")
MC("esp","ESP Box",Vars.Misc,"ESPBox",
    function() Vars.Misc.ESPBox=true end,
    function() Vars.Misc.ESPBox=false end)
MC("esp","ESP Nom",Vars.Misc,"ESPName",
    function() Vars.Misc.ESPName=true end,
    function() Vars.Misc.ESPName=false end)
MC("esp","ESP Lignes",Vars.Misc,"ESPLines",
    function() Vars.Misc.ESPLines=true end,
    function() Vars.Misc.ESPLines=false end)
MC("esp","ESP Bones",Vars.Misc,"ESPBones",
    function() Vars.Misc.ESPBones=true end,
    function() Vars.Misc.ESPBones=false end)
MC("esp","ESP Blips",Vars.Misc,"ESPBlips",
    function() Vars.Misc.ESPBlips=true end,
    function() Vars.Misc.ESPBlips=false end)

CreateMenu("scriptopts","Script Options","misc")
MC("scriptopts","Block Take Hostage",Vars.Script,"blocktakehostage",
    function() Vars.Script.blocktakehostage=true end,
    function() Vars.Script.blocktakehostage=false end)
MC("scriptopts","Block Black Screen",Vars.Script,"BlockBlackScreen",
    function() Vars.Script.BlockBlackScreen=true end,
    function() Vars.Script.BlockBlackScreen=false end)
MC("scriptopts","Block Being Carried",Vars.Script,"blockbeingcarried",
    function() Vars.Script.blockbeingcarried=true end,
    function() Vars.Script.blockbeingcarried=false end)
MC("scriptopts","Block Peacetime",Vars.Script,"BlockPeacetime",
    function() Vars.Script.BlockPeacetime=true end,
    function() Vars.Script.BlockPeacetime=false end)
MC("scriptopts","GGAC Bypass",Vars.Script,"GGACBypass",
    function() Vars.Script.GGACBypass=true end,
    function() Vars.Script.GGACBypass=false end)
MC("scriptopts","SSB Bypass",Vars.Script,"SSBBypass",
    function() Vars.Script.SSBBypass=true end,
    function() Vars.Script.SSBBypass=false end)
MC("scriptopts","Vault Doors",Vars.Script,"vault_doors",
    function() Vars.Script.vault_doors=true end,
    function() Vars.Script.vault_doors=false end)

CreateMenu("serveropts","Server Options","misc")
MB("serveropts","ESX: "..(Vars.Server.ESXServer and "~g~Detecte" or "~r~Non detecte"),"",nil)
MB("serveropts","VRP: "..(Vars.Server.VRPServer and "~g~Detecte" or "~r~Non detecte"),"",nil)

-- SETTINGS
CreateMenu("settings","Settings","main")
MC("settings","Watermark",Vars.MenuOptions,"Watermark",
    function() Vars.MenuOptions.Watermark=true end,
    function() Vars.MenuOptions.Watermark=false end)
MB("settings","ZeyMenu Macho Edition","",nil)
MB("settings","Cle: "..MachoAuthenticationKey(),"",nil)
MB("settings","Kill Menu","Fermer completement", function()
    Menu.open=false; killmenu=true
end)

-- ============================================================
-- MOTEUR DE RENDU ET NAVIGATION CLAVIER
-- ============================================================

local function GetChecked(item)
    if item.varTable == nil or item.varKey == nil then return false end
    if type(item.varTable) ~= "table" then return false end
    return item.varTable[item.varKey] == true
end

local function DrawMenuText(text, x, y, scale, r, g, b, a, centered, outlined)
    SetTextFont(0)
    SetTextScale(scale, scale)
    SetTextColour(r or 255, g or 255, b or 255, a or 255)
    if outlined then SetTextOutline() end
    if centered then SetTextJustification(0) end
    BeginTextCommandDisplayText("STRING")
    AddTextComponentSubstringPlayerName(text)
    EndTextCommandDisplayText(x, y)
end

-- Rendu du menu
local function RenderMenu()
    if not Menu.open or not Menu.currentMenu then return end
    local menu = Menus[Menu.currentMenu]
    if not menu then return end

    local x    = Menu.x
    local y    = Menu.y
    local w    = Menu.width
    local tH   = Menu.titleH
    local iH   = Menu.itemH
    local rgb  = Menu.rgb

    -- Fond titre
    DrawRect(x + w/2, y + tH/2, w, tH, 0, 0, 0, 220)
    -- Barre couleur en haut du titre
    DrawRect(x + w/2, y + 0.003, w, 0.006, rgb.r, rgb.g, rgb.b, 255)
    -- Texte titre
    DrawMenuText(menu.title, x + w/2, y + tH*0.5, 0.7, 255, 255, 255, 255, true, true)

    -- Items
    local nbItems = #menu.items
    local visible = math.min(Menu.maxVisible, nbItems)
    for i = 1, visible do
        local realIdx = i + Menu.scroll
        local item    = menu.items[realIdx]
        if not item then break end

        local iy     = y + tH + (i-1)*iH
        local selected = (realIdx == Menu.cursorIndex)

        -- Fond item
        if selected then
            DrawRect(x + w/2, iy + iH/2, w, iH, rgb.r, rgb.g, rgb.b, 200)
        else
            local bg = (i % 2 == 0) and 20 or 30
            DrawRect(x + w/2, iy + iH/2, w, iH, bg, bg, bg, 210)
        end

        -- Label
        local labelColor = selected and {0,0,0} or {255,255,255}
        DrawMenuText(item.label, x + 0.007, iy + iH*0.23, Menu.textScale,
            labelColor[1], labelColor[2], labelColor[3], 255, false, false)

        -- Subtext / checkbox / fleche
        if item.type == "checkbox" then
            local checked = GetChecked(item)
            -- Aligner à droite dans le menu avec une marge intérieure
            SetTextFont(0)
            SetTextScale(Menu.textScale, Menu.textScale)
            SetTextRightJustify(true)
            SetTextWrap(0.0, x + w - 0.006)
            if checked then
                SetTextColour(selected and 0 or 50, selected and 180 or 220, selected and 0 or 50, 255)
            else
                SetTextColour(selected and 160 or 200, selected and 0 or 50, selected and 0 or 50, 255)
            end
            BeginTextCommandDisplayText("STRING")
            AddTextComponentSubstringPlayerName(checked and "ON" or "OFF")
            EndTextCommandDisplayText(x + w - 0.006, iy + iH*0.23)
        elseif item.type == "submenu" then
            SetTextFont(0)
            SetTextScale(Menu.textScale, Menu.textScale)
            SetTextRightJustify(true)
            SetTextWrap(0.0, x + w - 0.006)
            SetTextColour(selected and 0 or 200, selected and 0 or 200, selected and 0 or 200, 255)
            BeginTextCommandDisplayText("STRING")
            AddTextComponentSubstringPlayerName(">")
            EndTextCommandDisplayText(x + w - 0.006, iy + iH*0.23)
        elseif item.subtext and item.subtext ~= "" then
            SetTextFont(0)
            SetTextScale(Menu.textScale * 0.85, Menu.textScale * 0.85)
            SetTextRightJustify(true)
            SetTextWrap(0.0, x + w - 0.006)
            SetTextColour(selected and 20 or 150, selected and 20 or 150, selected and 20 or 150, 255)
            BeginTextCommandDisplayText("STRING")
            AddTextComponentSubstringPlayerName(item.subtext)
            EndTextCommandDisplayText(x + w - 0.006, iy + iH*0.23)
        end
    end

    -- Barre de scroll si nécessaire
    if nbItems > Menu.maxVisible then
        local sbH  = iH * visible
        local sbY  = y + tH
        local prog = Menu.scroll / math.max(1, nbItems - Menu.maxVisible)
        local kH   = sbH * (Menu.maxVisible / nbItems)
        local kY   = sbY + prog * (sbH - kH)
        DrawRect(x + w - 0.003, kY + kH/2, 0.004, kH, rgb.r, rgb.g, rgb.b, 200)
    end

    -- Hint bas
    local hintY = y + tH + visible * iH + 0.005
    DrawMenuText("~INPUT_FRONTEND_UP~~INPUT_FRONTEND_DOWN~ Naviguer  ~INPUT_FRONTEND_ACCEPT~ Valider  ~INPUT_FRONTEND_CANCEL~ Retour",
        x + w/2, hintY, 0.22, 180, 180, 180, 255, true, false)
end

-- Navigation
local navCooldown = 0

local function Navigate(dir)
    if not Menu.currentMenu then return end
    local menu = Menus[Menu.currentMenu]
    if not menu then return end
    local n = #menu.items

    Menu.cursorIndex = Menu.cursorIndex + dir
    if Menu.cursorIndex < 1 then Menu.cursorIndex = n end
    if Menu.cursorIndex > n then Menu.cursorIndex = 1 end

    -- Ajuster scroll
    if Menu.cursorIndex <= Menu.scroll then
        Menu.scroll = Menu.cursorIndex - 1
    elseif Menu.cursorIndex > Menu.scroll + Menu.maxVisible then
        Menu.scroll = Menu.cursorIndex - Menu.maxVisible
    end
end

local function Select()
    if not Menu.currentMenu then return end
    local menu = Menus[Menu.currentMenu]
    if not menu then return end
    local item = menu.items[Menu.cursorIndex]
    if not item then return end

    if item.type == "submenu" then
        table.insert(breadcrumb, {menu=Menu.currentMenu, cursor=Menu.cursorIndex, scroll=Menu.scroll})
        Menu.currentMenu = item.targetId
        Menu.cursorIndex = 1
        Menu.scroll = 0

    elseif item.type == "checkbox" then
        local checked = GetChecked(item)
        if checked then
            if item.onDisable then item.onDisable() end
        else
            if item.onEnable then item.onEnable() end
        end

    elseif item.type == "button" then
        if item.action then item.action() end
    end
end

local function GoBack()
    if #breadcrumb > 0 then
        local prev = table.remove(breadcrumb)
        Menu.currentMenu = prev.menu
        Menu.cursorIndex = prev.cursor
        Menu.scroll      = prev.scroll
    else
        Menu.open = false
    end
end

-- Input via MachoOnKeyDown (Virtual-Key codes)
-- VK_DELETE=0x2E, UP=0x26, DOWN=0x28, RETURN=0x0D, BACK=0x08
MachoOnKeyDown(function(vk)
    -- DELETE: toggle menu
    if vk == 0x2E then
        Menu.open = not Menu.open
        if Menu.open and not Menu.currentMenu then
            Menu.currentMenu = "main"
            Menu.cursorIndex = 1
            Menu.scroll = 0
            breadcrumb = {}
        end
        return
    end

    if not Menu.open then return end

    if vk == 0x26 then        -- Fleche Haut
        Navigate(-1)
    elseif vk == 0x28 then    -- Fleche Bas
        Navigate(1)
    elseif vk == 0x0D then    -- Entree
        Select()
    elseif vk == 0x08 then    -- Backspace
        GoBack()
    end
end)

-- ============================================================
-- THREAD RENDU PRINCIPAL
-- ============================================================

Citizen.CreateThread(function()
    while not killmenu do
        Citizen.Wait(0)

        -- Cycling RGB
        local t = GetGameTimer() / 1000.0
        Menu.rgb.r = math.floor((math.sin(t*0.8)       * 0.5 + 0.5) * 255)
        Menu.rgb.g = math.floor((math.sin(t*0.8+2.094) * 0.5 + 0.5) * 255)
        Menu.rgb.b = math.floor((math.sin(t*0.8+4.189) * 0.5 + 0.5) * 255)

        -- Rendu
        if Menu.open then
            RenderMenu()
        end

        -- Watermark
        if Vars.MenuOptions.Watermark then
            DrawMenuText("ZeyMenu Macho", 0.01, 0.01, 0.3, 30, 144, 255, 200, false, true)
        end
    end
end)

-- ============================================================
-- THREADS LOGIQUE (identiques ZeyMenu)
-- ============================================================

-- Self
Citizen.CreateThread(function()
    while not killmenu do
        Citizen.Wait(0)
        local ped = PlayerPedId()
        if Vars.Self.godmode then SetEntityInvincible(ped,true); SetPlayerInvincible(PlayerId(),true) end
        if Vars.Self.AutoHealthRefil then if GetEntityHealth(ped)<190 then SetEntityHealth(ped,200) end end
        if Vars.Self.noragdoll then SetPedCanRagdoll(ped,false) end
        if Vars.Self.FreezeWantedLevel then
            SetPlayerWantedLevel(PlayerId(),0,false); SetPlayerWantedLevelNow(PlayerId(),false)
        end
        if Vars.Self.infstamina then ResetPlayerStaminaCountdown(PlayerId()) end
        if Vars.Self.superjump then SetSuperJumpThisFrame(PlayerId()) end
        if Vars.Self.superrun then SetRunSprintMultiplierForPlayer(PlayerId(),1.49) end
        if Vars.Self.MoonWalk then SetPedMoveRateOverride(ped,0.5) end
        if Vars.Self.AntiHeadshot then SetPedSuffersCriticalHits(ped,false) end
        if Vars.Self.invisiblitity then
            SetEntityVisible(ped,false,false)
            local v=GetVehiclePedIsIn(ped,false)
            if v~=0 then SetEntityVisible(v,false,false) end
        end
        if Vars.Self.forceradar then DisplayRadar(true) end
        if Vars.Self.playercoords then
            local c=GetEntityCoords(ped)
            SetTextFont(0); SetTextScale(0.3,0.3); SetTextColour(255,255,255,255)
            BeginTextCommandDisplayText("STRING")
            AddTextComponentSubstringPlayerName(string.format("X:%.1f Y:%.1f Z:%.1f",c.x,c.y,c.z))
            EndTextCommandDisplayText(0.01,0.95)
        end
        if Vars.Self.disableobjectcollisions then
            for _,o in ipairs(GetGamePool("CObject")) do SetEntityNoCollisionEntity(ped,o,true) end
        end
        if Vars.Self.disablepedcollisions then
            for _,p in ipairs(GetGamePool("CPed")) do
                if p~=ped then SetEntityNoCollisionEntity(ped,p,true) end
            end
        end
    end
end)

-- Vehicle
Citizen.CreateThread(function()
    while not killmenu do
        Citizen.Wait(100)
        local ped=PlayerPedId(); local veh=GetVehiclePedIsIn(ped,false)
        if veh~=0 then
            if Vars.Vehicle.vehgodmode then
                SetEntityInvincible(veh,true); SetVehicleEngineHealth(veh,1000.0); SetVehicleBodyHealth(veh,1000.0)
            end
            if Vars.Vehicle.AutoClean then SetVehicleDirtLevel(veh,0.0) end
            if Vars.Vehicle.rainbowcar then
                local t=GetGameTimer()/1000.0
                SetVehicleCustomPrimaryColour(veh,
                    math.floor((math.sin(t*2)*0.5+0.5)*255),
                    math.floor((math.sin(t*2+2.094)*0.5+0.5)*255),
                    math.floor((math.sin(t*2+4.189)*0.5+0.5)*255))
            end
            if Vars.Vehicle.ZeyMenuplate then SetVehicleNumberPlateText(veh,"ZEYMENU") end
            if Vars.Vehicle.speedboost and IsControlPressed(0,86) then
                local r=math.rad(GetEntityHeading(veh))
                SetEntityVelocity(veh,-math.sin(r)*30,math.cos(r)*30,0)
            end
            if Vars.Vehicle.NoBikeFall then SetPedCanBeDraggedOutOfVehicle(ped,false) end
        end
        if Vars.Vehicle.FullUnlockVehicle then
            local myC=GetEntityCoords(ped)
            for _,v in ipairs(GetGamePool("CVehicle")) do
                if #(myC-GetEntityCoords(v))<4.0 then SetVehicleDoorsLocked(v,1) end
            end
        end
        if Vars.Misc.UnlockAllVehicles then
            for _,v in ipairs(GetGamePool("CVehicle")) do SetVehicleDoorsLocked(v,1) end
        end
        if Vars.Misc.FlyingCars then
            for _,v in ipairs(GetGamePool("CVehicle")) do
                if GetVehiclePedIsIn(ped,false)~=v then
                    SetVehicleGravity(v,false)
                    local vel=GetEntityVelocity(v)
                    if vel.z<5.0 then SetEntityVelocity(v,vel.x,vel.y,vel.z+0.5) end
                end
            end
        end
    end
end)

-- Weapon
Citizen.CreateThread(function()
    while not killmenu do
        Citizen.Wait(0)
        local ped=PlayerPedId()
        if Vars.Weapon.InfAmmo then local h=GetSelectedPedWeapon(ped); if h then SetPedAmmo(ped,h,9999) end end
        if Vars.Weapon.ExplosiveAmmo then SetExplosiveAmmoThisFrame(PlayerId()) end
        if Vars.Weapon.Spinbot then SetEntityHeading(ped,GetEntityHeading(ped)+10.0) end
        if Vars.Weapon.OneShot then SetPlayerWeaponDamageModifier(PlayerId(),9999.0)
        else SetPlayerWeaponDamageModifier(PlayerId(),1.0) end
        if Vars.Weapon.Crosshair then
            DrawRect(0.5,0.5,0.001,0.002,255,255,255,200)
            DrawRect(0.5,0.5,0.002,0.001,255,255,255,200)
        end
        -- AimBot
        if Vars.Weapon.AimBot.Enabled then
            local myC=GetEntityCoords(ped); local best,bestDist,bRes=nil,Vars.Weapon.AimBot.Distance,{x=1.0,y=1.0}
            local targets={}
            if Vars.Weapon.AimBot.OnlyPlayers then
                for _,pid in ipairs(GetActivePlayers()) do
                    if pid~=PlayerId() then table.insert(targets,GetPlayerPed(pid)) end
                end
            else targets=GetGamePool("CPed") end
            for _,t in ipairs(targets) do
                if DoesEntityExist(t) and t~=ped then
                    local dist=#(myC-GetEntityCoords(t))
                    if dist<bestDist then
                        if not Vars.Weapon.AimBot.InvisibilityCheck or not IsEntityOccluded(t) then
                            local bIdx=GetEntityBoneIndexByName(t,Vars.Weapon.AimBot.Bone)
                            local bC=GetPedBoneCoords(t,bIdx,0,0,0)
                            local onS,sx,sy=GetScreenCoordFromWorldCoord(bC.x,bC.y,bC.z)
                            if onS then
                                local dx=math.abs(sx-0.5); local dy=math.abs(sy-0.5)
                                if dx<Vars.Weapon.AimBot.FOV and dy<Vars.Weapon.AimBot.FOV then
                                    if dx<bRes.x and dy<bRes.y then
                                        bRes={x=dx,y=dy}; best=t; bestDist=dist
                                    end
                                end
                            end
                        end
                    end
                end
            end
            if best and IsPlayerFreeAiming(PlayerId()) then
                local bIdx=GetEntityBoneIndexByName(best,Vars.Weapon.AimBot.Bone)
                local bC=GetPedBoneCoords(best,bIdx,0,0,0)
                local onS,sx,sy=GetScreenCoordFromWorldCoord(bC.x,bC.y,bC.z)
                if onS then SetCursorLocation(sx,sy) end
                if Vars.Weapon.AimBot.DrawFOV then
                    for i=0,360,10 do
                        local r=math.rad(i); local fov=Vars.Weapon.AimBot.FOV
                        DrawRect(0.5+math.cos(r)*fov,0.5+math.sin(r)*fov*(16/9),0.001,0.001,255,255,0,180)
                    end
                end
            end
        end
    end
end)

-- ESP
Citizen.CreateThread(function()
    while not killmenu do
        Citizen.Wait(0)
        if Vars.Misc.ESPBox or Vars.Misc.ESPName or Vars.Misc.ESPLines then
            local myPed=PlayerPedId(); local myC=GetEntityCoords(myPed)
            for _,pid in ipairs(GetActivePlayers()) do
                if pid~=PlayerId() then
                    local t=GetPlayerPed(pid)
                    if DoesEntityExist(t) then
                        local dist=#(myC-GetEntityCoords(t))
                        if dist<Vars.Misc.ESPDistance then
                            local c=GetEntityCoords(t)
                            local onS,sx,sy=GetScreenCoordFromWorldCoord(c.x,c.y,c.z+1.0)
                            if onS then
                                if Vars.Misc.ESPName then
                                    SetTextFont(0); SetTextScale(0.0,0.3)
                                    SetTextColour(255,255,255,255); SetTextOutline()
                                    BeginTextCommandDisplayText("STRING")
                                    AddTextComponentSubstringPlayerName(GetPlayerName(pid).." ["..math.floor(dist).."m]")
                                    EndTextCommandDisplayText(sx,sy-0.02)
                                end
                                if Vars.Misc.ESPLines then DrawLine(0.5,1.0,0.0,sx,sy,0.0,255,0,0,200) end
                                if Vars.Misc.ESPBox then DrawRect(sx,sy,0.015,0.03,255,0,0,80) end
                            end
                        end
                    end
                end
            end
        else Citizen.Wait(100) end
    end
end)

-- Farm: Ghost Vehicle
-- Thread injecté permanent qui maintient l'invisibilité
local ghostThreadStarted = false

local function StartGhostThread()
    if ghostThreadStarted then return end
    ghostThreadStarted = true
    MachoInjectResource2(0, "any", [[
        Citizen.CreateThread(function()
            while true do
                Citizen.Wait(50)
                if _G._ZeyGhostVehNetId and _G._ZeyGhostActive then
                    local veh = NetworkGetEntityFromNetworkId(_G._ZeyGhostVehNetId)
                    if DoesEntityExist(veh) then
                        SetEntityVisible(veh, false, false)
                        SetEntityAlpha(veh, 0, false)
                        SetVehicleDoorsLocked(veh, 0)
                        SetVehicleDoorsLockedForAllPlayers(veh, false)
                        -- Conducteur visible
                        local driver = GetPedInVehicleSeat(veh, -1)
                        if driver and driver ~= 0 then
                            SetEntityVisible(driver, true, false)
                            ResetEntityAlpha(driver)
                        end
                    end
                elseif _G._ZeyGhostVehNetId and not _G._ZeyGhostActive then
                    -- Reset visible
                    local veh = NetworkGetEntityFromNetworkId(_G._ZeyGhostVehNetId)
                    if DoesEntityExist(veh) then
                        SetEntityVisible(veh, true, false)
                        ResetEntityAlpha(veh)
                        local maxSeats = GetVehicleMaxNumberOfPassengers(veh)
                        for i = -1, maxSeats - 1 do
                            local p = GetPedInVehicleSeat(veh, i)
                            if p and p ~= 0 then
                                SetEntityVisible(p, true, false)
                                ResetEntityAlpha(p)
                            end
                        end
                    end
                    _G._ZeyGhostVehNetId = nil
                end
            end
        end)
    ]])
end

Citizen.CreateThread(function()
    while not killmenu do
        Citizen.Wait(100)
        local myPed = PlayerPedId()
        local myVeh = GetVehiclePedIsIn(myPed, false)

        if Vars.Farm.VehicleInvisible then
            -- Démarrer le thread injecté une seule fois
            StartGhostThread()

            if myVeh ~= 0 then
                if myVeh ~= farmGhostVeh then
                    -- Nouveau véhicule : reset l'ancien via le flag
                    if farmGhostVeh then
                        _G._ZeyGhostActive = false
                        Citizen.Wait(150)
                    end
                    farmGhostVeh = myVeh
                end
                -- Passer le netId au thread injecté
                local netId = NetworkGetNetworkIdFromEntity(myVeh)
                if netId and netId ~= 0 then
                    _G._ZeyGhostVehNetId = netId
                    _G._ZeyGhostActive = true
                end
                -- Garder le joueur visible
                SetEntityVisible(myPed, true, false)
                ResetEntityAlpha(myPed)
            else
                -- À pied : désactiver
                _G._ZeyGhostActive = false
                farmGhostVeh = nil
            end
        else
            -- Option off : reset
            _G._ZeyGhostActive = false
            _G._ZeyGhostVehNetId = nil
            farmGhostVeh = nil
            Citizen.Wait(200)
        end

        -- AutoInvisible
        if Vars.Farm.AutoInvisible and not Vars.Farm.VehicleInvisible then
            if myVeh ~= 0 then
                Citizen.Wait(600)
                local vN = GetVehiclePedIsIn(PlayerPedId(), false)
                if vN ~= 0 then
                    Vars.Farm.VehicleInvisible = true
                    farmGhostVeh = vN
                end
            end
        end
    end
    -- Nettoyage si killmenu
    _G._ZeyGhostActive = false
    _G._ZeyGhostVehNetId = nil
end)

Citizen.CreateThread(function()
    while not killmenu do
        Citizen.Wait(0)
        if not Vars.Farm.CollisionVehicule then
            local myPed=PlayerPedId(); local myVeh=GetVehiclePedIsIn(myPed,false)
            if myVeh~=0 then
                for _,o in ipairs(GetGamePool("CVehicle")) do
                    if o~=myVeh then SetEntityNoCollisionEntity(myVeh,o,true); SetEntityNoCollisionEntity(o,myVeh,false) end
                end
                for _,o in ipairs(GetGamePool("CPed")) do
                    if o~=myPed then SetEntityNoCollisionEntity(myVeh,o,true) end
                end
                for _,o in ipairs(GetGamePool("CObject")) do SetEntityNoCollisionEntity(myVeh,o,true) end
            end
        else Citizen.Wait(100) end
    end
end)

Citizen.CreateThread(function()
    while not killmenu do
        Citizen.Wait(500)
        if Vars.Farm.SoloSession then
            for _,pid in ipairs(GetActivePlayers()) do
                if pid~=PlayerId() then
                    local t=GetPlayerPed(pid)
                    if DoesEntityExist(t) then
                        SetEntityVisible(t,Vars.Farm.VoirJoueur,false)
                        local v=GetVehiclePedIsIn(t,false)
                        if v~=0 then SetEntityVisible(v,Vars.Farm.VoirJoueur,false) end
                    end
                end
            end
        end
    end
end)

-- Farm: F Descendre Joueur
Citizen.CreateThread(function()
    while not killmenu do
        Citizen.Wait(0)
        if Vars.Farm.FDescendreJoueur then
            local myPed=PlayerPedId(); local myVeh=GetVehiclePedIsIn(myPed,false)
            if myVeh~=0 then
                DisableControlAction(0,23,true)
                if IsDisabledControlJustPressed(0,23) then
                    for _,pid in ipairs(GetActivePlayers()) do
                        if pid~=PlayerId() then
                            local tp=GetPlayerPed(pid)
                            if GetVehiclePedIsIn(tp,false)==myVeh then
                                local nId=NetworkGetNetworkIdFromEntity(tp)
                                if nId and nId~=0 then SetNetworkIdCanMigrate(nId,true); NetworkRequestControlOfEntity(tp) end
                                Citizen.Wait(100)
                                if NetworkHasControlOfEntity(tp) then
                                    ClearPedTasksImmediately(tp); TaskLeaveVehicle(tp,myVeh,0)
                                else
                                    if NetworkHasControlOfEntity(myVeh) then
                                        SetVehicleUndriveable(myVeh,true); Citizen.Wait(600); SetVehicleUndriveable(myVeh,false)
                                    end
                                end
                            end
                        end
                    end
                end
            end
        else Citizen.Wait(100) end
    end
end)

-- Carjack Auto
Citizen.CreateThread(function()
    while not killmenu do
        Citizen.Wait(0)
        if Vars.Farm.Carjack and not carjackCooldown then
            local myPed=PlayerPedId()
            if not IsPedInAnyVehicle(myPed,false) then
                local myC=GetEntityCoords(myPed); local cV,cD,cDr=nil,4.0,nil
                for _,veh in ipairs(GetGamePool("CVehicle")) do
                    if DoesEntityExist(veh) then
                        local dr=GetPedInVehicleSeat(veh,-1)
                        if dr~=0 and DoesEntityExist(dr) and dr~=myPed and not IsPedAPlayer(dr) then
                            local d=#(myC-GetEntityCoords(veh))
                            if d<cD then cD=d; cV=veh; cDr=dr end
                        end
                    end
                end
                if cV and cDr then
                    carjackCooldown=true
                    SetVehicleDoorsLocked(cV,1); SetVehicleDoorOpen(cV,0,false,false)
                    TaskLeaveVehicle(cDr,cV,0)
                    local t=0
                    while GetVehiclePedIsIn(cDr,false)==cV and t<60 do
                        Citizen.Wait(50); t=t+1; TaskTurnPedToFaceEntity(myPed,cV,500)
                    end
                    TaskEnterVehicle(myPed,cV,10000,-1,2.0,1,0)
                    local mt=0
                    while not IsPedInAnyVehicle(myPed,false) and mt<100 do Citizen.Wait(100); mt=mt+1 end
                    Citizen.Wait(3000); carjackCooldown=false
                end
            else Citizen.Wait(100) end
        else Citizen.Wait(100) end
    end
end)

-- Carjack Distance E + Kick Vehicule E
local function ExecCJD(playersOnly)
    local myPed=PlayerPedId(); local myC=GetEntityCoords(myPed)
    local cV,cD,cDr=nil,math.huge,nil
    for _,veh in ipairs(GetGamePool("CVehicle")) do
        if DoesEntityExist(veh) then
            local dr=GetPedInVehicleSeat(veh,-1)
            if dr~=0 and DoesEntityExist(dr) and dr~=myPed then
                local isP=IsPedAPlayer(dr)
                if (not playersOnly) or isP then
                    local d=#(myC-GetEntityCoords(veh))
                    if d<cD then cD=d; cV=veh; cDr=dr end
                end
            end
        end
    end
    if cV then
        Citizen.CreateThread(function()
            local rC=GetEntityCoords(myPed); local rH=GetEntityHeading(myPed)
            SetPedIntoVehicle(myPed,cV,-1)
            local vC=GetEntityCoords(cV)
            TaskLeaveVehicle(cDr,cV,262144)
            SetEntityCoords(cDr,vC.x+3,vC.y,vC.z,false,false,false,false)
            for w=0,7 do SetVehicleTyreBurst(cV,w,true,1000.0) end
            BreakOffVehicleWheel(cV,0,false,false,true,false); BreakOffVehicleWheel(cV,1,false,false,true,false)
            BreakOffVehicleWheel(cV,2,false,false,true,false); BreakOffVehicleWheel(cV,3,false,false,true,false)
            Citizen.Wait(400)
            SetEntityCoords(myPed,rC.x,rC.y,rC.z,false,false,false,false); SetEntityHeading(myPed,rH)
            if IsPedInAnyVehicle(myPed,false) then TaskLeaveVehicle(myPed,GetVehiclePedIsIn(myPed,false),262144) end
        end)
    else MachoMenuNotification("Carjack","Aucun vehicule trouve") end
end

local function ExecKickVehicule()
    local myPed=PlayerPedId(); local myC=GetEntityCoords(myPed)
    local bestPid,bestVeh,bestDist=nil,nil,5000.0
    for _,pid in ipairs(GetActivePlayers()) do
        if pid~=PlayerId() then
            local tp=GetPlayerPed(pid)
            if DoesEntityExist(tp) then
                local tv=GetVehiclePedIsIn(tp,false)
                if tv~=0 then
                    local d=#(myC-GetEntityCoords(tv))
                    if d<bestDist then bestDist=d; bestPid=pid; bestVeh=tv end
                end
            end
        end
    end
    if bestVeh and bestPid then
        MachoMenuNotification("Kick Veh","Cible: "..GetPlayerName(bestPid))
        Citizen.CreateThread(function()
            local rC=GetEntityCoords(myPed); local rH=GetEntityHeading(myPed)
            local rV=GetVehiclePedIsIn(myPed,false)
            SetPedIntoVehicle(myPed,bestVeh,-1)
            local tNetId=NetworkGetNetworkIdFromEntity(GetPlayerPed(bestPid))
            local vNetId=NetworkGetNetworkIdFromEntity(bestVeh)
            MachoInjectResource2(3,"any",string.format([[
                local tp=NetworkGetEntityFromNetworkId(%d)
                local tv=NetworkGetEntityFromNetworkId(%d)
                if DoesEntityExist(tp) and DoesEntityExist(tv) then
                    SetNetworkIdCanMigrate(%d,true)
                    NetworkRequestControlOfEntity(tp)
                    Citizen.Wait(150)
                    if NetworkHasControlOfEntity(tp) then
                        ClearPedTasksImmediately(tp)
                        TaskLeaveVehicle(tp,tv,262144)
                        local vc=GetEntityCoords(tv)
                        SetEntityCoords(tp,vc.x+3,vc.y,vc.z,false,false,false,false)
                    end
                end
            ]],tNetId,vNetId,tNetId))
            Citizen.Wait(300)
            if IsPedInAnyVehicle(myPed,false) then TaskLeaveVehicle(myPed,bestVeh,262144); Citizen.Wait(100) end
            SetEntityCoords(myPed,rC.x,rC.y,rC.z,false,false,false,false)
            SetEntityHeading(myPed,rH)
            if rV~=0 and DoesEntityExist(rV) then SetPedIntoVehicle(myPed,rV,-1) end
            MachoMenuNotification("Kick Veh","Retour position")
        end)
    else MachoMenuNotification("Kick Veh","Aucun joueur en vehicule dans 5000m") end
end

Citizen.CreateThread(function()
    while not killmenu do
        Citizen.Wait(0)
        if Vars.Farm.CarjackDist then
            BeginTextCommandDisplayHelp("STRING")
            AddTextComponentSubstringPlayerName("~INPUT_JUMP~ Carjack Distance (PNJ+Joueurs)")
            EndTextCommandDisplayHelp(0,false,false,-1)
            if IsControlJustPressed(0,38) then ExecCJD(false) end
        elseif Vars.Farm.CarjackDistV2 then
            BeginTextCommandDisplayHelp("STRING")
            AddTextComponentSubstringPlayerName("~INPUT_JUMP~ Carjack Distance V2 (Joueurs)")
            EndTextCommandDisplayHelp(0,false,false,-1)
            if IsControlJustPressed(0,38) then ExecCJD(true) end
        elseif Vars.Farm.KickVehicule then
            BeginTextCommandDisplayHelp("STRING")
            AddTextComponentSubstringPlayerName("~INPUT_JUMP~ Kick Vehicule")
            EndTextCommandDisplayHelp(0,false,false,-1)
            if IsControlJustPressed(0,38) then ExecKickVehicule() end
        else Citizen.Wait(100) end
    end
end)

-- TP Ocean V2 [W]
Citizen.CreateThread(function()
    local cooldown=false
    while not killmenu do
        Citizen.Wait(0)
        if Vars.Teleport.OceanV2 and not cooldown then
            BeginTextCommandDisplayHelp("STRING")
            AddTextComponentSubstringPlayerName("~INPUT_MOVE_UP_ONLY~ TP Ocean V2")
            EndTextCommandDisplayHelp(0,false,false,-1)
            if IsControlJustPressed(0,32) then
                cooldown=true
                local myPed=PlayerPedId(); local myC=GetEntityCoords(myPed)
                local bestPid,bestVeh,bestDist=nil,nil,5000.0
                for _,pid in ipairs(GetActivePlayers()) do
                    if pid~=PlayerId() then
                        local tp=GetPlayerPed(pid)
                        if DoesEntityExist(tp) then
                            local tv=GetVehiclePedIsIn(tp,false)
                            if tv~=0 then
                                local d=#(myC-GetEntityCoords(tv))
                                if d<bestDist then bestDist=d; bestPid=pid; bestVeh=tv end
                            end
                        end
                    end
                end
                if bestVeh and bestPid then
                    MachoMenuNotification("TP Ocean V2","Cible: "..GetPlayerName(bestPid))
                    Citizen.CreateThread(function()
                        SetPedIntoVehicle(myPed,bestVeh,-1)
                        local tNId=NetworkGetNetworkIdFromEntity(GetPlayerPed(bestPid))
                        local vNId=NetworkGetNetworkIdFromEntity(bestVeh)
                        MachoInjectResource2(3,"any",string.format([[
                            local tp=NetworkGetEntityFromNetworkId(%d)
                            local tv=NetworkGetEntityFromNetworkId(%d)
                            if DoesEntityExist(tp) and DoesEntityExist(tv) then
                                SetNetworkIdCanMigrate(%d,true)
                                NetworkRequestControlOfEntity(tp)
                                Citizen.Wait(150)
                                if NetworkHasControlOfEntity(tp) then
                                    ClearPedTasksImmediately(tp)
                                    TaskLeaveVehicle(tp,tv,262144)
                                    local vc=GetEntityCoords(tv)
                                    SetEntityCoords(tp,vc.x+3,vc.y,vc.z,false,false,false,false)
                                end
                            end
                        ]],tNId,vNId,tNId))
                        Citizen.Wait(350)
                        local wp={x=-7000.0,y=-7000.0,z=0.0}
                        SetEntityCoords(bestVeh,wp.x,wp.y,wp.z,false,false,false,false)
                        if not IsPedInAnyVehicle(myPed,false) then SetPedIntoVehicle(myPed,bestVeh,-1) end
                        Citizen.Wait(math.random(80,150))
                        TaskLeaveVehicle(myPed,bestVeh,262144)
                        Citizen.Wait(200)
                        local dests=Vars.Teleport.oceanDestinations
                        local idx=math.random(1,#dests)
                        if Vars.Teleport.lastOceanIndex then
                            repeat idx=math.random(1,#dests) until idx~=Vars.Teleport.lastOceanIndex
                        end
                        Vars.Teleport.lastOceanIndex=idx
                        local d=dests[idx]
                        SetEntityCoords(myPed,d.x,d.y,d.z,false,false,false,false)
                        MachoMenuNotification("TP Ocean V2","Arrive a "..d.nom.." — vehicule laisse dans l ocean !")
                        Citizen.Wait(3000); cooldown=false
                    end)
                else
                    MachoMenuNotification("TP Ocean V2","Aucun joueur en vehicule dans 5000m")
                    Citizen.Wait(1000); cooldown=false
                end
            end
        else Citizen.Wait(100) end
    end
end)

-- Player loops
Citizen.CreateThread(function()
    while not killmenu do
        Citizen.Wait(100)
        if Vars.Player.freezeplayer and Vars.Player.playertofreeze then
            FreezeEntityPosition(Vars.Player.playertofreeze,true)
        end
        if Vars.Player.ExplosionLoop and Vars.Player.ExplodingPlayer then
            local c=GetEntityCoords(GetPlayerPed(Vars.Player.ExplodingPlayer))
            AddExplosion(c.x,c.y,c.z,Vars.Player.ExplosionType,10.0,true,false,0.0)
        end
        if Vars.AllPlayers.freezeserver then
            for _,pid in ipairs(GetActivePlayers()) do
                if pid~=PlayerId() then FreezeEntityPosition(GetPlayerPed(pid),true) end
            end
        end
        if Vars.AllPlayers.ExplodisionLoop then
            for _,pid in ipairs(GetActivePlayers()) do
                if pid~=PlayerId() or Vars.AllPlayers.IncludeSelf then
                    local c=GetEntityCoords(GetPlayerPed(pid))
                    AddExplosion(c.x,c.y,c.z,2,100.0,true,false,0.0)
                end
            end
        end
    end
end)

-- Anti-TP sync thread
Citizen.CreateThread(function()
    while not killmenu do
        Citizen.Wait(500)
        _G._ZeyAntiTP = Vars.Farm.AntiTP
    end
end)

-- Script options
AddEventHandler("cmg3_animations:syncTarget",function() if Vars.Script.blocktakehostage then TriggerEvent("cmg3_animations:cl_stop") end end)
AddEventHandler("CarryPeople:syncTarget",function() if Vars.Script.blockbeingcarried then TriggerEvent("CarryPeople:cl_stop") end end)

MachoMenuNotification("ZeyMenu","Macho Edition charge — F11 pour ouvrir")
