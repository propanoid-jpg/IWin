IWin = IWin or {}

function IWin:tankST()
    -- Error handling: validate IWin_Settings exists
    if not IWin_Settings or type(IWin_Settings) ~= "table" then
        DEFAULT_CHAT_FRAME:AddMessage("|cffff0000[IWin Error] IWin_Settings not initialized|r")
        return
    end

    -- Check reactive abilities BEFORE throttling (don't miss procs/interrupts)
    -- These have their own separate, faster throttles

    -- Validate player class
    local playerClass = UnitClass("player")
    if not playerClass or playerClass ~= "Warrior" then
        return
    end

    -- Require valid target for reactive abilities
    if IWin:ValidateTarget() then
        -- Interrupt enemy casting (SuperWOW only) - check first, most time-sensitive
        if IWin:HandleInterrupt() then
            return
        end

        -- Overpower (dodge-based, time-sensitive) - switch to Battle Stance, cast, return to Defensive
        if IWin:HandleOverpower() then
            return
        end

        -- Revenge (proc-based, time-sensitive)
        if IWin:HandleRevenge() then
            return
        end
    end

    -- Throttle normal rotation execution
    if IWin:ShouldThrottle() then
        return
    end

    local c = CastSpellByName
    if playerClass == "Warrior" then
        -- Require valid target for combat abilities
        if not IWin:ValidateTarget() then
            return
        end

        -- Use common auto-attack handler
        IWin:HandleAutoAttack()

        -- Use common battle shout handler (out of combat)
        if not UnitAffectingCombat("player") and IWin:HandleBattleShout(false) then
            return
        end

        -- Use common charge handler
        if IWin:HandleCharge() then
            return
        end

        if IWin:GetSpell("Last Stand") and not IWin:OnCooldown("Last Stand") and (UnitHealth("player") / UnitHealthMax("player")) * 100 <= IWin_Settings["LastStandThreshold"] and UnitAffectingCombat("player") then
            c("Last Stand")
            return
        end

        -- Execute phase for low health targets (20% threshold)
        if (UnitHealth("target") / UnitHealthMax("target")) * 100 <= 20 and UnitMana("player") >= IWin_Settings["RageExecuteMin"] then
            IWin:SwitchStance("Berserker Stance")
            c("Execute")
            return
        end

        -- Switch to Defensive Stance for tank abilities
        IWin:SwitchStance("Defensive Stance")

        -- DEMORALIZING SHOUT: OPENER - establish threat baseline before DPS starts
        -- This is critical for initial aggro in Turtle WOW
        if IWin:GetSpell("Demoralizing Shout") and not IWin:OnCooldown("Demoralizing Shout") and UnitMana("player") >= IWin_Settings["RageDemoShoutMin"] then
            if not IWin:GetDebuff("target", "Demoralizing Shout") or IWin:CheckDebuffDuration("Demoralizing Shout", IWin.CONSTANTS.DEMO_SHOUT_DURATION, IWin_Settings["RefreshDemoShout"]) then
                c("Demoralizing Shout")
                IWin_Settings.DebuffTracker["Demoralizing Shout"] = { startTime = GetTime(), duration = IWin.CONSTANTS.DEMO_SHOUT_DURATION }
                return
            end
        end

        -- SHIELD BLOCK: High priority for mitigation + Revenge proc enabler
        if IWin_Settings["AutoShieldBlock"] and IWin:GetSpell("Shield Block") and not IWin:OnCooldown("Shield Block") and UnitMana("player") >= IWin_Settings["RageShieldBlockMin"] then
            c("Shield Block")
            return
        end

        -- SHIELD BASH: 180 bonus threat at all levels - extremely efficient
        if IWin_Settings["AutoShieldBash"] and IWin:GetSpell("Shield Bash") and not IWin:OnCooldown("Shield Bash") and UnitMana("player") >= IWin_Settings["RageShieldBashMin"] then
            c("Shield Bash")
            return
        end

        -- SHIELD SLAM: High single-target threat (spam on cooldown)
        if IWin:GetSpell("Shield Slam") and not IWin:OnCooldown("Shield Slam") and UnitMana("player") >= IWin_Settings["RageShieldSlamMin"] then
            c("Shield Slam(Rank 4)")
            return
        end

        -- BLOODRAGE: Rage generation
        if IWin:HandleBloodrage() then
            return
        end

        -- SUNDER ARMOR: SPAM THIS - 10 rage cost on Turtle WOW makes this spammable filler
        -- "Sundering in Defensive Stance generates LOADS of threat"
        local isBoss = IWin:IsBoss()
        local sunderTargetStacks = isBoss and IWin_Settings["SunderStacksBoss"] or IWin_Settings["SunderStacksTrash"]

        if UnitMana("player") >= IWin_Settings["RageSunderMin"] and not IWin:OnCooldown("Sunder Armor") then
            local sunderStacks = IWin:GetDebuff("target", "Sunder Armor", 1)
            -- Ramp to target stacks first
            if not sunderStacks or sunderStacks < sunderTargetStacks then
                c("Sunder Armor")
                IWin_Settings.DebuffTracker["Sunder Armor"] = { startTime = GetTime(), duration = IWin.CONSTANTS.SUNDER_ARMOR_DURATION }
                return
            end
        end

        -- BLOODTHIRST: Fury/Prot threat generation
        if IWin:GetSpell("Bloodthirst") and not IWin:OnCooldown("Bloodthirst") and UnitMana("player") >= IWin_Settings["RageBloodthirstMin"] then
            IWin:SwitchStance("Berserker Stance")
            c("Bloodthirst")
            return
        end

        -- Switch back to Defensive Stance
        IWin:SwitchStance("Defensive Stance")

        -- BATTLE SHOUT: In-combat threat generation
        if IWin:HandleBattleShout(true) then
            return
        end

        -- SUNDER ARMOR SPAM: Refresh at max stacks as filler for continuous threat
        if UnitMana("player") >= IWin_Settings["RageSunderMin"] and not IWin:OnCooldown("Sunder Armor") then
            if IWin:CheckDebuffDuration("Sunder Armor", IWin.CONSTANTS.SUNDER_ARMOR_DURATION, IWin_Settings["RefreshSunder"]) then
                c("Sunder Armor")
                IWin_Settings.DebuffTracker["Sunder Armor"] = { startTime = GetTime(), duration = IWin.CONSTANTS.SUNDER_ARMOR_DURATION }
                return
            end
        end

        -- MORTAL STRIKE: Arms threat generation (lower priority than BT)
        if IWin:GetSpell("Mortal Strike") and not IWin:OnCooldown("Mortal Strike") and UnitMana("player") >= IWin_Settings["RageMortalStrikeMin"] then
            IWin:SwitchStance("Berserker Stance")
            c("Mortal Strike")
            return
        end

        -- Switch back to Defensive Stance
        IWin:SwitchStance("Defensive Stance")

        -- HEROIC STRIKE: Rage dump (inefficient, use only with excess rage)
        if IWin:GetSpell("Heroic Strike") and UnitMana("player") >= IWin_Settings["RageHeroicMin"] then
            c("Heroic Strike")
            return
        end

        -- REND: Low priority DoT
        if IWin_Settings["AutoRend"] and UnitMana("player") >= IWin_Settings["RageRendMin"] then
            local shouldApplyRend = isBoss or not IWin_Settings["SkipRendOnTrash"]
            if shouldApplyRend then
                if not IWin:GetDebuff("target", "Rend") or IWin:CheckDebuffDuration("Rend", IWin.CONSTANTS.REND_DURATION, IWin_Settings["RefreshRend"]) then
                    c("Rend")
                    IWin_Settings.DebuffTracker["Rend"] = { startTime = GetTime(), duration = IWin.CONSTANTS.REND_DURATION }
                    return
                end
            end
        end
    end
end
