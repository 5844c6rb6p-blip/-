--!nonstrict
--[[
    CustomUI  v1.0.0
    Obsidian風の自作UIライブラリ（単一ファイル完結）
    
    使い方:
        local Library = loadstring(game:HttpGet("URL/Library.lua"))()
        local Window = Library:CreateWindow({ Title = "MyHUB" })
]]

local Players          = game:GetService("Players")
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local HttpService      = game:GetService("HttpService")
local CoreGui          = game:GetService("CoreGui")
local PlayerGui        = Players.LocalPlayer:WaitForChild("PlayerGui")

-- ================================================================
--  Theme
-- ================================================================
local Theme = {
    Bg         = Color3.fromRGB(20, 20, 26),
    Surface    = Color3.fromRGB(30, 30, 38),
    SurfaceAlt = Color3.fromRGB(44, 44, 56),
    Accent     = Color3.fromRGB(120, 90, 255),
    AccentDark = Color3.fromRGB(90, 65, 200),
    Text       = Color3.fromRGB(235, 235, 240),
    TextDim    = Color3.fromRGB(150, 150, 165),
    Stroke     = Color3.fromRGB(55, 55, 70),
    Danger     = Color3.fromRGB(220, 70, 70),
    Success    = Color3.fromRGB(80, 200, 120),
    Font       = Enum.Font.GothamMedium,
    FontBold   = Enum.Font.GothamBold,
    Radius     = 8,
}

-- ================================================================
--  Util
-- ================================================================
local Util = {}

function Util.new(class, props, children)
    local inst = Instance.new(class)
    for k, v in pairs(props or {}) do inst[k] = v end
    for _, c in ipairs(children or {}) do c.Parent = inst end
    return inst
end

function Util.corner(parent, r)
    return Util.new("UICorner", { CornerRadius = UDim.new(0, r or Theme.Radius), Parent = parent })
end

function Util.stroke(parent, color, thick)
    return Util.new("UIStroke", {
        Color = color or Theme.Stroke, Thickness = thick or 1,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = parent,
    })
end

function Util.pad(parent, p)
    return Util.new("UIPadding", {
        PaddingLeft = UDim.new(0, p), PaddingRight = UDim.new(0, p),
        PaddingTop = UDim.new(0, p), PaddingBottom = UDim.new(0, p),
        Parent = parent,
    })
end

function Util.tween(inst, dur, props, style, dir)
    TweenService:Create(inst,
        TweenInfo.new(dur or 0.15, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out),
        props):Play()
end

function Util.drag(frame, handle)
    handle = handle or frame
    local dragging, dragStart, startPos
    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging  = true
            dragStart = input.Position
            startPos  = frame.Position
            local c; c = input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                    if c then c:Disconnect() end
                end
            end)
        end
    end)
    handle.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
                      or input.UserInputType == Enum.UserInputType.Touch) then
            local d = input.Position - dragStart
            frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X,
                                       startPos.Y.Scale, startPos.Y.Offset + d.Y)
        end
    end)
end

-- ================================================================
--  Library
-- ================================================================
local Library = {
    Theme    = Theme,
    Flags    = {},
    Elements = {},
    Windows  = {},
}

function Library:CreateWindow(opts)
    opts = opts or {}
    local win = { Tabs = {}, Order = 0 }

    local gui = Util.new("ScreenGui", {
        Name = "CustomUI", ResetOnSpawn = false,
        IgnoreGuiInset = true, ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        Parent = (pcall(function() return CoreGui end) and CoreGui) or PlayerGui,
    })

    local main = Util.new("Frame", {
        Size = UDim2.fromOffset(540, 360),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = Theme.Bg, BorderSizePixel = 0,
        ClipsDescendants = true, Parent = gui,
    })
    Util.corner(main, 10)
    Util.stroke(main, Theme.Stroke)

    -- タイトルバー
    local titleBar = Util.new("Frame", {
        Size = UDim2.new(1, 0, 0, 34),
        BackgroundColor3 = Theme.Surface, BorderSizePixel = 0, Parent = main,
    })
    Util.new("TextLabel", {
        Text = opts.Title or "CustomUI",
        Font = Theme.FontBold, TextSize = 15, TextColor3 = Theme.Text,
        BackgroundTransparency = 1, Position = UDim2.fromOffset(14, 0),
        Size = UDim2.new(1, -140, 1, 0),
        TextXAlignment = Enum.TextXAlignment.Left, Parent = titleBar,
    })
    Util.new("TextLabel", {
        Text = opts.Footer or "v1.0.0",
        Font = Theme.Font, TextSize = 11, TextColor3 = Theme.TextDim,
        BackgroundTransparency = 1, Position = UDim2.new(1, -80, 0, 0),
        Size = UDim2.fromOffset(60, 34),
        TextXAlignment = Enum.TextXAlignment.Right, Parent = titleBar,
    })
    local closeBtn = Util.new("TextButton", {
        Text = "×", Font = Theme.FontBold, TextSize = 16,
        TextColor3 = Theme.TextDim, BackgroundColor3 = Theme.SurfaceAlt,
        BorderSizePixel = 0, Position = UDim2.new(1, -30, 0.5, 0),
        AnchorPoint = Vector2.new(0, 0.5), Size = UDim2.fromOffset(22, 22),
        AutoButtonColor = false, Parent = titleBar,
    })
    Util.corner(closeBtn, 6)
    closeBtn.MouseEnter:Connect(function() Util.tween(closeBtn, .1, { BackgroundColor3 = Theme.Danger, TextColor3 = Theme.Text }) end)
    closeBtn.MouseLeave:Connect(function() Util.tween(closeBtn, .1, { BackgroundColor3 = Theme.SurfaceAlt, TextColor3 = Theme.TextDim }) end)
    closeBtn.MouseButton1Click:Connect(function() main.Visible = false end)
    Util.drag(main, titleBar)

    -- タブバー
    local tabBar = Util.new("Frame", {
        Size = UDim2.new(0, 140, 1, -34),
        Position = UDim2.fromOffset(0, 34),
        BackgroundColor3 = Theme.Bg, BorderSizePixel = 0, Parent = main,
    })
    Util.new("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder, Parent = tabBar })
    Util.pad(tabBar, 8)

    -- コンテンツ
    local content = Util.new("Frame", {
        Size = UDim2.new(1, -140, 1, -34),
        Position = UDim2.fromOffset(140, 34),
        BackgroundColor3 = Theme.Bg, BorderSizePixel = 0, Parent = main,
    })
    Util.pad(content, 12)

    -- Notify コンテナ
    local notifyFrame = Util.new("Frame", {
        Size = UDim2.new(0, 280, 1, -40),
        Position = UDim2.new(1, -300, 0, 20),
        BackgroundTransparency = 1, Parent = gui,
    })
    Util.new("UIListLayout", {
        Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder,
        VerticalAlignment = Enum.VerticalAlignment.Bottom, Parent = notifyFrame,
    })

    win.Gui, win.Main, win.TabBar, win.Content, win.NotifyFrame =
        gui, main, tabBar, content, notifyFrame

    -- 右Shift で表示切替
    UserInputService.InputBegan:Connect(function(input, gpe)
        if gpe then return end
        if input.KeyCode == Enum.KeyCode.RightShift then
            main.Visible = not main.Visible
        end
    end)

    function win:SelectTab(index)
        for i, tab in ipairs(self.Tabs) do
            local active = (i == index)
            Util.tween(tab.Button, 0.15, {
                BackgroundColor3 = active and Theme.Accent or Theme.Surface,
                TextColor3       = active and Theme.Text or Theme.TextDim,
            })
            tab.Page.Visible = active
        end
    end

    function win:Notify(o)
        o = o or {}
        local card = Util.new("Frame", {
            Size = UDim2.new(1, 0, 0, 52),
            BackgroundColor3 = Theme.Surface, BorderSizePixel = 0,
            BackgroundTransparency = 1, Parent = notifyFrame,
        })
        Util.corner(card, 8)
        local strk = Util.stroke(card, Theme.Stroke)
        strk.Transparency = 1
        local bar = Util.new("Frame", {
            Size = UDim2.new(0, 3, 1, -12),
            Position = UDim2.fromOffset(6, 6),
            BackgroundColor3 = o.Color or Theme.Accent,
            BorderSizePixel = 0, BackgroundTransparency = 1, Parent = card,
        })
        Util.corner(bar, 2)
        local t1 = Util.new("TextLabel", {
            Text = o.Title or "Notification", Font = Theme.FontBold, TextSize = 13,
            TextColor3 = Theme.Text, BackgroundTransparency = 1, TextTransparency = 1,
            Position = UDim2.fromOffset(16, 6), Size = UDim2.new(1, -24, 0, 18),
            TextXAlignment = Enum.TextXAlignment.Left, Parent = card,
        })
        local t2 = Util.new("TextLabel", {
            Text = o.Text or "", Font = Theme.Font, TextSize = 11,
            TextColor3 = Theme.TextDim, BackgroundTransparency = 1, TextTransparency = 1,
            Position = UDim2.fromOffset(16, 24), Size = UDim2.new(1, -24, 0, 22),
            TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true, Parent = card,
        })
        Util.tween(card, 0.2, { BackgroundTransparency = 0 })
        Util.tween(strk, 0.2, { Transparency = 0 })
        Util.tween(bar, 0.2, { BackgroundTransparency = 0 })
        Util.tween(t1, 0.2, { TextTransparency = 0 })
        Util.tween(t2, 0.2, { TextTransparency = 0 })

        task.delay(o.Duration or 3, function()
            Util.tween(card, 0.2, { BackgroundTransparency = 1 })
            Util.tween(strk, 0.2, { Transparency = 1 })
            Util.tween(bar, 0.2, { BackgroundTransparency = 1 })
            Util.tween(t1, 0.2, { TextTransparency = 1 })
            Util.tween(t2, 0.2, { TextTransparency = 1 })
            task.wait(0.25); card:Destroy()
        end)
    end

    function win:CreateTab(name)
        local tab = {}
        self.Order = self.Order + 1
        local order = self.Order

        local btn = Util.new("TextButton", {
            Size = UDim2.new(1, 0, 0, 32),
            BackgroundColor3 = Theme.Surface,
            Text = "  " .. name, Font = Theme.Font, TextSize = 13,
            TextColor3 = Theme.TextDim, TextXAlignment = Enum.TextXAlignment.Left,
            AutoButtonColor = false, LayoutOrder = order, Parent = tabBar,
        })
        Util.corner(btn, 6)

        local page = Util.new("ScrollingFrame", {
            Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1,
            BorderSizePixel = 0, ScrollBarThickness = 2,
            ScrollBarImageColor3 = Theme.SurfaceAlt,
            CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y,
            Visible = false, Parent = content,
        })
        Util.new("UIListLayout", {
            Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder, Parent = page,
        })

        btn.MouseButton1Click:Connect(function() self:SelectTab(order) end)

        tab.Button, tab.Page = btn, page
        table.insert(self.Tabs, tab)
        if #self.Tabs == 1 then self:SelectTab(1) end

        function tab:CreateSection(title)
            return Util.new("TextLabel", {
                Text = title, Font = Theme.FontBold, TextSize = 13,
                TextColor3 = Theme.Text, BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 22),
                TextXAlignment = Enum.TextXAlignment.Left, Parent = page,
            })
        end
        function tab:CreateToggle(o)   return Library:_Toggle(page, o)   end
        function tab:CreateSlider(o)   return Library:_Slider(page, o)   end
        function tab:CreateButton(o)   return Library:_Button(page, o)   end
        function tab:CreateTextbox(o)  return Library:_Textbox(page, o)  end
        function tab:CreateDropdown(o) return Library:_Dropdown(page, o) end
        function tab:CreateKeybind(o)  return Library:_Keybind(page, o)  end
        function tab:CreateColorPicker(o) return Library:_ColorPicker(page, o) end
        return tab
    end

    function win:SaveConfig(path)
        if writefile then
            writefile(path or "customui_config.json", HttpService:JSONEncode(Library.Flags))
        end
    end
    function win:LoadConfig(path)
        path = path or "customui_config.json"
        if isfile and isfile(path) then
            local data = HttpService:JSONDecode(readfile(path))
            for flag, v in pairs(data) do
                local el = Library.Elements[flag]
                if el and el.Set then el:Set(v) end
            end
        end
    end

    table.insert(Library.Windows, win)
    return win
end

-- ================================================================
--  要素実装
-- ================================================================
function Library:_row(parent, height)
    local row = Util.new("Frame", {
        Size = UDim2.new(1, 0, 0, height or 32),
        BackgroundColor3 = Theme.Surface, BorderSizePixel = 0, Parent = parent,
    })
    Util.corner(row, 6); Util.pad(row, 8)
    return row
end

-- Toggle
function Library:_Toggle(page, o)
    o = o or {}
    local row = self:_row(page, 32)
    Util.new("TextLabel", {
        Text = o.Title or "Toggle", Font = Theme.Font, TextSize = 13,
        TextColor3 = Theme.Text, BackgroundTransparency = 1,
        Size = UDim2.new(1, -50, 1, 0),
        TextXAlignment = Enum.TextXAlignment.Left, Parent = row,
    })
    local sw = Util.new("Frame", {
        Size = UDim2.fromOffset(34, 18), Position = UDim2.new(1, -34, .5, 0),
        AnchorPoint = Vector2.new(0, .5), BackgroundColor3 = Theme.SurfaceAlt,
        BorderSizePixel = 0, Parent = row,
    })
    Util.corner(sw, 9)
    local knob = Util.new("Frame", {
        Size = UDim2.fromOffset(14, 14), Position = UDim2.fromOffset(2, 2),
        BackgroundColor3 = Theme.Text, BorderSizePixel = 0, Parent = sw,
    })
    Util.corner(knob, 7)
    local hit = Util.new("TextButton", {
        Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1,
        Text = "", Parent = row,
    })
    local t = { Value = o.CurrentValue or false, Flag = o.Flag, Callback = o.Callback }
    function t:_render()
        Util.tween(sw, 0.15, { BackgroundColor3 = self.Value and Theme.Accent or Theme.SurfaceAlt })
        Util.tween(knob, 0.15, {
            Position = self.Value and UDim2.fromOffset(18, 2) or UDim2.fromOffset(2, 2),
        })
    end
    function t:Set(v)
        self.Value = v; self:_render()
        if self.Flag then Library.Flags[self.Flag] = v end
        if self.Callback then self.Callback(v) end
    end
    function t:Get() return self.Value end
    t:_render()
    hit.MouseButton1Click:Connect(function() t:Set(not t.Value) end)
    if t.Flag then Library.Elements[t.Flag] = t end
    return t
end

-- Slider
function Library:_Slider(page, o)
    o = o or {}
    local row = self:_row(page, 44)
    local range = o.Range or { 0, 100 }
    local min, max = range[1], range[2]
    local suffix = o.Suffix or ""
    local val = o.CurrentValue or min
    local inc = o.Increment or 1

    Util.new("TextLabel", {
        Text = o.Title or "Slider", Font = Theme.Font, TextSize = 13,
        TextColor3 = Theme.Text, BackgroundTransparency = 1,
        Size = UDim2.new(1, -60, 0, 18),
        TextXAlignment = Enum.TextXAlignment.Left, Parent = row,
    })
    local valueLbl = Util.new("TextLabel", {
        Text = tostring(val) .. suffix, Font = Theme.Font, TextSize = 12,
        TextColor3 = Theme.TextDim, BackgroundTransparency = 1,
        Size = UDim2.new(0, 55, 0, 18), Position = UDim2.new(1, -55, 0, 0),
        TextXAlignment = Enum.TextXAlignment.Right, Parent = row,
    })
    local barBg = Util.new("Frame", {
        Size = UDim2.new(1, 0, 0, 4), Position = UDim2.new(0, 0, 1, -8),
        BackgroundColor3 = Theme.SurfaceAlt, BorderSizePixel = 0, Parent = row,
    })
    Util.corner(barBg, 2)
    local pct0 = (val - min) / (max - min)
    local fill = Util.new("Frame", {
        Size = UDim2.new(pct0, 0, 1, 0),
        BackgroundColor3 = Theme.Accent, BorderSizePixel = 0, Parent = barBg,
    })
    Util.corner(fill, 2)
    local knob = Util.new("Frame", {
        Size = UDim2.fromOffset(12, 12), Position = UDim2.new(pct0, 0, .5, 0),
        AnchorPoint = Vector2.new(.5, .5), BackgroundColor3 = Theme.Text,
        BorderSizePixel = 0, Parent = barBg,
    })
    Util.corner(knob, 6)

    local s = { Value = val, Flag = o.Flag, Callback = o.Callback }
    local function apply(px)
        local w = barBg.AbsoluteSize.X
        if w <= 0 then return end
        local pct = math.clamp(px / w, 0, 1)
        local newVal = math.floor((min + (max - min) * pct) / inc + 0.5) * inc
        newVal = math.clamp(newVal, min, max)
        s.Value = newVal
        fill.Size = UDim2.new(pct, 0, 1, 0)
        knob.Position = UDim2.new(pct, 0, .5, 0)
        valueLbl.Text = tostring(newVal) .. suffix
        if s.Flag then Library.Flags[s.Flag] = newVal end
        if s.Callback then s.Callback(newVal) end
    end
    local dragging = false
    barBg.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            apply(input.Position.X - barBg.AbsolutePosition.X)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
                      or input.UserInputType == Enum.UserInputType.Touch) then
            apply(input.Position.X - barBg.AbsolutePosition.X)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    function s:Set(v)
        local function go() apply(((v - min) / (max - min)) * barBg.AbsoluteSize.X) end
        if barBg.AbsoluteSize.X > 0 then go() else task.defer(go) end
    end
    function s:Get() return self.Value end
    if s.Flag then Library.Elements[s.Flag] = s end
    return s
end

-- Button
function Library:_Button(page, o)
    o = o or {}
    local btn = Util.new("TextButton", {
        Size = UDim2.new(1, 0, 0, 32), BackgroundColor3 = Theme.Surface,
        Text = o.Title or "Button", Font = Theme.Font, TextSize = 13,
        TextColor3 = Theme.Text, AutoButtonColor = false, Parent = page,
    })
    Util.corner(btn, 6)
    btn.MouseEnter:Connect(function() Util.tween(btn, .1, { BackgroundColor3 = Theme.SurfaceAlt }) end)
    btn.MouseLeave:Connect(function() Util.tween(btn, .1, { BackgroundColor3 = Theme.Surface }) end)
    btn.MouseButton1Click:Connect(function() if o.Callback then o.Callback() end end)
    return btn
end

-- Textbox
function Library:_Textbox(page, o)
    o = o or {}
    local row = self:_row(page, 32)
    Util.new("TextLabel", {
        Text = o.Title or "Text", Font = Theme.Font, TextSize = 13,
        TextColor3 = Theme.Text, BackgroundTransparency = 1,
        Size = UDim2.new(0.4, 0, 1, 0),
        TextXAlignment = Enum.TextXAlignment.Left, Parent = row,
    })
    local box = Util.new("TextBox", {
        Text = o.Default or "", PlaceholderText = o.Placeholder or "入力...",
        Font = Theme.Font, TextSize = 12, TextColor3 = Theme.Text,
        PlaceholderColor3 = Theme.TextDim, BackgroundColor3 = Theme.SurfaceAlt,
        BorderSizePixel = 0, ClearTextOnFocus = false,
        Position = UDim2.new(0.4, 0, 0, 0), Size = UDim2.new(0.6, 0, 1, 0), Parent = row,
    })
    Util.corner(box, 4)
    local t = { Value = o.Default or "", Flag = o.Flag, Callback = o.Callback }
    box.FocusLost:Connect(function()
        t.Value = box.Text
        if t.Flag then Library.Flags[t.Flag] = box.Text end
        if t.Callback then t.Callback(box.Text) end
    end)
    function t:Set(v) box.Text = tostring(v); self.Value = tostring(v) end
    if t.Flag then Library.Elements[t.Flag] = t end
    return t
end

-- Dropdown
function Library:_Dropdown(page, o)
    o = o or {}
    local items = o.Items or {}
    local multi = o.Multi or false
    local selected = o.Default or (multi and {} or nil)

    local container = Util.new("Frame", {
        Size = UDim2.new(1, 0, 0, 44), BackgroundColor3 = Theme.Surface,
        BorderSizePixel = 0, ClipsDescendants = true, Parent = page,
    })
    Util.corner(container, 6)

    local header = Util.new("TextButton", {
        Size = UDim2.new(1, 0, 0, 44), BackgroundTransparency = 1,
        Text = "", Parent = container,
    })
    Util.new("TextLabel", {
        Text = o.Title or "Dropdown", Font = Theme.Font, TextSize = 13,
        TextColor3 = Theme.Text, BackgroundTransparency = 1,
        Position = UDim2.fromOffset(10, 8), Size = UDim2.new(1, -40, 0, 16),
        TextXAlignment = Enum.TextXAlignment.Left, Parent = container,
    })
    local preview = Util.new("TextLabel", {
        Text = "選択...", Font = Theme.Font, TextSize = 11,
        TextColor3 = Theme.TextDim, BackgroundTransparency = 1,
        Position = UDim2.fromOffset(10, 24), Size = UDim2.new(1, -30, 0, 14),
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd, Parent = container,
    })
    local arrow = Util.new("TextLabel", {
        Text = "▼", Font = Theme.FontBold, TextSize = 10,
        TextColor3 = Theme.TextDim, BackgroundTransparency = 1,
        Position = UDim2.new(1, -22, 0, 0), Size = UDim2.fromOffset(16, 44),
        Parent = container,
    })
    local list = Util.new("Frame", {
        Size = UDim2.new(1, 0, 0, 0), Position = UDim2.new(0, 0, 0, 44),
        BackgroundColor3 = Theme.SurfaceAlt, BorderSizePixel = 0,
        ClipsDescendants = true, Parent = container,
    })
    Util.new("UIListLayout", {
        Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder, Parent = list,
    })
    Util.pad(list, 4)

    local d = { Value = selected, Flag = o.Flag, Callback = o.Callback }
    local isOpen, btns = false, {}

    local function updatePreview()
        if multi then
            if #d.Value == 0 then preview.Text = "選択..."
            else
                local names = {}
                for _, v in ipairs(d.Value) do names[#names + 1] = tostring(v) end
                preview.Text = table.concat(names, ", ")
            end
        else
            preview.Text = d.Value and tostring(d.Value) or "選択..."
        end
    end

    local function rebuild()
        for _, b in ipairs(btns) do b:Destroy() end
        btns = {}
        for i, item in ipairs(items) do
            local isSel = multi and table.find(d.Value, item) or (d.Value == item)
            local ib = Util.new("TextButton", {
                Size = UDim2.new(1, 0, 0, 24),
                BackgroundColor3 = isSel and Theme.Accent or Theme.SurfaceAlt,
                Text = tostring(item), Font = Theme.Font, TextSize = 12,
                TextColor3 = Theme.Text, TextXAlignment = Enum.TextXAlignment.Left,
                AutoButtonColor = false, LayoutOrder = i, Parent = list,
            })
            Util.corner(ib, 4); Util.pad(ib, 4)
            ib.MouseButton1Click:Connect(function()
                if multi then
                    local idx = table.find(d.Value, item)
                    if idx then table.remove(d.Value, idx)
                    else table.insert(d.Value, item) end
                else
                    d.Value = item
                    isOpen = false
                    Util.tween(container, 0.15, { Size = UDim2.new(1, 0, 0, 44) })
                    arrow.Text = "▼"
                end
                updatePreview(); rebuild()
                if d.Flag then Library.Flags[d.Flag] = d.Value end
                if d.Callback then d.Callback(d.Value) end
            end)
            btns[#btns + 1] = ib
        end
        list.Size = UDim2.new(1, 0, 0, math.min(#items * 26 + 8, 150))
    end
    rebuild(); updatePreview()

    header.MouseButton1Click:Connect(function()
        isOpen = not isOpen
        local listH = math.min(#items * 26 + 8, 150)
        Util.tween(container, 0.15, { Size = UDim2.new(1, 0, 0, 44 + (isOpen and listH or 0)) })
        arrow.Text = isOpen and "▲" or "▼"
    end)

    function d:Set(v) self.Value = v; updatePreview(); rebuild() end
    function d:Get() return self.Value end
    if d.Flag then Library.Elements[d.Flag] = d end
    return d
end

-- Keybind
function Library:_Keybind(page, o)
    o = o or {}
    local row = self:_row(page, 32)
    Util.new("TextLabel", {
        Text = o.Title or "Keybind", Font = Theme.Font, TextSize = 13,
        TextColor3 = Theme.Text, BackgroundTransparency = 1,
        Size = UDim2.new(1, -80, 1, 0),
        TextXAlignment = Enum.TextXAlignment.Left, Parent = row,
    })
    local kb = Util.new("TextButton", {
        Text = o.Default and o.Default.Name or "None",
        Font = Theme.Font, TextSize = 12, TextColor3 = Theme.Text,
        BackgroundColor3 = Theme.SurfaceAlt, BorderSizePixel = 0,
        AutoButtonColor = false, Position = UDim2.new(1, -70, .5, 0),
        AnchorPoint = Vector2.new(0, .5), Size = UDim2.fromOffset(70, 22),
        Parent = row,
    })
    Util.corner(kb, 4)

    local k = { Value = o.Default, Flag = o.Flag, Callback = o.Callback, Pressed = false }
    local listening = false
    kb.MouseButton1Click:Connect(function() listening = true; kb.Text = "..." end)
    UserInputService.InputBegan:Connect(function(input, gpe)
        if gpe then return end
        if listening then
            listening = false
            k.Value = input.KeyCode
            kb.Text = input.KeyCode.Name
            if k.Flag then Library.Flags[k.Flag] = input.KeyCode.Name end
            return
        end
        if k.Value and input.KeyCode == k.Value and not k.Pressed then
            k.Pressed = true
            if k.Callback then k.Callback(true) end
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if k.Value and input.KeyCode == k.Value and k.Pressed then
            k.Pressed = false
            if k.Callback then k.Callback(false) end
        end
    end)
    function k:Set(v)
        if typeof(v) == "EnumItem" then self.Value = v
        elseif typeof(v) == "string" then
            local ok, code = pcall(function() return Enum.KeyCode[v] end)
            if ok then self.Value = code end
        end
        kb.Text = self.Value and self.Value.Name or "None"
    end
    if k.Flag then Library.Elements[k.Flag] = k end
    return k
end

-- ColorPicker
function Library:_ColorPicker(page, o)
    o = o or {}
    local init = o.Default or Color3.fromRGB(255, 255, 255)
    local h, s, v = init:ToHSV()

    local row = self:_row(page, 32)
    Util.new("TextLabel", {
        Text = o.Title or "Color", Font = Theme.Font, TextSize = 13,
        TextColor3 = Theme.Text, BackgroundTransparency = 1,
        Size = UDim2.new(1, -80, 1, 0),
        TextXAlignment = Enum.TextXAlignment.Left, Parent = row,
    })
    local sw = Util.new("TextButton", {
        Text = "", BackgroundColor3 = init, BorderSizePixel = 0,
        AutoButtonColor = false, Position = UDim2.new(1, -60, .5, 0),
        AnchorPoint = Vector2.new(0, .5), Size = UDim2.fromOffset(60, 22), Parent = row,
    })
    Util.corner(sw, 4); Util.stroke(sw, Theme.Stroke)

    -- ポップアップ
    local popup = Util.new("Frame", {
        Size = UDim2.fromOffset(180, 160), Visible = false,
        BackgroundColor3 = Theme.Surface, BorderSizePixel = 0,
        ZIndex = 10, Parent = row,
    })
    Util.corner(popup, 8); Util.stroke(popup, Theme.Stroke)

    local sat = Util.new("Frame", {
        Size = UDim2.new(1, -20, 0, 90), Position = UDim2.fromOffset(10, 10),
        BackgroundColor3 = Color3.fromHSV(h, 1, 1), BorderSizePixel = 0,
        ClipsDescendants = true, ZIndex = 11, Parent = popup,
    })
    Util.corner(sat, 4)
    local white = Util.new("Frame", {
        Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(1, 1, 1),
        BackgroundTransparency = 0, BorderSizePixel = 0, ZIndex = 12, Parent = sat,
    })
    local grad = Util.new("UIGradient", {
        Color = ColorSequence.new(Color3.new(1,1,1), Color3.new(1,1,1)),
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1),
        }), Parent = white,
    })
    local black = Util.new("Frame", {
        Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0),
        BorderSizePixel = 0, ZIndex = 13, Parent = sat,
    })
    local grad2 = Util.new("UIGradient", {
        Rotation = 90,
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1),
        }), Parent = black,
    })
    local cursor = Util.new("Frame", {
        Size = UDim2.fromOffset(10, 10), AnchorPoint = Vector2.new(.5, .5),
        BackgroundTransparency = 1, ZIndex = 14, Parent = sat,
    })
    Util.corner(cursor, 5); Util.stroke(cursor, Color3.new(1,1,1), 2)

    local hueBar = Util.new("Frame", {
        Size = UDim2.new(1, -20, 0, 12), Position = UDim2.fromOffset(10, 110),
        BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0,
        ZIndex = 11, Parent = popup,
    })
    Util.corner(hueBar, 6)
    local hueGrad = Util.new("UIGradient", {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0.00, Color3.fromRGB(255,   0,   0)),
            ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255, 255,   0)),
            ColorSequenceKeypoint.new(0.33, Color3.fromRGB(  0, 255,   0)),
            ColorSequenceKeypoint.new(0.50, Color3.fromRGB(  0, 255, 255)),
            ColorSequenceKeypoint.new(0.67, Color3.fromRGB(  0,   0, 255)),
            ColorSequenceKeypoint.new(0.83, Color3.fromRGB(255,   0, 255)),
            ColorSequenceKeypoint.new(1.00, Color3.fromRGB(255,   0,   0)),
        }), Parent = hueBar,
    })
    local hueCursor = Util.new("Frame", {
        Size = UDim2.fromOffset(4, 16), AnchorPoint = Vector2.new(.5, .5),
        Position = UDim2.new(h, 0, .5, 0), BackgroundColor3 = Theme.Text,
        BorderSizePixel = 0, ZIndex = 12, Parent = hueBar,
    })
    Util.corner(hueCursor, 2)

    local cp = { Value = init, Flag = o.Flag, Callback = o.Callback }
    local function updateVisual()
        sat.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
        cursor.Position = UDim2.new(s, 0, 1 - v, 0)
        hueCursor.Position = UDim2.new(h, 0, .5, 0)
        sw.BackgroundColor3 = Color3.fromHSV(h, s, v)
    end
    local function fire()
        cp.Value = Color3.fromHSV(h, s, v)
        updateVisual()
        if cp.Flag then Library.Flags[cp.Flag] = cp.Value end
        if cp.Callback then cp.Callback(cp.Value) end
    end
    updateVisual()

    local dragSat, dragHue = false, false
    local function satFromInput(px, py)
        local ap, sz = sat.AbsolutePosition, sat.AbsoluteSize
        s = math.clamp((px - ap.X) / sz.X, 0, 1)
        v = 1 - math.clamp((py - ap.Y) / sz.Y, 0, 1)
        fire()
    end
    sat.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            dragSat = true; satFromInput(i.Position.X, i.Position.Y)
        end
    end)
    hueBar.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            dragHue = true
            h = math.clamp((i.Position.X - hueBar.AbsolutePosition.X) / hueBar.AbsoluteSize.X, 0, 1)
            fire()
        end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if dragSat and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
            satFromInput(i.Position.X, i.Position.Y)
        elseif dragHue and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
            h = math.clamp((i.Position.X - hueBar.AbsolutePosition.X) / hueBar.AbsoluteSize.X, 0, 1)
            fire()
        end
    end)
    UserInputService.InputEnded:Connect(function() dragSat = false; dragHue = false end)

    sw.MouseButton1Click:Connect(function() popup.Visible = not popup.Visible end)

    function cp:Set(c)
        if typeof(c) == "table" then c = Color3.new(c[1] or c.R or 1, c[2] or c.G or 1, c[3] or c.B or 1) end
        self.Value = c
        h, s, v = c:ToHSV(); fire()
    end
    if cp.Flag then Library.Elements[cp.Flag] = cp end
    return cp
end

return Library
