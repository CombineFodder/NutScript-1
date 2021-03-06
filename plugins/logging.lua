PLUGIN.name = "Logging"
PLUGIN.author = "Black Tea"
PLUGIN.description = "You can modfiy the logging text/lists on this plugin."
 
if (SERVER) then
	local L = Format
	
	nut.log.AddType("chat", function(client, ...)
		local arg = {...}
		return L("[%s] %s: %s", arg[1], client:Name(), arg[2])
	end)
	nut.log.AddType("command", function(client, ...)
		local arg = {...}

		if (#arg[2] > 0) then
			return L("%s used command '%s %s'.", client:Name(), arg[1], arg[2])
		else
			return L("%s used command '%s'.", client:Name(), arg[1])
		end
	end)
	nut.log.AddType("cfgSet", function(client, ...)
		local arg = {...}
		return L("%s set %s to '%s'.", client:Name(), arg[1], arg[2])
	end)
	nut.log.AddType("connect", function(client, ...)
		return L("%s has connected.", client:SteamName())
	end)
	nut.log.AddType("disconnect", function(client, ...)
		return L("%s has disconnected.", client:SteamName())
	end)
	nut.log.AddType("charCreate", function(client, ...)
		local arg = {...}
		return L("%s created the character '%s'", client:SteamName(), arg[1])
	end)
	nut.log.AddType("charLoad", function(client, ...)
		local arg = {...}
		return L("%s loaded the character '%s'", client:SteamName(), arg[1])
	end)
	nut.log.AddType("charDelete", function(client, ...)
		local arg = {...}
		return L("%s (%s) deleted character '%s'", client:SteamName(), client:SteamID(), arg[1])
	end)
	nut.log.AddType("itemAction", function(client, ...)
		local arg = {...}
		local item = arg[2]
		return L("%s ran '%s' on item '%s' (#%s)", client:Name(), arg[1], item.name, item.id)
	end)
	nut.log.AddType("shipmentTake", function(client, ...)
		local arg = {...}
		return L("%s took '%s' from the shipment", client:Name(), arg[1])
	end)
	nut.log.AddType("shipmentOrder", function(client, ...)
		return L("%s ordered a shipment", client:Name())
	end)
	nut.log.AddType("buy", function(client, ...)
		local arg = {...}
		return L("%s purchased '%s' from the NPC", client:Name(), arg[1])
	end)
	nut.log.AddType("buydoor", function(client, ...)
		return L("%s purchased the door", client:Name())
	end)
	nut.log.AddType("playerHurt", function(client, ...)
		local arg = {...}
		return L("%s has taken %d damage from %s.", client:Name(), arg[1], arg[2])
	end)
	nut.log.AddType("playerDeath", function(client, ...)
		local arg = {...}
		return L("%s has killed %s.", arg[1], client:Name())
	end)

	function PLUGIN:PlayerInitialSpawn(client)
		nut.log.Add(client, "connect")
	end

	function PLUGIN:PlayerDisconnected(client)
		nut.log.Add(client, "disconnect")
	end

	function PLUGIN:OnCharCreated(client, character)
		nut.log.Add(client, "charCreate", character:GetName())
	end

	function PLUGIN:CharacterLoaded(character)
		local client = character:GetPlayer()
		nut.log.Add(client, "charLoad", character:GetName())
	end

	function PLUGIN:PreCharDelete(client, character)
		nut.log.Add(client, "charDelete", character:GetName())
	end

	function PLUGIN:OnTakeShipmentItem(client, itemClass, amount)
		local itemTable = nut.item.list[itemClass]
		nut.log.Add(client, "shipmentTake", itemTable.name)
	end

	function PLUGIN:OnCreateShipment(client, shipmentEntity)
		nut.log.Add(client, "shipmentOrder")
	end

	function PLUGIN:OnCharTradeVendor(client, vendor, x, y, invID, price, isSell)
	end

	local logInteractions = {
		["drop"] = true,
		["take"] = true,
		["equip"] = true,
		["unequip"] = true,
	}

	function PLUGIN:OnPlayerInteractItem(client, action, item)
		if (type(item) == "Entity") then
			if (IsValid(item)) then
				local entity = item
				local itemID = item.nutItemID
				item = nut.item.instances[itemID]
			else
				return
			end
		elseif (type(item) == "number") then
			item = nut.item.instances[item]
		end

		if (!item) then
			return
		end

		nut.log.Add(client, "itemAction", action, item)
	end
end
