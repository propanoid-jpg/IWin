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

        -- Log boss detection changes (no spam)
        IWin:LogBossDetection()

        -- Boss-aware thresholds (declare early for use throughout rotation)
        local isBoss = IWin:IsBoss()
        local executeThreshold = isBoss and IWin_Settings["ExecuteThresholdBoss"] or IWin_Settings["ExecuteThresholdTrash"]
        local sunderTargetStacks = isBoss and IWin_Settings["SunderStacksBoss"] or IWin_Settings["SunderStacksTrash"]

        -- Execute phase for low health targets (boss-aware threshold)
        if (UnitHealth("target") / UnitHealthMax("target")) * 100 <= executeThreshold and UnitMana("player") >= IWin_Settings["RageExecuteMin"] then
            IWin:SwitchStance("Berserker Stance")
            c("Execute")
            return
        end

        -- Concussion Blow: High priority threat generator (requires Berserker Stance)
        if IWin:GetSpell("Concussion Blow") and not IWin:OnCooldown("Concussion Blow") and UnitMana("player") >= IWin_Settings["RageConcussionBlowMin"] then
            IWin:SwitchStance("Berserker Stance")
            c("Concussion Blow")
            return
        end

        IWin:SwitchStance("Defensive Stance")

        -- Shield Slam priority: use it if Shield Block buff is active
        if IWin:GetSpell("Shield Slam") and not IWin:OnCooldown("Shield Slam") and UnitMana("player") >= IWin_Settings["RageShieldSlamMin"] then
            if IWin:GetBuff("player", "Shield Block") then
                c("Shield Slam")
                return
            end
        end

        -- Shield Block usage: Use when Shield Slam is available and we don't have the Shield Block buff
        if IWin_Settings["AutoShieldBlock"] and IWin:GetSpell("Shield Block") and not IWin:OnCooldown("Shield Block") and not IWin:OnCooldown("Sunder Armor") and UnitMana("player") >= IWin_Settings["RageShieldBlockMin"] then
            if IWin:GetSpell("Shield Slam") and not IWin:OnCooldown("Shield Slam") and not IWin:GetBuff("player", "Shield Block") then
                c("Shield Block")
                return
            end
        end

        -- SUNDER ARMOR RAMP-UP: Highest priority after main threat abilities (Revenge/Shield Slam)
        -- This ensures we stack sunders ASAP before applying other debuffs
        if UnitMana("player") >= IWin_Settings["RageSunderMin"] and not IWin:OnCooldown("Sunder Armor") then
            local sunderStacksCheck = IWin:GetDebuff("target", "Sunder Armor", 1)
            if not sunderStacksCheck or sunderStacksCheck < sunderTargetStacks then
                c("Sunder Armor")
                IWin_Settings.DebuffTracker["Sunder Armor"] = { startTime = GetTime(), duration = IWin.CONSTANTS.SUNDER_ARMOR_DURATION }
                return
            end
        end

        local skipThunderClap = IWin_Settings["SkipThunderClapWithThunderfury"] and IWin:GetDebuff("target", "Thunderfury")
        if IWin:GetSpell("Thunder Clap") and not IWin:OnCooldown("Thunder Clap") and not skipThunderClap and UnitMana("player") >= IWin_Settings["RageThunderClapMin"] then
            if not IWin:GetDebuff("target", "Thunder Clap") or IWin:CheckDebuffDuration("Thunder Clap", IWin.CONSTANTS.THUNDER_CLAP_DURATION, IWin_Settings["RefreshThunderClap"]) then
                c("Thunder Clap")
                IWin_Settings.DebuffTracker["Thunder Clap"] = { startTime = GetTime(), duration = IWin.CONSTANTS.THUNDER_CLAP_DURATION }
                return
            end
        end
        if IWin:GetSpell("Demoralizing Shout") and not IWin:OnCooldown("Demoralizing Shout") and UnitMana("player") >= IWin_Settings["RageDemoShoutMin"] then
            if not IWin:GetDebuff("target", "Demoralizing Shout") or IWin:CheckDebuffDuration("Demoralizing Shout", IWin.CONSTANTS.DEMO_SHOUT_DURATION, IWin_Settings["RefreshDemoShout"]) then
                c("Demoralizing Shout")
                IWin_Settings.DebuffTracker["Demoralizing Shout"] = { startTime = GetTime(), duration = IWin.CONSTANTS.DEMO_SHOUT_DURATION }
                return
            end
        end
        -- Use common battle shout handler (in combat)
        if IWin:HandleBattleShout(true) then
            return
        end

        -- Sunder refresh: maintain at max stacks by refreshing when duration is low
        if UnitMana("player") >= IWin_Settings["RageSunderMin"] and not IWin:OnCooldown("Sunder Armor") then
            local sunderStacksCheck = IWin:GetDebuff("target", "Sunder Armor", 1)
            if sunderStacksCheck and sunderStacksCheck >= sunderTargetStacks and IWin:CheckDebuffDuration("Sunder Armor", IWin.CONSTANTS.SUNDER_ARMOR_DURATION, IWin_Settings["RefreshSunder"]) then
                -- At max stacks, refresh when duration is low
                c("Sunder Armor")
                IWin_Settings.DebuffTracker["Sunder Armor"] = { startTime = GetTime(), duration = IWin.CONSTANTS.SUNDER_ARMOR_DURATION }
                return
            end
        end

        -- Use common bloodrage handler
        if IWin:HandleBloodrage() then
            return
        end

        -- Rend: maintain DoT (skip on trash if configured)
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

        -- Filler DPS abilities only when Sunder is at max stacks and all debuffs are up
        local sunderStacks = IWin:GetDebuff("target", "Sunder Armor", 1)
        if sunderStacks and sunderStacks >= sunderTargetStacks then
            if IWin:GetSpell("Bloodthirst") and not IWin:OnCooldown("Bloodthirst") and UnitMana("player") >= IWin_Settings["RageBloodthirstMin"] then
                c("Bloodthirst")
                return
            elseif IWin:GetSpell("Mortal Strike") and not IWin:OnCooldown("Mortal Strike") and UnitMana("player") >= IWin_Settings["RageMortalStrikeMin"] then
                c("Mortal Strike")
                return
            elseif IWin:GetSpell("Heroic Strike") and UnitMana("player") >= IWin_Settings["RageHeroicMin"] then
                c("Heroic Strike")
                return
            end
        end
    end
end
