function startEnemyTurn()
	print("queueing night")
	
	--reset all enemies APs
	for y, r in ipairs(stage.field) do
		for x, c in ipairs(r) do
			if c and c.contents and c.contents.class and c.contents.class == "enemy" then
				c.contents.ap.actual = c.contents.ap.max
			end
		end
	end
	
	--transition to night
	queueSet({
		gameStateEvent("state", "night"),
		bgEvent("night1", 0.5)
	})
end

function queueEnemyTurn()
	--fade to night
	-- queue(bgEvent("night1", 0.5))
	
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
	-- hero.ap.actual = hero.ap.max --ap reset
	-- queueSet({
	-- 	bgEvent("day1", 0.5),
	-- 	actuationEvent(hero.ap, 3)
	-- })
	startHeroTurn()
end

function queueFullEnemyTurn(c)
	--DEBUG
	print("queueing full enemy turn at", c.y, c.x)
	-- queue(animEvent(c.y, c.x, sparkAnimFrames()))
	meleeTurnAt(c.y, c.x)
	stage.field[c.y][c.x].contents.ap.actual = stage.field[c.y][c.x].contents.ap.actual - 1
	-- queue(waitEvent(0.25)) --tempting to put this here, but no-ops just cause pointless waits, which is yucky
	--END DEBUG
end

function allEnemiesWithAP()
	local arr = {}
	
	for y, r in ipairs(stage.field) do
		for x, c in ipairs(r) do
			if c and c.contents and c.contents.class and c.contents.class == "enemy" and c.contents.ap.actual > 0 then
				push(arr, {y = y, x = x})
			end
		end
	end
	
	return arr
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
		-- return
	else
		--otherwise, where's hero? move closer (vertically first).
		-- print(ey, ex, "wants to move closer")
		enemyApproachHero(ey, ex, hy, hx, ac)
	end

	--reduce AP; this will happen whether they actually take an action or not, which is good
	stage.field[ey][ex].contents.ap.actual = stage.field[ey][ex].contents.ap.actual - 1
	-- print("attacker's AP:", stage.field[ey][ex].contents.ap.actual)
end

function rangerTurn()
end

function healerTurn()
end

function enemyAttackHero(ey, ex, hy, hx)
	local dy, dx = hy - ey, hx - ex
	local attacker = stage.field[ey][ex].contents
	
	--first of all, reduce attacker AP
	-- attacker.ap.actual = attacker.ap.actual - 1
	-- print("attacker's AP:", stage.field[ey][ex].contents.ap.actual)
	
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
		actuationEvent(hero.hp, -attacker.attack),
		waitEvent(0.25)
	})
	
	--hero defeated? TODO game over implementation
end

--there are a bunch of print()s in here because it took me a million years to make it work. all because i flipped xs and ys. wow.
--real talk: TODO you gotta implement a* or something because this algo is awkward. hiding behind your friend is not the same as approaching your target
function enemyApproachHero(ey, ex, hy, hx, ac)
	-- local dy, dx = hy - ey, hx - ex
	local currentDistance = math.abs(ey - hy) + math.abs(ex - hx)
	local attacker = stage.field[ey][ex].contents
	
	--filter ac (adjacent cells) for clear cells
	local candidateCells = {}
	
	for k, c in ipairs(ac) do
		if stage.field[c.y][c.x].contents.class == "clear" then
			push(candidateCells, c)
		end
	end
	
	-- print("current distance from hero:", currentDistance)
	-- print("found this many clear adjacent cells:", table.getn(candidateCells))
	
	--ditto for powerups? or should enemies never move over these? TODO decide, i guess. leaning no, but maybe too easy to make a "wall" of powerups
	--this was kind of the reason for doing candidateCells at all, so TODO optimize this function if you're
	
	--find which cell, if any, will move the enemy closer. should always move vertically first
	local dest = nil
	for k, c in ipairs(shuffle(candidateCells)) do
		local distance = math.abs(c.y - hy) + math.abs(c.x - hx)
		-- print("...calculating distance... abs("..c.y.."-"..hy..") + abs("..c.x.."-"..hy..") = "..distance)
		-- print(c.y, c.x, "would be this far from hero: ", distance)
		if distance < currentDistance and not dest then
			dest = c
			-- print("that's closer! i'll go there.")
		end
	end
	
	--find a cell that's closer? 
	if dest then
		local dy, dx = dest.y - ey, dest.x - ex
		-- print(dy, dx)
	
		local moveFrames = { --TODO this should be consolidated with similar heroMove() code
			{pose = "idle", yOffset = dy * -15, xOffset = dx * -15},
			{pose = "idle", yOffset = dy * -10, xOffset = dx * -10},
			{pose = "idle", yOffset = dy * -5, xOffset = dx * -5},
			{pose = "idle", yOffset = 0, xOffset = 0},
		}
		-- print(ey, ex, "moving to", dest.y, dest.x)

		--queue cell ops
		queueSet({
			cellOpEvent(dest.y, dest.x, stage.field[ey][ex].contents), --enemy -> destination
			cellOpEvent(ey, ex, clear()), --current cell -> clear
			poseEvent(dest.y, dest.x, moveFrames),
			waitEvent(0.25)
		})
	else
		-- print(ey, ex, "didn't find a closer cell within reach")
	end
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

--could easily see moving enemy creating/spawning to another separate file TODO

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
			species = "algy",
			pose = "idle",
			ai = "melee", --or ranged or healer
			hp = {max = 5, actual = 5, shown = 5, posSound = nil, negSound = nil, quick = true},
			ap = {max = 1, actual = 1, shown = 1, posSound = nil, negSound = nil, quick = false},
			attack = 1,
			yOffset = 0,
			xOffset = 0
		}
	elseif species == "toxy" then
		return {
			class = "enemy",
			species = "toxy",
			pose = "idle",
			ai = "ranged", --or ranged or healer
			hp = {max = 5, actual = 5, shown = 5, posSound = nil, negSound = nil, quick = true},
			ap = {max = 2, actual = 2, shown = 2, posSound = nil, negSound = nil, quick = false},
			attack = 1,
			yOffset = 0,
			xOffset = 0
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