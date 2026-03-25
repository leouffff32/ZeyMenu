local killmenu          = false
local SafeMode          = false
local selectedPlayer    = 0
local farmGhostVeh      = nil
local carjackCooldown   = false
local noclipping        = false
local spawninsidevehicle= true
local isSpectatingTarget= false
local PVAutoDriving     = false
_G._ZeyAntiTP = false
local _lastOwnedVeh = nil
local _KB_Binds       = {}
local _KB_UsedVK      = {}
local _KB_Assigning   = nil
local _KB_AssignLabel = ""
local _KB_PendingVK   = nil
local _KB_EnterReady  = false
local _KB_PrevEnter   = false
local _KB_Configs     = {}
local _KB_ItemCount   = 0
local _VK_Names = {
    [0x41]="A",[0x42]="B",[0x43]="C",[0x44]="D",[0x45]="E",
    [0x46]="F",[0x47]="G",[0x48]="H",[0x49]="I",[0x4A]="J",
    [0x4B]="K",[0x4C]="L",[0x4D]="M",[0x4E]="N",[0x4F]="O",
    [0x50]="P",[0x51]="Q",[0x52]="R",[0x53]="S",[0x54]="T",
    [0x55]="U",[0x56]="V",[0x57]="W",[0x58]="X",[0x59]="Y",
    [0x5A]="Z",
    [0x30]="0",[0x31]="1",[0x32]="2",[0x33]="3",[0x34]="4",
    [0x35]="5",[0x36]="6",[0x37]="7",[0x38]="8",[0x39]="9",
    [0x70]="F1",[0x71]="F2",[0x72]="F3",[0x73]="F4",[0x74]="F5",
    [0x75]="F6",[0x76]="F7",[0x77]="F8",[0x78]="F9",[0x79]="F10",
    [0x7A]="F11",[0x7B]="F12",
    [0x20]="SPACE",[0x0D]="ENTER",[0x08]="BACK",[0x09]="TAB",
    [0x10]="SHIFT",[0x11]="CTRL",[0x12]="ALT",
    [0x21]="PGUP",[0x22]="PGDN",[0x23]="END",[0x24]="HOME",
    [0x25]="LEFT",[0x26]="UP",[0x27]="RIGHT",[0x28]="DOWN",
    [0x2E]="DEL",[0x2D]="INS",
    [0x60]="NUM0",[0x61]="NUM1",[0x62]="NUM2",[0x63]="NUM3",
    [0x64]="NUM4",[0x65]="NUM5",[0x66]="NUM6",[0x67]="NUM7",
    [0x68]="NUM8",[0x69]="NUM9",[0x6A]="NUM*",[0x6B]="NUM+",
    [0x6D]="NUM-",[0x6E]="NUM.",[0x6F]="NUM/",
    [0xBB]="+",[0xBD]="-",[0xDB]="[",[0xDD]="]",
}
local _VK_Scan = {}
do
    local all = {}
    for vk=0x30,0x39 do all[#all+1]=vk end
    for vk=0x41,0x5A do all[#all+1]=vk end
    for vk=0x60,0x6F do all[#all+1]=vk end
    for vk=0x70,0x7B do all[#all+1]=vk end
    all[#all+1]=0x20
    local exclude={[0x79]=true,[0x2E]=true,[0x0D]=true,[0x08]=true,[0x26]=true,[0x28]=true}
    for _,v in ipairs(all) do
        if not exclude[v] then _VK_Scan[#_VK_Scan+1]=v end
    end
end
local function _KB_GetVKName(vk)
    return _VK_Names[vk] or string.format("0x%02X",vk)
end
local function _KB_PlaySound()
    PlaySoundFrontend(-1,"SELECT","HUD_FRONTEND_DEFAULT_SOUNDSET",true)
end
local function _KB_Unbind(uid)
    local b = _KB_Binds[uid]
    if b then
        _KB_UsedVK[b.vk] = nil
        _KB_Binds[uid]   = nil
    end
end
local function _KB_Bind(uid, vk, label, action)
    _KB_Unbind(uid)
    if _KB_UsedVK[vk] then
        return false, "Touche deja utilisee par: ".._KB_Binds[_KB_UsedVK[vk]].label
    end
    _KB_Binds[uid]    = {vk=vk, label=label, action=action}
    _KB_UsedVK[vk]    = uid
    return true
end
local function _KB_NewUID()
    _KB_ItemCount = _KB_ItemCount + 1
    return "kb_"..tostring(_KB_ItemCount)
end
local function _KB_SaveConfig()
    local data = {}
    for uid, b in pairs(_KB_Binds) do
        data[uid] = {vk=b.vk, label=b.label}
    end
    local idx = #_KB_Configs + 1
    _KB_Configs[idx] = {name=tostring(idx), binds=data}
    Notify("Config","Config "..idx.." sauvegardee !")
    _KB_RebuildConfigMenu()
end
local function _KB_LoadConfig(cfgIdx)
    local cfg = _KB_Configs[cfgIdx]
    if not cfg then return end
    _KB_Binds   = {}
    _KB_UsedVK  = {}
    local count = 0
    for uid, bdata in pairs(cfg.binds) do
        for _, menu in pairs(Menus) do
            for _, item in ipairs(menu.items) do
                if item._kb_uid == uid then
                    local ok = _KB_Bind(uid, bdata.vk, bdata.label, item.action or (function()
                        if item.type=="checkbox" then
                            local v = item.varTable[item.varKey]
                            if not v then
                                if item.onEnable then item.onEnable() end
                            else
                                if item.onDisable then item.onDisable() end
                            end
                            item.varTable[item.varKey] = not v
                        end
                    end))
                    if ok then count=count+1 end
                    break
                end
            end
        end
    end
    Notify("Config","Config "..cfgIdx.." chargee — "..count.." touches actives")
end
local function _KB_DeleteConfig(cfgIdx)
    table.remove(_KB_Configs, cfgIdx)
    for i,c in ipairs(_KB_Configs) do c.name=tostring(i) end
    Notify("Config","Config supprimee")
    _KB_RebuildConfigMenu()
end
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
        Waterproof=false, ZeyMenuplate=false,
        rainbowcar=false, speedometer=false, EasyHandling=false,
        DriveOnWater=false, AlwaysWheelie=false, AutoClean=false,
        forcelauncontrol=false, NoBikeFall=false,
        AutoPilot={CruiseSpeed=50.0, DrivingStyle=6},
    },
    Farm = {
        Carjack=false, CarjackDist=false, CarjackDistV2=false,
        SoloSession=false, VoirJoueur=false,
        VehicleInvisible=false, AutoInvisible=false, PassagerVisible=false,
        CollisionVehicule=true, FDescendreJoueur=false,
        AntiTP=false, AntiTPv2=false, AntiTPv3=false, KickVehicule=false, TPVehicule=false, ExplosVehicule=false, ExplosVehicule2=false, EjectPassagers=false, StealthVehicule=false, TireDetach=false, AutoStealDriver=false,
        CollisionSteal=false, CollisionExplod=false, CollisionExplodV2=false,
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
            Enabled=false, Bone="SKEL_HEAD",
            ThroughWalls=false, DrawFOV=true,
            FOV=0.50, OnlyPlayers=false, IgnoreFriends=true,
            Distance=1000.0, InvisibilityCheck=true,
        },
    },
    Misc = {
        ESPBox=true, ESPName=false, ESPLines=false,
        ESPBones=false, ESPDistance=1000.0,
        UnlockAllVehicles=false, FlyingCars=false,
    },
    Script = {
        blocktakehostage=false, BlockBlackScreen=false,
        blockbeingcarried=false, BlockPeacetime=false,
        GGACBypass=false, SSBBypass=false,
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
    },
    Player = {
        ExplosionType=1,
        playertofreeze=nil, freezeplayer=false,
        ExplosionLoop=false, ExplodingPlayer=nil,
        attachtoplayer=false,
    },
    AllPlayers = {
        IncludeSelf=true, freezeserver=false,
        ExplodisionLoop=false, busingserverloop=false,
        cargoplaneserverloop=false,
    },
    MenuOptions={Watermark=false},
    VehicleLock = {
        LockNearby=false,
        LockSelf=false,
        lastOwnedVeh=nil,
    },
    MiscExtra = {
        AntiScreenshot=false,
        EventLogger=false,
        FakeDeath=false,
    },
}
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
if not Susano.HasNativeHookInitializationFailed() then
Susano.HookNative(0x6D0DE6A7B5DA71F8, function(player_id)
    if player_id == PlayerId() and SafeMode then
        return false, "Player_"..tostring(math.random(1000,9999))
    end
    return true
end)
Susano.HookNative(0x764B79499032D916, function()
    return false, true
end)
Susano.HookNative(0xE28B54053A4C5A6B, function(player)
    if Vars.Self.FreezeWantedLevel and player == PlayerId() then
        return false, 0
    end
    return true
end)
_G._ZeyFakePos   = nil
_G._ZeyV3Spoof   = false
_G._ZeyFakeHeading = nil
_G._ZeyFakeSpeed = 1.5
_G._ZeySpoofing  = false

-- [ANTI-TP] SET_ENTITY_COORDS — bloquer tout TP externe > 0.5m
Susano.HookNative(0x06843DA7060A026B, function(entity, x, y, z, p3, p4, p5, p6)
    if entity == PlayerPedId() and Vars.Farm.AntiTP then
        local c = GetEntityCoords(entity)
        if #(c - vector3(x,y,z)) > 0.5 then
            return false
        end
    end
    return true
end)

-- [ANTI-TP] SET_ENTITY_COORDS_NO_OFFSET
Susano.HookNative(0x239A3351AC1DA385, function(entity, x, y, z, p3, p4, p5)
    if entity == PlayerPedId() and Vars.Farm.AntiTP then
        local c = GetEntityCoords(entity)
        if #(c - vector3(x,y,z)) > 0.5 then
            return false
        end
    end
    return true
end)

-- [ANTI-FREEZE] FREEZE_ENTITY_POSITION
Susano.HookNative(0x428CA6DBD1094446, function(entity, toggle)
    if entity == PlayerPedId() and Vars.Farm.AntiTP and toggle == true then
        return false
    end
    return true
end)

-- [ANTI-TP] NETWORK_RESURRECT_LOCAL_PLAYER
Susano.HookNative(0x2959F695A6D1A7E5, function(x, y, z)
    if Vars.Farm.AntiTP then
        local c = GetEntityCoords(PlayerPedId())
        if #(c - vector3(x,y,z)) > 0.5 then
            return false
        end
    end
    return true
end)

-- [ANTI-TP] TASK_GO_TO_COORD_ANY_MEANS
Susano.HookNative(0x5BC448CB78FA3E88, function(ped)
    if Vars.Farm.AntiTP and ped == PlayerPedId() then
        return false
    end
    return true
end)

-- [ANTI-TP] SET_PED_COORDS_KEEP_VEHICLE (0x9AFEFF481A85AB2E)
Susano.HookNative(0x9AFEFF481A85AB2E, function(ped, x, y, z)
    if ped == PlayerPedId() and Vars.Farm.AntiTP then
        local c = GetEntityCoords(ped)
        if #(c - vector3(x,y,z)) > 0.5 then
            return false
        end
    end
    return true
end)

-- [ANTI-TP] DETACH_ENTITY — empeche de nous detacher
Susano.HookNative(0xF6A9D9708F6F23DF, function(entity)
    if entity == PlayerPedId() and Vars.Farm.AntiTP then
        return false, 0
    end
    return true
end)

-- [ANTI-TP] APPLY_DAMAGE_TO_PED — empecher degats forces
Susano.HookNative(0xA40B8C0B8F0B952E, function(ped, dmg, p2, p3)
    if ped == PlayerPedId() and Vars.Farm.AntiTP then
        return false
    end
    return true
end)



-- [SPEED SPOOF] GET_ENTITY_SPEED — simuler vitesse de marche
Susano.HookNative(0x6D5BCA5B13E72F3B, function(entity)
    if entity == PlayerPedId() and (_G._ZeySpoofing or _G._ZeyV3Spoof) then
        return false, 1.2 + math.random() * 0.6
    end
    return true
end)

-- [HEADING SPOOF] GET_ENTITY_HEADING — garder heading fixe pour V3
Susano.HookNative(0xE83D4F9BA2A38914, function(entity)
    if entity == PlayerPedId() and _G._ZeyV3Spoof and _G._ZeyFakeHeading then
        return false, _G._ZeyFakeHeading
    end
    return true
end)

-- [VEH GODMODE]
Susano.HookNative(0xC45D23BAF168AAB8, function(vehicle)
    if Vars.Vehicle.vehgodmode then
        local myVeh = GetVehiclePedIsIn(PlayerPedId(), false)
        if vehicle == myVeh then return false, 1000.0 end
    end
    return true
end)
Susano.HookNative(0xF271147EB7B40F12, function(vehicle)
    if Vars.Vehicle.vehgodmode then
        local myVeh = GetVehiclePedIsIn(PlayerPedId(), false)
        if vehicle == myVeh then return false, 1000.0 end
    end
    return true
end)
end
Citizen.CreateThread(function()
    local lastNormalPos = nil
    local spoofTimer    = 0
    local SPOOF_DURATION = 4000
    while not killmenu do
        Citizen.Wait(0)
        local ped = PlayerPedId()
        local c   = GetEntityCoords(ped)

        if noclipping then
            -- En noclip: activer spoof avec derniere position normale
            if not _G._ZeySpoofing then
                _G._ZeyFakePos = lastNormalPos or c
            end
            _G._ZeySpoofing = true
        elseif Vars.Farm.AntiTP then
            -- AntiTP V1 actif: spoof permanent avec position qui suit lentement
            -- On met a jour la fake pos en avance lente pour pas paraitre statique
            if not _G._ZeySpoofing then
                _G._ZeyFakePos  = lastNormalPos or c
                _G._ZeySpoofing = true
            else
                -- Faire avancer doucement la fake pos vers la vraie pos
                -- pour que l'AC voie un mouvement plausible
                if _G._ZeyFakePos and not _G._ZeyV3Spoof then
                    local fp = _G._ZeyFakePos
                    local dx = c.x - fp.x
                    local dy = c.y - fp.y
                    local dist = math.sqrt(dx*dx + dy*dy)
                    if dist > 2.0 then
                        -- Deplacer la fake pos a max 1.5m par frame vers la vraie
                        local step = math.min(1.5 / dist, 1.0)
                        _G._ZeyFakePos = vector3(
                            fp.x + dx * step * 0.01,
                            fp.y + dy * step * 0.01,
                            c.z
                        )
                    end
                end
            end
            lastNormalPos = c
        else
            -- Ni noclip ni AntiTP: detecter TP personnel (> 20m) et spoof post-TP
            if lastNormalPos and not _G._ZeyV3Spoof then
                if #(c - lastNormalPos) > 20.0 then
                    _G._ZeyFakePos  = lastNormalPos
                    _G._ZeySpoofing = true
                    spoofTimer      = GetGameTimer() + SPOOF_DURATION
                end
            end
            if _G._ZeySpoofing and not _G._ZeyV3Spoof then
                if GetGameTimer() > spoofTimer then
                    _G._ZeySpoofing = false
                    _G._ZeyFakePos  = nil
                end
            else
                lastNormalPos = c
            end
        end
    end
end)
Citizen.CreateThread(function()
    local speed      = 0.5
    local speedBoost = 3.0
    local prevF9     = false
    local wasActive  = false
    while not killmenu do
        Citizen.Wait(0)
        local dF9, pF9 = Susano.GetAsyncKeyState(0x78)
        if pF9 and not prevF9 then
            noclipping = not noclipping
            if noclipping then
                Notify("Noclip","Actif [F9] — ZQSD+Souris, Shift=boost")
                wasActive = true
            else
                Notify("Noclip","Desactive")
            end
        end
        prevF9 = dF9
        if noclipping then
            local ped = PlayerPedId()
            if not _G._ZeyRealPos then
                local initPos = GetEntityCoords(ped)
                if _G._ZeyFakePos then
                    _G._ZeyRealPos = _G._ZeyFakePos
                else
                    _G._ZeyRealPos = vector3(initPos.x, initPos.y, initPos.z)
                end
            end
            SetEntityVisible(ped, false, false)
            SetEntityCollision(ped, false, false)
            SetEntityInvincible(ped, true)
            FreezeEntityPosition(ped, true)
            if not Menu.open then
                DisableAllControlActions(0)
                EnableControlAction(0, 1, true)
                EnableControlAction(0, 2, true)
            end
            local cx, cy, cz = Susano.GetCameraAngles()
            local yawRad   = math.rad(cz)
            local pitchRad = math.rad(cx)
            local fwdX =  -math.sin(yawRad) * math.cos(pitchRad)
            local fwdY =   math.cos(yawRad) * math.cos(pitchRad)
            local fwdZ =   math.sin(pitchRad)
            local rightX =  math.cos(yawRad)
            local rightY =  math.sin(yawRad)
            local dShift, _ = Susano.GetAsyncKeyState(0xA0)
            local spd = dShift and speedBoost or speed
            local dZ, _ = Susano.GetAsyncKeyState(0x5A)
            local dS, _ = Susano.GetAsyncKeyState(0x53)
            local dQ, _ = Susano.GetAsyncKeyState(0x51)
            local dD, _ = Susano.GetAsyncKeyState(0x44)
            local dSpc,_ = Susano.GetAsyncKeyState(0x20)
            local dCtl,_ = Susano.GetAsyncKeyState(0x11)
            local mx, my, mz = 0.0, 0.0, 0.0
            if dZ   then mx=mx+fwdX*spd;  my=my+fwdY*spd;  mz=mz+fwdZ*spd  end
            if dS   then mx=mx-fwdX*spd;  my=my-fwdY*spd;  mz=mz-fwdZ*spd  end
            if dD   then mx=mx+rightX*spd; my=my+rightY*spd                  end
            if dQ   then mx=mx-rightX*spd; my=my-rightY*spd                  end
            if dSpc then mz=mz+spd end
            if dCtl then mz=mz-spd end
            local pos = _G._ZeyRealPos or GetEntityCoords(ped)
            if mx ~= 0.0 or my ~= 0.0 or mz ~= 0.0 then
                local nx = pos.x + mx
                local ny = pos.y + my
                local nz = pos.z + mz
                _G._ZeyRealPos = vector3(nx, ny, nz)
                SetEntityCoordsNoOffset(ped, nx, ny, nz, false, false, false)
                Susano.LockCameraPos(true)
                Susano.SetCameraPos(nx, ny, nz + 0.5)
            else
                _G._ZeyRealPos = pos
            end
        elseif wasActive then
            wasActive = false
            _G._ZeyRealPos = nil
            local ped = PlayerPedId()
            SetEntityVisible(ped, true, false)
            SetEntityCollision(ped, true, false)
            SetEntityInvincible(ped, false)
            FreezeEntityPosition(ped, false)
            Susano.LockCameraPos(false)
        end
    end
end)
Susano.InjectResource("any", [[
    AddEventHandler("screenshot_basic:requestScreenshot", function() CancelEvent() end)
    AddEventHandler("EasyAdmin:CaptureScreenshot", function()
        TriggerServerEvent("EasyAdmin:TookScreenshot","ERROR"); CancelEvent()
    end)
    AddEventHandler("requestScreenshot", function() CancelEvent() end)
    AddEventHandler("requestScreenshotUpload", function() CancelEvent() end)
    AddEventHandler("EasyAdmin:FreezePlayer", function()
        TriggerEvent("EasyAdmin:FreezePlayer", false)
    end)
]], Susano.InjectionType.NEW_THREAD)
Susano.InjectResource("any", [[
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
]], Susano.InjectionType.NEW_THREAD)
Susano.OnTriggerServerEvent(function(name, payload)
    if not name then return end
    local _blocked = {
        ["blev"]=true,["iven"]=true,["it"]=true,["rf"]=true,
        ["fc"]=true,["rcm"]=true,["sm"]=true,["tk"]=true,
        ["st"]=true,["hb"]=true,
    }
    if _blocked[name] then return false end
    local nl = string.lower(tostring(name))
    local _patterns = {
        "seed","guardian","warden","watchdog","sentry",
        "rageshit","crash_reporter","bans:report","bans:flag",
        "anticheat","violation","screenshot:url",
        "discord:log","logs:send",
        -- Rollback patterns Guardian/Watchdog specifiques
        "rollback","revert","restore","teleport","setcoord",
        "forcetp","forcemove","punish","kick","ban",
        "sync:pos","pos:sync","position:set","coord:set",
        "wd:","gd:","ac:","sentry:","wdog:",
    }
    for _, p in ipairs(_patterns) do
        if string.find(nl, p, 1, true) then return false end
    end
    return name, payload
end)
local _notifQueue = {}
local function Notify(title, msg)
    table.insert(_notifQueue, {
        title  = tostring(title),
        msg    = tostring(msg),
        until_ = GetGameTimer() + 3500,
    })
    while #_notifQueue > 5 do table.remove(_notifQueue, 1) end
end
local function RenderNotifications(sW, sH)
    local now = GetGameTimer()
    local ny  = sH * 0.84
    local i = #_notifQueue
    while i >= 1 do
        local n = _notifQueue[i]
        if now > n.until_ then
            table.remove(_notifQueue, i)
        else
            Susano.DrawRectFilled(12, ny, sW * 0.20, 42, 0, 0, 0, 0.85, 0)
            Susano.DrawRectFilled(12, ny, 4, 42, 0.12, 0.56, 1.0, 1.0, 0)
            Susano.DrawText(20, ny + 5,  n.title, 15, 0.12, 0.56, 1.0, 1.0)
            Susano.DrawText(20, ny + 24, n.msg,   14, 0.9,  0.9,  0.9, 0.9)
            ny = ny - 50
        end
        i = i - 1
    end
end
local SW, SH = 1920, 1080
local Menu = {
    open        = false,
    currentMenu = nil,
    cursorIndex = 1,
    scroll      = 0,
    maxVisible  = 14,
    x     = SW * 0.78,
    y     = SH * 0.04,
    w     = 390,
    titleH= 90,
    itemH = 38,
    textSz= 21,
    rgb   = {r=0.12, g=0.56, b=1.0},
}
local Menus     = {}
local breadcrumb= {}
local function CreateMenu(id, title, parent)
    Menus[id] = {title=title, parent=parent, items={}}
end
local function AddItem(menuId, item)
    if Menus[menuId] then
        table.insert(Menus[menuId].items, item)
    end
end
local function MB(menuId, label, subtext, action)
    local uid = _KB_NewUID()
    AddItem(menuId, {type="button", label=label, subtext=subtext or "", action=action, _kb_uid=uid})
end
local function MC(menuId, label, varTable, varKey, onEnable, onDisable)
    local uid = _KB_NewUID()
    AddItem(menuId, {type="checkbox", label=label, varTable=varTable, varKey=varKey,
        onEnable=onEnable, onDisable=onDisable, _kb_uid=uid})
end
local function MS(menuId, label, subtext, targetId)
    local uid = _KB_NewUID()
    AddItem(menuId, {type="submenu", label=label, subtext=subtext or "", targetId=targetId, _kb_uid=uid})
end
local function GetChecked(item)
    if item.varTable == nil or item.varKey == nil then return false end
    if type(item.varTable) ~= "table" then return false end
    return item.varTable[item.varKey] == true
end
local function KillMenu()
    Menu.open = false
    killmenu  = true
    Susano.ResetAllFrames()
    Susano.UnhookAllNatives()
    Susano.ClearOnTriggerServerEvent()
end
CreateMenu("main", "ZeyMenu", nil)
MS("main", "New",                   "Collision / Anti-TP / Kick Veh",   "new")
MS("main", "Farm",                  "Carjack / Solo Session / Ghost",   "farm")
MS("main", "Online Player Options", "Individual / All Players",         "players")
MS("main", "Self Options",          "Godmode / Super Powers",           "self")
MS("main", "Vehicle Options",       "Spawn / Godmode / Rainbow",        "vehicle")
MS("main", "Teleport Options",      "Waypoint / Ocean / Coords",        "teleport")
MS("main", "Weapon Options",        "Ammo / AimBot / Explosive",        "weapon")
MS("main", "World Options",         "Weather / Time / Flying Cars",     "world")
MS("main", "Misc Options",          "ESP / AntiCheat / Extra",          "misc")
MS("main", "Trigger",               "Unity / Unity Legacy / Safe",      "trigger")
MS("main", "Settings",              "Watermark / Config / Kill Menu",   "settings")
MB("main", "Kill Menu",             "Fermer le menu", function() KillMenu() end)
CreateMenu("new", "New", "main")
MC("new","Collision Vehicule",Vars.Farm,"CollisionVehicule",
    function() Vars.Farm.CollisionVehicule=true end,
    function() Vars.Farm.CollisionVehicule=false end)
MC("new","F Descendre Joueur",Vars.Farm,"FDescendreJoueur",
    function() Vars.Farm.FDescendreJoueur=true end,
    function() Vars.Farm.FDescendreJoueur=false end)
MC("new","Anti-TP",Vars.Farm,"AntiTP",
    function() Vars.Farm.AntiTP=true; _G._ZeyAntiTP=true end,
    function() Vars.Farm.AntiTP=false; _G._ZeyAntiTP=false end)
MC("new","Anti-TP V2 [Inject SEED]",Vars.Farm,"AntiTPv2",
    function()
        Vars.Farm.AntiTPv2=true
        Citizen.CreateThread(function()
            -- Trouver Guardian / Watchdog / Seed
            local acRes=nil
            for i=0,GetNumResources()-1 do
                local r=GetResourceByFindIndex(i)
                if r then
                    local rL=string.lower(r)
                    if (string.find(rL,"seed") or string.find(rL,"warden") or
                        string.find(rL,"watchdog") or string.find(rL,"guardian"))
                       and not string.find(rL,"underdog") then
                        acRes=r; break
                    end
                end
            end

            -- === INJECTION 1: dans l'AC directement ===
            if acRes then
                Susano.InjectResource(acRes,[[
                    -- Neutraliser toutes les fonctions de rollback/TP connues
                    local _rollbackFns = {
                        "rollback","Rollback","RollBack","rollBack",
                        "teleportPlayer","TeleportPlayer","tpPlayer","TPPlayer",
                        "forceTP","ForceTP","forceTp","force_tp",
                        "setPlayerCoords","SetPlayerCoords","setCoords",
                        "antiCheatTP","anticheatTp","acTeleport","ACTeleport",
                        "revertPosition","RevertPosition","revert_pos",
                        "restorePosition","RestorePosition","restore_pos",
                        "punishPlayer","PunishPlayer","punish","Punish",
                        "kickPlayer","KickPlayer","banPlayer","BanPlayer",
                        "warpPlayer","WarpPlayer","movePlayer","MovePlayer",
                        "resetPosition","ResetPosition","reset_pos",
                        "correctPosition","CorrectPosition","fixPosition",
                    }
                    for _,fn in ipairs(_rollbackFns) do
                        if type(_G[fn])=="function" then _G[fn]=function(...) end end
                    end

                    -- Bloquer SetEntityCoords appele par l'AC sur nous
                    local _oSEC=SetEntityCoords
                    SetEntityCoords=function(entity,x,y,z,...)
                        if entity==PlayerPedId() then
                            local c=GetEntityCoords(entity)
                            local d=math.sqrt((x-c.x)^2+(y-c.y)^2+(z-c.z)^2)
                            if d>0.5 then return end
                        end
                        return _oSEC(entity,x,y,z,...)
                    end

                    -- Bloquer NRLP (rollback via respawn)
                    local _oNRLP=NetworkResurrectLocalPlayer
                    NetworkResurrectLocalPlayer=function(x,y,z,...)
                        local c=GetEntityCoords(PlayerPedId())
                        local d=math.sqrt((x-c.x)^2+(y-c.y)^2+(z-c.z)^2)
                        if d>0.5 then return end
                        return _oNRLP(x,y,z,...)
                    end

                    -- Bloquer FreezeEntityPosition force
                    local _oFEP=FreezeEntityPosition
                    FreezeEntityPosition=function(entity,toggle)
                        if entity==PlayerPedId() and toggle then return end
                        return _oFEP(entity,toggle)
                    end

                    -- Bloquer les events internes de rollback
                    local _oTE=TriggerEvent
                    TriggerEvent=function(n,...)
                        if not n then return _oTE(n,...) end
                        local nl=string.lower(tostring(n))
                        if string.find(nl,"rollback") or string.find(nl,"revert") or
                           string.find(nl,"restore") or string.find(nl,"punish") or
                           string.find(nl,"teleport") or string.find(nl,"setcoord") or
                           string.find(nl,"warp") or string.find(nl,"reset") then
                            return
                        end
                        return _oTE(n,...)
                    end

                    -- Bloquer TriggerServerEvent de rapport/ban
                    local _oTSE=TriggerServerEvent
                    TriggerServerEvent=function(n,...)
                        if not n then return _oTSE(n,...) end
                        local nl=string.lower(tostring(n))
                        if string.find(nl,"ban") or string.find(nl,"kick") or
                           string.find(nl,"report") or string.find(nl,"flag") or
                           string.find(nl,"violation") or string.find(nl,"detect") then
                            return
                        end
                        return _oTSE(n,...)
                    end

                    -- Vider les tables de detection si elles existent
                    if _G.detections then _G.detections={} end
                    if _G.violations then _G.violations={} end
                    if _G.flags then _G.flags={} end
                    if _G.CFG and _G.CFG.BlockedWeapons then _G.CFG.BlockedWeapons={} end
                    if _G.SEED then _G.SEED.GetWeaponFromHash=function() return nil end end

                    -- Thread de maintien: vider detections en continu
                    Citizen.CreateThread(function()
                        while true do
                            Citizen.Wait(1000)
                            if _G.detections then _G.detections={} end
                            if _G.violations then _G.violations={} end
                            if _G.flags then _G.flags={} end
                        end
                    end)
                ]], Susano.InjectionType.NEW_THREAD)
            end

            -- === INJECTION 2: dans "any" (tous les resources) ===
            Citizen.Wait(200)
            Susano.InjectResource("any",[[
                local _oSEC=SetEntityCoords
                SetEntityCoords=function(entity,x,y,z,...)
                    if entity==PlayerPedId() then
                        local c=GetEntityCoords(entity)
                        local d=math.sqrt((x-c.x)^2+(y-c.y)^2+(z-c.z)^2)
                        if d>0.5 then return end
                    end
                    return _oSEC(entity,x,y,z,...)
                end
                local _oNRLP=NetworkResurrectLocalPlayer
                NetworkResurrectLocalPlayer=function(x,y,z,...)
                    local c=GetEntityCoords(PlayerPedId())
                    local d=math.sqrt((x-c.x)^2+(y-c.y)^2+(z-c.z)^2)
                    if d>0.5 then return end
                    return _oNRLP(x,y,z,...)
                end
                local _oFEP=FreezeEntityPosition
                FreezeEntityPosition=function(entity,toggle)
                    if entity==PlayerPedId() and toggle then return end
                    return _oFEP(entity,toggle)
                end
                local _oTE=TriggerEvent
                TriggerEvent=function(n,...)
                    if not n then return _oTE(n,...) end
                    local nl=string.lower(tostring(n))
                    if string.find(nl,"rollback") or string.find(nl,"revert") or
                       string.find(nl,"restore") or string.find(nl,"punish") or
                       string.find(nl,"teleport") or string.find(nl,"setcoord") then
                        return
                    end
                    return _oTE(n,...)
                end
            ]], Susano.InjectionType.NO_THREAD)

            Notify("Anti-TP V2", acRes and ("Injection OK: "..acRes) or "Injection globale OK")
        end)
    end,
    function()
        Vars.Farm.AntiTPv2=false
        Notify("Anti-TP V2","Desactive")
    end)
MC("new","Anti-TP V3 [Position Freeze]",Vars.Farm,"AntiTPv3",
    function()
        Vars.Farm.AntiTPv3=true
        local ped = PlayerPedId()
        local c   = GetEntityCoords(ped)
        _G._ZeyFakePos     = c
        _G._ZeyFakeHeading = GetEntityHeading(ped)
        _G._ZeyV3Spoof     = true
        Notify("Anti-TP V3","Position figee — tu bouges librement, le serv te voit fixe")
    end,
    function()
        Vars.Farm.AntiTPv3=false
        _G._ZeyV3Spoof  = false
        if not _G._ZeySpoofing then
            _G._ZeyFakePos     = nil
            _G._ZeyFakeHeading = nil
        end
        Notify("Anti-TP V3","Desactive — position reelle visible")
    end)
MC("new","Kick Vehicule [E]",Vars.Farm,"KickVehicule",
    function() Vars.Farm.KickVehicule=true end,
    function() Vars.Farm.KickVehicule=false end)
MC("new","TP Dans Vehicule [E]",Vars.Farm,"TPVehicule",
    function() Vars.Farm.TPVehicule=true end,
    function() Vars.Farm.TPVehicule=false end)
MC("new","Explose Vehicule [E]",Vars.Farm,"ExplosVehicule",
    function() Vars.Farm.ExplosVehicule=true; Notify("Explose Veh","[E] TP dans le veh puis explosion") end,
    function() Vars.Farm.ExplosVehicule=false end)
MC("new","Explose Vehicule V2 [E]",Vars.Farm,"ExplosVehicule2",
    function() Vars.Farm.ExplosVehicule2=true; Notify("Explose Veh V2","[E] TP dans le veh, explose des conducteur detecte") end,
    function() Vars.Farm.ExplosVehicule2=false end)
MC("new","Collision Steal [Auto]",Vars.Farm,"CollisionSteal",
    function() Vars.Farm.CollisionSteal=true; Notify("Collision Steal","Actif — collision = TP conducteur auto + retour veh") end,
    function() Vars.Farm.CollisionSteal=false end)
MC("new","Collision Explod [Auto]",Vars.Farm,"CollisionExplod",
    function() Vars.Farm.CollisionExplod=true; Notify("Collision Explod","Actif — collision = TP dans veh puis explosion") end,
    function() Vars.Farm.CollisionExplod=false end)
MC("new","Collision Explod V2 [Auto]",Vars.Farm,"CollisionExplodV2",
    function() Vars.Farm.CollisionExplodV2=true; Notify("Collision Explod V2","Actif — collision = TP conducteur + explosion reseau visible") end,
    function() Vars.Farm.CollisionExplodV2=false end)
MC("new","Tire Detach [E]",Vars.Farm,"TireDetach",
    function() Vars.Farm.TireDetach=true; Notify("Tire Detach","[E] sur un vehicule proche = roues enlevees") end,
    function() Vars.Farm.TireDetach=false end)
MC("new","Auto Steal Driver",Vars.Farm,"AutoStealDriver",
    function() Vars.Farm.AutoStealDriver=true; Notify("Auto Steal","Monte comme passager, le conducteur sera ejecte auto") end,
    function() Vars.Farm.AutoStealDriver=false end)
MC("new","Stealth Vehicule [E]",Vars.Farm,"StealthVehicule",
    function() Vars.Farm.StealthVehicule=true end,
    function() Vars.Farm.StealthVehicule=false end)
MC("new","Eject Passagers [A]",Vars.Farm,"EjectPassagers",
    function() Vars.Farm.EjectPassagers=true end,
    function() Vars.Farm.EjectPassagers=false end)
CreateMenu("farm", "Farm", "main")
MC("farm","Carjack",Vars.Farm,"Carjack",
    function() Vars.Farm.Carjack=true end,
    function() Vars.Farm.Carjack=false end)
MC("farm","Carjack Distance [E] PNJ+Joueurs",Vars.Farm,"CarjackDist",
    function() Vars.Farm.CarjackDist=true; Vars.Farm.CarjackDistV2=false end,
    function() Vars.Farm.CarjackDist=false end)
MC("farm","Carjack Distance V2 [E] Joueurs",Vars.Farm,"CarjackDistV2",
    function() Vars.Farm.CarjackDistV2=true; Vars.Farm.CarjackDist=false end,
    function() Vars.Farm.CarjackDistV2=false end)
MC("farm","Solo Session",Vars.Farm,"SoloSession",
    function()
        Vars.Farm.SoloSession=true
        Citizen.Wait(1000); NetworkBail()
    end,
    function()
        Vars.Farm.SoloSession=false; Vars.Farm.VoirJoueur=false
        Citizen.CreateThread(function()
            local t=0
            while t<10 do
                NetworkBail(); t=t+1; Citizen.Wait(6000)
                if #GetActivePlayers()>1 then
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
MS("farm","Options Solo Session","Voir Joueur","solosession")
MC("farm","Vehicule Invisible",Vars.Farm,"VehicleInvisible",
    function()
        Vars.Farm.VehicleInvisible=true
        Vars.Farm.AutoInvisible=true
    end,
    function()
        Vars.Farm.VehicleInvisible=false
        Vars.Farm.AutoInvisible=false
        if farmGhostVeh and DoesEntityExist(farmGhostVeh) then
            SetEntityVisible(farmGhostVeh,true,false)
            SetEntityCollision(farmGhostVeh,true,false)
        end
        farmGhostVeh=nil
    end)
MS("farm","Options Vehicule Invisible","Auto / Passager","ghostopts")
CreateMenu("solosession","Options Solo Session","farm")
MC("solosession","Voir Joueur",Vars.Farm,"VoirJoueur",
    function() Vars.Farm.VoirJoueur=true end,
    function() Vars.Farm.VoirJoueur=false end)
CreateMenu("ghostopts","Options Vehicule Invisible","farm")
MC("ghostopts","Auto Invisible",Vars.Farm,"AutoInvisible",
    function() Vars.Farm.AutoInvisible=true end,
    function() Vars.Farm.AutoInvisible=false end)
MC("ghostopts","Passager Visible",Vars.Farm,"PassagerVisible",
    function() Vars.Farm.PassagerVisible=true end,
    function() Vars.Farm.PassagerVisible=false end)
CreateMenu("players","Online Player Options","main")
MS("players","All Player Options","Tous les joueurs","allplayers")
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
    function() isSpectatingTarget=true; NetworkSetInSpectatorMode(true,GetPlayerPed(selectedPlayer)) end,
    function() isSpectatingTarget=false; NetworkSetInSpectatorMode(false,PlayerPedId()) end)
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
CreateMenu("allplayers","All Player Options","players")
MC("allplayers","Include Self","",nil,
    function() Vars.AllPlayers.IncludeSelf=true end,
    function() Vars.AllPlayers.IncludeSelf=false end)
MB("allplayers","Exploser Tout le Monde","", function()
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
MC("self","Anti Headshot",Vars.Self,"AntiHeadshot",
    function() Vars.Self.AntiHeadshot=true end,
    function() Vars.Self.AntiHeadshot=false; SetPedSuffersCriticalHits(PlayerPedId(),true) end)
MC("self","Thermal Vision","",nil,
    function() SetSeethrough(true) end,
    function() SetSeethrough(false) end)
MC("self","Night Vision","",nil,
    function() SetNightvision(true) end,
    function() SetNightvision(false) end)
MB("self","Toggle Noclip [F9]","ZQSD + Souris, Shift=rapide", function()
    noclipping = not noclipping
    if noclipping then
        Notify("Noclip","Actif — ZQSD bouge, souris dirige, Shift=boost")
    else
        Notify("Noclip","Desactive")
    end
end)
MB("self","Refill Health","", function() SetEntityHealth(PlayerPedId(),200) end)
MB("self","Refill Armour","", function() SetPedArmour(PlayerPedId(),100) end)
MB("self","Force Revive","", function()
    local c=GetEntityCoords(PlayerPedId())
    NetworkResurrectLocalPlayer(c.x,c.y,c.z,GetEntityHeading(PlayerPedId()),true,false)
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
MB("vehicle","Lock Vehicule Proche [E]","Verrouillement natif + injection", function()
    Vars.VehicleLock.LockNearby = not Vars.VehicleLock.LockNearby
    if Vars.VehicleLock.LockNearby then
        Notify("Lock Veh [E]","Actif — [E] sur un vehicule proche le verrouille/deverrouille")
    else
        Notify("Lock Veh [E]","Desactive")
    end
end)
MC("vehicle","Lock Vehicule V2 [Auto]",Vars.VehicleLock,"LockSelf",
    function()
        Vars.VehicleLock.LockSelf=true
        local v=GetVehiclePedIsIn(PlayerPedId(),false)
        if v~=0 then _lastOwnedVeh=v; Vars.VehicleLock.lastOwnedVeh=v end
        Notify("Lock Veh V2","Actif — verrouille ton veh ou le dernier conduit")
    end,
    function()
        Vars.VehicleLock.LockSelf=false
        Notify("Lock Veh V2","Desactive")
    end)
MC("vehicle","ZeyMenu Plate",Vars.Vehicle,"ZeyMenuplate",
    function() Vars.Vehicle.ZeyMenuplate=true end,
    function() Vars.Vehicle.ZeyMenuplate=false end)
local function SpawnVeh(model)
    local hash = GetHashKey(model)
    RequestModel(hash)
    Citizen.CreateThread(function()
        local t = 0
        while not HasModelLoaded(hash) and t < 50 do Citizen.Wait(100); t=t+1 end
        if not HasModelLoaded(hash) then Notify("Spawn","Modele introuvable: "..model); return end
        local ped = PlayerPedId()
        local c   = GetEntityCoords(ped)
        local h   = GetEntityHeading(ped)
        local v   = Susano.CreateSpoofedVehicle(hash, c.x+3, c.y, c.z, h, true, true, false)
        if v ~= 0 then
            if spawninsidevehicle then SetPedIntoVehicle(ped, v, -1) end
            Notify("Spawn", model.." spawne !")
        else
            Notify("Spawn","Echec spawn: "..model)
        end
        SetModelAsNoLongerNeeded(hash)
    end)
end
CreateMenu("spawnveh","Spawn Vehicles","vehicle")
MC("spawnveh","Spawn Inside","",nil,
    function() spawninsidevehicle=true end,
    function() spawninsidevehicle=false end)
MS("spawnveh","Super Cars",    "Adder / Zentorno / Turismo...", "sp_super")
MS("spawnveh","Sports",        "Elegy / Sultan / Comet...",     "sp_sports")
MS("spawnveh","Muscle",        "Gauntlet / Vigero / Blade...",  "sp_muscle")
MS("spawnveh","Sedans",        "Asea / Ingot / Schafter...",    "sp_sedans")
MS("spawnveh","SUV",           "Baller / Cavalcade / Granger..","sp_suv")
MS("spawnveh","Trucks",        "Dump / Hauler / Phantom...",    "sp_trucks")
MS("spawnveh","Vans",          "Bison / Minivan / Speedo...",   "sp_vans")
MS("spawnveh","Motorcycles",   "Akuma / Bati / Daemon...",      "sp_motos")
MS("spawnveh","Off-Road",      "Bifta / Brawler / Insurgent...", "sp_offroad")
MS("spawnveh","Military",      "Barracks / Rhino / Lazer...",   "sp_military")
MS("spawnveh","Emergency",     "Ambulance / Police / FIB...",   "sp_emergency")
MS("spawnveh","Aircraft",      "Besra / Hydra / Lazer...",      "sp_aircraft")
MS("spawnveh","Boats",         "Dinghy / Jetmax / Submersible...","sp_boats")
MS("spawnveh","Special",       "Oppressor / Deluxo / Vigilante..","sp_special")
CreateMenu("sp_super","Super Cars","spawnveh")
for _,v in ipairs({
    {"Adder","adder"},{"Zentorno","zentorno"},{"Turismo R","turismor"},
    {"Entity XF","entityxf"},{"Osiris","osiris"},{"X80 Proto","x80proto"},
    {"Tempesta","tempesta"},{"FMJ","fmj"},{"Tyrus","tyrus"},
    {"Vagner","vagner"},{"Deveste Eight","deveste8"},{"Tezeract","tezeract"},
    {"Krieger","krieger"},{"Emerus","emerus"},{"Furia","furia"},
    {"Praetor","praetor"},{"Weaponized Tampa","tampa3"},{"Cyclone","cyclone"},
}) do local l,m=v[1],v[2]; MB("sp_super",l,"",function() SpawnVeh(m) end) end
CreateMenu("sp_sports","Sports","spawnveh")
for _,v in ipairs({
    {"Elegy RH8","elegy"},{"Elegy Retro","elegy2"},{"Sultan RS","sultanrs"},
    {"Comet SR","comet2"},{"Comet S2","comet3"},{"Jester RR","jester3"},
    {"Schafter V12","schafter4"},{"Schafter LWB","schafter6"},
    {"Rapid GT","rapidgt"},{"Rapid GT Classic","rapidgt2"},
    {"Alpha","alpha"},{"Banshee","banshee"},{"Banshee 900R","banshee2"},
    {"Buffalo STX","buffalo4"},{"Carbon RS","carbonrs"},
    {"Growler","growler"},{"Issi Classic","issi3"},{"Italigto","italigto"},
    {"Pariah","pariah"},{"Penumbra FF","penumbra2"},
}) do local l,m=v[1],v[2]; MB("sp_sports",l,"",function() SpawnVeh(m) end) end
CreateMenu("sp_muscle","Muscle","spawnveh")
for _,v in ipairs({
    {"Gauntlet","gauntlet"},{"Gauntlet Classic","gauntlet2"},{"Gauntlet Hellfire","gauntlet3"},
    {"Vigero","vigero"},{"Vigero ZX","vigerox"},{"Blade","blade"},
    {"Dominator","dominator"},{"Dominator GTX","dominator3"},{"Dominator ASP","dominator6"},
    {"Impaler","impaler"},{"Impaler LX","impaler2"},{"Lurcher","lurcher"},
    {"Phoenix","phoenix"},{"Ruiner","ruiner"},{"Ruiner 2000","ruiner2"},
    {"Sabre Turbo","sabre2"},{"Stallion","stallion"},{"Tulip","tulip"},
}) do local l,m=v[1],v[2]; MB("sp_muscle",l,"",function() SpawnVeh(m) end) end
CreateMenu("sp_sedans","Sedans","spawnveh")
for _,v in ipairs({
    {"Asea","asea"},{"Asterope","asterope"},{"Emperor","emperor"},
    {"Fugitive","fugitive"},{"Glendale","glendale"},{"Ingot","ingot"},
    {"Intruder","intruder"},{"Premier","premier"},{"Primo","primo"},
    {"Schafter 3","schafter3"},{"Stafford","stafford"},{"Stratum","stratum"},
    {"Surge","surge"},{"Warrener","warrener"},{"Warrener HKR","warrener2"},
}) do local l,m=v[1],v[2]; MB("sp_sedans",l,"",function() SpawnVeh(m) end) end
CreateMenu("sp_suv","SUV","spawnveh")
for _,v in ipairs({
    {"Baller","baller"},{"Baller LE","baller2"},{"Baller LE LWB","baller3"},
    {"Baller LE LWB (Armoured)","baller4"},{"Cavalcade","cavalcade"},{"Cavalcade FXT","cavalcade2"},
    {"Contender","contender"},{"Dubsta","dubsta"},{"Dubsta 6x6","dubsta2"},
    {"FQ 2","fq2"},{"Granger","granger"},{"Granger 3600LX","granger2"},
    {"Huntley S","huntley"},{"Landstalker","landstalker"},{"Landstalker XL","landstalker2"},
    {"Mesa","mesa"},{"Patriot","patriot"},{"Patriot Stretch","patriot2"},
    {"Rebla GTS","rebla"},{"Rocoto","rocoto"},{"Seminole","seminole"},
    {"Seminole Frontier","seminole2"},{"Toros","toros"},{"XLS","xls"},{"XLS Armoured","xls2"},
}) do local l,m=v[1],v[2]; MB("sp_suv",l,"",function() SpawnVeh(m) end) end
CreateMenu("sp_trucks","Trucks","spawnveh")
for _,v in ipairs({
    {"Dump","dump"},{"Flatbed","flatbed"},{"Handler","handler"},
    {"Hauler","hauler"},{"Hauler Custom","hauler2"},{"Mixer","mixer"},
    {"Mixer 2","mixer2"},{"Phantom","phantom"},{"Phantom Custom","phantom3"},
    {"Packer","packer"},{"Pounder","pounder"},{"Pounder Custom","pounder2"},
    {"Rubble","rubble"},{"Tipper","tipper"},{"Tipper 2","tipper2"},
}) do local l,m=v[1],v[2]; MB("sp_trucks",l,"",function() SpawnVeh(m) end) end
CreateMenu("sp_vans","Vans","spawnveh")
for _,v in ipairs({
    {"Bison","bison"},{"Bison 2","bison2"},{"Bison 3","bison3"},
    {"Bobcat XL","bobcatxl"},{"Boxville","boxville"},{"Boxville 2","boxville2"},
    {"Burrito","burrito"},{"Burrito 3","burrito3"},{"Gang Burrito","burrito5"},
    {"Minivan","minivan"},{"Minivan Custom","minivan2"},{"Paradise","paradise"},
    {"Rumpo","rumpo"},{"Rumpo Custom","rumpo2"},{"Speedo","speedo"},
    {"Speedo Custom","speedo2"},{"Taco Van","taco"},{"Youga","youga"},{"Youga Classic","youga2"},
}) do local l,m=v[1],v[2]; MB("sp_vans",l,"",function() SpawnVeh(m) end) end
CreateMenu("sp_motos","Motorcycles","spawnveh")
for _,v in ipairs({
    {"Akuma","akuma"},{"Bati 801","bati"},{"Bati 801RR","bati2"},
    {"Chimera","chimera"},{"Cliffhanger","cliffhanger"},{"Daemon","daemon"},
    {"Daemon Custom","daemon2"},{"Defiler","defiler"},{"Diablous","diablous"},
    {"Diablous Custom","diablous2"},{"Double T","doublet"},{"Enduro","enduro"},
    {"Esskey","esskey"},{"FCR 1000","fcr"},{"FCR 1000 Custom","fcr2"},
    {"Faggio","faggio2"},{"Faggio Mod","faggio3"},{"Faggio Sport","faggio"},
    {"Gargoyle","gargoyle"},{"Hakuchou","hakuchou"},{"Hakuchou Drag","hakuchou2"},
    {"Hexer","hexer"},{"Innovation","innovation"},{"Lectro","lectro"},
    {"Manchez","manchez"},{"Manchez Scout","manchez2"},{"Nemesis","nemesis"},
    {"Nightblade","nightblade"},{"PCJ-600","pcj"},{"Rat Bike","ratbike"},
    {"Ruffian","ruffian"},{"Sanchez","sanchez"},{"Sovereign","sovereign"},
    {"Thrust","thrust"},{"Vader","vader"},{"Vindicator","vindicator"},
    {"Wolfsbane","wolfsbane"},{"Zombiea","zombiea"},{"Zombieb","zombieb"},
}) do local l,m=v[1],v[2]; MB("sp_motos",l,"",function() SpawnVeh(m) end) end
CreateMenu("sp_offroad","Off-Road","spawnveh")
for _,v in ipairs({
    {"Bifta","bifta"},{"Blazer","blazer"},{"Blazer Aqua","blazer4"},
    {"Blazer Hot Rod","blazer5"},{"Brawler","brawler"},{"Caracara","caracara"},
    {"Caracara 4x4","caracara2"},{"Desert Raid","desertraid"},{"Dune","dune"},
    {"Dune FAV","dune3"},{"Insurgent","insurgent"},{"Insurgent Custom","insurgent2"},
    {"Insurgent PU","insurgent3"},{"Kamacho","kamacho"},{"Kalahari","kalahari"},
    {"Marshall","marshall"},{"Mesa","mesa3"},{"Nightshark","nightshark"},
    {"Outlaw","outlaw"},{"Rally Trophy","rallytrophy"},{"Rancher XL","rancherxl"},
    {"Rebel","rebel"},{"Rebel (Rusted)","rebel2"},{"Riata","riata"},
    {"Sandking SWB","sandking"},{"Sandking XL","sandking2"},{"Technical","technical"},
    {"Technical Custom","technical2"},{"Technical Aqua","technical3"},{"TerrorByte","terbyte"},
}) do local l,m=v[1],v[2]; MB("sp_offroad",l,"",function() SpawnVeh(m) end) end
CreateMenu("sp_military","Military","spawnveh")
for _,v in ipairs({
    {"Barracks","barracks"},{"Barracks Semi","barracks2"},{"Barracks OL","barracks3"},
    {"Chernobog","chernobog"},{"HVY APC","apc"},{"Khanjali","khanjali"},
    {"Lazer","lazer"},{"LF-22 Starling","starling"},{"Menacer","menacer"},
    {"Militray Truck","miltruck"},{"Rhino","rhino"},{"Riot","riot"},
    {"Riot 2","riot2"},{"RCV","rcv"},{"Squaddie","squaddie"},
    {"Thruster","thruster"},{"Valkyrie","valkyrie"},{"Valkyrie Mod","valkyrie2"},
    {"Volatol","volatol"},{"Weaponized Duster","duster"},
}) do local l,m=v[1],v[2]; MB("sp_military",l,"",function() SpawnVeh(m) end) end
CreateMenu("sp_emergency","Emergency","spawnveh")
for _,v in ipairs({
    {"Ambulance","ambulance"},{"FIB SUV","fbi"},{"FIB SUV 2","fbi2"},
    {"Fire Truck","firetruk"},{"Lifeguard","lifeguard"},{"Limo 2","limo2"},
    {"Park Ranger","pranger"},{"Police","police"},{"Police 2","police2"},
    {"Police 3","police3"},{"Police 4","police4"},{"Police Buffalo","policeb"},
    {"Police Cruiser","policet"},{"Police Rancher","policeold1"},{"Police Roadcruiser","policeold2"},
    {"Police Riot","polriot"},{"Police Transporter","policet2"},{"Polmav","polmav"},
    {"Predator","predator"},{"Sheriff","sheriff"},{"Sheriff SUV","sheriff2"},
    {"Stockade","stockade"},{"Unmarked Cruiser","pranger"},
}) do local l,m=v[1],v[2]; MB("sp_emergency",l,"",function() SpawnVeh(m) end) end
CreateMenu("sp_aircraft","Aircraft","spawnveh")
for _,v in ipairs({
    {"Besra","besra"},{"Buckingham Alpha Z-1","alphaz1"},{"Buckingham Luxor","luxor"},
    {"Cargo Plane","cargoplane"},{"Cargobob","cargobob"},{"Cargobob 2","cargobob2"},
    {"Cuban 800","cuban800"},{"Dodo","dodo"},{"Duster","duster"},
    {"Howard NX-25","howard"},{"Hydra","hydra"},{"Jet","jet"},
    {"Lazer","lazer"},{"Luxor Deluxe","luxor2"},{"Mallard","mallard"},
    {"Mammatus","mammatus"},{"Miljet","miljet"},{"Nimbus","nimbus"},
    {"P-45 Nokota","nokota"},{"Pyro","pyro"},{"Rogue","rogue"},
    {"Rustler","rustler"},{"Seabreeze","seabreeze"},{"Shamal","shamal"},
    {"Starling","starling"},{"Strikeforce","strikeforce"},{"Titan","titan"},
    {"Tula","tula"},{"Ultralight","ultralight"},{"V-65 Molotok","molotok"},
    {"Velum","velum"},{"Velum 5-Seater","velum2"},{"Vestra","vestra"},
    {"Volatol","volatol"},{"Western Annihilator","annihilator"},
    {"Western Cargobob","cargobob3"},{"Western Savage","savage"},
    {"Buzzard","buzzard"},{"Buzzard Attack","buzzard2"},
    {"Frogger","frogger"},{"Maverick","maverick"},{"Swift","swift"},{"Swift Deluxe","swift2"},
}) do local l,m=v[1],v[2]; MB("sp_aircraft",l,"",function() SpawnVeh(m) end) end
CreateMenu("sp_boats","Boats","spawnveh")
for _,v in ipairs({
    {"Dinghy","dinghy"},{"Dinghy 2","dinghy2"},{"Dinghy 3","dinghy3"},{"Dinghy 4","dinghy4"},
    {"Jetmax","jetmax"},{"Kosatka","kosatka"},{"Kraken","submersible2"},
    {"Longfin","longfin"},{"Marquis","marquis"},{"Patrol Boat","patrolboat"},
    {"Seashark","seashark"},{"Seashark 2","seashark2"},{"Seashark 3","seashark3"},
    {"Speeder","speeder"},{"Speeder 2","speeder2"},{"Squalo","squalo"},
    {"Stromberg","stromberg"},{"Submersible","submersible"},{"Toro","toro"},
    {"Toro 2","toro2"},{"Tropic","tropic"},{"Tropic 2","tropic2"},{"Weaponized Dinghy","dinghy5"},
}) do local l,m=v[1],v[2]; MB("sp_boats",l,"",function() SpawnVeh(m) end) end
CreateMenu("sp_special","Special / Armed","spawnveh")
for _,v in ipairs({
    {"Oppressor","oppressor"},{"Oppressor MK2","oppressor2"},{"Deluxo","deluxo"},
    {"Vigilante","vigilante"},{"Scramjet","scramjet"},{"Toreador","toreador"},
    {"Cyclone","cyclone"},{"Imorgon","imorgon"},{"Ignus","ignus"},
    {"Brioso 300","brioso3"},{"Armored Kuruma","kuruma2"},{"Armored Boxville","boxville5"},
    {"Half-track","halftrack"},{"Anti-Aircraft Trailer","trailersmall2"},
    {"Caracara (Special)","caracara"},{"RC Bandito","rcbandito"},
    {"RC Tank","rcbandito"},{"Arena War Dominator","dominator4"},
    {"Arena War Issi","issi4"},{"Imperator","imperator"},{"Imperator Custom","imperator2"},
    {"Cerberus","cerberus"},{"Scarab","scarab"},{"Scarab 2","scarab2"},{"ZR380","zr380"},
    {"Sasquatch","sasquatch"},{"Brutus","brutus"},{"Brutus Custom","brutus2"},
}) do local l,m=v[1],v[2]; MB("sp_special",l,"",function() SpawnVeh(m) end) end
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
MB("teleport","TP Ocean [C]","2 etapes bypass AC", function()
    local ped=PlayerPedId(); local veh=GetVehiclePedIsIn(ped,false)
    local wp={x=-7000.0,y=-7000.0,z=0.0}
    local savedPos=GetEntityCoords(ped); local savedH=GetEntityHeading(ped); local savedVeh=veh
    if veh~=0 then SetEntityCoords(veh,wp.x,wp.y,wp.z,false,false,false,false)
    else SetEntityCoords(ped,wp.x,wp.y,wp.z,false,false,false,false) end
    Citizen.Wait(math.random(80,150))
    if IsPedInAnyVehicle(ped,false) then TaskLeaveVehicle(ped,GetVehiclePedIsIn(ped,false),16); Citizen.Wait(500) end
    SetEntityCoords(ped,savedPos.x,savedPos.y,savedPos.z,false,false,false,false)
    SetEntityHeading(ped,savedH)
end)
MC("teleport","TP Ocean V2 [W]",Vars.Teleport,"OceanV2",
    function() Vars.Teleport.OceanV2=true end,
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
CreateMenu("weapon","Weapon Options","main")
MS("weapon","Aimbot","Settings aimbot","aimbot")
MS("weapon","Bullet Options","Remplacer balles","bulletopts")
MB("weapon","Get All Weapons","", function()
    for _,w in ipairs({"WEAPON_PISTOL","WEAPON_COMBATPISTOL","WEAPON_MICROSMG","WEAPON_SMG","WEAPON_ASSAULTRIFLE","WEAPON_CARBINERIFLE","WEAPON_MG","WEAPON_COMBATMG","WEAPON_HEAVYSNIPER","WEAPON_RPG","WEAPON_GRENADE","WEAPON_STICKYBOMB","WEAPON_KNIFE","WEAPON_BAT"}) do
        GiveWeaponToPed(PlayerPedId(),GetHashKey(w),9999,false,false)
    end
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
MC("weapon","No Recoil",Vars.Weapon,"NoRecoil",
    function() Vars.Weapon.NoRecoil=true end,
    function() Vars.Weapon.NoRecoil=false end)
MC("weapon","Crosshair",Vars.Weapon,"Crosshair",
    function() Vars.Weapon.Crosshair=true end,
    function() Vars.Weapon.Crosshair=false end)
MC("weapon","Spinbot",Vars.Weapon,"Spinbot",
    function() Vars.Weapon.Spinbot=true end,
    function() Vars.Weapon.Spinbot=false end)
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
    MB("bulletopts",name,"", function() Vars.Weapon.BulletIndex=idx end)
end
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
CreateMenu("misc","Misc Options","main")
MS("misc","Anticheat Options","Seed / Guardian / SafeMode","anticheat")
MS("misc","ESP Options","Box / Nom / Lignes","esp")
MS("misc","Script Options","Hostage / Carry / Peacetime","scriptopts")
MS("misc","Server Options","ESX / VRP","serveropts")
CreateMenu("anticheat","Anticheat Options","misc")
MC("anticheat","Guardian Full Bypass",Vars.AntiCheat,"GuardianBypass",
    function()
        Vars.AntiCheat.GuardianBypass=true
        Notify("Guardian","Bypass en cours...")
        Citizen.CreateThread(function()
            local guardianRes=nil
            for i=0,GetNumResources()-1 do
                local res=GetResourceByFindIndex(i)
                if res then
                    local rL=string.lower(res)
                    if string.find(rL,"seed") or string.find(rL,"guardian") then
                        guardianRes=res; break
                    end
                end
            end
            Susano.InjectResource("any",[[
                local _oTSE=TriggerServerEvent
                TriggerServerEvent=function(name,...)
                    if name=="blev" then return end
                    if name and (string.find(string.lower(tostring(name)),"seed") or
                                 string.find(string.lower(tostring(name)),"guardian")) then return end
                    return _oTSE(name,...)
                end
            ]], Susano.InjectionType.NEW_THREAD)
            Citizen.Wait(50)
            Susano.InjectResource("any",[[
                local _oAEH=AddEventHandler
                AddEventHandler=function(name,cb)
                    if name then
                        if string.find(tostring(name),"%.verify$") or
                           string.find(tostring(name),"%.getEvents$") or
                           string.find(tostring(name),"%.getServerEvents$") then
                            return _oAEH(name,function(...) end)
                        end
                    end
                    return _oAEH(name,cb)
                end
            ]], Susano.InjectionType.NEW_THREAD)
            Citizen.Wait(50)
            Susano.InjectResource("any",[[
                SetLocalPlayerCanCollectPortablePickups(true)
                Citizen.InvokeNative(0xF92099527DB8E2A7,2047,false)
                Citizen.CreateThread(function()
                    while true do
                        Citizen.Wait(2000)
                        SetLocalPlayerCanCollectPortablePickups(true)
                        Citizen.InvokeNative(0xF92099527DB8E2A7,2047,false)
                    end
                end)
            ]], Susano.InjectionType.NEW_THREAD)
            Citizen.Wait(50)
            if guardianRes then
                TriggerEvent("__cfx_internal:removeAllEventHandlers",guardianRes)
            end
            Citizen.Wait(50)
            Susano.InjectResource("any",[[
                AddEventHandler("populationPedCreating",function(x,y,z,model,setters) end)
            ]], Susano.InjectionType.NEW_THREAD)
            Susano.ClearOnTriggerServerEvent()
            Susano.OnTriggerServerEvent(function(name, payload)
                if not name then return end
                local _B={["blev"]=true,["iven"]=true,["it"]=true,["rf"]=true,
                           ["fc"]=true,["rcm"]=true,["sm"]=true,["tk"]=true,["st"]=true,["hb"]=true}
                if _B[name] then return false end
                local nl=string.lower(tostring(name))
                local _P={"seed","guardian","warden","watchdog","sentry","rageshit",
                           "bans:report","bans:flag","anticheat","violation",
                           "screenshot:url","discord:log","logs:send","crash_reporter"}
                for _,p in ipairs(_P) do
                    if string.find(nl,p,1,true) then return false end
                end
                return name,payload
            end)
            Notify("Guardian","Bypass actif !")
            print("[ZeyMenu] ✓ Guardian/SEED Bypass effectue — hooks TSE bloques, AEH vides, pickups restaures")
        end)
    end,
    function()
        Vars.AntiCheat.GuardianBypass=false
        Susano.ClearOnTriggerServerEvent()
        Susano.OnTriggerServerEvent(function(name, payload)
            if not name then return end
            local _B={["blev"]=true,["iven"]=true,["it"]=true,["rf"]=true,
                       ["fc"]=true,["rcm"]=true,["sm"]=true,["tk"]=true,["st"]=true,["hb"]=true}
            if _B[name] then return false end
            local nl=string.lower(tostring(name))
            local _P={"seed","guardian","warden","watchdog","sentry","rageshit",
                       "bans:report","bans:flag","anticheat","violation"}
            for _,p in ipairs(_P) do
                if string.find(nl,p,1,true) then return false end
            end
            return name,payload
        end)
    end)
MB("anticheat","Guardian — Bypass Logs 'blev'","", function()
    Susano.InjectResource("any",[[
        local _oTSE=TriggerServerEvent
        TriggerServerEvent=function(name,...)
            if name=="blev" then return end
            return _oTSE(name,...)
        end
    ]], Susano.InjectionType.NEW_THREAD)
    Notify("Bypass Logs","Event 'blev' bloque")
    print("[ZeyMenu] ✓ Guardian Bypass Logs — event 'blev' bloque")
end)
MB("anticheat","Guardian — Restore Pickups","", function()
    SetLocalPlayerCanCollectPortablePickups(true)
    Citizen.InvokeNative(0xF92099527DB8E2A7,2047,false)
    Susano.InjectResource("any",[[
        SetLocalPlayerCanCollectPortablePickups(true)
        Citizen.InvokeNative(0xF92099527DB8E2A7,2047,false)
    ]], Susano.InjectionType.NEW_THREAD)
    Notify("Pickups","Tous les pickups re-actives")
end)
MB("anticheat","Guardian — Unlock Blocked Weapons","", function()
    Citizen.CreateThread(function()
        local guardianRes=nil
        for i=0,GetNumResources()-1 do
            local res=GetResourceByFindIndex(i)
            if res then
                local rL=string.lower(res)
                if string.find(rL,"seed") or string.find(rL,"guardian") then
                    guardianRes=res; break
                end
            end
        end
        if guardianRes then
            Susano.InjectResource(guardianRes,[[
                if _G.CFG and _G.CFG.BlockedWeapons then _G.CFG.BlockedWeapons={} end
                if _G.SEED then _G.SEED.GetWeaponFromHash=function() return nil end end
            ]], Susano.InjectionType.NO_THREAD)
            Notify("Guardian","Armes bloquees debloquees")
        end
    end)
end)
MC("anticheat","Safe Mode Seed",Vars.AntiCheat,"SafeModeSeed",
    function()
        Vars.AntiCheat.SafeModeSeed=true
        Notify("Safe Mode Seed","Activation...")
        Citizen.CreateThread(function()
            local sr=nil
            for i=0,GetNumResources()-1 do
                local res=GetResourceByFindIndex(i)
                if res and (string.find(string.lower(res),"seed") or string.find(string.lower(res),"guardian")) then
                    sr=res; break
                end
            end
            if sr then
                TriggerEvent("__cfx_internal:removeAllEventHandlers",sr)
                Notify("Safe Mode Seed","Actif: "..sr)
                print("[ZeyMenu] ✓ Safe Mode SEED — handlers retires sur resource: "..sr)
            else
                Vars.AntiCheat.SafeModeSeed=false
                Notify("Safe Mode Seed","Aucune resource trouvee")
            end
        end)
    end,
    function() Vars.AntiCheat.SafeModeSeed=false end)
if not Vars.AntiCheat.SeedBlocked then
    MB("anticheat","Full Stop Seed 1","Stop total — voice coupe aussi", function()
        local seedRes=nil
        for i=0,GetNumResources()-1 do
            local res=GetResourceByFindIndex(i)
            if res then
                local rL=string.lower(res)
                if (string.find(rL,"seed") or string.find(rL,"watchdog"))
                   and not string.find(rL,"underdog") and not string.find(rL,"voice") then
                    seedRes=res; break
                end
            end
        end
        if not seedRes then Notify("Full Stop 1","SEED introuvable"); return end
        Vars.AntiCheat.SeedBlocked=true
        Notify("Full Stop 1",seedRes.." trouve — stop en cours...")
        Citizen.CreateThread(function()
            TriggerEvent("__cfx_internal:removeAllEventHandlers",seedRes)
            Citizen.Wait(200)
            local ok=Susano.StopResource(seedRes)
            if ok then Notify("Full Stop 1","SEED stoppe") print("[ZeyMenu] ✓ Full Stop SEED 1 — resource stoppee: "..seedRes) else Notify("Full Stop 1","Stop echoue") print("[ZeyMenu] ✗ Full Stop SEED 1 — echec stop sur: "..seedRes) end
        end)
    end)
    MB("anticheat","Full Stop Seed 2","AC neutralise — voice actif", function()
        local seedRes=nil
        for i=0,GetNumResources()-1 do
            local res=GetResourceByFindIndex(i)
            if res then
                local rL=string.lower(res)
                if (string.find(rL,"seed") or string.find(rL,"watchdog"))
                   and not string.find(rL,"underdog") and not string.find(rL,"voice") then
                    seedRes=res; break
                end
            end
        end
        if not seedRes then Notify("Full Stop 2","SEED introuvable"); return end
        Vars.AntiCheat.SeedBlocked=true
        Notify("Full Stop 2","Neutralisation AC dans "..seedRes.."...")
        Citizen.CreateThread(function()
            Susano.InjectResource(seedRes,[[
                local _oTSE=TriggerServerEvent
                TriggerServerEvent=function(n,...)
                    if not n then return _oTSE(n,...) end
                    local nl=string.lower(tostring(n))
                    if n=="blev" or n=="iven" or n=="it" or n=="rf" or n=="fc" or n=="rcm" or n=="sm" or n=="tk" then return end
                    if string.find(nl,"seed") or string.find(nl,"guardian") or string.find(nl,"anticheat") or string.find(nl,"detect") or string.find(nl,"violation") then return end
                    return _oTSE(n,...)
                end
            ]], Susano.InjectionType.NO_THREAD)
            Citizen.Wait(200)
            Notify("Full Stop 2","AC neutralise — voice actif")
            print("[ZeyMenu] ✓ Full Stop SEED 2 — TSE neutralises dans resource: "..seedRes)
        end)
    end)
end
MC("anticheat","Safe Mode Global","",nil,
    function() SafeMode=true end,
    function() SafeMode=false end)
local function acS(k) return Vars.AntiCheat[k] and "[DETECTE]" or "Non detecte" end
MB("anticheat","Scanner Events AC","Susano.FindEvent",function()
    Citizen.CreateThread(function()
        local patterns = {"seed","guardian","anticheat","detect","ban","kick","report","violation","warden","sentry","watchdog"}
        local found = {}
        for _,p in ipairs(patterns) do
            local res = Susano.FindEvent(p)
            for _,ev in ipairs(res) do
                found[#found+1] = ev.resource..": "..ev.event
            end
        end
        if #found > 0 then
            Notify("Events AC","Trouves: "..#found.." — F8 pour details")
            for _,s in ipairs(found) do print("[ZeyMenu AC] "..s) end
        else
            Notify("Events AC","Aucun event AC detecte")
        end
    end)
end)
MB("anticheat","BadgerAC: "..acS("BadgerAC"),"",nil)
MB("anticheat","TigoAC: "..acS("TigoAC"),"",nil)
MB("anticheat","VAC: "..acS("VAC"),"",nil)
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
MS("misc","Extras","Anti-Screenshot / Event Logger / Fake Death","miscextra")
CreateMenu("miscextra","Extras","misc")
MC("miscextra","Anti-Screenshot Renforce",Vars.MiscExtra,"AntiScreenshot",
    function()
        Vars.MiscExtra.AntiScreenshot=true
        Susano.HookNative(0x56EA24F2BEE12FA3, function()
            return false, false
        end)
        Susano.InjectResource("any",[[
            AddEventHandler("screenshot_basic:requestScreenshot",function() CancelEvent() end)
            AddEventHandler("EasyAdmin:CaptureScreenshot",function() TriggerServerEvent("EasyAdmin:TookScreenshot","ERROR"); CancelEvent() end)
            AddEventHandler("requestScreenshot",function() CancelEvent() end)
            AddEventHandler("requestScreenshotUpload",function() CancelEvent() end)
            AddEventHandler("screenshot:request",function() CancelEvent() end)
            AddEventHandler("screenshot:capture",function() CancelEvent() end)
        ]], Susano.InjectionType.NEW_THREAD)
        Notify("Anti-Screenshot","Hook natif + injection actifs")
    end,
    function()
        Vars.MiscExtra.AntiScreenshot=false
        Notify("Anti-Screenshot","Desactive — hooks retires au prochain reload")
    end)
MC("miscextra","Event Logger [TSE spy]",Vars.MiscExtra,"EventLogger",
    function()
        Vars.MiscExtra.EventLogger=true
        Notify("Event Logger","Actif — TriggerServerEvent loggues en F8")
    end,
    function()
        Vars.MiscExtra.EventLogger=false
        Notify("Event Logger","Desactive")
    end)
MB("miscextra","Fake Death","NetworkResurrect combo", function()
    local ped = PlayerPedId()
    local c   = GetEntityCoords(ped)
    local h   = GetEntityHeading(ped)
    SetEntityHealth(ped, 0)
    Citizen.CreateThread(function()
        Citizen.Wait(200)
        NetworkResurrectLocalPlayer(c.x, c.y, c.z, h, true, false)
        Citizen.Wait(100)
        SetEntityHealth(ped, 200)
        SetPedArmour(ped, 100)
        ClearPedBloodDamage(ped)
        SetEntityInvincible(ped, false)
    end)
    Notify("Fake Death","Mort reseau simulee — respawn auto")
end)
CreateMenu("serveropts","Server Options","misc")
MB("serveropts","ESX: "..(Vars.Server.ESXServer and "[Detecte]" or "Non detecte"),"",nil)
MB("serveropts","VRP: "..(Vars.Server.VRPServer and "[Detecte]" or "Non detecte"),"",nil)
CreateMenu("settings","Settings","main")
MS("settings","Config Keybinds","Sauvegarder / Charger","settings_config")
CreateMenu("settings_config","Config Keybinds","settings")
MC("settings","Watermark",Vars.MenuOptions,"Watermark",
    function() Vars.MenuOptions.Watermark=true end,
    function() Vars.MenuOptions.Watermark=false end)
MB("settings","ZeyMenu Susano Edition","",nil)
MB("settings","Kill Menu","Fermer completement", function() KillMenu() end)
_KB_RebuildConfigMenu = function()
    if Menus["settings_config"] then
        Menus["settings_config"].items = {}
    end
    MB("settings_config","Save Config","Sauvegarder les touches actuelles", function()
        if next(_KB_Binds) == nil then
            Notify("Config","Aucune touche assignee a sauvegarder")
            return
        end
        _KB_SaveConfig()
    end)
    MB("settings_config","Decharger Config","Retirer toutes les touches sans supprimer les configs", function()
        _KB_Binds      = {}
        _KB_UsedVK     = {}
        _KB_PendingVK  = nil
        _KB_Assigning  = nil
        _KB_AssignLabel= ""
        Notify("Config","Touches dechargees — configs conservees")
    end)
    for i, cfg in ipairs(_KB_Configs) do
        local cfgId = "kbcfg_"..i
        Menus[cfgId] = {title="Config "..cfg.name, parent="settings_config", items={}}
        MB(cfgId,"Load","Charger cette config", function()
            _KB_LoadConfig(i)
        end)
        MB(cfgId,"Delete","Supprimer cette config", function()
            _KB_DeleteConfig(i)
        end)
        local _nbBinds = 0
        for _ in pairs(cfg.binds) do _nbBinds=_nbBinds+1 end
        MS("settings_config","Config "..cfg.name,"("..tostring(_nbBinds).." touches)", cfgId)
    end
end
_KB_RebuildConfigMenu()
local function RenderMenu()
    if not Menu.open or not Menu.currentMenu then return end
    local menu = Menus[Menu.currentMenu]
    if not menu then return end
    local x  = Menu.x
    local y  = Menu.y
    local w  = Menu.w
    local tH = Menu.titleH
    local iH = Menu.itemH
    local r  = Menu.rgb.r
    local g  = Menu.rgb.g
    local b  = Menu.rgb.b
    Susano.BeginFrame()
    Susano.DrawRectFilled(x, y, w, tH, 0.05, 0.05, 0.05, 0.95, 4)
    Susano.DrawRectFilled(x, y, w, 3, r, g, b, 1.0, 0)
    local titleW = Susano.GetTextWidth("ZeyMenu", Menu.textSz + 4)
    Susano.DrawText(x + w/2 - titleW/2, y + tH/2 - 8, "ZeyMenu", Menu.textSz + 4, 1, 1, 1, 1)
    local subW = Susano.GetTextWidth(menu.title, Menu.textSz - 2)
    Susano.DrawText(x + w/2 - subW/2, y + tH/2 + 6, menu.title, Menu.textSz - 2, r, g, b, 0.9)
    local nbItems = #menu.items
    local visible = math.min(Menu.maxVisible, nbItems)
    for i = 1, visible do
        local realIdx = i + Menu.scroll
        local item    = menu.items[realIdx]
        if not item then break end
        local iy       = y + tH + (i-1)*iH
        local selected = (realIdx == Menu.cursorIndex)
        if selected then
            Susano.DrawRectFilled(x, iy, w, iH, r, g, b, 0.25, 0)
            Susano.DrawRectFilled(x, iy, 3, iH, r, g, b, 1.0, 0)
        else
            local shade = (i % 2 == 0) and 0.08 or 0.05
            Susano.DrawRectFilled(x, iy, w, iH, shade, shade, shade, 0.85, 0)
        end
        Susano.DrawLine(x, iy + iH - 1, x + w, iy + iH - 1, 1, 1, 1, 0.05, 1)
        local lr, lg, lb = selected and 1 or 0.9, selected and 1 or 0.9, selected and 1 or 0.9
        Susano.DrawText(x + 10, iy + iH/2 - Menu.textSz/2, item.label, Menu.textSz, lr, lg, lb, 1)
        local kbStr = ""
        if item._kb_uid and _KB_Binds[item._kb_uid] then
            kbStr = "["..(_VK_Names[_KB_Binds[item._kb_uid].vk] or "?").."]"
        end
        if item.type == "checkbox" then
            local checked = GetChecked(item)
            local stateStr = checked and "ON" or "OFF"
            local stateR,stateG,stateB = checked and 0.2 or 0.85, checked and 0.9 or 0.25, checked and 0.3 or 0.25
            local tw = Susano.GetTextWidth(stateStr, Menu.textSz)
            Susano.DrawText(x + w - tw - 8, iy + iH/2 - Menu.textSz/2, stateStr, Menu.textSz, stateR,stateG,stateB, 1)
            if kbStr ~= "" then
                local kw = Susano.GetTextWidth(kbStr, Menu.textSz - 4)
                Susano.DrawText(x + w - tw - kw - 14, iy + iH/2 - (Menu.textSz-4)/2, kbStr, Menu.textSz-4, 1,0.8,0.1,0.9)
            end
        elseif item.type == "submenu" then
            local tw = Susano.GetTextWidth(">", Menu.textSz)
            Susano.DrawText(x + w - tw - 8, iy + iH/2 - Menu.textSz/2, ">", Menu.textSz, r, g, b, 0.8)
        elseif item.subtext and item.subtext ~= "" then
            local tw = Susano.GetTextWidth(item.subtext, Menu.textSz - 2)
            Susano.DrawText(x + w - tw - 8, iy + iH/2 - (Menu.textSz-2)/2, item.subtext, Menu.textSz - 2, 0.55, 0.55, 0.55, 1)
            if kbStr ~= "" then
                local kw = Susano.GetTextWidth(kbStr, Menu.textSz - 4)
                Susano.DrawText(x + w - tw - kw - 14, iy + iH/2 - (Menu.textSz-4)/2, kbStr, Menu.textSz-4, 1,0.8,0.1,0.9)
            end
        else
            if kbStr ~= "" then
                local kw = Susano.GetTextWidth(kbStr, Menu.textSz - 4)
                Susano.DrawText(x + w - kw - 8, iy + iH/2 - (Menu.textSz-4)/2, kbStr, Menu.textSz-4, 1,0.8,0.1,0.9)
            end
        end
    end
    local bottomY = y + tH + visible * iH
    Susano.DrawRectFilled(x, bottomY, w, 20, 0.04, 0.04, 0.04, 0.95, 0)
    Susano.DrawRectFilled(x, bottomY, w, 1, r, g, b, 0.5, 0)
    local hint = string.format("%d / %d  | UP DOWN ENTER BACK | F10=Assigner touche", Menu.cursorIndex, nbItems)
    Susano.DrawText(x + 6, bottomY + 4, hint, 10, 0.5, 0.5, 0.5, 0.8)
    if nbItems > Menu.maxVisible then
        local sbH   = visible * iH
        local kH    = sbH * (Menu.maxVisible / nbItems)
        local prog  = Menu.scroll / math.max(1, nbItems - Menu.maxVisible)
        local kY    = y + tH + prog * (sbH - kH)
        Susano.DrawRectFilled(x + w - 4, kY, 3, kH, r, g, b, 0.7, 0)
    end
    if _KB_Assigning then
        local ow, oh = 500, 110
        local ox = SW/2 - ow/2
        local oy = SH - 160
        Susano.DrawRectFilled(ox, oy, ow, oh, 0.05, 0.05, 0.05, 0.96, 8)
        Susano.DrawRectFilled(ox, oy, ow, 3, r, g, b, 1.0, 0)
        Susano.DrawRectFilled(ox, oy+oh-3, ow, 3, r, g, b, 0.5, 0)
        local t1 = "ASSIGNER UNE TOUCHE"
        local t1w = Susano.GetTextWidth(t1, 18)
        Susano.DrawText(ox + ow/2 - t1w/2, oy + 14, t1, 18, r, g, b, 1.0)
        local t2 = '"'.._KB_AssignLabel..'"'
        local t2w = Susano.GetTextWidth(t2, 15)
        Susano.DrawText(ox + ow/2 - t2w/2, oy + 40, t2, 15, 1.0, 1.0, 1.0, 0.9)
        if _KB_PendingVK then
            local t3a = "Touche selectionnee : ".._KB_GetVKName(_KB_PendingVK)
            local t3aw = Susano.GetTextWidth(t3a, 14)
            Susano.DrawText(ox + ow/2 - t3aw/2, oy + 60, t3a, 14, 0.2, 1.0, 0.4, 1.0)
            local t3b = "ENTREE = confirmer  |  Autre touche = changer  |  ECHAP = annuler"
            local t3bw = Susano.GetTextWidth(t3b, 11)
            Susano.DrawText(ox + ow/2 - t3bw/2, oy + 82, t3b, 11, 0.6, 0.6, 0.6, 0.85)
        else
            local t3 = "Appuie sur une touche..."
            local t3w = Susano.GetTextWidth(t3, 13)
            Susano.DrawText(ox + ow/2 - t3w/2, oy + 66, t3, 13, 0.7, 0.7, 0.7, 0.85)
        end
        Susano.DrawRect(ox, oy, ow, oh, r, g, b, 0.4, 1)
    end
    Susano.SubmitFrame()
end
local function Navigate(dir)
    if not Menu.currentMenu then return end
    local menu = Menus[Menu.currentMenu]
    if not menu then return end
    local n = #menu.items
    Menu.cursorIndex = Menu.cursorIndex + dir
    if Menu.cursorIndex < 1 then Menu.cursorIndex = n end
    if Menu.cursorIndex > n then Menu.cursorIndex = 1 end
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
        Susano.ResetFrame()
    end
end
Citizen.CreateThread(function()
    local prevDEL, prevUP, prevDOWN, prevENTER, prevBACK = false,false,false,false,false
    local navTimer  = 0
    local navDelay  = 150
    while not killmenu do
        Citizen.Wait(0)
        local t = GetGameTimer() / 1000.0
        Menu.rgb.r = (math.sin(t*0.8)       * 0.5 + 0.5)
        Menu.rgb.g = (math.sin(t*0.8+2.094) * 0.5 + 0.5)
        Menu.rgb.b = (math.sin(t*0.8+4.189) * 0.5 + 0.5)
        local dDEL,   pDEL   = Susano.GetAsyncKeyState(0x2E)
        local dUP,    pUP    = Susano.GetAsyncKeyState(0x26)
        local dDOWN,  pDOWN  = Susano.GetAsyncKeyState(0x28)
        local dENTER, pENTER = Susano.GetAsyncKeyState(0x0D)
        local dBACK,  pBACK  = Susano.GetAsyncKeyState(0x08)
        if pDEL and not prevDEL then
            Menu.open = not Menu.open
            if Menu.open then
                if not Menu.currentMenu then
                    Menu.currentMenu = "main"
                    Menu.cursorIndex = 1
                    Menu.scroll = 0
                    breadcrumb = {}
                end
            else
                Susano.ResetFrame()
            end
        end
        prevDEL = dDEL
        if Menu.open then
            if not _KB_Assigning then
                local now = GetGameTimer()
                if pUP and not prevUP then
                    Navigate(-1); navTimer = now + navDelay
                elseif dUP and now > navTimer then
                    Navigate(-1); navTimer = now + 80
                end
                if pDOWN and not prevDOWN then
                    Navigate(1); navTimer = now + navDelay
                elseif dDOWN and now > navTimer then
                    Navigate(1); navTimer = now + 80
                end
                if pENTER and not prevENTER then Select() end
                if pBACK and not prevBACK then GoBack() end
                local _dF10, _pF10 = Susano.GetAsyncKeyState(0x79)
                if _pF10 then
                    local _menu = Menus[Menu.currentMenu]
                    local _item = _menu and _menu.items[Menu.cursorIndex]
                    if _item and _item._kb_uid then
                        _KB_PendingVK   = nil
                        _KB_EnterReady  = false
                        _KB_Assigning   = _item._kb_uid
                        _KB_AssignLabel = _item.label
                    end
                end
            end
        end
        prevUP    = dUP
        prevDOWN  = dDOWN
        prevENTER = dENTER
        prevBACK  = dBACK
        if _KB_Assigning then
            local _dESC, _pESC = Susano.GetAsyncKeyState(0x1B)
            local _dDEL2, _pDEL2 = Susano.GetAsyncKeyState(0x2E)
            local _eD = Susano.GetAsyncKeyState(0x0D)
            local _ePressed = _eD and not _KB_PrevEnter
            _KB_PrevEnter = _eD
            if not _eD then _KB_EnterReady = true end
            if _pESC then
                _KB_PendingVK   = nil
                _KB_EnterReady  = false
                _KB_PrevEnter   = false
                _KB_Assigning   = nil
                _KB_AssignLabel = ""
            elseif _pDEL2 then
                _KB_Unbind(_KB_Assigning)
                _KB_PendingVK   = nil
                _KB_Assigning   = nil
                _KB_AssignLabel = ""
                Notify("Keybind","Touche retiree")
            elseif _ePressed and _KB_PendingVK and _KB_EnterReady then
                local _uid = _KB_Assigning
                local _action = nil
                for _, _m in pairs(Menus) do
                    for _, _it in ipairs(_m.items) do
                        if _it._kb_uid == _uid then
                            if _it.type == "button" then
                                _action = _it.action
                            elseif _it.type == "checkbox" then
                                local _itRef = _it
                                _action = function()
                                    local v = _itRef.varTable[_itRef.varKey]
                                    if not v then
                                        if _itRef.onEnable then _itRef.onEnable() end
                                    else
                                        if _itRef.onDisable then _itRef.onDisable() end
                                    end
                                    _itRef.varTable[_itRef.varKey] = not v
                                end
                            end
                            break
                        end
                    end
                    if _action then break end
                end
                local _ok, _err = _KB_Bind(_uid, _KB_PendingVK, _KB_AssignLabel, _action)
                if _ok then
                    Notify("Keybind", _KB_AssignLabel.." → ".._KB_GetVKName(_KB_PendingVK))
                    _KB_PlaySound()
                else
                    Notify("Keybind", _err or "Erreur")
                end
                _KB_PendingVK   = nil
                _KB_Assigning   = nil
                _KB_AssignLabel = ""
            else
                for _, vk in ipairs(_VK_Scan) do
                    local _d2, _p2 = Susano.GetAsyncKeyState(vk)
                    if _p2 then
                        local _uid = _KB_Assigning
                        if _KB_UsedVK[vk] and _KB_UsedVK[vk] ~= _uid then
                            Notify("Keybind","Touche ".._KB_GetVKName(vk).." deja utilisee — choisis une autre")
                        else
                            _KB_PendingVK = vk
                        end
                        break
                    end
                end
            end
        end
        if not _KB_Assigning then
            for uid, bind in pairs(_KB_Binds) do
                local _bd, _bp = Susano.GetAsyncKeyState(bind.vk)
                if _bp and bind.action then
                    bind.action()
                    _KB_PlaySound()
                end
            end
        end
        if Menu.open then
            RenderMenu()
        end
        if Vars.MenuOptions.Watermark then
            Susano.BeginFrame()
            Susano.DrawText(12, 12, "ZeyMenu Susano", 14, 0.12, 0.56, 1.0, 0.85)
            RenderNotifications(SW, SH)
            Susano.SubmitFrame()
        end
    end
end)
CreateMenu("trigger","Trigger","main")
MS("trigger","Unity",        "57.128.30.206 — Exploits SEED",  "unity")
MS("trigger","Unity Legacy", "57.128.57.193 — Exploits SEED",  "unity_legacy")
MS("trigger","Safe Trigger", "Actions natives 0 detect",        "safetrigger")
local function _TI(code) Susano.InjectResource("any",code,Susano.InjectionType.NEW_THREAD) end
local function BuildTriggerMenu(pid)
    MS(pid,"Sante / Revive",   "healHealth / ambulance",         pid.."_sante")
    MS(pid,"Prison",           "freePrisoner / setPrisoner",     pid.."_prison")
    MS(pid,"Police",           "Alertes / Renforts",             pid.."_police")
    MS(pid,"Armes",            "weapons:equip",                  pid.."_armes")
    MS(pid,"Drogues",          "meth / drugs",                   pid.."_drugs")
    MS(pid,"Admin Events",     "noclip / invincibility",         pid.."_admin")
    MS(pid,"Guardian Bypass",  "Bloquer events",                 pid.."_guardian")
    MS(pid,"Misc Events",      "Divers",                         pid.."_misc")
end
local function BuildTriggerSubMenus(pid)
    CreateMenu(pid.."_sante","Sante / Revive",pid)
    MB(pid.."_sante","Se Heal (healHealth)","",function()
        _TI([[TriggerEvent("healHealth")]])
        SetEntityHealth(PlayerPedId(),200); SetPedArmour(PlayerPedId(),100)
        Notify("Heal","healHealth + HP/Armure max")
    end)
    MB(pid.."_sante","Revive (ambulance:revive)","",function()
        local ped=PlayerPedId(); local c=GetEntityCoords(ped)
        _TI([[TriggerEvent("ambulance:revive")]])
        NetworkResurrectLocalPlayer(c.x,c.y,c.z,GetEntityHeading(ped),true,false)
        SetEntityHealth(ped,200); ClearPedBloodDamage(ped)
        Notify("Revive","ambulance:revive declenche")
    end)
    MB(pid.."_sante","Status Boost Toggle","",function()
        _TI([[TriggerEvent("status:boostToggled",true)]])
        Notify("Boost","Status boost active")
    end)
    MB(pid.."_sante","Pause Status Consumption","",function()
        _TI([[TriggerEvent("setStatusConsumptionPaused",true)]])
        Notify("Status","Consommation pausee")
    end)
    MB(pid.."_sante","Combo Full Heal","",function()
        _TI([[TriggerEvent("healHealth") TriggerEvent("status:boostToggled",true) TriggerEvent("setStatusConsumptionPaused",true) TriggerEvent("bandage")]])
        SetEntityHealth(PlayerPedId(),200); SetPedArmour(PlayerPedId(),100)
        Notify("Full Heal","Combo complet !")
    end)
    CreateMenu(pid.."_prison","Prison",pid)
    MB(pid.."_prison","Se Liberer de Prison","freePrisoner",function()
        _TI(string.format([[TriggerEvent("freePrisoner",%d)]],GetPlayerServerId(PlayerId())))
        Notify("Prison","freePrisoner declenche")
    end)
    MB(pid.."_prison","Reset Expiration Prison","",function()
        _TI(string.format([[TriggerEvent("updatePrisonerExpiration",%d,0)]],GetPlayerServerId(PlayerId())))
        Notify("Prison","Expiration mise a 0")
    end)
    MB(pid.."_prison","Mettre Joueur en Prison [50m]","setPrisoner",function()
        local myC=GetEntityCoords(PlayerPedId()); local best,bd=nil,50.0
        for _,p in ipairs(GetActivePlayers()) do
            if p~=PlayerId() then local tp=GetPlayerPed(p)
                if DoesEntityExist(tp) then local d=#(myC-GetEntityCoords(tp)); if d<bd then bd=d;best=p end end
            end
        end
        if best then _TI(string.format([[TriggerEvent("setPrisoner",%d,3600)]],GetPlayerServerId(best))); Notify("Prison",GetPlayerName(best).." mis en prison")
        else Notify("Prison","Aucun joueur dans 50m") end
    end)
    CreateMenu(pid.."_police","Police",pid)
    MB(pid.."_police","Alerte Maximale","",function()
        local c=GetEntityCoords(PlayerPedId())
        _TI(string.format([[TriggerEvent("police:receiveMaximalAlert",{x=%f,y=%f,z=%f,reason="URGENCE",level=5})]],c.x,c.y,c.z))
        Notify("Police","Alerte maximale envoyee")
    end)
    MB(pid.."_police","Alerte Renforts","",function()
        local c=GetEntityCoords(PlayerPedId())
        _TI(string.format([[TriggerEvent("police:reinforcementAlertPlayers",{x=%f,y=%f,z=%f})]],c.x,c.y,c.z))
        Notify("Police","Alerte renforts envoyee")
    end)
    MB(pid.."_police","Alerte Coup de Feu","",function()
        local c=GetEntityCoords(PlayerPedId())
        _TI(string.format([[TriggerEvent("police:sendGunShotAlert",{x=%f,y=%f,z=%f})]],c.x,c.y,c.z))
        Notify("Police","Alerte gunshot envoyee")
    end)
    CreateMenu(pid.."_armes","Armes",pid)
    MB(pid.."_armes","Assault Rifle","",function()
        _TI([[TriggerEvent("weapons:equip","weapon_assaultrifle",nil)]])
        GiveWeaponToPed(PlayerPedId(),GetHashKey("WEAPON_ASSAULTRIFLE"),9999,false,true)
        Notify("Armes","Assault Rifle equipe")
    end)
    MB(pid.."_armes","Heavy Sniper","",function()
        _TI([[TriggerEvent("weapons:equip","weapon_heavysniper",nil)]])
        GiveWeaponToPed(PlayerPedId(),GetHashKey("WEAPON_HEAVYSNIPER"),9999,false,true)
        Notify("Armes","Heavy Sniper equipe")
    end)
    MB(pid.."_armes","RPG","",function()
        _TI([[TriggerEvent("weapons:equip","weapon_rpg",nil)]])
        GiveWeaponToPed(PlayerPedId(),GetHashKey("WEAPON_RPG"),250,false,true)
        Notify("Armes","RPG equipe")
    end)
    MB(pid.."_armes","Minigun","",function()
        _TI([[TriggerEvent("weapons:equip","weapon_minigun",nil)]])
        GiveWeaponToPed(PlayerPedId(),GetHashKey("WEAPON_MINIGUN"),9999,false,true)
        Notify("Armes","Minigun equipe")
    end)
    CreateMenu(pid.."_drugs","Drogues",pid)
    MB(pid.."_drugs","Exploser Tank Meth","",function()
        _TI([[TriggerEvent("meth:triggerTankExplosion")]]); Notify("Meth","Explosion tank !")
    end)
    MB(pid.."_drugs","Vider Tank Meth","",function()
        _TI([[TriggerEvent("meth:wipeLargeTank")]]); Notify("Meth","Tank vide")
    end)
    CreateMenu(pid.."_admin","Admin Events",pid)
    MB(pid.."_admin","Toggle Noclip Admin","",function()
        _TI([[TriggerEvent("noclipToggle",true)]]); Notify("Admin","noclipToggle(true)")
    end)
    MB(pid.."_admin","Toggle Invincibilite Admin","",function()
        _TI([[TriggerEvent("invincibilityToggle",true)]])
        SetEntityInvincible(PlayerPedId(),true); Notify("Admin","invincibilityToggle(true)")
    end)
    MB(pid.."_admin","Unfreeze Self","",function()
        _TI([[TriggerEvent("setPlayerFreezeState",false)]])
        FreezeEntityPosition(PlayerPedId(),false); Notify("Admin","setPlayerFreezeState(false)")
    end)
    MB(pid.."_admin","Vanish Toggle","",function()
        _TI([[TriggerEvent("vanishToggle",true)]]); Notify("Admin","vanishToggle(true)")
    end)
    MB(pid.."_admin","Set Staff Mode","",function()
        _TI([[TriggerEvent("setStaffMode",true)]]); Notify("Admin","setStaffMode(true)")
    end)
    CreateMenu(pid.."_guardian","Guardian Bypass",pid)
    MB(pid.."_guardian","Bloquer TOUS events Guardian","",function()
        _TI([[local _o=TriggerServerEvent local b={"st","hb","iven","it","rf","fc","rcm","sm","blev","tk"} TriggerServerEvent=function(n,...) if n then for _,v in ipairs(b) do if n==v then return end end end return _o(n,...) end]])
        Notify("Guardian","TOUS les events bloques")
    end)
    MB(pid.."_guardian","Bypass Complet","tout en un",function()
        _TI([[local _oTSE=TriggerServerEvent local blocked={"st","hb","iven","it","rf","fc","rcm","sm","blev","tk"} TriggerServerEvent=function(n,...) if n then for _,b in ipairs(blocked) do if n==b then return end end end return _oTSE(n,...) end local _oAEH=AddEventHandler AddEventHandler=function(n,cb) if n then if string.find(tostring(n),"%.verify$") or string.find(tostring(n),"%.getEvents$") or string.find(tostring(n),"%.getServerEvents$") then return _oAEH(n,function() end) end if n=="onClientResourceStart" or n=="onClientResourceStop" then return _oAEH(n,function() end) end end return _oAEH(n,cb) end]])
        Notify("Guardian","Bypass complet actif")
        print("[ZeyMenu] ✓ Guardian Bypass Complet effectue — TSE bloques + AEH neutralises")
    end)
    CreateMenu(pid.."_misc","Misc Events",pid)
    MB(pid.."_misc","Ouvrir Inventaire","open",function()
        _TI([[TriggerEvent("open")]]); Notify("Inventaire","Event open envoye")
    end)
    MB(pid.."_misc","Ouvrir Crafting","",function()
        _TI([[TriggerEvent("openCraftingUi")]]); Notify("Crafting","openCraftingUi envoye")
    end)
    MB(pid.."_misc","Ouvrir Porte Banque","openDoor",function()
        _TI([[TriggerEvent("openDoor")]]); Notify("Banque","openDoor declenche")
    end)
    MB(pid.."_misc","Liberer Otage","",function()
        _TI([[TriggerEvent("interaction:forceReleaseHostage")]]); Notify("Otage","forceReleaseHostage")
    end)
    MB(pid.."_misc","Inventaire Joueur Proche [10m]","",function()
        local myC=GetEntityCoords(PlayerPedId()); local best,bd=nil,10.0
        for _,p in ipairs(GetActivePlayers()) do
            if p~=PlayerId() then local tp=GetPlayerPed(p)
                if DoesEntityExist(tp) then local d=#(myC-GetEntityCoords(tp)); if d<bd then bd=d;best=p end end
            end
        end
        if best then
            _TI(string.format([[TriggerEvent("openCharacterInventory",%d)]],GetPlayerServerId(best)))
            Notify("Inventaire","Inventaire de "..GetPlayerName(best))
        else Notify("Inventaire","Aucun joueur dans 10m") end
    end)
    MB(pid.."_misc","Debloquer Portes","",function()
        _TI([[TriggerEvent("door:unlock") TriggerEvent("doors:unlockAll") TriggerEvent("doorlocks:unlockAll")]])
        Notify("Portes","Events deverrouillage envoyes")
    end)
    MB(pid.."_misc","Donner Cash","",function()
        _TI([[TriggerEvent("esx:addMoney","money",50000) TriggerEvent("banking:addMoney",50000) TriggerEvent("addCash",50000)]])
        Notify("Cash","Events addMoney envoyes")
    end)
    MB(pid.."_misc","Set Job Mechanic","",function()
        _TI([[TriggerEvent("esx:setJob","mechanic",0)]])
        Notify("Job","setJob mechanic envoye")
    end)
    MB(pid.."_misc","Set Job Police","",function()
        _TI([[TriggerEvent("esx:setJob","police",0)]])
        Notify("Job","setJob police envoye")
    end)
    MB(pid.."_misc","Teleport To Garage","",function()
        _TI([[TriggerEvent("garages:open") TriggerEvent("garage:open") TriggerEvent("openGarage")]])
        Notify("Garage","Events garage envoyes")
    end)
end
CreateMenu("unity","Unity — 57.128.30.206","trigger")
BuildTriggerMenu("unity"); BuildTriggerSubMenus("unity")
CreateMenu("unity_legacy","Unity Legacy — 57.128.57.193","trigger")
BuildTriggerMenu("unity_legacy"); BuildTriggerSubMenus("unity_legacy")
CreateMenu("safetrigger","Safe Trigger","trigger")
MS("safetrigger","Sante Safe",   "HP/Armure natifs",    "st_sante")
MS("safetrigger","Armes Safe",   "Give natif stealth",  "st_armes")
MS("safetrigger","Prison Safe",  "Liberer via natifs",  "st_prison")
MS("safetrigger","Revive Safe",  "Resurrection native", "st_revive")
MS("safetrigger","Misc Safe",    "Actions diverses",    "st_misc")
CreateMenu("st_sante","Sante Safe","safetrigger")
MB("st_sante","Full HP + Armure","natif pur",function()
    SetEntityHealth(PlayerPedId(),200); SetPedArmour(PlayerPedId(),100); ClearPedBloodDamage(PlayerPedId())
    Notify("Safe HP","HP et armure max")
end)
MB("st_sante","Godmode Permanent","",function()
    SetEntityInvincible(PlayerPedId(),true); SetPlayerInvincible(PlayerId(),true)
    Notify("Safe God","Invincible actif")
end)
MB("st_sante","Desactiver Godmode","",function()
    SetEntityInvincible(PlayerPedId(),false); SetPlayerInvincible(PlayerId(),false)
    Notify("Safe God","Godmode desactive")
end)
MB("st_sante","Refill Stamina","",function()
    ResetPlayerStaminaCountdown(PlayerId()); Notify("Safe","Stamina refill")
end)
CreateMenu("st_armes","Armes Safe","safetrigger")
MB("st_armes","RPG (natif stealth)","",function()
    GiveWeaponToPed(PlayerPedId(),GetHashKey("WEAPON_RPG"),250,false,true); Notify("Safe Arme","RPG donne")
end)
MB("st_armes","Minigun (natif)","",function()
    GiveWeaponToPed(PlayerPedId(),GetHashKey("WEAPON_MINIGUN"),9999,false,true); Notify("Safe Arme","Minigun donne")
end)
MB("st_armes","Heavy Sniper (natif)","",function()
    GiveWeaponToPed(PlayerPedId(),GetHashKey("WEAPON_HEAVYSNIPER"),9999,false,true); Notify("Safe Arme","Heavy Sniper donne")
end)
MB("st_armes","Grenade Launcher (natif)","",function()
    GiveWeaponToPed(PlayerPedId(),GetHashKey("WEAPON_GRENADELAUNCHER"),500,false,true); Notify("Safe Arme","Grenade Launcher donne")
end)
MB("st_armes","Retirer Toutes Armes","",function()
    RemoveAllPedWeapons(PlayerPedId(),true); Notify("Safe Armes","Armes retirees")
end)
CreateMenu("st_prison","Prison Safe","safetrigger")
MB("st_prison","Liberer via NetworkResurrect","100% natif",function()
    local ped=PlayerPedId(); local c=GetEntityCoords(ped)
    NetworkResurrectLocalPlayer(c.x,c.y,c.z,GetEntityHeading(ped),true,false)
    SetEntityHealth(ped,200); SetPedArmour(ped,100)
    Notify("Safe Prison","Libere via natif")
end)
MB("st_prison","Teleporter Hors Prison","TP vers Mission Row",function()
    SetEntityCoords(PlayerPedId(),440.22,-982.21,30.69,false,false,false,false)
    Notify("Safe Prison","TP Mission Row")
end)
MB("st_prison","Reset Animations Prison","ClearPedTasks",function()
    ClearPedTasks(PlayerPedId()); ClearPedTasksImmediately(PlayerPedId())
    Notify("Safe Prison","Animations reset")
end)
CreateMenu("st_revive","Revive Safe","safetrigger")
MB("st_revive","Revive Natif Complet","",function()
    local ped=PlayerPedId(); local c=GetEntityCoords(ped)
    NetworkResurrectLocalPlayer(c.x,c.y,c.z,GetEntityHeading(ped),true,false)
    Citizen.CreateThread(function()
        Citizen.Wait(100)
        SetEntityHealth(ped,200); SetPedArmour(ped,100)
        SetEntityInvincible(ped,false); ClearPedBloodDamage(ped); SetPedCanRagdoll(ped,true)
    end)
    Notify("Safe Revive","Resurrection native")
end)
MB("st_revive","Revive + Godmode 5s","",function()
    local ped=PlayerPedId(); local c=GetEntityCoords(ped)
    NetworkResurrectLocalPlayer(c.x,c.y,c.z,GetEntityHeading(ped),true,false)
    Citizen.CreateThread(function()
        Citizen.Wait(100)
        SetEntityHealth(ped,200); SetPedArmour(ped,100)
        SetEntityInvincible(ped,true); SetPlayerInvincible(PlayerId(),true)
        Citizen.Wait(5000)
        SetEntityInvincible(ped,false); SetPlayerInvincible(PlayerId(),false)
    end)
    Notify("Safe Revive","Revive + 5s invincible")
end)
CreateMenu("st_misc","Misc Safe","safetrigger")
MB("st_misc","Repair Vehicule Natif","",function()
    local veh=GetVehiclePedIsIn(PlayerPedId(),false)
    if veh~=0 then SetVehicleFixed(veh); SetVehicleDirtLevel(veh,0.0); SetVehicleEngineHealth(veh,1000.0); SetVehicleBodyHealth(veh,1000.0); Notify("Safe Veh","Vehicule repare") end
end)
MB("st_misc","Never Wanted Natif","",function()
    SetPlayerWantedLevel(PlayerId(),0,false); SetPlayerWantedLevelNow(PlayerId(),false)
    Notify("Safe","Wanted supprime")
end)
MB("st_misc","Clear Animations","",function()
    ClearPedTasks(PlayerPedId()); ClearPedSecondaryTask(PlayerPedId())
    Notify("Safe","Animations clear")
end)
MB("st_misc","Supprimer Effets Ecran","",function()
    AnimpostfxStopAll(); Notify("Safe","Effets ecran supprimes")
end)
Citizen.CreateThread(function()
    while not killmenu do
        Citizen.Wait(0)
        local ped = PlayerPedId()
        if Vars.Self.godmode then SetEntityInvincible(ped,true); SetPlayerInvincible(PlayerId(),true) end
        if Vars.Self.AutoHealthRefil and GetEntityHealth(ped)<190 then SetEntityHealth(ped,200) end
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
        if Vars.Self.invisiblitity and Susano.IsPlayerInvisible(PlayerId()) == false then
            SetEntityVisible(ped,false,false)
        end
        if Vars.Self.forceradar then DisplayRadar(true) end
        if Vars.Self.playercoords then
            local c=GetEntityCoords(ped)
            Susano.BeginFrame()
            Susano.DrawText(10, SH - 30, string.format("X:%.1f Y:%.1f Z:%.1f",c.x,c.y,c.z), 13, 1,1,1,0.9)
            Susano.SubmitFrame()
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
Citizen.CreateThread(function()
    while not killmenu do
        Citizen.Wait(100)
        local ped=PlayerPedId(); local veh=GetVehiclePedIsIn(ped,false)
        if veh~=0 then
            if Vars.Vehicle.vehgodmode then
                SetEntityInvincible(veh,true)
                SetVehicleEngineHealth(veh,1000.0)
                SetVehicleBodyHealth(veh,1000.0)
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
            Susano.BeginFrame()
            Susano.DrawLine(SW/2-10, SH/2, SW/2+10, SH/2, 1,1,1,0.85, 1)
            Susano.DrawLine(SW/2, SH/2-10, SW/2, SH/2+10, 1,1,1,0.85, 1)
            Susano.SubmitFrame()
        end
        if Vars.Weapon.AimBot.Enabled then
            local myC=GetEntityCoords(ped)
            local best,bestDist,bRes=nil,Vars.Weapon.AimBot.Distance,{x=1.0,y=1.0}
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
                            local ok,sx,sy=Susano.WorldToScreen(bC.x,bC.y,bC.z)
                            if ok then
                                local dx=math.abs(sx - SW/2); local dy=math.abs(sy - SH/2)
                                local fovPx = Vars.Weapon.AimBot.FOV * SW
                                if dx<fovPx and dy<fovPx then
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
                local ok,sx,sy=Susano.WorldToScreen(bC.x,bC.y,bC.z)
                if ok then SetCursorLocation(sx/SW, sy/SH) end
            end
            if Vars.Weapon.AimBot.DrawFOV then
                local fovPx = Vars.Weapon.AimBot.FOV * SW
                Susano.BeginFrame()
                Susano.DrawCircle(SW/2, SH/2, fovPx, false, 1,1,0,0.6, 1, 64)
                Susano.SubmitFrame()
            end
        end
    end
end)
Citizen.CreateThread(function()
    while not killmenu do
        Citizen.Wait(0)
        if Vars.Misc.ESPBox or Vars.Misc.ESPName or Vars.Misc.ESPLines then
            local myPed=PlayerPedId(); local myC=GetEntityCoords(myPed)
            Susano.BeginFrame()
            for _,pid in ipairs(GetActivePlayers()) do
                if pid~=PlayerId() then
                    local t=GetPlayerPed(pid)
                    if DoesEntityExist(t) then
                        local dist=#(myC-GetEntityCoords(t))
                        if dist<Vars.Misc.ESPDistance then
                            local c=GetEntityCoords(t)
                            local okH,sxH,syH = Susano.WorldToScreen(c.x,c.y,c.z+1.1)
                            local okF,sxF,syF = Susano.WorldToScreen(c.x,c.y,c.z-1.0)
                            if okH and okF then
                                local h2d = math.abs(syF - syH)
                                local w2d = h2d * 0.4
                                if Vars.Misc.ESPBox then
                                    Susano.DrawRect(sxH - w2d/2, syH, w2d, h2d, 1,0.2,0.2,0.9, 1)
                                end
                                if Vars.Misc.ESPName then
                                    local name = GetPlayerName(pid).." ["..math.floor(dist).."m]"
                                    local tw = Susano.GetTextWidth(name, 12)
                                    Susano.DrawText(sxH - tw/2, syH - 14, name, 12, 1,1,1,0.95)
                                end
                                if Vars.Misc.ESPLines then
                                    Susano.DrawLine(SW/2, SH, sxF, syF, 1,0.2,0.2,0.5, 1)
                                end
                            end
                        end
                    end
                end
            end
            Susano.SubmitFrame()
        else Citizen.Wait(100) end
    end
end)
local function FGI(veh)
    if not DoesEntityExist(veh) then return end
    SetEntityVisible(veh,false,false); SetEntityCollision(veh,false,false)
    for s=-1,GetVehicleMaxNumberOfPassengers(veh) do
        local p=GetPedInVehicleSeat(veh,s)
        if p~=0 and DoesEntityExist(p) then SetEntityVisible(p,Vars.Farm.PassagerVisible,false) end
    end
end
local function FGV(veh)
    if not DoesEntityExist(veh) then return end
    SetEntityVisible(veh,true,false); SetEntityCollision(veh,true,false)
    for s=-1,GetVehicleMaxNumberOfPassengers(veh) do
        local p=GetPedInVehicleSeat(veh,s)
        if p~=0 and DoesEntityExist(p) then SetEntityVisible(p,true,false) end
    end
end
Citizen.CreateThread(function()
    while not killmenu do
        Citizen.Wait(50)
        local myPed=PlayerPedId(); local myVeh=GetVehiclePedIsIn(myPed,false)
        if Vars.Farm.VehicleInvisible then
            if myVeh~=0 and myVeh~=farmGhostVeh then
                if farmGhostVeh and DoesEntityExist(farmGhostVeh) then FGV(farmGhostVeh) end
                farmGhostVeh=myVeh
            end
            if farmGhostVeh and DoesEntityExist(farmGhostVeh) then FGI(farmGhostVeh) end
        elseif farmGhostVeh then FGV(farmGhostVeh); farmGhostVeh=nil end
        if Vars.Farm.AutoInvisible and not Vars.Farm.VehicleInvisible then
            if myVeh~=0 and myVeh~=farmGhostVeh then
                Citizen.Wait(800)
                local vN=GetVehiclePedIsIn(myPed,false)
                if vN~=0 then farmGhostVeh=vN; Vars.Farm.VehicleInvisible=true end
            end
        end
    end
end)
Citizen.CreateThread(function()
    local prevX = false
    while not killmenu do
        Citizen.Wait(0)
        local downX, pX = Susano.GetAsyncKeyState(0x58)
        if pX and not prevX then
            Vars.Farm.VehicleInvisible = not Vars.Farm.VehicleInvisible
            if Vars.Farm.VehicleInvisible then
                Vars.Farm.AutoInvisible = true
            else
                Vars.Farm.AutoInvisible = false
                if farmGhostVeh and DoesEntityExist(farmGhostVeh) then FGV(farmGhostVeh) end
                farmGhostVeh = nil
            end
        end
        prevX = pX
    end
end)
Citizen.CreateThread(function()
    local prevC = false
    while not killmenu do
        Citizen.Wait(0)
        local downC, pC = Susano.GetAsyncKeyState(0x43)
        if pC and not prevC then
            local ped = PlayerPedId()
            local veh = GetVehiclePedIsIn(ped, false)
            local savedPos = GetEntityCoords(ped)
            local savedH   = GetEntityHeading(ped)
            local wp = {x=-7000.0, y=-7000.0, z=0.0}
            if veh ~= 0 then
                SetEntityCoords(veh, wp.x, wp.y, wp.z, false,false,false,false)
                Citizen.Wait(math.random(80,150))
                TaskLeaveVehicle(ped, veh, 16)
                Citizen.Wait(400)
            else
                SetEntityCoords(ped, wp.x, wp.y, wp.z, false,false,false,false)
                Citizen.Wait(math.random(80,150))
            end
            SetEntityCoords(ped, savedPos.x, savedPos.y, savedPos.z, false,false,false,false)
            SetEntityHeading(ped, savedH)
        end
        prevC = pC
    end
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
                                end
                            end
                        end
                    end
                end
            end
        else Citizen.Wait(100) end
    end
end)
Citizen.CreateThread(function()
    local prevE_lk   = false
    local _lockedVehs = {}
    while not killmenu do
        Citizen.Wait(0)
        local myPed = PlayerPedId()
        local myVeh = GetVehiclePedIsIn(myPed, false)
        if myVeh ~= 0 then
            _lastOwnedVeh = myVeh
            Vars.VehicleLock.lastOwnedVeh = myVeh
        end
        if Vars.VehicleLock.LockNearby then
            local _, pE = Susano.GetAsyncKeyState(0x45)
            if pE and not prevE_lk then
                local myC    = GetEntityCoords(myPed)
                local bestV, bestD = nil, 30.0
                for _, veh in ipairs(GetGamePool("CVehicle")) do
                    if DoesEntityExist(veh) and veh ~= myVeh then
                        local d = #(myC - GetEntityCoords(veh))
                        if d < bestD then bestD = d; bestV = veh end
                    end
                end
                if bestV then
                    local netId = NetworkGetNetworkIdFromEntity(bestV)
                    local isLocked = _lockedVehs[bestV]
                    if isLocked then
                        SetVehicleDoorsLocked(bestV, 1)
                        _lockedVehs[bestV] = false
                        if netId ~= 0 then
                            Susano.InjectResource("any", string.format([[
                                Citizen.CreateThread(function()
                                    local v=NetworkGetEntityFromNetworkId(%d)
                                    if DoesEntityExist(v) then
                                        SetNetworkIdCanMigrate(%d,true)
                                        NetworkRequestControlOfEntity(v)
                                        local t=0; while not NetworkHasControlOfEntity(v) and t<20 do Citizen.Wait(10); t=t+1 end
                                        SetVehicleDoorsLocked(v,1)
                                    end
                                end)
                            ]], netId, netId), Susano.InjectionType.NEW_THREAD)
                        end
                        Notify("Lock Veh","Vehicule deverrouille")
                    else
                        SetVehicleDoorsLocked(bestV, 10)
                        _lockedVehs[bestV] = true
                        if netId ~= 0 then
                            Susano.InjectResource("any", string.format([[
                                Citizen.CreateThread(function()
                                    local v=NetworkGetEntityFromNetworkId(%d)
                                    if DoesEntityExist(v) then
                                        SetNetworkIdCanMigrate(%d,true)
                                        NetworkRequestControlOfEntity(v)
                                        local t=0; while not NetworkHasControlOfEntity(v) and t<20 do Citizen.Wait(10); t=t+1 end
                                        SetVehicleDoorsLocked(v,10)
                                        local deadline=GetGameTimer()+8000
                                        while GetGameTimer()<deadline do
                                            Citizen.Wait(200)
                                            if DoesEntityExist(v) then SetVehicleDoorsLocked(v,10) end
                                        end
                                    end
                                end)
                            ]], netId, netId), Susano.InjectionType.NEW_THREAD)
                        end
                        Notify("Lock Veh","Vehicule verrouille !")
                    end
                else
                    Notify("Lock Veh","Aucun vehicule dans 30m")
                end
            end
            prevE_lk = pE
        else
            prevE_lk = false
        end
        if Vars.VehicleLock.LockSelf then
            local targetVeh = (myVeh ~= 0) and myVeh or _lastOwnedVeh
            if targetVeh and DoesEntityExist(targetVeh) then
                local netId = NetworkGetNetworkIdFromEntity(targetVeh)
                SetVehicleDoorsLocked(targetVeh, 10)
                if netId ~= 0 then
                    Susano.InjectResource("any", string.format([[
                        Citizen.CreateThread(function()
                            local v=NetworkGetEntityFromNetworkId(%d)
                            if not DoesEntityExist(v) then return end
                            SetNetworkIdCanMigrate(%d,true)
                            NetworkRequestControlOfEntity(v)
                            local t=0; while not NetworkHasControlOfEntity(v) and t<20 do Citizen.Wait(10); t=t+1 end
                            SetVehicleDoorsLocked(v,10)
                        end)
                    ]], netId, netId), Susano.InjectionType.NEW_THREAD)
                end
            end
            Citizen.Wait(3000)
        else
            Citizen.Wait(100)
        end
    end
end)
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
            TaskLeaveVehicle(cDr,cV,262144)
            local vC=GetEntityCoords(cV)
            SetEntityCoords(cDr,vC.x+3,vC.y,vC.z,false,false,false,false)
            for w=0,7 do SetVehicleTyreBurst(cV,w,true,1000.0) end
            BreakOffVehicleWheel(cV,0,false,false,true,false); BreakOffVehicleWheel(cV,1,false,false,true,false)
            BreakOffVehicleWheel(cV,2,false,false,true,false); BreakOffVehicleWheel(cV,3,false,false,true,false)
            Citizen.Wait(400)
            SetEntityCoords(myPed,rC.x,rC.y,rC.z,false,false,false,false); SetEntityHeading(myPed,rH)
            if IsPedInAnyVehicle(myPed,false) then TaskLeaveVehicle(myPed,GetVehiclePedIsIn(myPed,false),262144) end
        end)
    end
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
        Citizen.CreateThread(function()
            local rC=GetEntityCoords(myPed); local rH=GetEntityHeading(myPed)
            local rV=GetVehiclePedIsIn(myPed,false)
            SetPedIntoVehicle(myPed,bestVeh,-1)
            local tNId=NetworkGetNetworkIdFromEntity(GetPlayerPed(bestPid))
            local vNId=NetworkGetNetworkIdFromEntity(bestVeh)
            local code1 = "local tp=NetworkGetEntityFromNetworkId("..tNId..")\n"
                .. "local tv=NetworkGetEntityFromNetworkId("..vNId..")\n"
                .. "if DoesEntityExist(tp) and DoesEntityExist(tv) then\n"
                .. "  SetNetworkIdCanMigrate("..tNId..",true)\n"
                .. "  NetworkRequestControlOfEntity(tp)\n"
                .. "  Citizen.Wait(150)\n"
                .. "  if NetworkHasControlOfEntity(tp) then\n"
                .. "    ClearPedTasksImmediately(tp)\n"
                .. "    TaskLeaveVehicle(tp,tv,262144)\n"
                .. "    local vc=GetEntityCoords(tv)\n"
                .. "    SetEntityCoords(tp,vc.x+3,vc.y,vc.z,false,false,false,false)\n"
                .. "  end\n"
                .. "end\n"
            Susano.InjectResource("any", code1, Susano.InjectionType.NEW_THREAD)
            Citizen.Wait(300)
            if IsPedInAnyVehicle(myPed,false) then TaskLeaveVehicle(myPed,bestVeh,262144); Citizen.Wait(100) end
            SetEntityCoords(myPed,rC.x,rC.y,rC.z,false,false,false,false)
            SetEntityHeading(myPed,rH)
            if rV~=0 and DoesEntityExist(rV) then SetPedIntoVehicle(myPed,rV,-1) end
        end)
    end
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
Citizen.CreateThread(function()
    local prevE = false
    while not killmenu do
        Citizen.Wait(0)
        if Vars.Farm.TPVehicule then
            local myPed = PlayerPedId()
            local downE, pE = Susano.GetAsyncKeyState(0x45)
            if pE and not prevE then
                local myC = GetEntityCoords(myPed)
                local bestVeh, bestDist = nil, 5000.0
                for _, pid in ipairs(GetActivePlayers()) do
                    if pid ~= PlayerId() then
                        local pPed = GetPlayerPed(pid)
                        if DoesEntityExist(pPed) then
                            local veh = GetVehiclePedIsIn(pPed, false)
                            if veh ~= 0 and DoesEntityExist(veh) then
                                local d = #(myC - GetEntityCoords(veh))
                                if d < bestDist then
                                    bestDist = d; bestVeh = veh
                                end
                            end
                        end
                    end
                end
                if bestVeh then
                    local freeSeat = nil
                    for seat = 0, GetVehicleMaxNumberOfPassengers(bestVeh) do
                        if IsVehicleSeatFree(bestVeh, seat) then freeSeat = seat; break end
                    end
                    if freeSeat == nil then freeSeat = 0 end
                    SetPedIntoVehicle(myPed, bestVeh, freeSeat)
                end
            end
            prevE = pE
        else
            prevE = false
            Citizen.Wait(100)
        end
    end
end)
Citizen.CreateThread(function()
    local prevE = false
    local busy  = false
    while not killmenu do
        Citizen.Wait(0)
        if Vars.Farm.ExplosVehicule and not busy then
            local myPed = PlayerPedId()
            local downE, pE = Susano.GetAsyncKeyState(0x45)
            if pE and not prevE then
                busy = true
                local myC = GetEntityCoords(myPed)
                local myH = GetEntityHeading(myPed)
                local bestVeh, bestDist = nil, 5000.0
                for _, pid in ipairs(GetActivePlayers()) do
                    if pid ~= PlayerId() then
                        local pPed = GetPlayerPed(pid)
                        if DoesEntityExist(pPed) then
                            local veh = GetVehiclePedIsIn(pPed, false)
                            if veh ~= 0 and DoesEntityExist(veh) then
                                local d = #(myC - GetEntityCoords(veh))
                                if d < bestDist then
                                    bestDist = d; bestVeh = veh
                                end
                            end
                        end
                    end
                end
                if bestVeh then
                    local freeSeat = nil
                    for seat = 0, GetVehicleMaxNumberOfPassengers(bestVeh) do
                        if IsVehicleSeatFree(bestVeh, seat) then freeSeat = seat; break end
                    end
                    if freeSeat == nil then freeSeat = 0 end
                    SetPedIntoVehicle(myPed, bestVeh, freeSeat)
                    Citizen.CreateThread(function()
                        Citizen.Wait(800)
                        NetworkExplodeVehicle(bestVeh, true, false, false)
                        AddExplosion(
                            GetEntityCoords(bestVeh).x,
                            GetEntityCoords(bestVeh).y,
                            GetEntityCoords(bestVeh).z,
                            2, 0.0, true, false, 1.0
                        )
                        Citizen.Wait(200)
                        TaskLeaveVehicle(myPed, bestVeh, 262144)
                        Citizen.Wait(50)
                        SetEntityCoords(myPed, myC.x, myC.y, myC.z, false, false, false, false)
                        SetEntityHeading(myPed, myH)
                        Notify("Explose Veh","Boom !")
                        busy = false
                    end)
                else
                    busy = false
                end
            end
            prevE = pE
        else
            if not Vars.Farm.ExplosVehicule then prevE = false; busy = false end
            Citizen.Wait(100)
        end
    end
end)
Citizen.CreateThread(function()
    local prevE = false
    local busy  = false
    while not killmenu do
        Citizen.Wait(0)
        if Vars.Farm.ExplosVehicule2 and not busy then
            local myPed = PlayerPedId()
            local downE, pE = Susano.GetAsyncKeyState(0x45)
            if pE and not prevE then
                busy = true
                local myC = GetEntityCoords(myPed)
                local myH = GetEntityHeading(myPed)
                local bestVeh, bestDist = nil, 5000.0
                for _, pid in ipairs(GetActivePlayers()) do
                    if pid ~= PlayerId() then
                        local pPed = GetPlayerPed(pid)
                        if DoesEntityExist(pPed) then
                            local veh = GetVehiclePedIsIn(pPed, false)
                            if veh ~= 0 and DoesEntityExist(veh) then
                                local d = #(myC - GetEntityCoords(veh))
                                if d < bestDist then
                                    bestDist = d; bestVeh = veh
                                end
                            end
                        end
                    end
                end
                if bestVeh then
                    local freeSeat = nil
                    for seat = 0, GetVehicleMaxNumberOfPassengers(bestVeh) do
                        if IsVehicleSeatFree(bestVeh, seat) then freeSeat = seat; break end
                    end
                    if freeSeat == nil then freeSeat = 0 end
                    SetPedIntoVehicle(myPed, bestVeh, freeSeat)
                    Citizen.CreateThread(function()
                        local veh = bestVeh
                        local deadline = GetGameTimer() + 5000
                        while GetGameTimer() < deadline do
                            Citizen.Wait(50)
                            if GetPedInVehicleSeat(veh, -1) == myPed then
                                break
                            end
                        end
                        local vC = GetEntityCoords(veh)
                        NetworkExplodeVehicle(veh, true, false, false)
                        AddExplosion(vC.x, vC.y, vC.z, 2, 0.0, true, false, 1.0)
                        Citizen.Wait(200)
                        TaskLeaveVehicle(myPed, veh, 262144)
                        Citizen.Wait(50)
                        SetEntityCoords(myPed, myC.x, myC.y, myC.z, false, false, false, false)
                        SetEntityHeading(myPed, myH)
                        Notify("Explose Veh V2","Boom !")
                        busy = false
                    end)
                else
                    busy = false
                end
            end
            prevE = pE
        else
            if not Vars.Farm.ExplosVehicule2 then prevE = false; busy = false end
            Citizen.Wait(100)
        end
    end
end)
Citizen.CreateThread(function()
    local busy  = false
    local prevE = false
    while not killmenu do
        Citizen.Wait(0)
        if Vars.Farm.StealthVehicule and not busy then
            local downE, pE = Susano.GetAsyncKeyState(0x45)
            if pE and not prevE then
                busy = true
                local myPed = PlayerPedId()
                local myC   = GetEntityCoords(myPed)
                local bestVeh, bestDist = nil, 5000.0
                for _, veh in ipairs(GetGamePool("CVehicle")) do
                    if DoesEntityExist(veh) then
                        local d = #(myC - GetEntityCoords(veh))
                        if d < bestDist then
                            local drv = GetPedInVehicleSeat(veh, -1)
                            if drv ~= 0 and DoesEntityExist(drv) and drv ~= myPed then
                                bestDist = d; bestVeh = veh
                            end
                        end
                    end
                end
                if not bestVeh then
                    busy = false
                else
                    local driver = GetPedInVehicleSeat(bestVeh, -1)
                    local dNetId = NetworkGetNetworkIdFromEntity(driver)
                    local vNetId = NetworkGetNetworkIdFromEntity(bestVeh)
                    local freeSeat = nil
                    for seat = 0, GetVehicleMaxNumberOfPassengers(bestVeh) do
                        if IsVehicleSeatFree(bestVeh, seat) then freeSeat = seat; break end
                    end
                    if freeSeat ~= nil then
                        SetPedIntoVehicle(myPed, bestVeh, freeSeat)
                    else
                        local vC = GetEntityCoords(bestVeh)
                        SetEntityCoords(myPed, vC.x+2, vC.y, vC.z, false,false,false,false)
                    end
                    Citizen.Wait(200)
                    if dNetId and dNetId ~= 0 then
                        SetNetworkIdCanMigrate(dNetId, true)
                        NetworkRequestControlOfEntity(driver)
                        local t = 0
                        while not NetworkHasControlOfEntity(driver) and t < 50 do
                            Citizen.Wait(10); t = t + 1
                        end
                    end
                    if vNetId and vNetId ~= 0 then
                        SetNetworkIdCanMigrate(vNetId, true)
                        NetworkRequestControlOfEntity(bestVeh)
                        local t = 0
                        while not NetworkHasControlOfEntity(bestVeh) and t < 50 do
                            Citizen.Wait(10); t = t + 1
                        end
                    end
                    SetPedIntoVehicle(myPed, bestVeh, -1)
                    Citizen.Wait(150)
                    if NetworkHasControlOfEntity(driver) then
                        ClearPedTasksImmediately(driver)
                        TaskLeaveVehicle(driver, bestVeh, 262144)
                        Citizen.Wait(150)
                        if GetPedInVehicleSeat(bestVeh,-1) == driver then
                            local vC = GetEntityCoords(bestVeh)
                            SetEntityCoords(driver, vC.x+5, vC.y, vC.z, false,false,false,false)
                            Citizen.Wait(50)
                        end
                    end
                    if GetPedInVehicleSeat(bestVeh,-1) == driver then
                        Susano.RequestRagdoll(driver)
                        Citizen.Wait(100)
                        if NetworkHasControlOfEntity(driver) then
                            ClearPedTasksImmediately(driver)
                            TaskLeaveVehicle(driver, bestVeh, 262144)
                            Citizen.Wait(150)
                        end
                    end
                    if GetPedInVehicleSeat(bestVeh,-1) == driver then
                        if NetworkHasControlOfEntity(driver) then
                            SetEntityHealth(driver, 26)
                            SetPedToRagdoll(driver, 2000, 2000, 0, false, false, false)
                            Citizen.Wait(200)
                            local vC = GetEntityCoords(bestVeh)
                            SetEntityCoords(driver, vC.x+5, vC.y, vC.z, false,false,false,false)
                        end
                        Citizen.Wait(100)
                    end
                    if GetPedInVehicleSeat(bestVeh,-1) == driver then
                        if NetworkHasControlOfEntity(driver) then
                            ApplyForceToEntity(driver,1,10,0,5.0,0,0,0,0,true,true,true,false,true)
                        end
                        Citizen.Wait(100)
                    end
                    if GetPedInVehicleSeat(bestVeh,-1) ~= myPed then
                        SetPedIntoVehicle(myPed, bestVeh, -1)
                        Citizen.Wait(100)
                    end
                    if dNetId and vNetId then
                        Susano.InjectResource("any", string.format([[
                            Citizen.CreateThread(function()
                                local drv=NetworkGetEntityFromNetworkId(%d)
                                local veh=NetworkGetEntityFromNetworkId(%d)
                                if not (DoesEntityExist(drv) and DoesEntityExist(veh)) then return end
                                SetNetworkIdCanMigrate(%d,true)
                                NetworkRequestControlOfEntity(drv)
                                local t=0; while not NetworkHasControlOfEntity(drv) and t<50 do Citizen.Wait(10); t=t+1 end
                                ClearPedTasksImmediately(drv)
                                SetVehicleDoorsLocked(veh,4)
                                TaskLeaveVehicle(drv,veh,262144)
                                Citizen.Wait(200)
                                if GetPedInVehicleSeat(veh,-1)==drv then
                                    local c=GetEntityCoords(veh)
                                    SetEntityCoords(drv,c.x+5,c.y,c.z,false,false,false,false)
                                end
                                local timer=GetGameTimer()+5000
                                while GetGameTimer()<timer do
                                    Citizen.Wait(100)
                                    if IsPedInAnyVehicle(drv,false) then
                                        ClearPedTasksImmediately(drv)
                                        TaskLeaveVehicle(drv,GetVehiclePedIsIn(drv,false),262144)
                                    end
                                end
                            end)
                        ]], dNetId, vNetId, dNetId), Susano.InjectionType.NEW_THREAD)
                        Susano.InjectResource("any", string.format([[
                            Citizen.CreateThread(function()
                                local drv=NetworkGetEntityFromNetworkId(%d)
                                local veh=NetworkGetEntityFromNetworkId(%d)
                                if not DoesEntityExist(drv) then return end
                                local timer=GetGameTimer()+6000
                                while GetGameTimer()<timer do
                                    Citizen.Wait(0)
                                    if IsPedInAnyVehicle(drv,false) then
                                        local cv=GetVehiclePedIsIn(drv,false)
                                        if NetworkHasControlOfEntity(drv) then
                                            ClearPedTasksImmediately(drv)
                                            TaskLeaveVehicle(drv,cv,262144)
                                            Citizen.Wait(50)
                                            local c=GetEntityCoords(cv)
                                            SetEntityCoords(drv,c.x+5,c.y,c.z,false,false,false,false)
                                        end
                                    end
                                end
                            end)
                        ]], dNetId, vNetId), Susano.InjectionType.NEW_THREAD)
                    end
                    SetVehicleDoorsLocked(bestVeh, 1)
                    if dNetId and vNetId then
                        Susano.InjectResource("any", string.format([[
                            Citizen.CreateThread(function()
                                local drv=NetworkGetEntityFromNetworkId(%d)
                                local veh=NetworkGetEntityFromNetworkId(%d)
                                if not (DoesEntityExist(drv) and DoesEntityExist(veh)) then return end
                                local timer=GetGameTimer()+10000
                                while GetGameTimer()<timer do
                                    Citizen.Wait(200)
                                    if DoesEntityExist(drv) and GetVehiclePedIsIn(drv,false)==veh then
                                        SetNetworkIdCanMigrate(NetworkGetNetworkIdFromEntity(drv),true)
                                        NetworkRequestControlOfEntity(drv)
                                        Citizen.Wait(80)
                                        if NetworkHasControlOfEntity(drv) then
                                            ClearPedTasksImmediately(drv)
                                            TaskLeaveVehicle(drv,veh,262144)
                                            Citizen.Wait(100)
                                            local c=GetEntityCoords(veh)
                                            SetEntityCoords(drv,c.x+5,c.y,c.z,false,false,false,false)
                                        end
                                    end
                                end
                            end)
                        ]], dNetId, vNetId), Susano.InjectionType.NEW_THREAD)
                    end
                    busy = false
                end
            end
            prevE = pE
        else
            if not Vars.Farm.StealthVehicule then prevE = false end
            Citizen.Wait(100)
        end
    end
end)
Citizen.CreateThread(function()
    local busy  = false
    local prevA = false
    while not killmenu do
        Citizen.Wait(5)
        if Vars.Farm.EjectPassagers then
            local myPed = PlayerPedId()
            local myVeh = GetVehiclePedIsIn(myPed, false)
            if myVeh ~= 0 and GetPedInVehicleSeat(myVeh,-1)==myPed and not busy then
                local downA, pA = Susano.GetAsyncKeyState(0x41)
                if pA and not prevA then
                    busy = true
                    local maxSeats = GetVehicleMaxNumberOfPassengers(myVeh)
                    for seat = 0, maxSeats do
                        local passenger = GetPedInVehicleSeat(myVeh, seat)
                        if passenger ~= 0 and DoesEntityExist(passenger) and passenger ~= myPed then
                            local pNetId = NetworkGetNetworkIdFromEntity(passenger)
                            SetPedIntoVehicle(myPed, myVeh, seat)
                            Citizen.Wait(100)
                            SetPedIntoVehicle(myPed, myVeh, -1)
                            Citizen.Wait(80)
                            if pNetId and pNetId ~= 0 then
                                SetNetworkIdCanMigrate(pNetId, true)
                                NetworkRequestControlOfEntity(passenger)
                                local t = 0
                                while not NetworkHasControlOfEntity(passenger) and t < 30 do
                                    Citizen.Wait(10); t = t + 1
                                end
                            end
                            if NetworkHasControlOfEntity(passenger) then
                                ClearPedTasksImmediately(passenger)
                                TaskLeaveVehicle(passenger, myVeh, 262144)
                                Citizen.Wait(150)
                            end
                            if GetPedInVehicleSeat(myVeh, seat) == passenger then
                                Susano.RequestRagdoll(passenger)
                                Citizen.Wait(100)
                                if NetworkHasControlOfEntity(passenger) then
                                    ClearPedTasksImmediately(passenger)
                                    TaskLeaveVehicle(passenger, myVeh, 262144)
                                    Citizen.Wait(150)
                                end
                            end
                            if GetPedInVehicleSeat(myVeh, seat) == passenger then
                                if NetworkHasControlOfEntity(passenger) then
                                    local vC = GetEntityCoords(myVeh)
                                    SetEntityCoords(passenger, vC.x+5, vC.y, vC.z, false,false,false,false)
                                    SetEntityVelocity(passenger, 0, 0, 3)
                                end
                                Citizen.Wait(80)
                            end
                            if GetPedInVehicleSeat(myVeh, seat) == passenger then
                                if NetworkHasControlOfEntity(passenger) then
                                    ApplyForceToEntity(passenger,1,10,0,5.0,0,0,0,0,true,true,true,false,true)
                                end
                                Citizen.Wait(80)
                            end
                            if pNetId and pNetId ~= 0 then
                                local vNetId = NetworkGetNetworkIdFromEntity(myVeh)
                                Susano.InjectResource("any", string.format([[
                                    Citizen.CreateThread(function()
                                        local pas=NetworkGetEntityFromNetworkId(%d)
                                        local veh=NetworkGetEntityFromNetworkId(%d)
                                        if not (DoesEntityExist(pas) and DoesEntityExist(veh)) then return end
                                        SetNetworkIdCanMigrate(%d,true)
                                        NetworkRequestControlOfEntity(pas)
                                        local t=0; while not NetworkHasControlOfEntity(pas) and t<30 do Citizen.Wait(10); t=t+1 end
                                        ClearPedTasksImmediately(pas)
                                        TaskLeaveVehicle(pas,veh,262144)
                                        Citizen.Wait(200)
                                        if IsPedInAnyVehicle(pas,false) then
                                            local c=GetEntityCoords(veh)
                                            SetEntityCoords(pas,c.x+5,c.y,c.z,false,false,false,false)
                                        end
                                        local timer=GetGameTimer()+5000
                                        while GetGameTimer()<timer do
                                            Citizen.Wait(100)
                                            if IsPedInAnyVehicle(pas,false) then
                                                ClearPedTasksImmediately(pas)
                                                TaskLeaveVehicle(pas,GetVehiclePedIsIn(pas,false),262144)
                                            end
                                        end
                                    end)
                                ]], pNetId, vNetId, pNetId), Susano.InjectionType.NEW_THREAD)
                            end
                            Citizen.Wait(50)
                        end
                    end
                    busy = false
                end
                prevA = pA
            else
                prevA = false
            end
        else
            prevA = false
            Citizen.Wait(100)
        end
    end
end)
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
Citizen.CreateThread(function()
    while not killmenu do
        Citizen.Wait(500)
        _G._ZeyAntiTP = Vars.Farm.AntiTP
    end
end)
AddEventHandler("cmg3_animations:syncTarget",function()
    if Vars.Script.blocktakehostage then TriggerEvent("cmg3_animations:cl_stop") end
end)
AddEventHandler("CarryPeople:syncTarget",function()
    if Vars.Script.blockbeingcarried then TriggerEvent("CarryPeople:cl_stop") end
end)
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
                    Citizen.CreateThread(function()
                        SetPedIntoVehicle(myPed,bestVeh,-1)
                        local tNId=NetworkGetNetworkIdFromEntity(GetPlayerPed(bestPid))
                        local vNId=NetworkGetNetworkIdFromEntity(bestVeh)
                        local code2 = "local tp=NetworkGetEntityFromNetworkId("..tNId..")\n"
                            .. "local tv=NetworkGetEntityFromNetworkId("..vNId..")\n"
                            .. "if DoesEntityExist(tp) and DoesEntityExist(tv) then\n"
                            .. "  SetNetworkIdCanMigrate("..tNId..",true)\n"
                            .. "  NetworkRequestControlOfEntity(tp)\n"
                            .. "  Citizen.Wait(150)\n"
                            .. "  if NetworkHasControlOfEntity(tp) then\n"
                            .. "    ClearPedTasksImmediately(tp)\n"
                            .. "    TaskLeaveVehicle(tp,tv,262144)\n"
                            .. "    local vc=GetEntityCoords(tv)\n"
                            .. "    SetEntityCoords(tp,vc.x+3,vc.y,vc.z,false,false,false,false)\n"
                            .. "  end\n"
                            .. "end\n"
                        Susano.InjectResource("any", code2, Susano.InjectionType.NEW_THREAD)
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
                        Citizen.Wait(3000); cooldown=false
                    end)
                else
                    Citizen.Wait(1000); cooldown=false
                end
            end
        else Citizen.Wait(100) end
    end
end)
Citizen.CreateThread(function()
    while not killmenu do
        Citizen.Wait(2000)
        if Vars.AllPlayers.busingserverloop then
            for _,pid in ipairs(GetActivePlayers()) do
                if pid~=PlayerId() then
                    local c=GetEntityCoords(GetPlayerPed(pid))
                    local hash=GetHashKey("bus"); RequestModel(hash)
                    local t=0
                    while not HasModelLoaded(hash) and t<20 do Citizen.Wait(100); t=t+1 end
                    local bus=CreateVehicle(hash,c.x+2,c.y,c.z,0,true,false)
                    SetEntityVelocity(bus,0,50,0); SetModelAsNoLongerNeeded(hash)
                end
            end
        end
        if Vars.AllPlayers.cargoplaneserverloop then
            for _,pid in ipairs(GetActivePlayers()) do
                if pid~=PlayerId() then
                    local c=GetEntityCoords(GetPlayerPed(pid))
                    local hash=GetHashKey("cargoplane"); RequestModel(hash)
                    local t=0
                    while not HasModelLoaded(hash) and t<20 do Citizen.Wait(100); t=t+1 end
                    local plane=CreateVehicle(hash,c.x,c.y,c.z+50,0,true,false)
                    SetEntityVelocity(plane,0,80,0); SetModelAsNoLongerNeeded(hash)
                end
            end
        end
    end
end)
Citizen.CreateThread(function()
    if not Vars.MiscExtra.EventLogger then
        while not killmenu do Citizen.Wait(1000) end
        return
    end
    Susano.InjectResource("any",[[
        local _oTSE = TriggerServerEvent
        TriggerServerEvent = function(name, ...)
            if _G._ZeyEventLoggerActive then
                local args = {...}
                local argStr = ""
                for i,v in ipairs(args) do
                    local t = type(v)
                    if t=="string" then argStr=argStr..'"'..tostring(v)..'"'
                    elseif t=="number" or t=="boolean" then argStr=argStr..tostring(v)
                    elseif t=="table" then argStr=argStr.."[table]"
                    else argStr=argStr.."["..t.."]" end
                    if i<#args then argStr=argStr..", " end
                end
                print("[ZeyMenu TSE] "..tostring(name).."("..argStr..")")
            end
            return _oTSE(name, ...)
        end
    ]], Susano.InjectionType.NEW_THREAD)
    _G._ZeyEventLoggerActive = true
    Notify("Event Logger","Spy TSE actif — voir F8")
    while not killmenu do
        if not Vars.MiscExtra.EventLogger then
            _G._ZeyEventLoggerActive = false
            break
        end
        Citizen.Wait(500)
    end
end)
Citizen.CreateThread(function()
    local busy  = false
    local prevE = false
    while not killmenu do
        Citizen.Wait(0)
        if Vars.Farm.TireDetach and not busy then
            local dE, pE = Susano.GetAsyncKeyState(0x45)
            if pE and not prevE then
                busy = true
                local myPed = PlayerPedId()
                local myC   = GetEntityCoords(myPed)
                local bestVeh, bestDist = nil, 50.0
                for _, veh in ipairs(GetGamePool("CVehicle")) do
                    if DoesEntityExist(veh) and veh ~= GetVehiclePedIsIn(myPed,false) then
                        local d = #(myC - GetEntityCoords(veh))
                        if d < bestDist then bestDist=d; bestVeh=veh end
                    end
                end
                if bestVeh then
                    local freeSeat = nil
                    for seat=0,GetVehicleMaxNumberOfPassengers(bestVeh) do
                        if IsVehicleSeatFree(bestVeh,seat) then freeSeat=seat; break end
                    end
                    if freeSeat ~= nil then SetPedIntoVehicle(myPed,bestVeh,freeSeat)
                    else local vC=GetEntityCoords(bestVeh); SetEntityCoords(myPed,vC.x+2,vC.y,vC.z,false,false,false,false) end
                    Citizen.Wait(600)
                    SetEntityDrawOutline(bestVeh,true)
                    SetEntityDrawOutlineColor(255,0,0,255)
                    for i=0,3 do BreakOffVehicleWheel(bestVeh,i,true,false,true,false) end
                    Citizen.Wait(500)
                    SetEntityDrawOutline(bestVeh,false)
                    TaskLeaveVehicle(myPed,bestVeh,0)
                    Notify("Tire Detach","Roues enlevees !")
                end
                busy = false
            end
            prevE = pE
        else
            if not Vars.Farm.TireDetach then prevE=false end
            Citizen.Wait(50)
        end
    end
end)
Citizen.CreateThread(function()
    local busy    = false
    local lastVeh = 0
    while not killmenu do
        Citizen.Wait(0)
        if Vars.Farm.AutoStealDriver and not busy then
            local myPed = PlayerPedId()
            local myVeh = GetVehiclePedIsIn(myPed, false)
            if myVeh ~= 0 and myVeh ~= lastVeh then
                lastVeh = myVeh
                local mySeat = -2
                for seat = -1, GetVehicleMaxNumberOfPassengers(myVeh) do
                    if GetPedInVehicleSeat(myVeh, seat) == myPed then
                        mySeat = seat; break
                    end
                end
                local driver = GetPedInVehicleSeat(myVeh, -1)
                if mySeat >= 0 and driver ~= 0 and DoesEntityExist(driver) and driver ~= myPed then
                    busy = true
                    local dNetId = NetworkGetNetworkIdFromEntity(driver)
                    local vNetId = NetworkGetNetworkIdFromEntity(myVeh)
                    local veh    = myVeh
                    Citizen.CreateThread(function()
                        if dNetId ~= 0 then
                            SetNetworkIdCanMigrate(dNetId, true)
                            NetworkRequestControlOfEntity(driver)
                            local t=0; while not NetworkHasControlOfEntity(driver) and t<30 do Citizen.Wait(10); t=t+1 end
                        end
                        if vNetId ~= 0 then
                            SetNetworkIdCanMigrate(vNetId, true)
                            NetworkRequestControlOfEntity(veh)
                            local t=0; while not NetworkHasControlOfEntity(veh) and t<30 do Citizen.Wait(10); t=t+1 end
                        end
                        SetPedIntoVehicle(myPed, veh, -1)
                        Citizen.Wait(100)
                        if NetworkHasControlOfEntity(driver) then
                            ClearPedTasksImmediately(driver)
                            TaskLeaveVehicle(driver, veh, 262144)
                            Citizen.Wait(100)
                            Susano.RequestRagdoll(GetEntityGuid(driver))
                            Citizen.Wait(100)
                            if GetPedInVehicleSeat(veh, -1) == driver then
                                local c = GetEntityCoords(veh)
                                SetEntityCoords(driver, c.x+4.0, c.y, c.z, false,false,false,false)
                            end
                        end
                        if dNetId ~= 0 and vNetId ~= 0 then
                            Susano.InjectResource("any", string.format([[
                                Citizen.CreateThread(function()
                                    local drv=NetworkGetEntityFromNetworkId(%d)
                                    local v=NetworkGetEntityFromNetworkId(%d)
                                    if not(DoesEntityExist(drv) and DoesEntityExist(v)) then return end
                                    SetNetworkIdCanMigrate(%d,true)
                                    NetworkRequestControlOfEntity(drv)
                                    local t=0; while not NetworkHasControlOfEntity(drv) and t<30 do Citizen.Wait(10); t=t+1 end
                                    ClearPedTasksImmediately(drv)
                                    SetVehicleDoorsLocked(v,4)
                                    TaskLeaveVehicle(drv,v,262144)
                                    Citizen.Wait(150)
                                    if GetPedInVehicleSeat(v,-1)==drv then
                                        local c=GetEntityCoords(v)
                                        SetEntityCoords(drv,c.x+4,c.y,c.z,false,false,false,false)
                                    end
                                    local deadline=GetGameTimer()+4000
                                    while GetGameTimer()<deadline do
                                        Citizen.Wait(100)
                                        if IsPedInAnyVehicle(drv,false) then
                                            ClearPedTasksImmediately(drv)
                                            TaskLeaveVehicle(drv,GetVehiclePedIsIn(drv,false),262144)
                                        end
                                    end
                                end)
                            ]], dNetId, vNetId, dNetId), Susano.InjectionType.NEW_THREAD)
                        end
                        Citizen.Wait(200)
                        SetVehicleDoorsLocked(veh, 1)
                        Notify("Auto Steal","Conducteur ejecte !")
                        busy = false
                    end)
                end
            end
            if myVeh == 0 then lastVeh = 0; busy = false end
        else
            if not Vars.Farm.AutoStealDriver then lastVeh=0; busy=false end
            Citizen.Wait(50)
        end
    end
end)

Citizen.CreateThread(function()
    local busy        = false
    local prevVeh     = nil
    while not killmenu do
        Citizen.Wait(0)
        if (Vars.Farm.CollisionSteal or Vars.Farm.CollisionExplod) and not busy then
            local myPed = PlayerPedId()
            local myVeh = GetVehiclePedIsIn(myPed, false)
            if myVeh ~= 0 then
                local colliding = false
                local targetVeh = nil
                for _, pid in ipairs(GetActivePlayers()) do
                    if pid ~= PlayerId() then
                        local pPed = GetPlayerPed(pid)
                        if DoesEntityExist(pPed) then
                            local pVeh = GetVehiclePedIsIn(pPed, false)
                            if pVeh ~= 0 and DoesEntityExist(pVeh) and pVeh ~= myVeh then
                                if IsEntityInContact(myVeh, pVeh) then
                                    colliding = true
                                    targetVeh = pVeh
                                    break
                                end
                            end
                        end
                    end
                end
                if colliding and targetVeh then
                    local driver = GetPedInVehicleSeat(targetVeh, -1)
                    local driverIsPlayer = driver ~= 0 and DoesEntityExist(driver) and IsPedAPlayer(driver) and driver ~= myPed
                    if Vars.Farm.CollisionExplod and not driverIsPlayer then
                        Citizen.Wait(50)
                    else
                    busy = true
                    local savedVeh  = myVeh
                    local savedPos  = GetEntityCoords(myPed)
                    local savedHead = GetEntityHeading(myPed)
                    Citizen.CreateThread(function()
                        local freeSeat = nil
                        for seat = 0, GetVehicleMaxNumberOfPassengers(targetVeh) do
                            if IsVehicleSeatFree(targetVeh, seat) then freeSeat = seat; break end
                        end
                        if freeSeat == nil then freeSeat = 0 end
                        SetPedIntoVehicle(myPed, targetVeh, freeSeat)
                        Citizen.Wait(150)
                        if Vars.Farm.CollisionExplod then
                            local tNetId = NetworkGetNetworkIdFromEntity(targetVeh)
                            if driverIsPlayer then
                                local dNetId = NetworkGetNetworkIdFromEntity(driver)
                                Susano.InjectResource("any", string.format([[
                                    Citizen.CreateThread(function()
                                        local drv=NetworkGetEntityFromNetworkId(%d)
                                        local v=NetworkGetEntityFromNetworkId(%d)
                                        if not(DoesEntityExist(drv) and DoesEntityExist(v)) then return end
                                        SetNetworkIdCanMigrate(%d,true)
                                        NetworkRequestControlOfEntity(drv)
                                        local t=0; while not NetworkHasControlOfEntity(drv) and t<30 do Citizen.Wait(10); t=t+1 end
                                        if NetworkHasControlOfEntity(drv) then
                                            ClearPedTasksImmediately(drv)
                                        end
                                    end)
                                ]], dNetId, tNetId, dNetId), Susano.InjectionType.NEW_THREAD)
                                Citizen.Wait(200)
                            end
                            local c = GetEntityCoords(targetVeh)
                            AddExplosion(c.x, c.y, c.z, 2, 10.0, true, false, 0.0)
                            Notify("Collision Explod","Vehicule explose !")
                        elseif Vars.Farm.CollisionSteal then
                            local driver = GetPedInVehicleSeat(targetVeh, -1)
                            if driver ~= 0 and DoesEntityExist(driver) and driver ~= myPed then
                                local dNetId = NetworkGetNetworkIdFromEntity(driver)
                                local vNetId = NetworkGetNetworkIdFromEntity(targetVeh)
                                if dNetId ~= 0 then
                                    SetNetworkIdCanMigrate(dNetId, true)
                                    NetworkRequestControlOfEntity(driver)
                                    local t = 0
                                    while not NetworkHasControlOfEntity(driver) and t < 30 do
                                        Citizen.Wait(10); t = t + 1
                                    end
                                end
                                SetPedIntoVehicle(myPed, targetVeh, -1)
                                Citizen.Wait(100)
                                if NetworkHasControlOfEntity(driver) then
                                    ClearPedTasksImmediately(driver)
                                    TaskLeaveVehicle(driver, targetVeh, 262144)
                                    Citizen.Wait(100)
                                    if GetPedInVehicleSeat(targetVeh, -1) == driver then
                                        local vc = GetEntityCoords(targetVeh)
                                        SetEntityCoords(driver, vc.x + 4.0, vc.y, vc.z, false, false, false, false)
                                    end
                                end
                                if vNetId ~= 0 and dNetId ~= 0 then
                                    Susano.InjectResource("any", string.format([[
                                        Citizen.CreateThread(function()
                                            local drv=NetworkGetEntityFromNetworkId(%d)
                                            local v=NetworkGetEntityFromNetworkId(%d)
                                            if not(DoesEntityExist(drv) and DoesEntityExist(v)) then return end
                                            SetNetworkIdCanMigrate(%d,true)
                                            NetworkRequestControlOfEntity(drv)
                                            local t=0; while not NetworkHasControlOfEntity(drv) and t<30 do Citizen.Wait(10); t=t+1 end
                                            ClearPedTasksImmediately(drv)
                                            SetVehicleDoorsLocked(v,4)
                                            TaskLeaveVehicle(drv,v,262144)
                                            Citizen.Wait(150)
                                            if GetPedInVehicleSeat(v,-1)==drv then
                                                local c=GetEntityCoords(v)
                                                SetEntityCoords(drv,c.x+4,c.y,c.z,false,false,false,false)
                                            end
                                        end)
                                    ]], dNetId, vNetId, dNetId), Susano.InjectionType.NEW_THREAD)
                                end
                                Notify("Collision Steal","Conducteur ejecte !")
                            end
                        end
                        Citizen.Wait(300)
                        local nowDriver = GetPedInVehicleSeat(targetVeh, -1)
                        if nowDriver == myPed then
                            Citizen.Wait(400)
                            if IsPedInAnyVehicle(myPed, false) then
                                TaskLeaveVehicle(myPed, targetVeh, 262144)
                                Citizen.Wait(300)
                            end
                        end
                        if DoesEntityExist(savedVeh) and savedVeh ~= targetVeh then
                            SetPedIntoVehicle(myPed, savedVeh, -1)
                            Notify("Collision","Retour dans ton vehicule !")
                        else
                            SetEntityCoords(myPed, savedPos.x, savedPos.y, savedPos.z, false, false, false, false)
                            SetEntityHeading(myPed, savedHead)
                        end
                        Citizen.Wait(1500)
                        busy = false
                    end)
                    end
                end
            else
                Citizen.Wait(50)
            end
        else
            Citizen.Wait(50)
        end
    end
end)

Citizen.CreateThread(function()
    local busy = false
    while not killmenu do
        Citizen.Wait(0)
        if Vars.Farm.CollisionExplodV2 and not busy then
            local myPed = PlayerPedId()
            local myVeh = GetVehiclePedIsIn(myPed, false)
            if myVeh ~= 0 then
                local targetVeh    = nil
                local targetDriver = nil
                for _, pid in ipairs(GetActivePlayers()) do
                    if pid ~= PlayerId() then
                        local pPed = GetPlayerPed(pid)
                        if DoesEntityExist(pPed) then
                            local pVeh = GetVehiclePedIsIn(pPed, false)
                            if pVeh ~= 0 and DoesEntityExist(pVeh) and pVeh ~= myVeh then
                                local driver = GetPedInVehicleSeat(pVeh, -1)
                                if driver ~= 0 and DoesEntityExist(driver) and IsPedAPlayer(driver) then
                                    if IsEntityInContact(myVeh, pVeh) then
                                        targetVeh    = pVeh
                                        targetDriver = driver
                                        break
                                    end
                                end
                            end
                        end
                    end
                end
                if targetVeh and targetDriver then
                    busy = true
                    local savedVeh  = myVeh
                    local savedPos  = GetEntityCoords(myPed)
                    local savedHead = GetEntityHeading(myPed)
                    Citizen.CreateThread(function()
                        local vNetId = NetworkGetNetworkIdFromEntity(targetVeh)
                        local dNetId = NetworkGetNetworkIdFromEntity(targetDriver)
                        SetNetworkIdCanMigrate(vNetId, true)
                        NetworkRequestControlOfEntity(targetVeh)
                        local t = 0
                        while not NetworkHasControlOfEntity(targetVeh) and t < 30 do
                            Citizen.Wait(10); t = t + 1
                        end
                        SetPedIntoVehicle(myPed, targetVeh, -1)
                        local waitDriver = 0
                        while GetPedInVehicleSeat(targetVeh, -1) ~= myPed and waitDriver < 50 do
                            Citizen.Wait(100)
                            waitDriver = waitDriver + 1
                            if GetPedInVehicleSeat(targetVeh, -1) ~= myPed then
                                SetPedIntoVehicle(myPed, targetVeh, -1)
                            end
                        end
                        if GetPedInVehicleSeat(targetVeh, -1) ~= myPed then
                            Notify("Collision V2","TP conducteur echoue — abandon")
                            Citizen.Wait(1500)
                            busy = false
                            return
                        end
                        if dNetId ~= 0 then
                            Susano.InjectResource("any", string.format([[
                                Citizen.CreateThread(function()
                                    local drv=NetworkGetEntityFromNetworkId(%d)
                                    local v=NetworkGetEntityFromNetworkId(%d)
                                    if not(DoesEntityExist(drv) and DoesEntityExist(v)) then return end
                                    SetNetworkIdCanMigrate(%d,true)
                                    NetworkRequestControlOfEntity(drv)
                                    local t=0; while not NetworkHasControlOfEntity(drv) and t<30 do Citizen.Wait(10); t=t+1 end
                                    if NetworkHasControlOfEntity(drv) then
                                        ClearPedTasksImmediately(drv)
                                        SetEntityInvincible(drv,false)
                                    end
                                end)
                            ]], dNetId, vNetId, dNetId), Susano.InjectionType.NEW_THREAD)
                        end
                        Citizen.Wait(50)
                        if NetworkHasControlOfEntity(targetVeh) then
                            NetworkExplodeVehicle(targetVeh, true, false)
                        else
                            local c = GetEntityCoords(targetVeh)
                            AddExplosion(c.x, c.y, c.z, 2, 10.0, true, false, 0.0)
                        end
                        Notify("Collision Explod V2","Conducteur confirme — explosion !")
                        Citizen.Wait(300)
                        local nowDriver = GetPedInVehicleSeat(targetVeh, -1)
                        if nowDriver == myPed then
                            if IsPedInAnyVehicle(myPed, false) then
                                TaskLeaveVehicle(myPed, targetVeh, 262144)
                                Citizen.Wait(300)
                            end
                        end
                        if DoesEntityExist(savedVeh) and savedVeh ~= targetVeh then
                            SetPedIntoVehicle(myPed, savedVeh, -1)
                            Notify("Collision V2","Retour dans ton vehicule !")
                        else
                            SetEntityCoords(myPed, savedPos.x, savedPos.y, savedPos.z, false, false, false, false)
                            SetEntityHeading(myPed, savedHead)
                        end
                        Citizen.Wait(1500)
                        busy = false
                    end)
                end
            else
                Citizen.Wait(50)
            end
        else
            Citizen.Wait(50)
        end
    end
end)
