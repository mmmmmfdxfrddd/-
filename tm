local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer

local CoreGui = game:GetService("StarterGui")
CoreGui:SetCore("SendNotification", {
    Title = "作者:某沙雕鸭子（贝利亚升级）",
    Text = "正在加载（反挂机已开启）",
    Duration = 5,
})
print("反挂机开启")
local vu = game:GetService("VirtualUser")
game:GetService("Players").LocalPlayer.Idled:connect(function()
    vu:Button2Down(Vector2.new(0,0),workspace.CurrentCamera.CFrame)
    wait(1)
    vu:Button2Up(Vector2.new(0,0),workspace.CurrentCamera.CFrame)
end)

local autoFarmEnabled = false
local grabEnabled = false
local moveToChestEnabled = false
local moveSpeed = 50
local isFloating = false
local deleteLoopConnection = nil
local deleteInterval = 2
local deleteEnabled = false

local CHEST_KEYWORDS = {
    "Chest", "chest", "宝箱", "宝盒", "Treasure", "treasure",
    "箱子", "Box", "box", "Reward", "reward"
}
local FORBIDDEN_CENTER = Vector3.new(-4443, 109, -4431)
local FORBIDDEN_RADIUS = 150

local targetDeleteNames = {"Chest_Spawn", "DarkChest_Spawn", "LightChest_Spawn"}

local deleteList = {
    "Oil Cup", "Blood Cup", "Light Cup", "Radioactive Cup", "Unknown Soul", "Acid Cup",
    "Symbiote", "Dream Essence", "Sus Knife", "Blue Bucket", "Bloody Knife", "Faith Cup", "Unknown Phone"
}

local DEFAULT_NEG_AMOUNT = -999999
local GIFT_REMOTE_NAME = "SanstaGift"
local CURRENCY_NAME = "TrollCoins"
local SanstaGift = nil
local TrollCoins = nil
local oldCoinValue = 0

local function isInForbiddenArea(position)
    local distance = (position - FORBIDDEN_CENTER).Magnitude
    return distance <= FORBIDDEN_RADIUS
end

local function isChest(object)
    if not object then return false end
    local objectName = object.Name:lower()
    for _, keyword in ipairs(CHEST_KEYWORDS) do
        if objectName:find(keyword:lower(), 1, true) then
            return true
        end
    end
    if object.Parent then
        local parentName = object.Parent.Name:lower()
        for _, keyword in ipairs(CHEST_KEYWORDS) do
            if parentName:find(keyword:lower(), 1, true) then
                return true
            end
        end
    end
    return false
end

local function deleteTargetChests()
    local deleteCount = 0
    for _, instance in ipairs(Workspace:GetDescendants()) do
        if table.find(targetDeleteNames, instance.Name) then
            instance:Destroy()
            deleteCount += 1
        end
    end
    if deleteCount > 0 then
        print("循环删除：共删除 " .. deleteCount .. " 个目标宝箱")
    end
end

local function toggleDeleteLoop(enabled)
    if deleteLoopConnection then
        deleteLoopConnection:Disconnect()
        deleteLoopConnection = nil
    end
    if enabled then
        local lastDeleteTime = os.clock()
        deleteLoopConnection = RunService.Heartbeat:Connect(function()
            if os.clock() - lastDeleteTime >= deleteInterval then
                deleteTargetChests()
                lastDeleteTime = os.clock()
            end
        end)
        print("循环删除已启动，每" .. deleteInterval .. "秒执行一次")
    else
        print("循环删除已停止")
    end
end

local chestFolder = workspace:WaitForChild("ChestFolderThing", 5) or workspace
local proximityPrompts = {}

local function collectChestPrompts()
    proximityPrompts = {}
    for _, descendant in ipairs(chestFolder:GetDescendants()) do
        if descendant:IsA("ProximityPrompt") and isChest(descendant.Parent) then
            local chestPosition = descendant.Parent:GetPivot().Position
            if not isInForbiddenArea(chestPosition) then
                table.insert(proximityPrompts, descendant)
            end
        end
    end
    for _, descendant in ipairs(workspace:GetDescendants()) do
        if descendant:IsA("ProximityPrompt") and isChest(descendant.Parent) then
            local chestPosition = descendant.Parent:GetPivot().Position
            if not isInForbiddenArea(chestPosition) then
                local exists = false
                for _, p in ipairs(proximityPrompts) do
                    if p == descendant then exists = true break end
                end
                if not exists then table.insert(proximityPrompts, descendant) end
            end
        end
    end
    print("收集到 " .. #proximityPrompts .. " 个有效宝箱")
end

collectChestPrompts()

chestFolder.DescendantAdded:Connect(function(descendant)
    if descendant:IsA("ProximityPrompt") and isChest(descendant.Parent) then
        local chestPosition = descendant.Parent:GetPivot().Position
        if not isInForbiddenArea(chestPosition) then
            table.insert(proximityPrompts, descendant)
        end
    end
end)

chestFolder.DescendantRemoving:Connect(function(descendant)
    if descendant:IsA("ProximityPrompt") then
        for i, prompt in ipairs(proximityPrompts) do
            if prompt == descendant then
                table.remove(proximityPrompts, i)
                break
            end
        end
    end
end)

local function triggerNearbyPrompts()
    local range = 7
    local character = player.Character
    if not character then return end

    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then return end

    local currentPosition = humanoidRootPart.Position

    if isInForbiddenArea(currentPosition) then
        return
    end

    for _, prompt in ipairs(proximityPrompts) do
        if prompt and prompt.Parent and prompt.Enabled then
            local chestPosition = prompt.Parent:GetPivot().Position
            local distance = (chestPosition - currentPosition).Magnitude

            if distance <= range and not isInForbiddenArea(chestPosition) then
                local initialPosition = humanoidRootPart.Position

                if fireproximityprompt then
                    fireproximityprompt(prompt)
                else
                    warn("are you sure you are using executor?")
                end

                wait(0.1)
                local newPosition = humanoidRootPart.Position
                local positionChange = (newPosition - initialPosition).Magnitude

                if positionChange > 50 then
                    humanoidRootPart.CFrame = CFrame.new(initialPosition)
                end

                return true
            end
        end
    end
    return false
end

local function findNearestChest()
    local character = player.Character
    if not character then return nil end

    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then return nil end

    local currentPosition = humanoidRootPart.Position
    local nearestChest = nil
    local minDistance = math.huge

    for _, prompt in ipairs(proximityPrompts) do
        if prompt and prompt.Parent and prompt.Enabled then
            local chestPosition = prompt.Parent:GetPivot().Position
            local distance = (chestPosition - currentPosition).Magnitude

            if not isInForbiddenArea(chestPosition) and distance < minDistance then
                minDistance = distance
                nearestChest = prompt
            end
        end
    end

    return nearestChest
end

local collectConnection
local function startAutoCollect()
    if collectConnection then
        collectConnection:Disconnect()
        collectConnection = nil
    end

    collectConnection = RunService.Heartbeat:Connect(function()
        if autoFarmEnabled then
            triggerNearbyPrompts()
        end
    end)
end

local moveConnection
local function startAutoMove()
    if moveConnection then
        moveConnection:Disconnect()
        moveConnection = nil
    end

    moveConnection = RunService.Heartbeat:Connect(function(deltaTime)
        if moveToChestEnabled then
            local character = player.Character
            if not character then return end

            local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
            if not humanoidRootPart then return end

            local nearestChest = findNearestChest()
            if nearestChest then
                local chestPosition = nearestChest.Parent:GetPivot().Position
                local currentPosition = humanoidRootPart.Position

                if isInForbiddenArea(currentPosition) then
                    return
                end

                local direction = (chestPosition - currentPosition).Unit
                local movement = direction * moveSpeed * deltaTime

                local newPosition = currentPosition + movement
                if not isInForbiddenArea(newPosition) then
                    humanoidRootPart.CFrame = humanoidRootPart.CFrame + movement
                end
            end
        end
    end)
end

local function clearOriginalScripts()
    local sanstaGiftGui = player.PlayerGui:FindFirstChild("SanstaGiftGui")
    if not sanstaGiftGui then return end

    local deleted = 0
    for _, child in ipairs(sanstaGiftGui:GetDescendants()) do
        if child:IsA("LocalScript") then
            child:Destroy()
            deleted += 1
        end
    end

    for _, btn in ipairs(sanstaGiftGui:GetDescendants()) do
        if btn:IsA("TextButton") then
            for _, conn in ipairs(getconnections(btn.MouseButton1Click)) do
                conn:Disconnect()
            end
        end
    end
    print("✅ 清理 " .. deleted .. " 个原版干扰脚本")
end

local function getValidRemoteEvent()
    local giftRemote = ReplicatedStorage:FindFirstChild(GIFT_REMOTE_NAME)
    if not giftRemote or not giftRemote:IsA("RemoteEvent") then
        warn("❌ 未找到 SanstaGift 事件")
        return nil
    end

    local success = pcall(function()
        giftRemote:FireServer(0)
    end)
    if success then
        print("✅ 找到合法服务器事件")
        return giftRemote
    else
        warn("❌ 事件被服务器拦截")
        return nil
    end
end

local function sendMoneyRequest(inputAmount)
    if not SanstaGift or not TrollCoins then return end
    local currentNegAmount = tonumber(inputAmount) or DEFAULT_NEG_AMOUNT
    if currentNegAmount >= 0 then currentNegAmount = -math.abs(currentNegAmount) end
    local absAmount = math.abs(currentNegAmount)

    local success, err = pcall(function()
        TrollCoins.Value = oldCoinValue + absAmount + 1000
        task.wait(0.05)

        SanstaGift:FireServer(currentNegAmount)
        task.wait(0.2)

        local newValue = TrollCoins.Value
        local realAdd = newValue - oldCoinValue
        if realAdd > 0 then
            print("🎉 加钱成功！+" .. realAdd)
            oldCoinValue = newValue
        else
            TrollCoins.Value = oldCoinValue + absAmount
            print("⚠️ 服务器转正，强制加钱 +" .. absAmount)
            oldCoinValue = oldCoinValue + absAmount
        end
    end)

    if not success then
        warn("❌ 刷钱失败：" .. err)
        TrollCoins.Value = oldCoinValue
    end
end

local function initMoneyHack()
    clearOriginalScripts()
    SanstaGift = getValidRemoteEvent()
    if not SanstaGift then return end

    local leaderstats = player:WaitForChild("leaderstats", 5)
    if not leaderstats then
        warn("❌ 未找到 leaderstats")
        return
    end

    TrollCoins = leaderstats:WaitForChild(CURRENCY_NAME, 5)
    if not TrollCoins then
        warn("❌ 未找到 " .. CURRENCY_NAME)
        return
    end
    oldCoinValue = TrollCoins.Value
    print("✅ 刷钱功能初始化完成")
end

local _G = getfenv()
_G.OpenAllChests = false
_G.DeleteProps = false

local gui = Instance.new("ScreenGui", player:WaitForChild("PlayerGui"))
gui.Name = "AutoFarmGUI"
gui.ResetOnSpawn = false

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 200, 0, 350)
frame.Position = UDim2.new(0, 10, 0, 10)
frame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
frame.BorderSizePixel = 0
frame.Active = true
frame.Draggable = true
frame.Parent = gui
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 6)

local toggleButton = Instance.new("TextButton", frame)
toggleButton.Text = "−"
toggleButton.Size = UDim2.new(0, 20, 0, 20)
toggleButton.Position = UDim2.new(0, 5, 0, 5)
toggleButton.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
toggleButton.TextColor3 = Color3.new(1, 1, 1)
toggleButton.Font = Enum.Font.GothamBold
toggleButton.TextSize = 14
Instance.new("UICorner", toggleButton).CornerRadius = UDim.new(0, 6)

-- 左下角X删除按钮
local destroyBtn = Instance.new("TextButton")
destroyBtn.Text = "X"
destroyBtn.Size = UDim2.new(0, 25, 0, 25)
destroyBtn.Position = UDim2.new(0, 5, 1, -30)
destroyBtn.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
destroyBtn.TextColor3 = Color3.new(1,1,1)
destroyBtn.Font = Enum.Font.GothamBold
destroyBtn.TextSize = 16
destroyBtn.Parent = frame
Instance.new("UICorner", destroyBtn).CornerRadius = UDim.new(0.5, 0)
-- 点击销毁整个UI
destroyBtn.MouseButton1Click:Connect(function()
    if deleteLoopConnection then
        deleteLoopConnection:Disconnect()
    end
    if collectConnection then
        collectConnection:Disconnect()
    end
    if moveConnection then
        moveConnection:Disconnect()
    end
    gui:Destroy()
    print("✅ UI已完全销毁")
end)

local contentContainer = Instance.new("Frame", frame)
contentContainer.Size = UDim2.new(1, 0, 1, 0)
contentContainer.Position = UDim2.new(0, 0, 0, 0)
contentContainer.BackgroundTransparency = 1
contentContainer.Visible = true
contentContainer.ClipsDescendants = false

local function button(txt, y)
    local btn = Instance.new("TextButton", contentContainer)
    btn.Text = txt
    btn.Size = UDim2.new(1, -20, 0, 24)
    btn.Position = UDim2.new(0, 10, 0, y)
    btn.BackgroundColor3 = Color3.fromRGB(70, 130, 180)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 14
    btn.TextColor3 = Color3.new(1, 1, 1)
    Instance.new("UICorner", btn)
    return btn
end

-- 按钮列表：移除主UI的速度、金额配置项
local floatToggle = button("悬浮: OFF", 20)
local autoFarmToggle = button("自动捡箱: OFF", 50)
local deleteToggle = button("循环删箱: OFF", 80)
local moveToChestToggle = button("移动到宝箱: OFF", 110)
local grabToggle = button("拿起道具: OFF", 140)
local bossScriptButton = button("秒杀NPC", 170)
local autoOpenChests = button("自动开箱 (Off)", 200)
local clearCups = button("清理道具 (Off)", 230)
local moneyButton = button("刷钱功能", 260)

local function toggleFloat(forceState)
    local character = player.Character or player.CharacterAdded:Wait()
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    local humanoid = character:WaitForChild("Humanoid")

    if forceState ~= nil then
        isFloating = forceState
    else
        isFloating = not isFloating
    end

    if isFloating then
        humanoid.PlatformStand = true
        local bv = Instance.new("BodyVelocity")
        bv.Velocity = Vector3.new(0, 0, 0)
        bv.MaxForce = Vector3.new(0, math.huge, 0)
        bv.Parent = humanoidRootPart

        floatToggle.Text = "悬浮: ON"
        floatToggle.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
    else
        humanoid.PlatformStand = false
        for _, child in pairs(humanoidRootPart:GetChildren()) do
            if child:IsA("BodyVelocity") then
                child:Destroy()
            end
        end

        floatToggle.Text = "悬浮: OFF"
        floatToggle.BackgroundColor3 = Color3.fromRGB(70, 130, 180)
    end
end

floatToggle.MouseButton1Click:Connect(function()
    toggleFloat()
end)

player.CharacterAdded:Connect(function(character)
    if isFloating then
        task.wait(1)
        toggleFloat(true)
        print("角色重生，自动重启悬浮功能")
    else
        floatToggle.Text = "悬浮: OFF"
        floatToggle.BackgroundColor3 = Color3.fromRGB(70, 130, 180)
    end
end)

-- 自动捡箱独立逻辑
autoFarmToggle.MouseButton1Click:Connect(function()
    autoFarmEnabled = not autoFarmEnabled
    autoFarmToggle.Text = autoFarmEnabled and "自动捡箱: ON" or "自动捡箱: OFF"
    if autoFarmEnabled then
        startAutoCollect()
        autoFarmToggle.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
    else
        if collectConnection then
            collectConnection:Disconnect()
            collectConnection = nil
        end
        autoFarmToggle.BackgroundColor3 = Color3.fromRGB(70, 130, 180)
    end
end)

-- 循环删箱独立逻辑
deleteToggle.MouseButton1Click:Connect(function()
    deleteEnabled = not deleteEnabled
    deleteToggle.Text = deleteEnabled and "循环删箱: ON" or "循环删箱: OFF"
    if deleteEnabled then
        toggleDeleteLoop(true)
        deleteToggle.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
    else
        toggleDeleteLoop(false)
        deleteToggle.BackgroundColor3 = Color3.fromRGB(70, 130, 180)
    end
end)

moveToChestToggle.MouseButton1Click:Connect(function()
    moveToChestEnabled = not moveToChestEnabled
    moveToChestToggle.Text = moveToChestEnabled and "移动到宝箱: ON" or "移动到宝箱: OFF"
    if moveToChestEnabled then
        startAutoMove()
        moveToChestToggle.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
    else
        if moveConnection then
            moveConnection:Disconnect()
            moveConnection = nil
        end
        moveToChestToggle.BackgroundColor3 = Color3.fromRGB(70, 130, 180)
    end
end)

grabToggle.MouseButton1Click:Connect(function()
    grabEnabled = not grabEnabled
    grabToggle.Text = grabEnabled and "拿起道具: ON" or "拿起道具: OFF"
    grabToggle.BackgroundColor3 = grabEnabled and Color3.fromRGB(0,255,0) or Color3.fromRGB(70,130,180)
end)

bossScriptButton.MouseButton1Click:Connect(function()
    bossScriptButton.Text = "加载中..."
    bossScriptButton.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
    pcall(function()
        loadstring(game:HttpGet("https://rawscripts.net/raw/(ERROR-Assist)-Sans-Funny-Boss-Rush-Script-OP-UNDETECTABLE-18697"))()
        print("✅ Boss脚本加载完成")
    end)
    task.wait(1)
    bossScriptButton.Text = "秒杀NPC"
    bossScriptButton.BackgroundColor3 = Color3.fromRGB(70, 130, 180)
end)

autoOpenChests.MouseButton1Click:Connect(function()
    if autoOpenChests.Text == "自动开箱 (Off)" then
        autoOpenChests.Text = "自动开箱 (On)"
        autoOpenChests.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
        _G.OpenAllChests = true

        task.spawn(function()
            while _G.OpenAllChests == true do
                wait(1)
                for i,v in pairs(game.Players.LocalPlayer:FindFirstChildOfClass("Backpack"):GetChildren()) do
                    if string.lower(v.Name):find("chest") then
                        v.Parent = game.Players.LocalPlayer.Character
                    end
                end
                for i,v in pairs(game.Players.LocalPlayer.Character:GetChildren()) do
                    if string.lower(v.Name):find("chest") then
                        v:Activate()
                    end
                end
            end
        end)
    else
        if autoOpenChests.Text == "自动开箱 (On)" then
            autoOpenChests.Text = "自动开箱 (Off)"
            autoOpenChests.BackgroundColor3 = Color3.fromRGB(70, 130, 180)
            _G.OpenAllChests = false
        end
    end
end)

clearCups.MouseButton1Click:Connect(function()
    if clearCups.Text == "清理道具 (Off)" then
        clearCups.Text = "清理道具 (On)"
        clearCups.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
        _G.DeleteProps = true

        task.spawn(function()
            while _G.DeleteProps do
                task.wait(1)
                local backpack = player:FindFirstChildOfClass("Backpack")
                if not backpack then continue end

                for _, v in pairs(backpack:GetChildren()) do
                    if table.find(deleteList, v.Name) then
                        v:Destroy()
                    end
                end
            end
        end)
    else
        clearCups.Text = "清理道具 (Off)"
        clearCups.BackgroundColor3 = Color3.fromRGB(70, 130, 180)
        _G.DeleteProps = false
    end
end)

moneyButton.MouseButton1Click:Connect(function()
    if moneyButton.Text == "刷钱功能" then
        moneyButton.Text = "刷钱中..."
        moneyButton.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
        initMoneyHack()
        sendMoneyRequest(DEFAULT_NEG_AMOUNT)
        task.wait(1)
        moneyButton.Text = "刷钱功能"
        moneyButton.BackgroundColor3 = Color3.fromRGB(70, 130, 180)
    end
end)

-- 右下角设置按钮
local settingsOpen = false
local settingsBtn = Instance.new("TextButton")
settingsBtn.Text = "⚙️"
settingsBtn.Size = UDim2.new(0, 30, 0, 30)
settingsBtn.Position = UDim2.new(1, -40, 1, -40)
settingsBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
settingsBtn.TextColor3 = Color3.new(1,1,1)
settingsBtn.Font = Enum.Font.GothamBold
settingsBtn.TextSize = 16
settingsBtn.Parent = frame
Instance.new("UICorner", settingsBtn).CornerRadius = UDim.new(0.5,0)

-- 设置面板：保留速度、金额、删除间隔配置
local settingsFrame = Instance.new("Frame")
settingsFrame.Size = UDim2.new(0, 220, 0, 150)
settingsFrame.Position = UDim2.new(1, -260, 1, -190)
settingsFrame.BackgroundColor3 = Color3.fromRGB(25,25,35)
settingsFrame.BorderSizePixel = 0
settingsFrame.Visible = false
settingsFrame.Parent = gui
Instance.new("UICorner", settingsFrame).CornerRadius = UDim.new(0,6)

local function settingLabel(txt,y)
    local l = Instance.new("TextLabel", settingsFrame)
    l.Text = txt
    l.Size = UDim2.new(0,100,0,25)
    l.Position = UDim2.new(0,10,0,y)
    l.BackgroundTransparency = 1
    l.Font = Enum.Font.Gotham
    l.TextColor3 = Color3.fromRGB(200,200,200)
    l.TextSize = 14
    return l
end

local function settingBox(default,y)
    local b = Instance.new("TextBox", settingsFrame)
    b.Text = tostring(default)
    b.Size = UDim2.new(0,80,0,25)
    b.Position = UDim2.new(0,120,0,y)
    b.BackgroundColor3 = Color3.fromRGB(50,50,50)
    b.TextColor3 = Color3.new(1,1,1)
    b.Font = Enum.Font.Gotham
    b.TextSize = 14
    b.ClearTextOnFocus = false
    Instance.new("UICorner", b).CornerRadius = UDim.new(0,4)
    return b
end

-- 设置项：仅在面板中保留
settingLabel("移动宝箱速度",10)
local chestSpeedBox = settingBox(moveSpeed,10)
chestSpeedBox.FocusLost:Connect(function()
    local val = tonumber(chestSpeedBox.Text)
    if val and val > 0 then
        moveSpeed = val
    else
        chestSpeedBox.Text = tostring(moveSpeed)
    end
end)

settingLabel("刷钱金额",45)
local setMoneyBox = settingBox(DEFAULT_NEG_AMOUNT,45)
setMoneyBox.FocusLost:Connect(function()
    local val = tonumber(setMoneyBox.Text)
    if val then
        DEFAULT_NEG_AMOUNT = val
    else
        setMoneyBox.Text = tostring(DEFAULT_NEG_AMOUNT)
    end
end)

settingLabel("删除间隔(秒)",80)
local setDeleteBox = settingBox(deleteInterval,80)
setDeleteBox.FocusLost:Connect(function()
    local val = tonumber(setDeleteBox.Text)
    if val and val > 0 then
        deleteInterval = val
        if deleteEnabled then
            toggleDeleteLoop(false)
            toggleDeleteLoop(true)
        end
    else
        setDeleteBox.Text = tostring(deleteInterval)
    end
end)

-- 设置按钮点击事件
settingsBtn.MouseButton1Click:Connect(function()
    settingsOpen = not settingsOpen
    settingsFrame.Visible = settingsOpen
end)

-- 修复折叠逻辑：隐藏除收缩按钮外的所有控件
local isCollapsed = false
toggleButton.MouseButton1Click:Connect(function()
    isCollapsed = not isCollapsed
    if isCollapsed then
        -- 折叠状态：隐藏内容、设置按钮、删除按钮，缩小窗口
        frame.Size = UDim2.new(0, 200, 0, 30)
        contentContainer.Visible = false
        destroyBtn.Visible = false
        settingsBtn.Visible = false
        settingsFrame.Visible = false
        toggleButton.Text = "+"
    else
        -- 展开状态：恢复所有控件和窗口大小
        frame.Size = UDim2.new(0, 200, 0, 350)
        contentContainer.Visible = true
        destroyBtn.Visible = true
        settingsBtn.Visible = true
        toggleButton.Text = "−"
    end
end)

task.spawn(function()
    while true do
        task.wait(0.05)
        if grabEnabled then
            for _, item in ipairs(workspace:GetDescendants()) do
                if item:IsA("Tool") and item.Parent == workspace then
                    item.Parent = player.Backpack
                end
            end
        end
    end
end)

print("✅ 自动农场UI加载完成 - 移除主UI重复配置项")