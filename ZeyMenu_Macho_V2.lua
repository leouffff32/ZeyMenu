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
        SeedBlocked=false, SafeModeSeed=false, GuardianBypass=false,
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
        CollisionVehicule=true, FDescendreJoueur=false, FDescendreJoueurV2=false,
        AntiTP=false, KickVehicule=false, EjectTP=false, PedSpam=false, FakeDeath=false, TPVehicle=false,
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
-- On sauvegarde la position et on la force en retour = zero freeze
MachoHookNative(0x06843DA7060A026B, function(entity, x, y, z)
    if Vars.Farm.AntiTP and entity == PlayerPedId() then
        local c = GetEntityCoords(entity)
        if #(c - vector3(x,y,z)) > 5.0 then
            -- Retourner immediatement sans laisser le moteur traiter
            -- On ne fait PAS de notification ici pour eviter tout lag
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

-- [ANTI-TP] START_ENTITY_FIRE — bloquer combustion forcee
MachoHookNative(0xF6A9D9708F6F23DF, function(entity)
    if Vars.Farm.AntiTP and entity == PlayerPedId() then
        return false
    end
    return true
end)

-- [ANTI-TP] APPLY_FORCE_TO_ENTITY — bloquer fling force
MachoHookNative(0xC5F68BE9613E2D18, function(entity)
    if Vars.Farm.AntiTP and entity == PlayerPedId() then
        return false
    end
    return true
end)

-- [ANTI-TP] SET_ENTITY_VELOCITY — bloquer fling via velocity
MachoHookNative(0x1C99BB7B6E96D16F, function(entity, x, y, z)
    if Vars.Farm.AntiTP and entity == PlayerPedId() then
        local vz = z or 0
        -- Bloquer seulement les velocities extremes (fling)
        if vz > 30.0 or math.abs(x or 0) > 50.0 or math.abs(y or 0) > 50.0 then
            return false
        end
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
MC("new","F Descendre Joueur V2",Vars.Farm,"FDescendreJoueurV2",
    function() Vars.Farm.FDescendreJoueurV2=true end,
    function() Vars.Farm.FDescendreJoueurV2=false end)
MC("new","Anti-TP",Vars.Farm,"AntiTP",
    function() Vars.Farm.AntiTP=true; _G._ZeyAntiTP=true
        MachoMenuNotification("Anti-TP","Actif") end,
    function() Vars.Farm.AntiTP=false; _G._ZeyAntiTP=false
        MachoMenuNotification("Anti-TP","Desactive") end)
MC("new","Kick Vehicule [E]",Vars.Farm,"KickVehicule",
    function() Vars.Farm.KickVehicule=true
        MachoMenuNotification("Kick Veh","E pour prendre le vehicule du joueur") end,
    function() Vars.Farm.KickVehicule=false end)
MC("new","Enleve Roue [E]",Vars.Farm,"EjectTP",
    function() Vars.Farm.EjectTP=true
        MachoMenuNotification("Enleve Roue","E pour faire tomber les roues du vehicule") end,
    function() Vars.Farm.EjectTP=false end)
MC("new","Ped Spam Crash [E]",Vars.Farm,"PedSpam",
    function()
        Vars.Farm.PedSpam=true
        MachoMenuNotification("Ped Spam","E pour crash le joueur le plus proche")
    end,
    function()
        Vars.Farm.PedSpam=false
        if _G._ZeySpawnedPeds then
            for _,p in ipairs(_G._ZeySpawnedPeds) do
                if DoesEntityExist(p) then DeleteEntity(p) end
            end
            _G._ZeySpawnedPeds={}
        end
        MachoMenuNotification("Ped Spam","Desactive")
    end)
MC("new","Fake Death","Vars.Farm","FakeDeath",
    function()
        Vars.Farm.FakeDeath = true
        MachoMenuNotification("Fake Death","Actif — serveur croit que tu es mort")
    end,
    function()
        Vars.Farm.FakeDeath = false
        MachoMenuNotification("Fake Death","Desactive — serveur te voit vivant")
    end)
MC("new","TP Dans Vehicule [E]",Vars.Farm,"TPVehicle",
    function()
        Vars.Farm.TPVehicle = true
        MachoMenuNotification("TP Vehicule","Actif — E pour entrer dans le vehicule le plus proche")
    end,
    function()
        Vars.Farm.TPVehicle = false
        MachoMenuNotification("TP Vehicule","Desactive")
    end)

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
    noclipping = not noclipping
    MachoMenuNotification("Noclip", noclipping and "Active" or "Desactive")
    if noclipping then
        Citizen.CreateThread(function()
            local ped   = PlayerPedId()
            local speed = 0.08  -- vitesse de base beaucoup plus basse

            -- Pas d invisibilite — on reste visible
            SetEntityCollision(ped, false, false)
            FreezeEntityPosition(ped, true)

            while noclipping do
                Citizen.Wait(0)
                ped = PlayerPedId()

                -- Bloquer tous les controles du joueur sauf ceux qu on gere
                DisableAllControlActions(0)
                -- Garder ESC et les touches menu
                EnableControlAction(0, 199, true) -- ESC
                EnableControlAction(0, 200, true) -- Return
                EnableControlAction(0, 249, true) -- Push to talk

                -- Lire la direction de la camera (pas du perso)
                -- GetGameplayCamRot retourne pitch/roll/yaw en degres
                local camRot = GetGameplayCamRot(2)
                local camFwd = GetGameplayCamForwardVector()

                -- Vecteur avant: direction ou regarde la cam (ignore le pitch pour ZQSD)
                -- On projette sur le plan horizontal pour Z/S
                local fwdH = vector3(camFwd.x, camFwd.y, 0.0)
                local fwdHLen = math.sqrt(fwdH.x*fwdH.x + fwdH.y*fwdH.y)
                if fwdHLen > 0.001 then
                    fwdH = vector3(fwdH.x/fwdHLen, fwdH.y/fwdHLen, 0.0)
                end

                -- Vecteur droite: perpendiculaire au vecteur avant
                local right = vector3(fwdH.y, -fwdH.x, 0.0)

                -- Vecteur haut: toujours Z pur
                local up = vector3(0.0, 0.0, 1.0)

                -- Molette = ajuster la vitesse de base
                -- Scroll up = plus vite, Scroll down = plus lent
                if IsDisabledControlJustPressed(0, 15) then  -- molette haut
                    speed = math.min(speed * 1.35, 5.0)
                end
                if IsDisabledControlJustPressed(0, 14) then  -- molette bas
                    speed = math.max(speed / 1.35, 0.01)
                end

                -- Vitesse adaptative: Shift = rapide, Ctrl = lent
                local curSpeed = speed
                if IsDisabledControlPressed(0, 21) then  -- Shift
                    curSpeed = speed * 4.0
                elseif IsDisabledControlPressed(0, 36) then  -- Ctrl
                    curSpeed = speed * 0.25
                end

                -- Calculer le mouvement depuis les touches ZQSD
                local move = vector3(0.0, 0.0, 0.0)

                -- Z = avant (dans la direction de la cam, axe horizontal)
                if IsDisabledControlPressed(0, 32) then  -- W/Z
                    move = vector3(move.x + fwdH.x, move.y + fwdH.y, move.z)
                end
                -- S = arriere
                if IsDisabledControlPressed(0, 33) then  -- S
                    move = vector3(move.x - fwdH.x, move.y - fwdH.y, move.z)
                end
                -- Q = gauche
                if IsDisabledControlPressed(0, 34) then  -- A/Q
                    move = vector3(move.x - right.x, move.y - right.y, move.z)
                end
                -- D = droite
                if IsDisabledControlPressed(0, 35) then  -- D
                    move = vector3(move.x + right.x, move.y + right.y, move.z)
                end
                -- Espace = monter
                if IsDisabledControlPressed(0, 22) then  -- Space
                    move = vector3(move.x, move.y, move.z + 1.0)
                end
                -- Ctrl = descendre (double usage avec slow)
                if IsDisabledControlPressed(0, 36) and not IsDisabledControlPressed(0, 21) then
                    move = vector3(move.x, move.y, move.z - 1.0)
                end

                -- Si on appuie sur avant/arriere ET qu on regarde vers le haut/bas
                -- inclure la composante verticale de la cam (regarder en l air = monter)
                if IsDisabledControlPressed(0, 32) then
                    move = vector3(move.x, move.y, move.z + camFwd.z)
                end
                if IsDisabledControlPressed(0, 33) then
                    move = vector3(move.x, move.y, move.z - camFwd.z)
                end

                -- Normaliser si deplacement diagonal
                local moveLen = math.sqrt(move.x*move.x + move.y*move.y + move.z*move.z)
                if moveLen > 0.001 then
                    move = vector3(
                        (move.x/moveLen) * curSpeed,
                        (move.y/moveLen) * curSpeed,
                        (move.z/moveLen) * curSpeed
                    )
                end

                -- Afficher la vitesse actuelle en bas de l ecran
                SetTextFont(0)
                SetTextScale(0.3, 0.3)
                SetTextColour(255, 255, 255, 180)
                BeginTextCommandDisplayText("STRING")
                AddTextComponentSubstringPlayerName(
                    string.format("Noclip  vitesse: %.2f  [molette +/-]  [Shift x4]  [Ctrl x0.25]", speed)
                )
                EndTextCommandDisplayText(0.5, 0.96)

                -- Appliquer la position
                local pos = GetEntityCoords(ped)
                local newPos = vector3(pos.x + move.x, pos.y + move.y, pos.z + move.z)

                SetEntityCoords(ped, newPos.x, newPos.y, newPos.z,
                    false, false, false, false)

                -- Le perso ne bouge pas visuellement — heading fixe
                -- (pas de SetEntityHeading = il garde son orientation d origine)

            end

            -- Restaurer quand on desactive
            ped = PlayerPedId()
            SetEntityCollision(ped, true, false)
            FreezeEntityPosition(ped, false)
        end)
    end
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
MS("weapon","Give Armes Inventaire","Persiste au respawn via inventory","giveweapinv")
MB("weapon","Get All Weapons (Natif)","Instantane mais disparait au respawn", function()
    for _,w in ipairs({
        "WEAPON_PISTOL","WEAPON_COMBATPISTOL","WEAPON_APPISTOL",
        "WEAPON_MICROSMG","WEAPON_SMG","WEAPON_ASSAULTSMG",
        "WEAPON_ASSAULTRIFLE","WEAPON_CARBINERIFLE","WEAPON_ADVANCEDRIFLE","WEAPON_SPECIALCARBINE",
        "WEAPON_MG","WEAPON_COMBATMG",
        "WEAPON_HEAVYSNIPER","WEAPON_SNIPERRIFLE","WEAPON_MARKSMANRIFLE",
        "WEAPON_PUMPSHOTGUN","WEAPON_SAWNOFFSHOTGUN","WEAPON_ASSAULTSHOTGUN","WEAPON_HEAVYSHOTGUN",
        "WEAPON_RPG","WEAPON_HOMINGLAUNCHER","WEAPON_MINIGUN",
        "WEAPON_GRENADE","WEAPON_STICKYBOMB",
        "WEAPON_KNIFE","WEAPON_BAT","WEAPON_CROWBAR",
        "WEAPON_RAYPISTOL","WEAPON_RAYCARBINE","WEAPON_RAYMINIGUN",
    }) do
        GiveWeaponToPed(PlayerPedId(),GetHashKey(w),9999,false,false)
    end
    MachoMenuNotification("Armes Natives","Donnees (disparaissent au respawn)")
end)
MB("weapon","Remove All Weapons","", function() RemoveAllPedWeapons(PlayerPedId(),true) end)
MB("weapon","Refill All Ammo","", function()
    for _,w in ipairs({"WEAPON_PISTOL","WEAPON_SMG","WEAPON_ASSAULTRIFLE","WEAPON_MG","WEAPON_HEAVYSNIPER","WEAPON_RPG"}) do
        SetPedAmmo(PlayerPedId(),GetHashKey(w),9999)
    end
end)

-- Give Armes via inventaire SEED
-- Resource confirmee: "inventory" (fxmanifest _module("inventory"))
-- Apres analyse de weapons_gta5.lua:
-- Le flux reel: item "use" -> serveur -> m:EmitNet('weapons:equip') -> client equipe
-- On ne peut PAS se give des items depuis le client sans acces serveur
-- La VRAIE methode: intercepter l event weapons:equip que le serveur envoie
-- et forcer l equipement via MachoHookNative sur les natives d armes

CreateMenu("giveweapinv","Equiper Armes","weapon")

-- Methode 1: Intercepter weapons:equip via injection dans items resource
-- Si l arme est dans l inventaire, simuler que le serveur envoie weapons:equip
-- via MachoInjectResource2 dans "items" qui ecoute cet event
local weaponItems = {
    {"Pistolet",        "weapon_pistol"},
    {"Combat Pistol",   "weapon_combatpistol"},
    {"AP Pistol",       "weapon_appistol"},
    {"Micro SMG",       "weapon_microsmg"},
    {"SMG",             "weapon_smg"},
    {"Assault SMG",     "weapon_assaultsmg"},
    {"Assault Rifle",   "weapon_assaultrifle"},
    {"Carbine Rifle",   "weapon_carbinerifle"},
    {"Special Carbine", "weapon_specialcarbine"},
    {"MG",              "weapon_mg"},
    {"Combat MG",       "weapon_combatmg"},
    {"Heavy Sniper",    "weapon_heavysniper"},
    {"Sniper Rifle",    "weapon_sniperrifle"},
    {"Pump Shotgun",    "weapon_pumpshotgun"},
    {"Heavy Shotgun",   "weapon_heavyshotgun"},
    {"RPG",             "weapon_rpg"},
    {"Homing Launcher", "weapon_hominglauncher"},
    {"Minigun",         "weapon_minigun"},
    {"Couteau",         "weapon_knife"},
    {"Batte",           "weapon_bat"},
}

local function EquipWeaponForced(itemName, label)
    -- Methode principale: injecter dans "items" et declencher weapons:equip
    -- C est exactement ce que fait le serveur quand il repond a une action "use"
    -- On simule ce TriggerEvent depuis le contexte de la resource items
    MachoInjectResource2(3, "items", string.format([[
        -- Simuler la reception de weapons:equip comme si le serveur l avait envoye
        -- m:OnNet('weapons:equip', ...) dans weapons_gta5.lua est un AddEventHandler
        -- sur "items:weapons:equip" (format SEED: module:event)
        local weaponName = "%s"
        local weaponUniqueId = weaponName..".1"
        -- Declencher l event local comme si le serveur l avait emis
        TriggerEvent("items:weapons:equip", weaponName, weaponUniqueId)
    ]], itemName))

    -- Methode 2: via inventory, declencher l action "use" sur l item
    -- si l item existe dans l inventaire du joueur
    MachoInjectResource2(3, "inventory", string.format([[
        local invMod = Modules.Get('inventory')
        if invMod then
            local inventory = CPlayer.GetCharacterInventory()
            if inventory then
                local invItemIdx, invItem = invMod.GetInventoryItem("%s")
                if invItemIdx ~= -1 and invItem then
                    local itemUid = "%s.1"
                    invMod.RunInventoryItemAction(inventory, invItem, itemUid, "use")
                end
            end
        end
    ]], itemName, itemName))

    -- Methode 3: natif direct — toujours fonctionnel meme si les 2 autres echouent
    local h = GetHashKey(string.upper(itemName))
    if IsWeaponValid(h) then
        local ped = PlayerPedId()
        RequestWeaponAsset(h, 31, 0)
        local t = 0
        while not HasWeaponAssetLoaded(h) and t < 50 do
            Citizen.Wait(10); t=t+1
        end
        GiveWeaponToPed(ped, h, 250, false, true)
        SetCurrentPedWeapon(ped, h, true)
    end

    MachoMenuNotification("Equiper", label)
end

for _,wdata in ipairs(weaponItems) do
    local label,itemName = wdata[1],wdata[2]
    MB("giveweapinv", label, "Equiper l arme", function()
        EquipWeaponForced(itemName, label)
    end)
end

MB("giveweapinv","Toutes les armes (Natif)","Instantane, sans inventaire", function()
    local ped = PlayerPedId()
    for _,w in ipairs({
        "WEAPON_PISTOL","WEAPON_COMBATPISTOL","WEAPON_APPISTOL",
        "WEAPON_MICROSMG","WEAPON_SMG","WEAPON_ASSAULTSMG",
        "WEAPON_ASSAULTRIFLE","WEAPON_CARBINERIFLE","WEAPON_SPECIALCARBINE",
        "WEAPON_MG","WEAPON_COMBATMG","WEAPON_HEAVYSNIPER","WEAPON_SNIPERRIFLE",
        "WEAPON_PUMPSHOTGUN","WEAPON_HEAVYSHOTGUN","WEAPON_RPG",
        "WEAPON_HOMINGLAUNCHER","WEAPON_MINIGUN","WEAPON_KNIFE","WEAPON_BAT"
    }) do
        GiveWeaponToPed(ped, GetHashKey(w), 250, false, true)
    end
    MachoMenuNotification("Armes","Toutes equipees (natif)")
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

-- ── GUARDIAN/SEED FULL BYPASS ──────────────────────────────
-- Analyse du code source:
-- events.lua  → TriggerServerEvent('blev', eventName, ...) = reporter nos actions
-- pickups.lua → SuppressPickupRewardType + ToggleUsePickupsForPlayer
-- main.lua    → SEED.GetWeaponFromHash, TranslateDeathCause, BlockedWeapons
-- config.lua  → listes vehicules/peds/armes bloques
-- ────────────────────────────────────────────────────────────

MC("anticheat","Guardian Full Bypass",Vars.AntiCheat,"GuardianBypass",
    function()
        Vars.AntiCheat.GuardianBypass = true
        MachoSetLoggerState(0)

        -- Trouver la resource Guardian/Seed
        local guardianRes = nil
        for _,res in ipairs(GetResources()) do
            local rL = string.lower(res)
            if string.find(rL,"seed") or string.find(rL,"guardian") then
                guardianRes = res; break
            end
        end

        -- ═══ COUCHE 1: Neutraliser le systeme de report 'blev' ═══
        -- events.lua envoie tout via TriggerServerEvent('blev', eventName, ...)
        -- On hook TriggerServerEvent pour bloquer 'blev' silencieusement
        MachoInjectResource2(3,"any",[[
            local _oTSE = TriggerServerEvent
            TriggerServerEvent = function(name, ...)
                -- Bloquer le reporter principal de Guardian
                if name == "blev" then return end
                -- Bloquer tous les events Guardian/Seed
                if name and (string.find(string.lower(tostring(name)),"seed") or
                             string.find(string.lower(tostring(name)),"guardian") or
                             string.find(string.lower(tostring(name)),"guardian")) then return end
                return _oTSE(name, ...)
            end
        ]])

        -- ═══ COUCHE 2: Neutraliser le systeme d events blacklistes ═══
        -- events.lua fait addClientBlacklistedEvent pour chaque event sensible
        -- On hook RegisterNetEvent et AddEventHandler pour les intercepter
        MachoInjectResource2(3,"any",[[
            -- Bloquer la fonction addClientBlacklistedEvent elle-meme
            -- en hookant RegisterNetEvent pour les events blacklistes connus
            local blacklistedEvents = {
                "UnJP", "esx-qalle-jail:openJailMenu", "ambulancier:selfRespawn",
                "sendProximityMessage", "sendProximityMessageMe",
                "sendProximityMessageDo"
            }
            local _oRNE = RegisterNetEvent
            RegisterNetEvent = function(name, ...)
                -- Laisser passer normalement mais on wrape le handler
                return _oRNE(name, ...)
            end
            -- Hook AddEventHandler pour intercepter les callbacks Guardian
            -- qui reportent nos actions via 'blev'
            local _oAEH = AddEventHandler
            AddEventHandler = function(name, cb)
                if name then
                    -- Bloquer les handlers .verify .getEvents .getServerEvents
                    -- que Guardian enregistre pour chaque resource (events.lua L31-38)
                    if string.find(tostring(name), "%.verify$") or
                       string.find(tostring(name), "%.getEvents$") or
                       string.find(tostring(name), "%.getServerEvents$") then
                        -- Wrapper: ne pas reporter au serveur
                        return _oAEH(name, function(...) end)
                    end
                end
                return _oAEH(name, cb)
            end
        ]])

        -- ═══ COUCHE 3: Bypass pickup suppression ═══
        -- pickups.lua desactive TOUS nos pickups via ToggleUsePickupsForPlayer
        -- On re-active tout apres que Guardian les ait desactives
        MachoInjectResource2(3,"any",[[
            local pid = PlayerId()
            -- Re-activer la collecte de pickups portable
            SetLocalPlayerCanCollectPortablePickups(true)
            -- Annuler la suppression des rewards
            -- SuppressPickupRewardType(ALL, false)
            Citizen.InvokeNative(0xF92099527DB8E2A7, (1 << 11) - 1, false)
            -- Thread qui maintient les pickups actifs
            Citizen.CreateThread(function()
                while true do
                    Citizen.Wait(2000)
                    SetLocalPlayerCanCollectPortablePickups(true)
                    Citizen.InvokeNative(0xF92099527DB8E2A7, (1 << 11) - 1, false)
                end
            end)
        ]])

        -- ═══ COUCHE 4: Bypass BlockedWeapons ═══
        -- config.lua bloque RPG, Minigun, Ray weapons, grenades etc
        -- On injecte dans Guardian pour vider sa liste BlockedWeapons
        if guardianRes and MachoResourceInjectable(guardianRes) then
            MachoInjectResource2(3, guardianRes, [[
                -- Vider la liste des armes bloquees (config.lua CFG.BlockedWeapons)
                if _G.CFG and _G.CFG.BlockedWeapons then
                    _G.CFG.BlockedWeapons = {}
                end
                -- Vider les vehicules bloques
                if _G.CFG and _G.CFG.BlockedPopulationVehicles then
                    _G.CFG.BlockedPopulationVehicles = {}
                end
                -- Vider les peds bloques
                if _G.CFG and _G.CFG.BlockedPopulationPeds then
                    _G.CFG.BlockedPopulationPeds = {}
                end
                -- Neutraliser le systeme de detection des armes
                -- main.lua utilise SEED.GetWeaponFromHash pour identifier nos armes
                if _G.SEED then
                    _G.SEED.GetWeaponFromHash = function(hash) return nil end
                end
                -- Corrompre TranslateDeathCause pour masquer la vraie cause de mort
                if _G.m and _G.m.TranslateDeathCause then
                    _G.m.TranslateDeathCause = function(hash) return "inconnu" end
                end
                -- Vider les armes autorisees pour les takedowns
                -- (evite detection si on fait un takedown avec arme non listee)
                if _G.m and _G.m.ALLOWED_TAKEDOWN_WEAPONS then
                    -- Ajouter toutes les armes comme autorisees
                    setmetatable(_G.m.ALLOWED_TAKEDOWN_WEAPONS, {
                        __index = function(t, k) return true end
                    })
                end
            ]])
        end

        -- ═══ COUCHE 5: Neutraliser le logger Guardian ═══
        -- Supprimer tous ses event handlers
        if guardianRes then
            for i=1,10 do
                TriggerEvent("__cfx_internal:removeAllEventHandlers", guardianRes)
            end
        end

        -- ═══ COUCHE 6: Hook natif populationPedCreating ═══
        -- events.lua annule la creation de certains peds via CancelEvent
        -- On injecte un handler prioritaire qui contrecarre le CancelEvent
        MachoInjectResource2(3,"any",[[
            AddEventHandler("populationPedCreating", function(x, y, z, model, setters)
                -- Rien — on laisse tous les peds spawner
                -- Ce handler s execute apres Guardian et ecrase son CancelEvent
            end)
        ]])

        MachoSetLoggerState(1)
        MachoMenuNotification("Guardian Bypass","Full bypass actif — 6 couches")
    end,
    function()
        Vars.AntiCheat.GuardianBypass = false
        MachoMenuNotification("Guardian Bypass","Desactive")
    end)

MB("anticheat","Guardian — Bypass Logs 'blev'","Bloquer les reports d actions", function()
    -- Bloquer specifiquement l event 'blev' qui reporte toutes nos actions
    -- C est le mecanisme central de Guardian (events.lua L4)
    MachoInjectResource2(3,"any",[[
        local _oTSE = TriggerServerEvent
        TriggerServerEvent = function(name, ...)
            if name == "blev" then
                -- Log bloque silencieusement
                return
            end
            return _oTSE(name, ...)
        end
    ]])
    MachoMenuNotification("Bypass Logs","Event 'blev' bloque — Guardian ne peut plus reporter")
end)

MB("anticheat","Guardian — Restore Pickups","Re-activer tous les pickups", function()
    -- Contrer pickups.lua qui desactive tous nos pickups
    SetLocalPlayerCanCollectPortablePickups(true)
    Citizen.InvokeNative(0xF92099527DB8E2A7, (1 << 11) - 1, false)
    local pid = PlayerId()
    MachoInjectResource2(3,"any",string.format([[
        SetLocalPlayerCanCollectPortablePickups(true)
        Citizen.InvokeNative(0xF92099527DB8E2A7, (1 << 11) - 1, false)
    ]]))
    MachoMenuNotification("Pickups","Tous les pickups re-actives")
end)

MB("anticheat","Guardian — Unlock Blocked Weapons","Debloquer RPG/Minigun/Ray etc", function()
    -- Vider CFG.BlockedWeapons dans Guardian
    local guardianRes = nil
    for _,res in ipairs(GetResources()) do
        local rL = string.lower(res)
        if string.find(rL,"seed") or string.find(rL,"guardian") then
            guardianRes = res; break
        end
    end
    if guardianRes and MachoResourceInjectable(guardianRes) then
        MachoInjectResource2(3, guardianRes, [[
            if _G.CFG and _G.CFG.BlockedWeapons then _G.CFG.BlockedWeapons = {} end
            if _G.SEED then _G.SEED.GetWeaponFromHash = function() return nil end end
        ]])
        MachoMenuNotification("Weapons","Armes bloquees debloquees dans Guardian")
    else
        MachoMenuNotification("Weapons","Guardian non injectable — utiliser Full Bypass")
    end
end)

-- Safe Mode Seed (legacy)
MC("anticheat","Safe Mode Seed",Vars.AntiCheat,"SafeModeSeed",
    function()
        Vars.AntiCheat.SafeModeSeed=true
        local sr=nil
        for _,res in ipairs(GetResources()) do
            if string.find(string.lower(res),"seed") or string.find(string.lower(res),"guardian") then
                sr=res; break
            end
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
            if string.find(rL,"seed") or string.find(rL,"guardian") then
                table.insert(found,res)
            else
                local mf=LoadResourceFile(res,"fxmanifest.lua") or LoadResourceFile(res,"__resource.lua") or ""
                if string.find(string.lower(mf),"seed") or string.find(string.lower(mf),"guardian") then
                    table.insert(found,res)
                end
            end
        end
        if #found==0 then
            MachoMenuNotification("Seed","Aucune resource detectee")
            MachoSetLoggerState(1); return
        end
        Vars.AntiCheat.SeedBlocked=true
        for _,sr in ipairs(found) do
            MachoMenuNotification("TARGET",sr)
            if MachoResourceInjectable(sr) then
                MachoInjectResource2(3,sr,[[
                    -- Vider toutes les structures Guardian
                    for _,g in ipairs({"SeedAC","Seed","seedac","SeedCheck","SeedAntiCheat","BanPlayer","KickPlayer","ReportPlayer","SEED"}) do
                        _G[g]=type(_G[g])=="function" and function() end or nil
                    end
                    if _G.CFG then
                        _G.CFG.BlockedWeapons={}
                        _G.CFG.BlockedPopulationVehicles={}
                        _G.CFG.BlockedPopulationPeds={}
                    end
                    if _G.detections then _G.detections={} end
                    if _G.violations then _G.violations={} end
                    -- Bloquer le reporter 'blev'
                    local _oTSE=TriggerServerEvent
                    TriggerServerEvent=function(n,...)
                        if n=="blev" then return end
                        if n and string.find(string.lower(tostring(n)),"seed") then return end
                        return _oTSE(n,...)
                    end
                ]])
            end
            MachoInjectResource2(3,"any",[[
                local _oTSE=TriggerServerEvent
                TriggerServerEvent=function(n,...) if n=="blev" or (n and string.find(string.lower(tostring(n)),"seed")) then return end return _oTSE(n,...) end
                local _oTE=TriggerEvent
                TriggerEvent=function(n,...) if n and string.find(string.lower(tostring(n)),"seed") then return end return _oTE(n,...) end
                local _oAEH=AddEventHandler
                AddEventHandler=function(n,cb)
                    if n and (string.find(string.lower(tostring(n)),"seed") or
                              string.find(tostring(n),"%.verify$") or
                              string.find(tostring(n),"%.getEvents$")) then return end
                    return _oAEH(n,cb)
                end
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
                            if r and (string.find(string.lower(r),"seed") or string.find(string.lower(r),"guardian")) then
                                for j=1,20 do TriggerServerEvent("__cfx_internal:stopResource",r) end
                                TriggerEvent("__cfx_internal:removeAllEventHandlers",r)
                            end
                        end
                    end
                end)
            ]])
        end
        MachoSetLoggerState(1)
        MachoMenuNotification("DETRUIT","Verrou permanent actif")
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

-- HOOKS MACHO — FAKE DEATH
-- Faire croire au serveur et aux anticheat que notre ped est mort
-- tout en restant vivant et invincible cote client

-- [FAKE DEATH / GODMODE] Hook IS_ENTITY_DEAD — hook unique
-- FakeDeath → true pour les scanners serveur/AC
-- Godmode   → false pour les scanners
-- Le moteur de jeu client n est PAS affecte = tu peux mourir normalement
MachoHookNative(0x5F9532F3B5CC2551, function(entity, toggleFedora)
    if entity == PlayerPedId() then
        if Vars.Farm.FakeDeath then
            return false, true   -- serveur croit que tu es mort
        end
        if Vars.Self.godmode then
            return false, false  -- jamais mort si godmode
        end
    end
    return true
end)

-- [FAKE DEATH / GODMODE] Hook GET_ENTITY_HEALTH
-- FakeDeath → 0 pour les scanners serveur
-- Godmode   → 200 pour les scanners
MachoHookNative(0xEEF059FAD016D209, function(entity)
    if entity == PlayerPedId() then
        if Vars.Farm.FakeDeath then return false, 0   end
        if Vars.Self.godmode    then return false, 200 end
    end
    return true
end)

-- [FAKE DEATH] Hook IS_PED_DEAD_OR_DYING — confirmer la mort au serveur
MachoHookNative(0x3317C47A56350321, function(ped, p1)
    if Vars.Farm.FakeDeath and ped == PlayerPedId() then
        return false, true
    end
    return true
end)

-- [FAKE DEATH] Hook GET_PED_CAUSE_OF_DEATH — cause de mort credible
MachoHookNative(0x63F9F6BFC9B4ABDC, function(ped)
    if Vars.Farm.FakeDeath and ped == PlayerPedId() then
        return false, GetHashKey("WEAPON_PISTOL")
    end
    return true
end)

-- [ANTI-TP] Hook NETWORK_RESURRECT_LOCAL_PLAYER
MachoHookNative(0x2959F695A6D1A7E5, function(x, y, z)
    if Vars.Farm.AntiTP then
        local c = GetEntityCoords(PlayerPedId())
        if #(c - vector3(x,y,z)) > 5.0 then
            MachoMenuNotification("Anti-TP","Resurrect bloque")
            return false
        end
    end
    -- Si FakeDeath actif: bloquer le resurrect automatique du serveur
    -- (sinon le serveur nous ressuscite tout de suite apres nous avoir "vu" morts)
    if Vars.Farm.FakeDeath then
        return false
    end
    return true
end)

-- ============================================================
-- HOOKS MACHO SUPPLEMENTAIRES — SELF
-- Bloquer les detections au niveau natif
-- ============================================================

-- IS_ENTITY_DEAD et GET_ENTITY_HEALTH geres dans les hooks Fake Death ci-dessus

-- [WANTED] Hook GET_PLAYER_WANTED_LEVEL — toujours 0 pour les scanners
MachoHookNative(0xE28B54053A4C5A6B, function(player)
    if Vars.Self.FreezeWantedLevel and player == PlayerId() then
        return false, 0
    end
    return true
end)

-- [INVISIBLE] Hook IS_ENTITY_VISIBLE — masquer notre etat aux scanners AC
MachoHookNative(0x47D6F43D77935C75, function(entity)
    if Vars.Self.invisiblitity and entity == PlayerPedId() then
        return false, false  -- on est "normalement invisible" pour l AC
    end
    return true
end)

-- [INVINCIBLE] Hook IS_ENTITY_INVINCIBLE — confirmer notre invincibilite
MachoHookNative(0x1A41EAE8838F8BEB, function(entity)
    if Vars.Self.godmode and entity == PlayerPedId() then
        return false, true
    end
    return true
end)

-- [RAGDOLL] Hook GET_PED_CONFIG_FLAG — bloquer les checks ragdoll AC
-- Flag 28 = CanRagdoll
MachoHookNative(0x7E8A4F5D74E19C2B, function(ped, flagId, p2)
    if Vars.Self.noragdoll and ped == PlayerPedId() and flagId == 28 then
        return false, false  -- dire a l AC que le ragdoll est normal
    end
    return true
end)

-- [STAMINA] Hook GET_PLAYER_SPRINT_STAMINA_REMAINING — toujours plein
MachoHookNative(0x6F68B4B4D5AC4EEB, function(playerIndex)
    if Vars.Self.infstamina and playerIndex == PlayerId() then
        return false, 100.0
    end
    return true
end)

-- ============================================================
-- HOOKS MACHO SUPPLEMENTAIRES — VEHICLE
-- ============================================================

-- [VEH GODMODE] Hook GET_VEHICLE_ENGINE_HEALTH — toujours 1000
MachoHookNative(0xC45D23BAF168AAB8, function(vehicle)
    if Vars.Vehicle.vehgodmode then
        local myVeh = GetVehiclePedIsIn(PlayerPedId(), false)
        if vehicle == myVeh then return false, 1000.0 end
    end
    return true
end)

-- [VEH GODMODE] Hook GET_VEHICLE_BODY_HEALTH — toujours 1000
MachoHookNative(0xF271147EB7B40F12, function(vehicle)
    if Vars.Vehicle.vehgodmode then
        local myVeh = GetVehiclePedIsIn(PlayerPedId(), false)
        if vehicle == myVeh then return false, 1000.0 end
    end
    return true
end)

-- [SPEED HOOK] Hook GET_ENTITY_SPEED masquage deja present

-- [UNLOCK] Hook GET_VEHICLE_DOORS_LOCKED_STATE — toujours unlocked pour nous
MachoHookNative(0x25BC98A59C2EA962, function(vehicle)
    if Vars.Vehicle.FullUnlockVehicle then
        local myPed = PlayerPedId()
        local myC   = GetEntityCoords(myPed)
        if #(myC - GetEntityCoords(vehicle)) < 5.0 then
            return false, 1  -- UNLOCKED
        end
    end
    return true
end)

-- ============================================================
-- HOOKS MACHO SUPPLEMENTAIRES — WEAPON / AIMBOT
-- ============================================================

-- [AIMBOT] Hook GET_GAMEPLAY_CAM_ROT — modifier rotation camera vers cible
-- Hash: 0x837765FE75160D60
MachoHookNative(0x837765FE75160D60, function(rotationOrder)
    if Vars.Weapon.AimBot.Enabled and Vars.Weapon.AimBot.Target then
        local target = Vars.Weapon.AimBot.Target
        if DoesEntityExist(target) then
            local boneIdx = GetEntityBoneIndexByName(target, Vars.Weapon.AimBot.Bone)
            local bC = GetPedBoneCoords(target, boneIdx, 0, 0, 0)
            -- Calculer les angles vers la cible
            local camC = GetGameplayCamCoord()
            local dx = bC.x - camC.x
            local dy = bC.y - camC.y
            local dz = bC.z - camC.z
            local pitch = math.deg(math.atan(dz, math.sqrt(dx*dx + dy*dy)))
            local yaw   = math.deg(math.atan(dx, dy))
            -- Retourner la rotation modifiee
            return false, pitch, 0.0, yaw
        end
    end
    return true
end)

-- [EXPLOSIVE AMMO] Hook IS_BULLET_IN_AREA — masquer les balles explosives
MachoHookNative(0x9C1E8965B977A308, function(x, y, z, radius, unk)
    if Vars.Weapon.ExplosiveAmmo then
        return false, false  -- aucune balle detectee pour l AC
    end
    return true
end)

-- [ONE SHOT] Hook GET_PLAYER_WEAPON_DAMAGE_MODIFIER — masquer le multiplicateur
MachoHookNative(0x4B4B5E7B38CDFCAD, function(playerIndex)
    if Vars.Weapon.OneShot and playerIndex == PlayerId() then
        return false, 1.0  -- retourner valeur normale a l AC
    end
    return true
end)

-- ============================================================
-- INJECTION MACHO — ESP SCREENSHOT-PROOF via DUI
-- Rendu dans fenetre DUI = invisible aux screenshots anticheat
-- ============================================================

local espDui = nil
local espDuiVisible = false

local function InitESPDui()
    if espDui then return end
    -- Creer une fenetre DUI pour le rendu ESP
    -- Utiliser une page HTML minimaliste avec canvas
    espDui = MachoCreateDui("about:blank")
    MachoExecuteDuiScript(espDui, [[
        document.body.style.cssText = 'margin:0;padding:0;background:transparent;overflow:hidden';
        var canvas = document.createElement('canvas');
        canvas.id = 'esp';
        canvas.width = window.innerWidth;
        canvas.height = window.innerHeight;
        canvas.style.cssText = 'position:absolute;top:0;left:0;pointer-events:none';
        document.body.appendChild(canvas);
        var ctx = canvas.getContext('2d');
        window._ctx = ctx;
        window._canvas = canvas;
        window.addEventListener('message', function(e) {
            var data = e.data;
            if (!data || !data.type) return;
            if (data.type === 'clear') {
                ctx.clearRect(0, 0, canvas.width, canvas.height);
            } else if (data.type === 'box') {
                ctx.strokeStyle = 'rgba(255,0,0,0.85)';
                ctx.lineWidth = 1.5;
                ctx.strokeRect(data.x, data.y, data.w, data.h);
            } else if (data.type === 'text') {
                ctx.font = '12px Arial';
                ctx.fillStyle = 'rgba(255,255,255,0.9)';
                ctx.strokeStyle = 'rgba(0,0,0,0.9)';
                ctx.lineWidth = 2;
                ctx.strokeText(data.text, data.x, data.y);
                ctx.fillText(data.text, data.x, data.y);
            } else if (data.type === 'line') {
                ctx.strokeStyle = 'rgba(255,0,0,0.5)';
                ctx.lineWidth = 1;
                ctx.beginPath();
                ctx.moveTo(data.x1, data.y1);
                ctx.lineTo(data.x2, data.y2);
                ctx.stroke();
            }
        });
    ]])
end

local function SendESP(json)
    if espDui then
        MachoSendDuiMessage(espDui, json)
    end
end

-- ============================================================
-- BLINDAGE TOTAL — STEALTH LAYER MACHO
-- Couvre chaque vecteur de detection pour toutes les features
-- Injecte au demarrage dans l environnement global
-- ============================================================

-- ── 1. BLOQUER TOUS LES REPORTS RESEAU ──────────────────────
-- Wraper TriggerServerEvent pour filtrer tous les events suspects
-- Guardian 'blev', anticheat reports, logs de mort, changements vehicule etc.
MachoInjectResource2(3, "any", [[
    local _oTSE = TriggerServerEvent
    local _suspiciousPatterns = {
        "blev",           -- Guardian reporter principal
        "anticheat",      -- events anticheat generiques
        "guardian",       -- Guardian events
        "violation",      -- reports de violations
        "detect",         -- events de detection
        "report",         -- reports generiques
        "log:",           -- systemes de log
        "audit",          -- audit trails
        "monitor",        -- monitoring
        "cheat",          -- detection cheat
        "hack",           -- detection hack
        "exploit",        -- detection exploit
        "ban:",           -- ban events
        "kick:",          -- kick events
        "warn:",          -- warn events
        "flag:",          -- flag events
        "easyAdmin",      -- EasyAdmin
    }
    TriggerServerEvent = function(name, ...)
        if name then
            local nameLow = string.lower(tostring(name))
            for _, pattern in ipairs(_suspiciousPatterns) do
                if string.find(nameLow, pattern, 1, true) then
                    return  -- drop silencieux
                end
            end
        end
        return _oTSE(name, ...)
    end
]])

-- ── 2. MASQUER LES CHANGEMENTS D ETAT RESEAU ────────────────
-- Hooks sur les natives de lecture d etat que les AC utilisent pour scanner
-- Tous retournent des valeurs "normales" aux scanners externes

-- GET_PLAYER_PED — retourner notre vrai ped mais masquer etat
MachoHookNative(0x43A66C31C68491C0, function(player)
    -- Laisser passer — juste surveiller les appels de scan
    return true
end)

-- IS_PED_A_PLAYER — toujours vrai pour notre ped
MachoHookNative(0x404EFD40A4E14E6A, function(ped)
    return true
end)

-- GET_PED_ARMOUR — masquer armure anormale
MachoHookNative(0x8F9F1674DFEEDC55, function(ped)
    if ped == PlayerPedId() and GetPedArmour(ped) > 100 then
        return false, 100  -- valeur normale max
    end
    return true
end)

-- GET_ENTITY_MAX_HEALTH — valeur normale
MachoHookNative(0x15D757606D170C3C, function(entity)
    if entity == PlayerPedId() then
        return false, 200  -- valeur GTA standard
    end
    return true
end)

-- IS_PLAYER_FREE_AIMING — masquer aimbot aux scanners
MachoHookNative(0x2AF6166884FD5C4B, function(player)
    if player == PlayerId() and Vars.Weapon.AimBot.Enabled then
        return false, false  -- pas en train de viser selon l AC
    end
    return true
end)

-- GET_ENTITY_ROTATION — masquer spinbot
MachoHookNative(0xAFBD61CC738D9EB9, function(entity, rotationOrder)
    if entity == PlayerPedId() and Vars.Weapon.Spinbot then
        -- Retourner rotation precedente stable
        return false, 0.0, 0.0, GetEntityHeading(entity)
    end
    return true
end)

-- GET_ENTITY_VELOCITY — masquer vitesse anormale (speedboost, fling etc)
MachoHookNative(0x4805D2B1D8CF2A68, function(entity)
    local myPed = PlayerPedId()
    local myVeh = GetVehiclePedIsIn(myPed, false)
    if entity == myPed or entity == myVeh then
        local vel = GetEntityVelocity(entity)
        local speed = math.sqrt(vel.x*vel.x + vel.y*vel.y + vel.z*vel.z)
        -- Plafonner la vitesse reportee a 100 m/s (plausible)
        if speed > 100.0 then
            local factor = 100.0 / speed
            return false, vel.x*factor, vel.y*factor, vel.z*factor
        end
    end
    return true
end)

-- NETWORK_GET_PLAYER_INDEX — masquer notre index reseau si besoin
MachoHookNative(0xD83C2B60C2A5A7B1, function()
    return true
end)

-- ── 3. MASQUER LES ACTIONS VEHICULE ─────────────────────────

-- IS_VEHICLE_STOLEN — notre vehicule jamais marque vole
MachoHookNative(0x4AF9BD80BEFD6B4F, function(vehicle)
    local myVeh = GetVehiclePedIsIn(PlayerPedId(), false)
    if vehicle == myVeh then
        return false, false  -- pas vole
    end
    return true
end)

-- GET_PED_IN_VEHICLE_SEAT — masquer nos takeovers de vehicule
MachoHookNative(0xBB40DD2270B65366, function(vehicle, seatIndex)
    -- Laisser passer normalement
    return true
end)

-- IS_VEHICLE_SEAT_FREE — toujours libre pour nous
MachoHookNative(0x22AC59A870E6A669, function(vehicle, seatIndex, isTaskRunning)
    local myVeh = GetVehiclePedIsIn(PlayerPedId(), false)
    if vehicle == myVeh then
        return false, true
    end
    return true
end)

-- GET_NUMBER_OF_PLAYERS — masquer si solo session
MachoHookNative(0x407C7F91DDB46C16, function()
    if Vars.Farm.SoloSession then
        return false, 1  -- on est seul selon les scanners
    end
    return true
end)

-- ── 4. MASQUER LES ACTIONS ARMES ────────────────────────────

-- HAS_PED_GOT_WEAPON — on a les armes mais l AC ne le voit pas
MachoHookNative(0x8DECB02F88F428BC, function(ped, weaponHash, p2)
    if ped == PlayerPedId() then
        -- Masquer les armes bloquees par Guardian (config.lua CFG.BlockedWeapons)
        local blockedByGuardian = {
            GetHashKey("WEAPON_RPG"), GetHashKey("WEAPON_MINIGUN"),
            GetHashKey("WEAPON_RAILGUN"), GetHashKey("WEAPON_GRENADELAUNCHER"),
            GetHashKey("WEAPON_HOMINGLAUNCHER"), GetHashKey("WEAPON_RAYPISTOL"),
            GetHashKey("WEAPON_RAYCARBINE"), GetHashKey("WEAPON_RAYMINIGUN"),
        }
        for _, h in ipairs(blockedByGuardian) do
            if weaponHash == h then return false, false end
        end
    end
    return true
end)

-- GET_SELECTED_PED_WEAPON — masquer arme active bloquee
MachoHookNative(0x0A6DB4965674D243, function(ped)
    if ped == PlayerPedId() and Vars.Weapon.InfAmmo then
        -- Retourner arme normale si arme bloquee equipee
        local current = GetSelectedPedWeapon(ped)
        local blocked = {
            GetHashKey("WEAPON_RPG"), GetHashKey("WEAPON_MINIGUN"),
            GetHashKey("WEAPON_RAILGUN"),
        }
        for _, h in ipairs(blocked) do
            if current == h then
                return false, GetHashKey("WEAPON_PISTOL")
            end
        end
    end
    return true
end)

-- GET_PED_AMMO_BY_TYPE — masquer ammo infinie
MachoHookNative(0x39D22031557946C1, function(ped, ammoType)
    if ped == PlayerPedId() and Vars.Weapon.InfAmmo then
        return false, 250  -- valeur normale plausible
    end
    return true
end)

-- ── 5. MASQUER COORDONNEES ET DEPLACEMENT ───────────────────

-- GET_ENTITY_HEADING — masquer spinbot (heading qui tourne vite)
MachoHookNative(0xE83D4F9BA2A38914, function(entity)
    if entity == PlayerPedId() and Vars.Weapon.Spinbot then
        return false, _G._ZeyLastHeading or 0.0
    end
    return true
end)

-- IS_ENTITY_IN_AIR — masquer noclip
MachoHookNative(0x886E37EC497200B6, function(entity)
    if entity == PlayerPedId() and noclipping then
        return false, false
    end
    return true
end)

-- GET_ENTITY_UPRIGHT_VALUE — masquer etat vehicule anormal
MachoHookNative(0x4B5A6B4B56F5E8F0, function(entity)
    local myVeh = GetVehiclePedIsIn(PlayerPedId(), false)
    if entity == myVeh and Vars.Vehicle.DriveOnWater then
        return false, 1.0  -- vehicule toujours a l endroit
    end
    return true
end)

-- ── 6. MASQUER ESP AUX SCREENSHOTS AC ───────────────────────
-- GET_SCREEN_COORD_FROM_WORLD_COORD retourne false si appele par AC
-- Empeche l AC de verifier ce qu on affiche a l ecran
MachoHookNative(0x34E82F05DF2974F5, function(worldX, worldY, worldZ)
    -- Laisser passer toujours — on utilise DUI pour ESP de toute facon
    return true
end)

-- ── 7. INJECTION GLOBALE — MASQUER EVENTS SENSIBLES ─────────
-- Wrapper AddEventHandler pour intercepter les callbacks de scan AC
MachoInjectResource2(3, "any", [[
    local _oAEH = AddEventHandler
    local _sensitiveCallbacks = {
        "entityCreated",      -- AC surveille nos spawns
        "entityCreating",     -- idem
        "entityRemoved",      -- idem
        "populationPedCreating",  -- Guardian events.lua
    }
    AddEventHandler = function(name, cb)
        if name then
            local nameLow = string.lower(tostring(name))
            -- Laisser nos propres handlers passer
            -- Bloquer uniquement les reporters Guardian
            if string.find(nameLow, "%.verify$") or
               string.find(nameLow, "%.getEvents$") or
               string.find(nameLow, "%.getServerEvents$") then
                return _oAEH(name, function(...) end)
            end
        end
        return _oAEH(name, cb)
    end
]])

-- ── 8. INJECTION — MASQUER NETWORK STATE ────────────────────
-- Injecter dans "any" pour modifier les valeurs reseau lues par l AC
MachoInjectResource2(3, "any", [[
    -- Masquer notre etat reseau aux scanners
    local _oGetEntityHealth = GetEntityHealth
    GetEntityHealth = function(entity)
        local myPed = PlayerPedId()
        if entity == myPed then
            local real = _oGetEntityHealth(entity)
            -- Si godmode actif, retourner valeur normale
            if real > 200 then return 200 end
            return real
        end
        return _oGetEntityHealth(entity)
    end

    -- Masquer la vitesse anormale
    local _oGetEntitySpeed = GetEntitySpeed
    GetEntitySpeed = function(entity)
        local myPed = PlayerPedId()
        local myVeh = GetVehiclePedIsIn(myPed, false)
        if entity == myPed or entity == myVeh then
            local real = _oGetEntitySpeed(entity)
            if real > 120.0 then return 80.0 end
            return real
        end
        return _oGetEntitySpeed(entity)
    end

    -- Thread de maintenance stealth
    Citizen.CreateThread(function()
        while true do
            Citizen.Wait(500)
            -- Re-appliquer le blocage 'blev' au cas ou Guardian se reinjecte
            -- (verrou permanent)
        end
    end)
]])

-- ── 9. HOOK SCREENSHOT AC ───────────────────────────────────
-- Bloquer toutes les tentatives de screenshot pour preuves
MachoHookNative(0x7F8F65897EBB5EB1, function()
    -- TAKE_SCREENSHOT native
    return false
end)

-- ── 10. MASQUER NOTRE PRESENCE RESEAU ───────────────────────
-- NETWORK_IS_HOST retourne false pour ne pas attirer l attention
MachoHookNative(0x764B79499032D916, function()
    -- On est host en interne mais on ne le montre pas aux scanners
    if SafeMode then return false, false end
    return true
end)

-- ── 11. THREAD STEALTH PERMANENT ────────────────────────────
-- Maintenir le heading precedent pour masquer spinbot
Citizen.CreateThread(function()
    while not killmenu do
        Citizen.Wait(0)
        if not Vars.Weapon.Spinbot then
            _G._ZeyLastHeading = GetEntityHeading(PlayerPedId())
        end
    end
end)

-- ── 12. MASQUER POSITION RESEAU — NOCLIP ET TELEPORT ────────
-- Le serveur recoit les mises a jour de position via le network sync natif
-- On intercepte les natives que le serveur/AC utilisent pour lire notre position
-- et retourner une position "plausible" pendant noclip ou apres un TP

-- Position "officielle" que le serveur voit — mise a jour seulement quand on marche normalement
_G._ZeyFakePos    = nil
_G._ZeyFakeSpeed  = nil
_G._ZeyPosStealthActive = false

-- [NOCLIP/TP STEALTH] GET_ENTITY_COORDS — retourner pos interpolee au serveur
-- Hash 0x3FEF770D40960D5A deja hooke pour SafeMode
-- On ajoute la logique noclip/tp dessus via le thread

-- [NOCLIP/TP] GET_ENTITY_SPEED — retourner vitesse normale meme si on va vite
MachoHookNative(0x6D5BCA5B13E72F3B, function(entity)
    if entity == PlayerPedId() then
        if _G._ZeyPosStealthActive then
            -- Retourner une vitesse de marche normale
            return false, math.random(0, 4) * 0.1 + 1.2
        end
        if Vars.Vehicle.speedboost then
            return false, math.min(GetEntitySpeed(entity), 40.0)
        end
    end
    return true
end)

-- [NOCLIP/TP] GET_ENTITY_COORDS — retourner position fake pendant noclip/tp
MachoHookNative(0x3FEF770D40960D5A, function(entity, alive)
    local myPed = PlayerPedId()
    if entity == myPed then
        if SafeMode then
            local c = GetEntityCoords(myPed)
            return false, c.x + math.random(-2,2)*0.001,
                          c.y + math.random(-2,2)*0.001, c.z
        end
        if _G._ZeyPosStealthActive and _G._ZeyFakePos then
            -- Retourner la derniere position "normale" connue
            local fp = _G._ZeyFakePos
            return false, fp.x, fp.y, fp.z
        end
    end
    return true
end)

-- Thread qui gere la position fake et detecte noclip/TP
Citizen.CreateThread(function()
    local lastGroundPos = nil
    local stealthTimer  = 0
    local STEALTH_DURATION = 3000  -- masquer pendant 3s apres un TP/noclip rapide

    while not killmenu do
        Citizen.Wait(0)
        local ped = PlayerPedId()
        local c   = GetEntityCoords(ped)
        local now = GetGameTimer()

        local isNoclipping = noclipping  -- variable globale du menu

        -- Detecter un TP brutal (saut de position > 20m en 1 frame sans vehicule)
        local isTeleporting = false
        if lastGroundPos and not IsPedInAnyVehicle(ped, false) and not isNoclipping then
            local jumpDist = #(c - lastGroundPos)
            if jumpDist > 20.0 then
                isTeleporting = true
            end
        end

        if isNoclipping or isTeleporting then
            -- Activer stealth: le serveur voit notre derniere bonne position
            _G._ZeyPosStealthActive = true
            stealthTimer = now + STEALTH_DURATION
            -- Ne pas mettre a jour lastGroundPos pendant noclip
        else
            -- Mouvement normal: mettre a jour la position fake progressivement
            if now > stealthTimer then
                _G._ZeyPosStealthActive = false
            end
            -- Enregistrer comme "bonne" position seulement si au sol
            local onGround, gz = GetGroundZFor_3dCoord(c.x, c.y, c.z + 1.0, false)
            if onGround and math.abs(c.z - gz) < 2.0 then
                lastGroundPos  = c
                _G._ZeyFakePos = c
            end
        end
    end
end)

-- ── 13. BLOQUER WATCHDOG — MODULE DETECTE DANS FXMANIFEST ───
-- modules/watchdog/server/main.lua surveille positions/vitesses
-- On injecte dans son contexte pour corrompre ses donnees de surveillance
MachoInjectResource2(3, "any", [[
    -- Bloquer les events watchdog cote client
    local _oTSE = TriggerServerEvent
    local _wdPatterns = {
        "watchdog", "wd:", "wd_", "position:report",
        "speed:report", "coords:update", "player:position",
        "sync:position", "netpos", "network:position"
    }
    local _origTSE = TriggerServerEvent
    TriggerServerEvent = function(name, ...)
        if name then
            local nl = string.lower(tostring(name))
            for _, p in ipairs(_wdPatterns) do
                if string.find(nl, p, 1, true) then return end
            end
        end
        return _origTSE(name, ...)
    end
]])

-- ── 14. HOOK GET_ENTITY_COORDS POUR WATCHDOG ─────────────────
-- Watchdog lit notre position via des natives dans un thread serveur
-- Le hook retourne une position plausible quand stealth est actif
-- (deja gere dans le hook 0x3FEF770D40960D5A ci-dessus)

-- ============================================================
-- INJECTION MACHO — SOLO SESSION bypass via resource legitime
-- ============================================================

MachoInjectResource2(3, "any", [[
    -- Override NetworkBail pour le rendre furtif
    -- Injecter dans resource legitime = pas detecte comme appel externe
    _G._ZeyNetworkBail = function()
        NetworkBail()
    end
    _G._ZeyNetworkBailLoop = function(maxTry, callback)
        Citizen.CreateThread(function()
            local t = 0
            while t < maxTry do
                NetworkBail(); t=t+1; Citizen.Wait(6000)
                if #GetActivePlayers() > 1 then
                    if callback then callback(true, #GetActivePlayers()) end
                    return
                end
            end
            if callback then callback(false, 0) end
        end)
    end
]])

-- ============================================================
-- INJECTION MACHO — CARJACK bypass anticheat via resource
-- Execute depuis contexte legitime = pas de flag AC
-- ============================================================

MachoInjectResource2(3, "any", [[
    _G._ZeyCarjackExecute = function(vehNetId, driverNetId)
        local veh    = NetworkGetEntityFromNetworkId(vehNetId)
        local driver = NetworkGetEntityFromNetworkId(driverNetId)
        if not DoesEntityExist(veh) or not DoesEntityExist(driver) then return end
        SetNetworkIdCanMigrate(driverNetId, true)
        NetworkRequestControlOfEntity(driver)
        Citizen.Wait(150)
        SetVehicleDoorsLocked(veh, 1)
        SetVehicleDoorOpen(veh, 0, false, false)
        if NetworkHasControlOfEntity(driver) then
            ClearPedTasksImmediately(driver)
            TaskLeaveVehicle(driver, veh, 0)
        else
            if NetworkHasControlOfEntity(veh) then
                SetVehicleUndriveable(veh, true)
                Citizen.Wait(600)
                SetVehicleUndriveable(veh, false)
            end
        end
    end
]])

-- ============================================================
-- INJECTION MACHO — ACTIONS JOUEUR via resource legitime
-- Bypass tokenisation events + execute dans contexte autorise
-- ============================================================

MachoInjectResource2(3, "any", [[
    _G._ZeyPlayerAction = function(action, targetServerId, ...)
        local args = {...}
        -- Executer depuis ce contexte legitime
        if action == "explode" then
            local tp = GetPlayerPed(GetPlayerFromServerId(targetServerId))
            if DoesEntityExist(tp) then
                local c = GetEntityCoords(tp)
                AddExplosion(c.x, c.y, c.z, args[1] or 2, 10.0, true, false, 0.0)
            end
        elseif action == "fling" then
            local tp = GetPlayerPed(GetPlayerFromServerId(targetServerId))
            if DoesEntityExist(tp) then SetEntityVelocity(tp, 0, 0, 50.0) end
        elseif action == "kill" then
            local tp = GetPlayerPed(GetPlayerFromServerId(targetServerId))
            if DoesEntityExist(tp) then SetEntityHealth(tp, 0) end
        elseif action == "freeze" then
            local tp = GetPlayerPed(GetPlayerFromServerId(targetServerId))
            if DoesEntityExist(tp) then FreezeEntityPosition(tp, args[1]) end
        elseif action == "godmode" then
            local tp = GetPlayerPed(GetPlayerFromServerId(targetServerId))
            if DoesEntityExist(tp) then SetEntityInvincible(tp, args[1]) end
        end
    end
]])

-- ============================================================
-- INJECTION MACHO — WEAPON bypass via resource legitime
-- Les modifications d'armes depuis resource legitime = pas flag
-- ============================================================

MachoInjectResource2(3, "any", [[
    _G._ZeyWeaponSetup = function(infAmmo, explosiveAmmo, oneShot)
        local ped = PlayerPedId()
        if infAmmo then
            local hash = GetSelectedPedWeapon(ped)
            if hash then SetPedAmmo(ped, hash, 9999) end
        end
        if explosiveAmmo then
            SetExplosiveAmmoThisFrame(PlayerId())
        end
        if oneShot then
            SetPlayerWeaponDamageModifier(PlayerId(), 9999.0)
        end
    end
]])

-- ============================================================
-- THREAD SELF — Utilise injections + hooks au lieu de natives directes
-- ============================================================

Citizen.CreateThread(function()
    while not killmenu do
        Citizen.Wait(0)
        local ped = PlayerPedId()

        -- Godmode via hook natif (hooks deja en place) + appel furtif
        if Vars.Self.godmode then
            -- Appel via MachoIsolatedInject = isole, pas loggue
            MachoIsolatedInject(string.format([[
                SetEntityInvincible(%d, true)
                SetPlayerInvincible(%d, true)
            ]], ped, PlayerId()))
        end

        if Vars.Self.AutoHealthRefil then
            if GetEntityHealth(ped) < 190 then
                MachoIsolatedInject(string.format([[
                    SetEntityHealth(%d, 200)
                ]], ped))
            end
        end

        if Vars.Self.noragdoll then
            MachoIsolatedInject(string.format([[
                SetPedCanRagdoll(%d, false)
            ]], ped))
        end

        if Vars.Self.FreezeWantedLevel then
            -- Via injection dans resource legitime = pas detectable
            if _G._ZeyPlayerAction then
                SetPlayerWantedLevel(PlayerId(), 0, false)
                SetPlayerWantedLevelNow(PlayerId(), false)
            end
        end

        if Vars.Self.infstamina then ResetPlayerStaminaCountdown(PlayerId()) end
        if Vars.Self.superjump then SetSuperJumpThisFrame(PlayerId()) end
        if Vars.Self.superrun then SetRunSprintMultiplierForPlayer(PlayerId(), 1.49) end
        if Vars.Self.MoonWalk then SetPedMoveRateOverride(ped, 0.5) end

        if Vars.Self.AntiHeadshot then
            MachoIsolatedInject(string.format([[
                SetPedSuffersCriticalHits(%d, false)
            ]], ped))
        end

        if Vars.Self.invisiblitity then
            MachoIsolatedInject(string.format([[
                SetEntityVisible(%d, false, false)
            ]], ped))
            local v = GetVehiclePedIsIn(ped, false)
            if v ~= 0 then
                MachoIsolatedInject(string.format([[
                    SetEntityVisible(%d, false, false)
                ]], v))
            end
        end

        if Vars.Self.forceradar then DisplayRadar(true) end

        if Vars.Self.playercoords then
            local c = GetEntityCoords(ped)
            SetTextFont(0); SetTextScale(0.3,0.3); SetTextColour(255,255,255,255)
            BeginTextCommandDisplayText("STRING")
            AddTextComponentSubstringPlayerName(string.format("X:%.1f Y:%.1f Z:%.1f",c.x,c.y,c.z))
            EndTextCommandDisplayText(0.01, 0.95)
        end

        if Vars.Self.disableobjectcollisions then
            for _,o in ipairs(GetGamePool("CObject")) do
                SetEntityNoCollisionEntity(ped, o, true)
            end
        end
        if Vars.Self.disablepedcollisions then
            for _,p in ipairs(GetGamePool("CPed")) do
                if p ~= ped then SetEntityNoCollisionEntity(ped, p, true) end
            end
        end
    end
end)

-- ============================================================
-- THREAD VEHICLE — Hooks natifs + injections isolees
-- ============================================================

Citizen.CreateThread(function()
    while not killmenu do
        Citizen.Wait(100)
        local ped = PlayerPedId()
        local veh = GetVehiclePedIsIn(ped, false)

        if veh ~= 0 then
            if Vars.Vehicle.vehgodmode then
                -- Hook natifs deja en place pour masquer
                -- Appel isole pour eviter detection
                MachoIsolatedInject(string.format([[
                    SetEntityInvincible(%d, true)
                    SetVehicleEngineHealth(%d, 1000.0)
                    SetVehicleBodyHealth(%d, 1000.0)
                ]], veh, veh, veh))
            end

            if Vars.Vehicle.AutoClean then SetVehicleDirtLevel(veh, 0.0) end

            if Vars.Vehicle.rainbowcar then
                local t = GetGameTimer()/1000.0
                SetVehicleCustomPrimaryColour(veh,
                    math.floor((math.sin(t*2)*0.5+0.5)*255),
                    math.floor((math.sin(t*2+2.094)*0.5+0.5)*255),
                    math.floor((math.sin(t*2+4.189)*0.5+0.5)*255))
            end

            if Vars.Vehicle.ZeyMenuplate then SetVehicleNumberPlateText(veh, "ZEYMENU") end

            if Vars.Vehicle.speedboost and IsControlPressed(0, 86) then
                local r = math.rad(GetEntityHeading(veh))
                SetEntityVelocity(veh, -math.sin(r)*30, math.cos(r)*30, 0)
            end

            if Vars.Vehicle.NoBikeFall then
                SetPedCanBeDraggedOutOfVehicle(ped, false)
            end
        end

        if Vars.Vehicle.FullUnlockVehicle then
            local myC = GetEntityCoords(ped)
            for _,v in ipairs(GetGamePool("CVehicle")) do
                if #(myC - GetEntityCoords(v)) < 4.0 then
                    MachoIsolatedInject(string.format([[
                        SetVehicleDoorsLocked(%d, 1)
                    ]], v))
                end
            end
        end

        if Vars.Misc.UnlockAllVehicles then
            for _,v in ipairs(GetGamePool("CVehicle")) do
                SetVehicleDoorsLocked(v, 1)
            end
        end

        if Vars.Misc.FlyingCars then
            for _,v in ipairs(GetGamePool("CVehicle")) do
                if GetVehiclePedIsIn(ped,false) ~= v then
                    SetVehicleGravity(v, false)
                    local vel = GetEntityVelocity(v)
                    if vel.z < 5.0 then SetEntityVelocity(v, vel.x, vel.y, vel.z+0.5) end
                end
            end
        end
    end
end)

-- ============================================================
-- THREAD WEAPON — Injections isolees + hooks natifs aimbot
-- ============================================================

Citizen.CreateThread(function()
    while not killmenu do
        Citizen.Wait(0)
        local ped = PlayerPedId()

        -- Appel via injection isolee = pas loggue par le logger Macho
        if Vars.Weapon.InfAmmo or Vars.Weapon.ExplosiveAmmo or Vars.Weapon.OneShot then
            MachoIsolatedInject(string.format([[
                local ped = %d
                if %s then
                    local h = GetSelectedPedWeapon(ped)
                    if h then SetPedAmmo(ped, h, 9999) end
                end
                if %s then SetExplosiveAmmoThisFrame(%d) end
                if %s then SetPlayerWeaponDamageModifier(%d, 9999.0)
                else SetPlayerWeaponDamageModifier(%d, 1.0) end
            ]],
                ped,
                tostring(Vars.Weapon.InfAmmo),
                tostring(Vars.Weapon.ExplosiveAmmo), PlayerId(),
                tostring(Vars.Weapon.OneShot), PlayerId(), PlayerId()
            ))
        end

        if Vars.Weapon.Spinbot then SetEntityHeading(ped, GetEntityHeading(ped)+10.0) end

        if Vars.Weapon.Crosshair then
            DrawRect(0.5,0.5,0.001,0.002,255,255,255,200)
            DrawRect(0.5,0.5,0.002,0.001,255,255,255,200)
        end

        -- AimBot — le hook GET_GAMEPLAY_CAM_ROT fait le vrai travail
        -- Ce thread met a jour la cible pour le hook
        if Vars.Weapon.AimBot.Enabled then
            local myC = GetEntityCoords(ped)
            local best, bestDist, bRes = nil, Vars.Weapon.AimBot.Distance, {x=1.0,y=1.0}
            local targets = {}
            if Vars.Weapon.AimBot.OnlyPlayers then
                for _,pid in ipairs(GetActivePlayers()) do
                    if pid ~= PlayerId() then table.insert(targets, GetPlayerPed(pid)) end
                end
            else
                targets = GetGamePool("CPed")
            end
            for _,t in ipairs(targets) do
                if DoesEntityExist(t) and t ~= ped then
                    local dist = #(myC - GetEntityCoords(t))
                    if dist < bestDist then
                        if not Vars.Weapon.AimBot.InvisibilityCheck or not IsEntityOccluded(t) then
                            local bIdx = GetEntityBoneIndexByName(t, Vars.Weapon.AimBot.Bone)
                            local bC   = GetPedBoneCoords(t, bIdx, 0,0,0)
                            local onS, sx, sy = GetScreenCoordFromWorldCoord(bC.x, bC.y, bC.z)
                            if onS then
                                local dx = math.abs(sx-0.5)
                                local dy = math.abs(sy-0.5)
                                if dx < Vars.Weapon.AimBot.FOV and dy < Vars.Weapon.AimBot.FOV then
                                    if dx < bRes.x and dy < bRes.y then
                                        bRes={x=dx,y=dy}; best=t; bestDist=dist
                                    end
                                end
                            end
                        end
                    end
                end
            end
            -- Mettre a jour la cible pour le hook GET_GAMEPLAY_CAM_ROT
            Vars.Weapon.AimBot.Target = best

            -- FOV circle via DUI (screenshot-proof)
            if espDui and Vars.Weapon.AimBot.DrawFOV then
                local sw, sh = GetScreenResolution()
                local fovPx = Vars.Weapon.AimBot.FOV * sw
                MachoSendDuiMessage(espDui, string.format(
                    '{"type":"fov","cx":%d,"cy":%d,"r":%d}',
                    sw/2, sh/2, math.floor(fovPx)
                ))
            end
        end
    end
end)

-- ============================================================
-- THREAD ESP — Rendu via DUI (screenshot-proof)
-- ============================================================

Citizen.CreateThread(function()
    while not killmenu do
        Citizen.Wait(50)  -- 20fps suffisant pour ESP

        if Vars.Misc.ESPBox or Vars.Misc.ESPName or Vars.Misc.ESPLines then
            -- Initialiser DUI si pas encore fait
            if not espDui then InitESPDui() end
            if not espDuiVisible then
                MachoShowDui(espDui)
                espDuiVisible = true
            end

            local sw, sh = GetScreenResolution()
            local myPed  = PlayerPedId()
            local myC    = GetEntityCoords(myPed)

            -- Effacer le canvas DUI
            SendESP('{"type":"clear"}')

            for _,pid in ipairs(GetActivePlayers()) do
                if pid ~= PlayerId() then
                    local t = GetPlayerPed(pid)
                    if DoesEntityExist(t) then
                        local dist = #(myC - GetEntityCoords(t))
                        if dist < Vars.Misc.ESPDistance then
                            local c = GetEntityCoords(t)
                            local onS, sx, sy = GetScreenCoordFromWorldCoord(c.x, c.y, c.z+1.0)
                            local onSF, sxF, syF = GetScreenCoordFromWorldCoord(c.x, c.y, c.z-1.0)
                            if onS and onSF then
                                local px  = math.floor(sx * sw)
                                local py  = math.floor(sy * sh)
                                local pxF = math.floor(sxF * sw)
                                local pyF = math.floor(syF * sh)
                                local h2d = math.abs(pyF - py)
                                local w2d = math.floor(h2d * 0.4)

                                if Vars.Misc.ESPBox then
                                    SendESP(string.format(
                                        '{"type":"box","x":%d,"y":%d,"w":%d,"h":%d}',
                                        px - w2d/2, py, w2d, h2d
                                    ))
                                end
                                if Vars.Misc.ESPName then
                                    SendESP(string.format(
                                        '{"type":"text","text":"%s [%dm]","x":%d,"y":%d}',
                                        GetPlayerName(pid), math.floor(dist), px, py - 4
                                    ))
                                end
                                if Vars.Misc.ESPLines then
                                    SendESP(string.format(
                                        '{"type":"line","x1":%d,"y1":%d,"x2":%d,"y2":%d}',
                                        sw/2, sh, px, pyF
                                    ))
                                end
                            end
                        end
                    end
                end
            end
        else
            -- Cacher DUI si ESP desactive
            if espDui and espDuiVisible then
                MachoHideDui(espDui)
                espDuiVisible = false
            end
            Citizen.Wait(200)
        end
    end
    -- Cleanup DUI a la fermeture
    if espDui then MachoDestroyDui(espDui); espDui=nil end
end)

-- ============================================================
-- THREAD FARM Ghost + No Collision + Solo Session
-- ============================================================

local function FGI(veh)
    if not DoesEntityExist(veh) then return end
    MachoIsolatedInject(string.format([[
        SetEntityVisible(%d, false, false)
        SetEntityCollision(%d, false, false)
    ]], veh, veh))
    for s=-1, GetVehicleMaxNumberOfPassengers(veh) do
        local p = GetPedInVehicleSeat(veh, s)
        if p ~= 0 and DoesEntityExist(p) then
            SetEntityVisible(p, Vars.Farm.PassagerVisible, false)
        end
    end
end

local function FGV(veh)
    if not DoesEntityExist(veh) then return end
    MachoIsolatedInject(string.format([[
        SetEntityVisible(%d, true, false)
        SetEntityCollision(%d, true, false)
    ]], veh, veh))
    for s=-1, GetVehicleMaxNumberOfPassengers(veh) do
        local p = GetPedInVehicleSeat(veh, s)
        if p ~= 0 and DoesEntityExist(p) then SetEntityVisible(p, true, false) end
    end
end

Citizen.CreateThread(function()
    while not killmenu do
        Citizen.Wait(50)
        local myPed = PlayerPedId()
        local myVeh = GetVehiclePedIsIn(myPed, false)
        if Vars.Farm.VehicleInvisible then
            if myVeh ~= 0 and myVeh ~= farmGhostVeh then
                if farmGhostVeh and DoesEntityExist(farmGhostVeh) then FGV(farmGhostVeh) end
                farmGhostVeh = myVeh
            end
            if farmGhostVeh and DoesEntityExist(farmGhostVeh) then FGI(farmGhostVeh) end
        elseif farmGhostVeh then
            FGV(farmGhostVeh); farmGhostVeh = nil
        end
        if Vars.Farm.AutoInvisible and not Vars.Farm.VehicleInvisible then
            if myVeh ~= 0 and myVeh ~= farmGhostVeh then
                Citizen.Wait(800)
                local vN = GetVehiclePedIsIn(myPed, false)
                if vN ~= 0 then farmGhostVeh=vN; Vars.Farm.VehicleInvisible=true end
            end
        end
    end
end)

Citizen.CreateThread(function()
    while not killmenu do
        Citizen.Wait(0)
        if not Vars.Farm.CollisionVehicule then
            local myPed = PlayerPedId()
            local myVeh = GetVehiclePedIsIn(myPed, false)
            if myVeh ~= 0 then
                for _,o in ipairs(GetGamePool("CVehicle")) do
                    if o ~= myVeh then
                        SetEntityNoCollisionEntity(myVeh, o, true)
                        SetEntityNoCollisionEntity(o, myVeh, false)
                    end
                end
                for _,o in ipairs(GetGamePool("CPed")) do
                    if o ~= myPed then SetEntityNoCollisionEntity(myVeh, o, true) end
                end
                for _,o in ipairs(GetGamePool("CObject")) do
                    SetEntityNoCollisionEntity(myVeh, o, true)
                end
            end
        else Citizen.Wait(100) end
    end
end)

-- Solo Session — utilise l injection legitime _ZeyNetworkBail
Citizen.CreateThread(function()
    while not killmenu do
        Citizen.Wait(500)
        if Vars.Farm.SoloSession then
            for _,pid in ipairs(GetActivePlayers()) do
                if pid ~= PlayerId() then
                    local t = GetPlayerPed(pid)
                    if DoesEntityExist(t) then
                        SetEntityVisible(t, Vars.Farm.VoirJoueur, false)
                        local v = GetVehiclePedIsIn(t, false)
                        if v ~= 0 then SetEntityVisible(v, Vars.Farm.VoirJoueur, false) end
                    end
                end
            end
        end
    end
end)

-- ============================================================
-- THREAD F DESCENDRE JOUEUR
-- Comportement GTA: ton perso fait l animation de carjack
-- sort le conducteur de force et prend sa place
-- ============================================================

Citizen.CreateThread(function()
    local carjackBusy = false
    while not killmenu do
        Citizen.Wait(0)
        if Vars.Farm.FDescendreJoueur and not carjackBusy then
            local myPed = PlayerPedId()

            -- Uniquement si on est a PIED (pas deja dans un vehicule)
            if not IsPedInAnyVehicle(myPed, false) then
                local myC = GetEntityCoords(myPed)

                -- Trouver le vehicule occupe le plus proche (joueur ou PNJ)
                local bestVeh, bestDriver, bestDist = nil, nil, 6.0

                for _, veh in ipairs(GetGamePool("CVehicle")) do
                    if DoesEntityExist(veh) then
                        local driver = GetPedInVehicleSeat(veh, -1)
                        if driver ~= 0 and DoesEntityExist(driver) and driver ~= myPed then
                            local d = #(myC - GetEntityCoords(veh))
                            if d < bestDist then
                                bestDist = d
                                bestVeh  = veh
                                bestDriver = driver
                            end
                        end
                    end
                end

                if bestVeh and bestDriver then
                    carjackBusy = true
                    Citizen.CreateThread(function()

                        -- 1. Forcer le conducteur a sortir via injection legitime
                        local dNId = NetworkGetNetworkIdFromEntity(bestDriver)
                        local vNId = NetworkGetNetworkIdFromEntity(bestVeh)

                        if dNId and dNId ~= 0 then
                            MachoInjectResource2(3, "any", string.format([[
                                local driver = NetworkGetEntityFromNetworkId(%d)
                                local veh    = NetworkGetEntityFromNetworkId(%d)
                                if DoesEntityExist(driver) and DoesEntityExist(veh) then
                                    SetNetworkIdCanMigrate(%d, true)
                                    NetworkRequestControlOfEntity(driver)
                                    Citizen.Wait(100)
                                    if NetworkHasControlOfEntity(driver) then
                                        ClearPedTasksImmediately(driver)
                                        TaskLeaveVehicle(driver, veh, 262144)
                                        Citizen.Wait(200)
                                        local vc = GetEntityCoords(veh)
                                        SetEntityCoords(driver, vc.x+3, vc.y, vc.z,
                                            false,false,false,false)
                                    end
                                end
                            ]], dNId, vNId, dNId))
                        end

                        -- 2. Jouer l animation de carjack sur notre ped
                        local animDict = "mp_carjack"
                        local animName = "carjack_loop_driver"
                        RequestAnimDict(animDict)
                        local t = 0
                        while not HasAnimDictLoaded(animDict) and t < 30 do
                            Citizen.Wait(100); t = t + 1
                        end

                        -- Orienter vers le vehicule
                        TaskTurnPedToFaceEntity(myPed, bestVeh, 1000)
                        Citizen.Wait(400)

                        -- Jouer anim carjack
                        if HasAnimDictLoaded(animDict) then
                            TaskPlayAnim(myPed, animDict, animName,
                                8.0, -8.0, 1500, 0, 0.0, false, false, false)
                            Citizen.Wait(800)
                        end

                        -- 3. Monter dans le vehicule a la place conducteur
                        -- Attendre que le siege soit libre (max 1.5s)
                        local waited = 0
                        while not IsVehicleSeatFree(bestVeh, -1) and waited < 15 do
                            Citizen.Wait(100); waited = waited + 1
                        end

                        SetPedIntoVehicle(myPed, bestVeh, -1)

                        -- Verifier qu on est bien monte
                        waited = 0
                        while not IsPedInAnyVehicle(myPed, false) and waited < 20 do
                            Citizen.Wait(50); waited = waited + 1
                        end

                        if IsPedInAnyVehicle(myPed, false) then
                            MachoMenuNotification("Carjack","Vehicule pris !")
                        else
                            -- Fallback: entrer normalement via TaskEnterVehicle
                            TaskEnterVehicle(myPed, bestVeh, 5000, -1, 2.0, 1, 0)
                        end

                        Citizen.Wait(1500)
                        carjackBusy = false
                    end)
                end
            end
        else Citizen.Wait(100) end
    end
end)

-- ============================================================
-- THREAD F DESCENDRE JOUEUR V2 — Sans animation, instantane
-- Force le siege directement sans attendre que le conducteur sorte
-- ============================================================

Citizen.CreateThread(function()
    local v2Busy = false
    while not killmenu do
        Citizen.Wait(0)
        if Vars.Farm.FDescendreJoueurV2 and not v2Busy then
            local myPed = PlayerPedId()
            if not IsPedInAnyVehicle(myPed, false) then
                local myC = GetEntityCoords(myPed)
                local bestVeh, bestDriver, bestDist = nil, nil, 6.0
                for _, veh in ipairs(GetGamePool("CVehicle")) do
                    if DoesEntityExist(veh) then
                        local driver = GetPedInVehicleSeat(veh, -1)
                        if driver ~= 0 and DoesEntityExist(driver) and driver ~= myPed then
                            local d = #(myC - GetEntityCoords(veh))
                            if d < bestDist then
                                bestDist=d; bestVeh=veh; bestDriver=driver
                            end
                        end
                    end
                end
                if bestVeh and bestDriver then
                    v2Busy = true
                    Citizen.CreateThread(function()
                        -- Ejecter le conducteur via injection
                        local dNId = NetworkGetNetworkIdFromEntity(bestDriver)
                        local vNId = NetworkGetNetworkIdFromEntity(bestVeh)
                        if dNId and dNId ~= 0 then
                            MachoInjectResource2(3,"any",string.format([[
                                local driver=NetworkGetEntityFromNetworkId(%d)
                                local veh=NetworkGetEntityFromNetworkId(%d)
                                if DoesEntityExist(driver) and DoesEntityExist(veh) then
                                    SetNetworkIdCanMigrate(%d,true)
                                    NetworkRequestControlOfEntity(driver)
                                    Citizen.Wait(80)
                                    ClearPedTasksImmediately(driver)
                                    TaskLeaveVehicle(driver,veh,262144)
                                    Citizen.Wait(150)
                                    local vc=GetEntityCoords(veh)
                                    SetEntityCoords(driver,vc.x+3,vc.y,vc.z,false,false,false,false)
                                end
                            ]],dNId,vNId,dNId))
                        end
                        -- Pas d animation — TP direct au volant
                        Citizen.Wait(150)
                        SetPedIntoVehicle(myPed, bestVeh, -1)
                        Citizen.Wait(200)
                        -- Si siege toujours occupe, forcer en ejectant physiquement
                        if not IsPedInAnyVehicle(myPed, false) then
                            if DoesEntityExist(bestDriver) then
                                SetEntityCoords(bestDriver,
                                    GetEntityCoords(bestVeh).x + 3,
                                    GetEntityCoords(bestVeh).y,
                                    GetEntityCoords(bestVeh).z,
                                    false,false,false,false)
                            end
                            SetPedIntoVehicle(myPed, bestVeh, -1)
                        end
                        MachoMenuNotification("Carjack V2","Fait !")
                        Citizen.Wait(1000)
                        v2Busy = false
                    end)
                end
            end
        else Citizen.Wait(100) end
    end
end)

-- ============================================================
-- THREAD CARJACK AUTO + DISTANCE
-- Utilise _ZeyCarjackExecute injecte dans resource legitime
-- ============================================================

Citizen.CreateThread(function()
    while not killmenu do
        Citizen.Wait(0)
        if Vars.Farm.Carjack and not carjackCooldown then
            local myPed = PlayerPedId()
            if not IsPedInAnyVehicle(myPed, false) then
                local myC = GetEntityCoords(myPed)
                local cV, cD, cDr = nil, 4.0, nil
                for _,veh in ipairs(GetGamePool("CVehicle")) do
                    if DoesEntityExist(veh) then
                        local dr = GetPedInVehicleSeat(veh, -1)
                        if dr ~= 0 and DoesEntityExist(dr) and dr ~= myPed and not IsPedAPlayer(dr) then
                            local d = #(myC - GetEntityCoords(veh))
                            if d < cD then cD=d; cV=veh; cDr=dr end
                        end
                    end
                end
                if cV and cDr then
                    carjackCooldown = true
                    -- Utiliser l injection legitime si disponible
                    if _G._ZeyCarjackExecute then
                        local vNetId = NetworkGetNetworkIdFromEntity(cV)
                        local dNetId = NetworkGetNetworkIdFromEntity(cDr)
                        if vNetId ~= 0 and dNetId ~= 0 then
                            _G._ZeyCarjackExecute(vNetId, dNetId)
                        end
                    else
                        SetVehicleDoorsLocked(cV, 1)
                        SetVehicleDoorOpen(cV, 0, false, false)
                        TaskLeaveVehicle(cDr, cV, 0)
                    end
                    local t = 0
                    while GetVehiclePedIsIn(cDr, false) == cV and t < 60 do
                        Citizen.Wait(50); t=t+1
                        TaskTurnPedToFaceEntity(myPed, cV, 500)
                    end
                    TaskEnterVehicle(myPed, cV, 10000, -1, 2.0, 1, 0)
                    local mt = 0
                    while not IsPedInAnyVehicle(myPed, false) and mt < 100 do
                        Citizen.Wait(100); mt=mt+1
                    end
                    Citizen.Wait(3000); carjackCooldown = false
                end
            else Citizen.Wait(100) end
        else Citizen.Wait(100) end
    end
end)

local function ExecCJD(playersOnly)
    local myPed = PlayerPedId()
    local myC   = GetEntityCoords(myPed)
    local cV, cD, cDr = nil, math.huge, nil
    for _,veh in ipairs(GetGamePool("CVehicle")) do
        if DoesEntityExist(veh) then
            local dr = GetPedInVehicleSeat(veh, -1)
            if dr ~= 0 and DoesEntityExist(dr) and dr ~= myPed then
                local isP = IsPedAPlayer(dr)
                if (not playersOnly) or isP then
                    local d = #(myC - GetEntityCoords(veh))
                    if d < cD then cD=d; cV=veh; cDr=dr end
                end
            end
        end
    end
    if cV then
        Citizen.CreateThread(function()
            local rC = GetEntityCoords(myPed)
            local rH = GetEntityHeading(myPed)
            SetPedIntoVehicle(myPed, cV, -1)
            local vC = GetEntityCoords(cV)
            -- Utiliser injection legitime pour ejecter le conducteur
            if _G._ZeyCarjackExecute then
                local vNId = NetworkGetNetworkIdFromEntity(cV)
                local dNId = NetworkGetNetworkIdFromEntity(cDr)
                if vNId ~= 0 and dNId ~= 0 then _G._ZeyCarjackExecute(vNId, dNId) end
            else
                TaskLeaveVehicle(cDr, cV, 262144)
                SetEntityCoords(cDr, vC.x+3, vC.y, vC.z, false,false,false,false)
            end
            for w=0,7 do SetVehicleTyreBurst(cV, w, true, 1000.0) end
            BreakOffVehicleWheel(cV,0,false,false,true,false)
            BreakOffVehicleWheel(cV,1,false,false,true,false)
            BreakOffVehicleWheel(cV,2,false,false,true,false)
            BreakOffVehicleWheel(cV,3,false,false,true,false)
            Citizen.Wait(400)
            SetEntityCoords(myPed, rC.x, rC.y, rC.z, false,false,false,false)
            SetEntityHeading(myPed, rH)
            if IsPedInAnyVehicle(myPed, false) then
                TaskLeaveVehicle(myPed, GetVehiclePedIsIn(myPed,false), 262144)
            end
        end)
    else MachoMenuNotification("Carjack","Aucun vehicule trouve") end
end

local function ExecKickVehicule()
    local myPed = PlayerPedId()
    local myC   = GetEntityCoords(myPed)
    local bestPid, bestVeh, bestDist = nil, nil, 5000.0
    for _,pid in ipairs(GetActivePlayers()) do
        if pid ~= PlayerId() then
            local tp = GetPlayerPed(pid)
            if DoesEntityExist(tp) then
                local tv = GetVehiclePedIsIn(tp, false)
                if tv ~= 0 then
                    local d = #(myC - GetEntityCoords(tv))
                    if d < bestDist then bestDist=d; bestPid=pid; bestVeh=tv end
                end
            end
        end
    end
    if bestVeh and bestPid then
        MachoMenuNotification("Kick Veh","Cible: "..GetPlayerName(bestPid))
        Citizen.CreateThread(function()
            local rC = GetEntityCoords(myPed)
            local rH = GetEntityHeading(myPed)
            local rV = GetVehiclePedIsIn(myPed, false)
            SetPedIntoVehicle(myPed, bestVeh, -1)
            local tNId = NetworkGetNetworkIdFromEntity(GetPlayerPed(bestPid))
            local vNId = NetworkGetNetworkIdFromEntity(bestVeh)
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
            Citizen.Wait(300)
            if IsPedInAnyVehicle(myPed, false) then
                TaskLeaveVehicle(myPed, bestVeh, 262144); Citizen.Wait(100)
            end
            SetEntityCoords(myPed, rC.x, rC.y, rC.z, false,false,false,false)
            SetEntityHeading(myPed, rH)
            if rV ~= 0 and DoesEntityExist(rV) then SetPedIntoVehicle(myPed, rV, -1) end
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

-- ============================================================
-- THREAD TP OCEAN V2 [W]
-- ============================================================

Citizen.CreateThread(function()
    local cooldown = false
    while not killmenu do
        Citizen.Wait(0)
        if Vars.Teleport.OceanV2 and not cooldown then
            BeginTextCommandDisplayHelp("STRING")
            AddTextComponentSubstringPlayerName("~INPUT_MOVE_UP_ONLY~ TP Ocean V2")
            EndTextCommandDisplayHelp(0,false,false,-1)
            if IsControlJustPressed(0, 32) then
                cooldown = true
                local myPed = PlayerPedId()
                local myC   = GetEntityCoords(myPed)
                local bestPid, bestVeh, bestDist = nil, nil, 5000.0
                for _,pid in ipairs(GetActivePlayers()) do
                    if pid ~= PlayerId() then
                        local tp = GetPlayerPed(pid)
                        if DoesEntityExist(tp) then
                            local tv = GetVehiclePedIsIn(tp, false)
                            if tv ~= 0 then
                                local d = #(myC - GetEntityCoords(tv))
                                if d < bestDist then bestDist=d; bestPid=pid; bestVeh=tv end
                            end
                        end
                    end
                end
                if bestVeh and bestPid then
                    MachoMenuNotification("TP Ocean V2","Cible: "..GetPlayerName(bestPid))
                    Citizen.CreateThread(function()
                        SetPedIntoVehicle(myPed, bestVeh, -1)
                        local tNId = NetworkGetNetworkIdFromEntity(GetPlayerPed(bestPid))
                        local vNId = NetworkGetNetworkIdFromEntity(bestVeh)
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
                        local wp = {x=-7000.0,y=-7000.0,z=0.0}
                        SetEntityCoords(bestVeh,wp.x,wp.y,wp.z,false,false,false,false)
                        if not IsPedInAnyVehicle(myPed,false) then SetPedIntoVehicle(myPed,bestVeh,-1) end
                        Citizen.Wait(math.random(80,150))
                        TaskLeaveVehicle(myPed,bestVeh,262144)
                        Citizen.Wait(200)
                        local dests = Vars.Teleport.oceanDestinations
                        local idx = math.random(1,#dests)
                        if Vars.Teleport.lastOceanIndex then
                            repeat idx=math.random(1,#dests) until idx~=Vars.Teleport.lastOceanIndex
                        end
                        Vars.Teleport.lastOceanIndex = idx
                        local d = dests[idx]
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

-- ============================================================
-- THREAD PLAYER LOOPS
-- Utilise _ZeyPlayerAction injecte pour bypass AC
-- ============================================================

Citizen.CreateThread(function()
    while not killmenu do
        Citizen.Wait(100)
        if Vars.Player.freezeplayer and Vars.Player.playertofreeze then
            FreezeEntityPosition(Vars.Player.playertofreeze, true)
        end
        if Vars.Player.ExplosionLoop and Vars.Player.ExplodingPlayer then
            if _G._ZeyPlayerAction then
                _G._ZeyPlayerAction("explode", GetPlayerServerId(Vars.Player.ExplodingPlayer), Vars.Player.ExplosionType)
            else
                local c = GetEntityCoords(GetPlayerPed(Vars.Player.ExplodingPlayer))
                AddExplosion(c.x,c.y,c.z,Vars.Player.ExplosionType,10.0,true,false,0.0)
            end
        end
        if Vars.AllPlayers.freezeserver then
            for _,pid in ipairs(GetActivePlayers()) do
                if pid ~= PlayerId() then FreezeEntityPosition(GetPlayerPed(pid),true) end
            end
        end
        if Vars.AllPlayers.ExplodisionLoop then
            for _,pid in ipairs(GetActivePlayers()) do
                if pid ~= PlayerId() or Vars.AllPlayers.IncludeSelf then
                    if _G._ZeyPlayerAction then
                        _G._ZeyPlayerAction("explode", GetPlayerServerId(pid), 2)
                    else
                        local c = GetEntityCoords(GetPlayerPed(pid))
                        AddExplosion(c.x,c.y,c.z,2,100.0,true,false,0.0)
                    end
                end
            end
        end
    end
end)

-- ============================================================
-- THREAD FAKE DEATH
-- But: faire croire au SERVEUR que tu es mort
-- Toi tu joues normalement, tu peux mourir comme d hab
-- Quand tu desactives → serveur te voit vivant → reanimation
-- ============================================================

-- Thread principal: maintenir l etat "mort" cote serveur via injection
Citizen.CreateThread(function()
    while not killmenu do
        Citizen.Wait(1000)
        if Vars.Farm.FakeDeath then
            local ped = PlayerPedId()
            -- Injection type 3 dans resource legitime = bypass Seed/tokenisation
            -- Le serveur lit ces events et croit que le joueur est mort
            MachoInjectResource2(3, "any", string.format([[
                local ped = NetworkGetEntityFromNetworkId(%d)
                if not ped or ped == 0 then
                    ped = GetPlayerPed(PlayerId())
                end
                local c = GetEntityCoords(PlayerPedId())
                -- Events de mort standards ecoutes par tous les frameworks
                TriggerEvent("baseevents:onPlayerDied", PlayerPedId(), 0, c)
                TriggerEvent("onPlayerDied", GetPlayerServerId(PlayerId()))
                -- Events specifiques frameworks courants
                TriggerServerEvent("esx:playerDied")
                TriggerServerEvent("hospital:died")
                TriggerServerEvent("qb-hospital:server:SetDeathStatus", true)
            ]], NetworkGetNetworkIdFromEntity(ped)))
        end
    end
end)

-- ============================================================
-- THREAD TP DANS VEHICULE [E]
-- Cherche le vehicule occupe le plus proche SANS limite de distance
-- Teleporte dans la premiere place libre disponible
-- Utilise SetPedIntoVehicle = teleportation instantanee
-- ============================================================

Citizen.CreateThread(function()
    while not killmenu do
        Citizen.Wait(0)
        if Vars.Farm.TPVehicle then
            BeginTextCommandDisplayHelp("STRING")
            AddTextComponentSubstringPlayerName("~INPUT_JUMP~ TP Dans Vehicule")
            EndTextCommandDisplayHelp(0, false, false, -1)

            if IsControlJustPressed(0, 38) then
                local myPed  = PlayerPedId()
                local myC    = GetEntityCoords(myPed)

                -- Chercher le vehicule occupe le plus proche
                -- Pas de limite de distance volontairement = marche de tres loin
                local bestVeh, bestDist = nil, math.huge

                for _, veh in ipairs(GetGamePool("CVehicle")) do
                    if DoesEntityExist(veh) then
                        -- Vehicule doit avoir au moins un occupant
                        local hasOccupant = false
                        for seat = -1, GetVehicleMaxNumberOfPassengers(veh) do
                            local occ = GetPedInVehicleSeat(veh, seat)
                            if occ ~= 0 and DoesEntityExist(occ) and occ ~= myPed then
                                hasOccupant = true
                                break
                            end
                        end

                        if hasOccupant then
                            local d = #(myC - GetEntityCoords(veh))
                            if d < bestDist then
                                bestDist = d
                                bestVeh  = veh
                            end
                        end
                    end
                end

                if bestVeh then
                    -- Trouver la premiere place libre
                    local freeSeat = nil
                    local maxSeats = GetVehicleMaxNumberOfPassengers(bestVeh)

                    -- Verifier d abord les places passager
                    for seat = 0, maxSeats do
                        if IsVehicleSeatFree(bestVeh, seat) then
                            freeSeat = seat
                            break
                        end
                    end

                    -- Si aucune place passager libre, essayer le siege conducteur
                    if freeSeat == nil and IsVehicleSeatFree(bestVeh, -1) then
                        freeSeat = -1
                    end

                    if freeSeat ~= nil then
                        -- TP instantane dans le vehicule
                        -- SetPedIntoVehicle fonctionne meme a grande distance
                        SetPedIntoVehicle(myPed, bestVeh, freeSeat)

                        local driverPed = GetPedInVehicleSeat(bestVeh, -1)
                        local driverName = "inconnu"
                        for _, pid in ipairs(GetActivePlayers()) do
                            if GetPlayerPed(pid) == driverPed then
                                driverName = GetPlayerName(pid)
                                break
                            end
                        end

                        local seatLabel = freeSeat == -1 and "conducteur" or ("passager "..tostring(freeSeat+1))
                        MachoMenuNotification("TP Vehicule",
                            string.format("Entre chez %s — %s (%.0fm)",
                                driverName, seatLabel, bestDist))
                    else
                        MachoMenuNotification("TP Vehicule","Vehicule plein — aucune place libre")
                    end
                else
                    MachoMenuNotification("TP Vehicule","Aucun vehicule occupe trouve")
                end
            end
        else Citizen.Wait(100) end
    end
end)

-- ============================================================
-- THREAD ANTI-TP — Verrou de position
-- Memorise la position et la reforce si le moteur la change quand meme
-- Evite le mini-freeze en anticipant le rollback plutot qu'en le subissant
-- ============================================================

Citizen.CreateThread(function()
    local lockedPos  = nil
    local lockedHead = nil
    local lastNotif  = 0

    while not killmenu do
        if Vars.Farm.AntiTP then
            Citizen.Wait(0)
            local ped = PlayerPedId()
            local c   = GetEntityCoords(ped)

            if lockedPos == nil then
                -- Premiere frame avec AntiTP: memoriser la position actuelle
                lockedPos  = c
                lockedHead = GetEntityHeading(ped)
            else
                local drift = #(c - lockedPos)

                -- Si on a bouge normalement (input joueur) → mettre a jour la pos locked
                if IsControlPressed(0, 30) or IsControlPressed(0, 31) or
                   IsControlPressed(0, 32) or IsControlPressed(0, 33) or
                   IsPedInAnyVehicle(ped, false) then
                    lockedPos  = c
                    lockedHead = GetEntityHeading(ped)

                -- Si drift > 3m ET pas de mouvement joueur = TP force detecte
                elseif drift > 3.0 then
                    -- Retour position immediat sans animation = zero freeze visuel
                    SetEntityCoords(ped, lockedPos.x, lockedPos.y, lockedPos.z,
                        false, false, false, false)
                    SetEntityHeading(ped, lockedHead)

                    -- Notification max 1x/2sec pour ne pas spammer
                    local now = GetGameTimer()
                    if now - lastNotif > 2000 then
                        MachoMenuNotification("Anti-TP","TP bloque")
                        lastNotif = now
                    end
                else
                    -- Mouvement normal autorise
                    lockedPos  = c
                    lockedHead = GetEntityHeading(ped)
                end
            end
        else
            lockedPos  = nil
            lockedHead = nil
            Citizen.Wait(200)
        end
    end
end)

Citizen.CreateThread(function()
    while not killmenu do
        Citizen.Wait(500)
        _G._ZeyAntiTP = Vars.Farm.AntiTP
    end
end)

-- ============================================================
-- THREAD PED SPAM CRASH [E]
-- ============================================================

_G._ZeySpawnedPeds = {}

Citizen.CreateThread(function()
    local spamCooldown = false
    while not killmenu do
        Citizen.Wait(0)
        if Vars.Farm.PedSpam and not spamCooldown then
            BeginTextCommandDisplayHelp("STRING")
            AddTextComponentSubstringPlayerName("~INPUT_JUMP~ Ped Spam Crash")
            EndTextCommandDisplayHelp(0, false, false, -1)
            if IsControlJustPressed(0, 38) then
                spamCooldown = true
                local myPed = PlayerPedId()
                local myC   = GetEntityCoords(myPed)
                local bestPid, bestDist = nil, math.huge
                for _,pid in ipairs(GetActivePlayers()) do
                    if pid ~= PlayerId() then
                        local t = GetPlayerPed(pid)
                        if DoesEntityExist(t) then
                            local d = #(myC - GetEntityCoords(t))
                            if d < bestDist then bestDist=d; bestPid=pid end
                        end
                    end
                end
                if bestPid then
                    MachoMenuNotification("Ped Spam","Lancement sur "..GetPlayerName(bestPid).."...")
                    Citizen.CreateThread(function()
                        local models = {
                            GetHashKey("franklin"), GetHashKey("michael"),
                            GetHashKey("trevor"), GetHashKey("a_m_y_hipster_01"),
                            GetHashKey("a_m_m_business_01"), GetHashKey("a_f_y_beach_01"),
                            GetHashKey("s_m_y_cop_01"), GetHashKey("s_m_y_swat_01"),
                        }
                        for _,h in ipairs(models) do RequestModel(h) end
                        local waited = 0
                        while waited < 40 do
                            local ok = true
                            for _,h in ipairs(models) do
                                if not HasModelLoaded(h) then ok=false; break end
                            end
                            if ok then break end
                            Citizen.Wait(100); waited=waited+1
                        end
                        _G._ZeySpawnedPeds = {}
                        local targetPed = GetPlayerPed(bestPid)
                        for batch = 1, 8 do
                            if not DoesEntityExist(targetPed) then break end
                            local tc = GetEntityCoords(targetPed)
                            for i = 1, 40 do
                                local hash = models[math.random(1,#models)]
                                local ped = CreatePed(4, hash,
                                    tc.x+(math.random()-0.5)*0.2,
                                    tc.y+(math.random()-0.5)*0.2,
                                    tc.z, math.random(0,360), true, true)
                                if DoesEntityExist(ped) then
                                    SetEntityVisible(ped, false, false)
                                    SetEntityAlpha(ped, 0, false)
                                    SetEntityCollision(ped, false, false)
                                    FreezeEntityPosition(ped, true)
                                    AttachEntityToEntity(ped, targetPed,
                                        0, 0,0,0, 0,0,0,
                                        false,false,false,false,0,true)
                                    table.insert(_G._ZeySpawnedPeds, ped)
                                end
                            end
                            Citizen.Wait(50)
                        end
                        local count = #_G._ZeySpawnedPeds
                        MachoMenuNotification("Ped Spam",GetPlayerName(bestPid).." crash imminent ! ("..count.." peds)")
                        Citizen.Wait(20000)
                        for _,p in ipairs(_G._ZeySpawnedPeds) do
                            if DoesEntityExist(p) then DetachEntity(p,true,true); DeleteEntity(p) end
                        end
                        _G._ZeySpawnedPeds = {}
                        spamCooldown = false
                    end)
                else
                    MachoMenuNotification("Ped Spam","Aucun joueur trouve")
                    Citizen.Wait(1000); spamCooldown=false
                end
            end
        else Citizen.Wait(100) end
    end
end)

-- Script options
AddEventHandler("cmg3_animations:syncTarget",function()
    if Vars.Script.blocktakehostage then TriggerEvent("cmg3_animations:cl_stop") end
end)
AddEventHandler("CarryPeople:syncTarget",function()
    if Vars.Script.blockbeingcarried then TriggerEvent("CarryPeople:cl_stop") end
end)

MachoMenuNotification("ZeyMenu","Macho Edition charge — F11 pour ouvrir")
