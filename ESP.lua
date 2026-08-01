-- // Ultra D3D Keyboard Menu v4.0 by BlackHck //
-- // Full Keyboard Navigation (Arrow Keys + Enter) //
-- // Auto-select, Hover effect, Live Update //

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- ==========================================
-- CORE DRAWING ENGINE
-- ==========================================

local D3D = {
    Objects = {},
    Mouse = Vector2.new(0, 0),
    Resolution = Vector2.new(1920, 1080),
    Scale = 1,
    Visible = false,
    MenuPosition = Vector2.new(400, 150),
    MenuSize = Vector2.new(420, 520),
    
    -- Navigation state
    SelectedIndex = 1,
    SelectedTab = 1,
    MaxItems = 0,
    Items = {},
    Tabs = {"AIMBOT", "VISUALS", "COMBAT", "MISC"},
    CurrentTab = 1,
    
    -- Animation
    AnimationProgress = 0,
    Animating = false
}

-- Utility Functions
local function HexToRGB(hex)
    hex = hex:gsub("#", "")
    return Color3.fromRGB(tonumber("0x"..hex:sub(1,2)), 
                          tonumber("0x"..hex:sub(3,4)), 
                          tonumber("0x"..hex:sub(5,6)))
end

local function RGBToHex(color)
    return string.format("#%02X%02X%02X", color.R*255, color.G*255, color.B*255)
end

local function IsPointInRect(point, pos, size)
    return point.X >= pos.X and point.X <= pos.X + size.X and
           point.Y >= pos.Y and point.Y <= pos.Y + size.Y
end

-- Create UI Elements
function D3D:CreateText(text, pos, size, color, center, outline)
    local obj = Drawing.new("Text")
    obj.Text = text
    obj.Position = pos
    obj.Size = size or 16
    obj.Color = color or Color3.new(1,1,1)
    obj.Center = center or false
    obj.Outline = outline or true
    obj.OutlineColor = Color3.new(0,0,0)
    obj.Visible = false
    table.insert(self.Objects, obj)
    return obj
end

function D3D:CreateRectangle(pos, size, color, filled, thickness)
    local obj = Drawing.new("Square")
    obj.Position = pos
    obj.Size = size
    obj.Color = color or Color3.new(1,1,1)
    obj.Filled = filled or false
    obj.Thickness = thickness or 1
    obj.Visible = false
    table.insert(self.Objects, obj)
    return obj
end

function D3D:CreateCircle(pos, radius, color, filled, thickness)
    local obj = Drawing.new("Circle")
    obj.Position = pos
    obj.Radius = radius
    obj.Color = color or Color3.new(1,1,1)
    obj.Filled = filled or false
    obj.Thickness = thickness or 1
    obj.NumSides = 64
    obj.Visible = false
    table.insert(self.Objects, obj)
    return obj
end

-- ==========================================
-- GRADIENT ENGINE
-- ==========================================

function D3D:CreateGradient(pos, size, color1, color2, direction)
    local objects = {}
    local steps = 20
    local stepSize = direction == "horizontal" and size.X / steps or size.Y / steps
    
    for i = 0, steps do
        local t = i / steps
        local color = color1:Lerp(color2, t)
        local rectPos, rectSize
        
        if direction == "horizontal" then
            rectPos = Vector2.new(pos.X + (stepSize * i), pos.Y)
            rectSize = Vector2.new(stepSize + 1, size.Y)
        else
            rectPos = Vector2.new(pos.X, pos.Y + (stepSize * i))
            rectSize = Vector2.new(size.X, stepSize + 1)
        end
        
        local rect = self:CreateRectangle(rectPos, rectSize, color, true, 0)
        table.insert(objects, rect)
    end
    
    return objects
end

-- ==========================================
-- MENU CLASS
-- ==========================================

local Menu = {
    Visible = false,
    Position = D3D.MenuPosition,
    Size = D3D.MenuSize,
    TitleHeight = 40,
    TabHeight = 35,
    Animating = false,
    AnimationProgress = 0,
    CurrentTab = 1,
    SelectedIndex = 1,
    Items = {},
    ItemPositions = {},
    Tabs = D3D.Tabs
}

-- ==========================================
-- DRAW MENU
-- ==========================================

function Menu:Draw()
    -- Clear old objects
    for _, obj in pairs(D3D.Objects) do
        pcall(obj.Remove, obj)
    end
    D3D.Objects = {}
    self.ItemPositions = {}
    self.Items = {}
    
    local pos = self.Position
    local size = self.Size
    
    -- Shadow
    for i = 1, 10 do
        local shadow = D3D:CreateRectangle(
            Vector2.new(pos.X - i/2, pos.Y - i/2),
            Vector2.new(size.X + i, size.Y + i),
            Color3.new(0, 0, 0),
            true,
            0
        )
        shadow.Transparency = 0.5 - (i/10) * 0.4
    end
    
    -- Main Background (Gradient)
    local bg = D3D:CreateGradient(
        pos,
        size,
        Color3.fromRGB(18, 18, 25),
        Color3.fromRGB(8, 8, 15),
        "vertical"
    )
    
    -- Border Glow
    local border = D3D:CreateRectangle(
        pos,
        size,
        HexToRGB("#00BFFF"),
        false,
        2
    )
    
    -- Title Bar (Gradient)
    local titleBg = D3D:CreateGradient(
        Vector2.new(pos.X, pos.Y),
        Vector2.new(size.X, self.TitleHeight),
        HexToRGB("#00BFFF"),
        HexToRGB("#0066FF"),
        "horizontal"
    )
    
    -- Title Text
    local title = D3D:CreateText(
        "◈ ULTRA D3D v4.0",
        Vector2.new(pos.X + 15, pos.Y + 10),
        18,
        Color3.new(1, 1, 1),
        false
    )
    
    -- Close Button (dengan X)
    local closeBg = D3D:CreateRectangle(
        Vector2.new(pos.X + size.X - 30, pos.Y + 8),
        Vector2.new(20, 20),
        HexToRGB("#FF0044"),
        true,
        0
    )
    local closeText = D3D:CreateText(
        "✕",
        Vector2.new(pos.X + size.X - 20, pos.Y + 12),
        16,
        Color3.new(1, 1, 1),
        true
    )
    
    -- Tabs
    for i, tabName in ipairs(self.Tabs) do
        local tabX = pos.X + (i - 1) * (size.X / #self.Tabs)
        local isActive = i == self.CurrentTab
        
        local tabBg = D3D:CreateRectangle(
            Vector2.new(tabX, pos.Y + self.TitleHeight),
            Vector2.new(size.X / #self.Tabs, self.TabHeight),
            isActive and HexToRGB("#00BFFF") or Color3.fromRGB(28, 28, 35),
            true,
            0
        )
        
        -- Underline untuk tab aktif
        if isActive then
            local underline = D3D:CreateRectangle(
                Vector2.new(tabX + 10, pos.Y + self.TitleHeight + self.TabHeight - 3),
                Vector2.new(size.X / #self.Tabs - 20, 3),
                HexToRGB("#00FFFF"),
                true,
                0
            )
        end
        
        local tabText = D3D:CreateText(
            tabName,
            Vector2.new(tabX + (size.X / #self.Tabs) / 2, pos.Y + self.TitleHeight + 12),
            13,
            isActive and Color3.new(1, 1, 1) or Color3.fromRGB(160, 160, 160),
            true
        )
    end
    
    -- Content Background
    local contentBg = D3D:CreateRectangle(
        Vector2.new(pos.X + 10, pos.Y + self.TitleHeight + self.TabHeight + 10),
        Vector2.new(size.X - 20, size.Y - self.TitleHeight - self.TabHeight - 50),
        Color3.fromRGB(12, 12, 18),
        true,
        0
    )
    
    -- Draw items based on current tab
    self:DrawTabItems()
    
    -- Keyboard navigation hint
    local hint = D3D:CreateText(
        "↑↓ Navigate | ←→ Tabs | Enter Toggle | Insert Close",
        Vector2.new(pos.X + size.X/2, pos.Y + size.Y - 15),
        11,
        Color3.fromRGB(100, 100, 120),
        true
    )
end

-- ==========================================
-- DRAW TAB ITEMS
-- ==========================================

function Menu:DrawTabItems()
    local pos = self.Position
    local startY = pos.Y + self.TitleHeight + self.TabHeight + 20
    local xOffset = 20
    local itemSpacing = 40
    local index = 1
    
    -- Reset items
    self.Items = {}
    self.ItemPositions = {}
    
    -- Tab 1: AIMBOT
    if self.CurrentTab == 1 then
        local items = {
            {type = "toggle", label = "Aimbot Enabled", default = false},
            {type = "toggle", label = "Show FOV", default = true},
            {type = "toggle", label = "Prioritize Murderer", default = true},
            {type = "slider", label = "FOV Radius", min = 50, max = 300, default = 150},
            {type = "slider", label = "Smoothness", min = 0, max = 100, default = 30},
            {type = "slider", label = "Aim Speed", min = 1, max = 20, default = 5}
        }
        
        for i, item in ipairs(items) do
            local yPos = startY + (i - 1) * itemSpacing
            self:CreateItem(item, Vector2.new(pos.X + xOffset, yPos), index)
            index = index + 1
        end
    end
    
    -- Tab 2: VISUALS
    if self.CurrentTab == 2 then
        local items = {
            {type = "toggle", label = "ESP Enabled", default = true},
            {type = "toggle", label = "Show Box", default = true},
            {type = "toggle", label = "Show Lines", default = false},
            {type = "toggle", label = "Show Names", default = true},
            {type = "toggle", label = "Show Distances", default = true},
            {type = "slider", label = "Max Distance", min = 500, max = 5000, default = 2000}
        }
        
        for i, item in ipairs(items) do
            local yPos = startY + (i - 1) * itemSpacing
            self:CreateItem(item, Vector2.new(pos.X + xOffset, yPos), index)
            index = index + 1
        end
    end
    
    -- Tab 3: COMBAT
    if self.CurrentTab == 3 then
        local items = {
            {type = "toggle", label = "God Mode", default = false},
            {type = "toggle", label = "Fast Kill", default = false},
            {type = "toggle", label = "Auto Pickup", default = false},
            {type = "slider", label = "Pickup Range", min = 5, max = 50, default = 15},
            {type = "slider", label = "Kill Delay (ms)", min = 0, max = 1000, default = 100}
        }
        
        for i, item in ipairs(items) do
            local yPos = startY + (i - 1) * itemSpacing
            self:CreateItem(item, Vector2.new(pos.X + xOffset, yPos), index)
            index = index + 1
        end
    end
    
    -- Tab 4: MISC
    if self.CurrentTab == 4 then
        local items = {
            {type = "toggle", label = "Anti-AFK", default = false},
            {type = "toggle", label = "Auto-Rejoin", default = false},
            {type = "slider", label = "AFK Timer (min)", min = 1, max = 15, default = 5}
        }
        
        for i, item in ipairs(items) do
            local yPos = startY + (i - 1) * itemSpacing
            self:CreateItem(item, Vector2.new(pos.X + xOffset, yPos), index)
            index = index + 1
        end
    end
    
    self.MaxItems = index - 1
    
    -- Highlight selected item
    if self.SelectedIndex > 0 and self.SelectedIndex <= self.MaxItems then
        local selPos = self.ItemPositions[self.SelectedIndex]
        if selPos then
            local highlight = D3D:CreateRectangle(
                Vector2.new(selPos.X - 5, selPos.Y - 2),
                Vector2.new(380, 32),
                HexToRGB("#00BFFF"),
                false,
                2
            )
            highlight.Transparency = 0.3
        end
    end
end

-- ==========================================
-- CREATE ITEM (Toggle/Slider)
-- ==========================================

function Menu:CreateItem(item, pos, index)
    local isSelected = (index == self.SelectedIndex)
    local highlightColor = isSelected and HexToRGB("#00BFFF") or Color3.fromRGB(60, 60, 70)
    
    -- Background (hover/select effect)
    local bg = D3D:CreateRectangle(
        Vector2.new(pos.X - 5, pos.Y - 2),
        Vector2.new(380, 32),
        highlightColor,
        false,
        1
    )
    bg.Transparency = isSelected and 0.2 or 0.5
    
    -- Label
    local label = D3D:CreateText(
        item.label,
        Vector2.new(pos.X + 10, pos.Y + 8),
        14,
        isSelected and Color3.new(1, 1, 1) or Color3.fromRGB(200, 200, 200),
        false
    )
    
    -- Store item data
    local itemData = {
        type = item.type,
        label = item.label,
        pos = pos,
        index = index,
        objects = {bg, label},
        value = item.default or false,
        min = item.min or 0,
        max = item.max or 100,
        current = item.default or 0
    }
    
    -- Toggle
    if item.type == "toggle" then
        local toggleBg = D3D:CreateRectangle(
            Vector2.new(pos.X + 330, pos.Y + 4),
            Vector2.new(40, 20),
            itemData.value and HexToRGB("#00FF00") or Color3.fromRGB(60, 60, 60),
            true,
            0
        )
        
        local knob = D3D:CreateCircle(
            Vector2.new(pos.X + (itemData.value and 360 or 340), pos.Y + 14),
            8,
            itemData.value and HexToRGB("#00FF00") or Color3.fromRGB(200, 200, 200),
            true,
            0
        )
        
        local status = D3D:CreateText(
            itemData.value and "ON" or "OFF",
            Vector2.new(pos.X + 380, pos.Y + 8),
            12,
            itemData.value and Color3.new(0, 1, 0) or Color3.fromRGB(200, 50, 50),
            false
        )
        
        itemData.objects = {bg, label, toggleBg, knob, status}
        itemData.Update = function(self, newValue)
            self.value = newValue
            toggleBg.Color = newValue and HexToRGB("#00FF00") or Color3.fromRGB(60, 60, 60)
            knob.Position = Vector2.new(pos.X + (newValue and 360 or 340), pos.Y + 14)
            knob.Color = newValue and HexToRGB("#00FF00") or Color3.fromRGB(200, 200, 200)
            status.Text = newValue and "ON" or "OFF"
            status.Color = newValue and Color3.new(0, 1, 0) or Color3.fromRGB(200, 50, 50)
        end
    end
    
    -- Slider
    if item.type == "slider" then
        local sliderWidth = 150
        local sliderX = pos.X + 200
        
        -- Track
        local track = D3D:CreateRectangle(
            Vector2.new(sliderX, pos.Y + 14),
            Vector2.new(sliderWidth, 6),
            Color3.fromRGB(40, 40, 40),
            true,
            0
        )
        
        -- Fill
        local progress = (itemData.current - itemData.min) / (itemData.max - itemData.min)
        local fill = D3D:CreateRectangle(
            Vector2.new(sliderX, pos.Y + 14),
            Vector2.new(progress * sliderWidth, 6),
            HexToRGB("#00BFFF"),
            true,
            0
        )
        
        -- Knob
        local knob = D3D:CreateCircle(
            Vector2.new(sliderX + progress * sliderWidth, pos.Y + 17),
            8,
            isSelected and HexToRGB("#00FFFF") or HexToRGB("#00BFFF"),
            true,
            0
        )
        knob.Thickness = 2
        
        -- Value text
        local valueText = D3D:CreateText(
            tostring(math.round(itemData.current)),
            Vector2.new(sliderX + sliderWidth + 20, pos.Y + 8),
            13,
            HexToRGB("#00BFFF"),
            false
        )
        
        itemData.objects = {bg, label, track, fill, knob, valueText}
        itemData.Update = function(self, newValue)
            self.current = math.clamp(newValue, self.min, self.max)
            local newProgress = (self.current - self.min) / (self.max - self.min)
            fill.Size = Vector2.new(newProgress * sliderWidth, 6)
            knob.Position = Vector2.new(sliderX + newProgress * sliderWidth, pos.Y + 17)
            valueText.Text = tostring(math.round(self.current))
        end
    end
    
    self.Items[index] = itemData
    self.ItemPositions[index] = pos
end

-- ==========================================
-- NAVIGATION HANDLING
-- ==========================================

function Menu:Navigate(direction)
    if not self.Visible then return end
    
    if direction == "up" then
        self.SelectedIndex = math.max(1, self.SelectedIndex - 1)
    elseif direction == "down" then
        self.SelectedIndex = math.min(self.MaxItems, self.SelectedIndex + 1)
    elseif direction == "left" then
        self.CurrentTab = math.max(1, self.CurrentTab - 1)
        self.SelectedIndex = 1
        self:Refresh()
        return
    elseif direction == "right" then
        self.CurrentTab = math.min(#self.Tabs, self.CurrentTab + 1)
        self.SelectedIndex = 1
        self:Refresh()
        return
    end
    
    self:Refresh()
end

function Menu:Select()
    local item = self.Items[self.SelectedIndex]
    if not item then return end
    
    if item.type == "toggle" then
        item.Update(item, not item.value)
        print(item.label .. " → " .. tostring(item.value))
    elseif item.type == "slider" then
        -- Increment slider by 5
        local newValue = item.current + 5
        if newValue > item.max then newValue = item.min end
        item.Update(item, newValue)
        print(item.label .. " → " .. tostring(math.round(item.current)))
    end
end

function Menu:Refresh()
    self:Draw()
end

function Menu:Toggle()
    self.Visible = not self.Visible
    if self.Visible then
        self:Draw()
    else
        for _, obj in pairs(D3D.Objects) do
            obj.Visible = false
        end
    end
end

-- ==========================================
-- INPUT HANDLING
-- ==========================================

UIS.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    
    -- Toggle menu with INSERT
    if input.KeyCode == Enum.KeyCode.Insert then
        Menu:Toggle()
        return
    end
    
    if not Menu.Visible then return end
    
    -- Arrow keys navigation
    if input.KeyCode == Enum.KeyCode.Up then
        Menu:Navigate("up")
    elseif input.KeyCode == Enum.KeyCode.Down then
        Menu:Navigate("down")
    elseif input.KeyCode == Enum.KeyCode.Left then
        Menu:Navigate("left")
    elseif input.KeyCode == Enum.KeyCode.Right then
        Menu:Navigate("right")
    elseif input.KeyCode == Enum.KeyCode.Enter or input.KeyCode == Enum.KeyCode.Space then
        Menu:Select()
    elseif input.KeyCode == Enum.KeyCode.Escape then
        Menu:Toggle()
    end
end)

-- ==========================================
-- MOUSE HANDLING (Optional fallback)
-- ==========================================

UIS.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if not Menu.Visible then return end
    if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
    
    local mousePos = UIS:GetMouseLocation()
    
    -- Check close button
    local closePos = Vector2.new(Menu.Position.X + Menu.Size.X - 30, Menu.Position.Y + 8)
    if IsPointInRect(mousePos, closePos, Vector2.new(20, 20)) then
        Menu:Toggle()
        return
    end
    
    -- Check if clicking on item (for mouse support)
    for i, item in pairs(Menu.Items) do
        if item.pos then
            local itemRect = {
                Position = Vector2.new(item.pos.X - 5, item.pos.Y - 2),
                Size = Vector2.new(380, 32)
            }
            if IsPointInRect(mousePos, itemRect.Position, itemRect.Size) then
                Menu.SelectedIndex = i
                Menu:Select()
                Menu:Refresh()
                break
            end
        end
    end
end)

-- ==========================================
-- CLEANUP
-- ==========================================

local function Cleanup()
    for _, obj in pairs(D3D.Objects) do
        pcall(obj.Remove, obj)
    end
    D3D.Objects = {}
end

game:GetService("Players").LocalPlayer.CharacterAdded:Connect(Cleanup)

-- ==========================================
-- INITIALIZE
-- ==========================================

-- Auto-draw on load
Menu:Draw()
print("✅ ULTRA D3D KEYBOARD MENU v4.0 LOADED!")
print("📌 [INSERT] - Toggle Menu")
print("📌 [↑↓] - Navigate Items")
print("📌 [←→] - Switch Tabs")
print("📌 [ENTER] - Toggle/Select")
print("📌 [ESC] - Close Menu")

-- ==========================================
-- VISIBILITY TOGGLE
-- ==========================================

RunService.RenderStepped:Connect(function()
    if not Menu.Visible then
        for _, obj in pairs(D3D.Objects) do
            if obj.Visible == true then
                obj.Visible = false
            end
        end
    end
end)

-- Optional: Show menu automatically for testing
-- Menu:Toggle()