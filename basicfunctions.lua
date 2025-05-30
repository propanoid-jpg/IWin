-- Debug: Confirm file loading
DEFAULT_CHAT_FRAME:AddMessage("IWin: Loading basicfunctions.lua...")

IWin = IWin or {}

function IWin:GetBuff(name, buff, stacks)
	local a = 1
	while UnitBuff(name, a) do
		local _, s = UnitBuff(name, a)
		IWin_T:SetOwner(WorldFrame, "ANCHOR_NONE")
		IWin_T:ClearLines()
		IWin_T:SetUnitBuff(name, a)
		local text = IWin_TTextLeft1:GetText()
		if text == buff then
			if stacks == 1 then
				return s
			else
				return true
			end
		end
		a = a + 1
	end
	a = 1
	while UnitDebuff(name, a) do
		local _, s = UnitDebuff(name, a)
		IWin_T:SetOwner(WorldFrame, "ANCHOR_NONE")
		IWin_T:ClearLines()
		IWin_T:SetUnitDebuff(name, a)
		local text = IWin_TTextLeft1:GetText()
		if text == buff then
			if stacks == 1 then
				return s
			else
				return true
			end
		end
		a = a + 1
	end

	return false
end

function IWin:GetActionSlot(a)
	for i = 1, 100 do
		IWin_T:SetOwner(UIParent, "ANCHOR_NONE")
		IWin_T:ClearLines()
		IWin_T:SetAction(i)
		local ab = IWin_TTextLeft1:GetText()
		IWin_T:Hide()
		if ab == a then
			return i
		end
	end
	return 2
end

function IWin:OnCooldown(Spell)
	if Spell then
		local spellID = 1
		local spell = GetSpellName(spellID, "BOOKTYPE_SPELL")
		while spell do
			if Spell == spell then
				if GetSpellCooldown(spellID, "BOOKTYPE_SPELL") == 0 then
					return false
				else
					return true
				end
			end
			spellID = spellID + 1
			spell = GetSpellName(spellID, "BOOKTYPE_SPELL")
		end
	end
end

function IWin:GetSpell(name)
	local spellID = 1
	local spell = GetSpellName(spellID, BOOKTYPE_SPELL)
	while spell do
		if spell == name then
			return true
		end
		spellID = spellID + 1
		spell = GetSpellName(spellID, BOOKTYPE_SPELL)
	end
	return false
end
