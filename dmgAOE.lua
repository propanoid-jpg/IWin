IWin = IWin or {}

function IWin:dmgAOE()
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

        -- Overpower on dodge proc (time-sensitive)
        if IWin:HandleOverpower() then
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

        -- Use common charge handler
        if IWin:HandleCharge() then
            return
        end

        -- Use common battle shout handler (out of combat)
        if not UnitAffectingCombat("player") and IWin:HandleBattleShout(false) then
            return
        end

        -- Sweeping Strikes (Battle Stance) - highest priority AOE ability
        if IWin:GetSpell("Sweeping Strikes") and not IWin:OnCooldown("Sweeping Strikes") and UnitMana("player") >= IWin_Settings["RageSweepingMin"] then
            IWin:SwitchStance("Battle Stance")
            c("Sweeping Strikes")
            return
        end

        -- Switch to Berserker Stance for Whirlwind if we have enough rage
        if IWin:GetSpell("Whirlwind") and not IWin:OnCooldown("Whirlwind") and UnitMana("player") >= IWin_Settings["RageWhirlwindMin"] then
            if CheckInteractDistance("target", IWin.CONSTANTS.INTERACT_DISTANCE_MELEE) ~= nil then
                IWin:SwitchStance("Berserker Stance")
                c("Whirlwind")
                return
            end
        end

        -- Stay in Berserker Stance for general DPS (only switch if Sweeping Strikes buff is active)
        local _, _, isBattleStance = GetShapeshiftFormInfo(1)
        if isBattleStance and not IWin:GetBuff("player", "Sweeping Strikes") then
            -- Switch to Berserker if we're in Battle and Sweeping Strikes isn't active
            IWin:SwitchStance("Berserker Stance")
        end

        -- Use common bloodrage handler
        if IWin:HandleBloodrage() then
            return
        end

        -- Use offensive trinkets on cooldown
        IWin:UseTrinkets(true)

        -- Bloodthirst (if Fury spec)
        if IWin:GetSpell("Bloodthirst") and not IWin:OnCooldown("Bloodthirst") and UnitMana("player") >= IWin_Settings["RageBloodthirstMin"] then
            c("Bloodthirst")
            return
        -- Mortal Strike (if Arms spec)
        elseif IWin:GetSpell("Mortal Strike") and not IWin:OnCooldown("Mortal Strike") and UnitMana("player") >= IWin_Settings["RageMortalStrikeMin"] then
            c("Mortal Strike")
            return
        end

        -- Execute phase (20% threshold)
        if (UnitHealth("target") / UnitHealthMax("target")) * 100 <= 20 and UnitMana("player") >= IWin_Settings["RageExecuteMin"] then
            IWin:SwitchStance("Berserker Stance")
            c("Execute")
            return
        end

        local isBoss = IWin:IsBoss()

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

        -- Cleave - primary AOE rage dump (smart queueing with SuperWOW)
        if IWin:GetSpell("Cleave") and UnitMana("player") >= IWin_Settings["RageCleaveMin"] then
            if IWin:ShouldQueueHeroicStrike() then
                c("Cleave")
                return
            end
        end

        -- Heroic Strike as last resort if high rage (smart queueing with SuperWOW)
        if IWin:GetSpell("Heroic Strike") and UnitMana("player") >= IWin_Settings["RageHeroicMin"] then
            if IWin:ShouldQueueHeroicStrike() then
                c("Heroic Strike")
                return
            end
        end
    end
end
