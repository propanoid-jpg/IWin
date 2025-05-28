--[[
#######################################
# dmgST by Atreyyo @ VanillaGaming.org #
#######################################
]]
--
require("basicfunctions")
require("dmgST")
require("dmgAOE")
require("tankST")
require("tankAOE")

dmgST = CreateFrame("frame", nil, UIParent)
dmgST.t = CreateFrame("GameTooltip", "dmgST_T", UIParent, "GameTooltipTemplate")
dmgST_Settings = {
	["dodge"] = 0,
}

dmgST:RegisterEvent("CHAT_MSG_COMBAT_SELF_MISSES")
dmgST:RegisterEvent("CHAT_MSG_SPELL_DAMAGESHIELDS_ON_SELF")
dmgST:RegisterEvent("ADDON_LOADED")
dmgST:SetScript("OnEvent", function()
	if event == "ADDON_LOADED" and arg1 == "dmgST" then
		DEFAULT_CHAT_FRAME:AddMessage("|cff0066ff¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯|r")
		DEFAULT_CHAT_FRAME:AddMessage(
			"|cff0066ff dmgST system loaded, make some macros containg either of these commands:|r"
		)
		DEFAULT_CHAT_FRAME:AddMessage("|cff0066ff dmgst, /dmgaoe, /tankst, /tankaoe !|r")
		DEFAULT_CHAT_FRAME:AddMessage("|cff0066ff¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯|r")
		dmgST:UnregisterEvent("ADDON_LOADED")
	elseif event == "CHAT_MSG_COMBAT_SELF_MISSES" then
		if string.find(arg1, "dodge") then
			dmgST_Settings["dodge"] = GetTime()
		end
	elseif event == "CHAT_MSG_SPELL_DAMAGESHIELDS_ON_SELF" then
		if string.find(arg1, "dodge") then
			dmgST_Settings["dodge"] = GetTime()
		end
	end
end)

SlashCmdList["DMGST_SLASH"] = dmgST.DoShit
SLASH_DMGST_SLASH1 = "/dmgst"
SLASH_DMGST_SLASH2 = "/DMGST"
SlashCmdList["DMGAOE_SLASH"] = dmgAOE.DoShit
SLASH_DMGAOE_SLASH1 = "/dmgaoe"
SLASH_DMGAOE_SLASH2 = "/DMGAOE"
SlashCmdList["TANKST_SLASH"] = tankST.DoShit
SLASH_TANKST_SLASH1 = "/tankst"
SLASH_TANKST_SLASH2 = "/TANKST"
SlashCmdList["TANKAOE_SLASH"] = tankAOE.DoShit
SLASH_TANKAOE_SLASH1 = "/tankaoe"
SLASH_TANKAOE_SLASH2 = "/TANKAOE"
