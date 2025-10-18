--[[
#######################################
# IWin UI - Configuration Interface  #
# Version 3.0 - Complete Overhaul    #
#######################################
]]

-- Ensure IWin table exists before extending it
IWin = IWin or {}
IWin.UI = IWin.UI or {}

-- State management
IWin.UI.frame = nil
IWin.UI.tabs = {}
IWin.UI.currentTab = 1
IWin.UI.backup = {}
IWin.UI.controls = {}
IWin.UI.searchBox = nil
IWin.UI.compareMode = false
IWin.UI.minimapButton = nil

-- Constants
local FRAME_WIDTH = 620  -- Increased from 520
local FRAME_HEIGHT = 580  -- Increased from 520
local TAB_HEIGHT = 24
local CONTENT_HEIGHT = 425  -- Height to avoid overlapping bottom buttons
local BUTTON_HEIGHT = 25

-- Spacing constants (vertical rhythm)
local SPACING = {
    SECTION_GAP = 20,
    CONTROL_GAP = 40,
    HEADER_GAP = 30,
    PADDING = 15,
    INNER_PADDING = 10
}

-- Color scheme
local COLORS = {
    -- Setting type colors
    RAGE = {0.2, 0.4, 0.8},      -- Blue
    TIME = {0.2, 0.8, 0.4},      -- Green
    HEALTH = {0.8, 0.2, 0.2},    -- Red
    TOGGLE = {1, 0.82, 0},       -- Gold

    -- UI element colors
    HEADER = {1, 0.82, 0},       -- Gold
    DEFAULT_VALUE = {0.5, 1, 0.5}, -- Light green
    MODIFIED = {1, 0.5, 0},      -- Orange
    SECTION_BG = {0.1, 0.1, 0.2, 0.5},
    SECTION_BORDER = {0.4, 0.4, 0.6, 1}
}

-- Default values for all settings
IWin.UI.DEFAULTS = {
    -- Feature toggles
    AutoCharge = true,
    AutoBattleShout = true,
    AutoBloodrage = true,
    AutoTrinkets = true,
    AutoRend = true,
    AutoAttack = true,
    AutoStance = true,
    AutoShieldBlock = true,
    SkipThunderClapWithThunderfury = true,
    BattleShoutAOEMode = true,
    AutoInterrupt = true,
    SmartHeroicStrike = true,
    AutoRevenge = true,

    -- Rage thresholds (DPS)
    RageChargeMax = 50,
    RageBloodrageMin = 30,
    RageBloodthirstMin = 30,
    RageMortalStrikeMin = 30,
    RageWhirlwindMin = 25,
    RageSweepingMin = 30,
    RageHeroicMin = 30,
    RageCleaveMin = 30,
    RageShoutMin = 10,
    RageShoutCombatMin = 30,
    RageOverpowerMin = 5,
    RageExecuteMin = 10,
    RageRendMin = 10,
    RageInterruptMin = 10,

    -- Rage thresholds (Tank)
    RageShieldSlamMin = 20,
    RageRevengeMin = 5,
    RageThunderClapMin = 20,
    RageDemoShoutMin = 10,
    RageSunderMin = 15,
    RageConcussionBlowMin = 15,
    RageShieldBlockMin = 10,

    -- Health thresholds
    LastStandThreshold = 20,
    ConcussionBlowThreshold = 30,

    -- Boss detection
    SunderStacksBoss = 5,
    SunderStacksTrash = 3,
    SkipRendOnTrash = true,

    -- Debuff refresh timings
    RefreshRend = 5,
    RefreshSunder = 5,
    RefreshThunderClap = 5,
    RefreshDemoShout = 3,

    -- Advanced
    RotationThrottle = 0.1,
    OverpowerWindow = 5,
    RevengeWindow = 5,
    SunderStacks = 5,
    HeroicStrikeQueueWindow = 0.5,
    AOETargetThreshold = 3,

    -- UI
    ShowMinimapButton = true,
    MinimapButtonAngle = 200
}

-- Preset configurations
IWin.UI.PRESETS = {
    ["Fury DPS (Raid)"] = {
        -- Metadata
        rotation = "/dmgst",
        description = "Single-target DPS for Fury spec (Bloodthirst build)",

        -- Settings
        RageBloodthirstMin = 30,
        RageMortalStrikeMin = 100,  -- Effectively disabled
        RageWhirlwindMin = 25,
        RageHeroicMin = 40,
        RageCleaveMin = 30,
        RageExecuteMin = 10,
        RageRendMin = 10,
        AutoRend = true,
        SkipRendOnTrash = true,
        AutoStance = true,
        SmartHeroicStrike = true
    },
    ["Arms DPS (Raid)"] = {
        -- Metadata
        rotation = "/dmgst",
        description = "Single-target DPS for Arms spec (Mortal Strike build)",

        -- Settings
        RageBloodthirstMin = 100,  -- Effectively disabled
        RageMortalStrikeMin = 30,
        RageWhirlwindMin = 25,
        RageHeroicMin = 40,
        RageCleaveMin = 30,
        RageExecuteMin = 10,
        RageRendMin = 10,
        AutoRend = true,
        SkipRendOnTrash = true,
        AutoStance = true,
        SmartHeroicStrike = true
    },
    ["Protection Tank (Raid)"] = {
        -- Metadata
        rotation = "/tankst",
        description = "Single-target tanking (bosses, high threat)",

        -- Settings
        RageShieldSlamMin = 20,
        RageRevengeMin = 5,
        RageSunderMin = 15,
        RageThunderClapMin = 20,
        RageDemoShoutMin = 10,
        RageShieldBlockMin = 10,
        SunderStacksBoss = 5,
        SunderStacksTrash = 3,
        AutoShieldBlock = true,
        AutoRevenge = true,
        SkipRendOnTrash = true,
        BattleShoutAOEMode = true
    },
    ["AOE Tank (Dungeons)"] = {
        -- Metadata
        rotation = "/tankaoe",
        description = "Multi-target tanking (trash packs, dungeons)",

        -- Settings
        RageShieldSlamMin = 20,
        RageRevengeMin = 5,
        RageThunderClapMin = 15,
        RageDemoShoutMin = 10,
        RageCleaveMin = 25,
        SunderStacksTrash = 2,
        BattleShoutAOEMode = true,
        AutoRevenge = true,
        SkipRendOnTrash = true
    },
    ["Leveling (1-60)"] = {
        -- Metadata
        rotation = "/dmgst",
        description = "Leveling rotation (rage-efficient, any spec)",

        -- Settings
        RageHeroicMin = 20,
        RageRendMin = 5,
        RageExecuteMin = 5,
        RageChargeMax = 40,
        RageBloodrageMin = 20,
        AutoRend = true,
        SkipRendOnTrash = false,
        AutoCharge = true,
        AutoBattleShout = true
    }
}

-- Create main configuration frame
function IWin.UI:CreateMainFrame()
    if self.frame then return end

    local frame = CreateFrame("Frame", "IWinConfigFrame", UIParent)
    frame:SetWidth(FRAME_WIDTH)
    frame:SetHeight(FRAME_HEIGHT)
    frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    frame:SetFrameStrata("DIALOG")
    frame:EnableMouse(true)
    frame:SetMovable(true)
    frame:SetClampedToScreen(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function() this:StartMoving() end)
    frame:SetScript("OnDragStop", function()
        this:StopMovingOrSizing()
        local point, _, relativePoint, xOfs, yOfs = this:GetPoint()
        IWin_Settings["UIPosition"] = {
            point = point,
            relativePoint = relativePoint,
            xOfs = xOfs,
            yOfs = yOfs
        }
    end)

    frame:Hide()

    -- Register frame for ESC key handling
    -- UISpecialFrames is checked by WoW when ESC is pressed
    table.insert(UISpecialFrames, "IWinConfigFrame")

    -- Backdrop
    frame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true,
        tileSize = 32,
        edgeSize = 32,
        insets = { left = 11, right = 12, top = 12, bottom = 11 }
    })

    -- Title bar
    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", frame, "TOP", 0, -16)
    title:SetText("IWin Configuration v3.0")
    title:SetTextColor(0, 0.6, 1)

    -- Close button
    local closeBtn = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -5, -5)
    closeBtn:SetScript("OnClick", function()
        IWin.UI:Hide()
    end)

    -- Preset dropdown
    self:CreatePresetDropdown(frame)

    self.frame = frame
end

-- Create preset dropdown
function IWin.UI:CreatePresetDropdown(parent)
    local dropdown = CreateFrame("Frame", "IWinPresetDropdown", parent, "UIDropDownMenuTemplate")
    UIDropDownMenu_SetWidth(140, dropdown)
    dropdown:SetPoint("TOPLEFT", parent, "TOPLEFT", 10, -40)

    UIDropDownMenu_Initialize(dropdown, function()
        local info = UIDropDownMenu_CreateInfo()
        info.text = "Load Preset..."
        info.isTitle = true
        info.notCheckable = true
        UIDropDownMenu_AddButton(info)

        for name, _ in pairs(IWin.UI.PRESETS) do
            info = UIDropDownMenu_CreateInfo()
            info.text = name
            info.value = name
            info.func = function()
                local selectedPreset = this.value
                IWin.UI:LoadPreset(selectedPreset)
            end
            info.notCheckable = true
            UIDropDownMenu_AddButton(info)
        end
    end)

    UIDropDownMenu_SetText("Select Preset", dropdown)

    -- Add helper text showing recommended macro
    local helperText = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    helperText:SetPoint("LEFT", dropdown, "RIGHT", 10, 2)
    helperText:SetText("|cff808080Preset: None selected|r")
    helperText:SetTextColor(0.5, 0.5, 0.5)
    helperText:SetJustifyH("LEFT")
    helperText:SetWidth(300)

    self.presetHelperText = helperText
end

-- Load a preset configuration
function IWin.UI:LoadPreset(presetName)
    local preset = self.PRESETS[presetName]
    if not preset then
        DEFAULT_CHAT_FRAME:AddMessage("|cffff0000[IWin] Preset not found: " .. presetName .. "|r")
        return
    end

    -- Extract metadata
    local rotation = preset.rotation
    local description = preset.description

    -- Apply settings (skip metadata fields)
    for key, value in pairs(preset) do
        if key ~= "rotation" and key ~= "description" and IWin_Settings[key] ~= nil then
            IWin_Settings[key] = value
        end
    end

    self:RefreshControls()
    self:BackupSettings()

    -- Update helper text in UI
    if self.presetHelperText and rotation then
        self.presetHelperText:SetText("|cffffd700Macro: " .. rotation .. "|r  |cff808080(" .. (description or "") .. ")|r")
    end

    -- Show success message with rotation macro
    DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[IWin] Loaded preset: " .. presetName .. "|r")
    if rotation then
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00       Use rotation: |r|cffffd700" .. rotation .. "|r")
        DEFAULT_CHAT_FRAME:AddMessage("|cff808080       " .. (description or "") .. "|r")
        DEFAULT_CHAT_FRAME:AddMessage("|cff808080       Create a macro with just: " .. rotation .. "|r")
    end
end

-- Create tab button
function IWin.UI:CreateTabButton(parent, id, text, point, relativeTo, relativePoint, xOffset, yOffset, width)
    width = width or 100
    local btn = CreateFrame("Button", "IWinTabButton" .. id, parent)
    btn:SetWidth(width)
    btn:SetHeight(TAB_HEIGHT)
    btn:SetPoint(point, relativeTo, relativePoint, xOffset, yOffset)

    btn:SetNormalTexture("Interface\\PaperDollInfoFrame\\UI-Character-ActiveTab")
    local ntex = btn:GetNormalTexture()
    ntex:SetTexCoord(0, 1, 1, 0)

    btn:SetHighlightTexture("Interface\\PaperDollInfoFrame\\UI-Character-ActiveTab")
    local htex = btn:GetHighlightTexture()
    htex:SetTexCoord(0, 1, 1, 0)
    htex:SetAlpha(0.4)

    local label = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    label:SetPoint("CENTER", btn, "CENTER", 0, -3)
    label:SetText(text)

    btn:SetScript("OnClick", function()
        IWin.UI:SwitchTab(id)
    end)

    btn.label = label
    return btn
end

-- Create tab system (5 tabs instead of 7)
function IWin.UI:CreateTabs()
    local frame = self.frame

    -- Create 5 tabs
    self.tabs[1] = self:CreateTabButton(frame, 1, "General", "TOPLEFT", frame, "TOPLEFT", 15, -70, 100)
    self.tabs[2] = self:CreateTabButton(frame, 2, "Combat", "LEFT", self.tabs[1], "RIGHT", 0, 0, 100)
    self.tabs[3] = self:CreateTabButton(frame, 3, "Rotations", "LEFT", self.tabs[2], "RIGHT", 0, 0, 100)
    self.tabs[4] = self:CreateTabButton(frame, 4, "Boss/Debuffs", "LEFT", self.tabs[3], "RIGHT", 0, 0, 110)
    self.tabs[5] = self:CreateTabButton(frame, 5, "Advanced", "LEFT", self.tabs[4], "RIGHT", 0, 0, 100)

    -- Create content frames
    for i = 1, 5 do
        local content = CreateFrame("ScrollFrame", "IWinTabContent" .. i, frame)
        content:SetWidth(FRAME_WIDTH - 40)
        content:SetHeight(CONTENT_HEIGHT)
        content:SetPoint("TOP", frame, "TOP", 0, -100)
        content:Hide()

        -- Create scroll child
        local scrollChild = CreateFrame("Frame", nil, content)
        scrollChild:SetWidth(FRAME_WIDTH - 60)
        scrollChild:SetHeight(1400)  -- Enough height for all tabs (largest is ~1200px)
        content:SetScrollChild(scrollChild)

        -- Enable mouse wheel scrolling
        content:EnableMouseWheel(true)
        content:SetScript("OnMouseWheel", function()
            local current = content:GetVerticalScroll()
            local maxScroll = scrollChild:GetHeight() - content:GetHeight()
            if arg1 > 0 then
                content:SetVerticalScroll(math.max(0, current - 20))
            else
                content:SetVerticalScroll(math.min(maxScroll, current + 20))
            end
        end)

        self.tabs[i].content = content
        self.tabs[i].scrollChild = scrollChild
    end

    -- Populate tabs with new layout
    self:CreateGeneralTab()
    self:CreateCombatTab()
    self:CreateRotationsTab()
    self:CreateBossDebuffTab()
    self:CreateAdvancedTab()

    self:SwitchTab(1)
end

-- Switch to a different tab
function IWin.UI:SwitchTab(tabId)
    for i = 1, 5 do
        self.tabs[i].content:Hide()
        self.tabs[i].label:SetTextColor(1, 1, 1)
    end

    self.tabs[tabId].content:Show()
    self.tabs[tabId].label:SetTextColor(1, 0.82, 0)
    self.currentTab = tabId

    IWin_Settings["UILastTab"] = tabId
end

-- Create a section frame with background
function IWin.UI:CreateSection(parent, x, y, width, height, title)
    local section = CreateFrame("Frame", nil, parent)
    section:SetWidth(width)
    section:SetHeight(height)
    section:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)

    section:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    section:SetBackdropColor(COLORS.SECTION_BG[1], COLORS.SECTION_BG[2], COLORS.SECTION_BG[3], COLORS.SECTION_BG[4])
    section:SetBackdropBorderColor(COLORS.SECTION_BORDER[1], COLORS.SECTION_BORDER[2], COLORS.SECTION_BORDER[3], COLORS.SECTION_BORDER[4])

    if title then
        local header = section:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        header:SetPoint("TOPLEFT", section, "TOPLEFT", SPACING.INNER_PADDING, -SPACING.INNER_PADDING)
        header:SetText(title)
        header:SetTextColor(COLORS.HEADER[1], COLORS.HEADER[2], COLORS.HEADER[3])

        -- Divider line
        local divider = section:CreateTexture(nil, "ARTWORK")
        divider:SetTexture(1, 1, 1)
        divider:SetHeight(1)
        divider:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -3)
        divider:SetPoint("RIGHT", section, "RIGHT", -SPACING.INNER_PADDING, 0)
        divider:SetVertexColor(COLORS.HEADER[1], COLORS.HEADER[2], COLORS.HEADER[3], 0.5)
    end

    return section
end

-- Create enhanced checkbox with list style
function IWin.UI:CreateCheckbox(parent, label, settingKey, x, y, tooltipTitle, tooltipText)
    local cb = CreateFrame("CheckButton", "IWinCheck_" .. settingKey, parent, "UICheckButtonTemplate")
    cb:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    cb:SetHitRectInsets(0, -200, 0, 0)  -- Expand click area

    local text = cb:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    text:SetPoint("LEFT", cb, "RIGHT", 5, 0)
    text:SetText(label)

    cb:SetChecked(IWin_Settings[settingKey])
    cb:SetScript("OnClick", function()
        IWin_Settings[settingKey] = cb:GetChecked()
        IWin.UI:UpdateModifiedState(cb, settingKey)
    end)

    if tooltipTitle and tooltipText then
        cb:SetScript("OnEnter", function()
            GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
            GameTooltip:SetText(tooltipTitle, 1, 1, 1)
            GameTooltip:AddLine(tooltipText, 0.8, 0.8, 0.8, true)

            -- Add default value
            local defaultVal = IWin.UI.DEFAULTS[settingKey]
            if defaultVal ~= nil then
                GameTooltip:AddLine(" ", 1, 1, 1)
                GameTooltip:AddLine("Default: " .. (defaultVal and "Enabled" or "Disabled"), 0.5, 1, 0.5)
            end

            GameTooltip:Show()
        end)
        cb:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)
    end

    cb.label = text
    cb.labelText = label
    cb.settingKey = settingKey
    table.insert(self.controls, cb)

    self:UpdateModifiedState(cb, settingKey)

    return cb
end

-- Create compact slider with integrated design
function IWin.UI:CreateCompactSlider(parent, label, settingKey, minVal, maxVal, x, y, suffix, tooltipText, colorType)
    suffix = suffix or ""
    colorType = colorType or "RAGE"

    local container = CreateFrame("Frame", nil, parent)
    container:SetWidth(260)
    container:SetHeight(45)
    container:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)

    -- Label and value on same line
    local labelText = container:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    labelText:SetPoint("TOPLEFT", container, "TOPLEFT", 0, 0)
    labelText:SetText(label)

    local valueText = container:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    valueText:SetPoint("TOPRIGHT", container, "TOPRIGHT", -20, 0)
    local currentValue = IWin_Settings[settingKey] or minVal

    -- Format value
    local displayValue
    if settingKey == "RotationThrottle" or settingKey == "HeroicStrikeQueueWindow" then
        displayValue = string.format("%.2f", currentValue)
    else
        displayValue = tostring(math.floor(currentValue))
    end
    valueText:SetText(displayValue .. suffix)

    -- Slider
    local slider = CreateFrame("Slider", "IWinSlider_" .. settingKey, container)
    slider:SetWidth(260)
    slider:SetHeight(16)
    slider:SetPoint("TOPLEFT", labelText, "BOTTOMLEFT", 0, -8)
    slider:SetOrientation("HORIZONTAL")
    slider:SetMinMaxValues(minVal, maxVal)
    slider:SetValue(currentValue)

    -- Set value step based on setting type
    local valueStep = 1
    if settingKey == "RotationThrottle" or settingKey == "HeroicStrikeQueueWindow" then
        valueStep = 0.01
    end
    slider:SetValueStep(valueStep)
    slider:EnableKeyboard(true)

    slider:SetBackdrop({
        bgFile = "Interface\\Buttons\\UI-SliderBar-Background",
        edgeFile = "Interface\\Buttons\\UI-SliderBar-Border",
        tile = true,
        tileSize = 8,
        edgeSize = 8,
        insets = { left = 3, right = 3, top = 6, bottom = 6 }
    })

    -- Color-code the slider track
    local trackColor = COLORS[colorType] or COLORS.RAGE
    local colorBar = slider:CreateTexture(nil, "BACKGROUND")
    colorBar:SetTexture("Interface\\Buttons\\UI-SliderBar-Background")
    colorBar:SetVertexColor(trackColor[1], trackColor[2], trackColor[3], 0.3)
    colorBar:SetAllPoints(slider)

    local thumb = slider:CreateTexture(nil, "OVERLAY")
    thumb:SetTexture("Interface\\Buttons\\UI-SliderBar-Button-Horizontal")
    thumb:SetWidth(32)
    thumb:SetHeight(32)
    slider:SetThumbTexture(thumb)

    -- Min/max labels
    local minLabel = container:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    minLabel:SetPoint("TOPLEFT", slider, "BOTTOMLEFT", 0, -2)
    minLabel:SetText(minVal)
    minLabel:SetTextColor(0.6, 0.6, 0.6)

    local maxLabel = container:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    maxLabel:SetPoint("TOPRIGHT", slider, "BOTTOMRIGHT", 0, -2)
    maxLabel:SetText(maxVal)
    maxLabel:SetTextColor(0.6, 0.6, 0.6)

    -- Reset to default button
    local resetBtn = CreateFrame("Button", nil, container)
    resetBtn:SetWidth(16)
    resetBtn:SetHeight(16)
    resetBtn:SetPoint("LEFT", valueText, "RIGHT", 3, 0)
    resetBtn:SetNormalTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Up")
    resetBtn:SetHighlightTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Up")
    resetBtn:SetScript("OnClick", function()
        local defaultVal = IWin.UI.DEFAULTS[settingKey]
        if defaultVal then
            slider:SetValue(defaultVal)
        end
    end)
    resetBtn:SetScript("OnEnter", function()
        GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
        GameTooltip:SetText("Reset to Default", 1, 1, 1)
        local defaultVal = IWin.UI.DEFAULTS[settingKey]
        if defaultVal then
            GameTooltip:AddLine("Default: " .. defaultVal .. suffix, 0.5, 1, 0.5)
        end
        GameTooltip:Show()
    end)
    resetBtn:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    -- Update function
    local function updateValue(value, skipSave)
        if value < minVal then value = minVal end
        if value > maxVal then value = maxVal end

        local displayVal
        if settingKey == "RotationThrottle" or settingKey == "HeroicStrikeQueueWindow" then
            displayVal = string.format("%.2f", value)
        else
            displayVal = tostring(math.floor(value))
        end

        valueText:SetText(displayVal .. suffix)

        if not skipSave then
            if settingKey == "RotationThrottle" or settingKey == "HeroicStrikeQueueWindow" then
                IWin_Settings[settingKey] = value
            else
                IWin_Settings[settingKey] = math.floor(value)
            end

            IWin.UI:UpdateModifiedState(slider, settingKey, valueText, resetBtn)
        end
    end

    slider:SetScript("OnValueChanged", function()
        updateValue(slider:GetValue())
    end)

    -- Keyboard support
    slider:SetScript("OnKeyDown", function(_, key)
        local value = slider:GetValue()
        local step = slider:GetValueStep()
        if key == "UP" or key == "RIGHT" then
            slider:SetValue(value + step)
        elseif key == "DOWN" or key == "LEFT" then
            slider:SetValue(value - step)
        end
    end)

    -- Tooltip
    if tooltipText then
        slider:SetScript("OnEnter", function()
            GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
            GameTooltip:SetText(label, 1, 1, 1)
            GameTooltip:AddLine(tooltipText, 0.8, 0.8, 0.8, true)

            -- Add default value
            local defaultVal = IWin.UI.DEFAULTS[settingKey]
            if defaultVal then
                GameTooltip:AddLine(" ", 1, 1, 1)
                GameTooltip:AddLine("Default: " .. defaultVal .. suffix, 0.5, 1, 0.5)
            end

            -- Add examples if available
            IWin.UI:AddTooltipExamples(GameTooltip, settingKey)

            GameTooltip:Show()
        end)
        slider:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)
    end

    container.slider = slider
    container.valueText = valueText
    container.resetBtn = resetBtn
    container.labelText = label
    container.settingKey = settingKey

    table.insert(self.controls, {
        container = container,
        slider = slider,
        valueText = valueText,
        resetBtn = resetBtn,
        labelText = label,
        settingKey = settingKey
    })

    self:UpdateModifiedState(slider, settingKey, valueText, resetBtn)

    return container, slider
end

-- Add tooltip examples for specific settings
function IWin.UI:AddTooltipExamples(tooltip, settingKey)
    local examples = {
        RageBloodthirstMin = {
            "20 = Aggressive, spam often",
            "30 = Balanced (default)",
            "40 = Conservative, save rage"
        },
        RageHeroicMin = {
            "20 = Frequent rage dumps",
            "30 = Balanced (default)",
            "50 = Only when rage capped"
        },
        RotationThrottle = {
            "0.05 = Fast response, high CPU",
            "0.10 = Balanced (default)",
            "0.20 = Slower, low CPU"
        },
        LastStandThreshold = {
            "10 = Very aggressive (risky)",
            "20 = Balanced (default)",
            "30 = Very defensive"
        }
    }

    if examples[settingKey] then
        tooltip:AddLine(" ", 1, 1, 1)
        tooltip:AddLine("Examples:", 1, 0.82, 0)
        for _, example in ipairs(examples[settingKey]) do
            tooltip:AddLine("• " .. example, 0.7, 0.7, 0.7, true)
        end
    end
end

-- Update modified state visuals
function IWin.UI:UpdateModifiedState(control, settingKey, valueText, resetBtn)
    local currentValue = IWin_Settings[settingKey]
    local defaultValue = self.DEFAULTS[settingKey]

    -- Check if values are equal (with floating point tolerance for numeric values)
    local isDefault = false
    if type(currentValue) == "number" and type(defaultValue) == "number" then
        -- For floating point comparison, use epsilon tolerance
        local epsilon = 0.001
        isDefault = math.abs(currentValue - defaultValue) < epsilon
    else
        -- For non-numeric values, use direct comparison
        isDefault = (currentValue == defaultValue)
    end

    if isDefault then
        -- At default
        if valueText then
            valueText:SetTextColor(COLORS.DEFAULT_VALUE[1], COLORS.DEFAULT_VALUE[2], COLORS.DEFAULT_VALUE[3])
        end
        if resetBtn then
            resetBtn:Hide()
        end
        if control.SetBackdropBorderColor and self.compareMode then
            control:SetBackdropBorderColor(0.3, 0.3, 0.3, 0.8)
        end
    else
        -- Modified
        if valueText then
            valueText:SetTextColor(1, 1, 1)
        end
        if resetBtn then
            resetBtn:Show()
        end
        if control.SetBackdropBorderColor and self.compareMode then
            control:SetBackdropBorderColor(COLORS.MODIFIED[1], COLORS.MODIFIED[2], COLORS.MODIFIED[3], 1)
        end
    end
end

-- Tab 1: General (consolidated Toggles)
function IWin.UI:CreateGeneralTab()
    local content = self.tabs[1].scrollChild
    local y = -10

    -- Quick Start Guide section
    local guideSection = self:CreateSection(content, 10, y, 560, 145, "Quick Start: Create Your Macro")

    local guideText = guideSection:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    guideText:SetPoint("TOPLEFT", guideSection, "TOPLEFT", SPACING.INNER_PADDING, -35)
    guideText:SetPoint("RIGHT", guideSection, "RIGHT", -SPACING.INNER_PADDING, 0)
    guideText:SetJustifyH("LEFT")
    guideText:SetText(
        "1. Open macros (/macro) and create a new macro\n" ..
        "2. Choose ONE rotation command based on your role:\n\n" ..
        "   |cffffd700/dmgst|r   - DPS Single-Target (bosses, Fury/Arms)\n" ..
        "   |cffffd700/dmgaoe|r  - DPS AOE (trash packs, Fury/Arms)\n" ..
        "   |cffffd700/tankst|r  - Tank Single-Target (bosses, Protection)\n" ..
        "   |cffffd700/tankaoe|r - Tank AOE (trash packs, Protection)\n\n" ..
        "3. Bind the macro to a key and spam it during combat"
    )
    guideText:SetTextColor(0.9, 0.9, 0.9)

    y = y - 155

    -- Combat Features section
    local combatSection = self:CreateSection(content, 10, y, 560, 240, "Combat Features")
    y = y - 40

    self:CreateCheckbox(combatSection, "Auto-Charge", "AutoCharge", SPACING.INNER_PADDING, -35,
        "Auto-Charge",
        "Automatically use Charge when out of combat and target is in range (8-25 yards).")
    self:CreateCheckbox(combatSection, "Auto-Battle Shout", "AutoBattleShout", SPACING.INNER_PADDING, -65,
        "Auto-Battle Shout",
        "Automatically cast Battle Shout when the buff is missing.")
    self:CreateCheckbox(combatSection, "Auto-Bloodrage", "AutoBloodrage", SPACING.INNER_PADDING, -95,
        "Auto-Bloodrage",
        "Automatically use Bloodrage for rage generation when rage drops below threshold.")
    self:CreateCheckbox(combatSection, "Auto-Attack", "AutoAttack", SPACING.INNER_PADDING, -125,
        "Auto-Attack",
        "Automatically enable auto-attack on your current target when in combat.")
    self:CreateCheckbox(combatSection, "Auto-Rend", "AutoRend", SPACING.INNER_PADDING, -155,
        "Auto-Rend",
        "Automatically apply and maintain Rend on target.")
    self:CreateCheckbox(combatSection, "Auto-Stance", "AutoStance", SPACING.INNER_PADDING, -185,
        "Auto-Stance",
        "Automatically switch stances to use abilities (e.g., Berserker for Whirlwind).")

    self:CreateCheckbox(combatSection, "Auto-Trinkets", "AutoTrinkets", 290, -35,
        "Auto-Trinkets",
        "Automatically use offensive trinkets in slots 13 and 14.")

    y = y - 250

    -- Tank Features section
    local tankSection = self:CreateSection(content, 10, y, 560, 155, "Tank Features")

    self:CreateCheckbox(tankSection, "Auto-Shield Block", "AutoShieldBlock", SPACING.INNER_PADDING, -35,
        "Auto-Shield Block",
        "Automatically use Shield Block before Shield Slam for damage bonus.")
    self:CreateCheckbox(tankSection, "Auto-Revenge", "AutoRevenge", SPACING.INNER_PADDING, -65,
        "Auto-Revenge",
        "Automatically use Revenge when available. Requires Revenge on action bars!")
    self:CreateCheckbox(tankSection, "Battle Shout AOE Mode", "BattleShoutAOEMode", SPACING.INNER_PADDING, -95,
        "Battle Shout AOE Mode",
        "Spam Battle Shout in tankAOE rotation for AOE threat (1.12 meta).")

    self:CreateCheckbox(tankSection, "Skip Thunder Clap with Thunderfury", "SkipThunderClapWithThunderfury", 290, -35,
        "Skip Thunder Clap",
        "Skip Thunder Clap if target has Thunderfury debuff.")

    y = y - 165

    -- SuperWOW Features section
    local swSection = self:CreateSection(content, 10, y, 560, 130, "SuperWOW Features")

    -- Add SuperWOW status indicator
    local swStatus = swSection:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    swStatus:SetPoint("TOPRIGHT", swSection, "TOPRIGHT", -SPACING.INNER_PADDING, -SPACING.INNER_PADDING - 2)
    if IWin.superwow and IWin.superwow.detected then
        swStatus:SetText("✓ SuperWOW Detected")
        swStatus:SetTextColor(0, 1, 0)
    else
        swStatus:SetText("✗ SuperWOW Not Detected")
        swStatus:SetTextColor(0.7, 0.7, 0.7)
    end

    self:CreateCheckbox(swSection, "Auto-Interrupt", "AutoInterrupt", SPACING.INNER_PADDING, -35,
        "Auto-Interrupt (SuperWOW)",
        "Automatically interrupt enemy spell casts using Pummel or Shield Bash.")
    self:CreateCheckbox(swSection, "Smart Heroic Strike", "SmartHeroicStrike", SPACING.INNER_PADDING, -65,
        "Smart Heroic Strike (SuperWOW)",
        "Only queue Heroic Strike/Cleave near swing timer to avoid wasting rage.")
end

-- Tab 2: Combat (consolidated DPS + Tank + Health)
function IWin.UI:CreateCombatTab()
    local content = self.tabs[2].scrollChild
    local y = -10

    -- Rage Management section
    local rageSection = self:CreateSection(content, 10, y, 560, 260, "Rage Management")
    y = y - 40

    self:CreateCompactSlider(rageSection, "Charge Max", "RageChargeMax", 0, 100, SPACING.INNER_PADDING, -40, "",
        "Maximum rage threshold for using Charge.", "RAGE")
    self:CreateCompactSlider(rageSection, "Bloodrage Min", "RageBloodrageMin", 0, 100, SPACING.INNER_PADDING, -95, "",
        "Triggers Bloodrage when rage drops below this value.", "RAGE")
    self:CreateCompactSlider(rageSection, "Battle Shout Min (OOC)", "RageShoutMin", 0, 100, SPACING.INNER_PADDING, -150, "",
        "Minimum rage required to cast Battle Shout when out of combat.", "RAGE")
    self:CreateCompactSlider(rageSection, "Battle Shout Min (Combat)", "RageShoutCombatMin", 0, 100, SPACING.INNER_PADDING, -205, "",
        "Minimum rage required to cast Battle Shout in combat.", "RAGE")

    y = y - 270

    -- DPS Abilities section
    local dpsSection = self:CreateSection(content, 10, y, 560, 425, "DPS Abilities")

    self:CreateCompactSlider(dpsSection, "Bloodthirst", "RageBloodthirstMin", 0, 100, SPACING.INNER_PADDING, -40, "",
        "Minimum rage for Bloodthirst. Higher values save rage.", "RAGE")
    self:CreateCompactSlider(dpsSection, "Mortal Strike", "RageMortalStrikeMin", 0, 100, SPACING.INNER_PADDING, -95, "",
        "Minimum rage for Mortal Strike. Set to 100 to disable.", "RAGE")
    self:CreateCompactSlider(dpsSection, "Whirlwind", "RageWhirlwindMin", 0, 100, SPACING.INNER_PADDING, -150, "",
        "Minimum rage for Whirlwind. Important for AOE.", "RAGE")
    self:CreateCompactSlider(dpsSection, "Sweeping Strikes", "RageSweepingMin", 0, 100, SPACING.INNER_PADDING, -205, "",
        "Minimum rage for Sweeping Strikes in AOE rotation.", "RAGE")
    self:CreateCompactSlider(dpsSection, "Heroic Strike", "RageHeroicMin", 0, 100, SPACING.INNER_PADDING, -260, "",
        "Minimum rage for Heroic Strike (rage dump).", "RAGE")
    self:CreateCompactSlider(dpsSection, "Cleave", "RageCleaveMin", 0, 100, SPACING.INNER_PADDING, -315, "",
        "Minimum rage for Cleave (AOE rage dump).", "RAGE")
    self:CreateCompactSlider(dpsSection, "Overpower", "RageOverpowerMin", 0, 100, SPACING.INNER_PADDING, -370, "",
        "Minimum rage for Overpower (after enemy dodge).", "RAGE")

    y = y - 435

    -- Tank Abilities section
    local tankSection = self:CreateSection(content, 10, y, 560, 425, "Tank Abilities")

    self:CreateCompactSlider(tankSection, "Shield Slam", "RageShieldSlamMin", 0, 100, SPACING.INNER_PADDING, -40, "",
        "Minimum rage for Shield Slam. High threat ability.", "RAGE")
    self:CreateCompactSlider(tankSection, "Revenge", "RageRevengeMin", 0, 100, SPACING.INNER_PADDING, -95, "",
        "Minimum rage for Revenge (after dodge/parry/block).", "RAGE")
    self:CreateCompactSlider(tankSection, "Sunder Armor", "RageSunderMin", 0, 100, SPACING.INNER_PADDING, -150, "",
        "Minimum rage for Sunder Armor. Primary threat builder.", "RAGE")
    self:CreateCompactSlider(tankSection, "Thunder Clap", "RageThunderClapMin", 0, 100, SPACING.INNER_PADDING, -205, "",
        "Minimum rage for Thunder Clap. AOE threat + slow.", "RAGE")
    self:CreateCompactSlider(tankSection, "Demoralizing Shout", "RageDemoShoutMin", 0, 100, SPACING.INNER_PADDING, -260, "",
        "Minimum rage for Demoralizing Shout. Reduces enemy AP.", "RAGE")
    self:CreateCompactSlider(tankSection, "Concussion Blow", "RageConcussionBlowMin", 0, 100, SPACING.INNER_PADDING, -315, "",
        "Minimum rage for Concussion Blow (stun).", "RAGE")
    self:CreateCompactSlider(tankSection, "Shield Block", "RageShieldBlockMin", 0, 100, SPACING.INNER_PADDING, -370, "",
        "Minimum rage for Shield Block.", "RAGE")

    y = y - 435

    -- Execute & Emergency section
    local execSection = self:CreateSection(content, 10, y, 560, 195, "Execute & Emergency")

    self:CreateCompactSlider(execSection, "Execute Min", "RageExecuteMin", 0, 100, SPACING.INNER_PADDING, -40, "",
        "Minimum rage for Execute on low health targets.", "RAGE")
    self:CreateCompactSlider(execSection, "Rend Min", "RageRendMin", 0, 100, SPACING.INNER_PADDING, -95, "",
        "Minimum rage to apply/refresh Rend DoT.", "RAGE")
    self:CreateCompactSlider(execSection, "Last Stand Threshold", "LastStandThreshold", 1, 99, SPACING.INNER_PADDING, -150, "%",
        "Emergency ability when YOUR health drops below this %.", "HEALTH")

    y = y - 205

    -- Add info note at bottom
    local note = content:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    note:SetPoint("TOP", content, "TOP", 0, y - 10)
    note:SetText("Lower rage values = more aggressive ability use")
    note:SetTextColor(0.7, 0.7, 0.7)
end
-- Tab 3: Rotations (NEW - visual priority display)
function IWin.UI:CreateRotationsTab()
    local content = self.tabs[3].scrollChild
    local y = -10

    -- Rotation info section
    local infoSection = self:CreateSection(content, 10, y, 560, 630, "Rotation Priority Display")

    -- Add description
    local desc = infoSection:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    desc:SetPoint("TOP", infoSection, "TOP", 0, -35)
    desc:SetText("Visual rotation priority for reference")
    desc:SetTextColor(0.7, 0.7, 0.7)

    -- Rotation selector dropdown
    local rotationDropdown = CreateFrame("Frame", "IWinRotationDropdown", infoSection, "UIDropDownMenuTemplate")
    UIDropDownMenu_SetWidth(180, rotationDropdown)
    rotationDropdown:SetPoint("TOP", desc, "BOTTOM", 0, -10)

    local rotations = {
        "DPS Single-Target",
        "DPS AOE",
        "Tank Single-Target",
        "Tank AOE"
    }

    UIDropDownMenu_Initialize(rotationDropdown, function()
        for i, rotation in ipairs(rotations) do
            local info = UIDropDownMenu_CreateInfo()
            info.text = rotation
            info.value = rotation
            info.func = function()
                local selectedRotation = this.value
                UIDropDownMenu_SetText(selectedRotation, rotationDropdown)
                IWin.UI:ShowRotationPriority(selectedRotation, infoSection)
            end
            info.notCheckable = true
            UIDropDownMenu_AddButton(info)
        end
    end)

    UIDropDownMenu_SetText(rotations[1], rotationDropdown)

    -- Priority display area
    local priorityFrame = CreateFrame("Frame", nil, infoSection)
    priorityFrame:SetWidth(540)
    priorityFrame:SetHeight(480)
    priorityFrame:SetPoint("TOP", rotationDropdown, "BOTTOM", 0, -25)

    priorityFrame:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\ChatFrame\\ChatFrameBackground",
        tile = true,
        edgeSize = 1,
        tileSize = 5,
    })
    priorityFrame:SetBackdropColor(0, 0, 0, 0.3)
    priorityFrame:SetBackdropBorderColor(0.3, 0.3, 0.3, 0.8)

    infoSection.priorityFrame = priorityFrame

    -- Show first rotation
    self:ShowRotationPriority(rotations[1], infoSection)

    y = y - 650

    -- Notes section
    local noteSection = self:CreateSection(content, 10, y, 560, 100, "Rotation Notes")

    local note1 = noteSection:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    note1:SetPoint("TOPLEFT", noteSection, "TOPLEFT", SPACING.INNER_PADDING, -35)
    note1:SetText("• Reactive abilities (Revenge, Overpower) bypass throttle")
    note1:SetTextColor(0.8, 0.8, 0.8)

    local note2 = noteSection:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    note2:SetPoint("TOPLEFT", note1, "BOTTOMLEFT", 0, -5)
    note2:SetText("• Interrupts checked every 0.05s (SuperWOW only)")
    note2:SetTextColor(0.8, 0.8, 0.8)

    local note3 = noteSection:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    note3:SetPoint("TOPLEFT", note2, "BOTTOMLEFT", 0, -5)
    note3:SetText("• Boss detection affects Execute threshold and Sunder stacks")
    note3:SetTextColor(0.8, 0.8, 0.8)
end

-- Show rotation priority for selected rotation
function IWin.UI:ShowRotationPriority(rotationName, parentSection)
    local frame = parentSection.priorityFrame
    if not frame then return end

    -- Initialize rows table if needed
    if not frame.rows then
        frame.rows = {}
    end

    -- Rotation priority data (matches actual .lua files)
    local priorities = {
        ["DPS Single-Target"] = {
            {icon = "Ability_Kick", name = "Interrupt", condition = "Enemy casting (SuperWOW)"},
            {icon = "Ability_MeleeDamage", name = "Overpower", condition = "After dodge, 5s window"},
            {icon = "Ability_Warrior_Charge", name = "Charge", condition = "OOC, 8-25 yds, rage ≤ 50"},
            {icon = "INV_Sword_48", name = "Execute", condition = "Target ≤ 20%"},
            {icon = "Ability_Warrior_BattleShout", name = "Battle Shout", condition = "OOC, buff missing"},
            {icon = "Ability_Racial_BloodRage", name = "Bloodrage", condition = "Rage < 30"},
            {icon = "Spell_Nature_BloodLust", name = "Bloodthirst", condition = "Fury, 6s CD"},
            {icon = "Ability_Warrior_SavageBlow", name = "Mortal Strike", condition = "Arms, 6s CD"},
            {icon = "Ability_Whirlwind", name = "Whirlwind", condition = "10s CD, melee range"},
            {icon = "Ability_Gouge", name = "Rend", condition = "Refresh at 5s (bosses)"},
            {icon = "Ability_Rogue_Ambush", name = "Heroic Strike", condition = "Smart queue (SuperWOW)"}
        },
        ["DPS AOE"] = {
            {icon = "Ability_Kick", name = "Interrupt", condition = "Enemy casting (SuperWOW)"},
            {icon = "Ability_MeleeDamage", name = "Overpower", condition = "After dodge, 5s window"},
            {icon = "Ability_Warrior_Charge", name = "Charge", condition = "OOC, rage ≤ 50"},
            {icon = "Ability_Warrior_BattleShout", name = "Battle Shout", condition = "OOC, buff missing"},
            {icon = "Ability_Rogue_SliceDice", name = "Sweeping Strikes", condition = "Battle Stance"},
            {icon = "Ability_Whirlwind", name = "Whirlwind", condition = "Berserker, 10s CD"},
            {icon = "Ability_Racial_BloodRage", name = "Bloodrage", condition = "Rage < 30"},
            {icon = "Spell_Nature_BloodLust", name = "Bloodthirst", condition = "Fury"},
            {icon = "Ability_Warrior_SavageBlow", name = "Mortal Strike", condition = "Arms"},
            {icon = "INV_Sword_48", name = "Execute", condition = "Target ≤ 20%"},
            {icon = "Ability_Gouge", name = "Rend", condition = "Bosses only"},
            {icon = "Ability_Warrior_Cleave", name = "Cleave", condition = "Smart queue"},
            {icon = "Ability_Rogue_Ambush", name = "Heroic Strike", condition = "Fallback rage dump"}
        },
        ["Tank Single-Target"] = {
            {icon = "Ability_Kick", name = "Interrupt", condition = "Enemy casting (SuperWOW)"},
            {icon = "Ability_MeleeDamage", name = "Overpower", condition = "After dodge, 5s window"},
            {icon = "Ability_Warrior_Revenge", name = "Revenge", condition = "After block/parry/dodge"},
            {icon = "Ability_Warrior_Charge", name = "Charge", condition = "OOC"},
            {icon = "Spell_Holy_AshesToAshes", name = "Last Stand", condition = "Health ≤ 20%"},
            {icon = "INV_Sword_48", name = "Execute", condition = "Target ≤ 20%"},
            {icon = "Ability_Warrior_WarCry", name = "Demo Shout", condition = "Opener, refresh at 3s"},
            {icon = "Ability_Defend", name = "Shield Block", condition = "Mitigation + Revenge proc"},
            {icon = "Ability_Warrior_ShieldBash", name = "Shield Bash", condition = "180 threat (efficient)"},
            {icon = "INV_Shield_05", name = "Shield Slam", condition = "Spam on CD"},
            {icon = "Ability_Racial_BloodRage", name = "Bloodrage", condition = "Rage gen"},
            {icon = "Ability_Warrior_Sunder", name = "Sunder Armor", condition = "Ramp + spam (10 rage)"},
            {icon = "Spell_Nature_BloodLust", name = "Bloodthirst", condition = "Berserker if available"},
            {icon = "Ability_Warrior_BattleShout", name = "Battle Shout", condition = "In combat threat"},
            {icon = "Ability_Rogue_Ambush", name = "Heroic Strike", condition = "Rage dump (inefficient)"},
            {icon = "Ability_Gouge", name = "Rend", condition = "Low priority DoT"}
        },
        ["Tank AOE"] = {
            {icon = "Ability_Kick", name = "Interrupt", condition = "Enemy casting (SuperWOW)"},
            {icon = "Ability_MeleeDamage", name = "Overpower", condition = "After dodge, 5s window"},
            {icon = "Ability_Warrior_Revenge", name = "Revenge", condition = "After block/parry/dodge"},
            {icon = "Ability_Warrior_Charge", name = "Charge", condition = "OOC"},
            {icon = "Spell_Holy_AshesToAshes", name = "Last Stand", condition = "Health ≤ 20%"},
            {icon = "INV_Sword_48", name = "Execute", condition = "Target ≤ 20%"},
            {icon = "Ability_Warrior_WarCry", name = "Demo Shout", condition = "FIRST - opener"},
            {icon = "Spell_Nature_ThunderClap", name = "Thunder Clap", condition = "PRIMARY AOE threat"},
            {icon = "Ability_Warrior_BattleShout", name = "Battle Shout", condition = "Spam (3s throttle)"},
            {icon = "Ability_Warrior_ShieldBash", name = "Shield Bash", condition = "Priority target"},
            {icon = "Ability_Warrior_Cleave", name = "Cleave", condition = "Primary rage dump"},
            {icon = "Ability_Racial_BloodRage", name = "Bloodrage", condition = "Rage gen"},
            {icon = "INV_Shield_05", name = "Shield Slam", condition = "Focus target"},
            {icon = "Ability_Warrior_PunishingBlow", name = "Concussion Blow", condition = "Extra threat"},
            {icon = "Ability_Whirlwind", name = "Whirlwind", condition = "Berserker AOE"}
        }
    }

    local priority = priorities[rotationName]
    if not priority then return end

    -- Display priority list
    local y = -10
    for i, ability in ipairs(priority) do
        -- Reuse existing row or create new one
        local row = frame.rows[i]
        if not row then
            -- Create new row frame
            row = CreateFrame("Frame", nil, frame)
            row:SetWidth(520)
            row:SetHeight(24)

            -- Priority number
            row.numText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
            row.numText:SetPoint("LEFT", row, "LEFT", 0, 0)
            row.numText:SetTextColor(COLORS.HEADER[1], COLORS.HEADER[2], COLORS.HEADER[3])

            -- Icon texture
            row.iconTexture = row:CreateTexture(nil, "ARTWORK")
            row.iconTexture:SetWidth(20)
            row.iconTexture:SetHeight(20)
            row.iconTexture:SetPoint("LEFT", row.numText, "RIGHT", 8, 0)

            -- Ability name
            row.nameText = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            row.nameText:SetPoint("LEFT", row.iconTexture, "RIGHT", 8, 0)
            row.nameText:SetTextColor(1, 1, 1)

            -- Condition
            row.condText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            row.condText:SetPoint("LEFT", row.nameText, "RIGHT", 15, 0)
            row.condText:SetTextColor(0.6, 0.6, 0.6)

            -- Store row for reuse
            frame.rows[i] = row
        end

        -- Update row content
        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, y)
        row.numText:SetText(i)

        -- Set icon texture
        if ability.icon then
            row.iconTexture:SetTexture("Interface\\Icons\\" .. ability.icon)
            row.iconTexture:Show()
        else
            row.iconTexture:Hide()
        end

        row.nameText:SetText(ability.name)
        row.condText:SetText("[" .. ability.condition .. "]")

        -- Show the row
        row:Show()

        y = y - 28
    end

    -- Hide any extra rows that aren't being used
    for i = table.getn(priority) + 1, table.getn(frame.rows) do
        if frame.rows[i] then
            frame.rows[i]:Hide()
        end
    end
end

-- Tab 4: Boss/Debuffs (consolidated Boss + Debuffs)
function IWin.UI:CreateBossDebuffTab()
    local content = self.tabs[4].scrollChild
    local y = -10

    -- Boss Detection section
    local bossSection = self:CreateSection(content, 10, y, 560, 230, "Boss Detection")

    -- Boss detection explanation
    local bossDesc = bossSection:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    bossDesc:SetPoint("TOPLEFT", bossSection, "TOPLEFT", SPACING.INNER_PADDING, -35)
    bossDesc:SetText("Boss detection: worldboss classification, skull level (-1), or elite + skull")
    bossDesc:SetTextColor(0.7, 0.7, 0.7)

    self:CreateCompactSlider(bossSection, "Boss Sunder Stacks", "SunderStacksBoss", 1, 5, SPACING.INNER_PADDING, -65, "",
        "Target Sunder Armor stacks to maintain on bosses. Full armor reduction = 5 stacks.", "RAGE")
    self:CreateCompactSlider(bossSection, "Trash Sunder Stacks", "SunderStacksTrash", 1, 5, SPACING.INNER_PADDING, -120, "",
        "Target Sunder Armor stacks on trash mobs. Lower stacks saves rage for AOE.", "RAGE")

    self:CreateCheckbox(bossSection, "Skip Rend on Trash", "SkipRendOnTrash", SPACING.INNER_PADDING, -175,
        "Skip Rend on Trash",
        "Don't apply Rend to trash mobs to save rage. Still applies Rend to bosses.")

    y = y - 240

    -- Debuff Refresh Timings section
    local debuffSection = self:CreateSection(content, 10, y, 560, 275, "Debuff Refresh Timings")

    local debuffDesc = debuffSection:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    debuffDesc:SetPoint("TOPLEFT", debuffSection, "TOPLEFT", SPACING.INNER_PADDING, -35)
    debuffDesc:SetText("Refresh debuffs when this many seconds remain on the duration")
    debuffDesc:SetTextColor(0.7, 0.7, 0.7)

    self:CreateCompactSlider(debuffSection, "Rend Refresh", "RefreshRend", 1, 20, SPACING.INNER_PADDING, -65, "s",
        "Refresh Rend when this many seconds remain. Rend lasts 21s total.", "TIME")
    self:CreateCompactSlider(debuffSection, "Sunder Armor Refresh", "RefreshSunder", 1, 29, SPACING.INNER_PADDING, -120, "s",
        "Refresh Sunder Armor when below stacks or this many seconds remain. Lasts 30s.", "TIME")
    self:CreateCompactSlider(debuffSection, "Thunder Clap Refresh", "RefreshThunderClap", 1, 25, SPACING.INNER_PADDING, -175, "s",
        "Refresh Thunder Clap when this many seconds remain. Lasts 26s, reduces attack speed.", "TIME")
    self:CreateCompactSlider(debuffSection, "Demo Shout Refresh", "RefreshDemoShout", 1, 29, SPACING.INNER_PADDING, -230, "s",
        "Refresh Demoralizing Shout when this many seconds remain. Lasts 30s, reduces AP.", "TIME")

    y = y - 285

    -- Info note
    local note = content:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    note:SetPoint("TOP", content, "TOP", 0, y - 10)
    note:SetText("Lower refresh times = better uptime but more GCDs used")
    note:SetTextColor(0.7, 0.7, 0.7)
end

-- Tab 5: Advanced (keep existing + add new features)
function IWin.UI:CreateAdvancedTab()
    local content = self.tabs[5].scrollChild
    local y = -10

    -- Throttle Settings section
    local throttleSection = self:CreateSection(content, 10, y, 560, 195, "Throttle Settings")

    self:CreateCompactSlider(throttleSection, "Rotation Throttle", "RotationThrottle", 0.05, 1.0, SPACING.INNER_PADDING, -40, "s",
        "How often rotation checks run. Lower = faster response, higher CPU.", "TIME")
    self:CreateCompactSlider(throttleSection, "Overpower Window", "OverpowerWindow", 1, 10, SPACING.INNER_PADDING, -95, "s",
        "Time window after dodge to use Overpower.", "TIME")
    self:CreateCompactSlider(throttleSection, "Revenge Window", "RevengeWindow", 1, 10, SPACING.INNER_PADDING, -150, "s",
        "Time window after block/dodge/parry to use Revenge (SuperWOW).", "TIME")

    y = y - 205

    -- SuperWOW Settings section
    local swSection = self:CreateSection(content, 10, y, 560, 140, "SuperWOW Settings")

    self:CreateCompactSlider(swSection, "Heroic Strike Queue Window", "HeroicStrikeQueueWindow", 0.1, 2.0, SPACING.INNER_PADDING, -40, "s",
        "Queue Heroic Strike/Cleave when this close to next swing (SuperWOW).", "TIME")
    self:CreateCompactSlider(swSection, "AOE Target Threshold", "AOETargetThreshold", 2, 10, SPACING.INNER_PADDING, -95, "",
        "Minimum nearby enemies to trigger AOE abilities (SuperWOW).", "RAGE")

    y = y - 150

    -- Legacy Settings section
    local legacySection = self:CreateSection(content, 10, y, 560, 85, "Legacy Settings")

    local legacyNote = legacySection:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    legacyNote:SetPoint("TOPLEFT", legacySection, "TOPLEFT", SPACING.INNER_PADDING, -35)
    legacyNote:SetText("Legacy setting (use Boss/Debuffs tab for boss-specific values)")
    legacyNote:SetTextColor(0.7, 0.7, 0.7)

    self:CreateCompactSlider(legacySection, "Sunder Stack Target (Legacy)", "SunderStacks", 1, 5, SPACING.INNER_PADDING, -55, "",
        "Legacy setting. Use SunderStacksBoss/Trash in Boss/Debuffs tab instead.", "RAGE")

    y = y - 95

    -- Cache Management section
    local cacheSection = self:CreateSection(content, 10, y, 560, 120, "Cache Management")

    local cacheLabel = cacheSection:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    cacheLabel:SetPoint("TOPLEFT", cacheSection, "TOPLEFT", SPACING.INNER_PADDING, -35)
    cacheLabel:SetText("Spell Cache:")

    local cacheCount = cacheSection:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    cacheCount:SetPoint("LEFT", cacheLabel, "RIGHT", 5, 0)
    local count = 0
    for _ in pairs(IWin_Settings.SpellCache or {}) do count = count + 1 end
    cacheCount:SetText(count .. " spells cached")
    cacheCount:SetTextColor(0, 1, 0)

    -- Clear cache button
    local clearBtn = CreateFrame("Button", nil, cacheSection, "UIPanelButtonTemplate")
    clearBtn:SetWidth(120)
    clearBtn:SetHeight(25)
    clearBtn:SetPoint("LEFT", cacheCount, "RIGHT", 20, 0)
    clearBtn:SetText("Clear Cache")
    clearBtn:SetScript("OnClick", function()
        if IWin_Settings and type(IWin_Settings) == "table" then
            IWin_Settings.SpellCache = {}
            IWin_Settings.SpellIDCache = {}
            IWin_Settings.AttackSlot = nil
            IWin_Settings.RevengeSlot = nil
            cacheCount:SetText("0 spells cached")
            DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[IWin] Spell cache cleared|r")
        end
    end)
    clearBtn:SetScript("OnEnter", function()
        GameTooltip:SetOwner(this, "ANCHOR_TOP")
        GameTooltip:SetText("Clear Spell Cache", 1, 1, 1)
        GameTooltip:AddLine("Clears cached spell data. Use after learning new spells. Cache rebuilds automatically.", 0.8, 0.8, 0.8, true)
        GameTooltip:Show()
    end)
    clearBtn:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    cacheSection.cacheCount = cacheCount

    y = y - 130

    -- Import/Export Settings section
    local importExportSection = self:CreateSection(content, 10, y, 560, 120, "Import/Export Settings")

    local exportBtn = CreateFrame("Button", nil, importExportSection, "UIPanelButtonTemplate")
    exportBtn:SetWidth(140)
    exportBtn:SetHeight(25)
    exportBtn:SetPoint("TOPLEFT", importExportSection, "TOPLEFT", SPACING.INNER_PADDING, -35)
    exportBtn:SetText("Export Settings")
    exportBtn:SetScript("OnClick", function()
        IWin.UI:ExportSettings()
    end)
    exportBtn:SetScript("OnEnter", function()
        GameTooltip:SetOwner(this, "ANCHOR_TOP")
        GameTooltip:SetText("Export Settings", 1, 1, 1)
        GameTooltip:AddLine("Generate a settings string you can copy and share.", 0.8, 0.8, 0.8, true)
        GameTooltip:Show()
    end)
    exportBtn:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    local importBtn = CreateFrame("Button", nil, importExportSection, "UIPanelButtonTemplate")
    importBtn:SetWidth(140)
    importBtn:SetHeight(25)
    importBtn:SetPoint("LEFT", exportBtn, "RIGHT", 10, 0)
    importBtn:SetText("Import Settings")
    importBtn:SetScript("OnClick", function()
        IWin.UI:ImportSettings()
    end)
    importBtn:SetScript("OnEnter", function()
        GameTooltip:SetOwner(this, "ANCHOR_TOP")
        GameTooltip:SetText("Import Settings", 1, 1, 1)
        GameTooltip:AddLine("Load settings from a previously exported string.", 0.8, 0.8, 0.8, true)
        GameTooltip:Show()
    end)
    importBtn:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    local infoText = importExportSection:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    infoText:SetPoint("TOPLEFT", exportBtn, "BOTTOMLEFT", 0, -10)
    infoText:SetPoint("RIGHT", importExportSection, "RIGHT", -SPACING.INNER_PADDING, 0)
    infoText:SetText("Export creates a compressed string of your settings.\nImport loads settings from a string. Use for backups or sharing.")
    infoText:SetTextColor(0.7, 0.7, 0.7)
    infoText:SetJustifyH("LEFT")

    y = y - 130

    -- Compare Mode section
    local compareSection = self:CreateSection(content, 10, y, 560, 110, "Visual Helpers")

    local compareCheck = self:CreateCheckbox(compareSection, "Show Differences from Default", "dummy", SPACING.INNER_PADDING, -35,
        "Compare Mode",
        "Highlight settings that differ from default values with orange border.")

    compareCheck:SetChecked(self.compareMode)
    compareCheck:SetScript("OnClick", function()
        IWin.UI.compareMode = compareCheck:GetChecked()
        IWin.UI:RefreshControls()
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[IWin] Compare mode " .. (IWin.UI.compareMode and "enabled" or "disabled") .. "|r")
    end)

    local minimapCheck = self:CreateCheckbox(compareSection, "Show Minimap Button", "ShowMinimapButton", SPACING.INNER_PADDING, -60,
        "Minimap Button",
        "Show/hide the minimap button. Use /iwin ui to reopen config if hidden.")

    minimapCheck:SetScript("OnClick", function()
        local show = minimapCheck:GetChecked()
        IWin_Settings["ShowMinimapButton"] = show
        if show then
            if IWin.UI.minimapButton then
                IWin.UI.minimapButton:Show()
            else
                IWin.UI:CreateMinimapButton()
            end
            DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[IWin] Minimap button shown|r")
        else
            if IWin.UI.minimapButton then
                IWin.UI.minimapButton:Hide()
            end
            DEFAULT_CHAT_FRAME:AddMessage("|cffff8800[IWin] Minimap button hidden. Use /iwin ui to reopen config|r")
        end
    end)
end

-- Create bottom buttons
function IWin.UI:CreateButtons()
    local frame = self.frame

    -- Save & Close button
    local saveBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    saveBtn:SetWidth(120)
    saveBtn:SetHeight(BUTTON_HEIGHT)
    saveBtn:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 20, 15)
    saveBtn:SetText("Save & Close")
    saveBtn:SetScript("OnClick", function()
        IWin.UI:SaveSettings()
        IWin.UI:Hide()
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[IWin] Settings saved|r")
    end)
    saveBtn:SetScript("OnEnter", function()
        GameTooltip:SetOwner(this, "ANCHOR_TOP")
        GameTooltip:SetText("Save & Close", 1, 1, 1)
        GameTooltip:AddLine("Save all changes and close the configuration window.", 0.8, 0.8, 0.8, true)
        GameTooltip:Show()
    end)
    saveBtn:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    -- Cancel button
    local cancelBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    cancelBtn:SetWidth(100)
    cancelBtn:SetHeight(BUTTON_HEIGHT)
    cancelBtn:SetPoint("LEFT", saveBtn, "RIGHT", 10, 0)
    cancelBtn:SetText("Cancel")
    cancelBtn:SetScript("OnClick", function()
        IWin.UI:RevertSettings()
        IWin.UI:Hide()
    end)
    cancelBtn:SetScript("OnEnter", function()
        GameTooltip:SetOwner(this, "ANCHOR_TOP")
        GameTooltip:SetText("Cancel", 1, 1, 1)
        GameTooltip:AddLine("Discard all changes and close the window.", 0.8, 0.8, 0.8, true)
        GameTooltip:Show()
    end)
    cancelBtn:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    -- Apply button
    local applyBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    applyBtn:SetWidth(100)
    applyBtn:SetHeight(BUTTON_HEIGHT)
    applyBtn:SetPoint("LEFT", cancelBtn, "RIGHT", 10, 0)
    applyBtn:SetText("Apply")
    applyBtn:SetScript("OnClick", function()
        IWin.UI:SaveSettings()
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[IWin] Settings applied|r")
    end)
    applyBtn:SetScript("OnEnter", function()
        GameTooltip:SetOwner(this, "ANCHOR_TOP")
        GameTooltip:SetText("Apply", 1, 1, 1)
        GameTooltip:AddLine("Save changes without closing the window.", 0.8, 0.8, 0.8, true)
        GameTooltip:Show()
    end)
    applyBtn:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    -- Reset to Defaults button
    local resetBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    resetBtn:SetWidth(140)
    resetBtn:SetHeight(BUTTON_HEIGHT)
    resetBtn:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -20, 15)
    resetBtn:SetText("Reset to Defaults")
    resetBtn:SetScript("OnClick", function()
        IWin.UI:ResetDefaults()
    end)
    resetBtn:SetScript("OnEnter", function()
        GameTooltip:SetOwner(this, "ANCHOR_TOP")
        GameTooltip:SetText("Reset to Defaults", 1, 1, 1)
        GameTooltip:AddLine("Reset ALL settings to default values. Cannot be undone!", 0.8, 0.8, 0.8, true)
        GameTooltip:Show()
    end)
    resetBtn:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
end

-- Create minimap button
function IWin.UI:CreateMinimapButton()
    if self.minimapButton then return end

    -- Check if user wants minimap button
    if IWin_Settings and IWin_Settings["ShowMinimapButton"] == false then
        return
    end

    -- Create button
    local button = CreateFrame("Button", "IWinMinimapButton", Minimap)
    button:SetWidth(32)
    button:SetHeight(32)
    button:SetFrameStrata("MEDIUM")
    button:SetFrameLevel(8)
    button:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

    -- Icon texture (using Rage icon)
    local icon = button:CreateTexture("IWinMinimapButtonIcon", "BACKGROUND")
    icon:SetWidth(20)
    icon:SetHeight(20)
    icon:SetPoint("CENTER", 0, 1)
    icon:SetTexture("Interface\\Icons\\Ability_Warrior_BattleShout")

    -- Border
    local overlay = button:CreateTexture("IWinMinimapButtonBorder", "OVERLAY")
    overlay:SetWidth(52)
    overlay:SetHeight(52)
    overlay:SetPoint("TOPLEFT", 0, 0)
    overlay:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")

    -- Position (default angle)
    local angle = IWin_Settings and IWin_Settings.MinimapButtonAngle or 200
    local angleRad = math.rad(angle)
    local x = 80 * math.cos(angleRad)
    local y = 80 * math.sin(angleRad)
    button:SetPoint("CENTER", Minimap, "CENTER", x, y)

    -- Click handler
    button:SetScript("OnClick", function()
        IWin.UI:Toggle()
    end)

    -- Tooltip
    button:SetScript("OnEnter", function()
        GameTooltip:SetOwner(this, "ANCHOR_LEFT")
        GameTooltip:SetText("IWin", 1, 1, 1)
        GameTooltip:AddLine("Warrior rotation addon", 0.8, 0.8, 0.8, true)
        GameTooltip:AddLine(" ", 1, 1, 1)
        GameTooltip:AddLine("Left-click: Toggle config UI", 0.7, 0.7, 0.7, true)
        GameTooltip:AddLine("Right-click: Drag to move", 0.7, 0.7, 0.7, true)
        GameTooltip:Show()
    end)

    button:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    -- Dragging
    button:RegisterForDrag("RightButton")
    button:SetScript("OnDragStart", function()
        this:LockHighlight()
        this.isDragging = true
    end)

    button:SetScript("OnDragStop", function()
        this:UnlockHighlight()
        this.isDragging = false
    end)

    button:SetScript("OnUpdate", function()
        if this.isDragging then
            local xpos, ypos = GetCursorPosition()
            local xmin, ymin = Minimap:GetLeft(), Minimap:GetBottom()

            xpos = xmin - xpos / Minimap:GetEffectiveScale() + 70
            ypos = ypos / Minimap:GetEffectiveScale() - ymin - 70

            local angle = math.deg(math.atan2(ypos, xpos))
            if angle < 0 then angle = angle + 360 end

            local angleRad = math.rad(angle)
            local x = 80 * math.cos(angleRad)
            local y = 80 * math.sin(angleRad)
            this:SetPoint("CENTER", Minimap, "CENTER", x, y)

            -- Save position
            if IWin_Settings then
                IWin_Settings.MinimapButtonAngle = angle
            end
        end
    end)

    self.minimapButton = button
    button:Show()
end

-- Initialize the UI
function IWin.UI:Initialize()
    if self.frame then return end

    self:CreateMainFrame()
    self:CreateTabs()
    self:CreateButtons()
end

-- Show the UI
function IWin.UI:Show()
    if not IWin_Settings or type(IWin_Settings) ~= "table" then
        DEFAULT_CHAT_FRAME:AddMessage("|cffff0000[IWin] Cannot show UI - IWin_Settings not initialized|r")
        return
    end

    local success, err = pcall(function()
        if not self.frame then
            self:Initialize()
        end

        if not self.frame then
            DEFAULT_CHAT_FRAME:AddMessage("|cffff0000[IWin] Failed to create UI frame|r")
            return
        end

        -- Restore window position if saved
        if IWin_Settings["UIPosition"] and type(IWin_Settings["UIPosition"]) == "table" then
            local pos = IWin_Settings["UIPosition"]
            local xOfs = pos.xOfs or 0
            local yOfs = pos.yOfs or 0
            local screenWidth = GetScreenWidth()
            local screenHeight = GetScreenHeight()

            -- Reset to center if position invalid
            if math.abs(xOfs) > screenWidth or math.abs(yOfs) > screenHeight then
                xOfs = 0
                yOfs = 0
            end

            self.frame:ClearAllPoints()
            self.frame:SetPoint(
                pos.point or "CENTER",
                UIParent,
                pos.relativePoint or "CENTER",
                xOfs,
                yOfs
            )
        end

        -- Restore last viewed tab
        if IWin_Settings["UILastTab"] and IWin_Settings["UILastTab"] >= 1 and IWin_Settings["UILastTab"] <= 5 then
            self:SwitchTab(IWin_Settings["UILastTab"])
        end

        -- Refresh all controls
        self:RefreshControls()

        -- Backup current settings
        self:BackupSettings()

        self.frame:Show()
    end)

    if not success then
        DEFAULT_CHAT_FRAME:AddMessage("|cffff0000[IWin] UI Show failed: " .. tostring(err) .. "|r")
    end
end

-- Hide the UI
function IWin.UI:Hide()
    if self.frame then
        self.frame:Hide()
    end
end

-- Toggle UI visibility
function IWin.UI:Toggle()
    if self.frame and self.frame:IsVisible() then
        self:Hide()
    else
        self:Show()
    end
end

-- Backup current settings
function IWin.UI:BackupSettings()
    if not IWin_Settings or type(IWin_Settings) ~= "table" then
        DEFAULT_CHAT_FRAME:AddMessage("|cffff0000[IWin] Cannot backup settings - IWin_Settings not available|r")
        return
    end

    local success, err = pcall(function()
        self.backup = {}
        for k, v in pairs(IWin_Settings) do
            if type(v) ~= "table" then
                self.backup[k] = v
            end
        end
    end)

    if not success then
        DEFAULT_CHAT_FRAME:AddMessage("|cffff0000[IWin] BackupSettings failed: " .. tostring(err) .. "|r")
        self.backup = {}
    end
end

-- Revert to backed up settings
function IWin.UI:RevertSettings()
    if not self.backup or type(self.backup) ~= "table" then
        DEFAULT_CHAT_FRAME:AddMessage("|cffff0000[IWin] No backup to revert to|r")
        return
    end

    if not IWin_Settings or type(IWin_Settings) ~= "table" then
        DEFAULT_CHAT_FRAME:AddMessage("|cffff0000[IWin] Cannot revert settings|r")
        return
    end

    local success, err = pcall(function()
        for k, v in pairs(self.backup) do
            IWin_Settings[k] = v
        end

        self:RefreshControls()
    end)

    if not success then
        DEFAULT_CHAT_FRAME:AddMessage("|cffff0000[IWin] RevertSettings failed: " .. tostring(err) .. "|r")
    else
        DEFAULT_CHAT_FRAME:AddMessage("|cffff0000[IWin] Settings reverted|r")
    end
end

-- Save settings (already saved live)
function IWin.UI:SaveSettings()
    self.backup = {}
end

-- Reset all settings to defaults
function IWin.UI:ResetDefaults()
    if not IWin_Settings or type(IWin_Settings) ~= "table" then
        DEFAULT_CHAT_FRAME:AddMessage("|cffff0000[IWin] Cannot reset - IWin_Settings not available|r")
        return
    end

    if not self.DEFAULTS or type(self.DEFAULTS) ~= "table" then
        DEFAULT_CHAT_FRAME:AddMessage("|cffff0000[IWin] Cannot reset - DEFAULTS table not found|r")
        return
    end

    local count = 0
    for key, defaultValue in pairs(self.DEFAULTS) do
        if IWin_Settings[key] ~= nil then
            IWin_Settings[key] = defaultValue
            count = count + 1
        end
    end

    self:RefreshControls()
    self:BackupSettings()

    DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[IWin] Settings reset to defaults (" .. count .. " settings)|r")
end

-- Refresh all UI controls to match current IWin_Settings values
function IWin.UI:RefreshControls()
    if not self.frame then return end
    if not IWin_Settings or type(IWin_Settings) ~= "table" then
        DEFAULT_CHAT_FRAME:AddMessage("|cffff0000[IWin] Cannot refresh UI - IWin_Settings not available|r")
        return
    end

    -- Refresh all stored controls
    for _, control in ipairs(self.controls) do
        if control.container then
            -- Slider control
            local settingKey = control.settingKey
            if settingKey and IWin_Settings[settingKey] ~= nil then
                control.slider:SetValue(IWin_Settings[settingKey])
            end
        elseif control.settingKey then
            -- Checkbox control
            local settingKey = control.settingKey
            if IWin_Settings[settingKey] ~= nil then
                control:SetChecked(IWin_Settings[settingKey])
            end
        elseif control:GetObjectType() == "CheckButton" then
            -- Legacy checkbox
            local name = control:GetName()
            if name then
                local settingKey = string.gsub(name, "IWinCheck_", "")
                if IWin_Settings[settingKey] ~= nil then
                    control:SetChecked(IWin_Settings[settingKey])
                end
            end
        elseif control:GetObjectType() == "Slider" then
            -- Legacy slider
            local name = control:GetName()
            if name then
                local settingKey = string.gsub(name, "IWinSlider_", "")
                if IWin_Settings[settingKey] ~= nil then
                    control:SetValue(IWin_Settings[settingKey])
                end
            end
        end
    end

    -- Refresh cache count if Advanced tab exists
    if self.tabs[5] and self.tabs[5].scrollChild then
        local children = {self.tabs[5].scrollChild:GetChildren()}
        for _, child in ipairs(children) do
            if child.cacheCount then
                local count = 0
                for _ in pairs(IWin_Settings.SpellCache or {}) do count = count + 1 end
                child.cacheCount:SetText(count .. " spells cached")
                break
            end
        end
    end
end

-- Export settings to a string
function IWin.UI:ExportSettings()
    if not IWin_Settings or type(IWin_Settings) ~= "table" then
        DEFAULT_CHAT_FRAME:AddMessage("|cffff0000[IWin] Cannot export - IWin_Settings not available|r")
        return
    end

    local settingsStr = ""
    local count = 0

    for key, value in pairs(IWin_Settings) do
        -- Only export basic settings (not caches or internal state)
        if type(value) ~= "table" and key ~= "UIPosition" and key ~= "UILastTab" then
            if type(value) == "boolean" then
                settingsStr = settingsStr .. key .. "=" .. (value and "1" or "0") .. ","
                count = count + 1
            elseif type(value) == "number" then
                settingsStr = settingsStr .. key .. "=" .. value .. ","
                count = count + 1
            end
        end
    end

    -- Remove trailing comma
    if string.len(settingsStr) > 0 then
        settingsStr = string.sub(settingsStr, 1, -2)
    end

    -- Create popup frame to display the export string
    local popup = CreateFrame("Frame", "IWinExportFrame", UIParent)
    popup:SetWidth(500)
    popup:SetHeight(200)
    popup:SetPoint("CENTER")
    popup:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true,
        tileSize = 32,
        edgeSize = 32,
        insets = { left = 8, right = 8, top = 8, bottom = 8 }
    })
    popup:SetBackdropColor(0, 0, 0, 1)
    popup:EnableMouse(true)
    popup:SetMovable(true)
    popup:RegisterForDrag("LeftButton")
    popup:SetScript("OnDragStart", popup.StartMoving)
    popup:SetScript("OnDragStop", popup.StopMovingOrSizing)
    popup:SetFrameStrata("DIALOG")

    local title = popup:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", popup, "TOP", 0, -15)
    title:SetText("Export Settings")

    local info = popup:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    info:SetPoint("TOP", title, "BOTTOM", 0, -10)
    info:SetText("Copy this string to backup or share your settings (" .. count .. " settings)")
    info:SetTextColor(1, 0.82, 0)

    local editBox = CreateFrame("EditBox", nil, popup)
    editBox:SetWidth(470)
    editBox:SetHeight(80)
    editBox:SetPoint("TOP", info, "BOTTOM", 0, -10)
    editBox:SetAutoFocus(true)
    editBox:SetFontObject(ChatFontNormal)
    editBox:SetMultiLine(true)
    editBox:SetMaxLetters(0)
    editBox:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\ChatFrame\\ChatFrameBackground",
        tile = true,
        edgeSize = 1,
        tileSize = 5,
    })
    editBox:SetBackdropColor(0, 0, 0, 0.8)
    editBox:SetBackdropBorderColor(0.3, 0.3, 0.3, 0.8)
    editBox:SetText(settingsStr)
    editBox:HighlightText()
    editBox:SetScript("OnEscapePressed", function()
        popup:Hide()
    end)

    local closeBtn = CreateFrame("Button", nil, popup, "UIPanelButtonTemplate")
    closeBtn:SetWidth(100)
    closeBtn:SetHeight(25)
    closeBtn:SetPoint("BOTTOM", popup, "BOTTOM", 0, 15)
    closeBtn:SetText("Close")
    closeBtn:SetScript("OnClick", function()
        popup:Hide()
    end)

    popup:Show()
    DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[IWin] Settings exported. Copy the string from the popup.|r")
end

-- Import settings from a string
function IWin.UI:ImportSettings()
    if not IWin_Settings or type(IWin_Settings) ~= "table" then
        DEFAULT_CHAT_FRAME:AddMessage("|cffff0000[IWin] Cannot import - IWin_Settings not available|r")
        return
    end

    -- Create popup frame for import
    local popup = CreateFrame("Frame", "IWinImportFrame", UIParent)
    popup:SetWidth(500)
    popup:SetHeight(230)
    popup:SetPoint("CENTER")
    popup:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true,
        tileSize = 32,
        edgeSize = 32,
        insets = { left = 8, right = 8, top = 8, bottom = 8 }
    })
    popup:SetBackdropColor(0, 0, 0, 1)
    popup:EnableMouse(true)
    popup:SetMovable(true)
    popup:RegisterForDrag("LeftButton")
    popup:SetScript("OnDragStart", popup.StartMoving)
    popup:SetScript("OnDragStop", popup.StopMovingOrSizing)
    popup:SetFrameStrata("DIALOG")

    local title = popup:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", popup, "TOP", 0, -15)
    title:SetText("Import Settings")

    local info = popup:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    info:SetPoint("TOP", title, "BOTTOM", 0, -10)
    info:SetText("Paste your exported settings string below")
    info:SetTextColor(1, 0.82, 0)

    local editBox = CreateFrame("EditBox", nil, popup)
    editBox:SetWidth(470)
    editBox:SetHeight(80)
    editBox:SetPoint("TOP", info, "BOTTOM", 0, -10)
    editBox:SetAutoFocus(true)
    editBox:SetFontObject(ChatFontNormal)
    editBox:SetMultiLine(true)
    editBox:SetMaxLetters(0)
    editBox:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\ChatFrame\\ChatFrameBackground",
        tile = true,
        edgeSize = 1,
        tileSize = 5,
    })
    editBox:SetBackdropColor(0, 0, 0, 0.8)
    editBox:SetBackdropBorderColor(0.3, 0.3, 0.3, 0.8)

    local importBtn = CreateFrame("Button", nil, popup, "UIPanelButtonTemplate")
    importBtn:SetWidth(100)
    importBtn:SetHeight(25)
    importBtn:SetPoint("BOTTOMLEFT", popup, "BOTTOM", -55, 15)
    importBtn:SetText("Import")
    importBtn:SetScript("OnClick", function()
        local settingsStr = editBox:GetText()

        if not settingsStr or string.len(settingsStr) == 0 then
            DEFAULT_CHAT_FRAME:AddMessage("|cffff0000[IWin] No settings string provided|r")
            return
        end

        local success, err = pcall(function()
            local count = 0
            -- Parse key=value pairs separated by commas
            for pair in string.gfind(settingsStr, "[^,]+") do
                local key, value = string.match(pair, "([^=]+)=([^=]+)")
                if key and value then
                    key = strtrim(key)
                    value = strtrim(value)

                    -- Check if this is a valid setting
                    if IWin_Settings[key] ~= nil then
                        if type(IWin_Settings[key]) == "boolean" then
                            IWin_Settings[key] = (value == "1" or value == "true")
                            count = count + 1
                        elseif type(IWin_Settings[key]) == "number" then
                            local num = tonumber(value)
                            if num then
                                IWin_Settings[key] = num
                                count = count + 1
                            end
                        end
                    end
                end
            end

            DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[IWin] Imported " .. count .. " settings|r")
            IWin.UI:RefreshControls()
            IWin.UI:BackupSettings()
        end)

        if not success then
            DEFAULT_CHAT_FRAME:AddMessage("|cffff0000[IWin] Import failed: " .. tostring(err) .. "|r")
        end

        popup:Hide()
    end)

    local cancelBtn = CreateFrame("Button", nil, popup, "UIPanelButtonTemplate")
    cancelBtn:SetWidth(100)
    cancelBtn:SetHeight(25)
    cancelBtn:SetPoint("LEFT", importBtn, "RIGHT", 10, 0)
    cancelBtn:SetText("Cancel")
    cancelBtn:SetScript("OnClick", function()
        popup:Hide()
    end)

    popup:Show()
end
