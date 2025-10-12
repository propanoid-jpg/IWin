IWin = IWin or {}

function IWin:tankAOE()
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

        -- Execute phase for low health targets (20% threshold)
        if (UnitHealth("target") / UnitHealthMax("target")) * 100 <= 20 and UnitMana("player") >= IWin_Settings["RageExecuteMin"] then
            IWin:SwitchStance("Berserker Stance")
            c("Execute")
            return
        end

        -- Switch to Defensive Stance for tank abilities
        IWin:SwitchStance("Defensive Stance")

        -- BATTLE SHOUT: Primary AOE threat generator (1.12 meta)
        -- Spam this for AOE threat, but throttle to every 10 seconds minimum
        if IWin:GetSpell("Battle Shout") and UnitMana("player") >= IWin_Settings["RageShoutCombatMin"] then
            local needsBuff = not IWin:GetBuff("player", "Battle Shout")
            local aoeMode = IWin_Settings["BattleShoutAOEMode"]

            -- Check if enough time has passed since last Battle Shout (throttle to 10s)
            local lastShoutTime = IWin_Settings.DebuffTracker["Battle Shout"] and IWin_Settings.DebuffTracker["Battle Shout"].startTime or 0
            local timeSinceLastShout = GetTime() - lastShoutTime
            local canShoutAgain = timeSinceLastShout >= 10

            if needsBuff or (aoeMode and canShoutAgain) then
                c("Battle Shout")
                IWin_Settings.DebuffTracker["Battle Shout"] = { startTime = GetTime(), duration = IWin.CONSTANTS.BATTLE_SHOUT_DURATION }
                return
            end
        end

        -- DEMORALIZING SHOUT: Damage reduction + secondary threat
        if IWin:GetSpell("Demoralizing Shout") and not IWin:OnCooldown("Demoralizing Shout") and UnitMana("player") >= IWin_Settings["RageDemoShoutMin"] then
            if not IWin:GetDebuff("target", "Demoralizing Shout") or IWin:CheckDebuffDuration("Demoralizing Shout", IWin.CONSTANTS.DEMO_SHOUT_DURATION, IWin_Settings["RefreshDemoShout"]) then
                c("Demoralizing Shout")
                IWin_Settings.DebuffTracker["Demoralizing Shout"] = { startTime = GetTime(), duration = IWin.CONSTANTS.DEMO_SHOUT_DURATION }
                return
            end
        end

        -- THUNDER CLAP: Attack speed reduction debuff
        local skipThunderClap = IWin_Settings["SkipThunderClapWithThunderfury"] and IWin:GetDebuff("target", "Thunderfury")
        if IWin:GetSpell("Thunder Clap") and not IWin:OnCooldown("Thunder Clap") and not skipThunderClap and UnitMana("player") >= IWin_Settings["RageThunderClapMin"] then
            if not IWin:GetDebuff("target", "Thunder Clap") or IWin:CheckDebuffDuration("Thunder Clap", IWin.CONSTANTS.THUNDER_CLAP_DURATION, IWin_Settings["RefreshThunderClap"]) then
                c("Thunder Clap")
                IWin_Settings.DebuffTracker["Thunder Clap"] = { startTime = GetTime(), duration = IWin.CONSTANTS.THUNDER_CLAP_DURATION }
                return
            end
        end

        -- CLEAVE: Primary AOE rage dump
        if IWin:GetSpell("Cleave") and UnitMana("player") >= IWin_Settings["RageCleaveMin"] then
            c("Cleave")
            return
        end

        -- BLOODRAGE: Rage generation
        if IWin:HandleBloodrage() then
            return
        end

        -- CONCUSSION BLOW: Additional threat when available
        if IWin:GetSpell("Concussion Blow") and not IWin:OnCooldown("Concussion Blow") and UnitMana("player") >= IWin_Settings["RageConcussionBlowMin"] then
            IWin:SwitchStance("Berserker Stance")
            c("Concussion Blow")
            return
        end

        -- WHIRLWIND: Additional AOE damage when available
        if IWin:GetSpell("Whirlwind") and not IWin:OnCooldown("Whirlwind") and UnitMana("player") >= IWin_Settings["RageWhirlwindMin"] then
            IWin:SwitchStance("Berserker Stance")
            c("Whirlwind")
            return
        end
    end
end
