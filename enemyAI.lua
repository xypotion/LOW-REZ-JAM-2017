function queueEnemyTurn()
	--DEBUG
	queue(bgEvent("night1", 0.5))
	-- hero.sp.actual = hero.sp.actual - 1
	-- queue(actuationEvent(hero.sp, -1))
	-- queue(bgEvent("night1", 1)) --fake "wait"
	-- local xxx, yyy = math.random(3), math.random(3) --spawny
	-- if stage.field[yyy][xxx].class == "clear" then
	-- 	queue(cellOpEvent(yyy, xxx, enemy("toxy")))
	-- end
	spawnEnemies()
	hero.ap.actual = 3 --ap reset
	queueSet({
		bgEvent("day1", 0.5),
		actuationEvent(hero.ap, 3)
	})
	--END DEBUG
end

--[[
take list of all cells and shuffle; iterate through that set
for each enemy:
	loop while enemy has AP
	weigh available options: approach hero, escape hero, attack, heal (if applicable) -> do favorite
	before moving, must check destination cell to see if it's already reserved.
]]

function meleeTurn()
end

function rangerTurn()
end

function healerTurn()
end

--might as well put spawning here, too?
--[[
init: take stage's list of enemies and shuffle
end of each night: 
  if there's enough open space, pop the next set of enemies and insert randomly
	if less space than required for spawn-set, spawn part and mash remainder into next set
  	...but please balance so this doesn't happen. 2 per turn = enough? 3 at most, on endgame stages, and only some sets?
]]

function spawnEnemies(l)
	local list = l or pop(stage.enemyList) --TODO check this before popping
	
	if not list then return end --...or after. TODO eh
	
	local es = {}
	local empties = allEmptiesNotReserved()
	
	--if there's space, spawn all enemies in list
	if table.getn(list) <= table.getn(empties) then
		shuffle(empties)
		
		for k, en in ipairs(list) do
			local cell = pop(empties)
			push(es, cellOpEvent(cell.fieldY, cell.fieldX, enemy(en)))
		end
	end
	
	--actually queue the spawn events
	queueSet(es)
end

function enemy(species)
	if species == "algy" then
		return {
			class = "enemy",
			species = "algy", --will be used for graphics TODO
			pose = "idle",
			ai = "melee", --or ranged or healer
			hp = {max = 5, actual = 5, shown = 5, posSound = nil, negSound = nil, quick = true},
			ap = {max = 1, actual = 1, shown = 1, posSound = nil, negSound = nil, quick = false},
			attack = 1
		}
	elseif species == "toxy" then
		return {
			class = "enemy",
			species = "toxy", --will be used for graphics TODO
			pose = "idle",
			ai = "ranged", --or ranged or healer
			hp = {max = 5, actual = 5, shown = 5, posSound = nil, negSound = nil, quick = true},
			ap = {max = 1, actual = 1, shown = 1, posSound = nil, negSound = nil, quick = false},
			attack = 1
		}
	end
end