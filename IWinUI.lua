--[[
#######################################
# IWin UI - Configuration Interface  #
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

-- Constants
local FRAME_WIDTH = 520
local FRAME_HEIGHT = 520
local TAB_HEIGHT = 24
local CONTENT_HEIGHT = 410
local BUTTON_HEIGHT = 25

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
    frame:SetClampedToScreen(true)  -- Prevent window from being dragged off screen
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function() this:StartMoving() end)
    frame:SetScript("OnDragStop", function()
        this:StopMovingOrSizing()
        -- Save window position
        local point, _, relativePoint, xOfs, yOfs = this:GetPoint()
        IWin_Settings["UIPosition"] = {
            point = point,
            relativePoint = relativePoint,
            xOfs = xOfs,
            yOfs = yOfs
        }
    end)

    -- ESC key closes the frame
    table.insert(UISpecialFrames, "IWinConfigFrame")

    frame:Hide()

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
    title:SetText("IWin Configuration")
    title:SetTextColor(0, 0.6, 1)

    -- Close button
    local closeBtn = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -5, -5)
    closeBtn:SetScript("OnClick", function()
        IWin.UI:Hide()
    end)

    self.frame = frame
end

-- Create tab button
function IWin.UI:CreateTabButton(parent, id, text, point, relativeTo, relativePoint, xOffset, yOffset)
    local btn = CreateFrame("Button", "IWinTabButton" .. id, parent)
    btn:SetWidth(80)
    btn:SetHeight(TAB_HEIGHT)
    btn:SetPoint(point, relativeTo, relativePoint, xOffset, yOffset)

    -- Normal texture
    btn:SetNormalTexture("Interface\\PaperDollInfoFrame\\UI-Character-ActiveTab")
    local ntex = btn:GetNormalTexture()
    ntex:SetTexCoord(0, 1, 1, 0)

    -- Highlight texture
    btn:SetHighlightTexture("Interface\\PaperDollInfoFrame\\UI-Character-ActiveTab")
    local htex = btn:GetHighlightTexture()
    htex:SetTexCoord(0, 1, 1, 0)
    htex:SetAlpha(0.4)

    -- Text
    local label = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    label:SetPoint("CENTER", btn, "CENTER", 0, -3)
    label:SetText(text)

    -- Click handler
    btn:SetScript("OnClick", function()
        IWin.UI:SwitchTab(id)
    end)

    btn.label = label
    return btn
end

-- Create tab system
function IWin.UI:CreateTabs()
    local frame = self.frame

    -- Create tab buttons (positioned below the title)
    self.tabs[1] = self:CreateTabButton(frame, 1, "Toggles", "TOPLEFT", frame, "TOPLEFT", 15, -45)
    self.tabs[2] = self:CreateTabButton(frame, 2, "DPS", "LEFT", self.tabs[1], "RIGHT", 0, 0)
    self.tabs[3] = self:CreateTabButton(frame, 3, "Tank", "LEFT", self.tabs[2], "RIGHT", 0, 0)
    self.tabs[4] = self:CreateTabButton(frame, 4, "Health", "LEFT", self.tabs[3], "RIGHT", 0, 0)
    self.tabs[5] = self:CreateTabButton(frame, 5, "Debuffs", "LEFT", self.tabs[4], "RIGHT", 0, 0)
    self.tabs[6] = self:CreateTabButton(frame, 6, "Boss", "LEFT", self.tabs[5], "RIGHT", 0, 0)
    self.tabs[7] = self:CreateTabButton(frame, 7, "Advanced", "LEFT", self.tabs[6], "RIGHT", 0, 0)

    -- Create content frames for each tab (positioned below tabs)
    for i = 1, 7 do
        local content = CreateFrame("Frame", "IWinTabContent" .. i, frame)
        content:SetWidth(FRAME_WIDTH - 40)
        content:SetHeight(CONTENT_HEIGHT)
        content:SetPoint("TOP", frame, "TOP", 0, -75)
        content:Hide()

        self.tabs[i].content = content
    end

    -- Populate tabs
    self:CreateTogglesTab()
    self:CreateDPSTab()
    self:CreateTankTab()
    self:CreateHealthTab()
    self:CreateDebuffTab()
    self:CreateBossTab()
    self:CreateAdvancedTab()

    -- Show first tab
    self:SwitchTab(1)
end

-- Switch to a different tab
function IWin.UI:SwitchTab(tabId)
    -- Hide all tabs
    for i = 1, 7 do
        self.tabs[i].content:Hide()
        self.tabs[i].label:SetTextColor(1, 1, 1)
    end

    -- Show selected tab
    self.tabs[tabId].content:Show()
    self.tabs[tabId].label:SetTextColor(1, 0.82, 0)
    self.currentTab = tabId

    -- Save last viewed tab
    IWin_Settings["UILastTab"] = tabId
end

-- Create a checkbox control
function IWin.UI:CreateCheckbox(parent, label, settingKey, x, y, tooltipTitle, tooltipText)
    local cb = CreateFrame("CheckButton", "IWinCheck_" .. settingKey, parent, "UICheckButtonTemplate")
    cb:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)

    local text = cb:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    text:SetPoint("LEFT", cb, "RIGHT", 5, 0)
    text:SetText(label)

    cb:SetChecked(IWin_Settings[settingKey])
    cb:SetScript("OnClick", function()
        IWin_Settings[settingKey] = cb:GetChecked()
    end)

    -- Add tooltip
    if tooltipTitle and tooltipText then
        cb:SetScript("OnEnter", function()
            GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
            GameTooltip:SetText(tooltipTitle, 1, 1, 1)
            GameTooltip:AddLine(tooltipText, 0.8, 0.8, 0.8, true)
            GameTooltip:Show()
        end)
        cb:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)
    end

    cb.label = text
    table.insert(self.controls, cb)
    return cb
end

-- Create a slider with editbox
function IWin.UI:CreateSlider(parent, label, settingKey, minVal, maxVal, x, y, suffix, tooltipText)
    suffix = suffix or ""

    -- Label
    local labelText = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    labelText:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    labelText:SetText(label)

    -- Slider
    local slider = CreateFrame("Slider", "IWinSlider_" .. settingKey, parent)
    slider:SetWidth(150)
    slider:SetHeight(16)
    slider:SetPoint("TOPLEFT", labelText, "BOTTOMLEFT", 0, -8)
    slider:SetOrientation("HORIZONTAL")
    slider:SetMinMaxValues(minVal, maxVal)
    slider:SetValue(IWin_Settings[settingKey] or minVal)
    slider:SetValueStep(1)

    -- Slider textures
    slider:SetBackdrop({
        bgFile = "Interface\\Buttons\\UI-SliderBar-Background",
        edgeFile = "Interface\\Buttons\\UI-SliderBar-Border",
        tile = true,
        tileSize = 8,
        edgeSize = 8,
        insets = { left = 3, right = 3, top = 6, bottom = 6 }
    })

    local thumb = slider:CreateTexture(nil, "OVERLAY")
    thumb:SetTexture("Interface\\Buttons\\UI-SliderBar-Button-Horizontal")
    thumb:SetWidth(32)
    thumb:SetHeight(32)
    slider:SetThumbTexture(thumb)

    -- EditBox
    local editbox = CreateFrame("EditBox", "IWinEdit_" .. settingKey, parent)
    editbox:SetWidth(50)
    editbox:SetHeight(20)
    editbox:SetPoint("LEFT", slider, "RIGHT", 10, 0)
    editbox:SetAutoFocus(false)
    editbox:SetNumeric(false)  -- Allow decimals for throttle slider
    editbox:SetMaxLetters(5)

    editbox:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\ChatFrame\\ChatFrameBackground",
        tile = true,
        edgeSize = 1,
        tileSize = 5,
    })
    editbox:SetBackdropColor(0, 0, 0, 0.5)
    editbox:SetBackdropBorderColor(0.3, 0.3, 0.3, 0.8)

    local fontString = editbox:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    fontString:SetPoint("CENTER", editbox, "CENTER", 0, 0)
    editbox:SetFontObject(GameFontHighlight)

    -- Sync slider and editbox
    local function updateValue(value)
        if value < minVal then value = minVal end
        if value > maxVal then value = maxVal end
        slider:SetValue(value)
        editbox:SetText(value .. suffix)
        IWin_Settings[settingKey] = value
    end

    slider:SetScript("OnValueChanged", function()
        local value = slider:GetValue()
        -- Format based on whether we expect decimals
        if settingKey == "RotationThrottle" then
            editbox:SetText(string.format("%.2f", value) .. suffix)
            IWin_Settings[settingKey] = value
        else
            editbox:SetText(math.floor(value) .. suffix)
            IWin_Settings[settingKey] = math.floor(value)
        end
    end)

    editbox:SetScript("OnEnterPressed", function()
        local text = editbox:GetText()
        -- Remove suffix if present
        if suffix ~= "" then
            text = string.gsub(text, suffix, "")
        end
        local value = tonumber(text)
        if value then
            updateValue(value)
        else
            editbox:SetText(slider:GetValue() .. suffix)
        end
        editbox:ClearFocus()
    end)

    editbox:SetScript("OnEscapePressed", function()
        editbox:SetText(slider:GetValue() .. suffix)
        editbox:ClearFocus()
    end)

    -- Initialize editbox
    editbox:SetText((IWin_Settings[settingKey] or minVal) .. suffix)

    -- Add tooltip to slider
    if tooltipText then
        slider:SetScript("OnEnter", function()
            GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
            GameTooltip:SetText(label, 1, 1, 1)
            GameTooltip:AddLine(tooltipText, 0.8, 0.8, 0.8, true)
            GameTooltip:Show()
        end)
        slider:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)
    end

    table.insert(self.controls, slider)
    table.insert(self.controls, editbox)

    return slider, editbox
end

-- Create Toggles tab (Tab 1)
function IWin.UI:CreateTogglesTab()
    local content = self.tabs[1].content

    local title = content:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", content, "TOP", 0, -10)
    title:SetText("Feature Toggles")

    local desc = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    desc:SetPoint("TOP", title, "BOTTOM", 0, -5)
    desc:SetText("Enable or disable automatic features")
    desc:SetTextColor(0.7, 0.7, 0.7)

    -- Column 1
    self:CreateCheckbox(content, "Auto-Charge", "AutoCharge", 40, -60,
        "Auto-Charge",
        "Automatically use Charge when out of combat and target is in range (8-25 yards). Won't charge if rage is above configured maximum.")
    self:CreateCheckbox(content, "Auto-Battle Shout", "AutoBattleShout", 40, -90,
        "Auto-Battle Shout",
        "Automatically cast Battle Shout when the buff is missing. Uses configured minimum rage threshold when out of combat.")
    self:CreateCheckbox(content, "Auto-Bloodrage", "AutoBloodrage", 40, -120,
        "Auto-Bloodrage",
        "Automatically use Bloodrage for rage generation when rage drops below configured minimum threshold.")
    self:CreateCheckbox(content, "Auto-Trinkets", "AutoTrinkets", 40, -150,
        "Auto-Trinkets",
        "Automatically use offensive trinkets in trinket slots 13 and 14 when available.")

    -- Column 2
    self:CreateCheckbox(content, "Auto-Rend", "AutoRend", 260, -60,
        "Auto-Rend",
        "Automatically apply and maintain Rend on target. Refreshes when configured time remaining is reached.")
    self:CreateCheckbox(content, "Auto-Attack", "AutoAttack", 260, -90,
        "Auto-Attack",
        "Automatically enable auto-attack on your current target when in combat.")
    self:CreateCheckbox(content, "Auto-Stance", "AutoStance", 260, -120,
        "Auto-Stance",
        "Automatically switch stances to use abilities. For example, switching to Berserker for Whirlwind or Battle for Overpower.")
    self:CreateCheckbox(content, "Auto-Shield Block", "AutoShieldBlock", 260, -150,
        "Auto-Shield Block",
        "Automatically use Shield Block before Shield Slam to ensure the blocking buff is active for maximum damage.")

    -- SuperWOW Section
    local superTitle = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    superTitle:SetPoint("TOPLEFT", content, "TOPLEFT", 40, -190)
    superTitle:SetText("SuperWOW Features")
    superTitle:SetTextColor(0, 1, 0)

    self:CreateCheckbox(content, "Auto-Interrupt", "AutoInterrupt", 40, -210,
        "Auto-Interrupt (SuperWOW)",
        "Automatically interrupt enemy spell casts using Pummel or Shield Bash. Requires SuperWOW for cast detection.")
    self:CreateCheckbox(content, "Auto-Revenge", "AutoRevenge", 40, -240,
        "Auto-Revenge",
        "Automatically use Revenge when available after dodging, parrying, or blocking. IMPORTANT: Revenge must be on your action bars for proc detection to work using IsUsableAction API.")
    self:CreateCheckbox(content, "Smart Heroic Strike", "SmartHeroicStrike", 40, -270,
        "Smart Heroic Strike (SuperWOW)",
        "Only queue Heroic Strike/Cleave near swing timer to avoid wasting rage. Requires SuperWOW for swing detection.")

    -- AOE Section
    local aoeTitle = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    aoeTitle:SetPoint("TOPLEFT", content, "TOPLEFT", 260, -190)
    aoeTitle:SetText("AOE Tanking")
    aoeTitle:SetTextColor(1, 0.5, 0)

    self:CreateCheckbox(content, "Battle Shout AOE Mode", "BattleShoutAOEMode", 260, -210,
        "Battle Shout AOE Mode",
        "Spam Battle Shout in tankAOE rotation even when buff is active. This is the 1.12 meta for AOE threat generation. Turn OFF to only cast when buff is missing.")

    -- Info text
    local info = content:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    info:SetPoint("BOTTOM", content, "BOTTOM", 0, 20)
    info:SetText("Hover over checkboxes for detailed information")
    info:SetTextColor(0.5, 0.5, 0.5)
end

-- Create DPS tab (Tab 2)
function IWin.UI:CreateDPSTab()
    local content = self.tabs[2].content

    local title = content:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", content, "TOP", 0, -10)
    title:SetText("DPS Rage Thresholds")

    local desc = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    desc:SetPoint("TOP", title, "BOTTOM", 0, -5)
    desc:SetText("Configure minimum/maximum rage for abilities")
    desc:SetTextColor(0.7, 0.7, 0.7)

    -- Left column
    local y = -60
    self:CreateSlider(content, "Bloodthirst Min", "RageBloodthirstMin", 0, 100, 40, y, "",
        "Minimum rage required to use Bloodthirst. Higher values save rage for other abilities. Default: 30")
    y = y - 50
    self:CreateSlider(content, "Mortal Strike Min", "RageMortalStrikeMin", 0, 100, 40, y, "",
        "Minimum rage required to use Mortal Strike. Higher values save rage for other abilities. Default: 30")
    y = y - 50
    self:CreateSlider(content, "Whirlwind Min", "RageWhirlwindMin", 0, 100, 40, y, "",
        "Minimum rage required to use Whirlwind. Lower values for more frequent AOE, higher to save rage. Default: 25")
    y = y - 50
    self:CreateSlider(content, "Sweeping Strikes Min", "RageSweepingMin", 0, 100, 40, y, "",
        "Minimum rage required to activate Sweeping Strikes in AOE rotation. Controls AOE burst timing. Default: 30")
    y = y - 50
    self:CreateSlider(content, "Heroic Strike Min", "RageHeroicMin", 0, 100, 40, y, "",
        "Minimum rage required to use Heroic Strike as a rage dump. Higher values = less frequent use. Default: 30")
    y = y - 50
    self:CreateSlider(content, "Execute Min", "RageExecuteMin", 0, 100, 40, y, "",
        "Minimum rage required to use Execute on low health targets. Default: 10")
    y = y - 50
    self:CreateSlider(content, "Rend Min", "RageRendMin", 0, 100, 40, y, "",
        "Minimum rage required to apply/refresh Rend bleed. Default: 10")

    -- Right column
    y = -60
    self:CreateSlider(content, "Cleave Min", "RageCleaveMin", 0, 100, 280, y, "",
        "Minimum rage required to use Cleave in AOE situations. Primary AOE rage dump ability. Default: 30")
    y = y - 50
    self:CreateSlider(content, "Charge Max", "RageChargeMax", 0, 100, 280, y, "",
        "Maximum rage threshold for using Charge. Won't charge if rage is above this value. Default: 50")
    y = y - 50
    self:CreateSlider(content, "Bloodrage Min", "RageBloodrageMin", 0, 100, 280, y, "",
        "Triggers Bloodrage when rage drops below this value. Higher values = more aggressive rage generation. Default: 30")
    y = y - 50
    self:CreateSlider(content, "Battle Shout Min (OOC)", "RageShoutMin", 0, 100, 280, y, "",
        "Minimum rage required to cast Battle Shout when OUT of combat. Default: 10")
    y = y - 50
    self:CreateSlider(content, "Battle Shout Min (Combat)", "RageShoutCombatMin", 0, 100, 280, y, "",
        "Minimum rage required to cast Battle Shout when IN combat. Default: 30")
    y = y - 50
    self:CreateSlider(content, "Overpower Min", "RageOverpowerMin", 0, 100, 280, y, "",
        "Minimum rage required to use Overpower. Reactive ability available after enemy dodge. Default: 5")
    y = y - 50
    self:CreateSlider(content, "Interrupt Min (SuperWOW)", "RageInterruptMin", 0, 100, 280, y, "",
        "Minimum rage required to use Pummel/Shield Bash interrupts. Default: 10")
end

-- Create Tank tab (Tab 3)
function IWin.UI:CreateTankTab()
    local content = self.tabs[3].content

    local title = content:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", content, "TOP", 0, -10)
    title:SetText("Tank Rage Thresholds")

    local desc = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    desc:SetPoint("TOP", title, "BOTTOM", 0, -5)
    desc:SetText("Configure rage costs for tanking abilities")
    desc:SetTextColor(0.7, 0.7, 0.7)

    -- Left column
    local y = -60
    self:CreateSlider(content, "Shield Slam Min", "RageShieldSlamMin", 0, 100, 40, y, "",
        "Minimum rage required to use Shield Slam. High threat and damage ability. Default: 20")
    y = y - 50
    self:CreateSlider(content, "Revenge Min", "RageRevengeMin", 0, 100, 40, y, "",
        "Minimum rage required to use Revenge. Available after dodge/parry/block. Default: 5")
    y = y - 50
    self:CreateSlider(content, "Thunder Clap Min", "RageThunderClapMin", 0, 100, 40, y, "",
        "Minimum rage required to use Thunder Clap. AOE threat and attack speed reduction. Default: 20")
    y = y - 50
    self:CreateSlider(content, "Demo Shout Min", "RageDemoShoutMin", 0, 100, 40, y, "",
        "Minimum rage required to use Demoralizing Shout. Reduces enemy attack power. Default: 10")
    y = y - 50
    self:CreateSlider(content, "Sunder Min", "RageSunderMin", 0, 100, 40, y, "",
        "Minimum rage required to apply/maintain Sunder Armor stacks. Primary threat builder. Default: 15")

    -- Right column
    y = -60
    self:CreateSlider(content, "Concussion Blow Min", "RageConcussionBlowMin", 0, 100, 280, y, "",
        "Minimum rage required to use Concussion Blow. Stuns target at low health. Default: 15")
    y = y - 50
    self:CreateSlider(content, "Shield Block Min", "RageShieldBlockMin", 0, 100, 280, y, "",
        "Minimum rage required to use Shield Block. Used before Shield Slam for bonus damage. Default: 10")

    -- Info note
    local note = content:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    note:SetPoint("BOTTOM", content, "BOTTOM", 0, 20)
    note:SetText("Execute Min and Rend Min are in the DPS tab (shared settings)")
    note:SetTextColor(0.7, 0.7, 0.7)
end

-- Create Health tab (Tab 4)
function IWin.UI:CreateHealthTab()
    local content = self.tabs[4].content

    local title = content:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", content, "TOP", 0, -10)
    title:SetText("Health Thresholds")

    local desc = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    desc:SetPoint("TOP", title, "BOTTOM", 0, -5)
    desc:SetText("Configure health-based ability triggers")
    desc:SetTextColor(0.7, 0.7, 0.7)

    -- Centered sliders
    local y = -80
    self:CreateSlider(content, "Last Stand Threshold", "LastStandThreshold", 1, 99, 120, y, "%",
        "Emergency ability that triggers when YOUR health drops below this percentage. Higher values = more defensive. Default: 20%")
    y = y - 80
    self:CreateSlider(content, "Concussion Blow Threshold", "ConcussionBlowThreshold", 1, 99, 120, y, "%",
        "Use Concussion Blow when target health drops below this percentage. Stuns low health targets. Default: 30%")

    -- Info
    local info = content:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    info:SetPoint("BOTTOM", content, "BOTTOM", 0, 40)
    info:SetText("Execute is hardcoded at 20% health threshold")
    info:SetTextColor(0.7, 0.7, 0.7)

    local info2 = content:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    info2:SetPoint("TOP", info, "BOTTOM", 0, -5)
    info2:SetText("Last Stand triggers when your health drops below threshold")
    info2:SetTextColor(0.7, 0.7, 0.7)
end

-- Create Debuffs tab (Tab 5)
function IWin.UI:CreateDebuffTab()
    local content = self.tabs[5].content

    local title = content:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", content, "TOP", 0, -10)
    title:SetText("Debuff Refresh Timings")

    local desc = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    desc:SetPoint("TOP", title, "BOTTOM", 0, -5)
    desc:SetText("Refresh debuffs when this many seconds remain")
    desc:SetTextColor(0.7, 0.7, 0.7)

    -- Sliders
    local y = -80
    self:CreateSlider(content, "Rend Refresh", "RefreshRend", 1, 20, 120, y, "s",
        "Refresh Rend when this many seconds remain on the debuff. Lower = better uptime, higher = fewer GCDs used. Rend lasts 21s total. Default: 5s")
    y = y - 70
    self:CreateSlider(content, "Sunder Armor Refresh", "RefreshSunder", 1, 29, 120, y, "s",
        "Refresh Sunder Armor when below configured stacks or this many seconds remain. Sunder lasts 30s. Helps maintain threat. Default: 5s")
    y = y - 70
    self:CreateSlider(content, "Thunder Clap Refresh", "RefreshThunderClap", 1, 25, 120, y, "s",
        "Refresh Thunder Clap when this many seconds remain. Thunder Clap lasts 26s and reduces attack speed. Important for AOE tanking. Default: 5s")
    y = y - 70
    self:CreateSlider(content, "Demoralizing Shout Refresh", "RefreshDemoShout", 1, 29, 120, y, "s",
        "Refresh Demoralizing Shout when this many seconds remain. Lasts 30s and reduces enemy attack power. Essential for tanking. Default: 3s")

    -- Info
    local info = content:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    info:SetPoint("BOTTOM", content, "BOTTOM", 0, 20)
    info:SetText("Lower values = better uptime but more GCDs used")
    info:SetTextColor(0.7, 0.7, 0.7)
end

-- Create Boss tab (Tab 6)
function IWin.UI:CreateBossTab()
    local content = self.tabs[6].content

    local title = content:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", content, "TOP", 0, -10)
    title:SetText("Boss Detection Settings")

    local desc = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    desc:SetPoint("TOP", title, "BOTTOM", 0, -5)
    desc:SetText("Different thresholds for bosses vs trash mobs")
    desc:SetTextColor(0.7, 0.7, 0.7)

    -- Sunder stacks
    local y = -80
    self:CreateSlider(content, "Boss Sunder Stacks", "SunderStacksBoss", 1, 5, 120, y, "",
        "Target Sunder Armor stacks to maintain on bosses. Full armor reduction requires 5 stacks. Default: 5")
    y = y - 70
    self:CreateSlider(content, "Trash Sunder Stacks", "SunderStacksTrash", 1, 5, 120, y, "",
        "Target Sunder Armor stacks on trash mobs. Lower stacks saves rage for AOE. Default: 3")

    -- Skip rend on trash (with more spacing to avoid tooltip overlap)
    y = y - 70
    self:CreateCheckbox(content, "Skip Rend on Trash", "SkipRendOnTrash", 120, y,
        "Skip Rend on Trash",
        "Don't apply Rend to trash mobs to save rage. Still applies Rend to bosses for full damage.")

    -- Info
    local info = content:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    info:SetPoint("BOTTOM", content, "BOTTOM", 0, 40)
    info:SetText("Boss detection: worldboss, skull level (-1), or elite + skull")
    info:SetTextColor(0.7, 0.7, 0.7)

    local info2 = content:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    info2:SetPoint("TOP", info, "BOTTOM", 0, -5)
    info2:SetText("Use /iwin status to see if current target is detected as boss")
    info2:SetTextColor(0.7, 0.7, 0.7)
end

-- Create Advanced tab (Tab 7)
function IWin.UI:CreateAdvancedTab()
    local content = self.tabs[7].content

    local title = content:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", content, "TOP", 0, -10)
    title:SetText("Advanced Settings")

    -- Left column sliders
    local y = -50
    self:CreateSlider(content, "Rotation Throttle", "RotationThrottle", 0.05, 1.0, 40, y, "s",
        "Controls how often the rotation checks for abilities. Lower = faster response but more CPU usage. Higher = less frequent checks but better performance. Default: 0.10s")
    y = y - 70
    self:CreateSlider(content, "Overpower Window", "OverpowerWindow", 1, 10, 40, y, "s",
        "Time window after a dodge to use Overpower. If target dodges, Overpower is available for this many seconds. Default: 5s")
    y = y - 70
    self:CreateSlider(content, "Revenge Window (SuperWOW)", "RevengeWindow", 1, 10, 40, y, "s",
        "Time window after dodge/parry/block to use Revenge. Requires SuperWOW for proc detection. Default: 5s")
    y = y - 70
    self:CreateSlider(content, "Sunder Stack Target", "SunderStacks", 1, 5, 40, y, "",
        "Target number of Sunder Armor stacks to maintain on the target. Rotation will keep stacking until this number is reached. Default: 5 stacks")

    -- Right column sliders
    y = -50
    self:CreateSlider(content, "Heroic Strike Queue Window", "HeroicStrikeQueueWindow", 0.1, 2.0, 260, y, "s",
        "Queue Heroic Strike/Cleave when this close to next swing. Requires SuperWOW swing timer. Lower = less rage waste. Default: 0.5s")
    y = y - 70
    self:CreateSlider(content, "AOE Target Threshold (SuperWOW)", "AOETargetThreshold", 2, 10, 260, y, "",
        "Minimum number of nearby enemies to trigger AOE abilities. Requires SuperWOW for enemy counting. Default: 3")

    -- Thunderfury toggle
    y = y - 70
    self:CreateCheckbox(content, "Skip Thunder Clap with Thunderfury", "SkipThunderClapWithThunderfury", 260, y,
        "Skip Thunder Clap",
        "When enabled, skips Thunder Clap if target has Thunderfury debuff (legendary weapon proc). Disable if you don't have Thunderfury.")

    -- Cache info (moved to bottom)
    local cacheLabel = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    cacheLabel:SetPoint("BOTTOM", content, "BOTTOM", -100, 30)
    cacheLabel:SetText("Spell Cache:")

    local cacheCount = content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    cacheCount:SetPoint("LEFT", cacheLabel, "RIGHT", 5, 0)
    local count = 0
    for _ in pairs(IWin_Settings.SpellCache or {}) do count = count + 1 end
    cacheCount:SetText(count .. " spells cached")

    -- Clear cache button
    local clearBtn = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
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
            DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00Spell and attack cache cleared|r")
        else
            DEFAULT_CHAT_FRAME:AddMessage("|cffff0000Error: IWin_Settings not found|r")
        end
    end)

    -- Tooltip for clear cache button
    clearBtn:SetScript("OnEnter", function()
        GameTooltip:SetOwner(this, "ANCHOR_TOP")
        GameTooltip:SetText("Clear Spell Cache", 1, 1, 1)
        GameTooltip:AddLine("Clears the addon's spell cache. Use this after learning new spells or if abilities aren't being detected properly. The cache will rebuild automatically.", 0.8, 0.8, 0.8, true)
        GameTooltip:Show()
    end)
    clearBtn:SetScript("OnLeave", function()
        GameTooltip:Hide()
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
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00IWin settings saved|r")
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
        GameTooltip:AddLine("Discard all changes and close the configuration window. Settings will revert to their values from when you opened the UI.", 0.8, 0.8, 0.8, true)
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
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00IWin settings applied|r")
    end)
    applyBtn:SetScript("OnEnter", function()
        GameTooltip:SetOwner(this, "ANCHOR_TOP")
        GameTooltip:SetText("Apply", 1, 1, 1)
        GameTooltip:AddLine("Save all changes without closing the configuration window. Changes take effect immediately.", 0.8, 0.8, 0.8, true)
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
        GameTooltip:AddLine("Reset ALL settings to their default values. This cannot be undone! The UI will reload to show the default values.", 0.8, 0.8, 0.8, true)
        GameTooltip:Show()
    end)
    resetBtn:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
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
    -- Error handling: validate IWin_Settings exists
    if not IWin_Settings or type(IWin_Settings) ~= "table" then
        DEFAULT_CHAT_FRAME:AddMessage("|cffff0000[IWin Error] Cannot show UI - IWin_Settings not initialized|r")
        return
    end

    -- Wrap in pcall for safety
    local success, err = pcall(function()
        if not self.frame then
            self:Initialize()
        end

        -- Validate frame was created
        if not self.frame then
            DEFAULT_CHAT_FRAME:AddMessage("|cffff0000[IWin Error] Failed to create UI frame|r")
            return
        end

        -- Restore window position if saved
        if IWin_Settings["UIPosition"] and type(IWin_Settings["UIPosition"]) == "table" then
            local pos = IWin_Settings["UIPosition"]
            -- Validate offsets are within screen bounds (simple check)
            local xOfs = pos.xOfs or 0
            local yOfs = pos.yOfs or 0
            local screenWidth = GetScreenWidth()
            local screenHeight = GetScreenHeight()

            -- Reset to center if position seems invalid
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

        -- Restore last viewed tab if saved
        if IWin_Settings["UILastTab"] and type(IWin_Settings["UILastTab"]) == "number" and IWin_Settings["UILastTab"] >= 1 and IWin_Settings["UILastTab"] <= 7 then
            self:SwitchTab(IWin_Settings["UILastTab"])
        end

        -- Refresh all controls to match current settings
        self:RefreshControls()

        -- Backup current settings
        self:BackupSettings()

        self.frame:Show()
    end)

    if not success then
        DEFAULT_CHAT_FRAME:AddMessage("|cffff0000[IWin Error] UI Show failed: " .. tostring(err) .. "|r")
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
    -- Error handling: validate IWin_Settings exists
    if not IWin_Settings or type(IWin_Settings) ~= "table" then
        DEFAULT_CHAT_FRAME:AddMessage("|cffff0000[IWin Error] Cannot backup settings - IWin_Settings not available|r")
        return
    end

    -- Wrap in pcall for safety
    local success, err = pcall(function()
        self.backup = {}
        for k, v in pairs(IWin_Settings) do
            if type(v) ~= "table" then
                self.backup[k] = v
            end
        end
    end)

    if not success then
        DEFAULT_CHAT_FRAME:AddMessage("|cffff0000[IWin Error] BackupSettings failed: " .. tostring(err) .. "|r")
        self.backup = {}
    end
end

-- Revert to backed up settings
function IWin.UI:RevertSettings()
    -- Error handling: validate backup and IWin_Settings exist
    if not self.backup or type(self.backup) ~= "table" then
        DEFAULT_CHAT_FRAME:AddMessage("|cffff0000[IWin Error] No backup to revert to|r")
        return
    end

    if not IWin_Settings or type(IWin_Settings) ~= "table" then
        DEFAULT_CHAT_FRAME:AddMessage("|cffff0000[IWin Error] Cannot revert settings - IWin_Settings not available|r")
        return
    end

    -- Wrap in pcall for safety
    local success, err = pcall(function()
        for k, v in pairs(self.backup) do
            IWin_Settings[k] = v
        end

        -- Refresh all controls to show reverted values
        self:RefreshControls()
    end)

    if not success then
        DEFAULT_CHAT_FRAME:AddMessage("|cffff0000[IWin Error] RevertSettings failed: " .. tostring(err) .. "|r")
    else
        DEFAULT_CHAT_FRAME:AddMessage("|cffff0000IWin settings reverted|r")
    end
end

-- Save settings (already saved live, just confirm)
function IWin.UI:SaveSettings()
    -- Settings are already saved in real-time
    -- This just clears the backup
    self.backup = {}
end

-- Reset all settings to defaults
function IWin.UI:ResetDefaults()
    -- Feature toggles
    IWin_Settings["AutoCharge"] = true
    IWin_Settings["AutoBattleShout"] = true
    IWin_Settings["AutoBloodrage"] = true
    IWin_Settings["AutoTrinkets"] = true
    IWin_Settings["AutoRend"] = true
    IWin_Settings["AutoAttack"] = true
    IWin_Settings["AutoStance"] = true
    IWin_Settings["AutoShieldBlock"] = true
    IWin_Settings["SkipThunderClapWithThunderfury"] = true
    IWin_Settings["BattleShoutAOEMode"] = true

    -- SuperWOW toggles
    IWin_Settings["AutoInterrupt"] = true
    IWin_Settings["SmartHeroicStrike"] = true
    IWin_Settings["AutoRevenge"] = true

    -- Rage thresholds (DPS)
    IWin_Settings["RageChargeMax"] = 50
    IWin_Settings["RageBloodrageMin"] = 30
    IWin_Settings["RageBloodthirstMin"] = 30
    IWin_Settings["RageMortalStrikeMin"] = 30
    IWin_Settings["RageWhirlwindMin"] = 25
    IWin_Settings["RageSweepingMin"] = 30
    IWin_Settings["RageHeroicMin"] = 30
    IWin_Settings["RageCleaveMin"] = 30
    IWin_Settings["RageShoutMin"] = 10
    IWin_Settings["RageShoutCombatMin"] = 30
    IWin_Settings["RageOverpowerMin"] = 5
    IWin_Settings["RageExecuteMin"] = 10
    IWin_Settings["RageRendMin"] = 10
    IWin_Settings["RageInterruptMin"] = 10

    -- Rage thresholds (Tank)
    IWin_Settings["RageShieldSlamMin"] = 20
    IWin_Settings["RageRevengeMin"] = 5
    IWin_Settings["RageThunderClapMin"] = 20
    IWin_Settings["RageDemoShoutMin"] = 10
    IWin_Settings["RageSunderMin"] = 15
    IWin_Settings["RageConcussionBlowMin"] = 15
    IWin_Settings["RageShieldBlockMin"] = 10

    -- Health thresholds
    IWin_Settings["LastStandThreshold"] = 20
    IWin_Settings["ConcussionBlowThreshold"] = 30

    -- Boss detection
    IWin_Settings["SunderStacksBoss"] = 5
    IWin_Settings["SunderStacksTrash"] = 3
    IWin_Settings["SkipRendOnTrash"] = true

    -- Debuff refresh timings
    IWin_Settings["RefreshRend"] = 5
    IWin_Settings["RefreshSunder"] = 5
    IWin_Settings["RefreshThunderClap"] = 5
    IWin_Settings["RefreshDemoShout"] = 3

    -- Advanced
    IWin_Settings["RotationThrottle"] = 0.1
    IWin_Settings["OverpowerWindow"] = 5
    IWin_Settings["RevengeWindow"] = 5
    IWin_Settings["SunderStacks"] = 5
    IWin_Settings["HeroicStrikeQueueWindow"] = 0.5
    IWin_Settings["AOETargetThreshold"] = 3

    -- Refresh all controls to show default values
    self:RefreshControls()

    -- Update backup to match defaults
    self:BackupSettings()

    DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00IWin settings reset to defaults|r")
end

-- Refresh all UI controls to match current IWin_Settings values
function IWin.UI:RefreshControls()
    if not self.frame then return end
    if not IWin_Settings or type(IWin_Settings) ~= "table" then
        DEFAULT_CHAT_FRAME:AddMessage("|cffff0000Error: Cannot refresh UI - IWin_Settings not available|r")
        return
    end

    -- Refresh all stored controls
    for _, control in ipairs(self.controls) do
        local controlType = control:GetObjectType()

        if controlType == "CheckButton" then
            -- Extract setting key from control name
            local name = control:GetName()
            if name then
                local settingKey = string.gsub(name, "IWinCheck_", "")
                if IWin_Settings[settingKey] ~= nil then
                    control:SetChecked(IWin_Settings[settingKey])
                end
            end
        elseif controlType == "Slider" then
            -- Extract setting key from control name
            local name = control:GetName()
            if name then
                local settingKey = string.gsub(name, "IWinSlider_", "")
                if IWin_Settings[settingKey] ~= nil then
                    control:SetValue(IWin_Settings[settingKey])
                    -- This will trigger OnValueChanged which updates the editbox
                end
            end
        end
    end

    -- Refresh cache count display (Advanced tab is tab 7 now)
    if self.tabs[7] and self.tabs[7].content then
        local children = { self.tabs[7].content:GetChildren() }
        for _, child in ipairs(children) do
            if child and child:GetObjectType() == "FontString" then
                local text = child:GetText()
                if text and string.find(text, "spells cached") then
                    local count = 0
                    for _ in pairs(IWin_Settings.SpellCache or {}) do count = count + 1 end
                    child:SetText(count .. " spells cached")
                    break
                end
            end
        end
    end
end
