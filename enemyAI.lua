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
	local enemy = cellAt(ey, ex).contents
	
	if enemy.ai == "melee" then
		meleeTurnAt(ey, ex)
	elseif enemy.ai == "ranger" then
		rangerTurnAt(ey, ex)
	elseif enemy.ai == "healer" then
		healerTurnAt(ey, ex)
	elseif enemy.ai == "glutton" then
		gluttonTurnAt(ey, ex)
	end
	
	--reduce AP; this will happen whether they actually take an action or not, which is good
	cellAt(ey, ex).contents.ap.actual = cellAt(ey, ex).contents.ap.actual - 1
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
	
	--TODO COULD optimize this, or not since it will be obsolete when you change enemy turn order code
	
	return arr
end

function meleeTurnAt(ey, ex)	
	--if hero is adjacent, attack, otherwise approach
	if heroAdjacentToEnemy(ey, ex) then
		enemyAttackHero(ey, ex)
	else
		enemyApproachHero(ey, ex, ac)
	end
end

--TODO attacking should look like a cast, not a melee hit
function rangerTurnAt(ey, ex)
	--if hero is adjacent and there's at least one clear neighbor, run away
	if heroAdjacentToEnemy(ey, ex) and table.getn(getAdjacentCells(ey, ex, "clear")) >= 1 then
		enemyFleeHero(ey, ex)
	else
		--otherwise attack (either not next to hero or there was nowhere to flee to)
		enemyAttackHero(ey, ex)
	end
end

function healerTurnAt(ey, ex)
	--see if any enemies are below max HP
	local enemyCells = getAllCells("enemy")
	local hurt = false
	
	for i, c in pairs(enemyCells) do
		if cellAt(c.y, c.x).contents.hp.actual < cellAt(c.y, c.x).contents.hp.max then
			hurt = true
		end
	end
	
	--heal all if any are hurt, otherwise act like melee
	if hurt then
		--TODO casting pose for the healer
		
		local es = {}
		for i, c in pairs(enemyCells) do
			--get difference; can heal a max of 3 HP
			local need = cellAt(c.y, c.x).contents.hp.max - cellAt(c.y, c.x).contents.hp.actual
			if need > 3 then need = 3 end
			
			cellAt(c.y, c.x).contents.hp.actual = cellAt(c.y, c.x).contents.hp.actual + need
			
			--push animation & HP actuation
			push(es, actuationEvent(cellAt(c.y, c.x).contents.hp, need))
			push(es, animEvent(c.y, c.x, sparkAnimFrames()))
		end
		
		queueSet(es)
	else
		meleeTurnAt(ey, ex)
	end
end

function gluttonTurnAt(ey, ex)
	local powerNeighbors = shuffle(getAdjacentCells(ey, ex, "power"))
	
	--any neighbors have powerups?
	if peek(powerNeighbors) then
		local target = peek(powerNeighbors)
		local glutton = cellAt(ey, ex).contents
		local dy, dx = target.y - ey, target.x - ex
		
		--queue pose stuff
		queue(poseEvent(ey, ex, { --TODO move elsewhere
			{pose = "casting", yOffset = dy * 1, xOffset = dx * 1},
			{pose = "casting", yOffset = dy * 1, xOffset = dx * 1},
			{pose = "casting", yOffset = dy * 2, xOffset = dx * 2},
			{pose = "casting", yOffset = dy * 2, xOffset = dx * 2},
			{pose = "casting", yOffset = dy * 3, xOffset = dx * 3},
			{pose = "casting", yOffset = dy * 3, xOffset = dx * 3},
			{pose = "casting", yOffset = dy * 4, xOffset = dx * 4},
			{pose = "casting", yOffset = dy * 4, xOffset = dx * 4},
			{pose = "casting", yOffset = dy * 5, xOffset = dx * 5},
			{pose = "casting", yOffset = dy * 5, xOffset = dx * 5},
			{pose = "casting", yOffset = dy * 6, xOffset = dx * 6},
			{pose = "casting", yOffset = dy * 6, xOffset = dx * 6},
			{pose = "casting", yOffset = dy * 7, xOffset = dx * 7},
			{pose = "casting", yOffset = dy * 7, xOffset = dx * 7},
			{pose = "casting", yOffset = dy * 8, xOffset = dx * 8},
			{pose = "casting", yOffset = dy * 8, xOffset = dx * 8},
			{pose = "casting", yOffset = dy * 9, xOffset = dx * 9},
			{pose = "casting", yOffset = dy * 9, xOffset = dx * 9},
			{pose = "casting", yOffset = dy * 10, xOffset = dx * 10},
			{pose = "casting", yOffset = dy * 10, xOffset = dx * 10},
			{pose = "casting", yOffset = dy * 11, xOffset = dx * 11},
			{pose = "casting", yOffset = dy * 11, xOffset = dx * 11},
			{pose = "casting", yOffset = dy * 12, xOffset = dx * 12},
			{pose = "casting", yOffset = dy * 12, xOffset = dx * 12},
			{pose = "casting", yOffset = dy * 13, xOffset = dx * 13},
			{pose = "casting", yOffset = dy * 13, xOffset = dx * 13},
			{pose = "casting", yOffset = dy * 14, xOffset = dx * 14},
			{pose = "casting", yOffset = dy * 14, xOffset = dx * 14},
			{pose = "casting", yOffset = dy * 15, xOffset = dx * 15},
			{pose = "casting", yOffset = dy * 15, xOffset = dx * 15},
		}))

		--THEN queue resulting move (powerup consumption/removal implied) & enemy HP recovery
		local events = {}
		
		push(events, cellOpEvent(target.y, target.x, glutton))
		push(events, cellOpEvent(ey, ex, clear()))
		push(events, poseEvent(target.y, target.x, {{pose = "idle", yOffset = 0, xOffset = 0}}))
		
		local need = glutton.hp.max - glutton.hp.actual
		push(events, actuationEvent(glutton.hp, need))
		push(events, waitEvent(0.25))
		
		queueSet(events)
		
		--reduce AP
		-- glutton.ap.actual = glutton.hp.actual - 1 --wait, no, this happens already
	else 
		meleeTurnAt(ey, ex)
	end
end

--"is there at least one adjacent cell containing a hero?"
function heroAdjacentToEnemy(ey, ex)
	return table.getn(getAdjacentCells(ey, ex, "hero")) > 0
end

function enemyAttackHero(ey, ex)
	local hy, hx = locateHero()
	local dy, dx = hy - ey, hx - ex
	local attacker = cellAt(ey, ex).contents
		
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
	
	if attacker.reaction == "stick" then
		queue(statusEvent(ey, ex, "stick"))
	end
	
	--hero defeated? TODO game over implementation
end

--real talk: TODO you gotta implement a* or something because this algo is awkward. hiding behind your friend is not the same as approaching your target
function enemyApproachHero(ey, ex)
	local emptyNeighbors = getAdjacentCells(ey, ex, "clear")
	local hy, hx = locateHero()
	local currentDistance = math.abs(ey - hy) + math.abs(ex - hx)
		
	--find which cell, if any, will move the enemy closer
	local dest = nil
	for k, c in ipairs(shuffle(emptyNeighbors)) do
		local distance = math.abs(c.y - hy) + math.abs(c.x - hx)
		if distance < currentDistance and not dest then
			dest = c
		end
	end
	--could optimize ^ a little, but i think i'd rather just implement something else. baby's first pathing algorithm?
	
	--if a cell closer than currentDistance was found, move there
	if dest then
		enemyMoveTo(ey, ex, dest.y, dest.x)
	end
end

function enemyFleeHero(ey, ex)
	local emptyNeighbors = getAdjacentCells(ey, ex, "clear")
	local hy, hx = locateHero()
	local currentDistance = math.abs(ey - hy) + math.abs(ex - hx)
		
	--find which cell, if any, will move the enemy further from hero
	local dest = nil
	for k, c in ipairs(shuffle(emptyNeighbors)) do
		local distance = math.abs(c.y - hy) + math.abs(c.x - hx)
		if distance > currentDistance and not dest then
			dest = c
		end
	end
	
	--if a cell further than currentDistance was found, move there
	if dest then
		enemyMoveTo(ey, ex, dest.y, dest.x)
	end
end

--TODO this should be consolidated with very similar heroMove() code
function enemyMoveTo(ey, ex, ty, tx)
	local dy, dx = ty - ey, tx - ex

	local moveFrames = { 
		{pose = "idle", yOffset = dy * -15, xOffset = dx * -15},
		{pose = "idle", yOffset = dy * -10, xOffset = dx * -10},
		{pose = "idle", yOffset = dy * -5, xOffset = dx * -5},
		{pose = "idle", yOffset = 0, xOffset = 0},
	}

	--queue cell ops & wait
	queueSet({
		cellOpEvent(ty, tx, cellAt(ey, ex).contents), --enemy -> destination
		cellOpEvent(ey, ex, clear()), --current cell -> clear
		poseEvent(ty, tx, moveFrames),
		waitEvent(0.25) --if you move this somewhere higher in the call stack, you can probably merge enemyMoveTo and heroMove entirely! TODO
	})
end

function explosionAt(ey, ex)
	local nukey = cellAt(ey, ex).contents
	
	--set hp to 0
	nukey.hp.actual = 0
	
	--events: explosion animation on self...
	local es = {animEvent(ey, ex, sparkAnimFrames())}
	
	--...explosion animation on neighbors TODO sort of misleading since it doesn't damage other enemies
	for i, c in pairs(getAdjacentCells(ey, ex)) do
		push(es, animEvent(c.y, c.x, sparkAnimFrames()))
	end
	
	--...damage to hero if adjacent
	if heroAdjacentToEnemy(ey, ex) then
		hero.hp.actual = hero.hp.actual - 2
		push(es, actuationEvent(hero.hp, -2))
	end
	
	--...nukey removal
	push(es, cellOpEvent(ey, ex, clear()))
	
	--then queue them!
	queueSet(es)
end

----------------------------------------------------------------------------------------------------------------------------------------------------

--search whole grid for cells at least min away and up to max away, optionally matching class
--this can still be optimized, methinks TODO something mathy, not just looping over whole grid. low priority, though
function cellsInDistanceRange(ly, lx, min, max, class) --l as in 'locus'
	local cells = {}
	
	for y, r in ipairs(stage.field) do
		for x, c in ipairs(r) do
			if math.abs(y - ly) + math.abs(x - lx) >= min and math.abs(y - ly) + math.abs(x - lx) <= max then
				--y-x is within specified distance range of ly-lx
				if class then
					if c.contents.class and c.contents.class == class then
						--we do care about class & it matches, so push
						push(cells, {y = y, x = x})
					end
				else
					--we don't care about class, just push
					push(cells, {y = y, x = x})
				end
			end
		end
	end
	
	return cells
end

--cells 0 to 2 cells from 2,2 = the whole grid
function getAllCells(class)
	return cellsInDistanceRange(2, 2, 0, 2, class)
end

function allClearCells()
	return getAllCells("clear")
end

function getAdjacentCells(ly, lx, class)
	return cellsInDistanceRange(ly, lx, 1, 1, class)
end

----------------------------------------------------------------------------------------------------------------------------------------------------

--could easily see moving enemy creating/spawning to another separate file TODO
--[[
init: take stage's list of enemies and shuffle
end of each night: 
  if there's enough open space, pop the next set of enemies and insert randomly
	if less space than required for spawn-set, spawn NEXT set. maybe pop big one off the stack and push back on the end. careful of infinite loops here
]]

function spawnEnemies(l)
	--if not provided, get list of enemy species by popping off the stage's enemy list
	local list = l or pop(stage.enemyList) --TODO check this before popping
	
	if not list then return end --...or after. TODO eh
	
	local events = {}
	local empties = shuffle(allClearCells())
	
	--if there's space, spawn all enemies in list
	if table.getn(list) <= table.getn(empties) then		
		for k, en in ipairs(list) do
			local cell = pop(empties)
			local newEnemy = enemy(en)
			newEnemy.drop = pop(stage.powers)
			push(events, cellOpEvent(cell.y, cell.x, newEnemy))
		end
	end
	
	--actually queue the spawn events
	queueSet(events)
end

function enemy(species)
	--base enemy
	local enemy = {
		class = "enemy",
		species = species,
		pose = "idle",
		ai = "melee",
		hp = {max = 5, actual = 0, shown = 0, posSound = nil, negSound = nil, quick = true},
		ap = {max = 1, actual = 0, shown = 0, posSound = nil, negSound = nil, quick = false},
		attack = 1,
		yOffset = 0,
		xOffset = 0
	}
	
	--hp and other species-specific stuff
	if species == "garby" then
		enemy.hp.max = 5
		enemy.ai = "glutton"
		
	elseif species == "plasty" then
		enemy.hp.max = 10 --4 hits if atk 3, 3 if atk 4, 2 if atk 5 (rare). this seems good
		
	elseif species == "algy" then
		enemy.hp.max = 7
		enemy.effect = "stick"
		enemy.reaction = "stick" 
		
	elseif species == "toxy" then
		enemy.hp.max = 5
		enemy.ai = "ranger"
		
	elseif species == "mercuri" then
		enemy.hp.max = 4
		enemy.ap.max = 2
		
	elseif species == "sewy" then
		enemy.hp.max = 5
		
	elseif species == "nukey" then
		enemy.hp.max = 3
		enemy.reaction = "explode"
		
	elseif species == "pharma" then
		enemy.hp.max = 7
		enemy.ai = "healer"
	end
	
	enemy.hp.actual = enemy.hp.max
	enemy.hp.shown = enemy.hp.max
	enemy.ap.actual = enemy.ap.max
	enemy.ap.shown = enemy.ap.max
	
	return enemy
end