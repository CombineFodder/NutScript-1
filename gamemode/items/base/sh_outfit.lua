ITEM.name = "Outfit"
ITEM.description = "A Outfit Base."
ITEM.category = "Outfit"
ITEM.model = "models/Gibs/HGIBS.mdl"
ITEM.width = 1
ITEM.height = 1
ITEM.outfitCategory = "model"
ITEM.pacData = {}

--[[
-- This will change a player's skin after changing the model. Keep in mind it starts at 0.
ITEM.newSkin = 1
-- This will change a certain part of the model.
ITEM.replacements = {"group01", "group02"}
-- This will change the player's model completely.
ITEM.replacements = "models/manhack.mdl"
-- This will have multiple replacements.
ITEM.replacements = {
	{"male", "female"},
	{"group01", "group02"}
}

-- This will apply body groups.
ITEM.bodyGroups = {
	["blade"] = 1,
	["bladeblur"] = 1
}
]]--

-- Inventory drawing
if (CLIENT) then
	-- Draw camo if it is available.
	function ITEM:PaintOver(item, w, h)
		if (item:GetData("equip")) then
			surface.SetDrawColor(110, 255, 110, 100)
			surface.DrawRect(w - 14, h - 14, 8, 8)
		end
	end
end

function ITEM:removeOutfit(client)
	local character = client:GetChar()
	
	self:SetData("equip", false)

	if (character:GetData("oldMdl")) then
		character:SetModel(character:GetData("oldMdl"))
		character:SetData("oldMdl", nil)
	end
	
	if (self.newSkin) then
		if (character:GetData("oldSkin")) then
			client:SetSkin(character:GetData("oldSkin"))
			character:SetData("oldSkin", nil)
		else
			client:SetSkin(0)
		end
	end

	for k, v in pairs(self.bodyGroups or {}) do
		local index = client:FindBodygroupByName(k)

		if (index > -1) then
			client:SetBodygroup(index, 0)

			local groups = character:GetData("groups", {})

			if (groups[index]) then
				groups[index] = nil
				character:SetData("groups", groups)
			end
		end
	end

	if (self.attribBoosts) then
		for k, _ in pairs(self.attribBoosts) do
			character:RemoveBoost(self.uniqueID, k)
		end
	end
end

-- On item is dropped, Remove a weapon from the player and keep the ammo in the item.
ITEM:Hook("drop", function(item)
	if (item:GetData("equip")) then
		item:removeOutfit(item.player)
	end
end)

-- On player uneqipped the item, Removes a weapon from the player and keep the ammo in the item.
ITEM.functions.EquipUn = { -- sorry, for name order.
	name = "Unequip",
	tip = "equipTip",
	icon = "icon16/cross.png",
	OnRun = function(item)
		item:removeOutfit(item.player)
		
		return false
	end,
	OnCanRun = function(item)
		return (!IsValid(item.entity) and item:GetData("equip") == true)
	end
}

-- On player eqipped the item, Gives a weapon to player and load the ammo data from the item.
ITEM.functions.Equip = {
	name = "Equip",
	tip = "equipTip",
	icon = "icon16/tick.png",
	OnRun = function(item)
		local char = item.player:GetChar()
		local items = char:GetInv():GetItems()

		for k, v in pairs(items) do
			if (v.id != item.id) then
				local itemTable = nut.item.instances[v.id]

				if (itemTable.pacData and v.outfitCategory == item.outfitCategory and itemTable:GetData("equip")) then
					item.player:Notify("You're already equipping this kind of outfit")

					return false
				end
			end
		end

		item:SetData("equip", true)
		
		if (type(item.OnGetReplacement) == "function") then
			char:SetData("oldMdl", char:GetData("oldMdl", item.player:GetModel()))
			char:SetModel(item:OnGetReplacement())
		elseif (item.replacement or item.replacements) then
			char:SetData("oldMdl", char:GetData("oldMdl", item.player:GetModel()))

			if (type(item.replacements) == "table") then
				if (#item.replacements == 2 and type(item.replacements[1]) == "string") then
					char:SetModel(item.player:GetModel():gsub(item.replacements[1], item.replacements[2]))
				else
					for k, v in ipairs(item.replacements) do
						char:SetModel(item.player:GetModel():gsub(v[1], v[2]))
					end
				end
			else
				char:SetModel(item.replacement or item.replacements)
			end
		end
		
		if (item.newSkin) then
			char:SetData("oldSkin", item.player:GetSkin())
			item.player:SetSkin(item.newSkin)
		end
		
		if (item.bodyGroups) then
			local groups = {}

			for k, value in pairs(item.bodyGroups) do
				local index = item.player:FindBodygroupByName(k)

				if (index > -1) then
					groups[index] = value
				end
			end

			local newGroups = char:GetData("groups", {})

			for index, value in pairs(groups) do
				newGroups[index] = value
				item.player:SetBodygroup(index, value)
			end

			if (table.Count(newGroups) > 0) then
				char:SetData("groups", newGroups)
			end
		end

		if (item.attribBoosts) then
			for k, v in pairs(item.attribBoosts) do
				char:AddBoost(item.uniqueID, k, v)
			end
		end
		
		return false
	end,
	OnCanRun = function(item)
		return (!IsValid(item.entity) and item:GetData("equip") != true)
	end
}

function ITEM:OnCanBeTransfered(oldInventory, newInventory)
	if (newInventory and self:GetData("equip")) then
		return false
	end

	return true
end
