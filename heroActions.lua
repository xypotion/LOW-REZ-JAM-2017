function initHero()
	--init hero
	hero = {
		class = "hero",
		hp = {max = 9, actual = 2, shown = 9, posSound = "hp", negSound = nil},
		ap = {max = 3, actual = 3, shown = 3, posSound = "sp", negSound = nil},
		sp = {max = 3, actual = 3, shown = 3, posSound = "sp", negSound = nil},
		attack = 3,
		powers = {},
		pose = "idle",
		yOffset = 0,
		xOffset = 0,
		statusAfflictors = {},
		sewyAdjacent = false
	}
	
	--TODO load stats from autosave
	
	--who's afflicting the hero? no one! yes, this is hacky, and yes, i should be using getters and setters. don't care right now, though
	hero.statusAfflictors[11] = "none"
	hero.statusAfflictors[12] = "none"
	hero.statusAfflictors[13] = "none"
	hero.statusAfflictors[21] = "none"
	hero.statusAfflictors[22] = "none"
	hero.statusAfflictors[23] = "none"
	hero.statusAfflictors[31] = "none"
	hero.statusAfflictors[32] = "none"
	hero.statusAfflictors[33] = "none"
end

function startHeroTurn()
	--reset hero AP
	hero.ap.actual = hero.ap.max
	
	--queue ap actuation & transition to day
	queueSet({
		bgEvent("day1", 0.5),
		actuationEvent(hero.ap, 3),
		gameStateEvent("state", "day"),
	})
end

function reduceHeroAP()
	hero.ap.actual = hero.ap.actual - 1
	queue(actuationEvent(hero.ap, -1))
end

function heroImpetus(dy, dx)
	local y, x = locateHero()
	
	--see what lies ahead
	local destClass = nil
	if cellAt(y + dy, x + dx) then
		destClass = cellAt(y + dy, x + dx).contents.class
	else
		--seems like you're trying to move off the grid, so...
		return
	end
	
	--move
	if destClass == "clear" then
		if heroStuck() then
			heroStuckMove(y, x, dy, dx)
		else
			reduceHeroAP()
			heroMove(y, x, dy, dx)
		end
	end
	
	--get powerup
	if destClass == "power" then
		if heroStuck() then
			heroStuckMove(y, x, dy, dx)
		else
			reduceHeroAP()
			heroGetPowerUp(y, x, dy, dx)
		end
	end
	
	--fight
	if destClass == "enemy" then
		reduceHeroAP()
		heroFight(y, x, dy, dx)
	end
end

--merge with enemyMoveTo() somehow TODO (maybe)
function heroMove(y, x, dy, dx)
	local ty, tx = y + dy, x + dx
	
	-- local moveFrames = {
	-- 	-- {pose = "idle", yOffset = dy * -15, xOffset = dx * -15},
	-- 	{pose = "idle", yOffset = dy * -12, xOffset = dx * -12},
	-- 	{pose = "idle", yOffset = dy * -9, xOffset = dx * -9},
	-- 	{pose = "idle", yOffset = dy * -6, xOffset = dx * -6},
	-- 	{pose = "idle", yOffset = dy * -3, xOffset = dx * -3},
	-- 	{pose = "idle", yOffset = 0, xOffset = 0},
	-- }

	local moveFrames = {
		{pose = "idle", yOffset = dy * -15, xOffset = dx * -15},
		{pose = "idle", yOffset = dy * -10, xOffset = dx * -10},
		{pose = "idle", yOffset = dy * -5, xOffset = dx * -5},
		{pose = "idle", yOffset = 0, xOffset = 0},
	}	

	--queue pose and cell ops
	queueSet({
		cellOpEvent(ty, tx, hero),
		cellOpEvent(y, x, clear()),
		poseEvent(ty, tx, moveFrames)
	})
	
	processNow()
end

function heroGetPowerUp(y, x, dy, dx)
	local ty, tx = y + dy, x + dx
	
	local moveFrames = {
		{pose = "idle", yOffset = dy * -15, xOffset = dx * -15},
		{pose = "idle", yOffset = dy * -10, xOffset = dx * -10},
		{pose = "idle", yOffset = dy * -5, xOffset = dx * -5},
		{pose = "idle", yOffset = 0, xOffset = 0},
	}
	
	local power = cellAt(ty, tx).contents
	local es = {}
	
	--apply powerup & push any actuations to event set. for each entry in power.effects[]...
	for i, effect in pairs(power.effects) do
		if effect.stat then
			local need = hero[effect.stat].max - hero[effect.stat].actual
			if need > effect.amount then need = effect.amount end
			hero[effect.stat].actual = hero[effect.stat].actual + need
			
			if power.actuate then
				push(es, actuationEvent(hero[effect.stat], need))
			end
		end
	end

	--queue pose and cell ops
	push(es, cellOpEvent(ty, tx, hero))
	push(es, cellOpEvent(y, x, clear()))
	push(es, poseEvent(ty, tx, moveFrames))
	
	queueSet(es)
	
	processNow()
end

function heroFight(y, x, dy, dx)
	local ty, tx = y + dy, x + dx
	local target = cellAt(ty, tx).contents
	
	target.hp.actual = target.hp.actual - hero.attack
	
	--queue attack animation & damage actuation
	queueSet({
		poseEvent(y, x, {
			{pose = "idle", yOffset = dy * 4, xOffset = dx * 4},
			{pose = "idle", yOffset = dy * 5, xOffset = dx * 5},
			{pose = "idle", yOffset = dy * 2, xOffset = dx * 2},
			{pose = "idle", yOffset = dy * 1, xOffset = dx * 1},
			{pose = "idle", yOffset = 0, xOffset = 0},
		}),
		actuationEvent(target.hp, -hero.attack),
		soundEvent("attack")
	})
	
	--stick (unless defeated)
	if target.reaction == "stick" and target.hp.actual > 0 then
		queue(statusEvent(ty, tx, "stick"))
	end
	
	--explode; damage hero (with effect) & queue removal
	if target.reaction == "explode" then
		print("i'm exploding!!!", ty, tx)
		explosionAt(ty, tx)
	end
	
	--kill if at 0 HP
	if target.hp.actual <= 0 then
		killEnemy(ty, tx)
	end

	processNow()
end

function killEnemy(ty, tx)
	local target = cellAt(ty, tx).contents
	
	--decrement enemy counter
	stage.enemyCount.actual = stage.enemyCount.actual - 1

	--drop an item (removing enemy), play sound, actuate count decrement
	if target.drop then
		queueSet({
			cellOpEvent(ty, tx, newPower(target.drop)),
			soundEvent("kill"),
			actuationEvent(stage.enemyCount, -1)
		})
	else
		queue(cellOpEvent(ty, tx, clear())) --also unnecessary? TODO or if you're in boss mode & enemies don't drop stuff, handle differently...?
	end
	
	--remove stick status "pointer"
	queue(statusEvent(ty, tx, "none"))
	
	if stage.enemyCount.actual == 0 then print ("time to queue a boss?!?!?!") end
end

function heroSpecialAttack()
	--NOPE if sewy adjacent
	if hero.sp.actual <= 0 or hero.sewyAdjacent then
		return
	end
		
	--reduce SP and AP
	hero.sp.actual = hero.sp.actual - 1
	hero.ap.actual = hero.ap.actual - 1
	queueSet({
		actuationEvent(hero.sp, -1),
		actuationEvent(hero.ap, -1),
	})
	
	--and do stuff!
	
	--DEBUG
	hy, hx = locateHero()
	attacky = {soundEvent("wish"), animEvent(hy, hx, glowAnimFrames())}
	for y, r in ipairs(stage.field) do
		for x, c in ipairs(r) do
			if c and c.contents and c.contents.class and c.contents.class == "enemy" then
				c.contents.hp.actual = c.contents.hp.actual - 1
				push(attacky, actuationEvent(c.contents.hp, -1))
				push(attacky, animEvent(y, x, sparkAnimFrames()))
			end
		end
	end
	queueSet(attacky)
	
	--looping again after attacking so that deaths happen after damage animactuation
	for y, r in ipairs(stage.field) do
		for x, c in ipairs(r) do
			if c and c.contents and c.contents.class and c.contents.class == "enemy" then
				if c.contents.hp.actual <= 0 then
					killEnemy(y, x)
				end
			end
		end
	end
	--END DEBUG TODO this attack should pick 3 and do 3 damage to each
	
	processNow()
end

function heroStuckMove(y, x, dy, dx)
	--queue failed-move animation
	queueSet({
		poseEvent(y, x, {
			{pose = "idle", yOffset = dy * 4, xOffset = dx * 4},
			{pose = "idle", yOffset = dy * 5, xOffset = dx * 5},
			{pose = "idle", yOffset = dy * 2, xOffset = dx * 2},
			{pose = "idle", yOffset = dy * 1, xOffset = dx * 1},
			{pose = "idle", yOffset = 0, xOffset = 0},
		}),
		--that's it! unless you want a sound or something
	})
end

function locateHero()
	local h = getAllCells("hero")[1]
	if h then 
		return h.y, h.x
	else 
		print("hero not found!")
		return nil, nil
	end
end