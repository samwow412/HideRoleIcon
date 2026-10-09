local ADDON_NAME = ...

local inCombat = false

local function OnlyInCombat()
	return HideRoleIconDB and HideRoleIconDB.onlyInCombat
end

local function ShouldHide()
	if OnlyInCombat() then
		return inCombat
	end
	return true
end

local function IsTankOrHealer(f)
	local unit = f.unit or f.displayedUnit
	if not unit then return false end
	local role = UnitGroupRolesAssigned(unit)
	if issecretvalue and issecretvalue(role) then return false end
	return role == "TANK" or role == "HEALER"
end

-- Only touch the default compact unit frames (same check as the original addon),
-- but don't let a missing options table make the check pass for every frame.
local function Apply(f)
	if not f or not f.roleIcon then return end
	local opts = DefaultCompactUnitFrameOptions
	if opts and f.optionTable ~= opts then return end
	local hide = ShouldHide()
	if hide and HideRoleIconDB and HideRoleIconDB.dpsOnly and IsTankOrHealer(f) then
		hide = false
	end
	f.roleIcon:SetAlpha(hide and 0 or 1)
end

local function RefreshAll()
	for i = 1, 5 do
		Apply(_G["CompactPartyFrameMember" .. i])
	end
	for i = 1, 40 do
		Apply(_G["CompactRaidFrame" .. i])
	end
	for g = 1, 8 do
		for i = 1, 5 do
			Apply(_G["CompactRaidGroup" .. g .. "Member" .. i])
		end
	end
end

local hooked = false
local function TryHook()
	if hooked then return end
	if type(CompactUnitFrame_UpdateRoleIcon) == "function" then
		hooksecurefunc("CompactUnitFrame_UpdateRoleIcon", Apply)
		hooked = true
	end
end

local f = CreateFrame("Frame")
f:RegisterEvent("ADDON_LOADED")
f:RegisterEvent("PLAYER_LOGIN")
f:RegisterEvent("PLAYER_REGEN_DISABLED")
f:RegisterEvent("PLAYER_REGEN_ENABLED")
f:SetScript("OnEvent", function(_, event, arg1)
	if event == "ADDON_LOADED" then
		if arg1 == ADDON_NAME then
			HideRoleIconDB = HideRoleIconDB or {}
			if HideRoleIconDB.dpsOnly == nil then
				HideRoleIconDB.dpsOnly = false
			end
			if HideRoleIconDB.onlyInCombat == nil then
				HideRoleIconDB.onlyInCombat = true
			end
		end
		TryHook()
	elseif event == "PLAYER_LOGIN" then
		inCombat = InCombatLockdown() and true or false
		TryHook()
		if not hooked then
			print("|cffff8800HideRoleIcon:|r CompactUnitFrame_UpdateRoleIcon not found on this client; role icons will not be hidden.")
		end
		RefreshAll()
	elseif event == "PLAYER_REGEN_DISABLED" then
		inCombat = true
		RefreshAll()
	elseif event == "PLAYER_REGEN_ENABLED" then
		inCombat = false
		RefreshAll()
	end
end)

local optionsFrame
local function OpenOptions()
	if not optionsFrame then
		local o = CreateFrame("Frame", "HideRoleIconOptions", UIParent, "BasicFrameTemplateWithInset")
		o:SetSize(300, 130)
		o:SetPoint("CENTER")
		o:SetMovable(true)
		o:EnableMouse(true)
		o:RegisterForDrag("LeftButton")
		o:SetScript("OnDragStart", o.StartMoving)
		o:SetScript("OnDragStop", o.StopMovingOrSizing)
		o:SetFrameStrata("DIALOG")

		local title = o:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
		title:SetPoint("TOP", o, "TOP", 0, -5)
		title:SetText("HideRoleIcon")

		local cb = CreateFrame("CheckButton", nil, o, "UICheckButtonTemplate")
		cb:SetPoint("TOPLEFT", o, "TOPLEFT", 16, -38)
		local label = o:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		label:SetPoint("LEFT", cb, "RIGHT", 4, 0)
		label:SetText("Only hide role icons in combat")
		cb:SetScript("OnClick", function(self)
			HideRoleIconDB.onlyInCombat = self:GetChecked() and true or false
			RefreshAll()
		end)

		local cb2 = CreateFrame("CheckButton", nil, o, "UICheckButtonTemplate")
		cb2:SetPoint("TOPLEFT", cb, "BOTTOMLEFT", 0, -6)
		local label2 = o:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		label2:SetPoint("LEFT", cb2, "RIGHT", 4, 0)
		label2:SetText("Only hide DPS icons (keep tank/healer)")
		cb2:SetScript("OnClick", function(self)
			HideRoleIconDB.dpsOnly = self:GetChecked() and true or false
			RefreshAll()
		end)

		o:SetScript("OnShow", function()
			cb:SetChecked(HideRoleIconDB.onlyInCombat)
			cb2:SetChecked(HideRoleIconDB.dpsOnly)
		end)
		o.checkbox = cb
		o.checkbox2 = cb2

		tinsert(UISpecialFrames, "HideRoleIconOptions")
		optionsFrame = o
	end
	optionsFrame:Show()
	optionsFrame.checkbox:SetChecked(HideRoleIconDB.onlyInCombat)
	optionsFrame.checkbox2:SetChecked(HideRoleIconDB.dpsOnly)
end

SLASH_HIDEROLEICON1 = "/hri"
SlashCmdList["HIDEROLEICON"] = function()
	if optionsFrame and optionsFrame:IsShown() then
		optionsFrame:Hide()
	else
		OpenOptions()
	end
end
