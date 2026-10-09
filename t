-- ==================== 自动刷金币 + 全技能循环脚本 ====================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
if not player then
    repeat wait() until Players.LocalPlayer
    player = Players.LocalPlayer
end

print("[脚本] 玩家已加载: " .. player.Name)

-- 创建UI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "AutoCoinGui"
screenGui.ResetOnSpawn = false
screenGui.DisplayOrder = 9999

local function getGuiParent()
    if gethui then
        local ok, hui = pcall(gethui)
        if ok and hui then return hui end
    end
    if get_hidden_gui then
        local ok, hui = pcall(get_hidden_gui)
        if ok and hui then return hui end
    end
    return player:WaitForChild("PlayerGui")
end

screenGui.Parent = getGuiParent()

-- ============================================================
-- 通用：创建按钮
-- ============================================================
local BTN_W = 120
local BTN_H = 30
local GAP = 34

local currentY = 10

local function makeButton(text, color)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, BTN_W, 0, BTN_H)
    btn.Position = UDim2.new(1, -130, 0, currentY)
    btn.BackgroundColor3 = color or Color3.fromRGB(50, 50, 50)
    btn.BackgroundTransparency = 0.1
    btn.BorderSizePixel = 0
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextSize = 12
    btn.Font = Enum.Font.GothamBold
    btn.ZIndex = 999
    btn.Parent = screenGui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = btn

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(255, 255, 255)
    stroke.Thickness = 1
    stroke.Transparency = 0.7
    stroke.Parent = btn

    currentY = currentY + GAP
    return btn
end

-- ============================================================
-- 按钮们
-- ============================================================
local deleteBtn = makeButton("🗑 删除UI", Color3.fromRGB(200, 50, 50))
local toggleBtn = makeButton("🪙 刷金币: 关", Color3.fromRGB(50, 50, 50))

local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(0, 220, 0, 18)
statusLabel.Position = UDim2.new(1, -230, 0, currentY + 4)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "⏳ 未开启"
statusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
statusLabel.TextSize = 11
statusLabel.Font = Enum.Font.Gotham
statusLabel.TextXAlignment = Enum.TextXAlignment.Right
statusLabel.ZIndex = 999
statusLabel.Parent = screenGui

-- ============================================================
-- 公共
-- ============================================================
local function getChar()
    local char = player.Character
    if not char then return nil end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end
    return char, hrp
end

local function getRoot()
    local char = player.Character
    if not char then return nil end
    return char:FindFirstChild("HumanoidRootPart")
end

local function fireTouchInterest(ti)
    if not ti then return false end

    local root = getRoot()
    if not root then return false end

    local ok = pcall(function()
        ti:Fire(root)
    end)
    if ok then return true end

    local part = ti.Parent
    if part and part:IsA("BasePart") then
        local ok2 = pcall(function()
            firetouchinterest(part, root, 0)
            task.wait(0.05)
            firetouchinterest(part, root, 1)
        end)
        if ok2 then return true end
    end

    return false
end

local function fireClickDetector(cd)
    if not cd then return false end
    local ok = pcall(function()
        fireclickdetector(cd)
    end)
    return ok
end

-- ============================================================
-- 变量
-- ============================================================
local isEnabled = false
local mainThread = nil
local tpThread = nil
local skillThread = nil
local step3Thread = nil   -- ★ 第3步循环

local TP_POS = Vector3.new(-66.7, 29.9, 1161.5)

local COIN_TARGET = 10000000

local function readCoins()
    local ls = player:FindFirstChild("leaderstats")
    if not ls then return nil end
    local coins = ls:FindFirstChild("Coins")
    if not coins then return nil end
    return coins.Value
end

-- ============================================================
-- 全技能（9 个工具 + nil 的 Wide Slash）
-- ============================================================
local SKILL_INTERVAL = 0.5

local NEW_ARGS = {-72.44404602050781, 26.948883056640625, 1108.3070068359375}

local USE_TOOLS = {
    { tool = "POWER OF NEO",        remote = "RemoteEvent", args = {33.402862548828125, 26.948890686035156, 971.2333984375} },
    { tool = "GRIPPING PHONES",     remote = "RemoteEvent", args = {-8.755027770996094, 26.94888687133789, 756.6915893554688} },
    { tool = "HEAD THROW",          remote = "RemoteEvent", args = {15.339271545410156, 26.948890686035156, 743.77587890625} },
    { tool = "GAME OVER",           remote = "RemoteEvent", args = NEW_ARGS },
    { tool = "Chains of Judgement", remote = "RemoteEvent", args = NEW_ARGS },
    { tool = "Massive Bone Waves",  remote = "RemoteEvent", args = NEW_ARGS },
    { tool = "Giant Bone Zones",    remote = "RemoteEvent", args = NEW_ARGS },
    { tool = "King Blaster Circle", remote = "RemoteEvent", args = NEW_ARGS },
    { tool = "King's Blasters",     remote = "RemoteEvent", args = NEW_ARGS },
}

local NIL_TARGET = {
    name = "Wide Slash",
    class = "RemoteEvent",
    args = {142.47024536132812, 26.94888687133789, 721.6943969726562},
}

local function getNil(name, class)
    for _, v in next, getnilinstances() do
        if v.ClassName == class and v.Name == name then
            return v
        end
    end
end

local function getTool(name)
    local backpack = player:FindFirstChild("Backpack")
    if backpack then
        local t = backpack:FindFirstChild(name)
        if t then return t end
    end
    local char = player.Character
    if char then
        local t = char:FindFirstChild(name)
        if t then return t end
    end
    return nil
end

local function fireOneTool(entry)
    local tool = getTool(entry.tool)
    if not tool then return false end
    local remote = tool:FindFirstChild(entry.remote)
    if not remote or not remote:IsA("RemoteEvent") then return false end
    pcall(function()
        remote:FireServer(unpack(entry.args))
    end)
    return true
end

local function fireNilTarget()
    local remote = getNil(NIL_TARGET.name, NIL_TARGET.class)
    if not remote then return false end
    pcall(function()
        remote:FireServer(unpack(NIL_TARGET.args))
    end)
    return true
end

local function skillLoop()
    while isEnabled do
        local fired = 0
        local total = #USE_TOOLS + 1

        for _, entry in ipairs(USE_TOOLS) do
            if not isEnabled then break end
            if fireOneTool(entry) then
                fired = fired + 1
            end
        end

        if isEnabled then
            if fireNilTarget() then
                fired = fired + 1
            end
        end

        statusLabel.Text = "⚔️ 已触发 " .. fired .. "/" .. total
        statusLabel.TextColor3 = Color3.fromRGB(0, 255, 150)

        task.wait(SKILL_INTERVAL)
    end
end

-- ============================================================
-- ★ 第3步循环：每 0.25 秒触发一次 PabloCreation.Morph.TouchInterest ★
-- ============================================================
local STEP3_INTERVAL = 0.25

local function step3Loop()
    while isEnabled do
        local pc = Workspace:FindFirstChild("PabloCreation")
        if pc then
            local morph = pc:FindFirstChild("Morph")
            if morph then
                local ti = morph:FindFirstChild("TouchInterest")
                if ti then
                    fireTouchInterest(ti)
                end
            end
        end
        task.wait(STEP3_INTERVAL)
    end
end

-- ============================================================
-- 主循环（刷金币流程）
-- ============================================================
local function mainLoop()
    while isEnabled do
        --------------------------------------------------------
        -- 1. EndlessModeVote.ClickDetector
        --------------------------------------------------------
        statusLabel.Text = "1. EndlessModeVote..."
        statusLabel.TextColor3 = Color3.fromRGB(255, 255, 150)

        local vote = Workspace:FindFirstChild("EndlessModeVote")
        if vote then
            local cd = vote:FindFirstChild("ClickDetector")
            if cd then
                fireClickDetector(cd)
                print("[刷金币] 已触发 EndlessModeVote")
            end
        end

        task.wait(2)

        --------------------------------------------------------
        -- 2. EndlessModeVoteSkip.ClickDetector
        --------------------------------------------------------
        statusLabel.Text = "2. EndlessModeVoteSkip..."

        for i = 1, 5 do
            if not isEnabled then break end

            local skip = Workspace:FindFirstChild("EndlessModeVoteSkip")
            if skip then
                local cd = skip:FindFirstChild("ClickDetector")
                if cd then
                    fireClickDetector(cd)
                    print("[刷金币] 已触发 EndlessModeVoteSkip (第" .. i .. "遍找到)")
                    break
                end
            end

            task.wait(1)
        end

        if not isEnabled then break end

        task.wait(1)

        --------------------------------------------------------
        -- 3. 启动 PabloCreation.Morph.TouchInterest 循环（0.25秒一次）
        --    不阻塞主流程
        --------------------------------------------------------
        statusLabel.Text = "3. PabloCreation.Morph（循环触发）..."

        if step3Thread then
            pcall(function() task.cancel(step3Thread) end)
            step3Thread = nil
        end
        step3Thread = task.spawn(step3Loop)

        -- 等一小下，让第3步循环先跑起来
        task.wait(0.2)

        --------------------------------------------------------
        -- 4. 传送 + 同时启动全技能循环
        --------------------------------------------------------
        statusLabel.Text = "4. 传送中..."

        if tpThread then
            pcall(function() task.cancel(tpThread) end)
            tpThread = nil
        end
        tpThread = task.spawn(function()
            while isEnabled do
                local char, hrp = getChar()
                if hrp then
                    pcall(function()
                        hrp.CFrame = CFrame.new(TP_POS)
                        hrp.Velocity = Vector3.new(0, 0, 0)
                    end)
                end
                task.wait()
            end
        end)

        if skillThread then
            pcall(function() task.cancel(skillThread) end)
            skillThread = nil
        end
        skillThread = task.spawn(skillLoop)

        task.wait(2)

        --------------------------------------------------------
        -- 5. Start.Part.TouchInterest
        --------------------------------------------------------
        statusLabel.Text = "5. Start.Part.TouchInterest..."

        local startObj = Workspace:FindFirstChild("Start")
        if startObj then
            local part = startObj:FindFirstChild("Part")
            if part then
                local ti = part:FindFirstChild("TouchInterest")
                if ti then
                    fireTouchInterest(ti)
                    print("[刷金币] 已触发 Start.Part.TouchInterest")
                end
            end
        end

        --------------------------------------------------------
        -- 6. 记录 Coins
        --------------------------------------------------------
        local startCoins = readCoins()
        if startCoins == nil then
            statusLabel.Text = "❌ 找不到 leaderstats.Coins"
            statusLabel.TextColor3 = Color3.fromRGB(255, 50, 50)
            task.wait(1)
            continue
        end

        print("[刷金币] 起始 Coins: " .. tostring(startCoins))

        --------------------------------------------------------
        -- 7. 等 Coins 增加 ≥ 1000万
        --------------------------------------------------------
        statusLabel.Text = "7. 等待金币 +1000万..."
        statusLabel.TextColor3 = Color3.fromRGB(255, 255, 150)

        while isEnabled do
            local nowCoins = readCoins()
            if nowCoins and (nowCoins - startCoins) >= COIN_TARGET then
                print("[刷金币] Coins 已增加: " .. startCoins .. " → " .. nowCoins)
                break
            end
            task.wait(0.1)
        end

        if not isEnabled then break end

        --------------------------------------------------------
        -- 8. SoulKiller.ClickDetector
        --------------------------------------------------------
        statusLabel.Text = "8. SoulKiller..."

        local sk = Workspace:FindFirstChild("SoulKiller")
        if sk then
            local cd = sk:FindFirstChild("ClickDetector")
            if cd then
                fireClickDetector(cd)
                print("[刷金币] 已触发 SoulKiller")
            end
        end

        --------------------------------------------------------
        -- 9. 停传送 + 停技能 + 停第3步循环，等 10 秒
        --------------------------------------------------------
        statusLabel.Text = "9. 等待10秒..."
        statusLabel.TextColor3 = Color3.fromRGB(0, 255, 150)

        if tpThread then
            pcall(function() task.cancel(tpThread) end)
            tpThread = nil
        end

        if skillThread then
            pcall(function() task.cancel(skillThread) end)
            skillThread = nil
        end

        if step3Thread then
            pcall(function() task.cancel(step3Thread) end)
            step3Thread = nil
        end

        task.wait(10)
    end
end

-- ============================================================
-- 开关点击
-- ============================================================
toggleBtn.MouseButton1Click:Connect(function()
    if isEnabled then
        isEnabled = false
        if mainThread then
            pcall(function() task.cancel(mainThread) end)
            mainThread = nil
        end
        if tpThread then
            pcall(function() task.cancel(tpThread) end)
            tpThread = nil
        end
        if skillThread then
            pcall(function() task.cancel(skillThread) end)
            skillThread = nil
        end
        if step3Thread then
            pcall(function() task.cancel(step3Thread) end)
            step3Thread = nil
        end

        toggleBtn.Text = "🪙 刷金币: 关"
        toggleBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
        statusLabel.Text = "⏳ 未开启"
        statusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
        print("[脚本] 刷金币已关闭")
    else
        isEnabled = true
        toggleBtn.Text = "🪙 刷金币: 开"
        toggleBtn.BackgroundColor3 = Color3.fromRGB(0, 180, 0)
        statusLabel.Text = "🔄 开始..."
        statusLabel.TextColor3 = Color3.fromRGB(0, 255, 150)
        print("[脚本] 刷金币已开启")

        mainThread = task.spawn(mainLoop)
    end
end)

-- ============================================================
-- 删除UI按钮点击
-- ============================================================
deleteBtn.MouseButton1Click:Connect(function()
    isEnabled = false
    if mainThread then
        pcall(function() task.cancel(mainThread) end)
        mainThread = nil
    end
    if tpThread then
        pcall(function() task.cancel(tpThread) end)
        tpThread = nil
    end
    if skillThread then
        pcall(function() task.cancel(skillThread) end)
        skillThread = nil
    end
    if step3Thread then
        pcall(function() task.cancel(step3Thread) end)
        step3Thread = nil
    end

    screenGui:Destroy()
    print("[脚本] UI 已删除")
end)

print("[脚本] 已加载")