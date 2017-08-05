function queueEnemyTurn()
	--fade to night
	queue(bgEvent("night1", 0.5))
	
	--all enemies take their turns
	local cells = shuffledCellList()
	for i, coords in ipairs(cells) do
		local c = stage.field[coords[1]][coords[2]]
		--TODO what if enemy has >1 AP? gotta loop again here (maybe just a "while")
		if c and c.contents and c.contents.class and c.contents.class == "enemy" then
			if c.contents.ai == "melee" then
				meleeTurnAt(coords[1], coords[2])
			elseif c.contents.ai == "ranged" then
				rangerTurnAt(c.contents)
			elseif c.contents.ai == "healer" then
				healerTurn(c.contents)
			end
		end
	end
	
	--pull from stage.enemylist to spawn new enemies
	spawnEnemies()
	
	--reset hero AP & fade back to day
	hero.ap.actual = hero.ap.max --ap reset
	queueSet({
		bgEvent("day1", 0.5),
		actuationEvent(hero.ap, 3)
	})
end

--[[
take list of all cells and shuffle; iterate through that set
for each enemy:
	loop while enemy has AP
	weigh available options: approach hero, escape hero, attack, heal (if applicable) -> do favorite
	before moving, must check destination cell to see if it's already reserved.
]]

function meleeTurnAt(ey, ex)
	--get adjacent cells
	local ac = getAdjacentCells(ey, ex)
	
	--if hero is adjacent, attack (reducing AP)
	local heroAdjacent = false
	local hy, hx = locateHero()
	for i, c in pairs(ac) do
		if c.y == hy and c.x == hx then
			heroAdjacent = true
		end
	end
	
	if heroAdjacent then
		enemyAttackHero(ey, ex, hy, hx)
		return
	end
	
	--otherwise, where's hero? move closer (vertically first). check reservation/vacancy status, too
	print(ey, ex, "wants to move closer")
end

function rangerTurn()
end

function healerTurn()
end

function enemyAttackHero(ey, ex, hy, hx)
	local dy, dx = hy - ey, hx - ex
	local attacker = stage.field[ey][ex].contents
	
	--first of all, reduce attacker AP
	attacker.ap.actual = attacker.ap.actual - 1
	print("attacker's AP:", stage.field[ey][ex].contents.ap.actual)
	
	--reduce hero HP
	hero.hp.actual = hero.hp.actual - attacker.attack

	--queue enemy attack animation & hero damage actuation
	queueSet({
		poseEvent(ey, ex, { --TODO refactor to share pose code with heroFight(), also TODO maybe not idle pose? eh
			{pose = "idle", yOffset = dy * 4, xOffset = dx * 4},
			{pose = "idle", yOffset = dy * 5, xOffset = dx * 5},
			{pose = "idle", yOffset = dy * 2, xOffset = dx * 2},
			{pose = "idle", yOffset = dy * 1, xOffset = dx * 1},
			{pose = "idle", yOffset = 0, xOffset = 0},
		}),
		actuationEvent(hero.hp, -attacker.attack)
	})
	
	--hero defeated? TODO game over implementation
end

function enemyMove()
end

--this feels messy, but might be the best way? hm
function getAdjacentCells(y, x)
	local cells = {}
	
	if y + 1 <= 3 then push(cells, {y = y + 1, x = x}) end
	if y - 1 >= 1 then push(cells, {y = y - 1, x = x}) end
	if x + 1 <= 3 then push(cells, {y = y, x = x + 1}) end
	if x - 1 >= 1 then push(cells, {y = y, x = x - 1}) end
	
	return cells
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
	local empties = allEmptyOrVacatingNotReservedCellsShuffled()
	
	--if there's space, spawn all enemies in list
	if table.getn(list) <= table.getn(empties) then		
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

--TODO you know there's a nicer way to do this, lazy bones
function shuffledCellList()
	return shuffle({
		{1, 1},
		{1, 2},
		{1, 3},
		{2, 1},
		{2, 2},
		{2, 3},
		{3, 1},
		{3, 2},
		{3, 3},		
	})
end