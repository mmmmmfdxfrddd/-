--==========================
--    自动瞄准脚本（修复版）- 只保留自瞄
--==========================
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local lp = Players.LocalPlayer

local enableAttack = false
local isScriptRunning = true
local enemyFolder = nil
local targetDummy = nil
local targetPos = nil
local selectedEnemyIndex = 1
local isPanelOpen = true

local targetDodgeValue = 0

local refreshCount = 0
local FileName = "DualFireConfig.json"
local SavedConfigs = {}

local function GetToolUniqueID(tool)
    local base = (tool.Name or "未知") .. "_" .. (tool.ToolTip or ""):gsub("^%s*(.-)%s*$", "%1")
    local addr = tostring(tool):match("0x%x+") or "noaddr"
    return base .. "_" .. addr:sub(-8)
end

local function GetDisplayName(tool)
    local name = tool.ToolTip ~= "" and tool.ToolTip or tool.Name
    name = name:gsub("^%s*[Cc][Dd][-:%s]*[0-9%.]*%s*", "")
    return name:match("^%s*(.-)%s*$") or name
end

local function IsToolOnCooldown(tool)
    local nameLower = (tool.Name or ""):lower()
    local isNameCooldown = nameLower:find("cooldown") or nameLower:find("cd") or nameLower:find("recharge") or nameLower:find("recharging") or nameLower:find("wait") or nameLower:find("sec") or nameLower:find("s left") or nameLower:find("seconds") or nameLower:find("disabled")
    local isDisabled = tool.Enabled == false
    local hasCooldownChild = tool:FindFirstChild("Cooldown") or tool:FindFirstChild("CooldownValue")
    return isNameCooldown or isDisabled or hasCooldownChild
end

local function HasRemoteEventRecursive(parent)
    if parent:FindFirstChildWhichIsA("RemoteEvent", true) then
        return true
    end
    return false
end

local function Save()
    pcall(function()
        writefile(FileName, HttpService:JSONEncode(SavedConfigs))
    end)
end

local function Load()
    pcall(function()
        if isfile(FileName) then
            local data = HttpService:JSONDecode(readfile(FileName))
            if type(data) == "table" then 
                SavedConfigs = data
            end
        end
    end)
end
Load()

local playerGui = lp:WaitForChild("PlayerGui")

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = playerGui

local main = Instance.new("Frame")
main.Size = UDim2.new(0,320,0,420)
main.Position = UDim2.new(0.02,0,0.5,-210)
main.BackgroundColor3 = Color3.new(0.12,0.12,0.12)
main.Active = true
main.Draggable = true
main.Parent = ScreenGui
local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0,8)
UICorner.Parent = main

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1,0,0,36)
title.BackgroundColor3 = Color3.new(0.18,0.18,0.18)
title.Text = "自动瞄准面板"
title.TextColor3 = Color3.new(1,1,1)
title.TextSize = 16
title.Parent = main
local titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = UDim.new(0,8)
titleCorner.Parent = title

local toggleArrow = Instance.new("TextButton")
toggleArrow.Size = UDim2.new(0,28,0,28)
toggleArrow.Position = UDim2.new(1,-70,0.5,-14)
toggleArrow.BackgroundTransparency = 1
toggleArrow.Text = "−"
toggleArrow.TextColor3 = Color3.new(1,1,1)
toggleArrow.TextSize = 16
toggleArrow.Parent = title

local close = Instance.new("TextButton")
close.Size = UDim2.new(0,28,0,28)
close.Position = UDim2.new(1,-33,0.5,-14)
close.BackgroundTransparency = 1
close.Text = "X"
close.TextColor3 = Color3.new(1,1,1)
close.TextSize = 16
close.Parent = title

local content = Instance.new("Frame")
content.Size = UDim2.new(1,0,1,-36)
content.Position = UDim2.new(0,0,0,36)
content.BackgroundTransparency = 1
content.Parent = main

local scroll = Instance.new("ScrollingFrame")
scroll.Size = UDim2.new(1,-16,0,280)
scroll.Position = UDim2.new(0.025,0,0.02,0)
scroll.BackgroundTransparency = 1
scroll.BorderSizePixel = 0
scroll.ScrollBarThickness = 4
scroll.CanvasSize = UDim2.new(0,0,0,0)
scroll.Parent = content

local btnClear = Instance.new("TextButton")
btnClear.Size = UDim2.new(0.45,0,0,36)
btnClear.Position = UDim2.new(0.53,0,0.88,0)
btnClear.BackgroundColor3 = Color3.new(0.22,0.22,0.22)
btnClear.Text = "清空配置"
btnClear.TextColor3 = Color3.new(1,1,1)
btnClear.Parent = content
local clearCorner = Instance.new("UICorner")
clearCorner.CornerRadius = UDim.new(0,6)
clearCorner.Parent = btnClear

local targetContainer = Instance.new("Frame")
targetContainer.Size = UDim2.new(0,150,0,140)
targetContainer.Position = UDim2.new(0.92,-150,0.4,-35-140-10)
targetContainer.BackgroundTransparency = 1
targetContainer.Parent = ScreenGui

local targetTitle = Instance.new("TextLabel")
targetTitle.Size = UDim2.new(1,0,0,20)
targetTitle.BackgroundTransparency = 1
targetTitle.Text = "当前目标"
targetTitle.TextColor3 = Color3.new(0.8,0.8,0.8)
targetTitle.TextSize = 14
targetTitle.Parent = targetContainer

local dodgeLabel = Instance.new("TextLabel")
dodgeLabel.Size = UDim2.new(1,0,0,20)
dodgeLabel.Position = UDim2.new(0,0,0,20)
dodgeLabel.BackgroundTransparency = 1
dodgeLabel.Text = "闪避:0"
dodgeLabel.TextColor3 = Color3.new(0.3,0.8,1)
dodgeLabel.TextSize = 16
dodgeLabel.Font = Enum.Font.SourceSansBold
dodgeLabel.ZIndex = 1
dodgeLabel.Parent = targetContainer

local hpBackground = Instance.new("Frame")
hpBackground.Name = "HPBackground"
hpBackground.Size = UDim2.new(1, 20, 0, 54)
hpBackground.Position = UDim2.new(0, -10, 0, 13)
hpBackground.BackgroundColor3 = Color3.new(0, 0, 0)
hpBackground.BackgroundTransparency = 0
hpBackground.BorderSizePixel = 0
hpBackground.ZIndex = 0
local hpCorner = Instance.new("UICorner")
hpCorner.CornerRadius = UDim.new(0, 10)
hpCorner.Parent = hpBackground
hpBackground.Parent = targetContainer

local hpLabel = Instance.new("TextLabel")
hpLabel.Size = UDim2.new(1,0,0,20)
hpLabel.Position = UDim2.new(0,0,0,40)
hpLabel.BackgroundTransparency = 1
hpLabel.Text = "0/0"
hpLabel.TextColor3 = Color3.new(1,0.3,0.3)
hpLabel.TextSize = 16
hpLabel.Font = Enum.Font.SourceSansBold
hpLabel.ZIndex = 1
hpLabel.Parent = targetContainer

local targetName = Instance.new("TextLabel")
targetName.Size = UDim2.new(1,0,0,30)
targetName.Position = UDim2.new(0,0,0,60)
targetName.BackgroundTransparency = 1
targetName.Text = "无目标"
targetName.TextColor3 = Color3.new(1,1,1)
targetName.TextSize = 18
targetName.Font = Enum.Font.SourceSansBold
targetName.Parent = targetContainer

local btnContainer = Instance.new("Frame")
btnContainer.Size = UDim2.new(1,0,0,30)
btnContainer.Position = UDim2.new(0,0,0,90)
btnContainer.BackgroundTransparency = 1
btnContainer.Parent = targetContainer

local btnPrev = Instance.new("TextButton")
btnPrev.Size = UDim2.new(0.45,0,1,0)
btnPrev.Position = UDim2.new(0,0,0,0)
btnPrev.BackgroundColor3 = Color3.new(0.2,0.2,0.2)
btnPrev.Text = "< 上一个"
btnPrev.TextColor3 = Color3.new(1,1,1)
btnPrev.TextSize = 12
btnPrev.Parent = btnContainer
local prevCorner = Instance.new("UICorner")
prevCorner.CornerRadius = UDim.new(0,6)
prevCorner.Parent = btnPrev

local btnNext = Instance.new("TextButton")
btnNext.Size = UDim2.new(0.45,0,1,0)
btnNext.Position = UDim2.new(0.55,0,0,0)
btnNext.BackgroundColor3 = Color3.new(0.2,0.2,0.2)
btnNext.Text = "下一个 >"
btnNext.TextColor3 = Color3.new(1,1,1)
btnNext.TextSize = 12
btnNext.Parent = btnContainer
local nextCorner = Instance.new("UICorner")
nextCorner.CornerRadius = UDim.new(0,6)
nextCorner.Parent = btnNext

local btnAttack = Instance.new("TextButton")
btnAttack.Size = UDim2.new(0,150,0,70)
btnAttack.Position = UDim2.new(0.92,-150,0.4,-35)
btnAttack.BackgroundColor3 = Color3.new(0.2,0.2,0.2)
btnAttack.Text = "攻击关闭"
btnAttack.TextSize = 22
btnAttack.TextColor3 = Color3.new(1,1,1)
btnAttack.Font = Enum.Font.SourceSansBold
btnAttack.Parent = ScreenGui
local attackCorner = Instance.new("UICorner")
attackCorner.CornerRadius = UDim.new(0,8)
attackCorner.Parent = btnAttack

local debounce = {}
local function Debounce(key, t)
    local now = tick()
    if debounce[key] and now - debounce[key] < t then return false end
    debounce[key] = now
    return true
end

local itemRows = {}
local activeTools = {}

local function RefreshPanel()
    refreshCount = refreshCount + 1
    if refreshCount % 5 == 0 then
        pcall(function()
            if not ScreenGui:IsDescendantOf(game) then
                ScreenGui.Parent = playerGui
            end
        end)
    end

    local bp = lp:FindFirstChild("Backpack")
    if not bp then return end

    for id, rowData in pairs(itemRows) do
        if rowData.frame and rowData.frame.Parent then
            rowData.frame.Visible = false
        end
    end

    local validTools = {}
    for _, tool in pairs(bp:GetChildren()) do
        if tool:IsA("Tool") and not IsToolOnCooldown(tool) and HasRemoteEventRecursive(tool) then
            local toolID = GetToolUniqueID(tool)
            local displayName = GetDisplayName(tool)
            table.insert(validTools, {tool = tool, id = toolID, name = displayName})
        end
    end

    table.sort(validTools, function(a, b)
        return a.name:lower() < b.name:lower()
    end)

    local currentIDs = {}
    for _, entry in ipairs(validTools) do
        currentIDs[entry.id] = true
    end

    for id, rowData in pairs(itemRows) do
        if not currentIDs[id] then
            if rowData.frame then rowData.frame:Destroy() end
            itemRows[id] = nil
        end
    end

    table.clear(activeTools)
    local y = 0

    for _, entry in ipairs(validTools) do
        local tool = entry.tool
        local id = entry.id
        local displayName = entry.name

        local cfg = SavedConfigs[id] or {mode = "vector", skip = false, dodgeLimit = true}
        SavedConfigs[id] = cfg

        table.insert(activeTools, tool)

        local rowData = itemRows[id]
        if rowData and rowData.frame and rowData.frame.Parent then
            rowData.frame.Position = UDim2.new(0, 0, 0, y)
            rowData.nameLabel.Text = displayName
            rowData.frame.Visible = true

            for _, child in ipairs(rowData.frame:GetChildren()) do
                if child:IsA("TextButton") then
                    if child.Text == "向量" then
                        child.BackgroundColor3 = (cfg.mode == "vector") and Color3.new(0,0.7,0.2) or Color3.new(0.22,0.22,0.22)
                    elseif child.Text == "XYZ坐标" then
                        child.BackgroundColor3 = (cfg.mode == "triple") and Color3.new(0,0.7,0.2) or Color3.new(0.22,0.22,0.22)
                    elseif child.Text == "跳过" or child.Text == "跳过开启" then
                        child.Text = cfg.skip and "跳过开启" or "跳过"
                        child.BackgroundColor3 = cfg.skip and Color3.new(0.7,0.2,0.2) or Color3.new(0.22,0.22,0.22)
                    elseif child.Text == "闪避开" or child.Text == "闪避关" then
                        child.Text = cfg.dodgeLimit and "闪避开" or "闪避关"
                        child.BackgroundColor3 = cfg.dodgeLimit and Color3.new(0.7,0.2,0.2) or Color3.new(0,0.7,0.2)
                    end
                end
            end
        else
            local row = Instance.new("Frame")
            row.Size = UDim2.new(1,0,0,36)
            row.Position = UDim2.new(0,0,0,y)
            row.BackgroundTransparency = 1
            row.Visible = true
            row.Parent = scroll

            local nameLbl = Instance.new("TextLabel")
            nameLbl.Name = "NameLabel"
            nameLbl.Size = UDim2.new(0.3,0,1,0)
            nameLbl.Position = UDim2.new(0,4,0,0)
            nameLbl.BackgroundTransparency = 1
            nameLbl.Text = displayName
            nameLbl.TextColor3 = Color3.new(1,1,1)
            nameLbl.TextSize = 14
            nameLbl.TextXAlignment = Enum.TextXAlignment.Left
            nameLbl.TextTruncate = Enum.TextTruncate.AtEnd
            nameLbl.Parent = row

            local dodgeBtn = Instance.new("TextButton")
            dodgeBtn.Size = UDim2.new(0.13,0,0.8,0)
            dodgeBtn.Position = UDim2.new(0.31,0,0.1,0)
            dodgeBtn.BackgroundColor3 = cfg.dodgeLimit and Color3.new(0.7,0.2,0.2) or Color3.new(0,0.7,0.2)
            dodgeBtn.Text = cfg.dodgeLimit and "闪避开" or "闪避关"
            dodgeBtn.TextColor3 = Color3.new(1,1,1)
            dodgeBtn.TextSize = 12
            dodgeBtn.Font = Enum.Font.SourceSansBold
            dodgeBtn.Parent = row
            Instance.new("UICorner").Parent = dodgeBtn

            local bVec = Instance.new("TextButton")
            bVec.Size = UDim2.new(0.15,0,0.8,0)
            bVec.Position = UDim2.new(0.45,0,0.1,0)
            bVec.BackgroundColor3 = cfg.mode == "vector" and Color3.new(0,0.7,0.2) or Color3.new(0.22,0.22,0.22)
            bVec.Text = "向量"
            bVec.TextColor3 = Color3.new(1,1,1)
            bVec.Parent = row
            Instance.new("UICorner").Parent = bVec

            local bXYZ = Instance.new("TextButton")
            bXYZ.Size = UDim2.new(0.15,0,0.8,0)
            bXYZ.Position = UDim2.new(0.61,0,0.1,0)
            bXYZ.BackgroundColor3 = cfg.mode == "triple" and Color3.new(0,0.7,0.2) or Color3.new(0.22,0.22,0.22)
            bXYZ.Text = "XYZ坐标"
            bXYZ.TextColor3 = Color3.new(1,1,1)
            bXYZ.Parent = row
            Instance.new("UICorner").Parent = bXYZ

            local bSkip = Instance.new("TextButton")
            bSkip.Size = UDim2.new(0.15,0,0.8,0)
            bSkip.Position = UDim2.new(0.77,0,0.1,0)
            bSkip.BackgroundColor3 = cfg.skip and Color3.new(0.7,0.2,0.2) or Color3.new(0.22,0.22,0.22)
            bSkip.Text = cfg.skip and "跳过开启" or "跳过"
            bSkip.TextColor3 = Color3.new(1,1,1)
            bSkip.Parent = row
            Instance.new("UICorner").Parent = bSkip

            dodgeBtn.MouseButton1Click:Connect(function()
                if not Debounce("d"..id, 0.1) then return end
                cfg.dodgeLimit = not cfg.dodgeLimit
                dodgeBtn.Text = cfg.dodgeLimit and "闪避开" or "闪避关"
                dodgeBtn.BackgroundColor3 = cfg.dodgeLimit and Color3.new(0.7,0.2,0.2) or Color3.new(0,0.7,0.2)
                Save()
            end)

            bVec.MouseButton1Click:Connect(function()
                if not Debounce("v"..id, 0.1) then return end
                cfg.mode = "vector"
                bVec.BackgroundColor3 = Color3.new(0,0.7,0.2)
                bXYZ.BackgroundColor3 = Color3.new(0.22,0.22,0.22)
                Save()
            end)

            bXYZ.MouseButton1Click:Connect(function()
                if not Debounce("x"..id, 0.1) then return end
                cfg.mode = "triple"
                bVec.BackgroundColor3 = Color3.new(0.22,0.22,0.22)
                bXYZ.BackgroundColor3 = Color3.new(0,0.7,0.2)
                Save()
            end)

            bSkip.MouseButton1Click:Connect(function()
                if not Debounce("s"..id, 0.1) then return end
                cfg.skip = not cfg.skip
                bSkip.Text = cfg.skip and "跳过开启" or "跳过"
                bSkip.BackgroundColor3 = cfg.skip and Color3.new(0.7,0.2,0.2) or Color3.new(0.22,0.22,0.22)
                Save()
            end)

            itemRows[id] = {frame = row, nameLabel = nameLbl}
        end

        y = y + 38
    end

    scroll.CanvasSize = UDim2.new(0,0,0,y)
end

task.spawn(function()
    while isScriptRunning do
        local char = lp.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health <= 0 then
                for _, r in pairs(itemRows) do
                    if r.frame then r.frame:Destroy() end
                end
                table.clear(itemRows)
                scroll.CanvasSize = UDim2.new(0,0,0,0)
            end
        end
        RefreshPanel()
        task.wait(0.5)
    end
end)

local function FireAll()
    if not enableAttack or not targetPos then return end
    
    local bp = lp.Backpack
    if not bp then return end

    for _, tool in pairs(bp:GetChildren()) do
        if not tool:IsA("Tool") then continue end
        if IsToolOnCooldown(tool) then continue end

        local cfg = SavedConfigs[GetToolUniqueID(tool)]
        if cfg and cfg.skip then continue end
        
        if cfg and cfg.dodgeLimit and targetDodgeValue > 0 then
            continue
        end

        local remotes = {}
        local function scan(obj)
            for _, child in ipairs(obj:GetChildren()) do
                if child:IsA("RemoteEvent") then
                    table.insert(remotes, child)
                end
                scan(child)
            end
        end
        scan(tool)

        for _, re in ipairs(remotes) do
            pcall(function()
                if cfg and cfg.mode == "vector" then
                    re:FireServer(targetPos)
                else
                    re:FireServer(targetPos.X, targetPos.Y, targetPos.Z)
                end
            end)
        end
    end
end

local function CollectEnemiesFirst(root)
    local list = {}
    for _, child in ipairs(root:GetChildren()) do
        if child:IsA("Model") then
            table.insert(list, child)
        end
    end
    return list
end

local function CollectSubTargetsRecursive(root)
    local list = {}
    local function scan(obj)
        for _, child in ipairs(obj:GetChildren()) do
            if child:IsA("Model") then
                local ok = false
                pcall(function()
                    for _, d in ip(child:GetDescendants()) do
                        if d:IsA("HumanoidRootPart") or d:IsA("Torso") or d:IsA("UpperTorso") then
                            ok = true
                            break
                        end
                    end
                end)
                if ok then
                    table.insert(list, child)
                end
                scan(child)
            end
        end
    end
    scan(root)
    return list
end

local function GetAllValidTargets()
    local enemyFolder = workspace:FindFirstChild("enemy")
    if not enemyFolder then return {} end

    local enemies = CollectEnemiesFirst(enemyFolder)
    if #enemies >= 2 then
        return enemies
    end

    if #enemies == 1 then
        local subs = CollectSubTargetsRecursive(enemies[1])
        if #subs > 0 then
            return subs
        else
            return enemies
        end
    end

    return {}
end

local function UpdateTarget()
    local normalList = GetAllValidTargets()
    local errorBoss = nil

    for _, obj in ipairs(normalList) do
        if obj.Name == "Error Sans" and obj:IsDescendantOf(workspace) then
            errorBoss = obj
            break
        end
    end

    if errorBoss then
        local petFolder = errorBoss:FindFirstChild("pet")
        if petFolder then
            local petList = {}
            for _, child in petFolder:GetChildren() do
                if child:IsA("Model") then
                    table.insert(petList, child)
                end
            end

            if #petList > 0 then
                finalList = petList
                selectedEnemyIndex = math.clamp(selectedEnemyIndex, 1, #finalList)
                targetDummy = finalList[selectedEnemyIndex]
                targetName.Text = targetDummy.Name
                return
            end
        end
    end

    local list = GetAllValidTargets()

    if #list == 0 then
        targetDummy = nil
        targetName.Text = "无目标"
        dodgeLabel.Text = "闪避:0"
        hpLabel.Text = "0/0"
        return
    end

    finalList = list

    selectedEnemyIndex = math.clamp(selectedEnemyIndex, 1, #finalList)
    if targetDummy ~= finalList[selectedEnemyIndex] then
        targetDummy = finalList[selectedEnemyIndex]
        targetName.Text = targetDummy.Name
    end
end

local function UpdateDodgeValue()
    targetDodgeValue = 0
    if not targetDummy then 
        dodgeLabel.Text = "闪避:0"
        return 
    end
    
    local function FindDodge(obj)
        if obj.Name == "dodge" then
            return obj
        end
        for _, c in ipairs(obj:GetChildren()) do
            local f = FindDodge(c)
            if f then return f end
        end
        return nil
    end
    
    local dodgeObj = FindDodge(targetDummy)
    if dodgeObj then
        if dodgeObj:IsA("NumberValue") then
            targetDodgeValue = dodgeObj.Value
        elseif dodgeObj:IsA("IntValue") then
            targetDodgeValue = dodgeObj.Value
        end
    end
    
    dodgeLabel.Text = "闪避:" .. tostring(targetDodgeValue)
    
    if targetDodgeValue > 0 then
        dodgeLabel.TextColor3 = Color3.new(1, 0.5, 0)
    else
        dodgeLabel.TextColor3 = Color3.new(0.3, 0.8, 1)
    end
end

local function UpdateHPDisplay()
    if not targetDummy then
        hpLabel.Text = "0/0"
        return
    end

    local function FindHumanoid(obj)
        if obj:IsA("Humanoid") then return obj end
        for _, c in ipairs(obj:GetChildren()) do
            local f = FindHumanoid(c)
            if f then return f end
        end
        return nil
    end

    local hum = FindHumanoid(targetDummy)
    if hum then
        hpLabel.Text = math.floor(hum.Health) .. "/" .. math.floor(hum.MaxHealth)
    else
        local function FindHealth(obj)
            if obj.Name == "Health" and obj:IsA("NumberValue") then return obj end
            for _, c in ipairs(obj:GetChildren()) do
                local f = FindHealth(c)
                if f then return f end
            end
        end
        local hp = FindHealth(targetDummy)
        if hp then
            hpLabel.Text = hp.Value .. "/" .. hp.Value
        else
            hpLabel.Text = "0/0"
        end
    end
end

local lastTar = nil
local lastTorso = nil
local torsoConnection = nil

local function UpdateTargetPos()
    if not enableAttack then
        targetPos = nil
        if torsoConnection then
            torsoConnection:Disconnect()
            torsoConnection = nil
        end
        return
    end
    
    if not targetDummy then
        targetPos = nil
        if torsoConnection then
            torsoConnection:Disconnect()
            torsoConnection = nil
        end
        return
    end

    local function FindTorso(obj)
        if obj.Name == "Torso" and obj:IsA("BasePart") then
            return obj
        end
        for _, c in ipairs(obj:GetChildren()) do
            local f = FindTorso(c)
            if f then return f end
        end
        return nil
    end

    local torso = FindTorso(targetDummy)
    
    if not torso then
        targetPos = targetDummy:GetPivot().Position
        return
    end

    if targetDummy ~= lastTar or torso ~= lastTorso or not torsoConnection then
        if torsoConnection then
            torsoConnection:Disconnect()
        end
        
        lastTar = targetDummy
        lastTorso = torso
        
        torsoConnection = torso:GetPropertyChangedSignal("Position"):Connect(function()
            if targetDummy and targetDummy:IsDescendantOf(workspace) and torso and torso.Parent then
                targetPos = torso.Position
            end
        end)
    end

    if torso and torso.Parent then
        targetPos = torso.Position
    end
end

close.MouseButton1Click:Connect(function()
    isScriptRunning = false
    ScreenGui:Destroy()
end)

toggleArrow.MouseButton1Click:Connect(function()
    isPanelOpen = not isPanelOpen
    content.Visible = isPanelOpen
    toggleArrow.Text = isPanelOpen and "−" or "+"
    main.Size = isPanelOpen and UDim2.new(0,320,0,420) or UDim2.new(0,320,0,36)
end)

btnAttack.MouseButton1Click:Connect(function()
    enableAttack = not enableAttack
    btnAttack.Text = enableAttack and "攻击开启" or "攻击关闭"
    btnAttack.BackgroundColor3 = enableAttack and Color3.new(0,0.7,0.2) or Color3.new(0.22,0.22,0.22)
end)

btnClear.MouseButton1Click:Connect(function()
    table.clear(SavedConfigs)
    Save()
    RefreshPanel()
end)

btnPrev.MouseButton1Click:Connect(function()
    selectedEnemyIndex = selectedEnemyIndex - 1
    UpdateTarget()
end)

btnNext.MouseButton1Click:Connect(function()
    selectedEnemyIndex = selectedEnemyIndex + 1
    UpdateTarget()
end)

task.spawn(function()
    while isScriptRunning do
        UpdateTarget()
        UpdateDodgeValue()
        UpdateHPDisplay()
        UpdateTargetPos()
        FireAll()
        task.wait(0.14)
    end
end)

print("✅ 加载完成：自动瞄准面板（修复版）- 已启动")
