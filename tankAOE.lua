IWin = IWin or {}

function IWin:tankAOE()
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
        if IWin:GetSpell("Battle Shout") and not IWin:GetBuff("player", "Battle Shout") and not UnitAffectingCombat("player") then
            if UnitExists("target") and (UnitHealth("target") / UnitHealthMax("target")) > 0.2 and UnitMana("player") > 9
            then
                c("Battle Shout")
                return
            elseif not UnitExists("target") and UnitMana("player") > 9 then
                c("Battle Shout")
                return
            end
        end
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
        --[[
        if GetTime() - IWin_Settings["dodge"] < 5 then
            if IWin:GetSpell("Overpower") and not IWin:OnCooldown("Overpower") and UnitMana("player") < 30 and UnitMana("player") > 4 then
                c("Battle Stance")
                c("Overpower")
            end
        end
        --]]
        if IWin:GetSpell("Last Stand") and not IWin:OnCooldown("Last Stand") and (UnitHealth("player") / UnitHealthMax("player")) <= 0.2 and UnitAffectingCombat("player") then
            c("Last Stand")
            return
        end
        if IWin:GetSpell("Taunt") and not IWin:OnCooldown("Taunt") and TargetUnit("targettarget") ~= "Sesshi" then
            c("Taunt")
            return
        end
        if IWin:GetSpell("Thunder Clap") and not IWin:OnCooldown("Thunder Clap") and UnitMana("player") > 19 then
            c("Thunder Clap")
            return
        end
        if IWin:GetSpell("Whirlwind") and not IWin:OnCooldown("Whirlwind") and UnitMana("player") > 19 and UnitMana("player") < 30 then
            c("Whirlwind")
            return
        end
        c("Defensive Stance")
        if IWin:GetSpell("Revenge") and not IWin:OnCooldown("Revenge") and UnitMana("player") > 4 then
            c("Revenge")
        end
        if IWin:GetSpell("Demoralizing Shout") and not IWin:OnCooldown("Demoralizing Shout") and not IWin:GetBuff("target", "Demoralizing Shout") and UnitMana("player") > 25 then
            c("Demoralizing Shout")
            return
        end
        if IWin:GetSpell("Shield Slam") and not IWin:OnCooldown("Shield Slam") and UnitMana("player") > 19 then
            c("Shield Slam")
            return
        end
        if IWin:GetSpell("Cleave") and not IWin:OnCooldown("Cleave") and UnitMana("player") > 59 then
            c("Cleave")
            return
        end
        if IWin:GetSpell("Concussion Blow") and not IWin:OnCooldown("Concussion Blow") and UnitHealth("target") <= 20000 and UnitMana("player") > 14 then
            c("Concussion Blow")
            return
        end
        if IWin:GetSpell("Battle Shout") and not IWin:GetBuff("player", "Battle Shout") and UnitMana("player") > 29 then
            c("Battle Shout")
        end
        if UnitMana("player") > 29 then
            if not IWin:GetBuff("target", "Sunder Armor") then
                c("Sunder Armor")
            else
                if IWin:GetBuff("target", "Sunder Armor", 1) < 5 then
                    c("Sunder Armor")
                end
            end
        end
        --[[
        if IWin:GetSpell("Battle Shout") and not IWin:GetBuff("player", "Battle Shout") then
            if UnitExists("target") and (UnitHealth("target") / UnitHealthMax("target")) > 0.2 and UnitMana("player") > 9
            then
                c("Battle Shout")
            elseif not UnitExists("target") and UnitMana("player") > 9 then
                c("Battle Shout")
            end
        end
        --]]
        --Dump some rage before entering Berserker Stance
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
        elseif IWin:GetSpell("Heroic Strike") and UnitMana("player") > 80 and not IWin:OnCooldown("Sunder Armor") then
            c("Heroic Strike")
        end
    end
end
