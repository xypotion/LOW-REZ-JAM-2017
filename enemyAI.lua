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

function queueFullEnemyTurn(ey, ex)
	--DEBUG
	print("queueing full enemy turn at", ey, ex)
	-- queue(animEvent(c.y, c.x, sparkAnimFrames()))
	meleeTurnAt(ey, ex)
	
	--reduce AP; this will happen whether they actually take an action or not, which is good
	stage.field[ey][ex].contents.ap.actual = stage.field[ey][ex].contents.ap.actual - 1
	-- print("attacker's AP:", stage.field[ey][ex].contents.ap.actual)
	
	-- queue(waitEvent(0.25)) --tempting to put this here, but no-ops just cause pointless waits, which is yucky
	--END DEBUG
end

function locationsOfAllEnemiesWithAP()
	local arr = {}
	
	--TODO use getAdjacentCells here, i think
	for y, r in ipairs(stage.field) do
		for x, c in ipairs(r) do
			if c and c.contents and c.contents.class and c.contents.class == "enemy" and c.contents.ap.actual > 0 then
				push(arr, {y = y, x = x})
			end
		end
	end
	
	-- getAdjacentCells(ey, ex, "enemy")
	--TODO COULD optimize this, or not since it won't be used soon
	
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
	--if hero is adjacent, attack, otherwise approach
	if heroAdjacentToEnemy(ey, ex) then
		enemyAttackHero(ey, ex)
	else
		enemyApproachHero(ey, ex, ac)
	end
end

function rangerTurn()
	--if hero is adjacent, try to move away
	--if hero is not adjacent (or enemy couldn't move away), attack
end

function healerTurn()
	--if any enemies are below max HP, heal all by 1
	--if not healing, act as melee
end

--"is there at least one adjacent cell containing a hero?"
function heroAdjacentToEnemy(ey, ex)
	return table.getn(getAdjacentCells(ey, ex, "hero")) > 0
end

function enemyAttackHero(ey, ex)
	local hy, hx = locateHero()
	local dy, dx = hy - ey, hx - ex
	local attacker = stage.field[ey][ex].contents
		
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

--real talk: TODO you gotta implement a* or something because this algo is awkward. hiding behind your friend is not the same as approaching your target
function enemyApproachHero(ey, ex, ac)
	local emptyNeighbors = getAdjacentCells(ey, ex, "clear")
	local hy, hx = locateHero()
	local currentDistance = math.abs(ey - hy) + math.abs(ex - hx)
	
	--ditto for powerups? or should enemies never move over these? TODO decide, i guess. leaning no, but maybe too easy to make a "wall" of powerups
	--this was kind of the reason for doing candidateCells at all, so TODO optimize this function if you're
	
	--find which cell, if any, will move the enemy closer. should always move vertically first
	local dest = nil
	for k, c in ipairs(shuffle(emptyNeighbors)) do
		local distance = math.abs(c.fieldY - hy) + math.abs(c.fieldX - hx)
		if distance < currentDistance and not dest then
			dest = c
		end
	end
	--could optimize ^ a little, but i think i'd rather just implement something else. baby's first pathing algorithm?
	
	--if a cell closer than currentDistance was found, move there
	if dest then
		local dy, dx = dest.fieldY - ey, dest.fieldX - ex
	
		local moveFrames = { --TODO this should be consolidated with similar heroMove() code
			{pose = "idle", yOffset = dy * -15, xOffset = dx * -15},
			{pose = "idle", yOffset = dy * -10, xOffset = dx * -10},
			{pose = "idle", yOffset = dy * -5, xOffset = dx * -5},
			{pose = "idle", yOffset = 0, xOffset = 0},
		}

		--queue cell ops & wait
		queueSet({
			cellOpEvent(dest.fieldY, dest.fieldX, stage.field[ey][ex].contents), --enemy -> destination
			cellOpEvent(ey, ex, clear()), --current cell -> clear
			poseEvent(dest.fieldY, dest.fieldX, moveFrames),
			waitEvent(0.25)
		})
	end
end

--search whole grid for cells at least min away and up to max away, optionally matching class
function cellsInDistanceRange(ly, lx, min, max, class) --l as in 'locus'
	local cells = {}
	
	for y, r in ipairs(stage.field) do
		for x, c in ipairs(r) do
			if math.abs(y - ly) + math.abs(x - lx) >= min and math.abs(y - ly) + math.abs(x - lx) <= max then
				--y-x is within specified distance range of ly-lx
				if class then
					if c.contents.class and c.contents.class == class then
						--we do care about class & it matches, so push
						push(cells, {fieldY = y, fieldX = x})
					end
				else
					--we don't care about class, just push
					push(cells, {fieldY = y, fieldX = x})
				end
			end
		end
	end
	
	return cells
end

--all clear cells 0 to 2 cells from 2,2 = the whole grid. filter for clear cells
function allClearCells()
	return cellsInDistanceRange(2, 2, 0, 2, "clear")
end

function getAdjacentCells(ly, lx, class)
	return cellsInDistanceRange(ly, lx, 1, 1, class)
end

--TODO. enemies should *spawn* in empty spaces first, then replace powerups if there's nowhere else
-- function allEmptiesThenPowerups()
-- end

--could easily see moving enemy creating/spawning to another separate file TODO
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
	local empties = shuffle(allClearCells())
	
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
			ap = {max = 1, actual = 1, shown = 1, posSound = nil, negSound = nil, quick = false},
			attack = 1,
			yOffset = 0,
			xOffset = 0
		}
	elseif species == "mercuri" then
		return {
			class = "enemy",
			species = "mercuri",
			pose = "idle",
			ai = "melee", --or ranged or healer
			hp = {max = 5, actual = 5, shown = 5, posSound = nil, negSound = nil, quick = true},
			ap = {max = 2, actual = 2, shown = 2, posSound = nil, negSound = nil, quick = false},
			attack = 1,
			yOffset = 0,
			xOffset = 0
		}
	end
end