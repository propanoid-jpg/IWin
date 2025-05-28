function dmgAOE:DoShit()
	local c = CastSpellByName
	if UnitClass("player") == "Warrior" then
		if not IWin_Settings["AttackSlot"] then
			IWin_Settings["AttackSlot"] = IWin:GetActionSlot("Attack")
		end
		if not IsCurrentAction(IWin_Settings["AttackSlot"]) then
			UseAction(IWin_Settings["AttackSlot"])
		end
		local _, _, isActive = GetShapeshiftFormInfo(2)
		if isActive then -- if prot stance
			if
				IWin:GetSpell("Bloodrage")
				and UnitAffectingCombat("player")
				and UnitMana("player") < 40
				and not IWin:OnCooldown("Bloodrage")
			then
				c("Bloodrage")
				return
			end
			if IWin:GetSpell("Revenge") and not IWin:OnCooldown("Revenge") and UnitMana("player") > 4 then
				c("Revenge")
				return
			end
			if IWin:GetSpell("Bloodthirst") and not IWin:OnCooldown("Bloodthirst") and UnitMana("player") > 29 then
				c("Bloodthirst")
				return
			end
			if not IWin:GetBuff("target", "Sunder Armor") then
				c("Sunder Armor")
			else
				if IWin:GetBuff("target", "Sunder Armor", 1) < 5 then
					c("Sunder Armor")
				end
			end
			if IWin:GetSpell("Heroic Strike") and UnitMana("player") > 30 then
				c("Heroic Strike")
			end
			return
		end
		--[[ interrupt function, turned off for now
		if IWin_Settings["interrupt"][UnitName("target")] ~= nil and (GetTime()-IWin_Settings["interrupt"][UnitName("target")]) < 2 and CheckInteractDistance("target", 1 ) ~= nil then
			if IWin:GetSpell("Pummel") and not IWin:OnCooldown("Pummel") then
				c("Berserker Stance")
				c("Pummel")
				return
			end
		end
		-- auto use cds, turned off for now
		if IWin:IsBoss(UnitName("target")) and CheckInteractDistance("target", 1 ) ~= nil and (UnitHealth("target")/UnitHealthMax("target")) < 0.95 then 
			if IWin:GetSpell("Death Wish") and not IWin:OnCooldown("Death Wish") then
				c("Death Wish")
			end
		end--]]
		if (UnitHealth("target") / UnitHealthMax("target")) <= 0.2 and UnitMana("player") > 9 then
			c("Execute")
			return
		end
		--]]
		if GetTime() - IWin_Settings["dodge"] < 5 then
			if
				IWin:GetSpell("Overpower")
				and not IWin:OnCooldown("Overpower")
				and UnitMana("player") < 30
				and UnitMana("player") > 4
			then
				c("Battle Stance")
				c("Overpower")
			end
		end
		c("Berserker Stance")
		if IWin:GetSpell("Battle Shout") and not IWin:GetBuff("player", "Battle Shout") then
			if
				UnitExists("target")
				and (UnitHealth("target") / UnitHealthMax("target")) > 0.2
				and UnitMana("player") > 9
			then
				c("Battle Shout")
				return
			elseif not UnitExists("target") and UnitMana("player") > 9 then
				c("Battle Shout")
				return
			end
		end
		if
			IWin:GetSpell("Bloodrage")
			and UnitAffectingCombat("player")
			and UnitMana("player") < 40
			and not IWin:OnCooldown("Bloodrage")
		then
			c("Bloodrage")
			return
		end
		if IWin:GetSpell("Bloodthirst") and not IWin:OnCooldown("Bloodthirst") and UnitMana("player") > 29 then
			c("Bloodthirst")
			return
		elseif IWin:GetSpell("Whirlwind") and not IWin:OnCooldown("Whirlwind") and UnitMana("player") > 29 then
			if CheckInteractDistance("target", 1) ~= nil then
				c("Whirlwind")
				return
			end
		elseif IWin:GetSpell("Heroic Strike") and UnitMana("player") > 29 then
			c("Heroic Strike")
		end
	end
end
