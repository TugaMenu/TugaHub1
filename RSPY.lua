-- RemoteSpy Mobile v2.0
if getgenv().__RSPY_RUNNING then
    if getgenv().__RSPY_STOP then getgenv().__RSPY_STOP() end
end

----------------------------------------------------------------
-- SERVIÇOS
----------------------------------------------------------------
local cloneref     = cloneref or function(x) return x end
local newcclosure  = newcclosure or function(f) return f end
local setclipboard = setclipboard or toclipboard or function() end

local Players      = cloneref(game:GetService("Players"))
local TweenService = cloneref(game:GetService("TweenService"))
local UIS          = cloneref(game:GetService("UserInputService"))
local TextService  = cloneref(game:GetService("TextService"))
local CoreGui      = cloneref(game:GetService("CoreGui"))
local GuiService   = cloneref(game:GetService("GuiService"))

local lower = string.lower

----------------------------------------------------------------
-- CORES
----------------------------------------------------------------
local C = {
    bg      = Color3.fromRGB(12, 12, 18),
    panel   = Color3.fromRGB(18, 18, 26),
    sidebar = Color3.fromRGB(14, 14, 20),
    item    = Color3.fromRGB(24, 24, 34),
    itemSel = Color3.fromRGB(40, 70, 180),
    accent  = Color3.fromRGB(70, 110, 255),
    accent2 = Color3.fromRGB(110, 70, 255),
    text    = Color3.fromRGB(215, 215, 230),
    dim     = Color3.fromRGB(110, 110, 135),
    red     = Color3.fromRGB(255, 75, 75),
    green   = Color3.fromRGB(70, 210, 110),
    yellow  = Color3.fromRGB(255, 205, 50),
    border  = Color3.fromRGB(35, 35, 52),
    code    = Color3.fromRGB(8, 10, 18),
}

----------------------------------------------------------------
-- HELPERS
----------------------------------------------------------------
local function mk(cls, props, parent)
    local o = Instance.new(cls)
    for k, v in next, props or {} do o[k] = v end
    if parent then o.Parent = parent end
    return o
end

local function frame(props, parent)
    local d = {BackgroundColor3=C.panel, BorderSizePixel=0}
    for k,v in next, props or {} do d[k]=v end
    return mk("Frame", d, parent)
end

local function label(props, parent)
    local d = {BackgroundTransparency=1, BorderSizePixel=0,
               TextColor3=C.text, Font=Enum.Font.Gotham,
               TextSize=14, TextWrapped=true}
    for k,v in next, props or {} do d[k]=v end
    return mk("TextLabel", d, parent)
end

local function btn(props, parent)
    local d = {BackgroundColor3=C.item, BorderSizePixel=0,
               TextColor3=C.text, Font=Enum.Font.GothamBold,
               TextSize=14, AutoButtonColor=false}
    for k,v in next, props or {} do d[k]=v end
    return mk("TextButton", d, parent)
end

local function corner(r, o)
    mk("UICorner", {CornerRadius=UDim.new(0, r or 8)}, o)
end

local function tw(o, t, p)
    TweenService:Create(o, TweenInfo.new(t, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), p):Play()
end

local function touchFeedback(b, normalColor)
    local nc = normalColor or C.item
    local flash = Color3.new(
        math.min(nc.R + 0.15, 1),
        math.min(nc.G + 0.15, 1),
        math.min(nc.B + 0.15, 1)
    )
    tw(b, 0.07, {BackgroundColor3 = flash})
    task.delay(0.15, function()
        pcall(tw, b, 0.1, {BackgroundColor3 = nc})
    end)
end

-- Conecta tanto MouseButton1Click quanto TouchTap
local function onPress(obj, fn)
    obj.MouseButton1Click:Connect(fn)
    obj.TouchTap:Connect(fn)
end

----------------------------------------------------------------
-- VAL2STR - sem wait, sem yield, sem loop infinito
----------------------------------------------------------------
local function val2str(v, depth)
    depth = depth or 0
    if depth > 4 then return "..." end
    local t = typeof(v)

    if t == "nil" then return "nil"
    elseif t == "boolean" then return tostring(v)
    elseif t == "number" then
        if v == math.huge then return "math.huge"
        elseif v == -math.huge then return "-math.huge"
        elseif v ~= v then return "0/0"
        else return tostring(v) end
    elseif t == "string" then
        local s = v:gsub('\\','\\\\'):gsub('"','\\"'):gsub('\n','\\n'):gsub('\r','\\r'):gsub('\t','\\t')
        if #s > 300 then s = s:sub(1,300)..'..."' end
        return '"'..s..'"'
    elseif t == "Instance" then
        local parts = {}
        local cur = v
        for _ = 1, 40 do
            if cur == nil or cur == game then break end
            table.insert(parts, 1, cur)
            cur = cur.Parent
        end
        if cur ~= game or #parts == 0 then return 'game --[[?]]' end
        local root = parts[1]
        local out
        local ok, svc = pcall(function() return game:GetService(root.ClassName) end)
        if ok and svc then
            if lower(root.ClassName) == "workspace" then
                out = "workspace"
            else
                out = 'game:GetService("'..root.ClassName..'")'
            end
        elseif root.Name:match("^[%a_][%w_]*$") then
            out = "game."..root.Name
        else
            out = 'game:FindFirstChild("'..root.Name:gsub('"','\\"')..'")'
        end
        for i = 2, #parts do
            local n = parts[i].Name
            if n:match("^[%a_][%w_]*$") then
                out = out.."."..n
            else
                out = out..':FindFirstChild("'..n:gsub('"','\\"')..'")'
            end
        end
        return out
    elseif t == "Vector3" then
        return ("Vector3.new(%g, %g, %g)"):format(v.X,v.Y,v.Z)
    elseif t == "Vector2" then
        return ("Vector2.new(%g, %g)"):format(v.X,v.Y)
    elseif t == "CFrame" then
        local c = {v:GetComponents()}
        return "CFrame.new("..table.concat(c,", ")..")"
    elseif t == "Color3" then
        return ("Color3.new(%g, %g, %g)"):format(v.R,v.G,v.B)
    elseif t == "UDim2" then
        return ("UDim2.new(%g, %g, %g, %g)"):format(v.X.Scale,v.X.Offset,v.Y.Scale,v.Y.Offset)
    elseif t == "UDim" then
        return ("UDim.new(%g, %g)"):format(v.Scale,v.Offset)
    elseif t == "BrickColor" then
        return ('BrickColor.new("%s")'):format(tostring(v))
    elseif t == "EnumItem" or t == "Enum" or t == "Enums" then
        return tostring(v)
    elseif t == "TweenInfo" then
        return ("TweenInfo.new(%g, %s, %s, %g, %s, %g)"):format(
            v.Time,tostring(v.EasingStyle),tostring(v.EasingDirection),
            v.RepeatCount,tostring(v.Reverses),v.DelayTime)
    elseif t == "NumberRange" then
        return ("NumberRange.new(%g, %g)"):format(v.Min,v.Max)
    elseif t == "Ray" then
        return ("Ray.new(Vector3.new(%g,%g,%g), Vector3.new(%g,%g,%g))"):format(
            v.Origin.X,v.Origin.Y,v.Origin.Z,v.Direction.X,v.Direction.Y,v.Direction.Z)
    elseif t == "table" then
        if depth >= 3 then return "{...}" end
        local entries, n = {}, 0
        for k2, val in next, v do
            n += 1
            if n > 20 then entries[#entries+1]="    -- ...mais"; break end
            local ks
            if type(k2)=="string" and k2:match("^[%a_][%w_]*$") then ks=k2
            else ks="["..val2str(k2,depth+1).."]" end
            entries[#entries+1] = "    "..ks.." = "..val2str(val,depth+1)
        end
        if #entries == 0 then return "{}" end
        return "{\n"..table.concat(entries,",\n").."\n}"
    else
        return tostring(v)
    end
end

local function buildScript(remote, args)
    local lines = {}
    for i, v in ipairs(args) do
        lines[#lines+1] = "local arg"..i.." = "..val2str(v)
    end
    local remotePath = val2str(remote)
    local argList = {}
    for i = 1, #args do argList[#argList+1] = "arg"..i end
    local call = table.concat(argList, ", ")
    lines[#lines+1] = ""
    if remote:IsA("RemoteEvent") then
        lines[#lines+1] = remotePath..":FireServer("..call..")"
    else
        lines[#lines+1] = remotePath..":InvokeServer("..call..")"
    end
    return table.concat(lines, "\n")
end

----------------------------------------------------------------
-- GUI
----------------------------------------------------------------
local ScreenGui = mk("ScreenGui", {
    Name            = "RemoteSpy_Mobile",
    ResetOnSpawn    = false,
    IgnoreGuiInset  = false,
    ZIndexBehavior  = Enum.ZIndexBehavior.Sibling,
    DisplayOrder    = 9999,
}, gethui and gethui() or CoreGui)

-- Janela principal centralizada
local Main = frame({
    Size             = UDim2.new(0, 700, 0, 460),
    Position         = UDim2.new(0.5, -350, 0.5, -230),
    BackgroundColor3 = C.bg,
    ClipsDescendants = true,
}, ScreenGui)
corner(12, Main)
mk("UIStroke", {Color=C.border, Thickness=1}, Main)

-- Linha accent topo
local accentBar = frame({
    Size=UDim2.new(1,0,0,3), BackgroundColor3=C.accent, ZIndex=5
}, Main)
mk("UIGradient", {
    Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, C.accent),
        ColorSequenceKeypoint.new(1, C.accent2),
    })
}, accentBar)

-- TOPBAR (48px, botões 44px touch)
local TopBar = frame({
    Size=UDim2.new(1,0,0,48), Position=UDim2.new(0,0,0,3),
    BackgroundColor3=C.bg,
}, Main)

label({
    Size=UDim2.new(1,-220,1,0), Position=UDim2.new(0,14,0,0),
    Text="RemoteSpy", TextXAlignment=Enum.TextXAlignment.Left,
    Font=Enum.Font.GothamBold, TextSize=16, TextWrapped=false,
}, TopBar)

local StatusLabel = label({
    Size=UDim2.new(0,60,1,0), Position=UDim2.new(1,-215,0,0),
    Text="● ON", TextSize=12, Font=Enum.Font.GothamBold,
    TextColor3=C.green, TextXAlignment=Enum.TextXAlignment.Right,
    TextWrapped=false,
}, TopBar)

local function mkTopBtn(txt, bg, xOff)
    local b = btn({
        Size=UDim2.fromOffset(44,38),
        Position=UDim2.new(1,xOff,0.5,-19),
        Text=txt, TextSize=15,
        BackgroundColor3=bg,
    }, TopBar)
    corner(8, b)
    return b
end

local BtnToggle = mkTopBtn("⏸", Color3.fromRGB(20,80,30),  -10)
local BtnClear  = mkTopBtn("🗑", C.item,                    -60)
local BtnClose  = mkTopBtn("✕", Color3.fromRGB(140,30,30), -110)

frame({Size=UDim2.new(1,0,0,1), Position=UDim2.new(0,0,1,-1), BackgroundColor3=C.border}, TopBar)

----------------------------------------------------------------
-- DRAG (touch + mouse)
----------------------------------------------------------------
do
    local dragging, startPos, winStart = false, nil, nil
    local function startDrag(x, y)
        dragging = true
        startPos = Vector2.new(x, y)
        winStart = Main.Position
    end
    local function moveDrag(x, y)
        if not dragging or not startPos then return end
        local d = Vector2.new(x,y) - startPos
        Main.Position = UDim2.new(
            winStart.X.Scale, winStart.X.Offset + d.X,
            winStart.Y.Scale, winStart.Y.Offset + d.Y
        )
    end
    local function stopDrag() dragging = false end

    TopBar.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            startDrag(inp.Position.X, inp.Position.Y)
        end
    end)
    TopBar.TouchStarted:Connect(function(touch)
        startDrag(touch.Position.X, touch.Position.Y)
    end)
    UIS.InputChanged:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseMovement
        or inp.UserInputType == Enum.UserInputType.Touch then
            moveDrag(inp.Position.X, inp.Position.Y)
        end
    end)
    UIS.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1
        or inp.UserInputType == Enum.UserInputType.Touch then
            stopDrag()
        end
    end)
end

----------------------------------------------------------------
-- CONTEÚDO
----------------------------------------------------------------
local Content = frame({
    Size=UDim2.new(1,0,1,-52), Position=UDim2.new(0,0,0,52),
    BackgroundTransparency=1,
}, Main)

-- SIDEBAR (240px)
local SIDE_W = 240
local Sidebar = frame({
    Size=UDim2.new(0,SIDE_W,1,0),
    BackgroundColor3=C.sidebar,
}, Content)

local SideHdr = frame({
    Size=UDim2.new(1,0,0,34), BackgroundColor3=C.bg,
}, Sidebar)
label({
    Size=UDim2.new(0.55,0,1,0), Position=UDim2.new(0,10,0,0),
    Text="REMOTES", TextSize=11, Font=Enum.Font.GothamBold,
    TextColor3=C.accent, TextXAlignment=Enum.TextXAlignment.Left,
    TextWrapped=false,
}, SideHdr)
local CountLabel = label({
    Size=UDim2.new(0.45,-8,1,0), Position=UDim2.new(0.55,0,0,0),
    Text="0 logs", TextSize=11,
    TextColor3=C.dim, TextXAlignment=Enum.TextXAlignment.Right,
    TextWrapped=false,
}, SideHdr)
frame({Size=UDim2.new(1,0,0,1), Position=UDim2.new(0,0,1,-1), BackgroundColor3=C.border}, SideHdr)

local ListScroll = mk("ScrollingFrame", {
    Size=UDim2.new(1,0,1,-34), Position=UDim2.new(0,0,0,34),
    BackgroundTransparency=1, BorderSizePixel=0,
    ScrollBarThickness=5, ScrollBarImageColor3=C.accent,
    CanvasSize=UDim2.new(0,0,0,0),
    ScrollingDirection=Enum.ScrollingDirection.Y,
}, Sidebar)

local ListLayout = mk("UIListLayout", {
    SortOrder=Enum.SortOrder.LayoutOrder, Padding=UDim.new(0,3),
}, ListScroll)
mk("UIPadding", {
    PaddingTop=UDim.new(0,4), PaddingBottom=UDim.new(0,4),
    PaddingLeft=UDim.new(0,4), PaddingRight=UDim.new(0,4),
}, ListScroll)

local EmptyLabel = label({
    Size=UDim2.new(1,0,0,60), Position=UDim2.new(0,0,0,8),
    Text="Nenhum remote.\nLigue o spy (⏸) e jogue.",
    TextSize=12, TextColor3=C.dim,
    TextXAlignment=Enum.TextXAlignment.Center,
}, ListScroll)

-- Divisor
frame({
    Size=UDim2.new(0,1,1,0), Position=UDim2.fromOffset(SIDE_W,0),
    BackgroundColor3=C.border,
}, Content)

-- PAINEL DIREITO
local RightPanel = frame({
    Size=UDim2.new(1,-(SIDE_W+1),1,0), Position=UDim2.fromOffset(SIDE_W+1,0),
    BackgroundColor3=C.bg,
}, Content)

-- Info bar
local InfoBar = frame({
    Size=UDim2.new(1,0,0,30), BackgroundColor3=C.panel,
}, RightPanel)
local InfoLabel = label({
    Size=UDim2.new(1,-10,1,0), Position=UDim2.new(0,10,0,0),
    Text="← Selecione um remote",
    TextSize=12, TextColor3=C.dim,
    TextXAlignment=Enum.TextXAlignment.Left, TextWrapped=false,
}, InfoBar)
frame({Size=UDim2.new(1,0,0,1), Position=UDim2.new(0,0,1,-1), BackgroundColor3=C.border}, InfoBar)

-- Área de código
local CodeScroll = mk("ScrollingFrame", {
    Size=UDim2.new(1,0,1,-84), Position=UDim2.new(0,0,0,30),
    BackgroundColor3=C.code, BorderSizePixel=0,
    ScrollBarThickness=5, ScrollBarImageColor3=C.accent,
    CanvasSize=UDim2.new(0,0,0,0),
    ScrollingDirection=Enum.ScrollingDirection.XY,
}, RightPanel)
mk("UIPadding", {PaddingAll=UDim.new(0,10)}, CodeScroll)

local CodeLabel = mk("TextLabel", {
    BackgroundTransparency=1,
    TextColor3=Color3.fromRGB(170,195,255),
    Font=Enum.Font.Code, TextSize=13,
    TextXAlignment=Enum.TextXAlignment.Left,
    TextYAlignment=Enum.TextYAlignment.Top,
    TextWrapped=false, RichText=false,
    Text="-- Nenhum remote selecionado",
    Size=UDim2.new(1,-20,1,-20),
}, CodeScroll)

local function setCode(str)
    str = str or ""
    CodeLabel.Text = str
    local sz = TextService:GetTextSize(str, CodeLabel.TextSize, CodeLabel.Font, Vector2.new(9999,9999))
    CodeScroll.CanvasSize = UDim2.fromOffset(
        math.max(sz.X+20, CodeScroll.AbsoluteSize.X),
        math.max(sz.Y+20, CodeScroll.AbsoluteSize.Y)
    )
end

-- Botões de ação (barra inferior, 54px, touch friendly)
local ActBar = frame({
    Size=UDim2.new(1,0,0,54), Position=UDim2.new(0,0,1,-54),
    BackgroundColor3=C.panel,
}, RightPanel)
frame({Size=UDim2.new(1,0,0,1), BackgroundColor3=C.border}, ActBar)

mk("UIListLayout", {
    FillDirection=Enum.FillDirection.Horizontal,
    HorizontalAlignment=Enum.HorizontalAlignment.Left,
    VerticalAlignment=Enum.VerticalAlignment.Center,
    Padding=UDim.new(0,4), SortOrder=Enum.SortOrder.LayoutOrder,
}, ActBar)
mk("UIPadding", {PaddingLeft=UDim.new(0,6), PaddingRight=UDim.new(0,6)}, ActBar)

local function mkActBtn(txt, order)
    local b = btn({
        Size=UDim2.fromOffset(96,40), Text=txt,
        TextSize=12, Font=Enum.Font.GothamBold,
        LayoutOrder=order, BackgroundColor3=C.item,
    }, ActBar)
    corner(8, b)
    mk("UIStroke", {Color=C.border, Thickness=1}, b)
    return b
end

local BtnCopy    = mkActBtn("📋 Copiar",   1)
local BtnCopyRem = mkActBtn("🔗 Remote",   2)
local BtnRun     = mkActBtn("▶ Run",       3)
local BtnExclude = mkActBtn("🚫 Excluir",  4)
local BtnBlock   = mkActBtn("🔒 Bloquear", 5)

----------------------------------------------------------------
-- ESTADO
----------------------------------------------------------------
local spyActive  = false
local logs       = {}
local selected   = nil
local blacklist  = {}
local blocklist  = {}
local logCount   = 0
local originalNC = nil

local function getRemoteId(remote)
    local ok, id = pcall(game.GetDebugId, game, remote)
    return ok and id or tostring(remote)
end

----------------------------------------------------------------
-- SELECIONAR LOG
----------------------------------------------------------------
local function selectLog(log)
    if selected and selected.item and selected.item.Parent then
        pcall(tw, selected.item, 0.12, {BackgroundColor3=C.item})
    end
    selected = log
    if log.item and log.item.Parent then
        pcall(tw, log.item, 0.12, {BackgroundColor3=C.itemSel})
    end
    local typeStr = log.remoteType == "event" and "Event" or "Function"
    InfoLabel.Text = log.remote.Name.."  •  "..typeStr.."  •  "..#log.args.." args"
    if not log.script then
        local ok, res = pcall(buildScript, log.remote, log.args)
        log.script = ok and res or ("-- Erro:\n-- "..tostring(res))
    end
    setCode(log.script)
end

----------------------------------------------------------------
-- ADICIONAR REMOTE
----------------------------------------------------------------
local function addLog(remoteType, remote, args)
    local id = getRemoteId(remote)
    if blacklist[id] or blacklist[remote.Name] then return end
    local blocked = blocklist[id] or blocklist[remote.Name]

    logCount += 1
    if #logs >= 300 then
        local oldest = table.remove(logs, 1)
        if oldest and oldest.item and oldest.item.Parent then
            oldest.item:Destroy()
        end
    end

    -- Item da lista (44px = touch friendly)
    local Item = frame({
        Size=UDim2.new(1,0,0,44),
        BackgroundColor3=C.item,
        LayoutOrder=logCount,
        ClipsDescendants=true,
    }, ListScroll)
    corner(7, Item)

    -- Barra lateral
    local barColor = blocked and C.red or (remoteType=="event" and C.yellow or C.accent2)
    local bar = frame({
        Size=UDim2.fromOffset(4,26),
        Position=UDim2.new(0,6,0.5,-13),
        BackgroundColor3=barColor,
    }, Item)
    corner(2, bar)

    -- Nome
    label({
        Size=UDim2.new(1,-18,0,22), Position=UDim2.new(0,18,0,3),
        Text=remote.Name, TextXAlignment=Enum.TextXAlignment.Left,
        TextTruncate=Enum.TextTruncate.AtEnd,
        Font=Enum.Font.GothamBold, TextSize=13,
        TextColor3=blocked and C.red or C.text, TextWrapped=false,
    }, Item)

    -- Subtítulo
    label({
        Size=UDim2.new(1,-18,0,16), Position=UDim2.new(0,18,0,25),
        Text=(remoteType=="event" and "Event" or "Func").." • "..#args.." args"..(blocked and " • BLOQ" or ""),
        TextXAlignment=Enum.TextXAlignment.Left,
        TextSize=10, Font=Enum.Font.Gotham,
        TextColor3=C.dim, TextWrapped=false,
    }, Item)

    -- Botão de toque transparente
    local Tap = btn({
        Size=UDim2.new(1,0,1,0),
        BackgroundTransparency=1,
        Text="", ZIndex=5,
    }, Item)

    local log = {
        remote=remote, remoteType=remoteType, args=args,
        script=nil, item=Item, id=id, blocked=blocked,
    }
    table.insert(logs, log)

    local function onTap()
        touchFeedback(Item, C.item)
        selectLog(log)
    end
    -- Conecta tanto click quanto touch
    Tap.MouseButton1Click:Connect(onTap)
    Tap.TouchTap:Connect(onTap)

    ListScroll.CanvasSize = UDim2.fromOffset(0, ListLayout.AbsoluteContentSize.Y+8)
    CountLabel.Text = #logs.." logs"
    EmptyLabel.Visible = false

    task.defer(function()
        ListScroll.CanvasPosition = Vector2.new(0,
            math.max(0, ListLayout.AbsoluteContentSize.Y - ListScroll.AbsoluteSize.Y + 8))
    end)
end

----------------------------------------------------------------
-- HOOK
----------------------------------------------------------------
local function doHook()
    if not hookmetamethod then
        warn("[RemoteSpy] hookmetamethod indisponivel.")
        return
    end
    local oldNC
    oldNC = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
        local method = getnamecallmethod()
        if typeof(self) == "Instance" and not checkcaller() then
            local isFire   = method == "FireServer"   or method == "fireServer"
            local isInvoke = method == "InvokeServer" or method == "invokeServer"
            if isFire and self:IsA("RemoteEvent") then
                local id = getRemoteId(self)
                local blocked = blocklist[id] or blocklist[self.Name]
                task.spawn(addLog, "event", cloneref(self), {...})
                if blocked then return end
            elseif isInvoke and self:IsA("RemoteFunction") then
                local id = getRemoteId(self)
                local blocked = blocklist[id] or blocklist[self.Name]
                task.spawn(addLog, "function", cloneref(self), {...})
                if blocked then return end
            end
        end
        return oldNC(self, ...)
    end))
    originalNC = oldNC
end

local function doUnhook()
    if hookmetamethod and originalNC then
        pcall(hookmetamethod, game, "__namecall", originalNC)
        originalNC = nil
    end
end

----------------------------------------------------------------
-- TOGGLE SPY
----------------------------------------------------------------
local function setSpy(active)
    spyActive = active
    if active then
        doHook()
        BtnToggle.Text = "⏸"
        BtnToggle.BackgroundColor3 = Color3.fromRGB(20,80,30)
        StatusLabel.Text = "● ON"
        StatusLabel.TextColor3 = C.green
    else
        doUnhook()
        BtnToggle.Text = "▶"
        BtnToggle.BackgroundColor3 = Color3.fromRGB(100,30,30)
        StatusLabel.Text = "● OFF"
        StatusLabel.TextColor3 = C.red
    end
end

----------------------------------------------------------------
-- AÇÕES DOS BOTÕES TOPBAR
----------------------------------------------------------------
onPress(BtnToggle, function()
    touchFeedback(BtnToggle, spyActive and Color3.fromRGB(20,80,30) or Color3.fromRGB(100,30,30))
    setSpy(not spyActive)
end)

onPress(BtnClear, function()
    touchFeedback(BtnClear, C.item)
    for _, log in ipairs(logs) do
        if log.item and log.item.Parent then log.item:Destroy() end
    end
    logs = {}
    selected = nil
    logCount = 0
    CountLabel.Text = "0 logs"
    EmptyLabel.Visible = true
    setCode("-- Logs limpos")
    InfoLabel.Text = "← Selecione um remote"
end)

onPress(BtnClose, function()
    touchFeedback(BtnClose, Color3.fromRGB(140,30,30))
    task.delay(0.1, function()
        setSpy(false)
        getgenv().__RSPY_RUNNING = false
        pcall(function() ScreenGui:Destroy() end)
    end)
end)

----------------------------------------------------------------
-- AÇÕES DO PAINEL DIREITO
----------------------------------------------------------------
local function actBtn(b, fn)
    onPress(b, function()
        touchFeedback(b, C.item)
        fn()
    end)
end

actBtn(BtnCopy, function()
    if selected and selected.script then
        pcall(setclipboard, selected.script)
        local old = BtnCopy.Text
        BtnCopy.Text = "✓ Copiado"
        task.delay(1.5, function() pcall(function() BtnCopy.Text = old end) end)
    end
end)

actBtn(BtnCopyRem, function()
    if selected then
        local ok, path = pcall(val2str, selected.remote)
        if ok then
            pcall(setclipboard, path)
            local old = BtnCopyRem.Text
            BtnCopyRem.Text = "✓ Copiado"
            task.delay(1.5, function() pcall(function() BtnCopyRem.Text = old end) end)
        end
    end
end)

actBtn(BtnRun, function()
    if selected then
        local ok, err = pcall(function()
            if selected.remote:IsA("RemoteEvent") then
                selected.remote:FireServer(table.unpack(selected.args))
            else
                selected.remote:InvokeServer(table.unpack(selected.args))
            end
        end)
        local old = BtnRun.Text
        BtnRun.Text = ok and "✓ Enviado" or "✗ Erro"
        if not ok then setCode("-- Erro ao executar:\n-- "..tostring(err)) end
        task.delay(2, function() pcall(function() BtnRun.Text = old end) end)
    end
end)

actBtn(BtnExclude, function()
    if selected then
        blacklist[selected.id] = true
        blacklist[selected.remote.Name] = true
        local old = BtnExclude.Text
        BtnExclude.Text = "✓ Excluido"
        task.delay(1.5, function() pcall(function() BtnExclude.Text = old end) end)
    end
end)

actBtn(BtnBlock, function()
    if selected then
        local id = selected.id
        if blocklist[id] then
            blocklist[id] = nil
            blocklist[selected.remote.Name] = nil
            local old = BtnBlock.Text
            BtnBlock.Text = "✓ Desbloq"
            task.delay(1.5, function() pcall(function() BtnBlock.Text = old end) end)
        else
            blocklist[id] = true
            blocklist[selected.remote.Name] = true
            local old = BtnBlock.Text
            BtnBlock.Text = "✓ Bloqueado"
            task.delay(1.5, function() pcall(function() BtnBlock.Text = old end) end)
        end
    end
end)

----------------------------------------------------------------
-- INICIA
----------------------------------------------------------------
getgenv().__RSPY_RUNNING = true
getgenv().__RSPY_STOP = function()
    pcall(setSpy, false)
    pcall(function() ScreenGui:Destroy() end)
    getgenv().__RSPY_RUNNING = false
end

setSpy(true)
print("[RemoteSpy Mobile] Pronto.")
