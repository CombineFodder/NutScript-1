AddCSLuaFile()

ENT.Type = "anim"
ENT.PrintName = "Money"
ENT.Category = "NutScript"
ENT.Spawnable = false
ENT.ShowPlayerInteraction = true

if (SERVER) then
	function ENT:Initialize()
		self:SetModel("models/props_lab/box01a.mdl")
		self:SetSolid(SOLID_VPHYSICS)
		self:PhysicsInit(SOLID_VPHYSICS)
		self:SetUseType(SIMPLE_USE)

		local physObj = self:GetPhysicsObject()

		if (IsValid(physObj)) then
			physObj:EnableMotion(true)
			physObj:Wake()
		else
			local min, max = Vector(-8, -8, -8), Vector(8, 8, 8)

			self:PhysicsInitBox(min, max)
			self:SetCollisionBounds(min, max)
		end
	end

	function ENT:Use(activator)
		if (self.client and self.charID) then
			local char = activator:GetChar()
			
			if (char) then
				if (self.charID != char:GetID() and self.client == activator) then
					activator:NotifyLocalized("logged")
					
					return false
				end
			end
		end
		
		activator:PerformInteraction(nut.config.Get("itemPickupTime", 0.5), self, function(client)
			if (hook.Run("OnPickupMoney", client, self) != false) then
				self:Remove()
			end
		end)
	end
else
	ENT.DrawEntityInfo = true

	local toScreen = FindMetaTable("Vector").ToScreen
	local colorAlpha = ColorAlpha
	local drawText = nut.util.DrawText
	local configGet = nut.config.Get

	function ENT:OnDrawEntityInfo(alpha)
		local position = toScreen(self.LocalToWorld(self, self.OBBCenter(self)))
		local x, y = position.x, position.y

		drawText(nut.currency.Get(self.GetAmount(self)), x, y, colorAlpha(configGet("color"), alpha), 1, 1, nil, alpha * 0.65)
	end
end

function ENT:SetAmount(amount)
	self:SetNetVar("amount", amount)
end

function ENT:GetAmount()
	return self:GetNetVar("amount", 0)
end
