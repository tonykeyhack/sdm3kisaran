-- ============================================
-- MAME D3D - ROBLOX ULTRA V5.9 FINAL (ALL FEATURES LOCKED)
-- [+] ROCKET SYSTEM: Deteksi Rocket Launcher asli + Auto-Lock + Slowmo (Q)
-- [+] Shadow Mode: Anti-Report, Anti-Ban, Traffic Mimicry
-- [+] FIXED: Wallhack, Spinbot, Speedhack, Crosshair
-- [+] FIXED: ESP Name (Jelas di atas player)
-- [+] Multi-Layer Auto Sell (GUI + Remotes)
-- [+] Navigasi Kiri & Kanan Fixed
-- [+] MENU FIXED - PASTI NONGOL
-- [+] Fly Hack (WASD + Space/Shift) - MEDIUM MENU
-- [+] Auto-Collect (Radius 50) - MEDIUM MENU
-- [+] Anti-AFK (10 detik) - MEDIUM MENU
-- [+] Rapid Fire (5x per click) - HARD MENU
-- [+] AimBullet Visual Detector - AIM MENU
-- [+] SEMUA FITUR AKTIF - TIDAK ADA YANG DIHAPUS
-- ============================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local mouse = player:GetMouse()
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")

-- ============================================
-- SHADOW MODE
-- ============================================
local function activateShadowMode()
    pcall(function()
        local oldReport = player.ReportPlayer
        if oldReport then
            player.ReportPlayer = function(target, reason)
                if target == player then return end
                return oldReport(target, "Spam")
            end
        end
    end)

    pcall(function()
        local BanService = game:GetService("BanService")
        if BanService then
            BanService.ReportAbuse = function() end
            BanService.BanPlayer = function() end
            BanService.KickPlayer = function() end
        end
    end)

    pcall(function()
        local fake = Instance.new("StringValue", player)
        fake.Name = "SynapseX_Loaded"
        fake.Value = "true"
    end)

    pcall(function()
        local RemoteEvent = ReplicatedStorage:FindFirstChild("FishingEvent") 
            or ReplicatedStorage:FindFirstChild("events") 
            or ReplicatedStorage:FindFirstChild("RemoteEvent")
        
        if RemoteEvent and RemoteEvent.FireServer then
            local oldFire = RemoteEvent.FireServer
            RemoteEvent.FireServer = function(self, ...)
                local args = {...}
                local success = pcall(function()
                    return oldFire(self, unpack(args))
                end)
                if args[1] == "ReelFish" or args[1] == "CatchFish" then
                    pcall(function()
                        oldFire(self, "ReelFish", math.random(1, 5000))
                    end)
                end
                return success
            end
        end
    end)

    pcall(function()
        local oldPrint = print
        print = function(...)
            local args = {...}
            for i, v in pairs(args) do
                if type(v) == "string" and (string.match(v, "Cheat") or string.match(v, "Exploit") or string.match(v, "Hack") or string.match(v, "Inject")) then
                    args[i] = "Error: Invalid argument"
                end
            end
            return oldPrint(unpack(args))
        end
    end)

    print("[ BlackHck⚡ ] Shadow Mode Active!")
end

pcall(activateShadowMode)

-- ============================================
-- CHEAT STATES (SEMUA FITUR TETAP ADA)
-- ============================================
local cheats = {
    -- VISUAL
    wallhack = false, noFog = false, noSmoke = false, noWaterEffect = false,
    crosshair = false, customFov = false,
    
    -- ESP
    fishESP = false, rareHighlight = false,
    
    -- ROCKET
    armRocket = false, rocketAutoLock = false, rocketSlow = false,
    
    -- FISHING
    autoFish = false, instantCatch = false, autoSell = false,
    autoFarm = false, perfectCatch = false,
    
    -- MOVEMENT
    speed = false, jump = false, infJump = false, noclip = false,
    fly = false, teleport = false,
    
    -- COMBAT
    aimbot = false, aimbullet = false, aimbulletVisual = false,
    spinbot = false, fastKill = false, rapidFire = false,
    
    -- UTILITY
    pickup = false, god = false, teamCheck = false,
    spectate = false, autoCollect = false, antiAFK = false,
}

local aimTargets = {"Head", "Body"}
local aimTargetIndex = 1
local aimbulletTarget = nil
local aimbulletObjects = {}

local ESP = {
    ShowHead = false, ShowSkeleton = false, ShowBox = false, ShowLine = false,
    ShowName = false, ShowHealth = false, ShowDistance = false, ShowWeapon = false,
    ShowDead = false, ShowTracer = false, ShowChams = false, MaxDistance = 2000,
    Colors = {
        Murderer = Color3.fromRGB(255, 0, 0), Sheriff = Color3.fromRGB(0, 100, 255),
        Innocent = Color3.fromRGB(0, 255, 0), Dead = Color3.fromRGB(128, 128, 128),
        Rare = Color3.fromRGB(255, 215, 0), Common = Color3.fromRGB(100, 200, 255)
    }
}

local NORMAL_SPEED = 16
local CHEAT_SPEED = 200
local NORMAL_JUMP = 50
local CHEAT_JUMP = 120

local Aimbot = { Enabled = false, AimKey = Enum.UserInputType.MouseButton2, FOVRadius = 150, Smoothness = 0.3, PrioritizeMurderer = true }
local AutoPickup = { Enabled = false, Range = 15 }
local GodMode = { Enabled = false }
local FastKill = { Enabled = false }
local roleCache = {}

local C = {
    bg = Color3.fromRGB(15, 15, 20), header = Color3.fromRGB(22, 22, 30), border = Color3.fromRGB(60, 60, 80),
    accent = Color3.fromRGB(138, 43, 226), highlight = Color3.fromRGB(138, 43, 226), sel_text = Color3.fromRGB(255, 255, 255),
    text = Color3.fromRGB(210, 210, 220), on = Color3.fromRGB(0, 255, 128), off = Color3.fromRGB(255, 70, 70),
    folder = Color3.fromRGB(0, 190, 255), info = Color3.fromRGB(130, 130, 150),
}

-- ============================================
-- DRAWING & DRAGGABLE LOGIC
-- ============================================
local drawings = {}
local menuVisible = true
local menuDirty = true
local fishESPObjects = {}

local menuX, menuY, menuW, itemH, headerH = 50, 50, 250, 18, 24
local dragging, dragStart, startPos = false, nil, nil

UserInputService.InputBegan:Connect(function(input)
    if not menuVisible then return end
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        local mPos = input.Position
        if mPos.X >= menuX and mPos.X <= menuX + menuW and mPos.Y >= menuY and mPos.Y <= menuY + headerH then
            dragging, dragStart, startPos = true, mPos, Vector2.new(menuX, menuY)
        end
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - dragStart
        menuX, menuY, menuDirty = startPos.X + delta.X, startPos.Y + delta.Y, true
    end
end)

local function clearDrawings() 
    for _, obj in pairs(drawings) do 
        pcall(function() obj:Remove() end) 
    end 
    drawings = {}
    for _, obj in pairs(aimbulletObjects) do
        pcall(function() obj:Remove() end)
    end
    aimbulletObjects = {}
end

local function clearFishESP() 
    for _, obj in pairs(fishESPObjects) do 
        pcall(function() obj:Remove() end) 
    end 
    fishESPObjects = {} 
end

local function draw(type, props)
    local obj = Drawing.new(type)
    for k, v in pairs(props) do 
        pcall(function() obj[k] = v end) 
    end
    table.insert(drawings, obj) 
    return obj
end

-- ============================================
-- MENU DATA (SEMUA FITUR TETAP ADA)
-- ============================================
local selection = 0
local items = {}

local function getStatusText() 
    return os.date("Date: %d-%m-%Y  Time: %H:%M:%S") 
end

local function buildMenu()
    items = {}
    local function add(label, type, ref) 
        table.insert(items, {label = label, type = type, ref = ref}) 
    end
    
    add("[ Visual Menu ]", "folder", {open = false, children = {
        {label = "Wallhack", state = function() return cheats.wallhack end, set = function(v) cheats.wallhack = v end},
        {label = "Custom FOV (120)", state = function() return cheats.customFov end, set = function(v) cheats.customFov = v end},
        {label = "No Fog", state = function() return cheats.noFog end, set = function(v) cheats.noFog = v end},
        {label = "No Smoke", state = function() return cheats.noSmoke end, set = function(v) cheats.noSmoke = v end},
        {label = "Crosshair", state = function() return cheats.crosshair end, set = function(v) cheats.crosshair = v end},
        {label = "No Water", state = function() return cheats.noWaterEffect end, set = function(v) cheats.noWaterEffect = v end},
    }})
    
    add("[ ESP Menu ]", "folder", {open = false, children = {
        {label = "ESP Chams", state = function() return ESP.ShowChams end, set = function(v) ESP.ShowChams = v end},
        {label = "ESP Tracers", state = function() return ESP.ShowTracer end, set = function(v) ESP.ShowTracer = v end},
        {label = "ESP Head", state = function() return ESP.ShowHead end, set = function(v) ESP.ShowHead = v end},
        {label = "ESP Skeleton", state = function() return ESP.ShowSkeleton end, set = function(v) ESP.ShowSkeleton = v end},
        {label = "ESP Box", state = function() return ESP.ShowBox end, set = function(v) ESP.ShowBox = v end},
        {label = "ESP Line", state = function() return ESP.ShowLine end, set = function(v) ESP.ShowLine = v end},
        {label = "ESP Name", state = function() return ESP.ShowName end, set = function(v) ESP.ShowName = v end},
        {label = "ESP Health", state = function() return ESP.ShowHealth end, set = function(v) ESP.ShowHealth = v end},
        {label = "ESP Weapon", state = function() return ESP.ShowWeapon end, set = function(v) ESP.ShowWeapon = v end},
        {label = "Fish ESP", state = function() return cheats.fishESP end, set = function(v) cheats.fishESP = v end},
        {label = "Rare Fish ESP", state = function() return cheats.rareHighlight end, set = function(v) cheats.rareHighlight = v end},
    }})
    
    add("[ Rocket Menu ]", "folder", {open = false, children = {
        {label = "Arm Rocket (LMB)", state = function() return cheats.armRocket end, set = function(v) cheats.armRocket = v end},
        {label = "Auto-Lock Head", state = function() return cheats.rocketAutoLock end, set = function(v) cheats.rocketAutoLock = v end},
        {label = "Rocket Slowmo (Q)", state = function() return cheats.rocketSlow end, set = function(v) cheats.rocketSlow = v end},
    }})
    
    add("[ Safe Fishing Menu ]", "folder", {open = false, children = {
        {label = "Safe Auto Fish", state = function() return cheats.autoFish end, set = function(v) cheats.autoFish = v end},
        {label = "Safe Auto Catch", state = function() return cheats.instantCatch end, set = function(v) cheats.instantCatch = v end},
        {label = "Safe Perfect Catch", state = function() return cheats.perfectCatch end, set = function(v) cheats.perfectCatch = v end},
        {label = "Safe Auto Sell", state = function() return cheats.autoSell end, set = function(v) cheats.autoSell = v end},
        {label = "Safe Auto Farm", state = function() return cheats.autoFarm end, set = function(v) cheats.autoFarm = v end},
    }})
    
    add("[ Aim Menu ]", "folder", {open = false, children = {
        {label = "Team Check", state = function() return cheats.teamCheck end, set = function(v) cheats.teamCheck = v end},
        {label = "Aimbot", state = function() return Aimbot.Enabled end, set = function(v) Aimbot.Enabled = v end},
        {label = "AimBullet", state = function() return cheats.aimbullet end, set = function(v) cheats.aimbullet = v end},
        {label = "AimBullet Visual", state = function() return cheats.aimbulletVisual end, set = function(v) cheats.aimbulletVisual = v end},
        {label = "Aim Target", state = function() return aimTargetIndex end, set = function(v) aimTargetIndex = v end, options = aimTargets},
    }})
    
    add("[ Medium Menu ]", "folder", {open = false, children = {
        {label = "Auto Pickup", state = function() return AutoPickup.Enabled end, set = function(v) AutoPickup.Enabled = v end},
        {label = "Speed Hack", state = function() return cheats.speed end, set = function(v) cheats.speed = v end},
        {label = "Super Jump", state = function() return cheats.jump end, set = function(v) cheats.jump = v end},
        {label = "Infinite Jump", state = function() return cheats.infJump end, set = function(v) cheats.infJump = v end},
        {label = "Fly Hack", state = function() return cheats.fly end, set = function(v) cheats.fly = v end},
        {label = "Auto-Collect", state = function() return cheats.autoCollect end, set = function(v) cheats.autoCollect = v end},
        {label = "Anti-AFK", state = function() return cheats.antiAFK end, set = function(v) cheats.antiAFK = v end},
    }})
    
    add("[ Hard Menu ]", "folder", {open = false, children = {
        {label = "God Mode", state = function() return GodMode.Enabled end, set = function(v) GodMode.Enabled = v end},
        {label = "Spinbot", state = function() return cheats.spinbot end, set = function(v) cheats.spinbot = v end},
        {label = "Spectate Hack", state = function() return cheats.spectate end, set = function(v) cheats.spectate = v end},
        {label = "Fast Kill", state = function() return FastKill.Enabled end, set = function(v) FastKill.Enabled = v end},
        {label = "Noclip", state = function() return cheats.noclip end, set = function(v) cheats.noclip = v end},
        {label = "Teleport", state = function() return cheats.teleport end, set = function(v) cheats.teleport = v end},
        {label = "Rapid Fire", state = function() return cheats.rapidFire end, set = function(v) cheats.rapidFire = v end},
    }})
    
    add("────────────────────────", "info", nil)
    add("🛡️ SHADOW MODE ACTIVE", "info", nil)
    add("DRAG: Klik Tahan Judul Menu", "info", nil)
    add("HIDE: RightShift / Insert", "info", nil)
    add("Spectate: [ / ]", "info", nil)
    add("Teleport: CTRL+T / Klik Kiri", "info", nil)
    add("Rocket Slowmo: Q", "info", nil)
    add("Fly: WASD | Space Naik | Shift Turun", "info", nil)
    add("Auto-Collect: Radius 50", "info", nil)
    add("Rapid Fire: 5x Shoot per Click", "info", nil)
    add("AimBullet: Auto-lock + Visual", "info", nil)
    add("Target: " .. aimTargets[aimTargetIndex + 1], "info", nil)
    add(getStatusText(), "info", nil)
    add("ROBLOX ULTRA - V5.9 FINAL", "info", nil)
end

-- ============================================
-- GET FLAT ITEMS
-- ============================================
local flatCache = {}
local flatCacheValid = false

local function getFlatItems()
    if flatCacheValid then return flatCache end
    flatCache = {}
    for _, item in pairs(items) do
        if item.type == "folder" then
            table.insert(flatCache, {label = item.label, type = "folder", ref = item.ref, depth = 0})
            if item.ref.open then
                for _, child in pairs(item.ref.children) do
                    local entry = { label = child.label, type = "toggle", state = child.state, set = child.set, depth = 1, ref = child }
                    if child.options then 
                        entry.options = child.options 
                        entry.isOption = true 
                        entry.value = child.state() 
                    end
                    table.insert(flatCache, entry)
                end
            end
        else 
            table.insert(flatCache, {label = item.label, type = item.type, ref = item.ref, depth = 0}) 
        end
    end
    flatCacheValid = true 
    return flatCache
end

local function invalidateCache() 
    flatCacheValid = false 
    menuDirty = true 
end

-- ============================================
-- RENDER MENU
-- ============================================
local function render()
    if not menuVisible then 
        clearDrawings() 
        return 
    end
    if not menuDirty then 
        return 
    end
    menuDirty = false 
    clearDrawings()
    
    local flat = getFlatItems()
    local totalH = headerH + (#flat * itemH) + 8
    
    draw("Square", {Position = Vector2.new(menuX + 3, menuY + 3), Size = Vector2.new(menuW, totalH), Color = Color3.fromRGB(0,0,0), Filled = true, Thickness = 0, Visible = true, Transparency = 0.5})
    
    draw("Square", {Position = Vector2.new(menuX, menuY), Size = Vector2.new(menuW, headerH), Color = C.header, Filled = true, Thickness = 0, Visible = true, Transparency = 1})
    draw("Square", {Position = Vector2.new(menuX, menuY), Size = Vector2.new(menuW, 2), Color = C.accent, Filled = true, Thickness = 0, Visible = true, Transparency = 1})
    draw("Square", {Position = Vector2.new(menuX, menuY), Size = Vector2.new(menuW, headerH), Color = C.border, Filled = false, Thickness = 1, Visible = true, Transparency = 1})
    draw("Text", {Position = Vector2.new(menuX + menuW/2, menuY + 4), Text = "ROBLOX ULTRA", Color = Color3.fromRGB(255, 255, 255), Size = 13, Center = true, Outline = false, Visible = true, Transparency = 1})
    
    draw("Square", {Position = Vector2.new(menuX, menuY + headerH), Size = Vector2.new(menuW, totalH - headerH), Color = C.bg, Filled = true, Thickness = 0, Visible = true, Transparency = 1})
    draw("Square", {Position = Vector2.new(menuX, menuY + headerH), Size = Vector2.new(menuW, totalH - headerH), Color = C.border, Filled = false, Thickness = 1, Visible = true, Transparency = 1})
    
    local y = menuY + headerH + 4
    for i, item in pairs(flat) do
        local selected = (i - 1 == selection)
        local x = menuX + 8 + (item.depth or 0) * 12
        
        if selected then
            draw("Square", {Position = Vector2.new(menuX + 1, y), Size = Vector2.new(menuW - 2, itemH), Color = C.highlight, Filled = true, Thickness = 0, Visible = true, Transparency = 0.2})
            draw("Square", {Position = Vector2.new(menuX + 1, y), Size = Vector2.new(2, itemH), Color = C.highlight, Filled = true, Thickness = 0, Visible = true, Transparency = 1})
        end
        
        if item.type == "folder" then
            local arrow = item.ref.open and "[-]" or "[+]"
            draw("Text", {Position = Vector2.new(x, y + 2), Text = arrow .. " " .. item.label, Color = selected and C.sel_text or C.folder, Size = 12, Center = false, Outline = false, Visible = true, Transparency = 1})
        elseif item.type == "toggle" then
            local state = item.state()
            if item.isOption and item.options then
                local displayText = item.options[state + 1] or "Off"
                draw("Text", {Position = Vector2.new(x, y + 2), Text = item.label, Color = selected and C.sel_text or C.text, Size = 12, Center = false, Outline = false, Visible = true, Transparency = 1})
                local valX = menuX + menuW - 50
                if selected then
                    draw("Text", {Position = Vector2.new(valX - 10, y + 2), Text = "<", Color = C.accent, Size = 12, Center = false, Outline = false, Visible = true, Transparency = 1})
                    draw("Text", {Position = Vector2.new(menuX + menuW - 10, y + 2), Text = ">", Color = C.accent, Size = 12, Center = false, Outline = false, Visible = true, Transparency = 1})
                end
                draw("Text", {Position = Vector2.new(valX, y + 2), Text = displayText, Color = selected and C.sel_text or C.text, Size = 12, Center = false, Outline = false, Visible = true, Transparency = 1})
            else
                draw("Text", {Position = Vector2.new(x, y + 2), Text = item.label, Color = selected and C.sel_text or C.text, Size = 12, Center = false, Outline = false, Visible = true, Transparency = 1})
                local stateText = state and "[ ON ]" or "[ OFF ]"
                local stateColor = state and C.on or C.off
                draw("Text", {Position = Vector2.new(menuX + menuW - 45, y + 2), Text = stateText, Color = stateColor, Size = 12, Center = false, Outline = false, Visible = true, Transparency = 1})
            end
        elseif item.type == "info" then 
            draw("Text", {Position = Vector2.new(x, y + 2), Text = item.label, Color = C.info, Size = 11, Center = false, Outline = false, Visible = true, Transparency = 1}) 
        end
        y = y + itemH
    end
end

-- ============================================
-- NAVIGASI UI
-- ============================================
local navCooldown = 0

local function getVisibleCount()
    local count = 0
    for _, item in pairs(items) do 
        if item.type == "folder" then 
            count = count + 1 
            if item.ref.open then 
                count = count + #item.ref.children 
            end 
        else 
            count = count + 1 
        end 
    end
    return count
end

local function navigate(direction)
    local now = tick() 
    if now - navCooldown < 0.1 then return end 
    navCooldown = now
    local total = getVisibleCount() 
    if total == 0 then return end
    if direction == "up" then 
        selection = selection - 1 
        if selection < 0 then selection = total - 1 end
    elseif direction == "down" then 
        selection = selection + 1 
        if selection >= total then selection = 0 end 
    end
    menuDirty = true
end

local function action(direction)
    local now = tick() 
    if now - navCooldown < 0.1 then return end 
    navCooldown = now
    local flat = getFlatItems() 
    if #flat == 0 then return end
    local item = flat[selection + 1] 
    if not item then return end
    
    if item.type == "folder" then 
        if direction == "right" then 
            item.ref.open = true 
        elseif direction == "left" then 
            item.ref.open = false
        else 
            item.ref.open = not item.ref.open 
        end
        invalidateCache()
    elseif item.type == "toggle" then
        if item.isOption and item.options then
            local currentVal = item.state() 
            local maxVal = #item.options - 1
            if direction == "right" then 
                currentVal = currentVal + 1 
                if currentVal > maxVal then currentVal = 0 end
            elseif direction == "left" then 
                currentVal = currentVal - 1 
                if currentVal < 0 then currentVal = maxVal end
            else 
                currentVal = currentVal + 1 
                if currentVal > maxVal then currentVal = 0 end 
            end
            item.set(currentVal)
            for _, infoItem in pairs(items) do 
                if infoItem.type == "info" and type(infoItem.label) == "string" and string.match(infoItem.label, "Target:") then 
                    infoItem.label = "Target: " .. aimTargets[aimTargetIndex + 1] 
                end 
            end
        else 
            local newState = item.state()
            if direction == "right" then 
                newState = true
            elseif direction == "left" then 
                newState = false
            else 
                newState = not newState 
            end
            item.set(newState) 
        end
        menuDirty = true
    end
end

-- ============================================
-- INPUT CATCHER (MENU NAV)
-- ============================================
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    local isTyping = UserInputService:GetFocusedTextBox() ~= nil

    if input.KeyCode == Enum.KeyCode.RightShift or input.KeyCode == Enum.KeyCode.Insert then
        if isTyping then return end
        menuVisible = not menuVisible
        menuDirty = true
        return
    end
    
    if not menuVisible or isTyping then return end
    
    if input.KeyCode == Enum.KeyCode.Up then 
        navigate("up")
    elseif input.KeyCode == Enum.KeyCode.Down then 
        navigate("down")
    elseif input.KeyCode == Enum.KeyCode.Right then 
        action("right")
    elseif input.KeyCode == Enum.KeyCode.Left then 
        action("left")
    elseif input.KeyCode == Enum.KeyCode.Return then 
        action("enter")
    end
end)

-- ============================================
-- GLOBAL UTILS (ROLE & TEAM CHECK)
-- ============================================
local function detectRoleByWeapons(targetPlayer)
    local char = targetPlayer.Character if not char then return nil end
    if char:FindFirstChild("Knife") or char:FindFirstChild("KnifeHandle") then return "Murderer" end
    if char:FindFirstChild("Pistol") or char:FindFirstChild("Revolver") then return "Sheriff" end
    local hum = char:FindFirstChild("Humanoid") if hum and hum.Health > 0 then return "Innocent" end 
    return nil
end

local function watchPlayerWeapons(targetPlayer)
    local function onCharacterAdded(char)
        roleCache[targetPlayer] = nil 
        local role = detectRoleByWeapons(targetPlayer) 
        if role then roleCache[targetPlayer] = role end
        char.ChildAdded:Connect(function(child)
            if roleCache[targetPlayer] then return end
            if child.Name == "Knife" or child.Name == "KnifeHandle" then 
                roleCache[targetPlayer] = "Murderer" 
            elseif child.Name == "Pistol" or child.Name == "Revolver" then 
                roleCache[targetPlayer] = "Sheriff" 
            end
        end)
    end
    targetPlayer.CharacterAdded:Connect(onCharacterAdded)
    if targetPlayer.Character then onCharacterAdded(targetPlayer.Character) end
end

for _, p in pairs(Players:GetPlayers()) do 
    watchPlayerWeapons(p) 
end 
Players.PlayerAdded:Connect(watchPlayerWeapons)

local function getStatus(targetPlayer)
    local char = targetPlayer.Character if not char then return "Dead" end
    local hum = char:FindFirstChild("Humanoid") 
    if hum and hum.Health <= 0 then return "Dead" end
    return roleCache[targetPlayer] or "Unknown"
end

local function getRoleColor(role) 
    return ESP.Colors[role] or Color3.new(1,1,1) 
end

local function isEnemy(p)
    if not cheats.teamCheck then return true end
    if player.Team and p.Team and player.Team == p.Team then return false end
    local myRole, targetRole = getStatus(player), getStatus(p)
    if myRole == "Innocent" and targetRole == "Innocent" then return false end
    if myRole == "Sheriff" and targetRole == "Innocent" then return false end
    if myRole == "Innocent" and targetRole == "Sheriff" then return false end
    return true
end

-- ============================================
-- ROCKET SYSTEM
-- ============================================
local canShootRocket = true
local rocketLauncher = nil
local slowmoActive = false
local slowmoConnections = {}

local function findRocketLauncher()
    local searchAreas = {character, player.Backpack}
    for _, area in pairs(searchAreas) do
        for _, tool in pairs(area:GetChildren()) do
            if tool:IsA("Tool") then
                local name = tool.Name:lower()
                if name:find("rocket") or name:find("launcher") or name:find("rpg") or name:find("bazooka") or name:find("explosive") then
                    return tool
                end
            end
        end
    end
    return nil
end

local function shootRocket()
    if not cheats.armRocket or not canShootRocket then return end
    canShootRocket = false
    
    if not rocketLauncher or not rocketLauncher.Parent then
        rocketLauncher = findRocketLauncher()
        if not rocketLauncher then
            canShootRocket = true
            print("[ BlackHck⚡ ] Rocket Launcher not found!")
            return
        end
    end
    
    if rocketLauncher.Parent ~= character then
        pcall(function()
            rocketLauncher.Parent = character
        end)
        task.wait(0.1)
    end
    
    if cheats.rocketAutoLock then
        local closest, closestDist = nil, math.huge
        local hrp = character:FindFirstChild("HumanoidRootPart")
        if hrp then
            for _, p in pairs(Players:GetPlayers()) do
                if p ~= player and p.Character then
                    local head = p.Character:FindFirstChild("Head")
                    if head then
                        local dist = (hrp.Position - head.Position).Magnitude
                        if dist < closestDist and dist < 200 then
                            closestDist = dist
                            closest = head
                        end
                    end
                end
            end
        end
        
        if closest then
            local screenPos, onScreen = Camera:WorldToViewportPoint(closest.Position)
            if onScreen then
                pcall(function()
                    mouse.Move(Vector2.new(screenPos.X, screenPos.Y))
                end)
            end
        end
    end
    
    local success = false
    pcall(function()
        if rocketLauncher:IsA("Tool") then
            rocketLauncher:Activate()
            success = true
        end
    end)
    
    if not success then
        pcall(function()
            for _, v in pairs(rocketLauncher:GetDescendants()) do
                if v:IsA("RemoteEvent") or v:IsA("RemoteFunction") then
                    v:FireServer()
                    success = true
                end
            end
        end)
    end
    
    if not success then
        pcall(function()
            for _, v in pairs(rocketLauncher:GetDescendants()) do
                if v:IsA("ClickDetector") then
                    v:Click()
                    success = true
                end
            end
        end)
    end
    
    task.wait(1.2)
    canShootRocket = true
end

local function toggleSlowmo()
    if not cheats.rocketSlow then return end
    slowmoActive = not slowmoActive
    
    if slowmoActive then
        for _, v in pairs(workspace:GetDescendants()) do
            if v:IsA("Part") and (v.Name:lower():find("rocket") or v.Name:lower():find("missile") or v.Name:lower():find("projectile")) then
                pcall(function()
                    v.AssemblyLinearVelocity = v.AssemblyLinearVelocity * 0.2
                end)
            end
        end
        
        local conn = RunService.Heartbeat:Connect(function()
            if slowmoActive then
                for _, v in pairs(workspace:GetDescendants()) do
                    if v:IsA("Part") and (v.Name:lower():find("rocket") or v.Name:lower():find("missile") or v.Name:lower():find("projectile")) then
                        pcall(function()
                            v.AssemblyLinearVelocity = v.AssemblyLinearVelocity * 0.95
                        end)
                    end
                end
            end
        end)
        table.insert(slowmoConnections, conn)
        print("[ BlackHck⚡ ] Rocket Slowmo ACTIVE!")
    else
        for _, conn in pairs(slowmoConnections) do
            pcall(function() conn:Disconnect() end)
        end
        slowmoConnections = {}
        print("[ BlackHck⚡ ] Rocket Slowmo OFF")
    end
end

-- ============================================
-- SAFE FISHING MENU
-- ============================================
local fishingCooldown = 0
local autoSellCooldown = 0
local farmTimer = 0

local function autoFishSafe()
    if not cheats.autoFish then return end
    local tool = character:FindFirstChildOfClass("Tool")
    if not tool then return end
    
    local now = tick()
    if now - fishingCooldown < 2.5 then return end
    fishingCooldown = now
    
    pcall(function() tool:Activate() end)
end

local function applyFishingModsSafe()
    if not (cheats.instantCatch or cheats.perfectCatch) then return end
    
    local searchAreas = {player:WaitForChild("PlayerGui"), character}
    for _, area in pairs(searchAreas) do
        for _, v in pairs(area:GetDescendants()) do
            if cheats.instantCatch then
                if v:IsA("NumberValue") and (v.Name:lower():find("time") or v.Name:lower():find("wait") or v.Name:lower():find("duration")) then
                    if v.Value > 0.5 then v.Value = 0.1 end 
                elseif v:IsA("BoolValue") and (v.Name:lower():find("biting") or v.Name:lower():find("catchable") or v.Name:lower():find("fishon")) then
                    v.Value = true
                end
            end
            
            if cheats.perfectCatch then
                if (v:IsA("NumberValue") or v:IsA("IntValue")) and (v.Name:lower():find("perfect") or v.Name:lower():find("bar") or v.Name:lower():find("progress") or v.Name:lower():find("score")) then
                    local targetVal = v:IsA("NumberValue") and 99.9 or 99
                    if v.Value < targetVal then v.Value = targetVal end
                end
            end
        end
    end
end

local function autoSellSafe()
    if not cheats.autoSell then return end
    local now = tick()
    if now - autoSellCooldown < 3.0 then return end
    autoSellCooldown = now
    
    pcall(function()
        if ReplicatedStorage:FindFirstChild("events") and ReplicatedStorage.events:FindFirstChild("selleverything") then
            ReplicatedStorage.events.selleverything:InvokeServer()
        end
    end)
    
    pcall(function()
        for _, v in pairs(workspace:GetDescendants()) do
            if (v.Name:lower() == "sellall" or v.Name:lower() == "selleverything") then
                if v:IsA("RemoteFunction") then v:InvokeServer() 
                elseif v:IsA("RemoteEvent") then v:FireServer() end
            end
        end
    end)

    pcall(function()
        for _, v in pairs(player.PlayerGui:GetDescendants()) do
            if v:IsA("TextButton") or v:IsA("ImageButton") then
                local btnText = ""
                if v:IsA("TextButton") then btnText = v.Text:lower() end
                local txtLabel = v:FindFirstChildOfClass("TextLabel")
                if txtLabel then btnText = txtLabel.Text:lower() end
                
                if btnText:find("sell all") or btnText:find("jual semua") or v.Name:lower():find("sellall") then
                    if getconnections then
                        for _, conn in pairs(getconnections(v.MouseButton1Click)) do conn:Fire() end
                        for _, conn in pairs(getconnections(v.Activated)) do conn:Fire() end
                    end
                end
            end
        end
    end)

    local root = character and character:FindFirstChild("HumanoidRootPart")
    if root then
        for _, v in pairs(workspace:GetDescendants()) do
            if v:IsA("ProximityPrompt") then
                local action = v.ActionText:lower()
                local objName = v.ObjectText:lower()
                if action:find("sell") or objName:find("sell") or action:find("merchant") then
                    local dist = (root.Position - v.Parent.Position).Magnitude
                    if dist <= 30 then
                        fireproximityprompt(v)
                    end
                end
            end
        end
    end
end

local function autoFarmLoop()
    if not cheats.autoFarm then return end
    local now = tick()
    if now - farmTimer < 2.5 then return end
    farmTimer = now
    autoFishSafe()
    autoSellSafe()
end

local function drawFishESP()
    clearFishESP()
    if not cheats.fishESP then return end
    for _, v in pairs(workspace:GetDescendants()) do
        if v:IsA("Model") and (v.Name:lower():find("fish") or v.Name:lower():find("shark") or v.Name:lower():find("whale")) then
            local root = v:FindFirstChild("HumanoidRootPart") or v:FindFirstChild("Head") or v:FindFirstChildOfClass("BasePart")
            if root then
                local screenPos, onScreen = Camera:WorldToViewportPoint(root.Position)
                if onScreen and screenPos.Z > 0 then
                    local pos = Vector2.new(screenPos.X, screenPos.Y)
                    local isRare = v.Name:lower():find("rare") or v.Name:lower():find("legendary") or v.Name:lower():find("epic") or v.Name:lower():find("shiny") or v.Name:lower():find("mutant")
                    local color = isRare and ESP.Colors.Rare or ESP.Colors.Common
                    
                    if cheats.rareHighlight and isRare then
                        local sq = Drawing.new("Square")
                        sq.Position = Vector2.new(pos.X - 20, pos.Y - 15)
                        sq.Size = Vector2.new(40, 30)
                        sq.Color = color
                        sq.Thickness = 2
                        sq.Filled = false
                        sq.Visible = true
                        table.insert(fishESPObjects, sq)
                        
                        local txt = Drawing.new("Text")
                        txt.Position = Vector2.new(pos.X, pos.Y - 30)
                        txt.Text = "⭐ RARE!"
                        txt.Color = color
                        txt.Size = 14
                        txt.Center = true
                        txt.Outline = true
                        txt.Visible = true
                        table.insert(fishESPObjects, txt)
                    else
                        local cir = Drawing.new("Circle")
                        cir.Position = pos
                        cir.Radius = 10
                        cir.Color = color
                        cir.Thickness = 2
                        cir.Filled = false
                        cir.Visible = true
                        table.insert(fishESPObjects, cir)
                    end
                    
                    local name = Drawing.new("Text")
                    name.Position = Vector2.new(pos.X, pos.Y - 20)
                    name.Text = v.Name
                    name.Color = Color3.fromRGB(255, 255, 255)
                    name.Size = 10
                    name.Center = true
                    name.Outline = true
                    name.Visible = true
                    table.insert(fishESPObjects, name)
                end
            end
        end
    end
end

-- ============================================
-- VISUAL HACKS
-- ============================================
local function applyNoFog() 
    if cheats.noFog then 
        Lighting.FogEnd = 999999 
        Lighting.FogStart = 0 
        Lighting.Atmosphere = nil 
    else 
        Lighting.FogEnd = 100000 
        Lighting.FogStart = 0 
    end 
end

local smokeParts = {}
local function applyNoSmoke()
    if cheats.noSmoke then
        for _, v in pairs(workspace:GetDescendants()) do
            if v:IsA("ParticleEmitter") or v:IsA("Smoke") or v:IsA("Fire") or v:IsA("Sparkles") then
                if not table.find(smokeParts, v) then table.insert(smokeParts, v) end 
                v.Enabled = false 
                v.Visible = false
            end
        end
    else
        for _, v in pairs(smokeParts) do 
            pcall(function() v.Enabled = true v.Visible = true end) 
        end 
        smokeParts = {}
    end
end

local waterParts = {}
local function applyNoWaterEffect()
    if cheats.noWaterEffect then
        for _, v in pairs(workspace:GetDescendants()) do
            if v:IsA("Water") or (v:IsA("BasePart") and v.Material == Enum.Material.Water) then
                if not table.find(waterParts, v) then table.insert(waterParts, v) end 
                v.Transparency = 1 
                v.Material = Enum.Material.SmoothPlastic
            end
        end
    else
        for _, v in pairs(waterParts) do 
            pcall(function() v.Transparency = 0 v.Material = Enum.Material.Water end) 
        end 
        waterParts = {}
    end
end

-- ============================================
-- WALLHACK
-- ============================================
local originalTransparencies = {}
local wallhackActive = false

local function applyWallhack()
    if cheats.wallhack then
        if not wallhackActive then
            wallhackActive = true
            for _, v in pairs(workspace:GetDescendants()) do
                if v:IsA("BasePart") and not v.Parent:IsA("Tool") and not v.Parent:FindFirstChild("Humanoid") then
                    if originalTransparencies[v] == nil then
                        originalTransparencies[v] = v.Transparency
                    end
                    v.Transparency = 0.4
                    v.Material = Enum.Material.SmoothPlastic
                end
            end
        end
    else
        if wallhackActive then
            wallhackActive = false
            for part, orig in pairs(originalTransparencies) do
                pcall(function()
                    part.Transparency = orig
                    part.Material = Enum.Material.Plastic
                end)
            end
            originalTransparencies = {}
        end
    end
end

-- ============================================
-- CROSSHAIR
-- ============================================
local crosshairObjects = {}
local function drawCrosshair()
    for _, obj in pairs(crosshairObjects) do
        pcall(function() obj:Remove() end)
    end
    crosshairObjects = {}
    
    if not cheats.crosshair then return end
    
    local vpSize = Camera.ViewportSize
    local cx, cy = vpSize.X / 2, vpSize.Y / 2
    local size, gap, color, thickness = 15, 5, Color3.fromRGB(0, 255, 0), 2
    
    local parts = {
        {from = Vector2.new(cx, cy - gap), to = Vector2.new(cx, cy - gap - size)},
        {from = Vector2.new(cx, cy + gap), to = Vector2.new(cx, cy + gap + size)},
        {from = Vector2.new(cx - gap, cy), to = Vector2.new(cx - gap - size, cy)},
        {from = Vector2.new(cx + gap, cy), to = Vector2.new(cx + gap + size, cy)},
    }
    
    for _, p in pairs(parts) do
        local line = Drawing.new("Line")
        line.From = p.from
        line.To = p.to
        line.Color = color
        line.Thickness = thickness
        line.Visible = true
        line.Transparency = 1
        table.insert(crosshairObjects, line)
    end
    
    local dot = Drawing.new("Square")
    dot.Size = Vector2.new(3, 3)
    dot.Position = Vector2.new(cx - 1.5, cy - 1.5)
    dot.Color = color
    dot.Filled = true
    dot.Thickness = 0
    dot.Visible = true
    dot.Transparency = 1
    table.insert(crosshairObjects, dot)
end

local function applyCustomFOV() 
    if cheats.customFov then 
        Camera.FieldOfView = 120 
    else 
        Camera.FieldOfView = 70 
    end 
end

-- ============================================
-- SPECTATE HACK
-- ============================================
local spectateIndex = 1
local function getSpectateTargets()
    local t = {} 
    for _, p in ipairs(Players:GetPlayers()) do 
        if p ~= player and p.Character and p.Character:FindFirstChild("Humanoid") then 
            table.insert(t, p) 
        end 
    end 
    return t
end

UserInputService.InputBegan:Connect(function(input, gp)
    if gp or not cheats.spectate then return end
    local targets = getSpectateTargets() 
    if #targets == 0 then return end
    if input.KeyCode == Enum.KeyCode.RightBracket then 
        spectateIndex = spectateIndex + 1 
        if spectateIndex > #targets then spectateIndex = 1 end 
        Camera.CameraSubject = targets[spectateIndex].Character.Humanoid
    elseif input.KeyCode == Enum.KeyCode.LeftBracket then 
        spectateIndex = spectateIndex - 1 
        if spectateIndex < 1 then spectateIndex = #targets end 
        Camera.CameraSubject = targets[spectateIndex].Character.Humanoid 
    end
end)

RunService.RenderStepped:Connect(function()
    if not cheats.spectate and Camera.CameraSubject ~= humanoid and humanoid then 
        Camera.CameraSubject = humanoid 
    end
end)

-- ============================================
-- ESP SYSTEM
-- ============================================
local playerESPs = {}

local function removeESP(targetPlayer)
    local esp = playerESPs[targetPlayer]
    if esp then
        if esp.Connection then esp.Connection:Disconnect() end
        if esp.Highlight then esp.Highlight:Destroy() end
        for _, obj in pairs(esp) do 
            if type(obj) == "table" and obj.Remove then obj:Remove() end 
        end
        playerESPs[targetPlayer] = nil
    end
end

local function getPlayerWeapon(targetPlayer)
    local char = targetPlayer.Character if not char then return nil end
    local weapon = char:FindFirstChild("Knife") or char:FindFirstChild("KnifeHandle") or char:FindFirstChild("Pistol") or char:FindFirstChild("Revolver") or char:FindFirstChild("Gun") or char:FindFirstChild("Weapon")
    if weapon then return weapon.Name end
    local tool = targetPlayer:FindFirstChild("Backpack")
    if tool then 
        for _, child in pairs(tool:GetChildren()) do 
            if child:IsA("Tool") then return child.Name end 
        end 
    end 
    return nil
end

local function getJointPos(char, jointName) 
    local joint = char:FindFirstChild(jointName) 
    if joint and joint:IsA("BasePart") then return joint.Position end 
    return nil 
end

local function getSkeletonPoints(char)
    local points = {} 
    local isR15 = char:FindFirstChild("UpperTorso") ~= nil
    if isR15 then
        points.Head = getJointPos(char, "Head") 
        points.UpperTorso = getJointPos(char, "UpperTorso") 
        points.LowerTorso = getJointPos(char, "LowerTorso") 
        points.Root = getJointPos(char, "HumanoidRootPart") 
        points.LeftUpperArm = getJointPos(char, "LeftUpperArm") 
        points.LeftLowerArm = getJointPos(char, "LeftLowerArm") 
        points.LeftHand = getJointPos(char, "LeftHand") 
        points.RightUpperArm = getJointPos(char, "RightUpperArm") 
        points.RightLowerArm = getJointPos(char, "RightLowerArm") 
        points.RightHand = getJointPos(char, "RightHand") 
        points.LeftUpperLeg = getJointPos(char, "LeftUpperLeg") 
        points.LeftLowerLeg = getJointPos(char, "LeftLowerLeg") 
        points.LeftFoot = getJointPos(char, "LeftFoot") 
        points.RightUpperLeg = getJointPos(char, "RightUpperLeg") 
        points.RightLowerLeg = getJointPos(char, "RightLowerLeg") 
        points.RightFoot = getJointPos(char, "RightFoot")
    else
        points.Head = getJointPos(char, "Head") 
        points.UpperTorso = getJointPos(char, "Torso") 
        points.LowerTorso = getJointPos(char, "Torso") 
        points.Root = getJointPos(char, "HumanoidRootPart") 
        points.LeftUpperArm = getJointPos(char, "LeftArm") 
        points.RightUpperArm = getJointPos(char, "RightArm") 
        points.LeftUpperLeg = getJointPos(char, "LeftLeg") 
        points.RightUpperLeg = getJointPos(char, "RightLeg")
    end 
    return points, isR15
end

local function createESP(targetPlayer)
    local esp = {}
    esp.Head = Drawing.new("Circle") 
    esp.Head.Visible = false 
    esp.Head.Radius = 8 
    esp.Head.Thickness = 2 
    esp.Head.Filled = true 
    esp.Head.Transparency = 0.6
    esp.Box = Drawing.new("Square") 
    esp.Box.Visible = false 
    esp.Box.Thickness = 2 
    esp.Box.Filled = false 
    esp.Box.Transparency = 1
    esp.Line = Drawing.new("Line") 
    esp.Line.Visible = false 
    esp.Line.Thickness = 1
    esp.Tracer = Drawing.new("Line") 
    esp.Tracer.Visible = false 
    esp.Tracer.Thickness = 1.5 
    esp.Tracer.Transparency = 0.8
    
    esp.Name = Drawing.new("Text") 
    esp.Name.Visible = false 
    esp.Name.Size = 18
    esp.Name.Center = true 
    esp.Name.Outline = true
    esp.Name.OutlineColor = Color3.fromRGB(0, 0, 0)
    esp.Name.Transparency = 1
    esp.Name.Font = 3
    
    esp.HealthBg = Drawing.new("Square") 
    esp.HealthBg.Visible = false 
    esp.HealthBg.Thickness = 0 
    esp.HealthBg.Filled = true 
    esp.HealthBg.Transparency = 0.5
    esp.HealthBar = Drawing.new("Square") 
    esp.HealthBar.Visible = false 
    esp.HealthBar.Thickness = 0 
    esp.HealthBar.Filled = true 
    esp.HealthBar.Transparency = 1
    esp.Dist = Drawing.new("Text") 
    esp.Dist.Visible = false 
    esp.Dist.Size = 12 
    esp.Dist.Center = true 
    esp.Dist.Outline = true
    esp.Weapon = Drawing.new("Text") 
    esp.Weapon.Visible = false 
    esp.Weapon.Size = 12 
    esp.Weapon.Center = true 
    esp.Weapon.Outline = true
    esp.Skeleton = {} 
    for i = 1, 14 do 
        esp.Skeleton[i] = Drawing.new("Line") 
        esp.Skeleton[i].Visible = false 
        esp.Skeleton[i].Thickness = 2 
    end
    esp.Highlight = Instance.new("Highlight") 
    esp.Highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop 
    esp.Highlight.FillTransparency = 0.5 
    esp.Highlight.OutlineTransparency = 0.2 
    esp.Highlight.Enabled = false

    local function hideAll()
        esp.Head.Visible = false
        esp.Box.Visible = false
        esp.Line.Visible = false
        esp.Tracer.Visible = false
        esp.Name.Visible = false
        esp.HealthBg.Visible = false
        esp.HealthBar.Visible = false
        esp.Dist.Visible = false
        esp.Weapon.Visible = false
        esp.Highlight.Enabled = false
        for _, line in pairs(esp.Skeleton) do line.Visible = false end
    end

    local function update()
        local char = targetPlayer.Character
        if not char or not char.Parent then hideAll() return end
        local root, head, hum = char:FindFirstChild("HumanoidRootPart"), char:FindFirstChild("Head"), char:FindFirstChild("Humanoid")
        if not (root and head and hum) then hideAll() return end
        local status = getStatus(targetPlayer)
        if (hum.Health <= 0 or status == "Dead") and not ESP.ShowDead then hideAll() return end
        if not isEnemy(targetPlayer) then hideAll() return end
        local dist = (Camera.CFrame.Position - root.Position).Magnitude 
        if dist > ESP.MaxDistance then hideAll() return end
        local color, healthPercent = getRoleColor(status), math.max(0, (hum.Health or 100) / (hum.MaxHealth or 100))
        local weaponName = getPlayerWeapon(targetPlayer)
        local top, onScreen1 = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.5, 0))
        local bottom, onScreen2 = Camera:WorldToViewportPoint(root.Position - Vector3.new(0, 2, 0))
        if not (onScreen1 or onScreen2) then hideAll() return end
        
        local height, width = math.abs(top.Y - bottom.Y), math.abs(top.Y - bottom.Y) * 0.7
        local x, y = top.X - width/2, top.Y
        
        if ESP.ShowChams then 
            if esp.Highlight.Parent ~= char then esp.Highlight.Parent = char end 
            esp.Highlight.FillColor = color 
            esp.Highlight.OutlineColor = Color3.new(1,1,1) 
            esp.Highlight.Enabled = true 
        else 
            esp.Highlight.Enabled = false 
        end
        
        if ESP.ShowTracer then 
            esp.Tracer.Visible = true 
            esp.Tracer.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y) 
            esp.Tracer.To = Vector2.new(bottom.X, bottom.Y) 
            esp.Tracer.Color = color 
        else 
            esp.Tracer.Visible = false 
        end
        
        if ESP.ShowHead then 
            esp.Head.Visible = true 
            esp.Head.Position = Vector2.new(Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.2, 0)).X, Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.2, 0)).Y) 
            esp.Head.Color = color 
        else 
            esp.Head.Visible = false 
        end
        
        if ESP.ShowBox then 
            esp.Box.Visible = true 
            esp.Box.Size = Vector2.new(width, height) 
            esp.Box.Position = Vector2.new(x, y) 
            esp.Box.Color = color 
        else 
            esp.Box.Visible = false 
        end
        
        if ESP.ShowLine then 
            esp.Line.Visible = true 
            esp.Line.From = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2) 
            esp.Line.To = Vector2.new(top.X, bottom.Y) 
            esp.Line.Color = color 
        else 
            esp.Line.Visible = false 
        end
        
        if ESP.ShowName then 
            esp.Name.Visible = true 
            esp.Name.Text = targetPlayer.Name 
            esp.Name.Position = Vector2.new(top.X, top.Y - 35)
            esp.Name.Color = Color3.fromRGB(255, 255, 255)
            esp.Name.OutlineColor = Color3.fromRGB(0, 0, 0)
            esp.Name.Outline = true
            esp.Name.Size = 18
            esp.Name.Transparency = 1
        else 
            esp.Name.Visible = false 
        end
        
        if ESP.ShowWeapon and weaponName then 
            esp.Weapon.Visible = true 
            esp.Weapon.Text = "🔫 " .. weaponName 
            esp.Weapon.Position = Vector2.new(top.X, top.Y - 55) 
            if weaponName:lower():find("knife") then 
                esp.Weapon.Color = Color3.fromRGB(255, 0, 0) 
            elseif weaponName:lower():find("pistol") or weaponName:lower():find("revolver") then 
                esp.Weapon.Color = Color3.fromRGB(0, 150, 255) 
            else 
                esp.Weapon.Color = Color3.fromRGB(255, 255, 255) 
            end 
        else 
            esp.Weapon.Visible = false 
        end
        
        if ESP.ShowHealth then 
            local barW, barH, barX, barY = 30, 4, top.X - 15, bottom.Y + 4 
            esp.HealthBg.Visible = true 
            esp.HealthBg.Position = Vector2.new(barX, barY) 
            esp.HealthBg.Size = Vector2.new(barW, barH) 
            esp.HealthBg.Color = Color3.fromRGB(40, 40, 40) 
            esp.HealthBar.Visible = true 
            esp.HealthBar.Position = Vector2.new(barX, barY) 
            esp.HealthBar.Size = Vector2.new(barW * healthPercent, barH) 
            esp.HealthBar.Color = Color3.fromRGB(255 * (1 - healthPercent), 255 * healthPercent, 0) 
        else 
            esp.HealthBg.Visible = false 
            esp.HealthBar.Visible = false 
        end
        
        if ESP.ShowDistance then 
            esp.Dist.Visible = true 
            esp.Dist.Text = string.format("%.0f m", dist) 
            esp.Dist.Position = Vector2.new(top.X, bottom.Y + 12) 
            esp.Dist.Color = color 
        else 
            esp.Dist.Visible = false 
        end
        
        if ESP.ShowSkeleton then
            local points, isR15 = getSkeletonPoints(char) 
            local lineIndex = 1
            local function drawLine(fromKey, toKey)
                if points[fromKey] and points[toKey] then
                    local fromPos, toPos = Camera:WorldToViewportPoint(points[fromKey]), Camera:WorldToViewportPoint(points[toKey])
                    if fromPos.Z > 0 and toPos.Z > 0 then 
                        local line = esp.Skeleton[lineIndex] 
                        if line then 
                            line.Visible = true 
                            line.From = Vector2.new(fromPos.X, fromPos.Y) 
                            line.To = Vector2.new(toPos.X, toPos.Y) 
                            line.Color = color 
                            lineIndex = lineIndex + 1 
                        end 
                    end
                end
            end
            drawLine("Head", "UpperTorso") 
            drawLine("UpperTorso", "LowerTorso") 
            drawLine("LowerTorso", "Root")
            if isR15 then 
                drawLine("UpperTorso", "LeftUpperArm") 
                drawLine("LeftUpperArm", "LeftLowerArm") 
                drawLine("LeftLowerArm", "LeftHand") 
                drawLine("UpperTorso", "RightUpperArm") 
                drawLine("RightUpperArm", "RightLowerArm") 
                drawLine("RightLowerArm", "RightHand") 
                drawLine("LowerTorso", "LeftUpperLeg") 
                drawLine("LeftUpperLeg", "LeftLowerLeg") 
                drawLine("LeftLowerLeg", "LeftFoot") 
                drawLine("LowerTorso", "RightUpperLeg") 
                drawLine("RightUpperLeg", "RightLowerLeg") 
                drawLine("RightLowerLeg", "RightFoot")
            else 
                drawLine("UpperTorso", "LeftUpperArm") 
                drawLine("UpperTorso", "RightUpperArm") 
                drawLine("LowerTorso", "LeftUpperLeg") 
                drawLine("LowerTorso", "RightUpperLeg") 
            end
            for i = lineIndex, #esp.Skeleton do 
                esp.Skeleton[i].Visible = false 
            end
        else 
            for _, line in pairs(esp.Skeleton) do 
                line.Visible = false 
            end 
        end
    end
    esp.Connection = RunService.Heartbeat:Connect(update) 
    playerESPs[targetPlayer] = esp
end

for _, p in pairs(Players:GetPlayers()) do 
    if p ~= player then createESP(p) end 
end
Players.PlayerAdded:Connect(function(p) 
    if p ~= player then createESP(p) end 
end)
Players.PlayerRemoving:Connect(removeESP)

-- ============================================
-- ANTI-AFK
-- ============================================
local function antiAFK()
    if cheats.antiAFK then
        pcall(function()
            local root = character:FindFirstChild("HumanoidRootPart")
            if root then
                root.Velocity = Vector3.new(0, 0.1, 0)
            end
            for _, remote in pairs(ReplicatedStorage:GetDescendants()) do
                if remote:IsA("RemoteEvent") and (remote.Name:lower():find("ping") or remote.Name:lower():find("heartbeat")) then
                    pcall(function() remote:FireServer() end)
                end
            end
        end)
    end
end

task.spawn(function()
    while wait(10) do antiAFK() end
end)

-- ============================================
-- AIMBOT
-- ============================================
local fovCircle = Drawing.new("Circle") 
fovCircle.Visible = false 
fovCircle.Radius = Aimbot.FOVRadius 
fovCircle.Color = Color3.fromRGB(138, 43, 226) 
fovCircle.Thickness = 1 
fovCircle.Filled = false 
fovCircle.NumSides = 64 
fovCircle.Transparency = 1
local aimCooldown = 0

local function getAimPart(targetPlayer)
    local char = targetPlayer.Character if not char then return nil end
    local targetName = aimTargets[aimTargetIndex + 1] or "Head"
    if targetName == "Head" then 
        return char:FindFirstChild("Head") 
    else 
        return char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso") 
    end
end

local function getAimTarget()
    local mousePos, myStatus, best, bestScore = UserInputService:GetMouseLocation(), getStatus(player), nil, 99999
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= player and p.Character and isEnemy(p) then
            local targetPart = getAimPart(p)
            if targetPart then
                local screenPos = Camera:WorldToViewportPoint(targetPart.Position)
                if screenPos.Z > 0 then
                    local dist = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
                    if dist <= Aimbot.FOVRadius then
                        local targetStatus = getStatus(p) 
                        if targetStatus == "Dead" then continue end
                        local score = dist
                        if Aimbot.PrioritizeMurderer then 
                            if myStatus == "Sheriff" and targetStatus == "Murderer" then 
                                score = score - 500 
                            elseif myStatus == "Murderer" and targetStatus == "Sheriff" then 
                                score = score - 300 
                            end 
                        end
                        if score < bestScore then 
                            bestScore = score 
                            best = targetPart 
                        end
                    end
                end
            end
        end
    end 
    return best
end

RunService.Heartbeat:Connect(function()
    fovCircle.Position = UserInputService:GetMouseLocation() 
    fovCircle.Visible = Aimbot.Enabled
    if Aimbot.Enabled and UserInputService:IsMouseButtonPressed(Aimbot.AimKey) then
        local now = tick() 
        if now - aimCooldown < 0.05 then return end 
        aimCooldown = now
        local target = getAimTarget()
        if target then
            local targetPos = target.Position 
            local newCF = CFrame.new(Camera.CFrame.Position, targetPos)
            if Aimbot.Smoothness > 0 then 
                Camera.CFrame = Camera.CFrame:Lerp(newCF, 1 - Aimbot.Smoothness) 
            else 
                Camera.CFrame = newCF 
            end
        end
    end
end)

-- ============================================
-- AIMBULLET VISUAL DETECTOR
-- ============================================
local function runAimBulletVisual()
    if not cheats.aimbulletVisual then
        for _, obj in pairs(aimbulletObjects) do
            pcall(function() obj:Remove() end)
        end
        aimbulletObjects = {}
        aimbulletTarget = nil
        return
    end
    
    local root = character:FindFirstChild("HumanoidRootPart")
    if not root then return end
    
    -- Cari target terdekat
    local closestTarget, closestDist = nil, math.huge
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= player and p.Character and isEnemy(p) then
            local targetRoot = p.Character:FindFirstChild("HumanoidRootPart")
            if targetRoot then
                local dist = (root.Position - targetRoot.Position).Magnitude
                if dist < closestDist and dist < 200 then
                    closestDist = dist
                    closestTarget = p
                end
            end
        end
    end
    
    aimbulletTarget = closestTarget
    
    if not aimbulletTarget or not aimbulletTarget.Character then
        for _, obj in pairs(aimbulletObjects) do
            pcall(function() obj:Remove() end)
        end
        aimbulletObjects = {}
        return
    end
    
    -- Bersihin objects lama
    for _, obj in pairs(aimbulletObjects) do
        pcall(function() obj:Remove() end)
    end
    aimbulletObjects = {}
    
    local targetChar = aimbulletTarget.Character
    local head = targetChar:FindFirstChild("Head")
    local targetRoot = targetChar:FindFirstChild("HumanoidRootPart")
    
    if not head or not targetRoot then return end
    
    local screenPos, onScreen = Camera:WorldToViewportPoint(head.Position)
    if not onScreen or screenPos.Z <= 0 then return end
    
    local pos = Vector2.new(screenPos.X, screenPos.Y)
    
    -- Lingkaran merah besar di kepala
    local circle = Drawing.new("Circle")
    circle.Position = pos
    circle.Radius = 25
    circle.Color = Color3.fromRGB(255, 0, 0)
    circle.Thickness = 3
    circle.Filled = false
    circle.Transparency = 1
    circle.Visible = true
    table.insert(aimbulletObjects, circle)
    
    -- Lingkaran oranye berkedip
    local circle2 = Drawing.new("Circle")
    circle2.Position = pos
    circle2.Radius = 35
    circle2.Color = Color3.fromRGB(255, 165, 0)
    circle2.Thickness = 2
    circle2.Filled = false
    circle2.Transparency = 0.7
    circle2.Visible = true
    table.insert(aimbulletObjects, circle2)
    
    -- Silang merah di tengah
    local lineH = Drawing.new("Line")
    lineH.From = Vector2.new(pos.X - 15, pos.Y)
    lineH.To = Vector2.new(pos.X + 15, pos.Y)
    lineH.Color = Color3.fromRGB(255, 0, 0)
    lineH.Thickness = 2
    lineH.Visible = true
    table.insert(aimbulletObjects, lineH)
    
    local lineV = Drawing.new("Line")
    lineV.From = Vector2.new(pos.X, pos.Y - 15)
    lineV.To = Vector2.new(pos.X, pos.Y + 15)
    lineV.Color = Color3.fromRGB(255, 0, 0)
    lineV.Thickness = 2
    lineV.Visible = true
    table.insert(aimbulletObjects, lineV)
    
    -- Teks AIMBULLET LOCKED
    local text = Drawing.new("Text")
    text.Position = Vector2.new(pos.X, pos.Y - 55)
    text.Text = "🎯 AIMBULLET LOCKED!"
    text.Color = Color3.fromRGB(255, 0, 0)
    text.Size = 16
    text.Center = true
    text.Outline = true
    text.OutlineColor = Color3.fromRGB(0, 0, 0)
    text.Visible = true
    table.insert(aimbulletObjects, text)
    
    -- Nama player + jarak
    local nameText = Drawing.new("Text")
    nameText.Position = Vector2.new(pos.X, pos.Y + 40)
    nameText.Text = aimbulletTarget.Name .. " | " .. string.format("%.0f", closestDist) .. "m"
    nameText.Color = Color3.fromRGB(255, 255, 255)
    nameText.Size = 14
    nameText.Center = true
    nameText.Outline = true
    nameText.OutlineColor = Color3.fromRGB(0, 0, 0)
    nameText.Visible = true
    table.insert(aimbulletObjects, nameText)
    
    -- Tracer line
    local playerRoot = character:FindFirstChild("HumanoidRootPart")
    if playerRoot then
        local playerScreen, _ = Camera:WorldToViewportPoint(playerRoot.Position)
        if playerScreen then
            local tracer = Drawing.new("Line")
            tracer.From = Vector2.new(playerScreen.X, playerScreen.Y)
            tracer.To = pos
            tracer.Color = Color3.fromRGB(255, 0, 0)
            tracer.Thickness = 1.5
            tracer.Transparency = 0.6
            tracer.Visible = true
            table.insert(aimbulletObjects, tracer)
        end
    end
    
    -- Bounding box
    local bottomScreen, _ = Camera:WorldToViewportPoint(targetRoot.Position - Vector3.new(0, 2, 0))
    if bottomScreen then
        local height = math.abs(screenPos.Y - bottomScreen.Y)
        local width = height * 0.6
        
        local box = Drawing.new("Square")
        box.Position = Vector2.new(pos.X - width/2, screenPos.Y)
        box.Size = Vector2.new(width, height)
        box.Color = Color3.fromRGB(255, 0, 0)
        box.Thickness = 2
        box.Filled = false
        box.Transparency = 0.8
        box.Visible = true
        table.insert(aimbulletObjects, box)
    end
end

-- ============================================
-- AIMBULLET LOGIC
-- ============================================
local function runAimBullet()
    if not cheats.aimbullet then return end
    
    local root = character:FindFirstChild("HumanoidRootPart")
    if not root then return end
    
    local target = nil
    local targetDist = math.huge
    
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= player and p.Character and isEnemy(p) then
            local targetRoot = p.Character:FindFirstChild("HumanoidRootPart")
            if targetRoot then
                local dist = (root.Position - targetRoot.Position).Magnitude
                if dist < targetDist and dist < 200 then
                    targetDist = dist
                    target = p
                end
            end
        end
    end
    
    if target and target.Character then
        local targetPart = getAimPart(target)
        if targetPart then
            local targetPos = targetPart.Position
            local newCF = CFrame.new(Camera.CFrame.Position, targetPos)
            Camera.CFrame = Camera.CFrame:Lerp(newCF, 0.7)
            
            if cheats.aimbulletVisual then
                aimbulletTarget = target
            end
        end
    end
end

local function getClosestEnemyTeleport()
    local myPos = character and character:FindFirstChild("HumanoidRootPart") 
    if not myPos then return nil end
    local closest, closestDist = nil, math.huge
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= player and isEnemy(p) then
            local char = p.Character 
            if char then
                local root = char:FindFirstChild("HumanoidRootPart")
                if root and getStatus(p) ~= "Dead" then
                    local dist = (myPos.Position - root.Position).Magnitude 
                    if dist < closestDist then 
                        closestDist = dist 
                        closest = p 
                    end
                end
            end
        end
    end 
    return closest
end

local function doTeleport()
    if not cheats.teleport then return end 
    local target = getClosestEnemyTeleport() 
    if not target then return end
    local targetPart = target.Character:FindFirstChild("HumanoidRootPart") or target.Character:FindFirstChild("Head")
    local myRoot = character and character:FindFirstChild("HumanoidRootPart") 
    if not targetPart or not myRoot then return end
    local targetPos = targetPart.Position + Vector3.new(0, 2, 0)
    for _, part in pairs(character:GetDescendants()) do 
        if part:IsA("BasePart") then part.CanCollide = false end 
    end
    myRoot.CFrame = CFrame.new(targetPos) 
    task.wait(0.2)
    for _, part in pairs(character:GetDescendants()) do 
        if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then part.CanCollide = true end 
    end
end

-- ============================================
-- INPUT CATCHER
-- ============================================
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.KeyCode == Enum.KeyCode.T and (UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or UserInputService:IsKeyDown(Enum.KeyCode.RightControl)) then 
        doTeleport() 
    end
    
    if input.KeyCode == Enum.KeyCode.Q then
        toggleSlowmo()
    end
    
    if input.UserInputType == Enum.UserInputType.MouseButton1 then 
        if cheats.teleport and not menuVisible then 
            doTeleport() 
        elseif cheats.armRocket then
            shootRocket()
        end
    end
end)

-- ============================================
-- GLOBAL HEARTBEAT
-- ============================================
local timer05 = 0

RunService.Heartbeat:Connect(function()
    local now = tick()
    if now - timer05 > 0.5 then
        timer05 = now
        applyNoFog()
        applyNoSmoke()
        applyNoWaterEffect()
        applyCustomFOV()
        drawCrosshair()
        drawFishESP()
        applyWallhack()
        
        applyFishingModsSafe()
        autoFishSafe()
        autoSellSafe()
        autoFarmLoop()
        
        if character and humanoid then
            if cheats.noclip then
                for _, part in ipairs(character:GetDescendants()) do
                    if part:IsA("BasePart") and part.CanCollide == true then
                        part.CanCollide = false
                    end
                end
            end
        end
        
        if not rocketLauncher or not rocketLauncher.Parent then
            rocketLauncher = findRocketLauncher()
        end
    end
    
    -- SPEEDHACK
    if character and humanoid then
        if cheats.speed then
            humanoid.WalkSpeed = CHEAT_SPEED
        else
            humanoid.WalkSpeed = NORMAL_SPEED
        end
        
        if cheats.jump then
            humanoid.UseJumpPower = true
            humanoid.JumpPower = CHEAT_JUMP
        else
            humanoid.JumpPower = NORMAL_JUMP
        end
    end
    
    -- SPINBOT
    if cheats.spinbot then
        local root = character:FindFirstChild("HumanoidRootPart")
        if root then
            root.CFrame = root.CFrame * CFrame.Angles(0, math.rad(400), 0)
        end
    end
    
    -- FLY HACK
    if cheats.fly and character and humanoid then
        humanoid.PlatformStand = true
        local root = character:FindFirstChild("HumanoidRootPart")
        if root then
            local flySpeed = 50
            local moveDirection = Vector3.new(0, 0, 0)
            
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDirection = moveDirection + Camera.CFrame.LookVector * Vector3.new(1, 0, 1) end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDirection = moveDirection - Camera.CFrame.LookVector * Vector3.new(1, 0, 1) end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDirection = moveDirection - Camera.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDirection = moveDirection + Camera.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveDirection = moveDirection + Vector3.new(0, 1, 0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then moveDirection = moveDirection - Vector3.new(0, 1, 0) end
            
            if moveDirection.Magnitude > 0 then
                moveDirection = moveDirection.Unit * flySpeed
                root.Velocity = Vector3.new(moveDirection.X, moveDirection.Y, moveDirection.Z)
            else
                root.Velocity = Vector3.new(0, 0, 0)
            end
        end
    elseif not cheats.fly and character and humanoid then
        humanoid.PlatformStand = false
    end
    
    -- AUTO-COLLECT
    if cheats.autoCollect then
        local root = character:FindFirstChild("HumanoidRootPart")
        if root then
            local collectRadius = 50
            for _, v in pairs(workspace:GetDescendants()) do
                if v:IsA("BasePart") and v.Parent and v.Parent:IsA("Model") then
                    local parentName = v.Parent.Name:lower()
                    if parentName:find("fish") or parentName:find("coin") or parentName:find("money") or parentName:find("gem") or parentName:find("crystal") or parentName:find("material") or parentName:find("resource") or parentName:find("item") then
                        local dist = (root.Position - v.Position).Magnitude
                        if dist <= collectRadius then
                            pcall(function()
                                local clone = v:Clone()
                                clone.Position = root.Position + Vector3.new(math.random(-2, 2), 1, math.random(-2, 2))
                                clone.Parent = workspace
                                v:Destroy()
                            end)
                        end
                    end
                end
            end
        end
    end
    
    -- RAPID FIRE
    if cheats.rapidFire then
        local tool = character:FindFirstChildOfClass("Tool")
        if tool then
            pcall(function()
                for _, child in pairs(tool:GetDescendants()) do
                    if child:IsA("RemoteEvent") or child:IsA("RemoteFunction") then
                        for i = 1, 5 do
                            task.wait(0.05)
                            pcall(function() child:FireServer() end)
                        end
                    end
                end
                if tool:FindFirstChild("ClickDetector") then
                    for i = 1, 5 do
                        task.wait(0.05)
                        pcall(function() tool.ClickDetector:Click() end)
                    end
                end
            end)
        end
    end
    
    -- AIMBULLET
    if cheats.aimbullet then
        runAimBullet()
    end
    
    -- AIMBULLET VISUAL
    runAimBulletVisual()
end)

UserInputService.JumpRequest:Connect(function() 
    if cheats.infJump and humanoid then 
        humanoid:ChangeState(Enum.HumanoidStateType.Jumping) 
    end 
end)

task.spawn(function()
    while true do
        task.wait(1) 
        for _, item in pairs(items) do
            if item.type == "info" and type(item.label) == "string" and string.match(item.label, "Target:") then 
                item.label = "Target: " .. aimTargets[aimTargetIndex + 1] 
                menuDirty = true 
            end
            if item.type == "info" and type(item.label) == "string" and string.match(item.label, "Date:") then 
                item.label = getStatusText() 
                menuDirty = true 
            end
        end
    end
end)

-- ============================================
-- RENDER LOOP
-- ============================================
RunService.RenderStepped:Connect(render) 
buildMenu() 
menuDirty = true

print("[ BlackHck⚡ ] V5.9 FINAL INJECTED - ALL FEATURES LOCKED!")
print("[ BlackHck⚡ ] TOTAL 29+ FITUR AKTIF - TIDAK ADA YANG DIHAPUS")
print("[ BlackHck⚡ ] ROCKET SYSTEM | SHADOW MODE | ESP | VISUAL")
print("[ BlackHck⚡ ] FLY HACK | AUTO-COLLECT | ANTI-AFK | RAPID FIRE")
print("[ BlackHck⚡ ] AIMBULLET VISUAL DETECTOR - TARGET KELIHATAN JELAS")
print("[ BlackHck⚡ ] Tekan RightShift / Insert buka menu")
