--[[
#######################################
# IWin by Atreyyo @ VanillaGaming.org #
# Forked by Bear-LB @ github.com #
#######################################
]]
--
IWin = IWin or {}

IWinFrame = CreateFrame("frame", nil, UIParent)
IWinFrame.t = CreateFrame("GameTooltip", "IWin_T", UIParent, "GameTooltipTemplate")
IWin_Settings = {
	["dodge"] = 0,
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

SlashCmdList["DMGST_SLASH"] = IWin.dmgST
SLASH_DMGST_SLASH1 = "/dmgst"
SlashCmdList["DMGAOE_SLASH"] = IWin.dmgAOE
SLASH_DMGAOE_SLASH1 = "/dmgaoe"
SlashCmdList["TANKST_SLASH"] = IWin.tankST
SLASH_TANKST_SLASH1 = "/tankst"
SlashCmdList["TANKAOE_SLASH"] = IWin.tankAOE
SLASH_TANKAOE_SLASH1 = "/tankaoe"
