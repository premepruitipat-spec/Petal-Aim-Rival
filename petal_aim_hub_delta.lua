-- PETAL AIM HUB | Delta-friendly local practice UI
-- Legitimate practice companion only.
-- Does NOT modify RIVALS, aim at players, unlock items, or call remote events.
-- Crosshair is a GUI preview; trainer and unlock tracker are local-only.

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local old = playerGui:FindFirstChild("PetalAimHub")
if old then old:Destroy() end

local gui = Instance.new("ScreenGui")
gui.Name = "PetalAimHub"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = false
gui.DisplayOrder = 999
gui.Parent = playerGui

local COLORS = {
    bg = Color3.fromRGB(20, 12, 29),
    panel = Color3.fromRGB(34, 22, 46),
    panel2 = Color3.fromRGB(48, 31, 63),
    pink = Color3.fromRGB(255, 139, 194),
    pale = Color3.fromRGB(255, 190, 220),
    text = Color3.fromRGB(255, 245, 251),
    muted = Color3.fromRGB(192, 170, 204),
    mint = Color3.fromRGB(169, 245, 219),
    line = Color3.fromRGB(88, 58, 103),
}
local currentColor = COLORS.pink
local crossSize, crossThickness, crossGap = 28, 3, 5
local crossStyle = "Plus"
local hitCount, shots, timeLeft = 0, 0, 30
local trainerRunning = false
local targetSize = 52
local unlocks = {}
local currentTab = "Crosshair"

local function corner(parent, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or 12)
    c.Parent = parent
    return c
end
local function stroke(parent, color, thickness)
    local s = Instance.new("UIStroke")
    s.Color = color or COLORS.line
    s.Thickness = thickness or 1
    s.Parent = parent
    return s
end
local function label(parent, text, size, color, font)
    local l = Instance.new("TextLabel")
    l.BackgroundTransparency = 1
    l.Text = text
    l.TextSize = size or 14
    l.TextColor3 = color or COLORS.text
    l.Font = font or Enum.Font.Gotham
    l.TextWrapped = true
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.Size = UDim2.new(1, 0, 0, (size or 14) + 12)
    l.Parent = parent
    return l
end
local function button(parent, text, callback, width)
    local b = Instance.new("TextButton")
    b.AutoButtonColor = true
    b.Text = text
    b.TextSize = 13
    b.Font = Enum.Font.GothamBold
    b.TextColor3 = COLORS.text
    b.BackgroundColor3 = COLORS.panel2
    b.Size = UDim2.new(1, 0, 0, 38)
    if width then b.Size = UDim2.new(0, width, 0, 38) end
    b.Parent = parent
    corner(b, 10)
    stroke(b)
    b.Activated:Connect(callback)
    return b
end
local function makeFrame(parent, name, size, position, color)
    local f = Instance.new("Frame")
    f.Name = name
    f.Size = size
    f.Position = position
    f.BackgroundColor3 = color or COLORS.panel
    f.BorderSizePixel = 0
    f.Parent = parent
    corner(f, 14)
    return f
end

local main = makeFrame(gui, "Main", UDim2.new(0, 350, 0, 480), UDim2.new(0.5, -175, 0.5, -240), COLORS.bg)
main.ClipsDescendants = true
stroke(main, COLORS.line, 1.5)
local scale = Instance.new("UIScale")
scale.Scale = 1
scale.Parent = main

local header = makeFrame(main, "Header", UDim2.new(1, 0, 0, 56), UDim2.new(), COLORS.panel)
local title = label(header, "✿  PETAL AIM HUB", 18, COLORS.pink, Enum.Font.GothamBold)
title.Position = UDim2.new(0, 14, 0, 7)
title.Size = UDim2.new(1, -55, 0, 24)
local subtitle = label(header, "iPad practice companion", 10, COLORS.muted)
subtitle.Position = UDim2.new(0, 15, 0, 31)
subtitle.Size = UDim2.new(1, -55, 0, 15)
local close = button(header, "×", function() gui:Destroy() end, 34)
close.Position = UDim2.new(1, -43, 0, 10)
close.BackgroundColor3 = Color3.fromRGB(85, 39, 67)

-- Dragging header works with touch and mouse.
local dragging, dragStart, startPos
header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = main.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then dragging = false end
        end)
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

local tabs = makeFrame(main, "Tabs", UDim2.new(1, -16, 0, 40), UDim2.new(0, 8, 0, 64), COLORS.bg)
tabs.BackgroundTransparency = 1
local tabNames = {"Crosshair", "Trainer", "Settings", "Unlocks"}
local pages = {}
local tabButtons = {}
for i, name in ipairs(tabNames) do
    local b = button(tabs, name, function() end)
    b.Size = UDim2.new(0.25, -5, 1, 0)
    b.Position = UDim2.new((i-1)*0.25, (i-1)*5, 0, 0)
    b.TextSize = 10
    tabButtons[name] = b
    local page = Instance.new("ScrollingFrame")
    page.Name = name .. "Page"
    page.Size = UDim2.new(1, -16, 1, -116)
    page.Position = UDim2.new(0, 8, 0, 112)
    page.BackgroundTransparency = 1
    page.BorderSizePixel = 0
    page.ScrollBarThickness = 4
    page.ScrollBarImageColor3 = COLORS.pink
    page.CanvasSize = UDim2.new(0,0,0,0)
    page.AutomaticCanvasSize = Enum.AutomaticSize.Y
    page.Visible = false
    page.Parent = main
    local list = Instance.new("UIListLayout")
    list.Padding = UDim.new(0, 8)
    list.SortOrder = Enum.SortOrder.LayoutOrder
    list.Parent = page
    pages[name] = page
end
local function showTab(name)
    currentTab = name
    for n, page in pairs(pages) do
        page.Visible = n == name
        tabButtons[n].BackgroundColor3 = n == name and COLORS.pink or COLORS.panel2
        tabButtons[n].TextColor3 = n == name and COLORS.bg or COLORS.text
    end
end
for name, b in pairs(tabButtons) do
    b.Activated:Connect(function() showTab(name) end)
end

local function card(parent, height)
    local f = makeFrame(parent, "Card", UDim2.new(1, -2, 0, height or 90), UDim2.new(), COLORS.panel)
    f.AutomaticSize = Enum.AutomaticSize.Y
    f.Size = UDim2.new(1, -2, 0, height or 90)
    local pad = Instance.new("UIPadding")
    pad.PaddingTop = UDim.new(0, 10)
    pad.PaddingBottom = UDim.new(0, 10)
    pad.PaddingLeft = UDim.new(0, 10)
    pad.PaddingRight = UDim.new(0, 10)
    pad.Parent = f
    local list = Instance.new("UIListLayout")
    list.Padding = UDim.new(0, 6)
    list.SortOrder = Enum.SortOrder.LayoutOrder
    list.Parent = f
    return f
end
local function sectionTitle(parent, text)
    local l = label(parent, text, 15, COLORS.pink, Enum.Font.GothamBold)
    l.Size = UDim2.new(1, 0, 0, 22)
    return l
end
local function smallText(parent, text)
    local l = label(parent, text, 11, COLORS.muted)
    l.Size = UDim2.new(1, 0, 0, 30)
    return l
end
local function makeCrosshair(parent, size, color, thickness, gap, style)
    local holder = Instance.new("Frame")
    holder.Name = "CrosshairPreview"
    holder.Size = UDim2.new(0, size, 0, size)
    holder.BackgroundTransparency = 1
    holder.Parent = parent
    local function part(name, x, y, w, h)
        local p = Instance.new("Frame")
        p.Name = name
        p.BorderSizePixel = 0
        p.BackgroundColor3 = color
        p.Position = UDim2.new(0.5, x, 0.5, y)
        p.Size = UDim2.new(0, w, 0, h)
        p.Parent = holder
        corner(p, 2)
    end
    if style == "Dot" then
        part("Dot", -thickness/2, -thickness/2, thickness, thickness)
    else
        local length = math.max(2, (size - gap*2)/2)
        part("Top", -thickness/2, -gap-length, thickness, length)
        part("Bottom", -thickness/2, gap, thickness, length)
        part("Left", -gap-length, -thickness/2, length, thickness)
        part("Right", gap, -thickness/2, length, thickness)
    end
    return holder
end

-- Crosshair page
local crossCard = card(pages.Crosshair, 260)
sectionTitle(crossCard, "Crosshair Studio")
smallText(crossCard, "Preview only — not overlaid into RIVALS.")
local previewBox = makeFrame(crossCard, "PreviewBox", UDim2.new(1, 0, 0, 105), UDim2.new(), Color3.fromRGB(18, 11, 25))
previewBox.ClipsDescendants = true
local crossPreview
local function redrawPreview()
    if crossPreview then crossPreview:Destroy() end
    crossPreview = makeCrosshair(previewBox, crossSize, currentColor, crossThickness, crossGap, crossStyle)
    crossPreview.AnchorPoint = Vector2.new(0.5,0.5)
    crossPreview.Position = UDim2.new(0.5,0,0.5,0)
end
local function makeStepper(parent, name, minV, maxV, initial, onChange)
    local row = Instance.new("Frame")
    row.BackgroundTransparency = 1
    row.Size = UDim2.new(1,0,0,36)
    row.Parent = parent
    local txt = label(row, name .. ": " .. initial, 12, COLORS.text, Enum.Font.GothamMedium)
    txt.Size = UDim2.new(0.48,0,1,0)
    local minus = button(row, "−", function() end, 34)
    minus.Position = UDim2.new(0.54,0,0,0)
    local plus = button(row, "+", function() end, 34)
    plus.Position = UDim2.new(1,-34,0,0)
    local value = initial
    local function set(v)
        value = math.clamp(v,minV,maxV)
        txt.Text = name .. ": " .. value
        onChange(value)
    end
    minus.Activated:Connect(function() set(value-1) end)
    plus.Activated:Connect(function() set(value+1) end)
end
redrawPreview()
makeStepper(crossCard, "Size", 12, 48, crossSize, function(v) crossSize=v; redrawPreview() end)
makeStepper(crossCard, "Thickness", 1, 6, crossThickness, function(v) crossThickness=v; redrawPreview() end)
makeStepper(crossCard, "Gap", 0, 12, crossGap, function(v) crossGap=v; redrawPreview() end)
local styleRow = Instance.new("Frame"); styleRow.BackgroundTransparency=1; styleRow.Size=UDim2.new(1,0,0,38); styleRow.Parent=crossCard
local styleBtn = button(styleRow, "Style: Plus", function()
    crossStyle = crossStyle == "Plus" and "Dot" or "Plus"
    styleBtn.Text = "Style: " .. crossStyle
    redrawPreview()
end)
styleBtn.Size=UDim2.new(1,0,1,0)
local colorRow = Instance.new("Frame"); colorRow.BackgroundTransparency=1; colorRow.Size=UDim2.new(1,0,0,38); colorRow.Parent=crossCard
local colorOptions = {COLORS.pink, COLORS.mint, Color3.new(1,1,1), Color3.fromRGB(255,230,109), Color3.fromRGB(169,165,255)}
for i,c in ipairs(colorOptions) do
    local b = Instance.new("TextButton"); b.Text=""; b.Size=UDim2.new(0,34,0,34); b.Position=UDim2.new(0,(i-1)*43,0,2); b.BackgroundColor3=c; b.Parent=colorRow; corner(b,17); stroke(b,Color3.fromRGB(255,255,255),1)
    b.Activated:Connect(function() currentColor=c; redrawPreview() end)
end
local presetName = Instance.new("TextBox"); presetName.PlaceholderText="Preset name"; presetName.Text="Petal Pink"; presetName.ClearTextOnFocus=false; presetName.Size=UDim2.new(1,0,0,36); presetName.BackgroundColor3=COLORS.bg; presetName.TextColor3=COLORS.text; presetName.Parent=crossCard; corner(presetName,8); stroke(presetName)
local savedPresets = {}
local presetLabel = smallText(crossCard, "No preset saved yet.")
button(crossCard, "Save current preset", function()
    savedPresets[presetName.Text ~= "" and presetName.Text or "Petal Preset"] = {size=crossSize,thickness=crossThickness,gap=crossGap,style=crossStyle,color=currentColor}
    presetLabel.Text = "Saved locally for this session: " .. (presetName.Text ~= "" and presetName.Text or "Petal Preset")
end)

-- Trainer page
local trainerCard = card(pages.Trainer, 330)
sectionTitle(trainerCard, "Touch Aim Trainer")
smallText(trainerCard, "Tap targets in this standalone mini-game. No interaction with other players.")
local statsLabel = label(trainerCard, "Hits: 0   Time: 30s   Accuracy: —", 13, COLORS.mint, Enum.Font.GothamBold)
statsLabel.Size=UDim2.new(1,0,0,25)
local arena = makeFrame(trainerCard, "PracticeArena", UDim2.new(1,0,0,205), UDim2.new(), Color3.fromRGB(17,10,24))
arena.ClipsDescendants=true
local hint = label(arena, "Tap Start to practice!", 13, COLORS.muted, Enum.Font.GothamMedium)
hint.Size=UDim2.new(1,-20,0,40); hint.Position=UDim2.new(0,10,0.5,-20); hint.TextXAlignment=Enum.TextXAlignment.Center
local startBtn
local function updateStats()
    local acc = shots > 0 and math.floor(hitCount/shots*100) or nil
    statsLabel.Text = "Hits: "..hitCount.."   Time: "..timeLeft.."s   Accuracy: "..(acc and (acc.."%") or "—")
end
local function spawnTarget()
    for _,v in ipairs(arena:GetChildren()) do if v.Name=="Target" then v:Destroy() end end
    local t=Instance.new("TextButton"); t.Name="Target"; t.Text=""; t.Size=UDim2.new(0,targetSize,0,targetSize); t.Position=UDim2.new(0,math.random(0,math.max(0,arena.AbsoluteSize.X-targetSize)),0,math.random(0,math.max(0,arena.AbsoluteSize.Y-targetSize))); t.BackgroundColor3=COLORS.pink; t.BackgroundTransparency=0.15; t.Parent=arena; corner(t,targetSize/2); stroke(t,COLORS.pale,2)
    t.Activated:Connect(function()
        if not trainerRunning then return end
        hitCount=hitCount+1; shots=shots+1; updateStats(); spawnTarget()
    end)
end
local function finishTrainer()
    trainerRunning=false
    for _,v in ipairs(arena:GetChildren()) do if v.Name=="Target" then v:Destroy() end end
    hint.Visible=true; hint.Text="Round complete! Hits: "..hitCount
    if startBtn then startBtn.Text="Play again" end
end
startBtn=button(trainerCard,"Start 30-second round",function()
    if trainerRunning then trainerRunning=false end
    hitCount=0;shots=0;timeLeft=30;trainerRunning=true;hint.Visible=false;updateStats();spawnTarget();startBtn.Text="Restart round"
    task.spawn(function()
        while trainerRunning and timeLeft>0 do task.wait(1); if trainerRunning then timeLeft=timeLeft-1;updateStats() end end
        if trainerRunning then finishTrainer() end
    end)
end)
local targetRow=Instance.new("Frame");targetRow.BackgroundTransparency=1;targetRow.Size=UDim2.new(1,0,0,38);targetRow.Parent=trainerCard
local easy=button(targetRow,"Easy targets",function() targetSize=60;if trainerRunning then spawnTarget() end end);easy.Size=UDim2.new(0.49,0,1,0)
local small=button(targetRow,"Small targets",function() targetSize=32;if trainerRunning then spawnTarget() end end);small.Size=UDim2.new(0.49,0,1,0);small.Position=UDim2.new(0.51,0,0,0)

-- Settings page
local settingsCard=card(pages.Settings,240)
sectionTitle(settingsCard,"iPad practice notes")
smallText(settingsCard,"These notes are not linked to RIVALS settings.")
local sensValue=5
makeStepper(settingsCard,"Practice sensitivity (1–10)",1,10,sensValue,function(v) sensValue=v end)
local styleChoices={"Balanced","Fast flicks","Steady tracking","Close-range"}
local styleIndex=1
button(settingsCard,"Play style: Balanced (tap to change)",function()
    styleIndex=styleIndex%#styleChoices+1
    -- update the most recent button label via stored reference below
end)
local tips={"Use a comfortable thumb position","Practice tracking before fast flicks","Change one setting at a time","Test a setting for several matches"}
for _,tip in ipairs(tips) do smallText(settingsCard,"• "..tip) end
local settingsStatus=smallText(settingsCard,"Practice notes are session-only in this script.")
-- Unlock page
local unlockCard=card(pages.Unlocks,260)
sectionTitle(unlockCard,"Legitimate unlock tracker")
smallText(unlockCard,"Personal checklist only. Does not grant weapons or skins.")
local unlockInput=Instance.new("TextBox");unlockInput.PlaceholderText="Weapon, skin, or goal name";unlockInput.Text="";unlockInput.ClearTextOnFocus=false;unlockInput.Size=UDim2.new(1,0,0,36);unlockInput.BackgroundColor3=COLORS.bg;unlockInput.TextColor3=COLORS.text;unlockInput.Parent=unlockCard;corner(unlockInput,8);stroke(unlockInput)
local unlockMethod="Earn through gameplay"
local methodBtn=button(unlockCard,"Method: Earn through gameplay",function()
    local methods={"Earn through gameplay","Complete a contract","Official shop / event"}
    local idx=table.find(methods,unlockMethod) or 1
    unlockMethod=methods[idx%#methods+1]
    methodBtn.Text="Method: "..unlockMethod
end)
local unlockList=Instance.new("Frame");unlockList.BackgroundTransparency=1;unlockList.Size=UDim2.new(1,0,0,10);unlockList.AutomaticSize=Enum.AutomaticSize.Y;unlockList.Parent=unlockCard
local unlockLayout=Instance.new("UIListLayout");unlockLayout.Padding=UDim.new(0,5);unlockLayout.Parent=unlockList
local function renderUnlocks()
    for _,v in ipairs(unlockList:GetChildren()) do if v:IsA("GuiObject") then v:Destroy() end end
    for i,item in ipairs(unlocks) do
        local row=Instance.new("Frame");row.Size=UDim2.new(1,0,0,34);row.BackgroundColor3=COLORS.bg;row.Parent=unlockList;corner(row,8)
        local cb=Instance.new("TextButton");cb.Size=UDim2.new(0,32,1,0);cb.Text=item.done and "✓" or "○";cb.TextColor3=COLORS.mint;cb.BackgroundTransparency=1;cb.Parent=row
        local txt=label(row,item.name.." · "..(item.done and "Done" or "In progress"),10,COLORS.text);txt.Position=UDim2.new(0,34,0,0);txt.Size=UDim2.new(1,-70,1,0)
        local del=Instance.new("TextButton");del.Text="×";del.Size=UDim2.new(0,30,1,0);del.Position=UDim2.new(1,-30,0,0);del.BackgroundTransparency=1;del.TextColor3=COLORS.pink;del.Parent=row
        cb.Activated:Connect(function() item.done=not item.done;renderUnlocks() end)
        del.Activated:Connect(function() table.remove(unlocks,i);renderUnlocks() end)
    end
end
button(unlockCard,"＋ Add unlock goal",function()
    local name=unlockInput.Text
    if name and name:gsub("%s","")~="" then
        table.insert(unlocks,{name=name,method=unlockMethod,done=false})
        unlockInput.Text=""
        renderUnlocks()
    else
        unlockInput.PlaceholderText="Type a goal name first!"
    end
end)
renderUnlocks()

-- Fit the UI to smaller screens / iPad portrait.
local function resize()
    local camera=workspace.CurrentCamera
    if not camera then return end
    local vp=camera.ViewportSize
    local w=math.min(350, math.max(285, vp.X-24))
    local h=math.min(480, math.max(360, vp.Y-50))
    main.Size=UDim2.new(0,w,0,h)
    main.Position=UDim2.new(0.5,-w/2,0.5,-h/2)
end
resize()
if workspace.CurrentCamera then
    workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(resize)
end
showTab("Crosshair")
print("Petal Aim Hub loaded: local practice UI only.")
