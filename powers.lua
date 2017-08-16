function newPower()
	local power = {
		class = "power",
	}
	
	if math.random(3) == 3 then
		power.type = "redFish"
		power.effects = {{stat = "sp", amount = 1}}
		power.actuate = true
	else
		power.type = "blueFish"
		power.effects = {{stat = "hp", amount = 1}}
		power.actuate = true
	end
	
	return power
end

-- function newPower(type)
-- 	local power = {
-- 		class = "power",
-- 		type = type,
-- 	}
--
-- 	if type == "blueFish" then
-- 		power.effects = {{stat = "hp", amount = 1}}
-- 		power.actuate = true
-- 	elseif type == "redFish" then
-- 		power.effects = {{stat = "sp", amount = 1}}
-- 		power.actuate = true
-- 	end
--
-- 	return power
-- end

function queueRarePowerups()
	-- print("queueing rare powerup placement")
end