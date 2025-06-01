--[[
#######################################
# IWin by Atreyyo @ VanillaGaming.org #
# Forked by Bear-LB @ github.com #
#######################################
]]
--
IWin = IWin or {}

IWinFrame = CreateFrame("frame", nil, UIParent)
IWinFrame.t = CreateFrame("GameTooltip", "IWinFrame_T", UIParent, "GameTooltipTemplate")
IWin_Settings = {
    ["dodge"] = 0,
    ["DebuffTracker"] = {},
}

IWinFrame:RegisterEvent("CHAT_MSG_COMBAT_SELF_MISSES")
IWinFrame:RegisterEvent("CHAT_MSG_SPELL_DAMAGESHIELDS_ON_SELF")
IWinFrame:RegisterEvent("ADDON_LOADED")
IWinFrame:SetScript("OnEvent", function()
    if event == "ADDON_LOADED" and arg1 == "IWin" then
        DEFAULT_CHAT_FRAME:AddMessage("|cff0066ff¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯|r")
        DEFAULT_CHAT_FRAME:AddMessage(
            "|cff0066ff IWin system loaded, make some macros containg either of these commands:|r"
        )
        DEFAULT_CHAT_FRAME:AddMessage("|cff0066ff dmgst, /dmgaoe, /tankst, /tankaoe !|r")
        DEFAULT_CHAT_FRAME:AddMessage("|cff0066ff¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯|r")
        IWinFrame:UnregisterEvent("ADDON_LOADED")
    elseif event == "CHAT_MSG_COMBAT_SELF_MISSES" then
        if string.find(arg1, "dodge") then
            IWin_Settings["dodge"] = GetTime()
        end
    elseif event == "CHAT_MSG_SPELL_DAMAGESHIELDS_ON_SELF" then
        if string.find(arg1, "dodge") then
            IWin_Settings["dodge"] = GetTime()
        end
    end
end)

function IWin:GetBuff(name, buff, stacks)
    local a = 1
    while UnitBuff(name, a) do
        local _, s = UnitBuff(name, a)
        IWinFrame_T:SetOwner(WorldFrame, "ANCHOR_NONE")
        IWinFrame_T:ClearLines()
        IWinFrame_T:SetUnitBuff(name, a)
        local text = IWinFrame_TTextLeft1:GetText()
        if text == buff then
            if stacks == 1 then
                return s
            else
                return true
            end
        end
        a = a + 1
    end
    a = 1
    while UnitDebuff(name, a) do
        local _, s = UnitDebuff(name, a)
        IWinFrame_T:SetOwner(WorldFrame, "ANCHOR_NONE")
        IWinFrame_T:ClearLines()
        IWinFrame_T:SetUnitDebuff(name, a)
        local text = IWinFrame_TTextLeft1:GetText()
        if text == buff then
            if stacks == 1 then
                return s
            else
                return true
            end
        end
        a = a + 1
    end

    return false
end

function IWin:CheckDebuffDuration(debuff, duration, recastThreshold)
    if IWin_Settings.DebuffTracker[debuff] then
        local currentTime = GetTime()
        local timeElapsed = currentTime - IWin_Settings.DebuffTracker[debuff].startTime
        local timeLeft = IWin_Settings.DebuffTracker[debuff].duration - timeElapsed
        if timeLeft > 0 then
            -- DEFAULT_CHAT_FRAME:AddMessage(debuff .. " has " .. string.format("%.1f", timeLeft) .. " seconds remaining.")
            if timeLeft < recastThreshold then
                return true -- Less than recastThreshold seconds remain
            end
        else
            -- DEFAULT_CHAT_FRAME:AddMessage(debuff .. " has expired.")
            IWin_Settings.DebuffTracker[debuff] = nil -- Clear expired debuff
            return true                               -- Treat as not found for recast
        end
        return false                                  -- Debuff is present with >= recastThreshold seconds remaining
    else
        -- DEFAULT_CHAT_FRAME:AddMessage(debuff .. " not tracked (not applied).")
        return true -- Debuff not applied, trigger recast
    end
end

function IWin:GetActionSlot(a)
    for i = 1, 100 do
        IWinFrame_T:SetOwner(UIParent, "ANCHOR_NONE")
        IWinFrame_T:ClearLines()
        IWinFrame_T:SetAction(i)
        local ab = IWinFrame_TTextLeft1:GetText()
        IWinFrame_T:Hide()
        if ab == a then
            return i
        end
    end
    return 2
end

function IWin:OnCooldown(Spell)
    if Spell then
        local spellID = 1
        local spell = GetSpellName(spellID, "BOOKTYPE_SPELL")
        while spell do
            if Spell == spell then
                if GetSpellCooldown(spellID, "BOOKTYPE_SPELL") == 0 then
                    return false
                else
                    return true
                end
            end
            spellID = spellID + 1
            spell = GetSpellName(spellID, "BOOKTYPE_SPELL")
        end
    end
end

function IWin:GetSpell(name)
    local spellID = 1
    local spell = GetSpellName(spellID, BOOKTYPE_SPELL)
    while spell do
        if spell == name then
            return true
        end
        spellID = spellID + 1
        spell = GetSpellName(spellID, BOOKTYPE_SPELL)
    end
    return false
end

SlashCmdList["DMGST_SLASH"] = IWin.dmgST
SLASH_DMGST_SLASH1 = "/dmgst"
SlashCmdList["DMGAOE_SLASH"] = IWin.dmgAOE
SLASH_DMGAOE_SLASH1 = "/dmgaoe"
SlashCmdList["TANKST_SLASH"] = IWin.tankST
SLASH_TANKST_SLASH1 = "/tankst"
SlashCmdList["TANKAOE_SLASH"] = IWin.tankAOE
SLASH_TANKAOE_SLASH1 = "/tankaoe"
