--[[
#######################################
# IWin by Atreyyo @ VanillaGaming.org #
# Forked by Bear-LB @ github.com #
#######################################
]]
--
IWin = IWin or {}

-- Logging system with levels
IWin.LOG_LEVELS = {
    ERROR = 1,
    WARN = 2,
    INFO = 3,
    DEBUG = 4
}

-- Constants: Ability durations and limits
IWin.CONSTANTS = {
    -- Debuff/Buff durations (in seconds)
    REND_DURATION = 21,
    SUNDER_ARMOR_DURATION = 30,
    THUNDER_CLAP_DURATION = 26,
    DEMO_SHOUT_DURATION = 30,
    BATTLE_SHOUT_DURATION = 120,

    -- Safety limits
    MAX_BUFF_SCAN_ITERATIONS = 40,
    MAX_SPELL_SCAN_ITERATIONS = 500,
    MAX_ACTION_SLOTS = 100,

    -- GCD threshold (abilities with cooldown <= this are considered "no cooldown")
    GCD_THRESHOLD = 1.5,

    -- Rage limits
    MAX_RAGE = 100,
    MIN_RAGE = 0,

    -- Stance indices
    BATTLE_STANCE = 1,
    DEFENSIVE_STANCE = 2,
    BERSERKER_STANCE = 3,

    -- Cache settings
    BUFF_CACHE_DURATION = 0.1, -- Cache buff results for 100ms
    DEBUFF_CACHE_DURATION = 0.1, -- Cache debuff results for 100ms
    MAX_DEBUFF_TRACKER_SIZE = 100, -- Maximum entries in DebuffTracker before cleanup

    -- Throttle settings
    REACTIVE_THROTTLE = 0.05, -- 50ms throttle for reactive abilities (Revenge, Overpower)
    INTERRUPT_THROTTLE = 0.05, -- 50ms throttle for interrupts

    -- Combat timing constants
    INTERRUPT_WINDOW_MIN = 0.3, -- Minimum time remaining to interrupt (seconds)
    INTERRUPT_WINDOW_MAX = 5.0, -- Maximum time remaining to interrupt (seconds)
    CHARGE_RANGE_MIN = 8, -- Minimum range for charge (yards)
    CHARGE_RANGE_MAX = 25, -- Maximum range for charge (yards)
    INTERACT_DISTANCE_MELEE = 1, -- Melee range check distance index
}

IWinFrame = CreateFrame("frame", nil, UIParent)
IWinFrame.t = CreateFrame("GameTooltip", "IWinFrame_T", UIParent, "GameTooltipTemplate")

-- Initialize SavedVariables with defaults (don't overwrite existing saved data)
if not IWin_Settings then
    IWin_Settings = {}
end
if not IWin_Settings["dodge"] then
    IWin_Settings["dodge"] = 0
end
if not IWin_Settings["DebuffTracker"] then
    IWin_Settings["DebuffTracker"] = {}
end
if not IWin_Settings["SpellCache"] then
    IWin_Settings["SpellCache"] = {}
end
if not IWin_Settings["SpellIDCache"] then
    IWin_Settings["SpellIDCache"] = {}
end
if not IWin_Settings["ActionSlotCache"] then
    IWin_Settings["ActionSlotCache"] = {}
end
if not IWin_Settings["LogLevel"] then
    IWin_Settings["LogLevel"] = IWin.LOG_LEVELS.INFO  -- Default to INFO
end
if not IWin_Settings["BuffCache"] then
    IWin_Settings["BuffCache"] = {}
end
if not IWin_Settings["DebuffCache"] then
    IWin_Settings["DebuffCache"] = {}
end
if not IWin_Settings["LastRotationTime"] then
    IWin_Settings["LastRotationTime"] = 0
end
if not IWin_Settings["LastReactiveTime"] then
    IWin_Settings["LastReactiveTime"] = 0
end
if not IWin_Settings["LastInterruptTime"] then
    IWin_Settings["LastInterruptTime"] = 0
end
if not IWin_Settings["revengeProc"] then
    IWin_Settings["revengeProc"] = 0
end
if not IWin_Settings["RevengeSlot"] then
    IWin_Settings["RevengeSlot"] = nil
end
if not IWin_Settings["lastSwingTime"] then
    IWin_Settings["lastSwingTime"] = 0
end
if not IWin_Settings["swingTimer"] then
    IWin_Settings["swingTimer"] = 0
end
if not IWin_Settings["targetCasting"] then
    IWin_Settings["targetCasting"] = {
        isCasting = false,
        spellName = nil,
        castEndTime = 0,
        isChanneling = false
    }
end

IWinFrame:RegisterEvent("CHAT_MSG_COMBAT_SELF_MISSES")
IWinFrame:RegisterEvent("CHAT_MSG_SPELL_DAMAGESHIELDS_ON_SELF")
IWinFrame:RegisterEvent("ADDON_LOADED")
IWinFrame:RegisterEvent("SPELLS_CHANGED")
IWinFrame:RegisterEvent("LEARNED_SPELL_IN_TAB")

-- Detect SuperWOW (check SUPERWOW_VERSION global first, then fallbacks)
IWin.superwow = false

if not IWin.superwow then
    if SUPERWOW_VERSION then
        -- SuperWOW is detected - create a proper API wrapper
        IWin.superwow = {
            detected = true,
            version = SUPERWOW_VERSION,
            GetUnitBuff = GetUnitBuff,
            GetUnitDebuff = GetUnitDebuff,
            GetDistanceToUnit = GetDistanceToUnit,
            UnitPosition = UnitPosition,
            SpellInfo = SpellInfo
        }
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[IWin] SuperWOW " .. SUPERWOW_VERSION .. " detected|r")
    elseif SuperWoWHook then
        IWin.superwow = SuperWoWHook
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[IWin] SuperWoWHook detected - using compatibility layer|r")
    elseif SuperAPI then
        IWin.superwow = SuperAPI
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[IWin] SuperAPI detected - using compatibility layer|r")
    elseif GetUnitBuff then
        -- Vanilla client with extended API (partial SuperWOW support)
        IWin.superwow = {
            detected = true,
            GetUnitBuff = GetUnitBuff,
            GetUnitDebuff = GetUnitDebuff
        }
        DEFAULT_CHAT_FRAME:AddMessage("|cffff8800[IWin] Extended API detected - partial SuperWOW support|r")
    end
end

-- SuperWOW enhanced event registration
if IWin.superwow then
    IWinFrame:RegisterEvent("UNIT_CASTEVENT")  -- For swing timer tracking
    IWinFrame:RegisterEvent("CHAT_MSG_COMBAT_SELF_MISSES")  -- For dodge/parry detection (enemy misses YOU)
    IWinFrame:RegisterEvent("CHAT_MSG_COMBAT_CREATURE_VS_SELF_DAMAGE")  -- For block detection
    DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[IWin] SuperWOW features enabled|r")
else
    DEFAULT_CHAT_FRAME:AddMessage("|cffff8800[IWin] Running in vanilla mode (no SuperWOW)|r")
end
-- Validate and clamp a numeric setting to a range
function IWin:ValidateSetting(key, value, min, max, default)
    if type(value) ~= "number" or value < min or value > max then
        return default
    end
    return value
end

-- Initialize or validate a setting with default value
function IWin:InitSetting(key, default, min, max)
    if IWin_Settings[key] == nil then
        IWin_Settings[key] = default
    elseif type(default) == "boolean" then
        -- Validate boolean settings
        if type(IWin_Settings[key]) ~= "boolean" then
            IWin_Settings[key] = default
        end
    elseif min and max then
        IWin_Settings[key] = IWin:ValidateSetting(key, IWin_Settings[key], min, max, default)
    end
end

IWinFrame:SetScript("OnEvent", function()
    -- Wrap event logic in pcall for error protection
    local success, err = pcall(function()
        if event == "ADDON_LOADED" and arg1 == "IWin" then
        -- Initialize trinket slots
        IWin:InitSetting("Trinket0Slot", 13)
        IWin:InitSetting("Trinket1Slot", 14)

        -- Feature toggles (boolean settings)
        IWin:InitSetting("AutoCharge", true)
        IWin:InitSetting("AutoBattleShout", true)
        IWin:InitSetting("AutoBloodrage", true)
        IWin:InitSetting("AutoTrinkets", true)
        IWin:InitSetting("AutoRend", true)
        IWin:InitSetting("AutoAttack", true)
        IWin:InitSetting("AutoStance", true)
        IWin:InitSetting("AutoShieldBlock", true)
        IWin:InitSetting("SkipThunderClapWithThunderfury", true)
        IWin:InitSetting("BattleShoutAOEMode", true)

        -- SuperWOW feature toggles - enable by default if SuperWOW detected
        local superWOWDefault = IWin.superwow and true or false
        IWin:InitSetting("AutoInterrupt", superWOWDefault)
        IWin:InitSetting("SmartHeroicStrike", superWOWDefault)
        -- Auto-Revenge works in vanilla using IsUsableAction - enable by default
        IWin:InitSetting("AutoRevenge", true)

        -- Rage thresholds (0-100)
        IWin:InitSetting("RageChargeMax", 50, 0, 100)
        IWin:InitSetting("RageBloodrageMin", 30, 0, 100)
        IWin:InitSetting("RageBloodthirstMin", 30, 0, 100)
        IWin:InitSetting("RageMortalStrikeMin", 30, 0, 100)
        IWin:InitSetting("RageWhirlwindMin", 25, 0, 100)
        IWin:InitSetting("RageSweepingMin", 30, 0, 100)
        IWin:InitSetting("RageHeroicMin", 30, 0, 100)
        IWin:InitSetting("RageCleaveMin", 30, 0, 100)
        IWin:InitSetting("RageShoutMin", 10, 0, 100)
        IWin:InitSetting("RageExecuteMin", 10, 0, 100)
        IWin:InitSetting("RageRendMin", 10, 0, 100)
        IWin:InitSetting("RageShieldSlamMin", 20, 0, 100)
        IWin:InitSetting("RageRevengeMin", 5, 0, 100)
        IWin:InitSetting("RageThunderClapMin", 20, 0, 100)
        IWin:InitSetting("RageDemoShoutMin", 10, 0, 100)
        IWin:InitSetting("RageSunderMin", 15, 0, 100)
        IWin:InitSetting("RageConcussionBlowMin", 15, 0, 100)
        IWin:InitSetting("RageShieldBlockMin", 10, 0, 100)
        IWin:InitSetting("RageShoutCombatMin", 30, 0, 100)
        IWin:InitSetting("RageOverpowerMin", 5, 0, 100)
        IWin:InitSetting("RageInterruptMin", 10, 0, 100)

        -- Health thresholds (1-99)
        IWin:InitSetting("LastStandThreshold", 20, 1, 99)
        IWin:InitSetting("ConcussionBlowThreshold", 30, 1, 99)

        -- Boss detection specific thresholds
        IWin:InitSetting("SunderStacksBoss", 5, 1, 5)
        IWin:InitSetting("SunderStacksTrash", 3, 1, 5)
        IWin:InitSetting("SkipRendOnTrash", true)

        -- Debuff refresh timings
        IWin:InitSetting("RefreshRend", 5, 1, 20)
        IWin:InitSetting("RefreshSunder", 5, 1, 29)
        IWin:InitSetting("RefreshThunderClap", 5, 1, 25)
        IWin:InitSetting("RefreshDemoShout", 3, 1, 29)

        -- Other configs
        IWin:InitSetting("RotationThrottle", 0.1, 0.05, 1.0)
        IWin:InitSetting("OverpowerWindow", 5, 1, 10)
        IWin:InitSetting("RevengeWindow", 5, 1, 10)
        IWin:InitSetting("SunderStacks", 5, 1, 5)
        IWin:InitSetting("HeroicStrikeQueueWindow", 0.5, 0.1, 2.0)
        IWin:InitSetting("AOETargetThreshold", 3, 2, 10)  -- Min enemies for AOE abilities
        DEFAULT_CHAT_FRAME:AddMessage("|cff0066ff========================================|r")
        DEFAULT_CHAT_FRAME:AddMessage("|cff0066ff IWin v2.6.0 loaded successfully!|r")
        DEFAULT_CHAT_FRAME:AddMessage("|cffff8800 Client:|r " .. (IWin.superwow and "|cff00ff00SuperWOW Enhanced|r" or "|cffff8800Vanilla|r"))
        DEFAULT_CHAT_FRAME:AddMessage("|cffff8800 Rotations:|r |cffffffff/dmgst, /dmgaoe, /tankst, /tankaoe|r")
        DEFAULT_CHAT_FRAME:AddMessage("|cffff8800 Commands:|r |cffffffff/iwin, /iwinhelp|r")
        DEFAULT_CHAT_FRAME:AddMessage("|cff0066ff========================================|r")
        IWinFrame:UnregisterEvent("ADDON_LOADED")
    elseif event == "CHAT_MSG_COMBAT_SELF_MISSES" then
        -- Combat log for dodge/parry detection (enemy misses YOU)
        -- Examples: "Mob's attack misses you.", "Mob's attack was dodged.", "Mob's attack was parried."
        if string.find(arg1, "dodge") then
            IWin_Settings["dodge"] = GetTime()
            if IWin.superwow then
                IWin_Settings["revengeProc"] = GetTime()
            end
        elseif string.find(arg1, "parr") then  -- "parries" or "parry"
            if IWin.superwow then
                IWin_Settings["revengeProc"] = GetTime()
            end
        end
    elseif event == "CHAT_MSG_SPELL_DAMAGESHIELDS_ON_SELF" then
        -- Fallback dodge detection for vanilla clients (kept for compatibility)
        if string.find(arg1, "dodge") then
            IWin_Settings["dodge"] = GetTime()
        end
    elseif event == "UNIT_CASTEVENT" and IWin.superwow then
        -- SuperWOW UNIT_CASTEVENT: tracks spell casts and weapon swings
        -- arg1 = caster GUID, arg2 = target unit, arg3 = event type, arg4 = spell ID, arg5 = cast duration
        local casterGUID = arg1
        local targetUnit = arg2
        local eventType = arg3
        local spellID = arg4
        local castDuration = arg5

        -- Player swing timer tracking (MAINHAND/OFFHAND events)
        if eventType == "MAINHAND" or eventType == "OFFHAND" then
            IWin_Settings["lastSwingTime"] = GetTime()
            -- Get weapon speed
            local speed, offhandSpeed = UnitAttackSpeed("player")
            if speed then
                IWin_Settings["swingTimer"] = speed
            end
        end

        -- Target casting detection for interrupts
        if UnitExists("target") then
            local _, targetGUID = UnitExists("target")

            -- Only track casts from our current target
            if casterGUID == targetGUID then
                if eventType == "START" then
                    local spellName, spellRank = IWin.superwow.SpellInfo(spellID)
                    IWin_Settings["targetCasting"].isCasting = true
                    IWin_Settings["targetCasting"].isChanneling = false
                    IWin_Settings["targetCasting"].spellName = spellName
                    IWin_Settings["targetCasting"].castEndTime = GetTime() + ((castDuration or 0) / 1000)
                elseif eventType == "CHANNEL" then
                    local spellName, spellRank = IWin.superwow.SpellInfo(spellID)
                    IWin_Settings["targetCasting"].isCasting = false
                    IWin_Settings["targetCasting"].isChanneling = true
                    IWin_Settings["targetCasting"].spellName = spellName
                    IWin_Settings["targetCasting"].castEndTime = GetTime() + ((castDuration or 0) / 1000)
                elseif eventType == "CAST" or eventType == "FAIL" then
                    IWin_Settings["targetCasting"].isCasting = false
                    IWin_Settings["targetCasting"].isChanneling = false
                    IWin_Settings["targetCasting"].spellName = nil
                end
            end
        end
        elseif event == "SPELLS_CHANGED" or event == "LEARNED_SPELL_IN_TAB" then
            -- Clear spell cache when spells change (learning new ranks, talents, etc.)
            if IWin_Settings and IWin_Settings.SpellCache then
                IWin_Settings.SpellCache = {}
            end
            if IWin_Settings and IWin_Settings.SpellIDCache then
                IWin_Settings.SpellIDCache = {}
            end
            -- Also clear action slot caches since abilities may move
            if IWin_Settings and IWin_Settings.ActionSlotCache then
                IWin_Settings.ActionSlotCache = {}
            end
            IWin_Settings["AttackSlot"] = nil
            IWin_Settings["RevengeSlot"] = nil
            IWin:Log(IWin.LOG_LEVELS.INFO, "Spell cache cleared (spells changed)")
        elseif event == "CHAT_MSG_COMBAT_CREATURE_VS_SELF_DAMAGE" and IWin.superwow then
            -- Combat log for block detection
            -- Example: "Mob's attack is blocked."
            if string.find(arg1, "block") then
                IWin_Settings["revengeProc"] = GetTime()
                DEFAULT_CHAT_FRAME:AddMessage("|cffff8800[Revenge Proc]|r BLOCK")
            end
        end
    end)

    -- Log errors if event handling fails
    if not success then
        DEFAULT_CHAT_FRAME:AddMessage("|cffff0000[IWin Error] Event handler failed: " .. tostring(err) .. "|r")
    end
end)

-- Logging function with level support
function IWin:Log(level, message)
    if not IWin_Settings or not IWin_Settings.LogLevel then
        return
    end

    -- Only log if message level is at or below configured level
    if level > IWin_Settings.LogLevel then
        return
    end

    local prefix = ""
    local color = "|cffffffff"  -- White default

    if level == IWin.LOG_LEVELS.ERROR then
        prefix = "[IWin Error]"
        color = "|cffff0000"  -- Red
    elseif level == IWin.LOG_LEVELS.WARN then
        prefix = "[IWin Warning]"
        color = "|cffff8800"  -- Orange
    elseif level == IWin.LOG_LEVELS.INFO then
        prefix = "[IWin]"
        color = "|cff00ff00"  -- Green
    elseif level == IWin.LOG_LEVELS.DEBUG then
        prefix = "[IWin Debug]"
        color = "|cff888888"  -- Gray
    end

    DEFAULT_CHAT_FRAME:AddMessage(color .. prefix .. "|r " .. message)
end

-- Enhanced buff checking with SuperWOW support and vanilla fallback
-- Returns: false if not found, true if found (stacks=nil), or stack count (stacks=1)
function IWin:GetBuff(unit, buffName, returnStacks)
    -- Error handling: validate inputs
    if not unit or type(unit) ~= "string" or unit == "" then
        return false
    end
    if not buffName or type(buffName) ~= "string" or buffName == "" then
        return false
    end

    -- Validate unit exists before checking buffs
    if not UnitExists(unit) then
        return false
    end

    -- Ensure BuffCache is initialized
    if not IWin_Settings.BuffCache then
        IWin_Settings.BuffCache = {}
    end

    -- Check cache first
    local cacheKey = unit .. ":" .. buffName .. ":" .. tostring(returnStacks or 0)
    local currentTime = GetTime()
    local cached = IWin_Settings.BuffCache[cacheKey]

    if cached and (currentTime - cached.timestamp) < IWin.CONSTANTS.BUFF_CACHE_DURATION then
        return cached.result
    end

    local result = false

    -- SuperWOW Enhanced API (if available)
    if IWin.superwow and IWin.superwow.GetUnitBuff then
        local success, scanResult = pcall(function()
            local i = 1
            while true do
                local name, rank, icon, count, debuffType, duration, expirationTime = IWin.superwow.GetUnitBuff(unit, i)
                if not name then break end

                if name == buffName then
                    if returnStacks == 1 then
                        return count or 0
                    else
                        return true
                    end
                end

                i = i + 1
                if i > IWin.CONSTANTS.MAX_BUFF_SCAN_ITERATIONS then break end
            end
            return false
        end)

        if success then
            result = scanResult
        else
            -- Fall through to tooltip method if SuperWOW method fails
            result = IWin:GetBuffTooltip(unit, buffName, returnStacks)
        end
    else
        -- Vanilla tooltip scanning fallback
        result = IWin:GetBuffTooltip(unit, buffName, returnStacks)
    end

    -- Cache the result
    IWin_Settings.BuffCache[cacheKey] = {
        result = result,
        timestamp = currentTime
    }

    return result
end

-- Tooltip scanning method for buff checking (vanilla fallback)
-- NOTE: Vanilla 1.12 UnitBuff() returns (texture, stacks), not (name, stacks).
-- Tooltip scanning is the ONLY reliable way to get buff names in vanilla.
function IWin:GetBuffTooltip(name, buff, stacks)
    -- Error handling: validate inputs
    if not name or type(name) ~= "string" or name == "" then
        return false
    end
    if not buff or type(buff) ~= "string" or buff == "" then
        return false
    end

    -- Validate unit exists before checking buffs
    if not UnitExists(name) then
        return false
    end

    -- Validate tooltip frame exists
    if not IWinFrame_T or not IWinFrame_TTextLeft1 then
        DEFAULT_CHAT_FRAME:AddMessage("|cffff0000[IWin Error] Tooltip frame not initialized|r")
        return false
    end

    -- Wrap in pcall for safety
    local success, result = pcall(function()
        -- Tooltip scanning (vanilla 1.12 method) - buffs only
        local a = 1
        while UnitBuff(name, a) do
            local _, s = UnitBuff(name, a)
            IWinFrame_T:SetOwner(WorldFrame, "ANCHOR_NONE")
            IWinFrame_T:ClearLines()
            IWinFrame_T:SetUnitBuff(name, a)
            local text = IWinFrame_TTextLeft1:GetText()
            if text and text == buff then
                if stacks == 1 then
                    return s or 0
                else
                    return true
                end
            end
            a = a + 1
            -- Safety limit to prevent infinite loops
            if a > IWin.CONSTANTS.MAX_BUFF_SCAN_ITERATIONS then break end
        end
        return false
    end)

    if not success then
        DEFAULT_CHAT_FRAME:AddMessage("|cffff0000[IWin Error] GetBuffTooltip failed: " .. tostring(result) .. "|r")
        return false
    end

    return result
end

-- Enhanced debuff checking with SuperWOW support and vanilla fallback
-- Returns: false if not found, true if found (stacks=nil), or stack count (stacks=1)
function IWin:GetDebuff(unit, debuffName, returnStacks)
    -- Error handling: validate inputs
    if not unit or type(unit) ~= "string" or unit == "" then
        return false
    end
    if not debuffName or type(debuffName) ~= "string" or debuffName == "" then
        return false
    end

    -- Validate unit exists before checking debuffs
    if not UnitExists(unit) then
        return false
    end

    -- Ensure DebuffCache is initialized
    if not IWin_Settings.DebuffCache then
        IWin_Settings.DebuffCache = {}
    end

    -- Check cache first
    local cacheKey = unit .. ":" .. debuffName .. ":" .. tostring(returnStacks or 0)
    local currentTime = GetTime()
    local cached = IWin_Settings.DebuffCache[cacheKey]

    if cached and (currentTime - cached.timestamp) < IWin.CONSTANTS.DEBUFF_CACHE_DURATION then
        return cached.result
    end

    local result = false

    -- SuperWOW Enhanced API (if available)
    if IWin.superwow and IWin.superwow.GetUnitDebuff then
        local success, scanResult = pcall(function()
            local i = 1
            while true do
                local name, rank, icon, count, debuffType, duration, expirationTime = IWin.superwow.GetUnitDebuff(unit, i)
                if not name then break end

                if name == debuffName then
                    if returnStacks == 1 then
                        return count or 0
                    else
                        return true
                    end
                end

                i = i + 1
                if i > IWin.CONSTANTS.MAX_BUFF_SCAN_ITERATIONS then break end
            end
            return false
        end)

        if success then
            result = scanResult
        else
            -- Fall through to tooltip method if SuperWOW method fails
            result = IWin:GetDebuffTooltip(unit, debuffName, returnStacks)
        end
    else
        -- Vanilla tooltip scanning fallback
        result = IWin:GetDebuffTooltip(unit, debuffName, returnStacks)
    end

    -- Cache the result
    IWin_Settings.DebuffCache[cacheKey] = {
        result = result,
        timestamp = currentTime
    }

    return result
end

-- Tooltip scanning method for debuff checking (vanilla fallback)
function IWin:GetDebuffTooltip(name, debuff, stacks)
    -- Error handling: validate inputs
    if not name or type(name) ~= "string" or name == "" then
        return false
    end
    if not debuff or type(debuff) ~= "string" or debuff == "" then
        return false
    end

    -- Validate unit exists before checking debuffs
    if not UnitExists(name) then
        return false
    end

    -- Validate tooltip frame exists
    if not IWinFrame_T or not IWinFrame_TTextLeft1 then
        DEFAULT_CHAT_FRAME:AddMessage("|cffff0000[IWin Error] Tooltip frame not initialized|r")
        return false
    end

    -- Wrap in pcall for safety
    local success, result = pcall(function()
        -- Tooltip scanning (vanilla 1.12 method) - debuffs only
        local a = 1
        while UnitDebuff(name, a) do
            local _, s = UnitDebuff(name, a)
            IWinFrame_T:SetOwner(WorldFrame, "ANCHOR_NONE")
            IWinFrame_T:ClearLines()
            IWinFrame_T:SetUnitDebuff(name, a)
            local text = IWinFrame_TTextLeft1:GetText()
            if text and text == debuff then
                if stacks == 1 then
                    return s or 0
                else
                    return true
                end
            end
            a = a + 1
            -- Safety limit to prevent infinite loops
            if a > IWin.CONSTANTS.MAX_BUFF_SCAN_ITERATIONS then break end
        end
        return false
    end)

    if not success then
        DEFAULT_CHAT_FRAME:AddMessage("|cffff0000[IWin Error] GetDebuffTooltip failed: " .. tostring(result) .. "|r")
        return false
    end

    return result
end

-- Cleanup expired entries from DebuffTracker to prevent memory growth
function IWin:CleanupDebuffTracker()
    if not IWin_Settings or not IWin_Settings.DebuffTracker then
        return
    end

    local currentTime = GetTime()
    local expiredDebuffs = {}

    -- Find expired debuffs
    for debuff, data in pairs(IWin_Settings.DebuffTracker) do
        if type(data) == "table" and data.startTime and data.duration then
            local timeElapsed = currentTime - data.startTime
            if timeElapsed > data.duration then
                table.insert(expiredDebuffs, debuff)
            end
        else
            -- Corrupted entry, mark for removal
            table.insert(expiredDebuffs, debuff)
        end
    end

    -- Remove expired debuffs
    for _, debuff in ipairs(expiredDebuffs) do
        IWin_Settings.DebuffTracker[debuff] = nil
    end

    -- If tracker is still too large, remove oldest entries
    local trackerSize = 0
    for _ in pairs(IWin_Settings.DebuffTracker) do
        trackerSize = trackerSize + 1
    end

    if trackerSize > IWin.CONSTANTS.MAX_DEBUFF_TRACKER_SIZE then
        -- Build list of entries with timestamps
        local entries = {}
        for debuff, data in pairs(IWin_Settings.DebuffTracker) do
            if type(data) == "table" and data.startTime then
                table.insert(entries, {debuff = debuff, startTime = data.startTime})
            end
        end

        -- Sort by startTime (oldest first)
        table.sort(entries, function(a, b) return a.startTime < b.startTime end)

        -- Remove oldest entries until we're under the limit
        local toRemove = trackerSize - IWin.CONSTANTS.MAX_DEBUFF_TRACKER_SIZE
        for i = 1, toRemove do
            if entries[i] then
                IWin_Settings.DebuffTracker[entries[i].debuff] = nil
            end
        end
    end
end

function IWin:CheckDebuffDuration(debuff, duration, recastThreshold)
    -- Validate IWin_Settings exists first
    if not IWin_Settings or type(IWin_Settings) ~= "table" then
        return true
    end
    if not IWin_Settings.DebuffTracker or type(IWin_Settings.DebuffTracker) ~= "table" then
        return true
    end

    -- Periodically cleanup tracker (every ~100 calls, randomly to avoid performance spikes)
    if math.random(1, 100) == 1 then
        IWin:CleanupDebuffTracker()
    end

    if IWin_Settings.DebuffTracker[debuff] then
        -- Validate tracker structure
        if type(IWin_Settings.DebuffTracker[debuff]) ~= "table" or
           not IWin_Settings.DebuffTracker[debuff].startTime or
           not IWin_Settings.DebuffTracker[debuff].duration then
            -- Corrupted tracker data, clear it and trigger recast
            IWin_Settings.DebuffTracker[debuff] = nil
            return true
        end

        local currentTime = GetTime()
        local timeElapsed = currentTime - IWin_Settings.DebuffTracker[debuff].startTime
        local timeLeft = IWin_Settings.DebuffTracker[debuff].duration - timeElapsed
        if timeLeft > 0 then
            IWin:Log(IWin.LOG_LEVELS.DEBUG, string.format("%s has %.1f seconds remaining", debuff, timeLeft))
            if timeLeft < recastThreshold then
                return true -- Less than recastThreshold seconds remain
            end
        else
            IWin:Log(IWin.LOG_LEVELS.DEBUG, debuff .. " has expired")
            IWin_Settings.DebuffTracker[debuff] = nil -- Clear expired debuff
            return true                               -- Treat as not found for recast
        end
        return false                                  -- Debuff is present with >= recastThreshold seconds remaining
    else
        IWin:Log(IWin.LOG_LEVELS.DEBUG, debuff .. " not tracked (not applied)")
        return true -- Debuff not applied, trigger recast
    end
end

function IWin:GetActionSlot(a)
    -- Error handling: validate input
    if not a or type(a) ~= "string" or a == "" then
        DEFAULT_CHAT_FRAME:AddMessage("|cffff0000[IWin Error] GetActionSlot called with invalid action name|r")
        return nil
    end

    -- Check cache first
    if IWin_Settings and IWin_Settings.ActionSlotCache and IWin_Settings.ActionSlotCache[a] then
        return IWin_Settings.ActionSlotCache[a]
    end

    -- Validate tooltip frame exists
    if not IWinFrame_T or not IWinFrame_TTextLeft1 then
        DEFAULT_CHAT_FRAME:AddMessage("|cffff0000[IWin Error] Tooltip frame not initialized|r")
        return nil
    end

    -- Wrap in pcall for safety
    local success, result = pcall(function()
        for i = 1, IWin.CONSTANTS.MAX_ACTION_SLOTS do
            IWinFrame_T:SetOwner(UIParent, "ANCHOR_NONE")
            IWinFrame_T:ClearLines()
            IWinFrame_T:SetAction(i)
            local ab = IWinFrame_TTextLeft1:GetText()
            IWinFrame_T:Hide()
            if ab and ab == a then
                return i
            end
        end
        return nil
    end)

    if not success then
        DEFAULT_CHAT_FRAME:AddMessage("|cffff0000[IWin Error] GetActionSlot failed: " .. tostring(result) .. "|r")
        return nil
    end

    if not result then
        DEFAULT_CHAT_FRAME:AddMessage("|cffff0000IWin: Could not find '" .. a .. "' on action bars. Auto-attack disabled.|r")
    else
        -- Cache the result for future lookups
        if IWin_Settings and IWin_Settings.ActionSlotCache then
            IWin_Settings.ActionSlotCache[a] = result
        end
    end

    return result
end

function IWin:OnCooldown(Spell)
    -- Error handling: validate input
    if not Spell or type(Spell) ~= "string" or Spell == "" then
        return true
    end

    -- Validate IWin_Settings exists
    if not IWin_Settings or type(IWin_Settings) ~= "table" or not IWin_Settings.SpellIDCache then
        DEFAULT_CHAT_FRAME:AddMessage("|cffff0000[IWin Error] IWin_Settings not initialized|r")
        return true
    end

    -- Wrap in pcall for safety
    local success, result = pcall(function()
        -- Check cache first
        if IWin_Settings.SpellIDCache[Spell] then
            local spellID = IWin_Settings.SpellIDCache[Spell]
            local startTime, duration = GetSpellCooldown(spellID, "BOOKTYPE_SPELL")

            -- Validate return values
            if not duration then
                return true
            end

            -- Duration <= GCD_THRESHOLD means it's just the GCD, not a real cooldown
            -- Treat GCD as "not on cooldown" so abilities can be used
            if duration == 0 or duration <= IWin.CONSTANTS.GCD_THRESHOLD then
                return false
            else
                return true
            end
        end

        -- Cache miss - scan spellbook
        local spellID = 1
        local spell = GetSpellName(spellID, "BOOKTYPE_SPELL")
        local iterations = 0
        while spell do
            if Spell == spell then
                IWin_Settings.SpellIDCache[Spell] = spellID -- Cache the ID
                local startTime, duration = GetSpellCooldown(spellID, "BOOKTYPE_SPELL")

                -- Validate return values
                if not duration then
                    return true
                end

                -- Duration <= GCD_THRESHOLD means it's just the GCD, not a real cooldown
                if duration == 0 or duration <= IWin.CONSTANTS.GCD_THRESHOLD then
                    return false
                else
                    return true
                end
            end
            spellID = spellID + 1
            spell = GetSpellName(spellID, "BOOKTYPE_SPELL")

            -- Safety limit to prevent infinite loops
            iterations = iterations + 1
            if iterations > IWin.CONSTANTS.MAX_SPELL_SCAN_ITERATIONS then
                DEFAULT_CHAT_FRAME:AddMessage("|cffff0000[IWin Error] OnCooldown exceeded iteration limit|r")
                break
            end
        end

        return true -- Spell not found
    end)

    if not success then
        DEFAULT_CHAT_FRAME:AddMessage("|cffff0000[IWin Error] OnCooldown failed: " .. tostring(result) .. "|r")
        return true
    end

    return result
end

function IWin:GetSpell(name)
    -- Error handling: validate input
    if not name or type(name) ~= "string" or name == "" then
        return false
    end

    -- Validate IWin_Settings exists
    if not IWin_Settings or type(IWin_Settings) ~= "table" or not IWin_Settings.SpellCache or not IWin_Settings.SpellIDCache then
        DEFAULT_CHAT_FRAME:AddMessage("|cffff0000[IWin Error] IWin_Settings not initialized|r")
        return false
    end

    -- Wrap in pcall for safety
    local success, result = pcall(function()
        -- Check cache first
        if IWin_Settings.SpellCache[name] ~= nil then
            return IWin_Settings.SpellCache[name]
        end

        -- Cache miss - scan spellbook
        local spellID = 1
        local spell = GetSpellName(spellID, "BOOKTYPE_SPELL")
        local iterations = 0
        while spell do
            if spell == name then
                IWin_Settings.SpellCache[name] = true
                IWin_Settings.SpellIDCache[name] = spellID -- Also cache the ID
                return true
            end
            spellID = spellID + 1
            spell = GetSpellName(spellID, "BOOKTYPE_SPELL")

            -- Safety limit to prevent infinite loops
            iterations = iterations + 1
            if iterations > IWin.CONSTANTS.MAX_SPELL_SCAN_ITERATIONS then
                DEFAULT_CHAT_FRAME:AddMessage("|cffff0000[IWin Error] GetSpell exceeded iteration limit|r")
                break
            end
        end
        IWin_Settings.SpellCache[name] = false
        return false
    end)

    if not success then
        DEFAULT_CHAT_FRAME:AddMessage("|cffff0000[IWin Error] GetSpell failed: " .. tostring(result) .. "|r")
        return false
    end

    return result
end

-- Safely switch to a stance if available and not already in it
function IWin:SwitchStance(stanceName)
    -- Error handling: validate input
    if not stanceName or type(stanceName) ~= "string" or stanceName == "" then
        return false
    end

    -- Validate IWin_Settings exists
    if not IWin_Settings or type(IWin_Settings) ~= "table" then
        return false
    end

    if not IWin_Settings["AutoStance"] then
        return false
    end

    -- Wrap in pcall for safety
    local success, result = pcall(function()
        -- Map stance names to stance bar indices
        local stanceMap = {
            ["Battle Stance"] = IWin.CONSTANTS.BATTLE_STANCE,
            ["Defensive Stance"] = IWin.CONSTANTS.DEFENSIVE_STANCE,
            ["Berserker Stance"] = IWin.CONSTANTS.BERSERKER_STANCE
        }

        local stanceIndex = stanceMap[stanceName]
        if not stanceIndex then
            return false
        end

        -- Check if we have this stance and if we're not already in it
        local _, _, isActive = GetShapeshiftFormInfo(stanceIndex)
        if isActive then
            return false -- Already in this stance
        end

        -- Check if the stance is available
        local texture = GetShapeshiftFormInfo(stanceIndex)
        if texture then
            CastSpellByName(stanceName)
            return true
        end

        return false
    end)

    if not success then
        DEFAULT_CHAT_FRAME:AddMessage("|cffff0000[IWin Error] SwitchStance failed: " .. tostring(result) .. "|r")
        return false
    end

    return result
end

-- Throttle rotations to prevent excessive function calls
function IWin:ShouldThrottle()
    -- Ensure settings are initialized
    if not IWin_Settings["LastRotationTime"] then
        IWin_Settings["LastRotationTime"] = 0
    end
    if not IWin_Settings["RotationThrottle"] then
        IWin_Settings["RotationThrottle"] = 0.1
    end

    local currentTime = GetTime()
    if currentTime - IWin_Settings["LastRotationTime"] < IWin_Settings["RotationThrottle"] then
        return true
    end
    IWin_Settings["LastRotationTime"] = currentTime
    return false
end

-- Separate throttle for reactive abilities (Revenge, Overpower) - much shorter delay
function IWin:ShouldThrottleReactive()
    -- Ensure settings are initialized
    if not IWin_Settings["LastReactiveTime"] then
        IWin_Settings["LastReactiveTime"] = 0
    end

    local currentTime = GetTime()
    if currentTime - IWin_Settings["LastReactiveTime"] < IWin.CONSTANTS.REACTIVE_THROTTLE then
        return true
    end
    IWin_Settings["LastReactiveTime"] = currentTime
    return false
end

-- Separate throttle for interrupts - very short delay
function IWin:ShouldThrottleInterrupt()
    -- Ensure settings are initialized
    if not IWin_Settings["LastInterruptTime"] then
        IWin_Settings["LastInterruptTime"] = 0
    end

    local currentTime = GetTime()
    if currentTime - IWin_Settings["LastInterruptTime"] < IWin.CONSTANTS.INTERRUPT_THROTTLE then
        return true
    end
    IWin_Settings["LastInterruptTime"] = currentTime
    return false
end

-- Common rotation functions to reduce code duplication
function IWin:HandleAutoAttack()
    if not IWin_Settings["AutoAttack"] then
        return
    end
    if not IWin_Settings["AttackSlot"] then
        IWin_Settings["AttackSlot"] = IWin:GetActionSlot("Attack")
    end
    -- Only attempt to use if we found a valid slot
    if IWin_Settings["AttackSlot"] and not IsCurrentAction(IWin_Settings["AttackSlot"]) then
        UseAction(IWin_Settings["AttackSlot"])
    end
end

function IWin:HandleCharge()
    -- Check if auto-charge is enabled
    if not IWin_Settings["AutoCharge"] then
        return false
    end

    local c = CastSpellByName
    local _, _, isActive = GetShapeshiftFormInfo(1)

    if not IWin:GetSpell("Charge") or UnitAffectingCombat("player") or IWin:OnCooldown("Charge") then
        return false
    end

    -- Try SuperWOW distance API if available (more accurate)
    local inChargeRange = false
    if IWin.superwow and IWin.superwow.GetDistanceToUnit then
        local distance = IWin.superwow.GetDistanceToUnit("target")
        if distance and distance >= IWin.CONSTANTS.CHARGE_RANGE_MIN and distance <= IWin.CONSTANTS.CHARGE_RANGE_MAX then
            inChargeRange = true
        end
    else
        -- Fallback to CheckInteractDistance (approximation: 10-28 yards)
        if CheckInteractDistance("target", 3) == nil and CheckInteractDistance("target", 4) == 1 then
            inChargeRange = true
        end
    end

    if inChargeRange then
        if UnitMana("player") <= IWin_Settings["RageChargeMax"] then
            self:SwitchStance("Battle Stance")
            c("Charge")
            return true
        elseif isActive then
            c("Charge")
            return true
        end
    end
    return false
end

function IWin:HandleBattleShout(inCombat)
    -- Check if auto-battle shout is enabled
    if not IWin_Settings["AutoBattleShout"] then
        return false
    end

    local c = CastSpellByName
    if IWin:GetSpell("Battle Shout") and not IWin:GetBuff("player", "Battle Shout") then
        local rageNeeded = inCombat and IWin_Settings["RageShoutCombatMin"] or IWin_Settings["RageShoutMin"]

        if UnitMana("player") >= rageNeeded then
            if not inCombat or not UnitExists("target") or (UnitHealth("target") / UnitHealthMax("target")) > 0.2 then
                c("Battle Shout")
                return true
            end
        end
    end
    return false
end

function IWin:HandleBloodrage()
    if not IWin_Settings["AutoBloodrage"] then
        return false
    end
    local c = CastSpellByName
    if IWin:GetSpell("Bloodrage") and UnitAffectingCombat("player") and UnitMana("player") < IWin_Settings["RageBloodrageMin"] and not IWin:OnCooldown("Bloodrage") then
        c("Bloodrage")
        return true
    end
    return false
end

function IWin:HandleOverpower()
    -- Use reactive throttle for Overpower
    if IWin:ShouldThrottleReactive() then
        return false
    end

    local c = CastSpellByName
    -- Check if dodge occurred within configured window
    if GetTime() - IWin_Settings["dodge"] < IWin_Settings["OverpowerWindow"] then
        if IWin:GetSpell("Overpower") and not IWin:OnCooldown("Overpower") and UnitMana("player") >= IWin_Settings["RageOverpowerMin"] then
            self:SwitchStance("Battle Stance")
            c("Overpower")
            return true
        end
    end
    return false
end

-- Revenge handler - Uses IsUsableAction to detect proc availability
function IWin:HandleRevenge()
    -- Use reactive throttle for Revenge - don't miss procs
    if IWin:ShouldThrottleReactive() then
        return false
    end

    if not IWin_Settings["AutoRevenge"] then
        return false
    end

    -- Check if player has Revenge spell
    if not IWin:GetSpell("Revenge") then
        return false
    end

    -- Check rage requirement
    if UnitMana("player") < IWin_Settings["RageRevengeMin"] then
        return false
    end

    -- Check cooldown
    if IWin:OnCooldown("Revenge") then
        return false
    end

    -- Find Revenge on action bars and check if usable
    if not IWin_Settings["RevengeSlot"] then
        IWin_Settings["RevengeSlot"] = IWin:GetActionSlot("Revenge")
    end

    -- If we found Revenge on action bars, use IsUsableAction to check proc
    if IWin_Settings["RevengeSlot"] then
        local usable, notEnoughMana = IsUsableAction(IWin_Settings["RevengeSlot"])
        if usable then
            CastSpellByName("Revenge")
            return true
        end
    else
        -- Fallback: if Revenge not on bars, try casting anyway (will fail if no proc)
        -- This maintains backward compatibility
        CastSpellByName("Revenge")
        return true
    end

    return false
end

-- Interrupt handler (SuperWOW only - requires casting detection)
function IWin:HandleInterrupt()
    -- Use interrupt throttle - faster than normal rotation
    if IWin:ShouldThrottleInterrupt() then
        return false
    end

    if not IWin_Settings["AutoInterrupt"] or not IWin.superwow then
        return false
    end

    -- Ensure targetCasting is initialized
    if not IWin_Settings["targetCasting"] or type(IWin_Settings["targetCasting"]) ~= "table" then
        IWin_Settings["targetCasting"] = {
            isCasting = false,
            spellName = nil,
            castEndTime = 0,
            isChanneling = false
        }
        return false
    end

    if not IWin_Settings["targetCasting"].isCasting then
        return false
    end

    local timeRemaining = IWin_Settings["targetCasting"].castEndTime - GetTime()

    -- Interrupt when sufficient time remaining (account for latency)
    if timeRemaining >= IWin.CONSTANTS.INTERRUPT_WINDOW_MIN and timeRemaining <= IWin.CONSTANTS.INTERRUPT_WINDOW_MAX then
        local c = CastSpellByName
        if IWin:GetSpell("Pummel") and not IWin:OnCooldown("Pummel") and UnitMana("player") >= IWin_Settings["RageInterruptMin"] then
            IWin:SwitchStance("Berserker Stance")
            c("Pummel")
            return true
        elseif IWin:GetSpell("Shield Bash") and not IWin:OnCooldown("Shield Bash") and UnitMana("player") >= IWin_Settings["RageInterruptMin"] then
            IWin:SwitchStance("Defensive Stance")
            c("Shield Bash")
            return true
        end
    end
    return false
end

-- Smart Heroic Strike queueing (SuperWOW only - based on swing timer)
function IWin:ShouldQueueHeroicStrike()
    if not IWin_Settings["SmartHeroicStrike"] or not IWin.superwow then
        return true  -- Always queue if not using smart logic
    end

    if IWin_Settings["swingTimer"] == 0 or IWin_Settings["lastSwingTime"] == 0 then
        return true  -- No swing data yet, queue normally
    end

    local currentTime = GetTime()
    local timeSinceLastSwing = currentTime - IWin_Settings["lastSwingTime"]
    local timeUntilNextSwing = IWin_Settings["swingTimer"] - timeSinceLastSwing

    -- Queue when within configured window of next swing
    if timeUntilNextSwing <= IWin_Settings["HeroicStrikeQueueWindow"] and timeUntilNextSwing >= 0 then
        return true
    end

    return false
end

-- Count nearby enemies using UnitPosition (SuperWOW only)
function IWin:CountNearbyEnemies(range)
    if not IWin.superwow or not IWin.superwow.UnitPosition then
        return 0  -- Fallback: can't count enemies on vanilla
    end

    local px, py, pz = IWin.superwow.UnitPosition("player")
    if not px then return 0 end

    local count = 0

    -- Check nameplates for nearby enemies (SuperWOW provides better nameplate info)
    for i = 1, 40 do
        local unit = "nameplate" .. i
        if UnitExists(unit) and UnitCanAttack("player", unit) and not UnitIsDead(unit) then
            local ex, ey, ez = IWin.superwow.UnitPosition(unit)
            if ex then
                -- Calculate 3D distance
                local distance = math.sqrt((px - ex)^2 + (py - ey)^2 + (pz - ez)^2)
                if distance <= range then
                    count = count + 1
                end
            end
        end
    end

    return count
end

-- Check if spell is in range using SuperWOW SpellInfo
function IWin:IsInSpellRange(spellName)
    if not IWin.superwow or not IWin.superwow.SpellInfo or not IWin.superwow.GetDistanceToUnit then
        return true  -- Fallback: assume in range on vanilla
    end

    local spellID = IWin_Settings.SpellIDCache[spellName]
    if not spellID then return true end

    -- Get spell range from SpellInfo
    local _, _, _, minRange, maxRange = IWin.superwow.SpellInfo(spellID)
    if not maxRange or maxRange == 0 then
        return true  -- Melee range or no range restriction
    end

    -- Get distance to target
    local distance = IWin.superwow.GetDistanceToUnit("target")
    if not distance then return false end

    -- Check if within range
    minRange = minRange or 0
    return distance >= minRange and distance <= maxRange
end

-- Detect if target is a boss (worldboss, skull level, or elite + skull)
function IWin:IsBoss()
    if not UnitExists("target") then
        return false
    end

    local classification = UnitClassification("target")
    local level = UnitLevel("target")

    -- Boss: worldboss, skull level (-1), or elite + skull
    return classification == "worldboss"
        or level == -1
        or (classification == "elite" and level == -1)
end

-- Validate target for combat (exists, alive, hostile)
function IWin:ValidateTarget()
    if not UnitExists("target") or UnitIsDead("target") then
        return false
    end
    if not UnitCanAttack("player", "target") then
        return false
    end
    return true
end

-- Log boss detection changes (called by rotations to avoid spam)
function IWin:LogBossDetection()
    if not UnitExists("target") then
        return
    end

    local isBoss = IWin:IsBoss()
    local targetName = UnitName("target")

    -- Only log when boss state or target changes
    if IWin_Settings["lastBossState"] ~= isBoss or IWin_Settings["lastTargetName"] ~= targetName then
        IWin_Settings["lastBossState"] = isBoss
        IWin_Settings["lastTargetName"] = targetName

        local classification = UnitClassification("target")
        local level = UnitLevel("target")
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[IWin Boss Detection]|r Target: " .. targetName ..
            " | Type: " .. (isBoss and "|cffff0000BOSS|r" or "|cff00ff00Trash|r") ..
            " | Class: " .. classification .. " | Level: " .. (level == -1 and "??" or tostring(level)))
    end
end

-- Helper function to check if a trinket is offensive (has a Use effect)
function IWin:IsOffensiveTrinket(slot)
    IWinFrame_T:SetOwner(WorldFrame, "ANCHOR_NONE")
    IWinFrame_T:ClearLines()
    IWinFrame_T:SetInventoryItem("player", slot)
    for i = 1, IWinFrame_T:NumLines() do
        local line = getglobal("IWinFrame_TTextLeft" .. i)
        if line and line:GetText() and string.find(line:GetText(), "Use:") then
            return true
        end
    end
    return false
end

-- Helper function to use a single trinket slot
function IWin:UseTrinketSlot(slot, onlyOffensiveTrinkets)
    if not GetInventoryItemTexture("player", slot) then
        return false
    end
    if GetInventoryItemCooldown("player", slot) ~= 0 then
        return false
    end

    if onlyOffensiveTrinkets then
        if self:IsOffensiveTrinket(slot) then
            UseInventoryItem(slot)
            return true
        end
    else
        UseInventoryItem(slot)
        return true
    end
    return false
end

-- Use trinkets if available and not on cooldown
function IWin:UseTrinkets(onlyOffensiveTrinkets)
    if not IWin_Settings["AutoTrinkets"] then
        return
    end
    self:UseTrinketSlot(IWin_Settings["Trinket0Slot"], onlyOffensiveTrinkets)
    self:UseTrinketSlot(IWin_Settings["Trinket1Slot"], onlyOffensiveTrinkets)
end

-- Command definition table: maps command names to their handlers
-- This replaces the massive if/elseif chain with a data-driven approach
IWin.Commands = {
	-- Boolean toggles
	charge = {type = "boolean", setting = "AutoCharge", label = "Auto-charge"},
	shout = {type = "boolean", setting = "AutoBattleShout", label = "Auto-battle shout"},
	bloodrage = {type = "boolean", setting = "AutoBloodrage", label = "Auto-bloodrage"},
	trinkets = {type = "boolean", setting = "AutoTrinkets", label = "Auto-trinkets"},
	rend = {type = "boolean", setting = "AutoRend", label = "Auto-rend"},
	attack = {type = "boolean", setting = "AutoAttack", label = "Auto-attack"},
	stance = {type = "boolean", setting = "AutoStance", label = "Auto-stance switching"},
	shieldblock = {type = "boolean", setting = "AutoShieldBlock", label = "Auto-shield block"},
	skipthunderclap = {type = "boolean", setting = "SkipThunderClapWithThunderfury", label = "Skip Thunder Clap with Thunderfury"},
	revenge = {type = "boolean", setting = "AutoRevenge", label = "Auto-revenge (Revenge must be on action bars)"},
	interrupt = {type = "boolean", setting = "AutoInterrupt", label = "Auto-interrupt (SuperWOW only)"},
	smarths = {type = "boolean", setting = "SmartHeroicStrike", label = "Smart Heroic Strike (SuperWOW only)"},
	skiprendtrash = {type = "boolean", setting = "SkipRendOnTrash", label = "Skip Rend on trash"},

	-- Rage thresholds (0-100)
	chargemax = {type = "numeric", setting = "RageChargeMax", min = 0, max = 100, label = "Charge max rage"},
	bloodragemin = {type = "numeric", setting = "RageBloodrageMin", min = 0, max = 100, label = "Bloodrage min rage"},
	bloodthirstmin = {type = "numeric", setting = "RageBloodthirstMin", min = 0, max = 100, label = "Bloodthirst min rage"},
	mortalstrikemin = {type = "numeric", setting = "RageMortalStrikeMin", min = 0, max = 100, label = "Mortal Strike min rage"},
	whirlwindmin = {type = "numeric", setting = "RageWhirlwindMin", min = 0, max = 100, label = "Whirlwind min rage"},
	sweepingmin = {type = "numeric", setting = "RageSweepingMin", min = 0, max = 100, label = "Sweeping Strikes min rage"},
	heroicmin = {type = "numeric", setting = "RageHeroicMin", min = 0, max = 100, label = "Heroic Strike min rage"},
	cleavemin = {type = "numeric", setting = "RageCleaveMin", min = 0, max = 100, label = "Cleave min rage"},
	shoutmin = {type = "numeric", setting = "RageShoutMin", min = 0, max = 100, label = "Battle Shout min rage"},
	shoutcombatmin = {type = "numeric", setting = "RageShoutCombatMin", min = 0, max = 100, label = "Battle Shout min rage (combat)"},
	overpowermin = {type = "numeric", setting = "RageOverpowerMin", min = 0, max = 100, label = "Overpower min rage"},
	executemin = {type = "numeric", setting = "RageExecuteMin", min = 0, max = 100, label = "Execute min rage"},
	rendmin = {type = "numeric", setting = "RageRendMin", min = 0, max = 100, label = "Rend min rage"},
	interruptmin = {type = "numeric", setting = "RageInterruptMin", min = 0, max = 100, label = "Interrupt min rage"},

	-- Tank rage thresholds
	shieldslammin = {type = "numeric", setting = "RageShieldSlamMin", min = 0, max = 100, label = "Shield Slam min rage"},
	revengemin = {type = "numeric", setting = "RageRevengeMin", min = 0, max = 100, label = "Revenge min rage"},
	thunderclapmin = {type = "numeric", setting = "RageThunderClapMin", min = 0, max = 100, label = "Thunder Clap min rage"},
	demoshoutmin = {type = "numeric", setting = "RageDemoShoutMin", min = 0, max = 100, label = "Demo Shout min rage"},
	sundermin = {type = "numeric", setting = "RageSunderMin", min = 0, max = 100, label = "Sunder Armor min rage"},
	concussionblowmin = {type = "numeric", setting = "RageConcussionBlowMin", min = 0, max = 100, label = "Concussion Blow min rage"},
	shieldblockmin = {type = "numeric", setting = "RageShieldBlockMin", min = 0, max = 100, label = "Shield Block min rage"},

	-- Health thresholds (1-99)
	laststand = {type = "numeric", setting = "LastStandThreshold", min = 1, max = 99, label = "Last Stand threshold", suffix = "%"},
	concussionblow = {type = "numeric", setting = "ConcussionBlowThreshold", min = 1, max = 99, label = "Concussion Blow threshold", suffix = "%"},

	-- Debuff refresh timings
	refreshrend = {type = "numeric", setting = "RefreshRend", min = 1, max = 20, label = "Rend refresh time", suffix = "s"},
	refreshsunder = {type = "numeric", setting = "RefreshSunder", min = 1, max = 29, label = "Sunder refresh time", suffix = "s"},
	refreshthunder = {type = "numeric", setting = "RefreshThunderClap", min = 1, max = 25, label = "Thunder Clap refresh time", suffix = "s"},
	refreshdemo = {type = "numeric", setting = "RefreshDemoShout", min = 1, max = 29, label = "Demo Shout refresh time", suffix = "s"},

	-- Boss detection
	sunderboss = {type = "numeric", setting = "SunderStacksBoss", min = 1, max = 5, label = "Boss sunder stacks"},
	sundertrash = {type = "numeric", setting = "SunderStacksTrash", min = 1, max = 5, label = "Trash sunder stacks"},

	-- Other numeric settings
	throttle = {type = "numeric", setting = "RotationThrottle", min = 0.05, max = 1.0, label = "Rotation throttle", suffix = " seconds"},
	opwindow = {type = "numeric", setting = "OverpowerWindow", min = 1, max = 10, label = "Overpower window", suffix = "s"},
	sunderstacks = {type = "numeric", setting = "SunderStacks", min = 1, max = 5, label = "Sunder stack target"},
	aoethreshold = {type = "numeric", setting = "AOETargetThreshold", min = 2, max = 10, label = "AOE target threshold", suffix = " enemies"}
}

-- Generic handler for boolean settings
function IWin:HandleBooleanCommand(cmd, value)
	if value == "on" then
		IWin_Settings[cmd.setting] = true
		DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00" .. cmd.label .. " enabled|r")
	elseif value == "off" then
		IWin_Settings[cmd.setting] = false
		DEFAULT_CHAT_FRAME:AddMessage("|cffff0000" .. cmd.label .. " disabled|r")
	else
		local status = IWin_Settings[cmd.setting] and "|cff00ff00ON|r" or "|cffff0000OFF|r"
		DEFAULT_CHAT_FRAME:AddMessage(cmd.label .. " is: " .. status)
	end
end

-- Generic handler for numeric settings
function IWin:HandleNumericCommand(cmd, value)
	if value then
		local num = tonumber(value)
		if num and num >= cmd.min and num <= cmd.max then
			IWin_Settings[cmd.setting] = num
			local suffix = cmd.suffix or ""
			DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00" .. cmd.label .. " set to " .. num .. suffix .. "|r")
		else
			DEFAULT_CHAT_FRAME:AddMessage("|cffff0000Invalid value. Use " .. cmd.min .. "-" .. cmd.max .. "|r")
		end
	else
		local suffix = cmd.suffix or ""
		DEFAULT_CHAT_FRAME:AddMessage(cmd.label .. ": " .. IWin_Settings[cmd.setting] .. suffix)
	end
end

-- Configuration and help commands
function IWin:Config(msg)
    local args = {}
    for word in string.gfind(msg, "%S+") do
        table.insert(args, string.lower(word))
    end

	-- Handle special commands first (help, status, debug, cache, loglevel, ui, config)
    if not args[1] or args[1] == "help" then
        DEFAULT_CHAT_FRAME:AddMessage("|cff0066ffIWin Configuration Commands:|r")
        DEFAULT_CHAT_FRAME:AddMessage("|cffff8800Toggles:|r")
        DEFAULT_CHAT_FRAME:AddMessage("/iwin charge [on|off] - Toggle auto-charge")
        DEFAULT_CHAT_FRAME:AddMessage("/iwin shout [on|off] - Toggle auto-battle shout")
        DEFAULT_CHAT_FRAME:AddMessage("/iwin bloodrage [on|off] - Toggle auto-bloodrage")
        DEFAULT_CHAT_FRAME:AddMessage("/iwin trinkets [on|off] - Toggle auto-trinkets")
        DEFAULT_CHAT_FRAME:AddMessage("/iwin rend [on|off] - Toggle auto-rend")
        DEFAULT_CHAT_FRAME:AddMessage("/iwin attack [on|off] - Toggle auto-attack")
        DEFAULT_CHAT_FRAME:AddMessage("/iwin stance [on|off] - Toggle auto-stance switching")
        DEFAULT_CHAT_FRAME:AddMessage("/iwin shieldblock [on|off] - Toggle auto-shield block")
        DEFAULT_CHAT_FRAME:AddMessage("/iwin skipthunderclap [on|off] - Skip Thunder Clap with Thunderfury")
        DEFAULT_CHAT_FRAME:AddMessage("/iwin revenge [on|off] - Auto-revenge (requires Revenge on bars)")
        DEFAULT_CHAT_FRAME:AddMessage("|cffff8800SuperWOW Features:|r")
        DEFAULT_CHAT_FRAME:AddMessage("/iwin interrupt [on|off] - Auto-interrupt (SuperWOW)")
        DEFAULT_CHAT_FRAME:AddMessage("/iwin smarths [on|off] - Smart Heroic Strike (SuperWOW)")
        DEFAULT_CHAT_FRAME:AddMessage("/iwin interruptmin [0-100] - Min rage for interrupts")
        DEFAULT_CHAT_FRAME:AddMessage("|cffff8800Rage Thresholds (DPS):|r")
        DEFAULT_CHAT_FRAME:AddMessage("/iwin chargemax [0-100] - Max rage to charge")
        DEFAULT_CHAT_FRAME:AddMessage("/iwin bloodragemin [0-100] - Min rage for bloodrage")
        DEFAULT_CHAT_FRAME:AddMessage("/iwin bloodthirstmin [0-100] - Min rage for bloodthirst")
        DEFAULT_CHAT_FRAME:AddMessage("/iwin mortalstrikemin [0-100] - Min rage for mortal strike")
        DEFAULT_CHAT_FRAME:AddMessage("/iwin whirlwindmin [0-100] - Min rage for whirlwind")
        DEFAULT_CHAT_FRAME:AddMessage("/iwin sweepingmin [0-100] - Min rage for sweeping strikes")
        DEFAULT_CHAT_FRAME:AddMessage("/iwin heroicmin [0-100] - Min rage for heroic strike")
        DEFAULT_CHAT_FRAME:AddMessage("/iwin cleavemin [0-100] - Min rage for cleave")
        DEFAULT_CHAT_FRAME:AddMessage("/iwin shoutmin [0-100] - Min rage for battle shout (OOC)")
        DEFAULT_CHAT_FRAME:AddMessage("/iwin shoutcombatmin [0-100] - Min rage for battle shout (combat)")
        DEFAULT_CHAT_FRAME:AddMessage("/iwin overpowermin [0-100] - Min rage for overpower")
        DEFAULT_CHAT_FRAME:AddMessage("/iwin executemin [0-100] - Min rage for execute")
        DEFAULT_CHAT_FRAME:AddMessage("/iwin rendmin [0-100] - Min rage for rend")
        DEFAULT_CHAT_FRAME:AddMessage("|cffff8800Rage Thresholds (Tank):|r")
        DEFAULT_CHAT_FRAME:AddMessage("/iwin shieldslammin [0-100] - Min rage for shield slam")
        DEFAULT_CHAT_FRAME:AddMessage("/iwin revengemin [0-100] - Min rage for revenge")
        DEFAULT_CHAT_FRAME:AddMessage("/iwin thunderclapmin [0-100] - Min rage for thunder clap")
        DEFAULT_CHAT_FRAME:AddMessage("/iwin demoshoutmin [0-100] - Min rage for demo shout")
        DEFAULT_CHAT_FRAME:AddMessage("/iwin sundermin [0-100] - Min rage for sunder armor")
        DEFAULT_CHAT_FRAME:AddMessage("/iwin concussionblowmin [0-100] - Min rage for concussion blow")
        DEFAULT_CHAT_FRAME:AddMessage("/iwin shieldblockmin [0-100] - Min rage for shield block")
        DEFAULT_CHAT_FRAME:AddMessage("|cffff8800Health Thresholds:|r")
        DEFAULT_CHAT_FRAME:AddMessage("/iwin execute [1-99] - Execute health threshold %")
        DEFAULT_CHAT_FRAME:AddMessage("/iwin laststand [1-99] - Last Stand health threshold %")
        DEFAULT_CHAT_FRAME:AddMessage("/iwin concussionblow [1-99] - Concussion Blow health threshold %")
        DEFAULT_CHAT_FRAME:AddMessage("|cffff8800Debuff Refresh Times:|r")
        DEFAULT_CHAT_FRAME:AddMessage("/iwin refreshrend [1-20] - Rend refresh time (seconds)")
        DEFAULT_CHAT_FRAME:AddMessage("/iwin refreshsunder [1-29] - Sunder refresh time (seconds)")
        DEFAULT_CHAT_FRAME:AddMessage("/iwin refreshthunder [1-25] - Thunder Clap refresh time (seconds)")
        DEFAULT_CHAT_FRAME:AddMessage("/iwin refreshdemo [1-29] - Demo Shout refresh time (seconds)")
        DEFAULT_CHAT_FRAME:AddMessage("|cffff8800Boss Detection:|r")
        DEFAULT_CHAT_FRAME:AddMessage("/iwin executeboss [1-99] - Boss execute threshold %")
        DEFAULT_CHAT_FRAME:AddMessage("/iwin executetrash [1-99] - Trash execute threshold %")
        DEFAULT_CHAT_FRAME:AddMessage("/iwin sunderboss [1-5] - Boss sunder stack target")
        DEFAULT_CHAT_FRAME:AddMessage("/iwin sundertrash [1-5] - Trash sunder stack target")
        DEFAULT_CHAT_FRAME:AddMessage("/iwin skiprendtrash [on|off] - Skip Rend on trash mobs")
        DEFAULT_CHAT_FRAME:AddMessage("|cffff8800Other:|r")
        DEFAULT_CHAT_FRAME:AddMessage("/iwin throttle [0.05-1.0] - Set rotation throttle in seconds")
        DEFAULT_CHAT_FRAME:AddMessage("/iwin opwindow [1-10] - Overpower window (seconds)")
        DEFAULT_CHAT_FRAME:AddMessage("/iwin sunderstacks [1-5] - Sunder stack target")
        DEFAULT_CHAT_FRAME:AddMessage("/iwin aoethreshold [2-10] - Min enemies for AOE (SuperWOW)")
        DEFAULT_CHAT_FRAME:AddMessage("/iwin status - Show current settings")
        DEFAULT_CHAT_FRAME:AddMessage("/iwin cache clear - Clear spell cache")
        DEFAULT_CHAT_FRAME:AddMessage("/iwin loglevel [error|warn|info|debug] - Set logging level")
        DEFAULT_CHAT_FRAME:AddMessage("/iwin debug - Show debug information")
        DEFAULT_CHAT_FRAME:AddMessage("/iwin ui - Open graphical configuration interface")
        DEFAULT_CHAT_FRAME:AddMessage("/iwin config - Same as /iwin ui")

	-- Try table-driven command lookup
	elseif IWin.Commands[args[1]] then
		local cmd = IWin.Commands[args[1]]
		if cmd.type == "boolean" then
			self:HandleBooleanCommand(cmd, args[2])
		elseif cmd.type == "numeric" then
			self:HandleNumericCommand(cmd, args[2])
		end

	elseif args[1] == "status" then
        DEFAULT_CHAT_FRAME:AddMessage("|cff0066ffIWin Status:|r")
        DEFAULT_CHAT_FRAME:AddMessage("|cffff8800Toggles:|r")
        DEFAULT_CHAT_FRAME:AddMessage("  Auto-charge: " .. (IWin_Settings["AutoCharge"] and "|cff00ff00ON|r" or "|cffff0000OFF|r"))
        DEFAULT_CHAT_FRAME:AddMessage("  Auto-battle shout: " .. (IWin_Settings["AutoBattleShout"] and "|cff00ff00ON|r" or "|cffff0000OFF|r"))
        DEFAULT_CHAT_FRAME:AddMessage("  Auto-bloodrage: " .. (IWin_Settings["AutoBloodrage"] and "|cff00ff00ON|r" or "|cffff0000OFF|r"))
        DEFAULT_CHAT_FRAME:AddMessage("  Auto-trinkets: " .. (IWin_Settings["AutoTrinkets"] and "|cff00ff00ON|r" or "|cffff0000OFF|r"))
        DEFAULT_CHAT_FRAME:AddMessage("  Auto-rend: " .. (IWin_Settings["AutoRend"] and "|cff00ff00ON|r" or "|cffff0000OFF|r"))
        DEFAULT_CHAT_FRAME:AddMessage("  Auto-attack: " .. (IWin_Settings["AutoAttack"] and "|cff00ff00ON|r" or "|cffff0000OFF|r"))
        DEFAULT_CHAT_FRAME:AddMessage("  Auto-stance: " .. (IWin_Settings["AutoStance"] and "|cff00ff00ON|r" or "|cffff0000OFF|r"))
        DEFAULT_CHAT_FRAME:AddMessage("  Auto-shield block: " .. (IWin_Settings["AutoShieldBlock"] and "|cff00ff00ON|r" or "|cffff0000OFF|r"))
        DEFAULT_CHAT_FRAME:AddMessage("  Skip Thunder Clap w/ Thunderfury: " .. (IWin_Settings["SkipThunderClapWithThunderfury"] and "|cff00ff00ON|r" or "|cffff0000OFF|r"))
        DEFAULT_CHAT_FRAME:AddMessage("|cffff8800SuperWOW Features:|r")
        DEFAULT_CHAT_FRAME:AddMessage("  Client: " .. (IWin.superwow and "|cff00ff00SuperWOW|r" or "|cffff8800Vanilla|r"))
        DEFAULT_CHAT_FRAME:AddMessage("  Auto-interrupt: " .. (IWin_Settings["AutoInterrupt"] and "|cff00ff00ON|r" or "|cffff0000OFF|r"))
        DEFAULT_CHAT_FRAME:AddMessage("  Smart Heroic Strike: " .. (IWin_Settings["SmartHeroicStrike"] and "|cff00ff00ON|r" or "|cffff0000OFF|r"))
        DEFAULT_CHAT_FRAME:AddMessage("  Auto-revenge: " .. (IWin_Settings["AutoRevenge"] and "|cff00ff00ON|r" or "|cffff0000OFF|r"))
        DEFAULT_CHAT_FRAME:AddMessage("  Interrupt min rage: " .. IWin_Settings["RageInterruptMin"])
        DEFAULT_CHAT_FRAME:AddMessage("|cffff8800Rage Thresholds (DPS):|r")
        DEFAULT_CHAT_FRAME:AddMessage("  Charge max: " .. IWin_Settings["RageChargeMax"])
        DEFAULT_CHAT_FRAME:AddMessage("  Bloodrage min: " .. IWin_Settings["RageBloodrageMin"])
        DEFAULT_CHAT_FRAME:AddMessage("  Bloodthirst min: " .. IWin_Settings["RageBloodthirstMin"])
        DEFAULT_CHAT_FRAME:AddMessage("  Mortal Strike min: " .. IWin_Settings["RageMortalStrikeMin"])
        DEFAULT_CHAT_FRAME:AddMessage("  Whirlwind min: " .. IWin_Settings["RageWhirlwindMin"])
        DEFAULT_CHAT_FRAME:AddMessage("  Sweeping Strikes min: " .. IWin_Settings["RageSweepingMin"])
        DEFAULT_CHAT_FRAME:AddMessage("  Heroic Strike min: " .. IWin_Settings["RageHeroicMin"])
        DEFAULT_CHAT_FRAME:AddMessage("  Cleave min: " .. IWin_Settings["RageCleaveMin"])
        DEFAULT_CHAT_FRAME:AddMessage("  Battle Shout min (OOC): " .. IWin_Settings["RageShoutMin"])
        DEFAULT_CHAT_FRAME:AddMessage("  Battle Shout min (Combat): " .. IWin_Settings["RageShoutCombatMin"])
        DEFAULT_CHAT_FRAME:AddMessage("  Overpower min: " .. IWin_Settings["RageOverpowerMin"])
        DEFAULT_CHAT_FRAME:AddMessage("  Execute min: " .. IWin_Settings["RageExecuteMin"])
        DEFAULT_CHAT_FRAME:AddMessage("  Rend min: " .. IWin_Settings["RageRendMin"])
        DEFAULT_CHAT_FRAME:AddMessage("|cffff8800Rage Thresholds (Tank):|r")
        DEFAULT_CHAT_FRAME:AddMessage("  Shield Slam min: " .. IWin_Settings["RageShieldSlamMin"])
        DEFAULT_CHAT_FRAME:AddMessage("  Revenge min: " .. IWin_Settings["RageRevengeMin"])
        DEFAULT_CHAT_FRAME:AddMessage("  Thunder Clap min: " .. IWin_Settings["RageThunderClapMin"])
        DEFAULT_CHAT_FRAME:AddMessage("  Demo Shout min: " .. IWin_Settings["RageDemoShoutMin"])
        DEFAULT_CHAT_FRAME:AddMessage("  Sunder Armor min: " .. IWin_Settings["RageSunderMin"])
        DEFAULT_CHAT_FRAME:AddMessage("  Concussion Blow min: " .. IWin_Settings["RageConcussionBlowMin"])
        DEFAULT_CHAT_FRAME:AddMessage("  Shield Block min: " .. IWin_Settings["RageShieldBlockMin"])
        DEFAULT_CHAT_FRAME:AddMessage("|cffff8800Health Thresholds:|r")
        DEFAULT_CHAT_FRAME:AddMessage("  Execute: 20% (hardcoded)")
        DEFAULT_CHAT_FRAME:AddMessage("  Last Stand: " .. IWin_Settings["LastStandThreshold"] .. "%")
        DEFAULT_CHAT_FRAME:AddMessage("  Concussion Blow: " .. IWin_Settings["ConcussionBlowThreshold"] .. "%")
        DEFAULT_CHAT_FRAME:AddMessage("|cffff8800Boss Detection:|r")
        if UnitExists("target") then
            local isBoss = IWin:IsBoss()
            DEFAULT_CHAT_FRAME:AddMessage("  Current target is: " .. (isBoss and "|cffff0000BOSS|r" or "|cff00ff00Trash|r"))
        else
            DEFAULT_CHAT_FRAME:AddMessage("  Current target: |cff808080No target|r")
        end
        DEFAULT_CHAT_FRAME:AddMessage("  Boss sunder stacks: " .. IWin_Settings["SunderStacksBoss"])
        DEFAULT_CHAT_FRAME:AddMessage("  Trash sunder stacks: " .. IWin_Settings["SunderStacksTrash"])
        DEFAULT_CHAT_FRAME:AddMessage("  Skip Rend on trash: " .. (IWin_Settings["SkipRendOnTrash"] and "|cff00ff00ON|r" or "|cffff0000OFF|r"))
        DEFAULT_CHAT_FRAME:AddMessage("|cffff8800Debuff Refresh Times:|r")
        DEFAULT_CHAT_FRAME:AddMessage("  Rend: " .. IWin_Settings["RefreshRend"] .. "s")
        DEFAULT_CHAT_FRAME:AddMessage("  Sunder: " .. IWin_Settings["RefreshSunder"] .. "s")
        DEFAULT_CHAT_FRAME:AddMessage("  Thunder Clap: " .. IWin_Settings["RefreshThunderClap"] .. "s")
        DEFAULT_CHAT_FRAME:AddMessage("  Demo Shout: " .. IWin_Settings["RefreshDemoShout"] .. "s")
        DEFAULT_CHAT_FRAME:AddMessage("|cffff8800Other:|r")
        DEFAULT_CHAT_FRAME:AddMessage("  Rotation throttle: " .. IWin_Settings["RotationThrottle"] .. "s")
        DEFAULT_CHAT_FRAME:AddMessage("  Overpower window: " .. IWin_Settings["OverpowerWindow"] .. "s")
        DEFAULT_CHAT_FRAME:AddMessage("  Sunder stacks: " .. IWin_Settings["SunderStacks"])
        DEFAULT_CHAT_FRAME:AddMessage("  AOE target threshold: " .. IWin_Settings["AOETargetThreshold"] .. " enemies")
        DEFAULT_CHAT_FRAME:AddMessage("  Cached spells: " .. IWin:TableSize(IWin_Settings.SpellCache))

	elseif args[1] == "debug" then
        DEFAULT_CHAT_FRAME:AddMessage("|cff0066ff=== IWin Debug Info ===|r")
        DEFAULT_CHAT_FRAME:AddMessage("SuperWOW detected: " .. (IWin.superwow and "|cff00ff00YES|r" or "|cffff0000NO|r"))
        DEFAULT_CHAT_FRAME:AddMessage("AutoRevenge enabled: " .. (IWin_Settings["AutoRevenge"] and "|cff00ff00YES|r" or "|cffff0000NO|r"))
        DEFAULT_CHAT_FRAME:AddMessage("Revenge spell known: " .. (IWin:GetSpell("Revenge") and "|cff00ff00YES|r" or "|cffff0000NO|r"))
        DEFAULT_CHAT_FRAME:AddMessage("Revenge rage min: " .. tostring(IWin_Settings["RageRevengeMin"]))
        DEFAULT_CHAT_FRAME:AddMessage("Revenge window: " .. tostring(IWin_Settings["RevengeWindow"]) .. "s")
        if IWin_Settings["revengeProc"] and IWin_Settings["revengeProc"] > 0 then
            DEFAULT_CHAT_FRAME:AddMessage("Last revenge proc: " .. string.format("%.1f", GetTime() - IWin_Settings["revengeProc"]) .. "s ago")
        else
            DEFAULT_CHAT_FRAME:AddMessage("Last revenge proc: |cffff0000NEVER|r")
        end
        DEFAULT_CHAT_FRAME:AddMessage("Current rage: " .. tostring(UnitMana("player")))
        if IWin:GetSpell("Revenge") then
            DEFAULT_CHAT_FRAME:AddMessage("Revenge on cooldown: " .. (IWin:OnCooldown("Revenge") and "|cffff0000YES|r" or "|cff00ff00NO|r"))
        end
    elseif args[1] == "cache" and args[2] == "clear" then
        IWin_Settings.SpellCache = {}
        IWin_Settings.SpellIDCache = {}
        IWin_Settings.ActionSlotCache = {}
        IWin_Settings.AttackSlot = nil
        IWin_Settings.RevengeSlot = nil
        IWin:Log(IWin.LOG_LEVELS.INFO, "Spell and action slot cache cleared")
    elseif args[1] == "loglevel" then
        if args[2] == "error" then
            IWin_Settings.LogLevel = IWin.LOG_LEVELS.ERROR
            IWin:Log(IWin.LOG_LEVELS.INFO, "Log level set to ERROR")
        elseif args[2] == "warn" then
            IWin_Settings.LogLevel = IWin.LOG_LEVELS.WARN
            IWin:Log(IWin.LOG_LEVELS.INFO, "Log level set to WARN")
        elseif args[2] == "info" then
            IWin_Settings.LogLevel = IWin.LOG_LEVELS.INFO
            IWin:Log(IWin.LOG_LEVELS.INFO, "Log level set to INFO")
        elseif args[2] == "debug" then
            IWin_Settings.LogLevel = IWin.LOG_LEVELS.DEBUG
            IWin:Log(IWin.LOG_LEVELS.INFO, "Log level set to DEBUG")
        else
            local levelName = "INFO"
            if IWin_Settings.LogLevel == IWin.LOG_LEVELS.ERROR then
                levelName = "ERROR"
            elseif IWin_Settings.LogLevel == IWin.LOG_LEVELS.WARN then
                levelName = "WARN"
            elseif IWin_Settings.LogLevel == IWin.LOG_LEVELS.DEBUG then
                levelName = "DEBUG"
            end
            DEFAULT_CHAT_FRAME:AddMessage("Current log level: |cff00ff00" .. levelName .. "|r")
        end
    elseif args[1] == "ui" or args[1] == "config" then
        if IWin.UI then
            IWin.UI:Toggle()
        else
            DEFAULT_CHAT_FRAME:AddMessage("|cffff0000IWin UI not loaded|r")
        end
    end
end

function IWin:Help()
    DEFAULT_CHAT_FRAME:AddMessage("|cff0066ff========================================|r")
    DEFAULT_CHAT_FRAME:AddMessage("|cff0066ffIWin Rotation Priorities|r")
    DEFAULT_CHAT_FRAME:AddMessage("|cff0066ff========================================|r")
    DEFAULT_CHAT_FRAME:AddMessage("|cffff8800/dmgst|r - DPS Single Target")
    DEFAULT_CHAT_FRAME:AddMessage("  Charge → Overpower → Execute → BT/MS → WW → HS → Rend")
    DEFAULT_CHAT_FRAME:AddMessage("|cffff8800/dmgaoe|r - DPS AOE")
    DEFAULT_CHAT_FRAME:AddMessage("  Charge → Sweeping Strikes → WW → Cleave → BT/MS → Execute → Rend")
    DEFAULT_CHAT_FRAME:AddMessage("|cffff8800/tankst|r - Tank Single Target")
    DEFAULT_CHAT_FRAME:AddMessage("  Charge → Overpower → Execute → Shield Slam → Shield Block → Revenge → Thunder Clap → Demo Shout → Sunder x5")
    DEFAULT_CHAT_FRAME:AddMessage("|cffff8800/tankaoe|r - Tank AOE")
    DEFAULT_CHAT_FRAME:AddMessage("  Charge → Overpower → Execute → Thunder Clap → WW → Revenge → Demo Shout → Shield Slam → Cleave → Sunder")
    DEFAULT_CHAT_FRAME:AddMessage("|cff0066ff========================================|r")
    DEFAULT_CHAT_FRAME:AddMessage("|cffffffff Type /iwin for configuration options|r")
end

function IWin:TableSize(t)
    local count = 0
    for _ in pairs(t) do count = count + 1 end
    return count
end

SlashCmdList["IWIN_SLASH"] = function(msg)
    IWin:Config(msg)
end
SLASH_IWIN_SLASH1 = "/iwin"

SlashCmdList["IWINHELP_SLASH"] = function()
    IWin:Help()
end
SLASH_IWINHELP_SLASH1 = "/iwinhelp"

SlashCmdList["DMGST_SLASH"] = function()
    if IWin.dmgST then
        local success, err = pcall(IWin.dmgST, IWin)
        if not success then
            DEFAULT_CHAT_FRAME:AddMessage("|cffff0000[IWin Error] dmgST rotation failed: " .. tostring(err) .. "|r")
        end
    else
        DEFAULT_CHAT_FRAME:AddMessage("|cffff0000[IWin] dmgST rotation not loaded|r")
    end
end
SLASH_DMGST_SLASH1 = "/dmgst"

SlashCmdList["DMGAOE_SLASH"] = function()
    if IWin.dmgAOE then
        local success, err = pcall(IWin.dmgAOE, IWin)
        if not success then
            DEFAULT_CHAT_FRAME:AddMessage("|cffff0000[IWin Error] dmgAOE rotation failed: " .. tostring(err) .. "|r")
        end
    else
        DEFAULT_CHAT_FRAME:AddMessage("|cffff0000[IWin] dmgAOE rotation not loaded|r")
    end
end
SLASH_DMGAOE_SLASH1 = "/dmgaoe"

SlashCmdList["TANKST_SLASH"] = function()
    if IWin.tankST then
        local success, err = pcall(IWin.tankST, IWin)
        if not success then
            DEFAULT_CHAT_FRAME:AddMessage("|cffff0000[IWin Error] tankST rotation failed: " .. tostring(err) .. "|r")
        end
    else
        DEFAULT_CHAT_FRAME:AddMessage("|cffff0000[IWin] tankST rotation not loaded|r")
    end
end
SLASH_TANKST_SLASH1 = "/tankst"

SlashCmdList["TANKAOE_SLASH"] = function()
    if IWin.tankAOE then
        local success, err = pcall(IWin.tankAOE, IWin)
        if not success then
            DEFAULT_CHAT_FRAME:AddMessage("|cffff0000[IWin Error] tankAOE rotation failed: " .. tostring(err) .. "|r")
        end
    else
        DEFAULT_CHAT_FRAME:AddMessage("|cffff0000[IWin] tankAOE rotation not loaded|r")
    end
end
SLASH_TANKAOE_SLASH1 = "/tankaoe"
