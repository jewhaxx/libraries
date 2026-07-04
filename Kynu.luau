local Services = setmetatable({}, {
    __index = function(Self, Key)
        return game:GetService(Key)
    end,
})

local LocalPlayer = Services.Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()
local GuiParent = gethui and gethui() or Services.CoreGui

local FromRGB = Color3.fromRGB
local FromHex = Color3.fromHex
local UDim2New = UDim2.new
local UDimNew = UDim.new
local Vector2New = Vector2.new
local MathClamp = math.clamp
local MathFloor = math.floor
local StringFormat = string.format
local StringSub = string.sub
local StringUpper = string.upper
local StringFind = string.find
local StringGSub = string.gsub
local TableInsert = table.insert
local TableFind = table.find
local TableRemove = table.remove

local BodySize = 13
local TitleSize = 14
local SmallSize = 11

local Theme = {
    Background = FromRGB(0, 0, 0),
    Window = FromRGB(8, 8, 12),
    Sidebar = FromRGB(5, 5, 8),
    TabBar = FromRGB(8, 8, 12),
    Section = FromRGB(20, 20, 24),
    Element = FromRGB(28, 28, 34),
    ElementHover = FromRGB(36, 36, 44),
    ElementActive = FromRGB(44, 44, 54),
    Border = FromRGB(45, 45, 55),
    Text = FromRGB(240, 240, 245),
    Subtext = FromRGB(160, 160, 170),
    Faded = FromRGB(100, 100, 110),
    Accent = FromRGB(0, 212, 255),
    AccentBright = FromRGB(120, 235, 255),
    AccentDim = FromRGB(0, 130, 170),
    AccentText = FromRGB(0, 0, 0),
    Danger = FromRGB(255, 75, 75),
    ToggleOff = FromRGB(50, 50, 60),
    SliderTrack = FromRGB(35, 35, 42),
}

local Library = {
    Flags = {},
    Connections = {},
    Instances = {},
    Theme = Theme,
    Folders = {
        Directory = "ModernUI",
        Configs = "ModernUI/Configs",
    },
    Window = nil,
    Watermark = nil,
    KeybindList = nil,
    NotificationStack = nil,
    ActiveElements = {},
    LoadedTick = os.clock(),
}

if getgenv then
    if getgenv().ModernLibrary then
        pcall(function()
            getgenv().ModernLibrary:Unload()
        end)
    end
    getgenv().ModernLibrary = Library
end

local Create = function(ClassName, Props, Children)
    local Object = Instance.new(ClassName)
    if Props then
        for Key, Value in next, Props do
            Object[Key] = Value
        end
    end
    if Children then
        for _, Child in next, Children do
            Child.Parent = Object
        end
    end
    return Object
end

local ApplyFont = function(Object, Size, Color)
    Object.FontFace = Font.fromName("RobotoMono")
    Object.TextColor3 = Color or Theme.Text
    Object.TextSize = Size or BodySize
    Object.TextXAlignment = Enum.TextXAlignment.Left
    Object.TextYAlignment = Enum.TextYAlignment.Center
    Object.TextStrokeColor3 = Color3.new(0, 0, 0)
    Object.TextStrokeTransparency = 0
    return Object
end

local Connect = function(Signal, Callback)
    local Connection = Signal:Connect(Callback)
    TableInsert(Library.Connections, Connection)
    return Connection
end

local Tween = function(Object, Props, Time, Style, Direction)
    local Info = TweenInfo.new(
        Time or 0.18,
        Style or Enum.EasingStyle.Quad,
        Direction or Enum.EasingDirection.Out
    )
    local Anim = Services.TweenService:Create(Object, Info, Props)
    Anim:Play()
    return Anim
end

local Round = function(Value, Decimals)
    local Mult = 10 ^ (Decimals or 0)
    return MathFloor(Value * Mult + 0.5) / Mult
end

local MathMax = math.max
local MathMin = math.min

local LerpColor = function(From, To, Alpha)
    return From:Lerp(To, Alpha)
end

local MakeCorner = function(Object, Radius)
    local Corner = Create("UICorner", {
        CornerRadius = UDimNew(0, Radius or 4),
    })
    Corner.Parent = Object
    return Corner
end

local MakeStroke = function(Object, Color, Thickness, Transparency)
    local Stroke = Create("UIStroke", {
        Color = Color or Theme.Border,
        Thickness = Thickness or 1,
        Transparency = Transparency or 0,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        LineJoinMode = Enum.LineJoinMode.Round,
    })
    Stroke.Parent = Object
    return Stroke
end

local MakePadding = function(Object, Padding)
    local Pad = Create("UIPadding", {
        PaddingLeft = UDimNew(0, Padding or 8),
        PaddingRight = UDimNew(0, Padding or 8),
        PaddingTop = UDimNew(0, Padding or 8),
        PaddingBottom = UDimNew(0, Padding or 8),
    })
    Pad.Parent = Object
    return Pad
end

local MakeList = function(Object, Padding, SortOrder)
    local List = Create("UIListLayout", {
        Padding = UDimNew(0, Padding or 8),
        SortOrder = SortOrder or Enum.SortOrder.LayoutOrder,
        HorizontalAlignment = Enum.HorizontalAlignment.Center,
        VerticalAlignment = Enum.VerticalAlignment.Top,
    })
    List.Parent = Object
    return List
end

local MakeGradient = function(Object, FromColor, ToColor, Angle)
    local Gradient = Create("UIGradient", {
        Color = ColorSequence.new(FromColor, ToColor),
        Rotation = Angle or 0,
    })
    Gradient.Parent = Object
    return Gradient
end

local Hover = function(Object, OnEnter, OnLeave)
    Connect(Object.MouseEnter, OnEnter)
    Connect(Object.MouseLeave, OnLeave)
end

local Ripple = function(Parent, Position, Color)
    local Container = Parent:FindFirstChild("RippleContainer")
    if not Container then
        Container = Create("Frame", {
            Name = "RippleContainer",
            BackgroundTransparency = 1,
            Size = UDim2New(1, 0, 1, 0),
            ZIndex = 50,
            ClipsDescendants = true,
        })
        MakeCorner(Container, 4)
        Container.Parent = Parent
    end
    local MaxDim = MathMax(Parent.AbsoluteSize.X, Parent.AbsoluteSize.Y)
    local Circle = Create("Frame", {
        BackgroundColor3 = Color or Theme.Accent,
        BackgroundTransparency = 0.4,
        BorderSizePixel = 0,
        AnchorPoint = Vector2New(0.5, 0.5),
        Position = UDim2New(0, Position.X, 0, Position.Y),
        Size = UDim2New(0, 0, 0, 0),
        ZIndex = 51,
    })
    MakeCorner(Circle, MaxDim)
    Circle.Parent = Container
    Tween(Circle, {
        Size = UDim2New(0, MaxDim, 0, MaxDim),
        BackgroundTransparency = 1,
    }, 0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    task.delay(0.45, function()
        Circle:Destroy()
    end)
end

local RegisterFlag = function(Name, Value)
    if not Name or Name == "" then
        return nil
    end
    Library.Flags[Name] = Value
    return Value
end

local GetFlag = function(Name)
    return Library.Flags[Name]
end

local RegisterElement = function(Element)
    TableInsert(Library.ActiveElements, Element)
    return Element
end

local ResolveImage = function(Image)
    if not Image then
        return "rbxassetid://0"
    end
    if StringFind(Image, "rbxasset") or StringFind(Image, "http") then
        return Image
    end
    return "rbxassetid://" .. Image
end

local DragFrame = function(Frame, Handle)
    local Dragging = false
    local StartPos = Vector2New(0, 0)
    local StartPosGui = Vector2New(0, 0)
    local Target = Handle or Frame
    Connect(Target.InputBegan, function(Input)
        if Input.UserInputType == Enum.UserInputType.MouseButton1 then
            Dragging = true
            StartPos = Input.Position
            StartPosGui = Frame.Position
        end
    end)
    Connect(Services.UserInputService.InputChanged, function(Input)
        if Dragging and Input.UserInputType == Enum.UserInputType.MouseMovement then
            local Delta = Input.Position - StartPos
            Frame.Position = UDim2New(
                StartPosGui.X.Scale, StartPosGui.X.Offset + Delta.X,
                StartPosGui.Y.Scale, StartPosGui.Y.Offset + Delta.Y
            )
        end
    end)
    Connect(Services.UserInputService.InputEnded, function(Input)
        if Input.UserInputType == Enum.UserInputType.MouseButton1 then
            Dragging = false
        end
    end)
end

local FormatNumber = function(Value, Decimals)
    local Dec = Decimals or 0
    return StringFormat("%." .. Dec .. "f", Value)
end

local GetShortKey = function(KeyCode)
    local Name = KeyCode.Name
    local Replacements = {
        LeftControl = "LCtrl",
        RightControl = "RCtrl",
        LeftShift = "LShift",
        RightShift = "RShift",
        LeftAlt = "LAlt",
        RightAlt = "RAlt",
        MouseButton1 = "Mouse1",
        MouseButton2 = "Mouse2",
        MouseButton3 = "Mouse3",
        CapsLock = "Caps",
        Backspace = "Bksp",
        Return = "Enter",
        Escape = "Esc",
        PageUp = "PgUp",
        PageDown = "PgDn",
        ScrollLock = "ScrlLk",
        NumLock = "NumLk",
    }
    return Replacements[Name] or Name
end

Library.Window = function(Self, Data)
    local Title = Data.Name or Data.Title or "Modern UI"
    local Size = Data.Size or UDim2New(0, 760, 0, 480)

    local Holder = Create("ScreenGui", {
        Name = "ModernUI",
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        DisplayOrder = 999,
        IgnoreGuiInset = true,
    })
    Holder.Parent = GuiParent

    local Window = Create("Frame", {
        Name = "Window",
        BackgroundColor3 = Theme.Window,
        BorderSizePixel = 0,
        Size = Size,
        Position = UDim2New(0.5, -Size.X.Offset / 2, 0.5, -Size.Y.Offset / 2),
        Active = true,
        Parent = Holder,
    })
    MakeCorner(Window, 8)
    MakeStroke(Window, Theme.Border, 1, 0)

    local Dropshadow = Create("ImageLabel", {
        Name = "Dropshadow",
        BackgroundTransparency = 1,
        Size = UDim2New(1, 30, 1, 30),
        Position = UDim2New(0, -15, 0, -15),
        ZIndex = -1,
        Image = "rbxassetid://1316045217",
        ImageColor3 = Color3.new(0, 0, 0),
        ImageTransparency = 0.4,
        ScaleType = Enum.ScaleType.Slice,
        SliceCenter = Rect.new(10, 10, 118, 118),
        Parent = Window,
    })

    local TitleBar = Create("Frame", {
        Name = "TitleBar",
        BackgroundColor3 = Theme.Sidebar,
        BackgroundTransparency = 0,
        BorderSizePixel = 0,
        Size = UDim2New(1, 0, 0, 38),
        Parent = Window,
    })
    local TitleCorner = MakeCorner(TitleBar, 8)
    Create("Frame", {
        Name = "TitleBarBottomCover",
        BackgroundColor3 = Theme.Sidebar,
        BorderSizePixel = 0,
        Size = UDim2New(1, 0, 0, 10),
        Position = UDim2New(0, 0, 1, -8),
        Parent = TitleBar,
    })

    local TitleText = Create("TextLabel", {
        Name = "Title",
        BackgroundTransparency = 1,
        Position = UDim2New(0, 16, 0, 0),
        Size = UDim2New(1, -120, 1, 0),
        Text = Title,
    })
    ApplyFont(TitleText, TitleSize, Theme.Text)
    TitleText.Parent = TitleBar

    local AccentDot = Create("Frame", {
        Name = "AccentDot",
        BackgroundColor3 = Theme.Accent,
        BorderSizePixel = 0,
        Size = UDim2New(0, 6, 0, 6),
        Position = UDim2New(0, -12, 0.5, -3),
    })
    MakeCorner(AccentDot, 3)
    AccentDot.Parent = TitleText

    local CloseBtn = Create("TextButton", {
        Name = "Close",
        BackgroundColor3 = Theme.Element,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2New(0, 28, 0, 28),
        Position = UDim2New(1, -34, 0.5, -14),
        Text = "",
        AutoButtonColor = false,
        Parent = TitleBar,
    })
    local CloseIcon = Create("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2New(1, 0, 1, 0),
        Text = "X",
    })
    ApplyFont(CloseIcon, 14, Theme.Faded)
    CloseIcon.TextXAlignment = Enum.TextXAlignment.Center
    CloseIcon.Parent = CloseBtn
    Hover(CloseBtn, function()
        Tween(CloseBtn, { BackgroundTransparency = 0, BackgroundColor3 = Theme.Danger })
        Tween(CloseIcon, { TextColor3 = Theme.Text })
    end, function()
        Tween(CloseBtn, { BackgroundTransparency = 1 })
        Tween(CloseIcon, { TextColor3 = Theme.Faded })
    end)
    MakeCorner(CloseBtn, 6)
    Connect(CloseBtn.MouseButton1Click, function()
        Self:Unload()
    end)

    local Body = Create("Frame", {
        Name = "Body",
        BackgroundColor3 = Theme.Window,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Position = UDim2New(0, 0, 0, 38),
        Size = UDim2New(1, 0, 1, -38),
        Parent = Window,
    })

    local Sidebar = Create("Frame", {
        Name = "Sidebar",
        BackgroundColor3 = Theme.Sidebar,
        BorderSizePixel = 0,
        Size = UDim2New(0, 76, 1, 0),
        Parent = Body,
    })
    local SidebarList = MakeList(Sidebar, 8, Enum.SortOrder.LayoutOrder)
    SidebarList.HorizontalAlignment = Enum.HorizontalAlignment.Center
    SidebarList.VerticalAlignment = Enum.VerticalAlignment.Top
    MakePadding(Sidebar, 14)
    Create("Frame", {
        Name = "SidebarDivider",
        BackgroundColor3 = Theme.Border,
        BorderSizePixel = 0,
        Size = UDim2New(0, 1, 1, 0),
        Position = UDim2New(1, -1, 0, 0),
        Parent = Sidebar,
    })

    local Content = Create("Frame", {
        Name = "Content",
        BackgroundColor3 = Theme.Window,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Position = UDim2New(0, 76, 0, 0),
        Size = UDim2New(1, -76, 1, 0),
        Parent = Body,
    })

    local SubTabBar = Create("Frame", {
        Name = "SubTabBar",
        BackgroundColor3 = Theme.TabBar,
        BorderSizePixel = 0,
        Size = UDim2New(1, 0, 0, 38),
        Parent = Content,
    })
    local SubTabList = Create("Frame", {
        Name = "SubTabList",
        BackgroundTransparency = 1,
        Size = UDim2New(1, -16, 1, 0),
        Position = UDim2New(0, 8, 0, 0),
        Parent = SubTabBar,
    })
    local SubTabLayout = MakeList(SubTabList, 4, Enum.SortOrder.LayoutOrder)
    SubTabLayout.FillDirection = Enum.FillDirection.Horizontal
    SubTabLayout.VerticalAlignment = Enum.VerticalAlignment.Center

    local SubTabDivider = Create("Frame", {
        Name = "SubTabDivider",
        BackgroundColor3 = Theme.Border,
        BorderSizePixel = 0,
        Size = UDim2New(1, 0, 0, 1),
        Position = UDim2New(0, 0, 1, -1),
        Parent = SubTabBar,
    })

    local PageContainer = Create("Frame", {
        Name = "PageContainer",
        BackgroundColor3 = Theme.Window,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Position = UDim2New(0, 0, 0, 38),
        Size = UDim2New(1, 0, 1, -38),
        Parent = Content,
    })
    MakePadding(PageContainer, 14)

    DragFrame(Window, TitleBar)

    local WindowData = {
        Gui = Holder,
        Frame = Window,
        Title = TitleText,
        Sidebar = Sidebar,
        SidebarList = SidebarList,
        SubTabBar = SubTabBar,
        SubTabList = SubTabList,
        PageContainer = PageContainer,
        Tabs = {},
        ActiveTab = nil,
        Visible = true,
    }

    Library.Window = WindowData

    WindowData.AddTab = function(Self, TabData)
        local TabName = TabData.Name or "Tab"
        local TabImage = ResolveImage(TabData.Image)

        local TabBtn = Create("TextButton", {
            Name = TabName,
            BackgroundTransparency = 1,
            Size = UDim2New(1, -16, 0, 56),
            Text = "",
            AutoButtonColor = false,
            Parent = Sidebar,
        })

        local IconContainer = Create("Frame", {
            Name = "IconContainer",
            BackgroundColor3 = Theme.Element,
            BorderSizePixel = 0,
            Size = UDim2New(0, 38, 0, 38),
            Position = UDim2New(0.5, 0, 0, 4),
            AnchorPoint = Vector2New(0.5, 0),
            ZIndex = 2,
            Parent = TabBtn,
        })
        MakeCorner(IconContainer, 19)
        MakeStroke(IconContainer, Theme.Border, 1, 0)

        local HasImage = TabData.Image ~= nil
        local Icon = nil
        local Letter = nil

        if HasImage then
            Icon = Create("ImageLabel", {
                Name = "Icon",
                BackgroundTransparency = 1,
                Size = UDim2New(0, 18, 0, 18),
                Position = UDim2New(0.5, 0, 0.5, 0),
                AnchorPoint = Vector2New(0.5, 0.5),
                Image = TabImage,
                ImageColor3 = Theme.Faded,
                ZIndex = 3,
                Parent = IconContainer,
            })
        else
            Letter = Create("TextLabel", {
                Name = "Letter",
                BackgroundTransparency = 1,
                Size = UDim2New(1, 0, 1, 0),
                Text = StringUpper(StringSub(TabName, 1, 1)),
                ZIndex = 3,
            })
            ApplyFont(Letter, 16, Theme.Faded)
            Letter.TextXAlignment = Enum.TextXAlignment.Center
            Letter.Parent = IconContainer
        end

        local SetTabColor = function(Color)
            if Icon then
                Tween(Icon, { ImageColor3 = Color }, 0.2)
            elseif Letter then
                Tween(Letter, { TextColor3 = Color }, 0.2)
            end
        end

        local Indicator = Create("Frame", {
            Name = "Indicator",
            BackgroundColor3 = Theme.Accent,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Size = UDim2New(0, 3, 0, 24),
            Position = UDim2New(0, -8, 0.5, -12),
            ZIndex = 4,
            Parent = TabBtn,
        })
        MakeCorner(Indicator, 2)
        local IndicatorGradient = Create("UIGradient", {
            Color = ColorSequence.new(Theme.Accent, Theme.AccentBright),
            Rotation = 90,
        })
        IndicatorGradient.Parent = Indicator

        local Label = Create("TextLabel", {
            Name = "Label",
            BackgroundTransparency = 1,
            Size = UDim2New(1, 0, 0, 12),
            Position = UDim2New(0, 0, 1, -4),
            Text = TabName,
            ZIndex = 3,
        })
        ApplyFont(Label, 10, Theme.Faded)
        Label.TextXAlignment = Enum.TextXAlignment.Center

        local TabObject = {
            Button = TabBtn,
            IconContainer = IconContainer,
            Indicator = Indicator,
            Icon = Icon,
            Letter = Letter,
            Label = Label,
            SetTabColor = SetTabColor,
            Pages = {},
            ActivePage = nil,
            Order = #WindowData.Tabs + 1,
        }

        TabBtn.LayoutOrder = TabObject.Order

        local SelectTab = function()
            for _, Other in next, WindowData.Tabs do
                if Other ~= TabObject then
                    Tween(Other.IconContainer, { BackgroundColor3 = Theme.Element }, 0.2)
                    local OtherStroke = Other.IconContainer:FindFirstChildOfClass("UIStroke")
                    if OtherStroke then
                        Tween(OtherStroke, { Color = Theme.Border, Thickness = 1 }, 0.2)
                    end
                    Tween(Other.Indicator, { BackgroundTransparency = 1 }, 0.2)
                    Other.SetTabColor(Theme.Faded)
                    Tween(Other.Label, { TextColor3 = Theme.Faded }, 0.2)
                    for _, Page in next, Other.Pages do
                        Page.Frame.Visible = false
                    end
                end
            end
            Tween(IconContainer, { BackgroundColor3 = Theme.Sidebar }, 0.2)
            local Stroke = IconContainer:FindFirstChildOfClass("UIStroke")
            if Stroke then
                Tween(Stroke, { Color = Theme.Accent, Thickness = 2 }, 0.2)
            end
            Tween(Indicator, { BackgroundTransparency = 0 }, 0.2)
            SetTabColor(Theme.Accent)
            Tween(Label, { TextColor3 = Theme.Text }, 0.2)
            WindowData.ActiveTab = TabObject
            if TabObject.ActivePage then
                TabObject.ActivePage.Frame.Visible = true
            elseif TabObject.Pages[1] then
                TabObject.Pages[1]:Select()
            end
        end

        Hover(TabBtn, function()
            if WindowData.ActiveTab ~= TabObject then
                Tween(IconContainer, { BackgroundColor3 = Theme.ElementHover }, 0.15)
                SetTabColor(Theme.Subtext)
                Tween(Label, { TextColor3 = Theme.Subtext }, 0.15)
            end
        end, function()
            if WindowData.ActiveTab ~= TabObject then
                Tween(IconContainer, { BackgroundColor3 = Theme.Element }, 0.15)
                SetTabColor(Theme.Faded)
                Tween(Label, { TextColor3 = Theme.Faded }, 0.15)
            end
        end)

        Connect(TabBtn.MouseButton1Click, function()
            SelectTab()
        end)

        TabObject.Select = SelectTab

        TabObject.AddPage = function(Self, PageData)
            local PageName = PageData.Name or "Page"

            local PageBtn = Create("TextButton", {
                Name = PageName,
                BackgroundColor3 = Theme.Element,
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                AutomaticSize = Enum.AutomaticSize.X,
                Size = UDim2New(0, 0, 0, 28),
                Text = "",
                AutoButtonColor = false,
                Parent = SubTabList,
            })
            MakeCorner(PageBtn, 6)
            MakePadding(PageBtn, 14)

            local PageLabel = Create("TextLabel", {
                Name = "Label",
                BackgroundTransparency = 1,
                Size = UDim2New(1, 0, 1, 0),
                Text = PageName,
            })
            ApplyFont(PageLabel, BodySize, Theme.Subtext)
            PageLabel.TextXAlignment = Enum.TextXAlignment.Center
            PageLabel.Parent = PageBtn

            local Underline = Create("Frame", {
                Name = "Underline",
                BackgroundColor3 = Theme.Accent,
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                Size = UDim2New(0, 0, 0, 2),
                Position = UDim2New(0.5, 0, 1, -1),
                AnchorPoint = Vector2New(0.5, 0),
                Parent = PageBtn,
            })
            MakeCorner(Underline, 1)

            local PageFrame = Create("Frame", {
                Name = PageName,
                BackgroundTransparency = 1,
                Size = UDim2New(1, 0, 1, 0),
                Visible = false,
                Parent = PageContainer,
            })

            local LeftColumn = Create("Frame", {
                Name = "LeftColumn",
                BackgroundTransparency = 1,
                Size = UDim2New(0.5, -7, 1, 0),
                Parent = PageFrame,
            })
            local LeftList = MakeList(LeftColumn, 10)

            local RightColumn = Create("Frame", {
                Name = "RightColumn",
                BackgroundTransparency = 1,
                Size = UDim2New(0.5, -7, 1, 0),
                Position = UDim2New(1, -0, 0, 0),
                AnchorPoint = Vector2New(1, 0),
                Parent = PageFrame,
            })
            local RightList = MakeList(RightColumn, 10)

            local PageObject = {
                Button = PageBtn,
                Label = PageLabel,
                Underline = Underline,
                Frame = PageFrame,
                LeftColumn = LeftColumn,
                RightColumn = RightColumn,
                Sections = {},
            }

            local SelectPage = function()
                for _, Other in next, TabObject.Pages do
                    if Other ~= PageObject then
                        Other.Frame.Visible = false
                        Tween(Other.Label, { TextColor3 = Theme.Subtext }, 0.15)
                        Tween(Other.Button, { BackgroundTransparency = 1 }, 0.15)
                    end
                end
                PageFrame.Visible = true
                Tween(PageLabel, { TextColor3 = Theme.AccentText }, 0.15)
                Tween(PageBtn, { BackgroundTransparency = 0, BackgroundColor3 = Theme.Accent }, 0.15)
                TabObject.ActivePage = PageObject
            end

            Hover(PageBtn, function()
                if TabObject.ActivePage ~= PageObject then
                    Tween(PageBtn, { BackgroundTransparency = 0, BackgroundColor3 = Theme.ElementHover }, 0.15)
                    Tween(PageLabel, { TextColor3 = Theme.Text }, 0.15)
                end
            end, function()
                if TabObject.ActivePage ~= PageObject then
                    Tween(PageBtn, { BackgroundTransparency = 1 }, 0.15)
                    Tween(PageLabel, { TextColor3 = Theme.Subtext }, 0.15)
                end
            end)

            Connect(PageBtn.MouseButton1Click, function()
                SelectPage()
            end)

            PageObject.Select = SelectPage

            PageObject.AddSection = function(Self, SectionData)
                local SectionName = SectionData.Name or "Section"
                local Side = SectionData.Side or 1
                local ParentColumn = Side == 2 and RightColumn or LeftColumn

                local SectionFrame = Create("Frame", {
                    Name = SectionName,
                    BackgroundColor3 = Theme.Section,
                    BorderSizePixel = 0,
                    Size = UDim2New(1, 0, 0, 0),
                    AutomaticSize = Enum.AutomaticSize.Y,
                    Parent = ParentColumn,
                })
                MakeCorner(SectionFrame, 8)
                MakeStroke(SectionFrame, Theme.Border, 1, 0)

                local Header = Create("Frame", {
                    Name = "Header",
                    BackgroundColor3 = Theme.Section,
                    BackgroundTransparency = 0,
                    BorderSizePixel = 0,
                    Size = UDim2New(1, 0, 0, 38),
                    Parent = SectionFrame,
                })
                MakeCorner(Header, 8)
                Create("Frame", {
                    Name = "HeaderBottomCover",
                    BackgroundColor3 = Theme.Section,
                    BorderSizePixel = 0,
                    Size = UDim2New(1, 0, 0, 10),
                    Position = UDim2New(0, 0, 1, -8),
                    Parent = Header,
                })

                local HeaderLabel = Create("TextLabel", {
                    Name = "Title",
                    BackgroundTransparency = 1,
                    Size = UDim2New(1, -28, 1, 0),
                    Position = UDim2New(0, 16, 0, 0),
                    Text = StringUpper(StringSub(SectionName, 1, 1)) .. StringSub(SectionName, 2),
                })
                ApplyFont(HeaderLabel, 12, Theme.Text)
                HeaderLabel.Parent = Header

                local HeaderAccent = Create("Frame", {
                    Name = "Accent",
                    BackgroundColor3 = Theme.Accent,
                    BorderSizePixel = 0,
                    Size = UDim2New(0, 3, 0, 16),
                    Position = UDim2New(0, 6, 0.5, -8),
                    Parent = Header,
                })
                MakeCorner(HeaderAccent, 2)

                local Content = Create("Frame", {
                    Name = "Content",
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    Size = UDim2New(1, 0, 0, 0),
                    Position = UDim2New(0, 0, 0, 38),
                    AutomaticSize = Enum.AutomaticSize.Y,
                    Parent = SectionFrame,
                })
                local ContentList = MakeList(Content, 6)
                MakePadding(Content, 12)

                local SectionObject = {
                    Frame = SectionFrame,
                    Header = Header,
                    Content = Content,
                    Page = PageObject,
                    Elements = {},
                }

                TableInsert(PageObject.Sections, SectionObject)

                local AddElement = function(Element)
                    TableInsert(SectionObject.Elements, Element)
                    return Element
                end

                SectionObject.AddLabel = function(Self, LabelData)
                    local LabelText = LabelData.Name or "Label"
                    local Alignment = LabelData.Alignment or "Left"

                    local Label = Create("Frame", {
                        Name = "Label",
                        BackgroundTransparency = 1,
                        Size = UDim2New(1, 0, 0, 28),
                        Parent = Content,
                    })
                    local Text = Create("TextLabel", {
                        BackgroundTransparency = 1,
                        Size = UDim2New(1, 0, 1, 0),
                        Text = LabelText,
                    })
                    ApplyFont(Text, BodySize, Theme.Subtext)
                    if Alignment == "Center" then
                        Text.TextXAlignment = Enum.TextXAlignment.Center
                    elseif Alignment == "Right" then
                        Text.TextXAlignment = Enum.TextXAlignment.Right
                    end
                    Text.Parent = Label

                    local LabelObject = {
                        Frame = Label,
                        Text = Text,
                        Section = SectionObject,
                    }

                    LabelObject.SetText = function(Self, NewText)
                        Text.Text = NewText
                    end

                    LabelObject.SetColor = function(Self, Color)
                        Text.TextColor3 = Color
                    end

                    LabelObject.Keybind = function(Self, KeybindData)
                        return SectionObject:AddKeybindInternal(Label, KeybindData)
                    end

                    LabelObject.Colorpicker = function(Self, ColorData)
                        return SectionObject:AddColorpickerInternal(Label, ColorData)
                    end

                    AddElement(LabelObject)
                    return LabelObject
                end

                SectionObject.AddToggle = function(Self, ToggleData)
                    local ToggleName = ToggleData.Name or "Toggle"
                    local Default = ToggleData.Default
                    local Flag = ToggleData.Flag
                    local Callback = ToggleData.Callback or function() end

                    local Toggle = Create("TextButton", {
                        Name = "Toggle",
                        BackgroundColor3 = Theme.Element,
                        BackgroundTransparency = 0,
                        BorderSizePixel = 0,
                        Size = UDim2New(1, 0, 0, 36),
                        Text = "",
                        AutoButtonColor = false,
                        Parent = Content,
                    })
                    MakeCorner(Toggle, 6)

                    local ToggleLabel = Create("TextLabel", {
                        Name = "Label",
                        BackgroundTransparency = 1,
                        Size = UDim2New(1, -70, 1, 0),
                        Position = UDim2New(0, 12, 0, 0),
                        Text = ToggleName,
                    })
                    ApplyFont(ToggleLabel, BodySize, Theme.Text)
                    ToggleLabel.Parent = Toggle

                    local Switch = Create("Frame", {
                        Name = "Switch",
                        BackgroundColor3 = Theme.ToggleOff,
                        BorderSizePixel = 0,
                        Size = UDim2New(0, 46, 0, 22),
                        Position = UDim2New(1, -54, 0.5, -11),
                        Parent = Toggle,
                    })
                    MakeCorner(Switch, 11)

                    local Knob = Create("Frame", {
                        Name = "Knob",
                        BackgroundColor3 = Theme.Faded,
                        BorderSizePixel = 0,
                        Size = UDim2New(0, 18, 0, 18),
                        Position = UDim2New(0, 2, 0.5, -9),
                        Parent = Switch,
                    })
                    MakeCorner(Knob, 9)

                    local State = Default and true or false
                    local Modifiers = {}

                    local SetState = function(NewState, SkipCallback)
                        State = NewState and true or false
                        if State then
                            Tween(Switch, { BackgroundColor3 = Theme.Accent }, 0.18)
                            Tween(Knob, {
                                BackgroundColor3 = Theme.AccentText,
                                Position = UDim2New(1, -20, 0.5, -9),
                            }, 0.18, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
                            Tween(ToggleLabel, { TextColor3 = Theme.Text }, 0.15)
                        else
                            Tween(Switch, { BackgroundColor3 = Theme.ToggleOff }, 0.18)
                            Tween(Knob, {
                                BackgroundColor3 = Theme.Faded,
                                Position = UDim2New(0, 2, 0.5, -9),
                            }, 0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
                            Tween(ToggleLabel, { TextColor3 = Theme.Subtext }, 0.15)
                        end
                        if Flag then
                            RegisterFlag(Flag, State)
                        end
                        for _, Mod in next, Modifiers do
                            if Mod.Type == "Keybind" then
                                Mod.HandleVisibility(State)
                            end
                        end
                        if not SkipCallback then
                            Callback(State)
                        end
                    end

                    Hover(Toggle, function()
                        Tween(Toggle, { BackgroundColor3 = Theme.ElementHover }, 0.15)
                    end, function()
                        Tween(Toggle, { BackgroundColor3 = Theme.Element }, 0.15)
                    end)

                    Connect(Toggle.MouseButton1Click, function()
                        Ripple(Toggle, Vector2New(Mouse.X - Toggle.AbsolutePosition.X, Mouse.Y - Toggle.AbsolutePosition.Y), Theme.Accent)
                        SetState(not State)
                    end)

                    local ToggleObject = {
                        Frame = Toggle,
                        Label = ToggleLabel,
                        Switch = Switch,
                        Knob = Knob,
                        Section = SectionObject,
                        Modifiers = Modifiers,
                        Set = function(Self, ...) SetState(...) end,
                        Get = function(Self)
                            return State
                        end,
                        SetVisibility = function(Self, Visible)
                            Toggle.Visible = Visible
                        end,
                    }

                    RegisterElement(ToggleObject)
                    if Flag then
                        RegisterFlag(Flag, State)
                    end

                    ToggleObject.Keybind = function(Self, KeybindData)
                        local Mod = SectionObject:AddKeybindInternal(Toggle, KeybindData)
                        Mod.Type = "Keybind"
                        Mod.HandleVisibility = function() end
                        TableInsert(Modifiers, Mod)
                        return Mod
                    end

                    ToggleObject.Colorpicker = function(Self, ColorData)
                        local Mod = SectionObject:AddColorpickerInternal(Toggle, ColorData)
                        Mod.Type = "Colorpicker"
                        TableInsert(Modifiers, Mod)
                        return Mod
                    end

                    AddElement(ToggleObject)
                    SetState(State, true)
                    return ToggleObject
                end

                SectionObject.AddButton = function(Self, ButtonData)
                    local ButtonName = ButtonData.Name or "Button"
                    local Callback = ButtonData.Callback or function() end

                    local Button = Create("TextButton", {
                        Name = "Button",
                        BackgroundColor3 = Theme.Element,
                        BorderSizePixel = 0,
                        Size = UDim2New(1, 0, 0, 36),
                        Text = "",
                        AutoButtonColor = false,
                        Parent = Content,
                    })
                    MakeCorner(Button, 6)
                    MakeStroke(Button, Theme.Border, 1, 0)

                    local ButtonLabel = Create("TextLabel", {
                        Name = "Label",
                        BackgroundTransparency = 1,
                        Size = UDim2New(1, -20, 1, 0),
                        Position = UDim2New(0, 10, 0, 0),
                        Text = ButtonName,
                    })
                    ApplyFont(ButtonLabel, BodySize, Theme.Text)
                    ButtonLabel.TextXAlignment = Enum.TextXAlignment.Center
                    ButtonLabel.Parent = Button

                    Hover(Button, function()
                        Tween(Button, { BackgroundColor3 = Theme.ElementHover }, 0.15)
                        Tween(ButtonLabel, { TextColor3 = Theme.Accent }, 0.15)
                    end, function()
                        Tween(Button, { BackgroundColor3 = Theme.Element }, 0.15)
                        Tween(ButtonLabel, { TextColor3 = Theme.Text }, 0.15)
                    end)

                    Connect(Button.MouseButton1Click, function()
                        Ripple(Button, Vector2New(Mouse.X - Button.AbsolutePosition.X, Mouse.Y - Button.AbsolutePosition.Y))
                        local Success, Err = pcall(Callback)
                        if not Success then
                            warn("[ModernUI] Button callback error: " .. tostring(Err))
                        end
                    end)

                    local ButtonObject = {
                        Frame = Button,
                        Label = ButtonLabel,
                        Section = SectionObject,
                        Press = function(Self)
                            Ripple(Button, Vector2New(Button.AbsoluteSize.X / 2, Button.AbsoluteSize.Y / 2))
                            Callback()
                        end,
                        SetVisibility = function(Self, Visible)
                            Button.Visible = Visible
                        end,
                        SetText = function(Self, NewText)
                            ButtonLabel.Text = NewText
                        end,
                    }

                    AddElement(ButtonObject)
                    return ButtonObject
                end

                SectionObject.AddSlider = function(Self, SliderData)
                    local SliderName = SliderData.Name or "Slider"
                    local Min = SliderData.Min or 0
                    local Max = SliderData.Max or 100
                    local Decimals = SliderData.Decimals or 0
                    local Default = SliderData.Default or Min
                    local Suffix = SliderData.Suffix or ""
                    local Flag = SliderData.Flag
                    local Callback = SliderData.Callback or function() end

                    local Slider = Create("Frame", {
                        Name = "Slider",
                        BackgroundColor3 = Theme.Element,
                        BorderSizePixel = 0,
                        Size = UDim2New(1, 0, 0, 44),
                        Parent = Content,
                    })
                    MakeCorner(Slider, 6)
                    MakePadding(Slider, 10)

                    local SliderLabel = Create("TextLabel", {
                        Name = "Label",
                        BackgroundTransparency = 1,
                        Size = UDim2New(1, -80, 0, 16),
                        Text = SliderName,
                    })
                    ApplyFont(SliderLabel, BodySize, Theme.Text)
                    SliderLabel.Parent = Slider

                    local ValueLabel = Create("TextLabel", {
                        Name = "Value",
                        BackgroundTransparency = 1,
                        Size = UDim2New(0, 80, 0, 16),
                        Position = UDim2New(1, -80, 0, 0),
                        Text = "",
                    })
                    ApplyFont(ValueLabel, BodySize, Theme.Accent)
                    ValueLabel.TextXAlignment = Enum.TextXAlignment.Right
                    ValueLabel.Parent = Slider

                    local Track = Create("Frame", {
                        Name = "Track",
                        BackgroundColor3 = Theme.SliderTrack,
                        BorderSizePixel = 0,
                        Size = UDim2New(1, 0, 0, 6),
                        Position = UDim2New(0, 0, 1, -12),
                        Parent = Slider,
                    })
                    MakeCorner(Track, 3)

                    local Fill = Create("Frame", {
                        Name = "Fill",
                        BackgroundColor3 = Theme.Accent,
                        BorderSizePixel = 0,
                        Size = UDim2New(0, 0, 1, 0),
                        Parent = Track,
                    })
                    MakeCorner(Fill, 3)
                    local FillGradient = Create("UIGradient", {
                        Color = ColorSequence.new(Theme.AccentDim, Theme.Accent),
                        Rotation = 0,
                    })
                    FillGradient.Parent = Fill

                    local Knob = Create("Frame", {
                        Name = "Knob",
                        BackgroundColor3 = Theme.Text,
                        BorderSizePixel = 0,
                        Size = UDim2New(0, 12, 0, 12),
                        AnchorPoint = Vector2New(0.5, 0.5),
                        Position = UDim2New(0, 0, 0.5, 0),
                        Parent = Track,
                    })
                    MakeCorner(Knob, 6)
                    MakeStroke(Knob, Theme.Accent, 1.5, 0)

                    local State = MathClamp(Default, Min, Max)
                    local Dragging = false

                    local FormatValue = function(Value)
                        local Formatted = FormatNumber(Value, Decimals)
                        if Suffix and Suffix ~= "" then
                            return Formatted .. Suffix
                        end
                        return Formatted
                    end

                    local Update = function(Value, SkipCallback)
                        State = MathClamp(Value, Min, Max)
                        local Range = Max - Min
                        local Percent = Range > 0 and (State - Min) / Range or 0
                        Tween(Fill, { Size = UDim2New(Percent, 0, 1, 0) }, 0.05)
                        Tween(Knob, { Position = UDim2New(Percent, 0, 0.5, 0) }, 0.05)
                        ValueLabel.Text = FormatValue(State)
                        if Flag then
                            RegisterFlag(Flag, State)
                        end
                        if not SkipCallback then
                            Callback(State)
                        end
                    end

                    local SlideFromMouse = function()
                        local Relative = Mouse.X - Track.AbsolutePosition.X
                        local Width = Track.AbsoluteSize.X
                        local Percent = MathClamp(Relative / Width, 0, 1)
                        local Value = Min + (Max - Min) * Percent
                        Update(Round(Value, Decimals))
                    end

                    Connect(Track.InputBegan, function(Input)
                        if Input.UserInputType == Enum.UserInputType.MouseButton1 then
                            Dragging = true
                            SlideFromMouse()
                        end
                    end)
                    Connect(Track.InputEnded, function(Input)
                        if Input.UserInputType == Enum.UserInputType.MouseButton1 then
                            Dragging = false
                        end
                    end)
                    Connect(Services.UserInputService.InputChanged, function(Input)
                        if Dragging and Input.UserInputType == Enum.UserInputType.MouseMovement then
                            SlideFromMouse()
                        end
                    end)

                    Hover(Slider, function()
                        Tween(Knob, { Size = UDim2New(0, 16, 0, 16) }, 0.15)
                    end, function()
                        if not Dragging then
                            Tween(Knob, { Size = UDim2New(0, 12, 0, 12) }, 0.15)
                        end
                    end)

                    local SliderObject = {
                        Frame = Slider,
                        Label = SliderLabel,
                        ValueLabel = ValueLabel,
                        Track = Track,
                        Fill = Fill,
                        Knob = Knob,
                        Section = SectionObject,
                        Set = function(Self, ...) Update(...) end,
                        Get = function(Self)
                            return State
                        end,
                        SetVisibility = function(Self, Visible)
                            Slider.Visible = Visible
                        end,
                    }

                    RegisterElement(SliderObject)
                    if Flag then
                        RegisterFlag(Flag, State)
                    end
                    Update(State, true)
                    AddElement(SliderObject)
                    return SliderObject
                end

                SectionObject.AddTextbox = function(Self, TextboxData)
                    local TextboxName = TextboxData.Name or "Textbox"
                    local Default = TextboxData.Default or ""
                    local Placeholder = TextboxData.Placeholder or ""
                    local Flag = TextboxData.Flag
                    local Callback = TextboxData.Callback or function() end

                    local Textbox = Create("Frame", {
                        Name = "Textbox",
                        BackgroundColor3 = Theme.Element,
                        BorderSizePixel = 0,
                        Size = UDim2New(1, 0, 0, 36),
                        Parent = Content,
                    })
                    MakeCorner(Textbox, 6)

                    local TextboxLabel = Create("TextLabel", {
                        Name = "Label",
                        BackgroundTransparency = 1,
                        Size = UDim2New(0, 90, 1, 0),
                        Position = UDim2New(0, 10, 0, 0),
                        Text = TextboxName,
                    })
                    ApplyFont(TextboxLabel, BodySize, Theme.Subtext)
                    TextboxLabel.Parent = Textbox

                    local Box = Create("TextBox", {
                        Name = "Box",
                        BackgroundColor3 = Theme.SliderTrack,
                        BorderSizePixel = 0,
                        Size = UDim2New(1, -110, 0, 22),
                        Position = UDim2New(1, -100, 0.5, -11),
                        Text = Default,
                        PlaceholderText = Placeholder,
                        ClearTextOnFocus = false,
                        TextEditable = true,
                    })
                    ApplyFont(Box, BodySize, Theme.Text)
                    Box.TextXAlignment = Enum.TextXAlignment.Left
                    MakePadding(Box, 8)
                    MakeCorner(Box, 4)
                    Box.Parent = Textbox

                    local State = Default
                    local Focused = false

                    Connect(Box.Focused, function()
                        Focused = true
                        Tween(Box, { BackgroundColor3 = Theme.ElementActive }, 0.15)
                        local Stroke = MakeStroke(Box, Theme.Accent, 1, 0)
                        Stroke.Name = "FocusStroke"
                    end)
                    Connect(Box.FocusLost, function(EnterPressed)
                        Focused = false
                        Tween(Box, { BackgroundColor3 = Theme.SliderTrack }, 0.15)
                        local Stroke = Box:FindFirstChild("FocusStroke")
                        if Stroke then
                            Stroke:Destroy()
                        end
                        State = Box.Text
                        if Flag then
                            RegisterFlag(Flag, State)
                        end
                        Callback(State, EnterPressed)
                    end)

                    local TextboxObject = {
                        Frame = Textbox,
                        Label = TextboxLabel,
                        Box = Box,
                        Section = SectionObject,
                        Set = function(Self, Value)
                            State = Value
                            Box.Text = Value
                            if Flag then
                                RegisterFlag(Flag, State)
                            end
                            Callback(State, false)
                        end,
                        Get = function(Self)
                            return State
                        end,
                        SetVisibility = function(Self, Visible)
                            Textbox.Visible = Visible
                        end,
                    }

                    RegisterElement(TextboxObject)
                    if Flag then
                        RegisterFlag(Flag, State)
                    end
                    AddElement(TextboxObject)
                    return TextboxObject
                end

                SectionObject.AddDropdown = function(Self, DropdownData)
                    local DropdownName = DropdownData.Name or "Dropdown"
                    local Items = DropdownData.Items or {}
                    local Default = DropdownData.Default
                    local Multi = DropdownData.Multi
                    local MaxHeight = DropdownData.MaxSize or 168
                    local Flag = DropdownData.Flag
                    local Callback = DropdownData.Callback or function() end

                    local Dropdown = Create("TextButton", {
                        Name = "Dropdown",
                        BackgroundColor3 = Theme.Element,
                        BorderSizePixel = 0,
                        Size = UDim2New(1, 0, 0, 36),
                        AutomaticSize = Enum.AutomaticSize.None,
                        Text = "",
                        AutoButtonColor = false,
                        Parent = Content,
                    })
                    MakeCorner(Dropdown, 6)

                    local DropdownLabel = Create("TextLabel", {
                        Name = "Label",
                        BackgroundTransparency = 1,
                        Size = UDim2New(1, -100, 1, 0),
                        Position = UDim2New(0, 12, 0, 0),
                        Text = DropdownName,
                    })
                    ApplyFont(DropdownLabel, BodySize, Theme.Text)
                    DropdownLabel.Parent = Dropdown

                    local Display = Create("TextLabel", {
                        Name = "Display",
                        BackgroundTransparency = 1,
                        Size = UDim2New(0, 90, 1, 0),
                        Position = UDim2New(1, -100, 0, 0),
                        Text = "",
                    })
                    ApplyFont(Display, BodySize, Theme.Accent)
                    Display.TextXAlignment = Enum.TextXAlignment.Right
                    Display.Parent = Dropdown

                    local Chevron = Create("ImageLabel", {
                        Name = "Chevron",
                        BackgroundTransparency = 1,
                        Size = UDim2New(0, 14, 0, 14),
                        Position = UDim2New(1, -16, 0.5, -7),
                        Image = "rbxassetid://6031094670",
                        ImageColor3 = Theme.Faded,
                        Parent = Dropdown,
                    })

                    local ListFrame = Create("Frame", {
                        Name = "List",
                        BackgroundColor3 = Theme.Section,
                        BorderSizePixel = 0,
                        Size = UDim2New(1, 0, 0, 0),
                        Position = UDim2New(0, 0, 1, 4),
                        Visible = false,
                        ZIndex = 10,
                        Parent = Dropdown,
                    })
                    MakeCorner(ListFrame, 4)
                    MakeStroke(ListFrame, Theme.Border, 1, 0)
                    local ListScroller = Create("ScrollingFrame", {
                        Name = "Scroller",
                        BackgroundTransparency = 1,
                        Size = UDim2New(1, 0, 1, 0),
                        ScrollBarThickness = 2,
                        ScrollBarImageColor3 = Theme.Accent,
                        CanvasSize = UDim2New(0, 0, 0, 0),
                        AutomaticCanvasSize = Enum.AutomaticSize.Y,
                        Parent = ListFrame,
                    })
                    MakePadding(ListScroller, 6)
                    local ScrollerList = MakeList(ListScroller, 4)

                    local Selected = Multi and {} or (Default or nil)
                    local Open = false

                    local UpdateDisplay = function()
                        if Multi then
                            if #Selected == 0 then
                                Display.Text = "None"
                            elseif #Selected == 1 then
                                Display.Text = Selected[1]
                            else
                                Display.Text = #Selected .. " selected"
                            end
                        else
                            Display.Text = Selected or "None"
                        end
                    end

                    local NotifyChange = function()
                        if Flag then
                            RegisterFlag(Flag, Multi and Selected or Selected)
                        end
                        Callback(Multi and Selected or Selected)
                    end

                    local RemoveItem = function(Name)
                        for Index, Item in next, ListScroller:GetChildren() do
                            if Item:IsA("TextButton") and Item.Name == Name then
                                Item:Destroy()
                            end
                        end
                        if Multi then
                            local Pos = TableFind(Selected, Name)
                            if Pos then
                                TableRemove(Selected, Pos)
                                UpdateDisplay()
                                NotifyChange()
                            end
                        else
                            if Selected == Name then
                                Selected = nil
                                UpdateDisplay()
                                NotifyChange()
                            end
                        end
                    end

                    local AddItem = function(Name)
                        local ItemBtn = Create("TextButton", {
                            Name = Name,
                            BackgroundColor3 = Theme.Element,
                            BackgroundTransparency = 1,
                            BorderSizePixel = 0,
                            Size = UDim2New(1, 0, 0, 24),
                            Text = "",
                            AutoButtonColor = false,
                            Parent = ListScroller,
                        })
                        MakeCorner(ItemBtn, 4)

                        local ItemLabel = Create("TextLabel", {
                            BackgroundTransparency = 1,
                            Size = UDim2New(1, -20, 1, 0),
                            Position = UDim2New(0, 10, 0, 0),
                            Text = Name,
                        })
                        ApplyFont(ItemLabel, BodySize, Theme.Subtext)
                        ItemLabel.TextXAlignment = Enum.TextXAlignment.Left
                        ItemLabel.Parent = ItemBtn

                        local IsSelected = function()
                            if Multi then
                                return TableFind(Selected, Name) ~= nil
                            else
                                return Selected == Name
                            end
                        end

                        local RefreshItem = function()
                            if IsSelected() then
                                Tween(ItemBtn, { BackgroundTransparency = 0, BackgroundColor3 = Theme.AccentDim }, 0.15)
                                Tween(ItemLabel, { TextColor3 = Theme.Accent }, 0.15)
                            else
                                Tween(ItemBtn, { BackgroundTransparency = 1 }, 0.15)
                                Tween(ItemLabel, { TextColor3 = Theme.Subtext }, 0.15)
                            end
                        end

                        Hover(ItemBtn, function()
                            if not IsSelected() then
                                Tween(ItemBtn, { BackgroundTransparency = 0, BackgroundColor3 = Theme.ElementHover }, 0.12)
                                Tween(ItemLabel, { TextColor3 = Theme.Text }, 0.12)
                            end
                        end, function()
                            RefreshItem()
                        end)

                        Connect(ItemBtn.MouseButton1Click, function()
                            if Multi then
                                local Pos = TableFind(Selected, Name)
                                if Pos then
                                    TableRemove(Selected, Pos)
                                else
                                    TableInsert(Selected, Name)
                                end
                            else
                                Selected = Name
                                if Open then
                                    local Close = function()
                                        Open = false
                                        Tween(ListFrame, { Size = UDim2New(1, 0, 0, 0) }, 0.15)
                                        Tween(Chevron, { Rotation = 0 }, 0.15)
                                        task.delay(0.16, function()
                                            ListFrame.Visible = false
                                        end)
                                    end
                                    Close()
                                end
                            end
                            UpdateDisplay()
                            RefreshItem()
                            NotifyChange()
                        end)

                        RefreshItem()
                    end

                    local Refresh = function(NewItems)
                        Items = NewItems or Items
                        for _, Child in next, ListScroller:GetChildren() do
                            if Child:IsA("TextButton") then
                                Child:Destroy()
                            end
                        end
                        for _, Item in next, Items do
                            AddItem(Item)
                        end
                    end

                    local ToggleOpen = function()
                        Open = not Open
                        if Open then
                            ListFrame.Visible = true
                            local Height = MathMin(MaxHeight, #Items * 28 + 12)
                            Tween(ListFrame, { Size = UDim2New(1, 0, 0, Height) }, 0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
                            Tween(Chevron, { Rotation = 180 }, 0.18)
                            Dropdown.AutomaticSize = Enum.AutomaticSize.Y
                            task.delay(0.18, function()
                                if Open then
                                    Dropdown.AutomaticSize = Enum.AutomaticSize.None
                                    Dropdown.Size = UDim2New(1, 0, 0, 36 + Height + 4)
                                end
                            end)
                        else
                            Dropdown.AutomaticSize = Enum.AutomaticSize.None
                            Tween(ListFrame, { Size = UDim2New(1, 0, 0, 0) }, 0.15)
                            Tween(Chevron, { Rotation = 0 }, 0.15)
                            Tween(Dropdown, { Size = UDim2New(1, 0, 0, 36) }, 0.15)
                            task.delay(0.16, function()
                                ListFrame.Visible = false
                            end)
                        end
                    end

                    Hover(Dropdown, function()
                        Tween(Chevron, { ImageColor3 = Theme.Accent }, 0.15)
                    end, function()
                        if not Open then
                            Tween(Chevron, { ImageColor3 = Theme.Faded }, 0.15)
                        end
                    end)

                    Connect(Dropdown.MouseButton1Click, function()
                        ToggleOpen()
                    end)

                    local DropdownObject = {
                        Frame = Dropdown,
                        Label = DropdownLabel,
                        Display = Display,
                        List = ListFrame,
                        Scroller = ListScroller,
                        Chevron = Chevron,
                        Section = SectionObject,
                        Set = function(Self, Value)
                            if Multi then
                                Selected = {}
                                if type(Value) == "table" then
                                    for _, V in next, Value do
                                        TableInsert(Selected, V)
                                    end
                                end
                            else
                                Selected = Value
                            end
                            UpdateDisplay()
                            NotifyChange()
                            for _, Child in next, ListScroller:GetChildren() do
                                if Child:IsA("TextButton") then
                                    local ItemLabel = Child:FindFirstChild("TextLabel")
                                    if ItemLabel then
                                        local IsSel = Multi and (TableFind(Selected, Child.Name) ~= nil) or (Selected == Child.Name)
                                        if IsSel then
                                            Tween(Child, { BackgroundTransparency = 0, BackgroundColor3 = Theme.AccentDim })
                                            Tween(ItemLabel, { TextColor3 = Theme.Accent })
                                        else
                                            Tween(Child, { BackgroundTransparency = 1 })
                                            Tween(ItemLabel, { TextColor3 = Theme.Subtext })
                                        end
                                    end
                                end
                            end
                        end,
                        Get = function(Self)
                            return Multi and Selected or Selected
                        end,
                        Add = function(Self, ...) AddItem(...) end,
                        Remove = function(Self, ...) RemoveItem(...) end,
                        Refresh = function(Self, ...) Refresh(...) end,
                        SetOpen = function(Self, ShouldOpen)
                            if ShouldOpen and not Open then
                                ToggleOpen()
                            elseif not ShouldOpen and Open then
                                ToggleOpen()
                            end
                        end,
                        SetVisibility = function(Self, Visible)
                            Dropdown.Visible = Visible
                        end,
                    }

                    RegisterElement(DropdownObject)
                    if Flag then
                        RegisterFlag(Flag, Selected)
                    end
                    Refresh(Items)
                    UpdateDisplay()
                    AddElement(DropdownObject)
                    return DropdownObject
                end

                SectionObject.AddKeybindInternal = function(Self, Parent, KeybindData)
                    local KeybindName = KeybindData.Name or "Keybind"
                    local Default = KeybindData.Default or Enum.KeyCode.B
                    local Mode = KeybindData.Mode or "Toggle"
                    local Flag = KeybindData.Flag
                    local Callback = KeybindData.Callback or function() end

                    local Container = Create("Frame", {
                        Name = "KeybindSlot",
                        BackgroundTransparency = 1,
                        Size = UDim2New(0, 60, 0, 18),
                        Position = UDim2New(1, -68, 0.5, -9),
                        Parent = Parent,
                    })

                    local Btn = Create("TextButton", {
                        Name = "Btn",
                        BackgroundColor3 = Theme.SliderTrack,
                        BorderSizePixel = 0,
                        Size = UDim2New(1, 0, 1, 0),
                        Text = "",
                        AutoButtonColor = false,
                        Parent = Container,
                    })
                    MakeCorner(Btn, 4)
                    MakeStroke(Btn, Theme.Border, 1, 0)

                    local BtnLabel = Create("TextLabel", {
                        BackgroundTransparency = 1,
                        Size = UDim2New(1, 0, 1, 0),
                        Text = GetShortKey(Default),
                    })
                    ApplyFont(BtnLabel, SmallSize, Theme.Subtext)
                    BtnLabel.TextXAlignment = Enum.TextXAlignment.Center
                    BtnLabel.Parent = Btn

                    local State = Default
                    local CurrentMode = Mode
                    local Listening = false
                    local Active = false

                    local KeybindEntry = {
                        Name = KeybindName,
                        Key = State,
                        Mode = CurrentMode,
                        Active = false,
                        Visible = true,
                    }

                    TableInsert(Library.Keybinds, KeybindEntry)

                    local UpdateKey = function(NewKey)
                        State = NewKey
                        BtnLabel.Text = GetShortKey(NewKey)
                        KeybindEntry.Key = NewKey
                        if Flag then
                            RegisterFlag(Flag, NewKey)
                        end
                    end

                    local UpdateMode = function(NewMode)
                        CurrentMode = NewMode
                        KeybindEntry.Mode = NewMode
                    end

                    local SetListening = function(ShouldListen)
                        Listening = ShouldListen
                        if Listening then
                            BtnLabel.Text = "..."
                            Tween(Btn, { BackgroundColor3 = Theme.AccentDim }, 0.15)
                            Tween(BtnLabel, { TextColor3 = Theme.Accent }, 0.15)
                        else
                            BtnLabel.Text = GetShortKey(State)
                            Tween(Btn, { BackgroundColor3 = Theme.SliderTrack }, 0.15)
                            Tween(BtnLabel, { TextColor3 = Theme.Subtext }, 0.15)
                        end
                    end

                    Hover(Btn, function()
                        if not Listening then
                            Tween(Btn, { BackgroundColor3 = Theme.ElementHover }, 0.15)
                            Tween(BtnLabel, { TextColor3 = Theme.Text }, 0.15)
                        end
                    end, function()
                        if not Listening then
                            Tween(Btn, { BackgroundColor3 = Theme.SliderTrack }, 0.15)
                            Tween(BtnLabel, { TextColor3 = Theme.Subtext }, 0.15)
                        end
                    end)

                    Connect(Btn.MouseButton1Click, function()
                        SetListening(not Listening)
                    end)

                    Connect(Services.UserInputService.InputBegan, function(Input, Processed)
                        if Listening then
                            if Input.UserInputType == Enum.UserInputType.Keyboard then
                                UpdateKey(Input.KeyCode)
                                SetListening(false)
                            elseif Input.UserInputType == Enum.UserInputType.MouseButton1 then
                                UpdateKey(Enum.KeyCode.MouseButton1)
                                SetListening(false)
                            elseif Input.UserInputType == Enum.UserInputType.MouseButton2 then
                                UpdateKey(Enum.KeyCode.MouseButton2)
                                SetListening(false)
                            end
                            return
                        end
                        if Processed then return end
                        if Input.UserInputType == Enum.UserInputType.Keyboard and Input.KeyCode == State then
                            if CurrentMode == "Toggle" then
                                Active = not Active
                                KeybindEntry.Active = Active
                                Callback(Active)
                            elseif CurrentMode == "Hold" then
                                Active = true
                                KeybindEntry.Active = true
                                Callback(true)
                            end
                        elseif Input.UserInputType == Enum.UserInputType.MouseButton1 and State == Enum.KeyCode.MouseButton1 then
                            if CurrentMode == "Toggle" then
                                Active = not Active
                                KeybindEntry.Active = Active
                                Callback(Active)
                            elseif CurrentMode == "Hold" then
                                Active = true
                                KeybindEntry.Active = true
                                Callback(true)
                            end
                        elseif Input.UserInputType == Enum.UserInputType.MouseButton2 and State == Enum.KeyCode.MouseButton2 then
                            if CurrentMode == "Toggle" then
                                Active = not Active
                                KeybindEntry.Active = Active
                                Callback(Active)
                            elseif CurrentMode == "Hold" then
                                Active = true
                                KeybindEntry.Active = true
                                Callback(true)
                            end
                        end
                    end)

                    Connect(Services.UserInputService.InputEnded, function(Input, Processed)
                        if Processed then return end
                        if CurrentMode ~= "Hold" then return end
                        if Input.UserInputType == Enum.UserInputType.Keyboard and Input.KeyCode == State then
                            Active = false
                            KeybindEntry.Active = false
                            Callback(false)
                        elseif Input.UserInputType == Enum.UserInputType.MouseButton1 and State == Enum.KeyCode.MouseButton1 then
                            Active = false
                            KeybindEntry.Active = false
                            Callback(false)
                        elseif Input.UserInputType == Enum.UserInputType.MouseButton2 and State == Enum.KeyCode.MouseButton2 then
                            Active = false
                            KeybindEntry.Active = false
                            Callback(false)
                        end
                    end)

                    UpdateKey(Default)
                    if Library.KeybindList then
                        Library.KeybindList:Refresh()
                    end

                    return {
                        Frame = Container,
                        Button = Btn,
                        Label = BtnLabel,
                        Set = function(Self, ...) UpdateKey(...) end,
                        Get = function(Self)
                            return State
                        end,
                        SetMode = function(Self, ...) UpdateMode(...) end,
                        SetOpen = function(Self) end,
                        SetVisibility = function(Self, Visible)
                            Container.Visible = Visible
                            KeybindEntry.Visible = Visible
                        end,
                        HandleVisibility = function(Self) end,
                    }
                end

                SectionObject.AddKeybind = function(Self, KeybindData)
                    local Holder = Create("Frame", {
                        Name = "KeybindRow",
                        BackgroundColor3 = Theme.Element,
                        BorderSizePixel = 0,
                        Size = UDim2New(1, 0, 0, 36),
                        Parent = Content,
                    })
                    MakeCorner(Holder, 6)

                    local RowLabel = Create("TextLabel", {
                        Name = "Label",
                        BackgroundTransparency = 1,
                        Size = UDim2New(1, -80, 1, 0),
                        Position = UDim2New(0, 10, 0, 0),
                        Text = KeybindData.Name or "Keybind",
                    })
                    ApplyFont(RowLabel, BodySize, Theme.Text)
                    RowLabel.Parent = Holder

                    local Keybind = SectionObject:AddKeybindInternal(Holder, KeybindData)
                    local KeybindObject = {
                        Frame = Holder,
                        Label = RowLabel,
                        Button = Keybind.Button,
                        Section = SectionObject,
                        Set = Keybind.Set,
                        Get = Keybind.Get,
                        SetMode = Keybind.SetMode,
                        SetVisibility = function(Self, Visible)
                            Holder.Visible = Visible
                        end,
                    }
                    AddElement(KeybindObject)
                    return KeybindObject
                end

                SectionObject.AddColorpickerInternal = function(Self, Parent, ColorData)
                    local Default = ColorData.Default or Color3.fromRGB(34, 211, 238)
                    local Alpha = ColorData.Alpha or 1
                    local Flag = ColorData.Flag
                    local Callback = ColorData.Callback or function() end

                    local Swatch = Create("TextButton", {
                        Name = "Swatch",
                        BackgroundColor3 = Default,
                        BorderSizePixel = 0,
                        Size = UDim2New(0, 28, 0, 18),
                        Position = UDim2New(1, -38, 0.5, -9),
                        Text = "",
                        AutoButtonColor = false,
                        Parent = Parent,
                    })
                    MakeCorner(Swatch, 4)
                    MakeStroke(Swatch, Theme.Border, 1, 0)

                    local Hue, Sat, Val = Color3.toHSV(Default)
                    Hue = Hue or 0
                    Sat = Sat or 1
                    Val = Val or 1
                    local CurrentAlpha = Alpha
                    local PickerOpen = false

                    local Picker = Create("Frame", {
                        Name = "Picker",
                        BackgroundColor3 = Theme.Section,
                        BorderSizePixel = 0,
                        Size = UDim2New(0, 220, 0, 240),
                        Visible = false,
                        ZIndex = 100,
                        Parent = GuiParent,
                    })
                    MakeCorner(Picker, 6)
                    MakeStroke(Picker, Theme.Border, 1, 0)
                    MakePadding(Picker, 10)

                    local Palette = Create("TextButton", {
                        Name = "Palette",
                        BackgroundColor3 = Color3.fromHSV(Hue, 1, 1),
                        BorderSizePixel = 0,
                        Size = UDim2New(1, 0, 0, 120),
                        Text = "",
                        AutoButtonColor = false,
                        Parent = Picker,
                    })
                    MakeCorner(Palette, 4)
                    local SatValWhite = Create("Frame", {
                        BackgroundColor3 = Color3.new(1, 1, 1),
                        BorderSizePixel = 0,
                        Size = UDim2New(1, 0, 1, 0),
                        Parent = Palette,
                    })
                    local SatValGradient = Create("UIGradient", {
                        Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.new(1, 1, 0)),
                        Transparency = NumberSequence.new(0, 1),
                        Rotation = 0,
                    })
                    SatValGradient.Parent = SatValWhite
                    local SatValBlack = Create("Frame", {
                        BackgroundColor3 = Color3.new(0, 0, 0),
                        BorderSizePixel = 0,
                        Size = UDim2New(1, 0, 1, 0),
                        Parent = Palette,
                    })
                    local SatValBlackGradient = Create("UIGradient", {
                        Transparency = NumberSequence.new(1, 0),
                        Rotation = 90,
                    })
                    SatValBlackGradient.Parent = SatValBlack

                    local PaletteCursor = Create("Frame", {
                        Name = "Cursor",
                        BackgroundColor3 = Color3.new(1, 1, 1),
                        BorderSizePixel = 0,
                        Size = UDim2New(0, 8, 0, 8),
                        AnchorPoint = Vector2New(0.5, 0.5),
                        Position = UDim2New(Sat, 0, 1 - Val, 0),
                        ZIndex = 5,
                        Parent = Palette,
                    })
                    MakeCorner(PaletteCursor, 4)
                    MakeStroke(PaletteCursor, Color3.new(0, 0, 0), 1, 0)

                    local HueBar = Create("TextButton", {
                        Name = "HueBar",
                        BackgroundColor3 = Color3.new(1, 1, 1),
                        BorderSizePixel = 0,
                        Size = UDim2New(1, 0, 0, 12),
                        Position = UDim2New(0, 0, 0, 132),
                        Text = "",
                        AutoButtonColor = false,
                        Parent = Picker,
                    })
                    MakeCorner(HueBar, 6)
                    local HueGradient = Create("UIGradient", {
                        Color = ColorSequence.new({
                            ColorSequenceKeypoint.new(0, Color3.fromHSV(0, 1, 1)),
                            ColorSequenceKeypoint.new(0.17, Color3.fromHSV(0.17, 1, 1)),
                            ColorSequenceKeypoint.new(0.33, Color3.fromHSV(0.33, 1, 1)),
                            ColorSequenceKeypoint.new(0.5, Color3.fromHSV(0.5, 1, 1)),
                            ColorSequenceKeypoint.new(0.67, Color3.fromHSV(0.67, 1, 1)),
                            ColorSequenceKeypoint.new(0.83, Color3.fromHSV(0.83, 1, 1)),
                            ColorSequenceKeypoint.new(1, Color3.fromHSV(1, 1, 1)),
                        }),
                    })
                    HueGradient.Parent = HueBar

                    local HueCursor = Create("Frame", {
                        Name = "HueCursor",
                        BackgroundColor3 = Color3.new(1, 1, 1),
                        BorderSizePixel = 0,
                        Size = UDim2New(0, 6, 0, 16),
                        AnchorPoint = Vector2New(0.5, 0.5),
                        Position = UDim2New(Hue, 0, 0.5, 0),
                        ZIndex = 5,
                        Parent = HueBar,
                    })
                    MakeCorner(HueCursor, 3)
                    MakeStroke(HueCursor, Color3.new(0, 0, 0), 1, 0)

                    local AlphaBar = Create("TextButton", {
                        Name = "AlphaBar",
                        BackgroundColor3 = Color3.new(1, 1, 1),
                        BorderSizePixel = 0,
                        Size = UDim2New(1, 0, 0, 12),
                        Position = UDim2New(0, 0, 0, 154),
                        Text = "",
                        AutoButtonColor = false,
                        Parent = Picker,
                    })
                    MakeCorner(AlphaBar, 6)
                    local AlphaGradient = Create("UIGradient", {
                        Transparency = NumberSequence.new(0, 1),
                        Color = ColorSequence.new(Default, Default),
                    })
                    AlphaGradient.Parent = AlphaBar
                    local Checkers = Create("ImageLabel", {
                        BackgroundTransparency = 1,
                        Size = UDim2New(1, 0, 1, 0),
                        Image = "rbxassetid://0",
                        ImageTransparency = 1,
                        Parent = AlphaBar,
                    })

                    local AlphaCursor = Create("Frame", {
                        Name = "AlphaCursor",
                        BackgroundColor3 = Color3.new(1, 1, 1),
                        BorderSizePixel = 0,
                        Size = UDim2New(0, 6, 0, 16),
                        AnchorPoint = Vector2New(0.5, 0.5),
                        Position = UDim2New(1 - CurrentAlpha, 0, 0.5, 0),
                        ZIndex = 5,
                        Parent = AlphaBar,
                    })
                    MakeCorner(AlphaCursor, 3)
                    MakeStroke(AlphaCursor, Color3.new(0, 0, 0), 1, 0)

                    local HexBox = Create("TextBox", {
                        Name = "Hex",
                        BackgroundColor3 = Theme.Element,
                        BorderSizePixel = 0,
                        Size = UDim2New(1, 0, 0, 28),
                        Position = UDim2New(0, 0, 0, 178),
                        Text = "",
                        ClearTextOnFocus = false,
                    })
                    ApplyFont(HexBox, SmallSize, Theme.Text)
                    HexBox.TextXAlignment = Enum.TextXAlignment.Center
                    MakeCorner(HexBox, 4)
                    HexBox.Parent = Picker

                    local UpdateColor = function(SkipCallback)
                        local Color = Color3.fromHSV(Hue, Sat, Val)
                        Swatch.BackgroundColor3 = Color
                        Palette.BackgroundColor3 = Color3.fromHSV(Hue, 1, 1)
                        PaletteCursor.Position = UDim2New(Sat, 0, 1 - Val, 0)
                        HueCursor.Position = UDim2New(Hue, 0, 0.5, 0)
                        AlphaCursor.Position = UDim2New(1 - CurrentAlpha, 0, 0.5, 0)
                        AlphaGradient.Color = ColorSequence.new(Color, Color)
                        local R = MathFloor(Color.R * 255)
                        local G = MathFloor(Color.G * 255)
                        local B = MathFloor(Color.B * 255)
                        HexBox.Text = StringFormat("#%02X%02X%02X", R, G, B)
                        if Flag then
                            RegisterFlag(Flag, { Color = Color, Alpha = CurrentAlpha })
                        end
                        if not SkipCallback then
                            Callback(Color, CurrentAlpha)
                        end
                    end

                    local PaletteDragging = false
                    Connect(Palette.InputBegan, function(Input)
                        if Input.UserInputType == Enum.UserInputType.MouseButton1 then
                            PaletteDragging = true
                            local Rel = Services.UserInputService:GetMouseLocation() - Palette.AbsolutePosition
                            Sat = MathClamp(Rel.X / Palette.AbsoluteSize.X, 0, 1)
                            Val = MathClamp(1 - (Rel.Y / Palette.AbsoluteSize.Y), 0, 1)
                            UpdateColor()
                        end
                    end)
                    Connect(Palette.InputEnded, function(Input)
                        if Input.UserInputType == Enum.UserInputType.MouseButton1 then
                            PaletteDragging = false
                        end
                    end)
                    Connect(Services.UserInputService.InputChanged, function(Input)
                        if PaletteDragging and Input.UserInputType == Enum.UserInputType.MouseMovement then
                            local Rel = Services.UserInputService:GetMouseLocation() - Palette.AbsolutePosition
                            Sat = MathClamp(Rel.X / Palette.AbsoluteSize.X, 0, 1)
                            Val = MathClamp(1 - (Rel.Y / Palette.AbsoluteSize.Y), 0, 1)
                            UpdateColor()
                        end
                    end)

                    local HueDragging = false
                    Connect(HueBar.InputBegan, function(Input)
                        if Input.UserInputType == Enum.UserInputType.MouseButton1 then
                            HueDragging = true
                            local Rel = Services.UserInputService:GetMouseLocation() - HueBar.AbsolutePosition
                            Hue = MathClamp(Rel.X / HueBar.AbsoluteSize.X, 0, 1)
                            UpdateColor()
                        end
                    end)
                    Connect(HueBar.InputEnded, function(Input)
                        if Input.UserInputType == Enum.UserInputType.MouseButton1 then
                            HueDragging = false
                        end
                    end)
                    Connect(Services.UserInputService.InputChanged, function(Input)
                        if HueDragging and Input.UserInputType == Enum.UserInputType.MouseMovement then
                            local Rel = Services.UserInputService:GetMouseLocation() - HueBar.AbsolutePosition
                            Hue = MathClamp(Rel.X / HueBar.AbsoluteSize.X, 0, 1)
                            UpdateColor()
                        end
                    end)

                    local AlphaDragging = false
                    Connect(AlphaBar.InputBegan, function(Input)
                        if Input.UserInputType == Enum.UserInputType.MouseButton1 then
                            AlphaDragging = true
                            local Rel = Services.UserInputService:GetMouseLocation() - AlphaBar.AbsolutePosition
                            CurrentAlpha = MathClamp(1 - (Rel.X / AlphaBar.AbsoluteSize.X), 0, 1)
                            UpdateColor()
                        end
                    end)
                    Connect(AlphaBar.InputEnded, function(Input)
                        if Input.UserInputType == Enum.UserInputType.MouseButton1 then
                            AlphaDragging = false
                        end
                    end)
                    Connect(Services.UserInputService.InputChanged, function(Input)
                        if AlphaDragging and Input.UserInputType == Enum.UserInputType.MouseMovement then
                            local Rel = Services.UserInputService:GetMouseLocation() - AlphaBar.AbsolutePosition
                            CurrentAlpha = MathClamp(1 - (Rel.X / AlphaBar.AbsoluteSize.X), 0, 1)
                            UpdateColor()
                        end
                    end)

                    Connect(HexBox.FocusLost, function()
                        local Text = StringGSub(HexBox.Text, "#", "")
                        if #Text == 6 then
                            local Success, Color = pcall(FromHex, Text)
                            if Success then
                                Hue, Sat, Val = Color3.toHSV(Color)
                                UpdateColor()
                                return
                            end
                        end
                        UpdateColor()
                    end)

                    Hover(Swatch, function()
                        Tween(Swatch, { Size = UDim2New(0, 32, 0, 20) }, 0.15)
                    end, function()
                        Tween(Swatch, { Size = UDim2New(0, 28, 0, 18) }, 0.15)
                    end)

                    local TogglePicker = function()
                        PickerOpen = not PickerOpen
                        if PickerOpen then
                            local SwatchPos = Swatch.AbsolutePosition
                            local SwatchSize = Swatch.AbsoluteSize
                            Picker.Position = UDim2New(0, SwatchPos.X - 192, 0, SwatchPos.Y - 250)
                            Picker.Visible = true
                            Picker.Size = UDim2New(0, 220, 0, 0)
                            Tween(Picker, { Size = UDim2New(0, 220, 0, 240) }, 0.18, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
                        else
                            Tween(Picker, { Size = UDim2New(0, 220, 0, 0) }, 0.15)
                            task.delay(0.16, function()
                                if not PickerOpen then
                                    Picker.Visible = false
                                end
                            end)
                        end
                    end

                    Connect(Swatch.MouseButton1Click, function()
                        TogglePicker()
                    end)

                    Connect(Services.UserInputService.InputBegan, function(Input)
                        if PickerOpen and Input.UserInputType == Enum.UserInputType.MouseButton1 then
                            local MousePos = Services.UserInputService:GetMouseLocation()
                            local PickerPos = Picker.AbsolutePosition
                            local PickerEnd = PickerPos + Picker.AbsoluteSize
                            if MousePos.X < PickerPos.X or MousePos.X > PickerEnd.X or MousePos.Y < PickerPos.Y or MousePos.Y > PickerEnd.Y then
                                if Swatch.AbsolutePosition.X > MousePos.X or Swatch.AbsolutePosition.X + Swatch.AbsoluteSize.X < MousePos.X or Swatch.AbsolutePosition.Y > MousePos.Y or Swatch.AbsolutePosition.Y + Swatch.AbsoluteSize.Y < MousePos.Y then
                                    TogglePicker()
                                end
                            end
                        end
                    end)

                    UpdateColor(true)

                    return {
                        Frame = Swatch,
                        Picker = Picker,
                        Set = function(Self, Color, NewAlpha)
                            Hue, Sat, Val = Color3.toHSV(Color)
                            if NewAlpha then
                                CurrentAlpha = NewAlpha
                            end
                            UpdateColor()
                        end,
                        Get = function(Self)
                            return Color3.fromHSV(Hue, Sat, Val), CurrentAlpha
                        end,
                        SetOpen = function(Self, ShouldOpen)
                            if ShouldOpen and not PickerOpen then
                                TogglePicker()
                            elseif not ShouldOpen and PickerOpen then
                                TogglePicker()
                            end
                        end,
                        SetVisibility = function(Self, Visible)
                            Swatch.Visible = Visible
                        end,
                    }
                end

                SectionObject.AddColorpicker = function(Self, ColorData)
                    local Holder = Create("Frame", {
                        Name = "ColorpickerRow",
                        BackgroundColor3 = Theme.Element,
                        BorderSizePixel = 0,
                        Size = UDim2New(1, 0, 0, 36),
                        Parent = Content,
                    })
                    MakeCorner(Holder, 6)

                    local RowLabel = Create("TextLabel", {
                        Name = "Label",
                        BackgroundTransparency = 1,
                        Size = UDim2New(1, -80, 1, 0),
                        Position = UDim2New(0, 10, 0, 0),
                        Text = ColorData.Name or "Colorpicker",
                    })
                    ApplyFont(RowLabel, BodySize, Theme.Text)
                    RowLabel.Parent = Holder

                    local Picker = SectionObject:AddColorpickerInternal(Holder, ColorData)
                    local ColorObject = {
                        Frame = Holder,
                        Label = RowLabel,
                        Swatch = Picker.Frame,
                        Section = SectionObject,
                        Set = Picker.Set,
                        Get = Picker.Get,
                        SetOpen = Picker.SetOpen,
                        SetVisibility = function(Self, Visible)
                            Holder.Visible = Visible
                        end,
                    }
                    AddElement(ColorObject)
                    return ColorObject
                end

                SectionObject.AddListbox = function(Self, ListboxData)
                    local Size = ListboxData.Size or 6
                    local Items = ListboxData.Items or {}
                    local Multi = ListboxData.Multi
                    local Flag = ListboxData.Flag
                    local Callback = ListboxData.Callback or function() end

                    local Listbox = Create("Frame", {
                        Name = "Listbox",
                        BackgroundColor3 = Theme.Element,
                        BorderSizePixel = 0,
                        Size = UDim2New(1, 0, 0, 28 + Size * 24),
                        Parent = Content,
                    })
                    MakeCorner(Listbox, 6)
                    MakePadding(Listbox, 8)

                    local ListboxLabel = Create("TextLabel", {
                        Name = "Label",
                        BackgroundTransparency = 1,
                        Size = UDim2New(1, 0, 0, 16),
                        Text = ListboxData.Name or "Listbox",
                    })
                    ApplyFont(ListboxLabel, BodySize, Theme.Text)
                    ListboxLabel.Parent = Listbox

                    local Scroller = Create("ScrollingFrame", {
                        Name = "Scroller",
                        BackgroundColor3 = Theme.SliderTrack,
                        BorderSizePixel = 0,
                        Size = UDim2New(1, 0, 1, -24),
                        Position = UDim2New(0, 0, 0, 22),
                        ScrollBarThickness = 2,
                        ScrollBarImageColor3 = Theme.Accent,
                        CanvasSize = UDim2New(0, 0, 0, 0),
                        AutomaticCanvasSize = Enum.AutomaticSize.Y,
                        Parent = Listbox,
                    })
                    MakeCorner(Scroller, 4)
                    MakePadding(Scroller, 4)
                    local ScrollerList = MakeList(Scroller, 4)

                    local Selected = Multi and {} or nil

                    local Refresh = function(NewItems)
                        Items = NewItems or Items
                        for _, Child in next, Scroller:GetChildren() do
                            if Child:IsA("TextButton") then
                                Child:Destroy()
                            end
                        end
                        for _, Item in next, Items do
                            local ItemBtn = Create("TextButton", {
                                Name = Item,
                                BackgroundColor3 = Theme.Element,
                                BackgroundTransparency = 1,
                                BorderSizePixel = 0,
                                Size = UDim2New(1, 0, 0, 22),
                                Text = "",
                                AutoButtonColor = false,
                                Parent = Scroller,
                            })
                            MakeCorner(ItemBtn, 3)
                            local ItemLabel = Create("TextLabel", {
                                BackgroundTransparency = 1,
                                Size = UDim2New(1, -12, 1, 0),
                                Position = UDim2New(0, 8, 0, 0),
                                Text = Item,
                            })
                            ApplyFont(ItemLabel, SmallSize, Theme.Subtext)
                            ItemLabel.TextXAlignment = Enum.TextXAlignment.Left
                            ItemLabel.Parent = ItemBtn

                            local IsSelected = function()
                                if Multi then
                                    return TableFind(Selected, Item) ~= nil
                                else
                                    return Selected == Item
                                end
                            end

                            local RefreshItem = function()
                                if IsSelected() then
                                    Tween(ItemBtn, { BackgroundTransparency = 0, BackgroundColor3 = Theme.AccentDim }, 0.15)
                                    Tween(ItemLabel, { TextColor3 = Theme.Accent }, 0.15)
                                else
                                    Tween(ItemBtn, { BackgroundTransparency = 1 }, 0.15)
                                    Tween(ItemLabel, { TextColor3 = Theme.Subtext }, 0.15)
                                end
                            end

                            Hover(ItemBtn, function()
                                if not IsSelected() then
                                    Tween(ItemBtn, { BackgroundTransparency = 0, BackgroundColor3 = Theme.ElementHover }, 0.12)
                                    Tween(ItemLabel, { TextColor3 = Theme.Text }, 0.12)
                                end
                            end, function()
                                RefreshItem()
                            end)

                            Connect(ItemBtn.MouseButton1Click, function()
                                if Multi then
                                    local Pos = TableFind(Selected, Item)
                                    if Pos then
                                        TableRemove(Selected, Pos)
                                    else
                                        TableInsert(Selected, Item)
                                    end
                                else
                                    Selected = Item
                                end
                                RefreshItem()
                                if Flag then
                                    RegisterFlag(Flag, Multi and Selected or Selected)
                                end
                                Callback(Multi and Selected or Selected)
                            end)

                            RefreshItem()
                        end
                    end

                    Refresh(Items)

                    local ListboxObject = {
                        Frame = Listbox,
                        Label = ListboxLabel,
                        Scroller = Scroller,
                        Section = SectionObject,
                        Set = function(Self, Value)
                            if Multi then
                                Selected = {}
                                if type(Value) == "table" then
                                    for _, V in next, Value do
                                        TableInsert(Selected, V)
                                    end
                                end
                            else
                                Selected = Value
                            end
                            Refresh()
                            if Flag then
                                RegisterFlag(Flag, Selected)
                            end
                            Callback(Selected)
                        end,
                        Get = function(Self)
                            return Selected
                        end,
                        Add = function(Self, Item)
                            TableInsert(Items, Item)
                            Refresh()
                        end,
                        Remove = function(Self, Item)
                            for Index, V in next, Items do
                                if V == Item then
                                    TableRemove(Items, Index)
                                    break
                                end
                            end
                            if Multi then
                                local Pos = TableFind(Selected, Item)
                                if Pos then
                                    TableRemove(Selected, Pos)
                                end
                            elseif Selected == Item then
                                Selected = nil
                            end
                            Refresh()
                        end,
                        Refresh = function(Self, ...) Refresh(...) end,
                        SetVisibility = function(Self, Visible)
                            Listbox.Visible = Visible
                        end,
                    }

                    RegisterElement(ListboxObject)
                    if Flag then
                        RegisterFlag(Flag, Selected)
                    end
                    AddElement(ListboxObject)
                    return ListboxObject
                end

                SectionObject.AddDivider = function(Self)
                    local Divider = Create("Frame", {
                        Name = "Divider",
                        BackgroundColor3 = Theme.Border,
                        BorderSizePixel = 0,
                        Size = UDim2New(1, 0, 0, 1),
                        Parent = Content,
                    })
                    return Divider
                end

                return SectionObject
            end

            TableInsert(TabObject.Pages, PageObject)
            return PageObject
        end

        TableInsert(WindowData.Tabs, TabObject)

        if not WindowData.ActiveTab then
            TabObject:Select()
        end

        return TabObject
    end

    WindowData.Show = function(Self)
        if not WindowData.Visible then
            WindowData.Visible = true
            Holder.Enabled = true
        end
    end

    WindowData.Hide = function(Self)
        if WindowData.Visible then
            WindowData.Visible = false
            Holder.Enabled = false
        end
    end

    WindowData.Toggle = function(Self)
        if WindowData.Visible then
            WindowData:Hide()
        else
            WindowData:Show()
        end
    end

    return WindowData
end

Library.Notification = function(Self, Data)
    if type(Data) == "string" then
        Data = { Text = Data }
    end
    local Text = Data.Text or "Notification"
    local Duration = Data.Duration or 4
    local Color = Data.Color or Theme.Accent
    local Title = Data.Title or "Notice"

    if not Library.NotificationStack then
        local Stack = Create("Frame", {
            Name = "NotificationStack",
            BackgroundTransparency = 1,
            Size = UDim2New(0, 320, 1, -20),
            Position = UDim2New(1, -340, 0, 20),
            Parent = GuiParent,
        })
        local StackList = MakeList(Stack, 8, Enum.SortOrder.LayoutOrder)
        StackList.VerticalAlignment = Enum.VerticalAlignment.Top
        Library.NotificationStack = Stack
        Library.NotificationStackList = StackList
        Library.NotificationStackOrder = 0
    end

    Library.NotificationStackOrder = Library.NotificationStackOrder + 1

    local Card = Create("Frame", {
        Name = "Notification",
        BackgroundColor3 = Theme.Section,
        BorderSizePixel = 0,
        Size = UDim2New(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        LayoutOrder = Library.NotificationStackOrder,
        Parent = Library.NotificationStack,
    })
    MakeCorner(Card, 6)
    MakeStroke(Card, Theme.Border, 1, 0)

    local AccentBar = Create("Frame", {
        Name = "Accent",
        BackgroundColor3 = Color,
        BorderSizePixel = 0,
        Size = UDim2New(0, 3, 1, 0),
        Parent = Card,
    })
    MakeCorner(AccentBar, 1.5)

    local Inner = Create("Frame", {
        Name = "Inner",
        BackgroundTransparency = 1,
        Size = UDim2New(1, -16, 0, 0),
        Position = UDim2New(0, 12, 0, 10),
        AutomaticSize = Enum.AutomaticSize.Y,
        Parent = Card,
    })
    local InnerList = MakeList(Inner, 4)

    local TitleLabel = Create("TextLabel", {
        Name = "Title",
        BackgroundTransparency = 1,
        Size = UDim2New(1, 0, 0, 14),
        Text = Title,
    })
    ApplyFont(TitleLabel, 11, Color)
    TitleLabel.Parent = Inner

    local Body = Create("TextLabel", {
        Name = "Body",
        BackgroundTransparency = 1,
        Size = UDim2New(1, 0, 0, 14),
        Text = Text,
        TextWrapped = true,
    })
    ApplyFont(Body, BodySize, Theme.Text)
    Body.TextXAlignment = Enum.TextXAlignment.Left
    Body.Parent = Inner

    local Progress = Create("Frame", {
        Name = "Progress",
        BackgroundColor3 = Color,
        BackgroundTransparency = 0.6,
        BorderSizePixel = 0,
        Size = UDim2New(1, 0, 0, 2),
        Position = UDim2New(0, 0, 1, -2),
        Parent = Card,
    })
    MakeCorner(Progress, 1)

    Card.Size = UDim2New(1, 0, 0, 0)
    Tween(Card, { Size = UDim2New(1, 0, 0, 60) }, 0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

    task.delay(Duration, function()
        Tween(Card, { Size = UDim2New(1, 0, 0, 0) }, 0.2)
        task.delay(0.21, function()
            Card:Destroy()
        end)
    end)

    return Card
end

Library.Watermark = function(Self, Data)
    if type(Data) == "string" then
        Data = { Text = Data }
    end
    local Text = Data.Text or "Modern UI"

    local Mark = Create("Frame", {
        Name = "Watermark",
        BackgroundColor3 = Theme.Window,
        BorderSizePixel = 0,
        Size = UDim2New(0, 200, 0, 30),
        Position = UDim2New(0, 16, 0, 16),
        Parent = GuiParent,
    })
    MakeCorner(Mark, 6)
    MakeStroke(Mark, Theme.Border, 1, 0)

    local Accent = Create("Frame", {
        BackgroundColor3 = Theme.Accent,
        BorderSizePixel = 0,
        Size = UDim2New(0, 3, 0, 14),
        Position = UDim2New(0, 8, 0.5, -7),
        Parent = Mark,
    })
    MakeCorner(Accent, 2)

    local Label = Create("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2New(1, -30, 1, 0),
        Position = UDim2New(0, 18, 0, 0),
        Text = Text,
    })
    ApplyFont(Label, SmallSize, Theme.Text)
    Label.Parent = Mark

    local StatsLabel = Create("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2New(0, 80, 1, 0),
        Position = UDim2New(1, -88, 0, 0),
        Text = "",
    })
    ApplyFont(StatsLabel, SmallSize, Theme.Faded)
    StatsLabel.TextXAlignment = Enum.TextXAlignment.Right
    StatsLabel.Parent = Mark

    local RenderConnect
    RenderConnect = Services.RunService.RenderStepped:Connect(function()
        local Fps = MathFloor(1 / Services.RunService.RenderStepped:Wait())
        local Ping = 0
        pcall(function()
            Ping = MathFloor(LocalPlayer:GetNetworkPing() * 1000)
        end)
        StatsLabel.Text = StringFormat("%d fps | %d ms", Fps, Ping)
    end)
    TableInsert(Library.Connections, RenderConnect)

    local WatermarkObject = {
        Frame = Mark,
        Label = Label,
        SetText = function(Self, NewText)
            Label.Text = NewText
        end,
        SetVisibility = function(Self, Visible)
            Mark.Visible = Visible
        end,
    }
    Library.Watermark = WatermarkObject
    return WatermarkObject
end

Library.KeybindList = function(Self)
    local Container = Create("Frame", {
        Name = "KeybindList",
        BackgroundTransparency = 1,
        Size = UDim2New(0, 220, 1, -32),
        Position = UDim2New(0, 16, 0, 60),
        Parent = GuiParent,
    })
    local List = MakeList(Container, 6, Enum.SortOrder.LayoutOrder)
    List.VerticalAlignment = Enum.VerticalAlignment.Top

    local Items = {}

    local Refresh = function()
        for _, Child in next, Container:GetChildren() do
            if Child:IsA("Frame") then
                Child:Destroy()
            end
        end
        Items = {}
        local Order = 0
        for _, Kb in next, Library.Keybinds do
            if Kb.Active and Kb.Visible then
                Order = Order + 1
                local Row = Create("Frame", {
                    Name = "Item",
                    BackgroundColor3 = Theme.Section,
                    BorderSizePixel = 0,
                    Size = UDim2New(1, 0, 0, 28),
                    LayoutOrder = Order,
                    Parent = Container,
                })
                MakeCorner(Row, 4)
                MakeStroke(Row, Theme.Border, 1, 0)

                local NameLabel = Create("TextLabel", {
                    BackgroundTransparency = 1,
                    Size = UDim2New(1, -90, 1, 0),
                    Position = UDim2New(0, 10, 0, 0),
                    Text = Kb.Name,
                })
                ApplyFont(NameLabel, SmallSize, Theme.Text)
                NameLabel.Parent = Row

                local KeyLabel = Create("TextLabel", {
                    BackgroundTransparency = 1,
                    Size = UDim2New(0, 80, 1, 0),
                    Position = UDim2New(1, -86, 0, 0),
                    Text = GetShortKey(Kb.Key),
                })
                ApplyFont(KeyLabel, SmallSize, Theme.Accent)
                KeyLabel.TextXAlignment = Enum.TextXAlignment.Right
                KeyLabel.Parent = Row

                TableInsert(Items, Row)
            end
        end
    end

    local RenderConnect
    RenderConnect = Services.RunService.Heartbeat:Connect(function()
        Refresh()
    end)
    TableInsert(Library.Connections, RenderConnect)

    local ListObject = {
        Container = Container,
        Refresh = function(Self, ...) Refresh(...) end,
        SetVisibility = function(Self, Visible)
            Container.Visible = Visible
        end,
    }
    Library.KeybindList = ListObject
    return ListObject
end

Library.ConfigManager = function(Self)
    local Manager = {
        Directory = Library.Folders.Configs,
        Loaded = nil,
    }

    Manager.ListConfigs = function()
        if not listfiles then
            return {}
        end
        local Success, Result = pcall(listfiles, Manager.Directory)
        if not Success then
            return {}
        end
        local Names = {}
        for _, Path in next, Result do
            local Name = StringGSub(Path, Manager.Directory .. "/", "")
            Name = StringGSub(Name, ".json", "")
            TableInsert(Names, Name)
        end
        return Names
    end

    Manager.Save = function(Name)
        if not writefile then
            return false
        end
        if not isfolder(Manager.Directory) then
            makefolder(Manager.Directory)
        end
        local Path = Manager.Directory .. "/" .. Name .. ".json"
        local Data = {}
        for Flag, Value in next, Library.Flags do
            if typeof(Value) == "Color3" then
                Data[Flag] = { Type = "Color3", R = Value.R, G = Value.G, B = Value.B }
            else
                Data[Flag] = Value
            end
        end
        local Encoded = HttpService:JSONEncode(Data)
        writefile(Path, Encoded)
        Manager.Loaded = Name
        return true
    end

    Manager.Load = function(Name)
        if not readfile then
            return false
        end
        local Path = Manager.Directory .. "/" .. Name .. ".json"
        if not isfile(Path) then
            return false
        end
        local Content = readfile(Path)
        local Success, Data = pcall(Services.HttpService.JSONDecode, Services.HttpService, Content)
        if not Success then
            return false
        end
        for Flag, Value in next, Data do
            if type(Value) == "table" and Value.Type == "Color3" then
                Library.Flags[Flag] = Color3.new(Value.R, Value.G, Value.B)
            else
                Library.Flags[Flag] = Value
            end
        end
        Manager.Loaded = Name
        return true
    end

    Manager.Delete = function(Name)
        if not delfile then
            return false
        end
        local Path = Manager.Directory .. "/" .. Name .. ".json"
        if isfile(Path) then
            delfile(Path)
            return true
        end
        return false
    end

    return Manager
end

Library.Unload = function(Self)
    for _, Connection in next, Library.Connections do
        pcall(function()
            Connection:Disconnect()
        end)
    end
    Library.Connections = {}
    if Library.Window then
        pcall(function()
            Library.Window.Gui:Destroy()
        end)
        Library.Window = nil
    end
    if Library.Watermark then
        pcall(function()
            if Library.Watermark.Frame then
                Library.Watermark.Frame:Destroy()
            end
        end)
        Library.Watermark = nil
    end
    if Library.KeybindList then
        pcall(function()
            if Library.KeybindList.Container then
                Library.KeybindList.Container:Destroy()
            end
        end)
        Library.KeybindList = nil
    end
    if Library.NotificationStack then
        pcall(function()
            Library.NotificationStack:Destroy()
        end)
        Library.NotificationStack = nil
    end
    Library.Flags = {}
    Library.Keybinds = {}
    Library.ActiveElements = {}
    if getgenv then
        getgenv().ModernLibrary = nil
    end
end

return Library
