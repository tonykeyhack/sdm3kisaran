-- ============================================
-- TAMBAHAN CHEAT STATES
-- ============================================
local cheats = {
    -- ... (semua yg udah ada tetep)
    
    -- TAMBAHAN
    itemESP = false,
    antiStun = false,
    autoHeal = false,
    damageMultiplier = false,
    invisibleMode = false,
    autoTalk = false,
}

local damageMultiplierLevel = 2 -- 2x, 3x, 5x
local autoHealThreshold = 30 -- heal kalo HP di bawah 30%
local autoTalkMessages = {"gg", "ez", "nice", "lol", "bruh", "wtf", "no way"}
local autoTalkCooldown = 0

-- ============================================
-- ITEM ESP (MASUK ESP MENU)
-- ============================================
local itemESPObjects = {}

local function clearItemESP()
    for _, obj in pairs(itemESPObjects) do
        pcall(function() obj:Remove() end)
    end
    itemESPObjects = {}
end

local function runItemESP()
    clearItemESP()
    if not cheats.itemESP then return end
    
    local root = character:FindFirstChild("HumanoidRootPart")
    if not root then return end
    
    for _, v in pairs(workspace:GetDescendants()) do
        if v:IsA("BasePart") and v.Parent and v.Parent:IsA("Model") then
            local parentName = v.Parent.Name:lower()
            local isItem = parentName:find("gun") or parentName:find("weapon") or parentName:find("ammo") or 
                          parentName:find("health") or parentName:find("medkit") or parentName:find("shield") or
                          parentName:find("key") or parentName:find("tool") or parentName:find("item") or
                          parentName:find("chest") or parentName:find("crate") or parentName:find("loot")
            
            if isItem then
                local dist = (root.Position - v.Position).Magnitude
                if dist <= 200 then
                    local screenPos, onScreen = Camera:WorldToViewportPoint(v.Position)
                    if onScreen and screenPos.Z > 0 then
                        local pos = Vector2.new(screenPos.X, screenPos.Y)
                        local color = Color3.fromRGB(0, 255, 255)
                        
                        -- Square marker
                        local sq = Drawing.new("Square")
                        sq.Position = Vector2.new(pos.X - 10, pos.Y - 10)
                        sq.Size = Vector2.new(20, 20)
                        sq.Color = color
                        sq.Thickness = 2
                        sq.Filled = false
                        sq.Visible = true
                        table.insert(itemESPObjects, sq)
                        
                        -- Nama item
                        local txt = Drawing.new("Text")
                        txt.Position = Vector2.new(pos.X, pos.Y - 25)
                        txt.Text = v.Parent.Name
                        txt.Color = color
                        txt.Size = 11
                        txt.Center = true
                        txt.Outline = true
                        txt.OutlineColor = Color3.fromRGB(0, 0, 0)
                        txt.Visible = true
                        table.insert(itemESPObjects, txt)
                        
                        -- Jarak
                        local distText = Drawing.new("Text")
                        distText.Position = Vector2.new(pos.X, pos.Y + 20)
                        distText.Text = string.format("%.0fm", dist)
                        distText.Color = Color3.fromRGB(255, 255, 255)
                        distText.Size = 10
                        distText.Center = true
                        distText.Outline = true
                        distText.OutlineColor = Color3.fromRGB(0, 0, 0)
                        distText.Visible = true
                        table.insert(itemESPObjects, distText)
                    end
                end
            end
        end
    end
end

-- ============================================
-- ANTI-STUN (MASUK MEDIUM MENU)
-- ============================================
local function runAntiStun()
    if not cheats.antiStun then return end
    
    -- Reset stun effects
    if humanoid then
        pcall(function()
            humanoid.WalkSpeed = cheats.speed and CHEAT_SPEED or NORMAL_SPEED
            humanoid.JumpPower = cheats.jump and CHEAT_JUMP or NORMAL_JUMP
            humanoid.PlatformStand = false
        end)
    end
    
    -- Remove stun visual effects
    for _, v in pairs(character:GetDescendants()) do
        if v:IsA("BlurEffect") or v:IsA("ColorCorrectionEffect") or v:IsA("BloomEffect") then
            pcall(function() v.Enabled = false end)
        end
        if v:IsA("ParticleEmitter") and v.Name:lower():find("stun") then
            pcall(function() v.Enabled = false end)
        end
    end
end

-- ============================================
-- AUTO-HEAL (MASUK MEDIUM MENU)
-- ============================================
local function runAutoHeal()
    if not cheats.autoHeal then return end
    if not humanoid then return end
    
    local healthPercent = (humanoid.Health / humanoid.MaxHealth) * 100
    
    if healthPercent < autoHealThreshold then
        -- Cari item heal di sekitar
        local root = character:FindFirstChild("HumanoidRootPart")
        if root then
            for _, v in pairs(workspace:GetDescendants()) do
                if v:IsA("BasePart") and v.Parent and v.Parent:IsA("Model") then
                    local parentName = v.Parent.Name:lower()
                    if parentName:find("health") or parentName:find("medkit") or parentName:find("heal") then
                        local dist = (root.Position - v.Position).Magnitude
                        if dist <= 20 then
                            pcall(function()
                                local clone = v:Clone()
                                clone.Position = root.Position + Vector3.new(0, 2, 0)
                                clone.Parent = workspace
                                v:Destroy()
                            end)
                        end
                    end
                end
            end
        end
        
        -- Auto-use heal tool
        local tool = character:FindFirstChildOfClass("Tool")
        if tool and (tool.Name:lower():find("heal") or tool.Name:lower():find("med") or tool.Name:lower():find("health")) then
            pcall(function() tool:Activate() end)
        end
    end
end

-- ============================================
-- DAMAGE MULTIPLIER (MASUK HARD MENU)
-- ============================================
local originalDamage = {}
local damageMultiplierValue = 2

local function runDamageMultiplier()
    if not cheats.damageMultiplier then return end
    
    for _, v in pairs(workspace:GetDescendants()) do
        if v:IsA("NumberValue") and (v.Name:lower():find("damage") or v.Name:lower():find("dmg") or v.Name:lower():find("attack") or v.Name:lower():find("hit")) then
            if originalDamage[v] == nil then
                originalDamage[v] = v.Value
            end
            v.Value = originalDamage[v] * damageMultiplierValue
        end
        
        if v:IsA("IntValue") and (v.Name:lower():find("damage") or v.Name:lower():find("dmg")) then
            if originalDamage[v] == nil then
                originalDamage[v] = v.Value
            end
            v.Value = math.floor(originalDamage[v] * damageMultiplierValue)
        end
        
        if v:IsA("Tool") and v:FindFirstChild("Damage") then
            local dmg = v.Damage
            if dmg:IsA("NumberValue") then
                if originalDamage[dmg] == nil then
                    originalDamage[dmg] = dmg.Value
                end
                dmg.Value = originalDamage[dmg] * damageMultiplierValue
            end
        end
    end
end

-- ============================================
-- INVISIBLE MODE (MASUK HARD MENU)
-- ============================================
local function runInvisibleMode()
    if not cheats.invisibleMode then return end
    
    for _, part in pairs(character:GetDescendants()) do
        if part:IsA("BasePart") then
            pcall(function()
                part.Transparency = 1
                part.Material = Enum.Material.SmoothPlastic
                part.CanCollide = false
            end)
        end
        if part:IsA("Accessory") or part:IsA("Clothing") then
            pcall(function()
                part.Transparency = 1
            end)
        end
    end
    
    if humanoid then
        pcall(function()
            humanoid.WalkSpeed = cheats.speed and CHEAT_SPEED or NORMAL_SPEED
        end)
    end
end

local function restoreVisibility()
    for _, part in pairs(character:GetDescendants()) do
        if part:IsA("BasePart") then
            pcall(function()
                if not cheats.invisibleMode then
                    part.Transparency = 0
                    part.CanCollide = true
                end
            end)
        end
        if part:IsA("Accessory") or part:IsA("Clothing") then
            pcall(function()
                if not cheats.invisibleMode then
                    part.Transparency = 0
                end
            end)
        end
    end
end

-- ============================================
-- AUTO-TALK (MASUK MEDIUM MENU)
-- ============================================
local function runAutoTalk()
    if not cheats.autoTalk then return end
    local now = tick()
    if now - autoTalkCooldown < 15 then return end
    autoTalkCooldown = now
    
    local msg = autoTalkMessages[math.random(1, #autoTalkMessages)]
    pcall(function()
        game:GetService("ReplicatedStorage"):FindFirstChild("DefaultChatSystemChatEvents") or 
        game:GetService("ReplicatedStorage"):FindFirstChild("Chat")
        
        local chatRemote = ReplicatedStorage:FindFirstChild("SayMessageRequest") or
                          ReplicatedStorage:FindFirstChild("ChatRemote") or
                          ReplicatedStorage:FindFirstChild("SendMessage")
        
        if chatRemote then
            if chatRemote:IsA("RemoteEvent") then
                chatRemote:FireServer(msg, "All")
            elseif chatRemote:IsA("RemoteFunction") then
                chatRemote:InvokeServer(msg, "All")
            end
        else
            -- Alternative chat
            for _, v in pairs(ReplicatedStorage:GetDescendants()) do
                if v:IsA("RemoteEvent") and (v.Name:lower():find("chat") or v.Name:lower():find("say") or v.Name:lower():find("message")) then
                    pcall(function() v:FireServer(msg) end)
                    break
                end
            end
        end
    end)
end

-- ============================================
-- UPDATE MENU BUILD
-- ============================================
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
        -- TAMBAHAN ITEM ESP
        {label = "Item ESP", state = function() return cheats.itemESP end, set = function(v) cheats.itemESP = v end},
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
        -- TAMBAHAN MEDIUM MENU
        {label = "Anti-Stun", state = function() return cheats.antiStun end, set = function(v) cheats.antiStun = v end},
        {label = "Auto-Heal", state = function() return cheats.autoHeal end, set = function(v) cheats.autoHeal = v end},
        {label = "Auto-Talk", state = function() return cheats.autoTalk end, set = function(v) cheats.autoTalk = v end},
    }})
    
    add("[ Hard Menu ]", "folder", {open = false, children = {
        {label = "God Mode", state = function() return GodMode.Enabled end, set = function(v) GodMode.Enabled = v end},
        {label = "Spinbot", state = function() return cheats.spinbot end, set = function(v) cheats.spinbot = v end},
        {label = "Spectate Hack", state = function() return cheats.spectate end, set = function(v) cheats.spectate = v end},
        {label = "Fast Kill", state = function() return FastKill.Enabled end, set = function(v) FastKill.Enabled = v end},
        {label = "Noclip", state = function() return cheats.noclip end, set = function(v) cheats.noclip = v end},
        {label = "Teleport", state = function() return cheats.teleport end, set = function(v) cheats.teleport = v end},
        {label = "Rapid Fire", state = function() return cheats.rapidFire end, set = function(v) cheats.rapidFire = v end},
        -- TAMBAHAN HARD MENU
        {label = "Damage Multiplier", state = function() return cheats.damageMultiplier end, set = function(v) cheats.damageMultiplier = v end},
        {label = "Invisible Mode", state = function() return cheats.invisibleMode end, set = function(v) cheats.invisibleMode = v end},
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
    add("TOTAL 35+ FITUR AKTIF!", "info", nil)
end

-- ============================================
-- UPDATE HEARTBEAT LOOP
-- ============================================
local function updateAllFeatures()
    if not character or not humanoid then return end
    
    -- Semua fitur yg udah ada tetap jalan
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
    runAimBullet()
    runAimBulletVisual()
    runItemESP()
    runAntiStun()
    runAutoHeal()
    runDamageMultiplier()
    runAutoTalk()
    
    -- Invisible mode
    if cheats.invisibleMode then
        runInvisibleMode()
    else
        restoreVisibility()
    end
    
    -- Damage multiplier level (bisa di-upgrade via UI)
    if cheats.damageMultiplier then
        -- Default 2x, user bisa ganti manual di sini
        damageMultiplierValue = 2
    end
    
    -- Speed & Jump
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
    
    -- Spinbot
    if cheats.spinbot then
        local root = character:FindFirstChild("HumanoidRootPart")
        if root then
            root.CFrame = root.CFrame * CFrame.Angles(0, math.rad(400), 0)
        end
    end
    
    -- Fly Hack
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
    
    -- Auto-Collect
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
    
    -- Rapid Fire
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
    
    -- Noclip
    if cheats.noclip then
        for _, part in ipairs(character:GetDescendants()) do
            if part:IsA("BasePart") and part.CanCollide == true then
                part.CanCollide = false
            end
        end
    end
end

-- Update loop
RunService.Heartbeat:Connect(function()
    local now = tick()
    if now - timer05 > 0.5 then
        timer05 = now
        updateAllFeatures()
    end
end)

print("[ BlackHck⚡ ] V5.9 FINAL + 6 FITUR BARU!")
print("[ BlackHck⚡ ] TOTAL 35+ FITUR AKTIF - SEMUA FITUR TETAP ADA!")
print("[ BlackHck⚡ ] Item ESP | Anti-Stun | Auto-Heal | Damage Multiplier | Invisible Mode | Auto-Talk")
print("[ BlackHck⚡ ] Tekan RightShift / Insert buka menu")
