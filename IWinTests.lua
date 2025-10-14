--[[
	IWin Tests - In-Game Testing Framework

	This addon provides smoke tests and integration tests for IWin.
	Run tests with: /iwintests

	Dependencies: IWin (must load first)
]]

IWinTests = {
	results = {},
	mocks = {}
}

-- Test result tracking
function IWinTests:Pass(message)
	table.insert(self.results, {pass = true, message = message})
end

function IWinTests:Fail(message)
	table.insert(self.results, {pass = false, message = message})
end

function IWinTests:Assert(condition, message)
	if condition then
		self:Pass(message)
	else
		self:Fail(message)
	end
end

function IWinTests:AssertEqual(actual, expected, message)
	if actual == expected then
		self:Pass(message .. " (expected: " .. tostring(expected) .. ")")
	else
		self:Fail(message .. " (expected: " .. tostring(expected) .. ", got: " .. tostring(actual) .. ")")
	end
end

function IWinTests:AssertNotNil(value, message)
	if value ~= nil then
		self:Pass(message)
	else
		self:Fail(message .. " (value was nil)")
	end
end

-- Mock helper functions
function IWinTests:MockWoWAPI(funcName, mockFunc)
	if not self.mocks[funcName] then
		self.mocks[funcName] = getglobal(funcName)
	end
	setglobal(funcName, mockFunc)
end

function IWinTests:RestoreWoWAPI(funcName)
	if self.mocks[funcName] then
		setglobal(funcName, self.mocks[funcName])
		self.mocks[funcName] = nil
	end
end

function IWinTests:RestoreAllMocks()
	for funcName, originalFunc in pairs(self.mocks) do
		setglobal(funcName, originalFunc)
	end
	self.mocks = {}
end

-- ============================================================================
-- SMOKE TESTS (Phase 1)
-- ============================================================================

function IWinTests:TestAddonLoaded()
	self:Assert(IWin ~= nil, "IWin addon loaded")
	self:Assert(IWin_Settings ~= nil, "IWin_Settings exists")
	self:Assert(type(IWin_Settings) == "table", "IWin_Settings is a table")
end

function IWinTests:TestConstants()
	self:AssertNotNil(IWin.CONSTANTS, "IWin.CONSTANTS exists")
	self:AssertNotNil(IWin.CONSTANTS.REACTIVE_THROTTLE, "REACTIVE_THROTTLE defined")
	self:AssertNotNil(IWin.CONSTANTS.INTERRUPT_THROTTLE, "INTERRUPT_THROTTLE defined")
	self:AssertEqual(type(IWin.CONSTANTS.REACTIVE_THROTTLE), "number", "REACTIVE_THROTTLE is numeric")
end

function IWinTests:TestCommandSystem()
	self:AssertNotNil(IWin.Commands, "IWin.Commands table exists")

	-- Test some known commands
	self:AssertNotNil(IWin.Commands.charge, "charge command defined")
	self:AssertNotNil(IWin.Commands.throttle, "throttle command defined")

	-- Test command structure
	local chargeCmd = IWin.Commands.charge
	self:AssertEqual(chargeCmd.type, "boolean", "charge is boolean type")
	self:AssertNotNil(chargeCmd.setting, "charge has setting field")
	self:AssertNotNil(chargeCmd.label, "charge has label field")
end

function IWinTests:TestRotationFunctions()
	-- Test rotation functions exist
	self:Assert(type(IWin.dmgST) == "function", "dmgST rotation exists")
	self:Assert(type(IWin.dmgAOE) == "function", "dmgAOE rotation exists")
	self:Assert(type(IWin.tankST) == "function", "tankST rotation exists")
	self:Assert(type(IWin.tankAOE) == "function", "tankAOE rotation exists")
end

function IWinTests:TestHelperFunctions()
	-- Test common helper functions exist
	self:Assert(type(IWin.GetSpell) == "function", "GetSpell function exists")
	self:Assert(type(IWin.OnCooldown) == "function", "OnCooldown function exists")
	self:Assert(type(IWin.IsBoss) == "function", "IsBoss function exists")
	self:Assert(type(IWin.ShouldThrottle) == "function", "ShouldThrottle function exists")
	self:Assert(type(IWin.ValidateTarget) == "function", "ValidateTarget function exists")
	self:Assert(type(IWin.SwitchStance) == "function", "SwitchStance function exists")
end

function IWinTests:TestSettingsInitialized()
	-- Test critical settings exist
	self:AssertNotNil(IWin_Settings.AutoCharge, "AutoCharge setting exists")
	self:AssertNotNil(IWin_Settings.RotationThrottle, "RotationThrottle setting exists")
	self:AssertNotNil(IWin_Settings.RageChargeMax, "RageChargeMax setting exists")

	-- Test setting types
	self:AssertEqual(type(IWin_Settings.AutoCharge), "boolean", "AutoCharge is boolean")
	self:AssertEqual(type(IWin_Settings.RotationThrottle), "number", "RotationThrottle is number")

	-- Test setting ranges
	local throttle = IWin_Settings.RotationThrottle
	self:Assert(throttle >= 0.05 and throttle <= 1.0, "RotationThrottle in valid range (0.05-1.0)")
end

function IWinTests:TestCacheInitialized()
	-- Test cache structures exist
	self:AssertNotNil(IWin_Settings.SpellCache, "SpellCache exists")
	self:AssertNotNil(IWin_Settings.SpellIDCache, "SpellIDCache exists")
	self:AssertNotNil(IWin_Settings.BuffCache, "BuffCache exists")
	self:AssertNotNil(IWin_Settings.DebuffCache, "DebuffCache exists")

	-- Test cache types
	self:AssertEqual(type(IWin_Settings.SpellCache), "table", "SpellCache is table")
	self:AssertEqual(type(IWin_Settings.SpellIDCache), "table", "SpellIDCache is table")
end

-- ============================================================================
-- UNIT TESTS (Phase 2 - with mocks)
-- ============================================================================

function IWinTests:TestBossDetection_WorldBoss()
	-- Mock WoW API for worldboss
	self:MockWoWAPI("UnitExists", function(unit) return true end)
	self:MockWoWAPI("UnitName", function(unit) return "Ragnaros" end)
	self:MockWoWAPI("UnitClassification", function(unit) return "worldboss" end)
	self:MockWoWAPI("UnitLevel", function(unit) return -1 end)

	local isBoss = IWin:IsBoss()
	self:Assert(isBoss == true, "Worldboss classification detected")

	self:RestoreAllMocks()
end

function IWinTests:TestBossDetection_SkullLevel()
	-- Mock WoW API for skull level elite
	self:MockWoWAPI("UnitExists", function(unit) return true end)
	self:MockWoWAPI("UnitName", function(unit) return "Elite Mob" end)
	self:MockWoWAPI("UnitClassification", function(unit) return "elite" end)
	self:MockWoWAPI("UnitLevel", function(unit) return -1 end)

	local isBoss = IWin:IsBoss()
	self:Assert(isBoss == true, "Skull level elite detected as boss")

	self:RestoreAllMocks()
end

function IWinTests:TestBossDetection_NormalMob()
	-- Mock WoW API for normal mob
	self:MockWoWAPI("UnitExists", function(unit) return true end)
	self:MockWoWAPI("UnitName", function(unit) return "Normal Mob" end)
	self:MockWoWAPI("UnitClassification", function(unit) return "normal" end)
	self:MockWoWAPI("UnitLevel", function(unit) return 60 end)

	local isBoss = IWin:IsBoss()
	self:Assert(isBoss == false, "Normal mob not detected as boss")

	self:RestoreAllMocks()
end

function IWinTests:TestBossDetection_NoTarget()
	-- Mock WoW API for no target
	self:MockWoWAPI("UnitExists", function(unit) return false end)

	local isBoss = IWin:IsBoss()
	self:Assert(isBoss == false, "No target returns false")

	self:RestoreAllMocks()
end

function IWinTests:TestThrottling_ShouldThrottle()
	-- Save original
	local originalTime = IWin_Settings.LastRotationTime
	local originalThrottle = IWin_Settings.RotationThrottle

	-- Set up recent call
	IWin_Settings.LastRotationTime = GetTime()
	IWin_Settings.RotationThrottle = 0.1

	local shouldThrottle = IWin:ShouldThrottle()
	self:Assert(shouldThrottle == true, "Should throttle when called immediately")

	-- Restore
	IWin_Settings.LastRotationTime = originalTime
	IWin_Settings.RotationThrottle = originalThrottle
end

function IWinTests:TestThrottling_ShouldNotThrottle()
	-- Save original
	local originalTime = IWin_Settings.LastRotationTime
	local originalThrottle = IWin_Settings.RotationThrottle

	-- Set up old call
	IWin_Settings.LastRotationTime = GetTime() - 1.0
	IWin_Settings.RotationThrottle = 0.1

	local shouldThrottle = IWin:ShouldThrottle()
	self:Assert(shouldThrottle == false, "Should not throttle after delay")

	-- Restore
	IWin_Settings.LastRotationTime = originalTime
	IWin_Settings.RotationThrottle = originalThrottle
end

function IWinTests:TestValidateTarget_ValidTarget()
	-- Mock valid target
	self:MockWoWAPI("UnitExists", function(unit) return true end)
	self:MockWoWAPI("UnitIsDead", function(unit) return false end)
	self:MockWoWAPI("UnitCanAttack", function(unit1, unit2) return true end)

	local isValid = IWin:ValidateTarget()
	self:Assert(isValid == true, "Valid target detected")

	self:RestoreAllMocks()
end

function IWinTests:TestValidateTarget_NoTarget()
	-- Mock no target
	self:MockWoWAPI("UnitExists", function(unit) return false end)

	local isValid = IWin:ValidateTarget()
	self:Assert(isValid == false, "No target returns false")

	self:RestoreAllMocks()
end

function IWinTests:TestValidateTarget_DeadTarget()
	-- Mock dead target
	self:MockWoWAPI("UnitExists", function(unit) return true end)
	self:MockWoWAPI("UnitIsDead", function(unit) return true end)

	local isValid = IWin:ValidateTarget()
	self:Assert(isValid == false, "Dead target returns false")

	self:RestoreAllMocks()
end

function IWinTests:TestValidateTarget_FriendlyTarget()
	-- Mock friendly target
	self:MockWoWAPI("UnitExists", function(unit) return true end)
	self:MockWoWAPI("UnitIsDead", function(unit) return false end)
	self:MockWoWAPI("UnitCanAttack", function(unit1, unit2) return false end)

	local isValid = IWin:ValidateTarget()
	self:Assert(isValid == false, "Friendly target returns false")

	self:RestoreAllMocks()
end

function IWinTests:TestCommandHandlers()
	-- Save originals
	local originalAutoCharge = IWin_Settings.AutoCharge
	local originalThrottle = IWin_Settings.RotationThrottle

	-- Test boolean handler
	if IWin.HandleBooleanCommand then
		local cmd = {setting = "AutoCharge", label = "Test Charge"}

		IWin:HandleBooleanCommand(cmd, "on")
		self:AssertEqual(IWin_Settings.AutoCharge, true, "Boolean handler sets true")

		IWin:HandleBooleanCommand(cmd, "off")
		self:AssertEqual(IWin_Settings.AutoCharge, false, "Boolean handler sets false")
	else
		self:Fail("HandleBooleanCommand not found")
	end

	-- Test numeric handler
	if IWin.HandleNumericCommand then
		local cmd = {setting = "RotationThrottle", min = 0.05, max = 1.0, label = "Test Throttle"}

		IWin:HandleNumericCommand(cmd, "0.5")
		self:AssertEqual(IWin_Settings.RotationThrottle, 0.5, "Numeric handler sets valid value")

		IWin:HandleNumericCommand(cmd, "5.0")
		self:AssertEqual(IWin_Settings.RotationThrottle, 0.5, "Numeric handler rejects invalid value")
	else
		self:Fail("HandleNumericCommand not found")
	end

	-- Restore
	IWin_Settings.AutoCharge = originalAutoCharge
	IWin_Settings.RotationThrottle = originalThrottle
end

-- ============================================================================
-- INTEGRATION TESTS (Phase 3)
-- ============================================================================

function IWinTests:TestRotationExecute_NoErrors()
	-- Test that rotations don't crash when called
	-- Note: They may not do anything useful without a valid target

	local success, err

	success, err = pcall(IWin.dmgST, IWin)
	self:Assert(success, "dmgST rotation executes without error")

	success, err = pcall(IWin.dmgAOE, IWin)
	self:Assert(success, "dmgAOE rotation executes without error")

	success, err = pcall(IWin.tankST, IWin)
	self:Assert(success, "tankST rotation executes without error")

	success, err = pcall(IWin.tankAOE, IWin)
	self:Assert(success, "tankAOE rotation executes without error")
end

function IWinTests:TestSpellCache()
	-- Clear cache
	local originalCache = IWin_Settings.SpellCache
	IWin_Settings.SpellCache = {}

	-- Try to lookup a spell (will check spellbook)
	local hasCharge = IWin:GetSpell("Charge")

	-- Result depends on whether player has Charge, but cache should be populated
	self:AssertNotNil(IWin_Settings.SpellCache["Charge"], "Charge cached after lookup")

	-- Second lookup should use cache
	local hasCharge2 = IWin:GetSpell("Charge")
	self:AssertEqual(hasCharge, hasCharge2, "Cached result matches original")

	-- Restore
	IWin_Settings.SpellCache = originalCache
end

-- ============================================================================
-- TEST RUNNER
-- ============================================================================

function IWinTests:RunAll()
	self.results = {}

	DEFAULT_CHAT_FRAME:AddMessage("|cff0066ff========================================|r")
	DEFAULT_CHAT_FRAME:AddMessage("|cff0066ffIWin Tests - Running...|r")
	DEFAULT_CHAT_FRAME:AddMessage("|cff0066ff========================================|r")

	-- Phase 1: Smoke Tests
	DEFAULT_CHAT_FRAME:AddMessage("|cffff8800Phase 1: Smoke Tests|r")
	self:TestAddonLoaded()
	self:TestConstants()
	self:TestCommandSystem()
	self:TestRotationFunctions()
	self:TestHelperFunctions()
	self:TestSettingsInitialized()
	self:TestCacheInitialized()

	-- Phase 2: Unit Tests
	DEFAULT_CHAT_FRAME:AddMessage("|cffff8800Phase 2: Unit Tests|r")
	self:TestBossDetection_WorldBoss()
	self:TestBossDetection_SkullLevel()
	self:TestBossDetection_NormalMob()
	self:TestBossDetection_NoTarget()
	self:TestThrottling_ShouldThrottle()
	self:TestThrottling_ShouldNotThrottle()
	self:TestValidateTarget_ValidTarget()
	self:TestValidateTarget_NoTarget()
	self:TestValidateTarget_DeadTarget()
	self:TestValidateTarget_FriendlyTarget()
	self:TestCommandHandlers()

	-- Phase 3: Integration Tests
	DEFAULT_CHAT_FRAME:AddMessage("|cffff8800Phase 3: Integration Tests|r")
	self:TestRotationExecute_NoErrors()
	self:TestSpellCache()

	self:PrintResults()
end

function IWinTests:PrintResults()
	local passed = 0
	local failed = 0

	for _, result in ipairs(self.results) do
		if result.pass then
			passed = passed + 1
			DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[PASS]|r " .. result.message)
		else
			failed = failed + 1
			DEFAULT_CHAT_FRAME:AddMessage("|cffff0000[FAIL]|r " .. result.message)
		end
	end

	DEFAULT_CHAT_FRAME:AddMessage("|cff0066ff========================================|r")
	if failed == 0 then
		DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00All tests passed! (" .. passed .. " tests)|r")
	else
		DEFAULT_CHAT_FRAME:AddMessage("|cffff0000Tests failed: " .. failed .. " / " .. (passed + failed) .. "|r")
	end
	DEFAULT_CHAT_FRAME:AddMessage("|cff0066ff========================================|r")
end

-- Slash command
SlashCmdList["IWINTESTS"] = function(msg)
	if msg == "help" then
		DEFAULT_CHAT_FRAME:AddMessage("|cff0066ffIWin Tests Commands:|r")
		DEFAULT_CHAT_FRAME:AddMessage("/iwintests - Run all tests")
		DEFAULT_CHAT_FRAME:AddMessage("/iwintests help - Show this help")
	else
		IWinTests:RunAll()
	end
end
SLASH_IWINTESTS1 = "/iwintests"

-- Auto-run on load (optional, comment out if annoying)
-- DEFAULT_CHAT_FRAME:AddMessage("|cff0066ff[IWin Tests]|r Loaded. Type |cffff8800/iwintests|r to run tests.")
