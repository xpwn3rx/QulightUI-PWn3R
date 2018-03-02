--[[ Element: Combo Point Icons
 Toggles visibility of the player and vehicles combo points.

 Widget

 CPoints - An array consisting of five UI widgets.

 Notes

 The default combo point texture will be applied to textures within the CPoints
 array that don't have a texture or color defined.

 Examples

   local CPoints = {}
   for index = 1, MAX_COMBO_POINTS do
      local CPoint = self:CreateTexture(nil, 'BACKGROUND')
   
      -- Position and size of the combo point.
      CPoint:SetSize(12, 16)
      CPoint:SetPoint('TOPLEFT', self, 'BOTTOMLEFT', index * CPoint:GetWidth(), 0)
   
      CPoints[index] = CPoint
   end
   
   -- Register with oUF
   self.CPoints = CPoints

 Hooks

 Override(self) - Used to completely override the internal update function.
                  Removing the table key entry will make the element fall-back
                  to its internal function again.
]]

local parent, ns = ...
local oUF = ns.oUF

local GetComboPoints = GetComboPoints
local MAX_COMBO_POINTS = MAX_COMBO_POINTS

local function Update(self, event, unit)
	if(unit == 'pet') then return end

	local element = self.CPoints

	--[[ Callback: ClassPower:PreUpdate(event)
	Called before the element has been updated.

	* self  - the ClassPower element
	]]
	if(element.PreUpdate) then
		element:PreUpdate()
	end

	local cur, max, mod, oldMax
	if(event ~= 'ClassPowerDisable') then
		if(unit == 'vehicle') then
			-- BUG: UnitPower always returns 0 combo points for vehicles
			cur = GetComboPoints(unit)
			max = MAX_COMBO_POINTS
			mod = 1
		else
			cur = UnitPower('player', ClassPowerID, true)
			max = UnitPowerMax('player', ClassPowerID)
			mod = UnitPowerDisplayMod(ClassPowerID)
		end

		-- mod should never be 0, but according to Blizz code it can actually happen
		cur = mod == 0 and 0 or cur / mod

		-- BUG: Destruction is supposed to show partial soulshards, but Affliction and Demonology should only show full ones
		if(ClassPowerType == 'SOUL_SHARDS' and GetSpecialization() ~= SPEC_WARLOCK_DESTRUCTION) then
			cur = cur - cur % 1
		end

		local numActive = cur + 0.9
		for i = 1, max do
			if(i > numActive) then
				element[i]:Hide()
				element[i]:SetValue(0)
			else
				element[i]:Show()
				element[i]:SetValue(cur - i + 1)
			end
		end

		oldMax = element.__max
		if(max ~= oldMax) then
			if(max < oldMax) then
				for i = max + 1, oldMax do
					element[i]:Hide()
					element[i]:SetValue(0)
				end
			end

			element.__max = max
		end
	end
	--[[ Callback: ClassPower:PostUpdate(cur, max, hasMaxChanged, powerType)
	Called after the element has been updated.

	* self          - the ClassPower element
	* cur           - the current amount of power (number)
	* max           - the maximum amount of power (number)
	* hasMaxChanged - indicates whether the maximum amount has changed since the last update (boolean)
	* powerType     - the active power type (string)
	--]]
	if(element.PostUpdate) then
		return element:PostUpdate(cur, max, oldMax ~= max, powerType)
	end
end

local Path = function(self, ...)
	return (self.CPoints.Override or Update) (self, ...)
end

local ForceUpdate = function(element)
	return Path(element.__owner, 'ForceUpdate', element.__owner.unit)
end

local Enable = function(self)
	local cpoints = self.CPoints
	if(cpoints) then
		cpoints.__owner = self
		cpoints.ForceUpdate = ForceUpdate

		self:RegisterEvent('UNIT_POWER_FREQUENT', Path, true)
		self:RegisterEvent('UNIT_MAXPOWER', Path, true)

		for index = 1, MAX_COMBO_POINTS do
			local cpoint = cpoints[index]
			if(cpoint:IsObjectType'Texture' and not cpoint:GetTexture()) then
				cpoint:SetTexture[[Interface\ComboFrame\ComboPoint]]
				cpoint:SetTexCoord(0, 0.375, 0, 1)
				cpoint:SetMinMaxValues(0,1)
			end
		end

		return true
	end
end

local Disable = function(self)
	local cpoints = self.CPoints
	if(cpoints) then
		self:UnregisterEvent('PLAYER_TALENT_UPDATE', VisibilityPath)
		self:UnregisterEvent('UNIT_DISPLAYPOWER', VisibilityPath)
		self:UnregisterEvent('SPELLS_CHANGED', Visibility)
	end
end

oUF:AddElement('CPoints', Path, Enable, Disable)