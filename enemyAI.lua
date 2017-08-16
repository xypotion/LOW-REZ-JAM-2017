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
		--TODO ranged attack must look different
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
		local es = {}
		for i, c in pairs(enemyCells) do
			--get difference; can heal a max of 3 HP
			local need = cellAt(c.y, c.x).contents.hp.max - cellAt(c.y, c.x).contents.hp.actual
			if need > 3 then need = 3 end
			
			--only heal & animate for enemies that need it
			if need > 0 then
				cellAt(c.y, c.x).contents.hp.actual = cellAt(c.y, c.x).contents.hp.actual + need
			
				--push animation & HP actuation
				push(es, actuationEvent(cellAt(c.y, c.x).contents.hp, need))
				push(es, animEvent(c.y, c.x, sparkAnimFrames()))
			end
		end

		push(es, poseEvent(ey, ex, {{pose = "casting", yOffset = 0, xOffset = 0}}))
		push(es, animEvent(ey, ex, glowAnimFrames()))
		push(es, soundEvent("pharma"))
		queueSet(es)
		
		-- queueSet({
		-- 	waitEvent(0.25),
		-- 	poseEvent(ey, ex, {{pose = "idle", yOffset = 0, xOffset = 0}})
		-- })
		queue(waitEvent(0.25))
		queue(poseEvent(ey, ex, {{pose = "idle", yOffset = 0, xOffset = 0}}))
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
		
		--queue sound & pose stuff
		queue(soundEvent("gluttony"))
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
		glutton.hp.actual = glutton.hp.actual + need
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
		soundEvent("attack"),
		waitEvent(0.25)
	})
	
	if attacker.reaction == "stick" then
		queue(statusEvent(ey, ex, "stick"))
	end
	
	--check if hero defeated
	gameOverIFHeroDead()
end

--real talk: TODO you gotta implement a* or something because this algo is awkward. hiding behind your friend is not the same as approaching your target
	--maybe just always favor moving towards center? hack, but it would halfway fix this. not perfect, though
	--find distance to hero, recurse outward (somehow), scoring potential destinations? ehhhh? or look up a* :|
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
	local es = {
		animEvent(ey, ex, sparkAnimFrames()),
		soundEvent("nukey")
	}
	
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

--spawning bosses: go ahead and use the same algo as above, for the wild case that all other cells contain powers & there's nowhere to spawn at first TODO
--...but when do you announce the boss & change the UI?

function spawnEnemies(l)
	local empties = shuffle(allClearCells())
	local list = nil
	
	--either just assign l to list (usually for stage.startingEnemies), or find a set of enemies in stage.enemyList that will fit in the available space
	if l then
		list = l
	else
		local nextEnemies
		local loops = 1
		while not list and loops <= table.getn(stage.enemyList) do
		  nextEnemies = pop(stage.enemyList)
			if table.getn(nextEnemies) <= table.getn(empties) then
				list = nextEnemies
			else
				push(stage.enemyList, nextEnemies)
				print("wasn't enough room")
				tablePrint(stage.enemyList)
			end
			loops = loops + 1
		end
	end	
	
	--spawn all enemies in list one by one (if there's anything to spawn)
	if list then
		for k, en in ipairs(list) do
			local cell = pop(empties)
			local newEnemy = enemy(en)
			-- newEnemy.drop = pop(stage.powers) --leaving in in case you ever let common enemies drop rare powerups...
			newEnemy.drop = true
			queueSet({
				waitEvent(0.25),
				soundEvent("tick"),
				cellOpEvent(cell.y, cell.x, newEnemy)
			})
			enemyInfoPopupIfFirstTime(en)
		end
	end
end

-- function spawnEnemies(l)
-- 	--if not provided, get list of enemy species by popping off the stage's enemy list. if none, then return
-- 	local list = l or pop(stage.enemyList)
-- 	if not list then return end
--
-- 	local empties = shuffle(allClearCells())
--
-- 	--if there's space, spawn all enemies in list, one by one
-- 	if table.getn(list) <= table.getn(empties) then
-- 		for k, en in ipairs(list) do
-- 			local cell = pop(empties)
-- 			local newEnemy = enemy(en)
-- 			newEnemy.drop = pop(stage.powers)
-- 			queueSet({
-- 				waitEvent(0.25),
-- 				soundEvent("tick"),
-- 				cellOpEvent(cell.y, cell.x, newEnemy)
-- 			})
-- 		end
-- 	else
-- 		--there wasn't enough space! probably gotta loop through all to get it TODO what you want
-- 		print("not enough space for "..table.getn(list).." enemies!")
-- 		-- push(stage.enemyList, list)
-- 	end
-- end

function spawnBossAndSwitchUI()
	local empties = shuffle(allClearCells())
		
	if empties[1] then		
		-- there's at least one clear cell for the boss, so spawn	it
		stage.boss = enemy(stage.bossSpecies)
	
		print("queue boss spawn now ~~")
		queueSet({
			waitEvent(0.25),
			soundEvent("tick"),
			cellOpEvent(empties[1].y, empties[1].x, stage.boss)
		})
		enemyInfoPopupIfFirstTime(stage.bossSpecies)
	else
		--miraculously, no free spaces exist; try again next round
	end
end

function enemy(species)
	--base enemy
	local enemy = {
		class = "enemy",
		species = species,
		pose = "idle",
		ai = "melee",
		hp = {max = 5, actual = 0, shown = 0, posSound = nil, negSound = nil},
		ap = {max = 1, actual = 0, shown = 0, posSound = nil, negSound = nil},
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

	else
		--it's a boss
		enemy.isBoss = true
		
		if species == "heat" then
			enemy.hp.max = 16
			enemy.ap.max = 1
			enemy.attack = 2 --TODO "heats up"?
		elseif species == "invasive" then
			enemy.hp.max = 30
			enemy.ap.max = 1
			enemy.effect = "stick"
			enemy.reaction = "stick" 
		elseif species == "oil" then
			enemy.hp.max = 21
			enemy.ap.max = 2
		elseif species == "light" then
			enemy.hp.max = 24
			enemy.ap.max = 2
			enemy.ai = "ranger"
		elseif species == "noise" then
			enemy.hp.max = 30
			enemy.ap.max = 2 --TODO 3? nothing gets 3 AP... 3 for Light if you swap with Noise? or shift XPS and Noise down?
			--TODO stinky like sewy? maybe whole field?
		elseif species == "xps" then
			enemy.hp.max = 50
			enemy.ap.max = 1
			--auto-healing? TODO reduce HP if so
		elseif species == "gluttony" then
			enemy.hp.max = 30
			enemy.ap.max = 2
			enemy.attack = 1
			enemy.ai = "glutton"
		elseif species == "greed" then
			enemy.hp.max = 30
			enemy.ap.max = 2
			--TODO always summons a pharma with first action
		elseif species == "apathy" then
			enemy.hp.max = 99
			enemy.ap.max = 1
			enemy.attack = 2
			--TODO always summons with first action
		end
	end
	
	enemy.hp.actual = enemy.hp.max
	enemy.hp.shown = enemy.hp.max
	enemy.ap.actual = enemy.ap.max
	enemy.ap.shown = enemy.ap.max
	
	return enemy
end

function enemyInfoPopupIfFirstTime(species)
	if game.seenPopups[species] then
		--already seen during this game!
		return
	else
		game.seenPopups[species] = true
		queue(screenEvent(enemyInfo[species], true, true, enemySheets[species]))
	end
end

enemyInfo = {
		toxy = "\n\nTOXY\nA meanie that hurts from afar.",
		mercuri = "\n\nMERCURI\nQuick like quicksilver!", 
		algy = "\n\nALGY\nSticky - don't touch it!",
		sewy = "\n\nSEWY\nUnbearably smelly! Yuck!!",
		garby = "\n\nGARBY\nConsumes anything in reach.",
		plasty = "\n\nPLASTY\nHard to break down!",
		pharma = "\n\nPHARMA\nGood for you... or not?", 
		nukey = "\n\nNUKEY\nDANGER: UNSTABLE ELEMENTS",
		oil = "\n\n- BOSS -\n\nOIL\nSPILL",
		heat = "\n\n- BOSS -\n\nHEAT\nPOLLUTION",
		noise = "\n\n- BOSS -\n\nNOISE\nPOLLUTION",
		light = "\n\n- BOSS -\n\nL IGHT\nPOLLUTION",
		invasive = "\n\n- BOSS -\n\nINVASIVE\nSPECIES",
		xps = "\n\n- BOSS -\n\nEXTRUDED\nPOLYSTYRENE",
		gluttony = "\n\n- BOSS -\n\nGLUTTONY",
		greed = "\n\n- BOSS -\n\nGREED",
		apathy = "\n\n- BOSS -\n\nAPATHY",
}