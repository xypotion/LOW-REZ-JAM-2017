function startHeroTurn()
	--probably don't put this here (TODO), but spawn enemies
	spawnEnemies()
	
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

function heroImpetus(dy, dx) --TODO rename playerImpetus
	local y, x = locateHero()
	
	--see what lies ahead TODO this can still be optimized
	local destClass = nil
	if stage.field[y + dy] and stage.field[y + dy][x + dx] then
		destClass = stage.field[y + dy][x + dx].contents.class
	else
		--seems like you're trying to move off the grid, so...
		return
	end
	
	-- --AP reduction
	-- hero.ap.actual = hero.ap.actual - 1
	-- queue(actuationEvent(hero.ap, -1))
	
	--move or fight
	if destClass == "clear" then
		if heroStuck() then
			heroStuckMove(y, x, dy, dx)
		else
			reduceHeroAP()
			heroMove(y, x, dy, dx)
		end
	end
	
	if destClass == "enemy" then
		reduceHeroAP()
		heroFight(y, x, dy, dx)
	end
end

--TODO probably rename
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

	--reserve target, set vacating, and queue cell ops
	-- stage.field[ty][tx].reserved = true
	-- stage.field[y][x].vacating = true
	queueSet({
		cellOpEvent(ty, tx, hero),
		cellOpEvent(y, x, clear()),
		poseEvent(ty, tx, moveFrames)
	})
	
	processNow()
end

--TODO clean up, maybe rename
function heroFight(y, x, dy, dx)
	local hy, hx = locateHero()
	local ty, tx = y + dy, x + dx --TODO you have two sets of hero coordinates...
	local target = stage.field[ty][tx].contents
	
	target.hp.actual = target.hp.actual - hero.attack
	
	--queue attack animation & damage actuation
	queueSet({
		poseEvent(hy, hx, {
			{pose = "idle", yOffset = dy * 4, xOffset = dx * 4},
			{pose = "idle", yOffset = dy * 5, xOffset = dx * 5},
			{pose = "idle", yOffset = dy * 2, xOffset = dx * 2},
			{pose = "idle", yOffset = dy * 1, xOffset = dx * 1},
			{pose = "idle", yOffset = 0, xOffset = 0},
		}),
		actuationEvent(target.hp, -hero.attack)
	})
	
	--stick (unless defeated)
	if target.reaction == "stick" and target.hp.actual > 0 then
		queue(statusEvent(ty, tx, "stick"))
	end
	
	--explode; damage hero (with effect) & queue removal
	if target.reaction == "explode" then
		print("i'm exploding!!!", ty, tx)
		target.hp.actual = 0
	end
	
	--kill if at 0 HP
	if target.hp.actual <= 0 then
		--dead; queue removal from grid
		queue(cellOpEvent(ty, tx, clear()))
		
		--remove stick status "pointer"
		queue(statusEvent(ty, tx, "none"))
	end

	processNow()
end

function heroSpecialAttack()
	if hero.sp.actual <= 0 or hero.sewyAdjacent then
		--TODO some kind of error feedback? or is silence OK?
		return
	end
	
	--TODO don't allow casting if no enemies present? or do? :o maybe if all of stage's enemies are dead?
	
	--reduce SP and AP
	hero.sp.actual = hero.sp.actual - 1
	hero.ap.actual = hero.ap.actual - 1
	queueSet({
		actuationEvent(hero.sp, -1),
		actuationEvent(hero.ap, -1),
	})
	
	--and do stuff!
	
	--DEBUG
	attacky = {}
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
	killy = {}
	for y, r in ipairs(stage.field) do
		for x, c in ipairs(r) do
			if c and c.contents and c.contents.class and c.contents.class == "enemy" then
				if c.contents.hp.actual <= 0 then
					push(killy, cellOpEvent(y, x, clear()))
				end
			end
		end
	end
	queueSet(killy)
	--END DEBUG
	
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
	for y,r in ipairs(stage.field) do
		for x,c in ipairs(r) do
			if c and c.contents and c.contents.class and c.contents.class == "hero" then
				return y, x
			end
		end
	end
end