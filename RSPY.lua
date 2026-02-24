-- RemoteSpy v1.0 - Criado do zero
-- GUI limpa, sem bugs de freeze, click funciona

if getgenv().__RSPY_RUNNING then
    if getgenv().__RSPY_STOP then getgenv().__RSPY_STOP() end
end

----------------------------------------------------------------
-- SERVIÇOS
----------------------------------------------------------------
local Players      = cloneref(game:GetService("Players"))
local RunService   = cloneref(game:GetService("RunService"))
local TweenService = cloneref(game:GetService("TweenService"))
local UIS          = cloneref(game:GetService("UserInputService"))
local TextService  = cloneref(game:GetService("TextService"))
local CoreGui      = cloneref(game:GetService("CoreGui"))

local LocalPlayer  = Players.LocalPlayer

----------------------------------------------------------------
-- UTILITÁRIOS
----------------------------------------------------------------
local cloneref     = cloneref or function(x) return x end
local newcclosure  = newcclosure or function(f) return f end
local setclipboard = setclipboard or toclipboard or function() end

local function tween(obj, t, props)
    TweenService:Create(obj, TweenInfo.new(t, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props):Play()
end

-- Converte valor para string sem bloquear o jogo
local function val2str(v, depth)
    depth = depth or 0
    if depth > 3 then return "..." end
    local t = typeof(v)
    if t == "nil"      then return "nil"
    elseif t == "boolean" then return tostring(v)
    elseif t == "number"  then
        if v == math.huge then return "math.huge"
        elseif v == -math.huge then return "-math.huge"
        elseif v ~= v then return "0/0"
        else return tostring(v) end
    elseif t == "string"  then
        local s = v:gsub('\\','\\\\'):gsub('"','\\"'):gsub('\n','\\n'):gsub('\r','\\r'):gsub('\t','\\t')
        if #s > 200 then s = s:sub(1,200)..'..." --[[truncated]]' end
        return '"'..s..'"'
    elseif t == "Instance" then
        local ok, path = pcall(function()
            -- Constrói caminho sem loops bloqueantes
            local parts = {}
            local cur = v
            local limit = 32
            while cur and cur ~= game and limit > 0 do
                table.insert(parts, 1, cur.Name)
                cur = cur.Parent
                limit -= 1
            end
            if cur == game and #parts > 0 then
                local root = v
                local steps = #parts
                for _ = 1, steps - 1 do root = root.Parent end
                local svc = pcall(function() return game:GetService(root.ClassName) end)
                if svc and lower(root.ClassName) ~= "workspace" then
                    parts[1] = 'game:GetService("'..root.ClassName..'")'
                elseif lower(root.ClassName) == "workspace" then
                    parts[1] = "workspace"
                else
                    parts[1] = "game."..parts[1]
                end
                local result = parts[1]
                for i = 2, #parts do
                    if parts[i]:match("^[%a_][%w_]*$") then
                        result = result.."."..parts[i]
                    else
                        result = result..':FindFirstChild("'..parts[i]:gsub('"','\\"')..'")'
                    end
                end
                return result
            end
            return "game --[[unknown]]"
        end)
        return ok and path or tostring(v)
    elseif t == "Vector3"   then return ("Vector3.new(%g, %g, %g)"):format(v.X, v.Y, v.Z)
    elseif t == "Vector2"   then return ("Vector2.new(%g, %g)"):format(v.X, v.Y)
    elseif t == "CFrame"    then
        local c = {v:GetComponents()}
        return ("CFrame.new(%s)"):format(table.concat(c, ", "))
    elseif t == "Color3"    then return ("Color3.new(%g, %g, %g)"):format(v.R, v.G, v.B)
    elseif t == "UDim2"     then return ("UDim2.new(%g, %g, %g, %g)"):format(v.X.Scale, v.X.Offset, v.Y.Scale, v.Y.Offset)
    elseif t == "UDim"      then return ("UDim.new(%g, %g)"):format(v.Scale, v.Offset)
    elseif t == "BrickColor" then return ('BrickColor.new("%s")'):format(tostring(v))
    elseif t == "Enum"      then return tostring(v)
    elseif t == "EnumItem"  then return tostring(v)
    elseif t == "TweenInfo" then
        return ("TweenInfo.new(%g, %s, %s, %g, %s, %g)"):format(
            v.Time, tostring(v.EasingStyle), tostring(v.EasingDirection),
            v.RepeatCount, tostring(v.Reverses), v.DelayTime)
    elseif t == "NumberRange" then return ("NumberRange.new(%g, %g)"):format(v.Min, v.Max)
    elseif t == "Rect"      then return ("Rect.new(%g, %g, %g, %g)"):format(v.Min.X, v.Min.Y, v.Max.X, v.Max.Y)
    elseif t == "Ray"       then
        return ("Ray.new(Vector3.new(%g,%g,%g), Vector3.new(%g,%g,%g))"):format(
            v.Origin.X, v.Origin.Y, v.Origin.Z,
            v.Direction.X, v.Direction.Y, v.Direction.Z)
    elseif t == "table" then
        if depth >= 3 then return "{...}" end
        local parts = {}
        local n = 0
        for k, val in next, v do
            n += 1
            if n > 30 then parts[#parts+1] = "  --[[...more]]"; break end
            local ks = type(k) == "string" and k:match("^[%a_][%w_]*$") and k or ("["..val2str(k, depth+1).."]")
            parts[#parts+1] = "  "..ks.." = "..val2str(val, depth+1)
        end
        if #parts == 0 then return "{}" end
        return "{\n"..table.concat(parts, ",\n").."\n}"
    else
        return tostring(v)
    end
end

local lower = string.lower

local function buildScript(remote, args)
    local lines = {}
    -- Variáveis dos args
    for i, v in ipairs(args) do
        lines[#lines+1] = "local arg"..i.." = "..val2str(v)
    end
    -- Caminho do remote
    local remotePath = val2str(remote)
    -- Chamada
    local argList = {}
    for i = 1, #args do argList[#argList+1] = "arg"..i end
    local call = argList[#argList] and table.concat(argList, ", ") or ""
    if remote:IsA("RemoteEvent") then
        lines[#lines+1] = ""
        lines[#lines+1] = remotePath..":FireServer("..call..")"
    elseif remote:IsA("RemoteFunction") then
        lines[#lines+1] = ""
        lines[#lines+1] = remotePath..":InvokeServer("..call..")"
    end
    return table.concat(lines, "\n")
end

----------------------------------------------------------------
-- GUI
----------------------------------------------------------------
local COLORS = {
    bg       = Color3.fromRGB(13, 13, 18),
    panel    = Color3.fromRGB(20, 20, 28),
    sidebar  = Color3.fromRGB(16, 16, 22),
    item     = Color3.fromRGB(26, 26, 36),
    itemHov  = Color3.fromRGB(34, 34, 48),
    itemSel  = Color3.fromRGB(60, 90, 200),
    accent   = Color3.fromRGB(80, 120, 255),
    accent2  = Color3.fromRGB(120, 80, 255),
    text     = Color3.fromRGB(220, 220, 235),
    textDim  = Color3.fromRGB(120, 120, 145),
    red      = Color3.fromRGB(255, 80, 80),
    green    = Color3.fromRGB(80, 220, 120),
    yellow   = Color3.fromRGB(255, 210, 60),
    border   = Color3.fromRGB(40, 40, 58),
    code     = Color3.fromRGB(10, 12, 20),
}

local function mk(cls, props, parent)
    local o = Instance.new(cls)
    if props then
        for k, v in next, props do
            o[k] = v
        end
    end
    if parent then o.Parent = parent end
    return o
end

local function mkFrame(props, parent)
    local defaults = {BackgroundColor3 = COLORS.panel, BorderSizePixel = 0}
    for k,v in next, (props or {}) do defaults[k] = v end
    return mk("Frame", defaults, parent)
end

local function mkText(props, parent)
    local defaults = {
        BackgroundTransparency = 1,
        TextColor3 = COLORS.text,
        Font = Enum.Font.Code,
        TextSize = 13,
        BorderSizePixel = 0,
    }
    for k,v in next, (props or {}) do defaults[k] = v end
    return mk("TextLabel", defaults, parent)
end

local function mkBtn(props, parent)
    local defaults = {
        BackgroundColor3 = COLORS.item,
        BorderSizePixel = 0,
        TextColor3 = COLORS.text,
        Font = Enum.Font.GothamBold,
        TextSize = 12,
        AutoButtonColor = false,
    }
    for k,v in next, (props or {}) do defaults[k] = v end
    return mk("TextButton", defaults, parent)
end

local function corner(r, parent)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, r or 6)
    c.Parent = parent
    return c
end

local function stroke(c, t, parent)
    local s = Instance.new("UIStroke")
    s.Color = c or COLORS.border
    s.Thickness = t or 1
    s.Parent = parent
    return s
end

-- Cria o ScreenGui
local ScreenGui = mk("ScreenGui", {
    Name = "RemoteSpy_v1",
    ResetOnSpawn = false,
    IgnoreGuiInset = true,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
}, gethui and gethui() or CoreGui)

-- Janela principal
local WIN_W, WIN_H = 680, 420
local WIN_X, WIN_Y = 100, 100

local Main = mkFrame({
    Size = UDim2.fromOffset(WIN_W, WIN_H),
    Position = UDim2.fromOffset(WIN_X, WIN_Y),
    BackgroundColor3 = COLORS.bg,
    ClipsDescendants = true,
}, ScreenGui)
corner(10, Main)
stroke(COLORS.border, 1, Main)

-- Gradiente sutil na borda superior
local topGrad = mk("Frame", {
    Size = UDim2.new(1, 0, 0, 2),
    Position = UDim2.new(0,0,0,0),
    BackgroundColor3 = COLORS.accent,
    BorderSizePixel = 0,
    ZIndex = 10,
}, Main)
mk("UIGradient", {
    Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, COLORS.accent),
        ColorSequenceKeypoint.new(1, COLORS.accent2),
    }),
}, topGrad)

-- Topbar
local TopBar = mkFrame({
    Size = UDim2.new(1, 0, 0, 38),
    Position = UDim2.new(0,0,0,2),
    BackgroundColor3 = COLORS.bg,
}, Main)

local TitleLabel = mkText({
    Size = UDim2.new(1, -120, 1, 0),
    Position = UDim2.new(0, 14, 0, 0),
    Text = "⬡  RemoteSpy",
    TextXAlignment = Enum.TextXAlignment.Left,
    Font = Enum.Font.GothamBold,
    TextSize = 14,
    TextColor3 = COLORS.text,
}, TopBar)

-- Botões topbar
local function mkTopBtn(icon, xOff, color)
    local b = mkBtn({
        Size = UDim2.fromOffset(28, 28),
        Position = UDim2.new(1, xOff, 0.5, -14),
        Text = icon,
        TextSize = 14,
        BackgroundColor3 = color or COLORS.item,
        TextColor3 = COLORS.text,
    }, TopBar)
    corner(6, b)
    return b
end

local BtnClose   = mkTopBtn("✕", -10, Color3.fromRGB(50,20,20))
local BtnClear   = mkTopBtn("🗑", -44, COLORS.item)
local BtnToggle  = mkTopBtn("●", -78, COLORS.item) -- verde=on, cinza=off

-- Divisor
mkFrame({Size=UDim2.new(1,0,0,1), Position=UDim2.new(0,0,0,40), BackgroundColor3=COLORS.border}, Main)

-- Layout principal (sidebar + codebox)
local Content = mkFrame({
    Size = UDim2.new(1, 0, 1, -41),
    Position = UDim2.new(0, 0, 0, 41),
    BackgroundTransparency = 1,
}, Main)

-- SIDEBAR - lista de remotes
local Sidebar = mkFrame({
    Size = UDim2.new(0, 210, 1, 0),
    BackgroundColor3 = COLORS.sidebar,
}, Content)

-- Header sidebar
local SideHeader = mkFrame({
    Size = UDim2.new(1, 0, 0, 30),
    BackgroundColor3 = COLORS.bg,
}, Sidebar)
mkText({
    Size = UDim2.new(1, -10, 1, 0),
    Position = UDim2.new(0, 10, 0, 0),
    Text = "REMOTES",
    TextXAlignment = Enum.TextXAlignment.Left,
    TextSize = 10,
    Font = Enum.Font.GothamBold,
    TextColor3 = COLORS.textDim,
    TextColor3 = COLORS.accent,
}, SideHeader)

local CountLabel = mkText({
    Size = UDim2.new(0, 40, 1, 0),
    Position = UDim2.new(1, -44, 0, 0),
    Text = "0",
    TextXAlignment = Enum.TextXAlignment.Right,
    TextSize = 10,
    Font = Enum.Font.GothamBold,
    TextColor3 = COLORS.textDim,
}, SideHeader)

-- Lista scrollable
local ListFrame = mk("ScrollingFrame", {
    Size = UDim2.new(1, 0, 1, -30),
    Position = UDim2.new(0, 0, 0, 30),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    ScrollBarThickness = 3,
    ScrollBarImageColor3 = COLORS.accent,
    CanvasSize = UDim2.new(0, 0, 0, 0),
}, Sidebar)

local ListLayout = mk("UIListLayout", {
    SortOrder = Enum.SortOrder.LayoutOrder,
    Padding = UDim.new(0, 2),
}, ListFrame)

mk("UIPadding", {
    PaddingLeft   = UDim.new(0, 4),
    PaddingRight  = UDim.new(0, 4),
    PaddingTop    = UDim.new(0, 4),
    PaddingBottom = UDim.new(0, 4),
}, ListFrame)

-- Divisor vertical
mkFrame({
    Size = UDim2.new(0, 1, 1, 0),
    Position = UDim2.new(0, 210, 0, 0),
    BackgroundColor3 = COLORS.border,
}, Content)

-- PAINEL DIREITO - código gerado
local RightPanel = mkFrame({
    Size = UDim2.new(1, -211, 1, 0),
    Position = UDim2.new(0, 211, 0, 0),
    BackgroundColor3 = COLORS.bg,
}, Content)

-- Botões de ação no topo do painel direito
local ActionBar = mkFrame({
    Size = UDim2.new(1, 0, 0, 36),
    BackgroundColor3 = COLORS.bg,
}, RightPanel)

local function mkAction(lbl, xPos)
    local b = mkBtn({
        Size = UDim2.fromOffset(100, 26),
        Position = UDim2.new(0, xPos, 0.5, -13),
        Text = lbl,
        TextSize = 11,
        Font = Enum.Font.GothamBold,
        BackgroundColor3 = COLORS.item,
        TextColor3 = COLORS.text,
    }, ActionBar)
    corner(5, b)
    stroke(COLORS.border, 1, b)
    b.MouseEnter:Connect(function() tween(b, 0.15, {BackgroundColor3 = COLORS.itemHov}) end)
    b.MouseLeave:Connect(function() tween(b, 0.15, {BackgroundColor3 = COLORS.item}) end)
    return b
end

local BtnCopy    = mkAction("📋  Copy Code", 8)
local BtnCopyRem = mkAction("🔗  Copy Remote", 116)
local BtnRunCode = mkAction("▶  Run", 224)
local BtnExclude = mkAction("🚫  Exclude", 332)
local BtnBlock   = mkAction("🔒  Block", 440)

mkFrame({Size=UDim2.new(1,0,0,1), Position=UDim2.new(0,0,0,36), BackgroundColor3=COLORS.border}, RightPanel)

-- Info bar (nome do remote, tipo, nº de args)
local InfoBar = mkFrame({
    Size = UDim2.new(1, 0, 0, 26),
    Position = UDim2.new(0, 0, 0, 37),
    BackgroundColor3 = COLORS.panel,
}, RightPanel)

local InfoLabel = mkText({
    Size = UDim2.new(1, -10, 1, 0),
    Position = UDim2.new(0, 10, 0, 0),
    Text = "Selecione um remote na lista →",
    TextXAlignment = Enum.TextXAlignment.Left,
    TextSize = 11,
    TextColor3 = COLORS.textDim,
}, InfoBar)

mkFrame({Size=UDim2.new(1,0,0,1), Position=UDim2.new(0,0,1,-1), BackgroundColor3=COLORS.border}, InfoBar)

-- Caixa de código
local CodeScroll = mk("ScrollingFrame", {
    Size = UDim2.new(1, 0, 1, -64),
    Position = UDim2.new(0, 0, 0, 64),
    BackgroundColor3 = COLORS.code,
    BorderSizePixel = 0,
    ScrollBarThickness = 4,
    ScrollBarImageColor3 = COLORS.accent,
    CanvasSize = UDim2.new(0, 0, 0, 0),
}, RightPanel)

mk("UIPadding", {
    PaddingAll = UDim.new(0, 12),
}, CodeScroll)

local CodeLabel = mk("TextLabel", {
    Size = UDim2.new(1, -24, 1, -24),
    BackgroundTransparency = 1,
    TextColor3 = Color3.fromRGB(180, 200, 255),
    Font = Enum.Font.Code,
    TextSize = 13,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextYAlignment = Enum.TextYAlignment.Top,
    TextWrapped = false,
    RichText = false,
    Text = "-- Nenhum remote selecionado",
}, CodeScroll)

local function setCode(str)
    CodeLabel.Text = str or ""
    -- Ajusta canvas ao texto
    local sz = TextService:GetTextSize(
        str or "",
        CodeLabel.TextSize,
        CodeLabel.Font,
        Vector2.new(math.huge, math.huge)
    )
    CodeScroll.CanvasSize = UDim2.fromOffset(
        math.max(sz.X + 24, CodeScroll.AbsoluteSize.X),
        math.max(sz.Y + 24, CodeScroll.AbsoluteSize.Y)
    )
end

-- Estado vazio
local EmptyLabel = mkText({
    Size = UDim2.new(1, 0, 1, 0),
    Text = "Nenhum remote capturado ainda.\nAtive o spy e use o jogo.",
    TextColor3 = COLORS.textDim,
    TextSize = 13,
    Font = Enum.Font.Gotham,
    TextWrapped = true,
}, ListFrame)

----------------------------------------------------------------
-- DRAG
----------------------------------------------------------------
do
    local dragging, dragStart, startPos
    TopBar.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging  = true
            dragStart = inp.Position
            startPos  = Main.Position
        end
    end)
    UIS.InputChanged:Connect(function(inp)
        if dragging and inp.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = inp.Position - dragStart
            Main.Position = UDim2.fromOffset(
                startPos.X.Offset + delta.X,
                startPos.Y.Offset + delta.Y
            )
        end
    end)
    UIS.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
end

----------------------------------------------------------------
-- ESTADO
----------------------------------------------------------------
local spyActive  = false
local logs       = {}        -- {remote, remoteType, args, script, frame, btn}
local selected   = nil
local blacklist  = {}        -- id -> true (excluídos)
local blocklist  = {}        -- id -> true (bloqueados)
local logCount   = 0
local originalNC = nil
local originalFire   = nil
local originalInvoke = nil

local function getRemoteId(remote)
    local ok, id = pcall(game.GetDebugId, game, remote)
    return ok and id or tostring(remote)
end

----------------------------------------------------------------
-- SELECIONAR LOG
----------------------------------------------------------------
local function selectLog(log)
    -- Deseleciona anterior
    if selected then
        tween(selected.btn, 0.15, {BackgroundColor3 = COLORS.item})
    end
    selected = log
    tween(log.btn, 0.15, {BackgroundColor3 = COLORS.itemSel})

    -- Info
    local typeStr = log.remoteType == "event" and "RemoteEvent" or "RemoteFunction"
    InfoLabel.Text = ("  %s  •  %s  •  %d args"):format(log.remote.Name, typeStr, #log.args)

    -- Gera script (sem bloquear - é rápido pois não tem wait)
    if not log.script then
        local ok, result = pcall(buildScript, log.remote, log.args)
        log.script = ok and result or ("-- Erro ao gerar script:\n-- "..tostring(result))
    end
    setCode(log.script)
end

----------------------------------------------------------------
-- ADICIONAR REMOTE À LISTA
----------------------------------------------------------------
local function addLog(remoteType, remote, args)
    local id = getRemoteId(remote)

    -- Verifica blacklist/blocklist
    if blacklist[id] or blacklist[remote.Name] then return end
    local blocked = blocklist[id] or blocklist[remote.Name]

    logCount += 1
    if logCount > 500 then
        -- Remove o mais antigo
        local oldest = table.remove(logs, 1)
        if oldest and oldest.frame and oldest.frame.Parent then
            oldest.frame:Destroy()
        end
    end

    -- Cria item na lista
    local Item = mkFrame({
        Size = UDim2.new(1, 0, 0, 34),
        BackgroundColor3 = COLORS.item,
        LayoutOrder = logCount,
        ClipsDescendants = true,
    }, ListFrame)
    corner(5, Item)

    -- Barra colorida lateral
    local barColor = remoteType == "event" and COLORS.yellow or COLORS.accent2
    mkFrame({
        Size = UDim2.fromOffset(3, 20),
        Position = UDim2.new(0, 6, 0.5, -10),
        BackgroundColor3 = blocked and COLORS.red or barColor,
    }, Item)

    -- Nome
    mkText({
        Size = UDim2.new(1, -20, 0, 18),
        Position = UDim2.new(0, 16, 0, 4),
        Text = remote.Name,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Font = Enum.Font.GothamBold,
        TextSize = 12,
        TextColor3 = blocked and COLORS.red or COLORS.text,
    }, Item)

    -- Subtítulo: tipo + args
    mkText({
        Size = UDim2.new(1, -20, 0, 14),
        Position = UDim2.new(0, 16, 0, 20),
        Text = (remoteType == "event" and "Event" or "Function").." • "..#args.." args"..(blocked and " • BLOQUEADO" or ""),
        TextXAlignment = Enum.TextXAlignment.Left,
        TextSize = 10,
        Font = Enum.Font.Gotham,
        TextColor3 = COLORS.textDim,
    }, Item)

    -- Botão invisível por cima
    local Btn = mkBtn({
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Text = "",
    }, Item)

    local log = {
        remote     = remote,
        remoteType = remoteType,
        args       = args,
        script     = nil,
        frame      = Item,
        btn        = Btn,
        id         = id,
        blocked    = blocked,
    }
    table.insert(logs, log)

    -- Hover
    Btn.MouseEnter:Connect(function()
        if selected ~= log then
            tween(Item, 0.12, {BackgroundColor3 = COLORS.itemHov})
        end
    end)
    Btn.MouseLeave:Connect(function()
        if selected ~= log then
            tween(Item, 0.12, {BackgroundColor3 = COLORS.item})
        end
    end)

    -- Click - simplesmente seleciona, sem nada bloqueante
    Btn.MouseButton1Click:Connect(function()
        selectLog(log)
    end)

    -- Atualiza canvas da lista
    ListFrame.CanvasSize = UDim2.fromOffset(0, ListLayout.AbsoluteContentSize.Y + 8)
    CountLabel.Text = tostring(#logs)

    -- Esconde label vazio
    EmptyLabel.Visible = false

    -- Auto-scroll para o novo item
    ListFrame.CanvasPosition = Vector2.new(0, math.max(0, ListLayout.AbsoluteContentSize.Y - ListFrame.AbsoluteSize.Y + 8))
end

----------------------------------------------------------------
-- HOOK / UNHOOK
----------------------------------------------------------------
local function doHook()
    -- Hook __namecall
    local oldNC
    if hookmetamethod then
        oldNC = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
            local method = getnamecallmethod()
            if typeof(self) == "Instance" then
                if (method == "FireServer" or method == "fireServer") and self:IsA("RemoteEvent") then
                    if not checkcaller() then
                        local id = getRemoteId(self)
                        if not blocklist[id] and not blocklist[self.Name] then
                            task.spawn(addLog, "event", cloneref(self), table.pack(...) and {table.unpack({...})} or {...})
                        else
                            task.spawn(addLog, "event", cloneref(self), {...})
                            return -- bloqueia
                        end
                    end
                elseif (method == "InvokeServer" or method == "invokeServer") and self:IsA("RemoteFunction") then
                    if not checkcaller() then
                        local id = getRemoteId(self)
                        if not blocklist[id] and not blocklist[self.Name] then
                            task.spawn(addLog, "function", cloneref(self), {...})
                        else
                            task.spawn(addLog, "function", cloneref(self), {...})
                            return
                        end
                    end
                end
            end
            return oldNC(self, ...)
        end))
        originalNC = oldNC
    end
end

local function doUnhook()
    if hookmetamethod and originalNC then
        hookmetamethod(game, "__namecall", originalNC)
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
        tween(BtnToggle, 0.2, {BackgroundColor3 = Color3.fromRGB(20,50,20), TextColor3 = COLORS.green})
        BtnToggle.Text = "●"
        TitleLabel.Text = "⬡  RemoteSpy  •  ON"
    else
        doUnhook()
        tween(BtnToggle, 0.2, {BackgroundColor3 = COLORS.item, TextColor3 = COLORS.textDim})
        BtnToggle.Text = "●"
        TitleLabel.Text = "⬡  RemoteSpy  •  OFF"
    end
end

----------------------------------------------------------------
-- BOTÕES DE AÇÃO
----------------------------------------------------------------
BtnToggle.MouseButton1Click:Connect(function()
    setSpy(not spyActive)
end)

BtnClear.MouseButton1Click:Connect(function()
    for _, log in ipairs(logs) do
        if log.frame and log.frame.Parent then
            log.frame:Destroy()
        end
    end
    logs = {}
    selected = nil
    logCount = 0
    CountLabel.Text = "0"
    EmptyLabel.Visible = true
    setCode("-- Logs limpos")
    InfoLabel.Text = "Selecione um remote na lista →"
end)

BtnClose.MouseButton1Click:Connect(function()
    setSpy(false)
    getgenv().__RSPY_RUNNING = false
    ScreenGui:Destroy()
end)

BtnCopy.MouseButton1Click:Connect(function()
    if selected and selected.script then
        setclipboard(selected.script)
        BtnCopy.Text = "✓  Copiado!"
        task.delay(1.5, function() BtnCopy.Text = "📋  Copy Code" end)
    end
end)

BtnCopyRem.MouseButton1Click:Connect(function()
    if selected then
        local ok, path = pcall(val2str, selected.remote)
        if ok then
            setclipboard(path)
            BtnCopyRem.Text = "✓  Copiado!"
            task.delay(1.5, function() BtnCopyRem.Text = "🔗  Copy Remote" end)
        end
    end
end)

BtnRunCode.MouseButton1Click:Connect(function()
    if selected then
        local ok, err = pcall(function()
            if selected.remote:IsA("RemoteEvent") then
                selected.remote:FireServer(table.unpack(selected.args))
            else
                selected.remote:InvokeServer(table.unpack(selected.args))
            end
        end)
        if ok then
            BtnRunCode.Text = "✓  Enviado!"
        else
            BtnRunCode.Text = "✗  Erro"
            setCode("-- Erro ao executar:\n-- "..tostring(err))
        end
        task.delay(2, function() BtnRunCode.Text = "▶  Run" end)
    end
end)

BtnExclude.MouseButton1Click:Connect(function()
    if selected then
        blacklist[selected.id] = true
        BtnExclude.Text = "✓  Excluído!"
        task.delay(1.5, function() BtnExclude.Text = "🚫  Exclude" end)
    end
end)

BtnBlock.MouseButton1Click:Connect(function()
    if selected then
        if blocklist[selected.id] then
            blocklist[selected.id] = nil
            BtnBlock.Text = "✓  Desbloqueado"
        else
            blocklist[selected.id] = true
            BtnBlock.Text = "✓  Bloqueado!"
        end
        task.delay(1.5, function() BtnBlock.Text = "🔒  Block" end)
    end
end)

-- Hover nos botões topbar
for _, b in ipairs({BtnClose, BtnClear, BtnToggle}) do
    b.MouseEnter:Connect(function()
        tween(b, 0.12, {BackgroundTransparency = 0.3})
    end)
    b.MouseLeave:Connect(function()
        tween(b, 0.12, {BackgroundTransparency = 0})
    end)
end

----------------------------------------------------------------
-- INICIA
----------------------------------------------------------------
getgenv().__RSPY_RUNNING = true
getgenv().__RSPY_STOP = function()
    setSpy(false)
    pcall(function() ScreenGui:Destroy() end)
    getgenv().__RSPY_RUNNING = false
end

-- Liga o spy ao iniciar
setSpy(true)

print("[RemoteSpy] Carregado. Clique nos remotes da lista para ver o script gerado.")
