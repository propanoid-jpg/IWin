--[[
	External Unit Tests for Boss Detection

	Run with: busted tests/test_boss_detection_spec.lua
]]

-- Load mocks first
require("tests/mock_wow_api")

-- Simple IWin mock for isolated testing
local IWin = {
	IsBoss = function(self)
		if not UnitExists("target") then
			return false
		end

		local classification = UnitClassification("target")
		local level = UnitLevel("target")

		return classification == "worldboss"
			or level == -1
			or (classification == "elite" and level == -1)
	end
}

describe("Boss Detection", function()
	before_each(function()
		ResetWoWMockState()
	end)

	describe("World Boss Classification", function()
		it("should detect worldboss classification as boss", function()
			_G.WoWMockState.target.classification = "worldboss"
			_G.WoWMockState.target.level = 63

			assert.is_true(IWin:IsBoss())
		end)

		it("should detect worldboss even with normal level", function()
			_G.WoWMockState.target.classification = "worldboss"
			_G.WoWMockState.target.level = 60

			assert.is_true(IWin:IsBoss())
		end)
	end)

	describe("Skull Level Detection", function()
		it("should detect skull level (-1) as boss", function()
			_G.WoWMockState.target.classification = "elite"
			_G.WoWMockState.target.level = -1

			assert.is_true(IWin:IsBoss())
		end)

		it("should detect skull level with rare classification", function()
			_G.WoWMockState.target.classification = "rare"
			_G.WoWMockState.target.level = -1

			assert.is_true(IWin:IsBoss())
		end)
	end)

	describe("Normal Mobs", function()
		it("should not detect normal classification as boss", function()
			_G.WoWMockState.target.classification = "normal"
			_G.WoWMockState.target.level = 60

			assert.is_false(IWin:IsBoss())
		end)

		it("should not detect elite with normal level as boss", function()
			_G.WoWMockState.target.classification = "elite"
			_G.WoWMockState.target.level = 60

			assert.is_false(IWin:IsBoss())
		end)

		it("should not detect rare with normal level as boss", function()
			_G.WoWMockState.target.classification = "rare"
			_G.WoWMockState.target.level = 58

			assert.is_false(IWin:IsBoss())
		end)
	end)

	describe("Edge Cases", function()
		it("should return false when no target exists", function()
			_G.WoWMockState.target.exists = false

			assert.is_false(IWin:IsBoss())
		end)

		it("should handle trivial classification", function()
			_G.WoWMockState.target.classification = "trivial"
			_G.WoWMockState.target.level = 1

			assert.is_false(IWin:IsBoss())
		end)
	end)
end)
