IWin = IWin or {}

--[[
    DPS Single Target Rotation Priority:
    1. Charge (out of combat, 8-25 yards)
    2. Overpower (on dodge proc within 5 seconds)
    3. Execute (target below 20% health)
    4. Battle Shout (if missing buff)
    5. Bloodrage (rage < 30)
    6. Bloodthirst (30+ rage, Fury spec)
    7. Mortal Strike (30+ rage, Arms spec)
    8. Whirlwind (30+ rage, melee range)
    9. Heroic Strike (30+ rage)
    10. Rend (if missing or < 5s remaining)
]]

function IWin:dmgST()
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

        -- Enable auto-attack if not already attacking
        IWin:HandleAutoAttack()

        -- PRIORITY 1: Charge if out of combat and in range (8-25 yards with SuperWOW)
        if IWin:HandleCharge() then
            return
        end

        -- PRIORITY 3: Execute phase (20% threshold)
        if (UnitHealth("target") / UnitHealthMax("target")) * 100 <= 20 and UnitMana("player") >= IWin_Settings["RageExecuteMin"] then
            IWin:SwitchStance("Berserker Stance")
            c("Execute")
            return
        end

        -- PRIORITY 4: Battle Shout if buff is missing (out of combat)
        if not UnitAffectingCombat("player") and IWin:HandleBattleShout(false) then
            return
        end

        -- Switch to Berserker Stance for DPS when not in execute range
        local _, _, isBattleStance = GetShapeshiftFormInfo(1)
        if isBattleStance and (UnitHealth("target") / UnitHealthMax("target")) * 100 > 20 then
            IWin:SwitchStance("Berserker Stance")
        end

        local isBoss = IWin:IsBoss()

        -- PRIORITY 5: Bloodrage for rage generation
        if IWin:HandleBloodrage() then
            return
        end

        -- Use offensive trinkets on cooldown
        IWin:UseTrinkets(true)

        -- PRIORITY 6: Bloodthirst (Fury spec main attack, 6s CD)
        if IWin:GetSpell("Bloodthirst") and not IWin:OnCooldown("Bloodthirst") and UnitMana("player") >= IWin_Settings["RageBloodthirstMin"] then
            c("Bloodthirst")
            return
        -- PRIORITY 7: Mortal Strike (Arms spec main attack, 6s CD)
        elseif IWin:GetSpell("Mortal Strike") and not IWin:OnCooldown("Mortal Strike") and UnitMana("player") >= IWin_Settings["RageMortalStrikeMin"] then
            c("Mortal Strike")
            return
        -- PRIORITY 8: Whirlwind (10s CD, requires melee range)
        elseif IWin:GetSpell("Whirlwind") and not IWin:OnCooldown("Whirlwind") and UnitMana("player") >= IWin_Settings["RageWhirlwindMin"] then
            if CheckInteractDistance("target", IWin.CONSTANTS.INTERACT_DISTANCE_MELEE) ~= nil then
                IWin:SwitchStance("Berserker Stance")
                c("Whirlwind")
                return
            end
        end

        -- PRIORITY 9: Rend (DoT, skip on trash if configured)
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

        -- PRIORITY 10: Heroic Strike (smart queueing with SuperWOW)
        if IWin:GetSpell("Heroic Strike") and UnitMana("player") >= IWin_Settings["RageHeroicMin"] then
            if IWin:ShouldQueueHeroicStrike() then
                c("Heroic Strike")
                return
            end
        end
    end
end
