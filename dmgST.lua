IWin = IWin or {}

function IWin:dmgST()
    local c = CastSpellByName
    if UnitClass("player") == "Warrior" then
        if not IWin_Settings["AttackSlot"] then
            IWin_Settings["AttackSlot"] = IWin:GetActionSlot("Attack")
        end
        if not IsCurrentAction(IWin_Settings["AttackSlot"]) then
            UseAction(IWin_Settings["AttackSlot"])
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
        -- Hopefully improve this in the future, this checks for charge range 10 to 28 instead of 8-25, dont swap stance and charge if above 50 rage. Charge if already in battle stance
        local _, _, isActive = GetShapeshiftFormInfo(1)
        if IWin:GetSpell("Charge") and not UnitAffectingCombat("player") and not IWin:OnCooldown("Charge") and CheckInteractDistance("target", 3) == nil and CheckInteractDistance("target", 4) == 1 then
            if UnitMana("player") < 51 then
                c("Battle Stance")
                c("Charge")
                return
            elseif isActive then
                c("Charge")
                return
            end
        end
        if (UnitHealth("target") / UnitHealthMax("target")) <= 0.2 and UnitMana("player") > 9 then
            c("Berserker Stance")
            c("Execute")
            return
        end
        -- if UnitIsPlayer("target") and not IWin:GetBuff("target", "Hamstring") then
        --     c("Hamstring")
        --     return
        -- end
        --[[
        if GetTime() - IWin_Settings["dodge"] < 5 then
            if IWin:GetSpell("Overpower") and not IWin:OnCooldown("Overpower") and UnitMana("player") < 30 and UnitMana("player") > 4 then
                c("Battle Stance")
                c("Overpower")
            end
        end
        --]]
        if IWin:GetSpell("Battle Shout") and not IWin:GetBuff("player", "Battle Shout") then
            if UnitExists("target") and (UnitHealth("target") / UnitHealthMax("target")) > 0.2 and UnitMana("player") > 9
            then
                c("Battle Shout")
                return
            elseif not UnitExists("target") and UnitMana("player") > 9 then
                c("Battle Shout")
                return
            end
        end
        --Dump some rage before entering Berserker Stance
        if isActive and UnitMana("player") < 30 then
            c("Berserker Stance")
        end
        if IWin:GetSpell("Bloodrage") and UnitAffectingCombat("player") and UnitMana("player") < 30 and not IWin:OnCooldown("Bloodrage") then
            c("Bloodrage")
            return
        end
        if IWin:GetSpell("Bloodthirst") and not IWin:OnCooldown("Bloodthirst") and UnitMana("player") > 29 then
            c("Bloodthirst")
            return
        elseif IWin:GetSpell("Mortal Strike") and not IWin:OnCooldown("Mortal Strike") and UnitMana("player") > 29 then
            c("Mortal Strike")
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
