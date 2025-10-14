--[[
	External Unit Tests for Throttling Logic

	Run with: busted tests/test_throttling_spec.lua
]]

-- Load mocks first
require("tests/mock_wow_api")

-- Simple IWin mock for isolated testing
local IWin = {
	ShouldThrottle = function(self)
		if not IWin_Settings["LastRotationTime"] then
			IWin_Settings["LastRotationTime"] = 0
		end

		local currentTime = GetTime()
		if currentTime - IWin_Settings["LastRotationTime"] < IWin_Settings["RotationThrottle"] then
			return true
		end
		IWin_Settings["LastRotationTime"] = currentTime
		return false
	end
}

describe("Throttling Logic", function()
	before_each(function()
		ResetWoWMockState()
		_G.WoWMockState.time = 0
		IWin_Settings.LastRotationTime = 0
		IWin_Settings.RotationThrottle = 0.1
	end)

	describe("Should Throttle", function()
		it("should throttle when called immediately", function()
			IWin_Settings.LastRotationTime = GetTime()

			assert.is_true(IWin:ShouldThrottle())
		end)

		it("should throttle when called within throttle window", function()
			IWin_Settings.LastRotationTime = 0
			AdvanceTime(0.05) -- Half the throttle time

			assert.is_true(IWin:ShouldThrottle())
		end)

		it("should throttle with very small delta", function()
			IWin_Settings.LastRotationTime = 0
			AdvanceTime(0.001)

			assert.is_true(IWin:ShouldThrottle())
		end)
	end)

	describe("Should Not Throttle", function()
		it("should not throttle after full throttle period", function()
			IWin_Settings.LastRotationTime = 0
			AdvanceTime(0.1) -- Exactly throttle time

			assert.is_false(IWin:ShouldThrottle())
		end)

		it("should not throttle after longer delay", function()
			IWin_Settings.LastRotationTime = 0
			AdvanceTime(1.0)

			assert.is_false(IWin:ShouldThrottle())
		end)

		it("should not throttle when LastRotationTime is nil", function()
			IWin_Settings.LastRotationTime = nil

			assert.is_false(IWin:ShouldThrottle())
		end)

		it("should not throttle when LastRotationTime is 0", function()
			IWin_Settings.LastRotationTime = 0
			AdvanceTime(0.2)

			assert.is_false(IWin:ShouldThrottle())
		end)
	end)

	describe("Throttle Period Variations", function()
		it("should respect different throttle values (0.05s)", function()
			IWin_Settings.RotationThrottle = 0.05
			IWin_Settings.LastRotationTime = 0
			AdvanceTime(0.04)

			assert.is_true(IWin:ShouldThrottle())

			AdvanceTime(0.02) -- Total 0.06
			assert.is_false(IWin:ShouldThrottle())
		end)

		it("should respect different throttle values (0.5s)", function()
			IWin_Settings.RotationThrottle = 0.5
			IWin_Settings.LastRotationTime = 0
			AdvanceTime(0.4)

			assert.is_true(IWin:ShouldThrottle())

			AdvanceTime(0.2) -- Total 0.6
			assert.is_false(IWin:ShouldThrottle())
		end)

		it("should respect different throttle values (1.0s)", function()
			IWin_Settings.RotationThrottle = 1.0
			IWin_Settings.LastRotationTime = 0
			AdvanceTime(0.9)

			assert.is_true(IWin:ShouldThrottle())

			AdvanceTime(0.2) -- Total 1.1
			assert.is_false(IWin:ShouldThrottle())
		end)
	end)

	describe("State Updates", function()
		it("should update LastRotationTime when not throttling", function()
			IWin_Settings.LastRotationTime = 0
			AdvanceTime(0.2)

			local beforeCall = IWin_Settings.LastRotationTime
			IWin:ShouldThrottle()
			local afterCall = IWin_Settings.LastRotationTime

			assert.is_true(afterCall > beforeCall)
			assert.equals(GetTime(), afterCall)
		end)

		it("should not update LastRotationTime when throttling", function()
			IWin_Settings.LastRotationTime = 0.5
			AdvanceTime(0.6) -- Time is now 0.6, last call was 0.5 (delta 0.1)

			local beforeCall = IWin_Settings.LastRotationTime
			IWin:ShouldThrottle()
			local afterCall = IWin_Settings.LastRotationTime

			assert.equals(beforeCall, afterCall)
		end)
	end)
end)
