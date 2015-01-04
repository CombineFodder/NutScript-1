--[[
    NutScript is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    NutScript is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with NutScript.  If not, see <http://www.gnu.org/licenses/>.
--]]
local PLUGIN = PLUGIN
ENT.Type = "anim"
ENT.PrintName = "Storage"
ENT.Category = "NutScript"
ENT.Spawnable = false

if (SERVER) then
	function ENT:Initialize()
		self:SetModel("models/props_junk/watermelon01.mdl")
		self:SetSolid(SOLID_VPHYSICS)
		self:PhysicsInit(SOLID_VPHYSICS)
		self:SetUseType(SIMPLE_USE)
		self.receivers = {}

		local physObj = self:GetPhysicsObject()

		if (IsValid(physObj)) then
			physObj:EnableMotion(true)
			physObj:Wake()
		end
	end

	function ENT:setInventory(inventory)
		if (inventory) then
			self:setNetVar("id", inventory:getID())
			inventory.onAuthorizeTransfer = function(inventory, client, oldInventory, item)
				if (IsValid(client) and IsValid(self) and self.receivers[client]) then
					return true
				end
			end
			inventory.getReceiver = function(inventory)
				local receivers = {}

				for k, v in pairs(self.receivers) do
					if (IsValid(k)) then
						receivers[#receivers + 1] = k
					end
				end

				return #receivers > 0 and receivers or nil
			end
		end
	end

	function ENT:OnRemove()
		local index = self:getNetVar("id")

		if (!nut.shuttingDown and !self.nutIsSafe and index) then
			local item = nut.item.inventories[index]

			if (item) then
				nut.item.inventories[index] = nil

				nut.db.query("DELETE FROM nut_items WHERE _invID = "..index)
				nut.db.query("DELETE FROM nut_inventories WHERE _invID = "..index)

				hook.Run("StorageItemRemoved", self, item)
			end
		end
	end

	local OPEN_TIME = .7
	function ENT:OpenInv(activator)
		local inventory = self:getInv()
		local def = PLUGIN.definitions[self:GetModel():lower()]

		if (def.onOpen) then
			def.onOpen(self, activator)
		end

		activator:setAction("Opening...", OPEN_TIME, function()
			if (activator:GetPos():Distance(self:GetPos()) <= 100) then
				self.receivers[activator] = true
				activator.nutBagEntity = self
				
				inventory:sync(activator)
				netstream.Start(activator, "invOpen", self, inventory:getID())
				self:EmitSound(def.opensound or "items/ammocrate_open.wav")
			end
		end)
	end

	function ENT:Use(activator)
		local inventory = self:getInv()

		if (inventory and (activator.nutNextOpen or 0) < CurTime()) then
			if (activator:getChar()) then
				local def = PLUGIN.definitions[self:GetModel():lower()]

				if (self:getNetVar("locked")) then
					self:EmitSound(def.locksound or "doors/default_locked.wav")
					netstream.Start(activator, "invLock", self)
				else
					self:OpenInv(activator)
				end
			end

			activator.nutNextOpen = CurTime() + OPEN_TIME * 1.5
		end
	end
else
	function ENT:onShouldDrawEntityInfo()
		return true
	end

	local COLOR_LOCKED = Color(242, 38, 19)
	local COLOR_UNLOCKED = Color(135, 211, 124)
	function ENT:onDrawEntityInfo(alpha)
		local locked = self:getNetVar("locked", false)
		local position = self:LocalToWorld(self:OBBCenter()):ToScreen()
		local x, y = position.x, position.y

		y = y - 20
		local tx, ty = nut.util.drawText(locked and "P" or "Q", x, y, ColorAlpha(locked and COLOR_LOCKED or COLOR_UNLOCKED, alpha), 1, 1, "nutIconsMedium", alpha * 0.65)
		y = y + ty*.9

		local def = PLUGIN.definitions[self:GetModel():lower()]
		local tx, ty = nut.util.drawText("Storage", x, y, ColorAlpha(nut.config.get("color"), alpha), 1, 1, nil, alpha * 0.65)
		if (def) then
			y = y + ty + 1
			nut.util.drawText(def.desc, x, y, ColorAlpha(color_white, alpha), 1, 1, nil, alpha * 0.65)
		end
	end
end

function ENT:getInv()
	return nut.item.inventories[self:getNetVar("id", 0)]
end