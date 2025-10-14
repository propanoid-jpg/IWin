--[[
	Mock WoW API for External Testing

	This file provides mock implementations of WoW API functions
	to allow testing addon logic outside of the game client.

	Usage:
		require("tests/mock_wow_api")
		-- Now you can call WoW API functions like GetTime(), UnitExists(), etc.
]]

-- Global state for mocks
_G.WoWMockState = {
	time = 0,
	target = {
		exists = true,
		name = "Test Target",
		classification = "elite",
		level = 60,
		health = 5000,
		healthMax = 10000,
		isDead = false,
		canAttack = true,
		mana = 100,
		manaMax = 100
	},
	player = {
		level = 60,
		class = "Warrior",
		health = 5000,
		healthMax = 5000,
		mana = 50,
		manaMax = 100,
		inCombat = false
	},
	spellbook = {
		["Charge"] = {id = 1, known = true},
		["Battle Shout"] = {id = 2, known = true},
		["Bloodrage"] = {id = 3, known = true},
		["Overpower"] = {id = 4, known = true},
		["Revenge"] = {id = 5, known = true},
		["Shield Slam"] = {id = 6, known = true},
		["Sunder Armor"] = {id = 7, known = true}
	},
	buffs = {},
	debuffs = {},
	stance = 1 -- 1=Battle, 2=Defensive, 3=Berserker
}

-- Helper to reset mock state
function _G.ResetWoWMockState()
	_G.WoWMockState = {
		time = 0,
		target = {
			exists = true,
			name = "Test Target",
			classification = "elite",
			level = 60,
			health = 5000,
			healthMax = 10000,
			isDead = false,
			canAttack = true,
			mana = 100,
			manaMax = 100
		},
		player = {
			level = 60,
			class = "Warrior",
			health = 5000,
			healthMax = 5000,
			mana = 50,
			manaMax = 100,
			inCombat = false
		},
		spellbook = {
			["Charge"] = {id = 1, known = true},
			["Battle Shout"] = {id = 2, known = true},
			["Bloodrage"] = {id = 3, known = true},
			["Overpower"] = {id = 4, known = true},
			["Revenge"] = {id = 5, known = true},
			["Shield Slam"] = {id = 6, known = true},
			["Sunder Armor"] = {id = 7, known = true}
		},
		buffs = {},
		debuffs = {},
		stance = 1
	}
end

-- ============================================================================
-- CHAT FRAME MOCKS
-- ============================================================================

_G.DEFAULT_CHAT_FRAME = {
	AddMessage = function(msg)
		-- Strip color codes for cleaner output
		local cleaned = string.gsub(msg, "|c%x%x%x%x%x%x%x%x", "")
		cleaned = string.gsub(cleaned, "|r", "")
		print(cleaned)
	end
}

-- ============================================================================
-- TIME FUNCTIONS
-- ============================================================================

_G.GetTime = function()
	return _G.WoWMockState.time
end

-- Helper to advance time
function _G.AdvanceTime(seconds)
	_G.WoWMockState.time = _G.WoWMockState.time + seconds
end

-- ============================================================================
-- UNIT FUNCTIONS
-- ============================================================================

_G.UnitExists = function(unit)
	if unit == "player" then
		return true
	elseif unit == "target" then
		return _G.WoWMockState.target.exists
	end
	return false
end

_G.UnitName = function(unit)
	if unit == "player" then
		return "Player"
	elseif unit == "target" then
		return _G.WoWMockState.target.name
	end
	return "Unknown"
end

_G.UnitClass = function(unit)
	if unit == "player" then
		return _G.WoWMockState.player.class
	end
	return "Unknown"
end

_G.UnitClassification = function(unit)
	if unit == "target" then
		return _G.WoWMockState.target.classification
	end
	return "normal"
end

_G.UnitLevel = function(unit)
	if unit == "player" then
		return _G.WoWMockState.player.level
	elseif unit == "target" then
		return _G.WoWMockState.target.level
	end
	return 1
end

_G.UnitHealth = function(unit)
	if unit == "player" then
		return _G.WoWMockState.player.health
	elseif unit == "target" then
		return _G.WoWMockState.target.health
	end
	return 0
end

_G.UnitHealthMax = function(unit)
	if unit == "player" then
		return _G.WoWMockState.player.healthMax
	elseif unit == "target" then
		return _G.WoWMockState.target.healthMax
	end
	return 1
end

_G.UnitMana = function(unit)
	if unit == "player" then
		return _G.WoWMockState.player.mana
	elseif unit == "target" then
		return _G.WoWMockState.target.mana
	end
	return 0
end

_G.UnitManaMax = function(unit)
	if unit == "player" then
		return _G.WoWMockState.player.manaMax
	elseif unit == "target" then
		return _G.WoWMockState.target.manaMax
	end
	return 1
end

_G.UnitIsDead = function(unit)
	if unit == "target" then
		return _G.WoWMockState.target.isDead
	end
	return false
end

_G.UnitCanAttack = function(unit1, unit2)
	if unit1 == "player" and unit2 == "target" then
		return _G.WoWMockState.target.canAttack
	end
	return false
end

_G.UnitAffectingCombat = function(unit)
	if unit == "player" then
		return _G.WoWMockState.player.inCombat
	end
	return false
end

-- ============================================================================
-- SPELL FUNCTIONS
-- ============================================================================

_G.GetNumSpellTabs = function()
	return 3 -- General, Arms, Fury
end

_G.GetSpellTabInfo = function(tab)
	if tab == 1 then
		return "General", "", 10, 10
	elseif tab == 2 then
		return "Arms", "", 20, 20
	elseif tab == 3 then
		return "Fury", "", 20, 20
	end
	return "", "", 0, 0
end

_G.GetSpellName = function(spellId, bookType)
	for name, data in pairs(_G.WoWMockState.spellbook) do
		if data.id == spellId then
			return name
		end
	end
	return nil
end

_G.GetSpellCooldown = function(spellId, bookType)
	-- Returns: start, duration, enabled
	return 0, 0, 1 -- Not on cooldown
end

_G.CastSpellByName = function(spellName)
	-- Mock spell cast (no-op)
	return
end

-- ============================================================================
-- ACTION BAR FUNCTIONS
-- ============================================================================

_G.GetActionTexture = function(slot)
	-- Return nil (no action in slot)
	return nil
end

_G.GetActionText = function(slot)
	return nil
end

_G.IsCurrentAction = function(slot)
	return false
end

_G.IsUsableAction = function(slot)
	return true, false -- usable, not enough mana
end

_G.UseAction = function(slot)
	-- Mock action use (no-op)
	return
end

-- ============================================================================
-- STANCE FUNCTIONS
-- ============================================================================

_G.GetNumShapeshiftForms = function()
	return 3 -- Battle, Defensive, Berserker
end

_G.GetShapeshiftFormInfo = function(index)
	local stances = {
		[1] = {texture = "Interface\\Icons\\Ability_Warrior_OffensiveStance", name = "Battle Stance", isActive = false},
		[2] = {texture = "Interface\\Icons\\Ability_Warrior_DefensiveStance", name = "Defensive Stance", isActive = false},
		[3] = {texture = "Interface\\Icons\\Ability_Racial_Avatar", name = "Berserker Stance", isActive = false}
	}

	local stance = stances[index]
	if not stance then
		return nil, nil, false
	end

	stance.isActive = (_G.WoWMockState.stance == index)
	return stance.texture, stance.name, stance.isActive
end

_G.CastShapeshiftForm = function(index)
	_G.WoWMockState.stance = index
end

-- ============================================================================
-- BUFF/DEBUFF FUNCTIONS
-- ============================================================================

_G.GetPlayerBuff = function(buffIndex, castable)
	-- Legacy function, return nil
	return nil
end

-- ============================================================================
-- INVENTORY FUNCTIONS
-- ============================================================================

_G.GetInventoryItemTexture = function(unit, slot)
	return nil
end

_G.GetInventoryItemCooldown = function(unit, slot)
	return 0, 0, 1 -- Not on cooldown
end

_G.UseInventoryItem = function(slot)
	-- Mock trinket use (no-op)
	return
end

-- ============================================================================
-- DISTANCE FUNCTIONS
-- ============================================================================

_G.CheckInteractDistance = function(unit, distIndex)
	-- distIndex: 1=inspect(28yd), 2=trade(11.11yd), 3=duel(9.9yd), 4=follow(28yd)
	return true
end

-- ============================================================================
-- TOOLTIP MOCK
-- ============================================================================

-- Create a mock tooltip frame
_G.IWinFrame_T = {
	lines = {},
	SetOwner = function(self, owner, anchor) end,
	ClearLines = function(self) self.lines = {} end,
	SetInventoryItem = function(self, unit, slot) end,
	NumLines = function(self) return #self.lines end
}

-- Create mock text objects
for i = 1, 40 do
	_G["IWinFrame_TTextLeft" .. i] = {
		GetText = function(self) return _G.IWinFrame_T.lines[i] end
	}
end

-- ============================================================================
-- STRING FUNCTIONS
-- ============================================================================

-- Lua 5.1 compatible string.gfind (iterator)
if not string.gfind then
	string.gfind = string.gmatch
end

-- ============================================================================
-- MOCK SETTINGS
-- ============================================================================

-- Initialize mock IWin_Settings
_G.IWin_Settings = {
	-- Feature toggles
	AutoCharge = true,
	AutoBattleShout = true,
	AutoBloodrage = true,
	AutoTrinkets = true,
	AutoRend = true,
	AutoAttack = true,
	AutoStance = true,
	AutoShieldBlock = true,
	SkipThunderClapWithThunderfury = false,
	AutoRevenge = true,
	AutoInterrupt = true,
	SmartHeroicStrike = true,
	SkipRendOnTrash = true,

	-- Rage thresholds
	RageChargeMax = 50,
	RageBloodrageMin = 30,
	RageBloodthirstMin = 30,
	RageMortalStrikeMin = 30,
	RageWhirlwindMin = 25,
	RageSweepingMin = 30,
	RageHeroicMin = 30,
	RageCleaveMin = 30,
	RageShoutMin = 10,
	RageShoutCombatMin = 30,
	RageOverpowerMin = 5,
	RageExecuteMin = 10,
	RageRendMin = 10,
	RageInterruptMin = 10,
	RageShieldSlamMin = 20,
	RageRevengeMin = 5,
	RageThunderClapMin = 20,
	RageDemoShoutMin = 10,
	RageSunderMin = 15,
	RageConcussionBlowMin = 15,
	RageShieldBlockMin = 10,

	-- Health thresholds
	LastStandThreshold = 20,
	ConcussionBlowThreshold = 30,

	-- Debuff refresh times
	RefreshRend = 5,
	RefreshSunder = 3,
	RefreshThunderClap = 5,
	RefreshDemoShout = 3,

	-- Boss detection
	SunderStacksBoss = 5,
	SunderStacksTrash = 3,

	-- Other
	RotationThrottle = 0.1,
	OverpowerWindow = 5,
	RevengeWindow = 5,
	SunderStacks = 5,
	AOETargetThreshold = 3,
	HeroicStrikeQueueWindow = 0.5,

	-- Tracking
	LastRotationTime = 0,
	LastReactiveTime = 0,
	LastInterruptTime = 0,
	dodge = 0,

	-- Caches
	SpellCache = {},
	SpellIDCache = {},
	ActionSlotCache = {},
	BuffCache = {},
	DebuffCache = {},
	DebuffTracker = {},

	-- Action slots
	Trinket0Slot = 13,
	Trinket1Slot = 14,
	AttackSlot = nil,
	RevengeSlot = nil
}

print("WoW API mocks loaded successfully")
