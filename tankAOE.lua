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

        -- DEMORALIZING SHOUT: FIRST PRIORITY - establish threat baseline before DPS starts
        -- Critical for AOE threat in Turtle WOW: "use Demo Shout BEFORE anyone else starts attacking"
        if IWin:GetSpell("Demoralizing Shout") and not IWin:OnCooldown("Demoralizing Shout") and UnitMana("player") >= IWin_Settings["RageDemoShoutMin"] then
            if not IWin:GetDebuff("target", "Demoralizing Shout") or IWin:CheckDebuffDuration("Demoralizing Shout", IWin.CONSTANTS.DEMO_SHOUT_DURATION, IWin_Settings["RefreshDemoShout"]) then
                c("Demoralizing Shout")
                IWin_Settings.DebuffTracker["Demoralizing Shout"] = { startTime = GetTime(), duration = IWin.CONSTANTS.DEMO_SHOUT_DURATION }
                return
            end
        end

        -- THUNDER CLAP: PRIMARY AOE THREAT GENERATOR
        -- "Thunder Clap is your main AOE threat generator and should be your priority"
        -- Turtle WOW: Available in Defensive Stance (custom change)
        local skipThunderClap = IWin_Settings["SkipThunderClapWithThunderfury"] and IWin:GetDebuff("target", "Thunderfury")
        if IWin:GetSpell("Thunder Clap") and not IWin:OnCooldown("Thunder Clap") and not skipThunderClap and UnitMana("player") >= IWin_Settings["RageThunderClapMin"] then
            if not IWin:GetDebuff("target", "Thunder Clap") or IWin:CheckDebuffDuration("Thunder Clap", IWin.CONSTANTS.THUNDER_CLAP_DURATION, IWin_Settings["RefreshThunderClap"]) then
                c("Thunder Clap")
                IWin_Settings.DebuffTracker["Thunder Clap"] = { startTime = GetTime(), duration = IWin.CONSTANTS.THUNDER_CLAP_DURATION }
                return
            end
        end

        -- BATTLE SHOUT: Secondary AOE threat (cannot be resisted, hits all nearby)
        -- Reduced throttle from 10s to 3s for better AOE threat generation
        if IWin:GetSpell("Battle Shout") and UnitMana("player") >= IWin_Settings["RageShoutCombatMin"] then
            local needsBuff = not IWin:GetBuff("player", "Battle Shout")
            local aoeMode = IWin_Settings["BattleShoutAOEMode"]

            -- Check if enough time has passed since last Battle Shout (throttle to 3s)
            local lastShoutTime = IWin_Settings.DebuffTracker["Battle Shout"] and IWin_Settings.DebuffTracker["Battle Shout"].startTime or 0
            local timeSinceLastShout = GetTime() - lastShoutTime
            local canShoutAgain = timeSinceLastShout >= 3

            if needsBuff or (aoeMode and canShoutAgain) then
                c("Battle Shout")
                IWin_Settings.DebuffTracker["Battle Shout"] = { startTime = GetTime(), duration = IWin.CONSTANTS.BATTLE_SHOUT_DURATION }
                return
            end
        end

        -- SHIELD BASH: High threat on skull/priority target (180 bonus threat)
        if IWin_Settings["AutoShieldBash"] and IWin:GetSpell("Shield Bash") and not IWin:OnCooldown("Shield Bash") and UnitMana("player") >= IWin_Settings["RageShieldBashMin"] then
            c("Shield Bash")
            return
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

        -- SHIELD SLAM: Additional single-target threat on focus target
        if IWin:GetSpell("Shield Slam") and not IWin:OnCooldown("Shield Slam") and UnitMana("player") >= IWin_Settings["RageShieldSlamMin"] then
            c("Shield Slam(Rank 4)")
            return
        end

        -- CONCUSSION BLOW: Additional threat when available
        if IWin:GetSpell("Concussion Blow") and not IWin:OnCooldown("Concussion Blow") and UnitMana("player") >= IWin_Settings["RageConcussionBlowMin"] then
            c("Concussion Blow(Rank 4)")
            return
        end

        -- WHIRLWIND: Additional AOE damage when available
        if IWin:GetSpell("Whirlwind") and not IWin:OnCooldown("Whirlwind") and UnitMana("player") >= IWin_Settings["RageWhirlwindMin"] then
            IWin:SwitchStance("Berserker Stance")
            c("Whirlwind")
            IWin:SwitchStance("Defensive Stance")
            return
        end
    end
end
