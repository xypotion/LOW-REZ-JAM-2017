function newPower(type)
	local power = {
		class = "power",
		type = type,
	}
	
	if type == "blueFish" then
		power.effects = {{stat = "hp", amount = 3}}
		power.actuate = true
	end
	
	return power
end