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
			queueSet({
				waitEvent(0.25),
				soundEvent("tick"),
				cellOpEvent(cell.y, cell.x, enemy(en, true))
			})
			enemyInfoPopupIfFirstTime(en)
		end
	end
end

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

--used only for Greed and Apathy bosses, hence setting AP to 0
function spawnOneEnemy(species)
	local empties = shuffle(allClearCells())
		
	if empties[1] then
		-- there's at least one clear cell for the enemy, so spawn it
		local add = enemy(species, true)
		add.ap.actual = 0
		
		queueSet({
			waitEvent(0.25),
			soundEvent("tick"),
			cellOpEvent(empties[1].y, empties[1].x, add)
		})
		enemyInfoPopupIfFirstTime(species)
	else
		--no free spaces, womp wah
	end
end

function enemy(species, hasDrop)
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
		xOffset = 0,
		drop = hasDrop
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
			enemy.hp.max = 18
			enemy.ap.max = 1
			enemy.attack = 2
		elseif species == "invasive" then
			enemy.hp.max = 30
			enemy.ap.max = 1
			enemy.effect = "stick"
			enemy.reaction = "stick" 
		elseif species == "oil" then
			enemy.hp.max = 21
			enemy.ap.max = 2
		elseif species == "noise" then
			enemy.hp.max = 27
			enemy.ap.max = 2
		elseif species == "xps" then
			enemy.hp.max = 45
			enemy.ap.max = 1
			--auto-healing? TODO reduce HP if so
		elseif species == "light" then
			enemy.hp.max = 21
			enemy.ap.max = 3
			enemy.ai = "ranger"
		elseif species == "gluttony" then
			enemy.hp.max = 30
			enemy.ap.max = 2
			enemy.ai = "glutton"
		elseif species == "greed" then
			enemy.hp.max = 27
			enemy.ap.max = 2 --always summons a pharma with first action
			enemy.attack = 2
			enemy.ai = "greed"
		elseif species == "apathy" then
			enemy.hp.max = 72
			enemy.ap.max = 1
			enemy.attack = 2
			enemy.ai = "apathy"
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