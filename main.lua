require "queueProcessing"
require "eventSetQueue"
require "enemyAI"
require "animScripts"

function love.load()
	--initial setup stuff & constants
	math.randomseed(os.time())
	love.window.setMode(512, 512)
	
	love.graphics.setLineWidth(1)
	
	cellD = 15 --D as in "dimension"
	
	--load graphics
	grid = love.graphics.newImage("grid.png")
	sheet_player = love.graphics.newImage("sheet_player.png")
	-- sheet_enemy = love.graphics.newImage("sheet_enemy.png")
	sheet_toxy = love.graphics.newImage("sheet_toxy.png")
	sheet_algy = love.graphics.newImage("sheet_algy.png")
	sheet_effects = love.graphics.newImage("effects.png")
	ui = love.graphics.newImage("ui.png")
	
	backgrounds = {
		day1 = love.graphics.newImage("bg_day1.png"),
		night1 = love.graphics.newImage("bg_night1.png")
	}
	
	--init quads
	quads_idle = {} --TODO probably quads_poses or something would be better, and put them all in here
	quads_idle[0] = love.graphics.newQuad(0, 0, 16, 16, 64, 64)
	quads_idle[1] = love.graphics.newQuad(0, 16, 16, 16, 64, 64)
	
	enemyQuads = {
		idle = {
			love.graphics.newQuad(0, 0, 16, 16, 64, 64),
			love.graphics.newQuad(0, 16, 16, 16, 64, 64)
		}
	}
	
	quads_ui = {
		hp = love.graphics.newQuad(0, 0, 9, 5, 64, 64),
		hpT = love.graphics.newQuad(10, 0, 3, 5, 64, 64),
		hpF = love.graphics.newQuad(14, 0, 3, 5, 64, 64),
		ap = love.graphics.newQuad(0, 6, 9, 5, 64, 64),
		apT1 = love.graphics.newQuad(10, 6, 5, 5, 64, 64),
		apF1 = love.graphics.newQuad(16, 6, 5, 5, 64, 64),
		apT2 = love.graphics.newQuad(22, 6, 4, 5, 64, 64),
		apF2 = love.graphics.newQuad(27, 6, 4, 5, 64, 64),
		sp = love.graphics.newQuad(0, 12, 9, 5, 64, 64),
		spT1 = love.graphics.newQuad(10, 12, 5, 5, 64, 64),
		spF1 = love.graphics.newQuad(16, 12, 5, 5, 64, 64),
		spT2 = love.graphics.newQuad(22, 12, 4, 5, 64, 64),
		spF2 = love.graphics.newQuad(27, 12, 4, 5, 64, 64),
	}
	
	initAnimFrames()
	
	--load sounds
	
	--init canvas & other graphics stuff
	gameCanvas = love.graphics.newCanvas(64, 64)
	gameCanvas:setFilter("nearest")
	bgMain = {graphic = "day1", alpha = 255}

	--find & load autosave for hi scores. also info panels that have been seen? AND maybe change title screen if game beaten?
	
	--init mechanical variables
	frame = 0 --for idle animations only? figure it out TODO
	eventFrame = 0
	eventFrameLength = 0.05
	eventSetQueue = {}
	inputLevel = "normal" --TODO should be a stack, not a string
	
	--init stage variables (KINDA DEBUG)
	stage = {}
	stage.field = {
		{empty(), empty(), empty()}, 
		{empty(), empty(), empty()}, 
		{empty(), empty(), empty()}
	}
	stage.startingEnemyList = {"algy", "algy"}
	stage.enemyList = {
		{"toxy"},
		{"algy", "algy"},
		{"algy"},
		{"algy"},
	}
	-- stage.boss = "invasive species"
	
	--init hero
	hero = {
		class = "hero",
		hp = {max = 9, actual = 2, shown = 9, posSound = nil, negSound = nil, quick = false},
		ap = {max = 3, actual = 3, shown = 3, posSound = nil, negSound = nil, quick = false},
		sp = {max = 3, actual = 3, shown = 3, posSound = nil, negSound = nil, quick = false},
		attack = 3,
		powers = {},
		pose = "idle",
		yOffset = 0,
		xOffset = 0
	}	
		
	--display title
	

	--DEBUG
	stage.field[2][2].contents = hero
	-- stage.field[2][3].contents = enemy("algy")
	spawnEnemies(stage.startingEnemyList)
end

function love.update(dt)	
	frame = frame + dt * 2
	frame = frame % 24
	
	--process events on a set interval
	eventFrame = eventFrame + dt
	if eventFrame >= eventFrameLength then
		processEventSets(dt)
		eventFrame = eventFrame % eventFrameLength
	end
end

function love.draw()
	--switch to gameCanvas
	love.graphics.setCanvas(gameCanvas)
	
	white()
	
	drawStage()
	
	--draw gameCanvas
	love.graphics.setCanvas()
	love.graphics.draw(gameCanvas, 0, 0, 0, 8, 8)
end

function love.keypressed(key)
	--DEBUG
	if key == "escape" then
		--merry quitmas
		love.event.quit()
	end
	if key == "return" then
		--inspect grid
		print("\nstuff:")
		for y,r in ipairs(stage.field) do
			for x,c in ipairs(r) do
				print(y, x, c.contents.class)
			end
			print()
		end
	end
	if key == "o" then
		hero.ap.actual = 3
		hero.ap.shown = 3
		hero.sp.actual = 3
		hero.sp.shown = 3
	end
	if key == "p" then
		--test spawn
		-- spawnEnemy()
		local xxx, yyy = math.random(3), math.random(3)
		if stage.field[yyy][xxx].contents.class == "clear" then
			queue(cellOpEvent(yyy, xxx, enemy("algy")))
		else
			print(yyy, xxx, "occupied!")
		end
	end
	--END DEBUG

	if inputLevel == "normal" then --TODO input levels should be a stack!
		--take directional input
		if key == "w" or key == "up" then
			heroImpetus(-1, 0)
		end
		if key == "s" or key == "down" then
			heroImpetus(1, 0)
		end
		if key == "a" or key == "left" then
			heroImpetus(0, -1)
		end
		if key == "d" or key == "right" then
			heroImpetus(0, 1)
		end
		if key == "space" then
			heroSpecialAttack()
		end
	end
	
	if hero.ap.actual <= 0 then
		queueEnemyTurn()
	end
end

----------------------------------------------------------------------------------------------------------------------------------------------------

function drawStage()
	--backgrounds
	love.graphics.draw(backgrounds[bgMain.graphic])
	
	if bgNext then
		love.graphics.setColor(255, 255, 255, bgNext.alpha)
		love.graphics.draw(backgrounds[bgNext.graphic])
	end
	
	white()
	
	--grid & UI
	love.graphics.draw(grid)

	drawUI()
	
	--draw cells' contents
	for y, r in ipairs(stage.field) do
		for x, c in ipairs(r) do			
			drawCellContents(c.contents, y, x)
		end
	end
end

function drawCellContents(obj, y, x)
	---DEBUG FOR HP
	if obj.hp then love.graphics.print(obj.hp.shown, x * 15 - 5, y * 15 - 5) end
	
	--draw hero or enemy --TODO optimize/clean up
	if obj.class == "hero" then
		love.graphics.draw(sheet_player, quads_idle[getAnimFrame()], cellD * x - 13 + obj.xOffset, cellD * y - 13 + obj.yOffset)
	end
	if obj.class == "enemy" then
		if obj.species == "algy" then
			love.graphics.draw(sheet_algy, enemyQuads[obj.pose][getAnimFrame() + 1], cellD * x - 13, cellD * y - 13)
		elseif obj.species == "toxy" then
			love.graphics.draw(sheet_toxy, enemyQuads[obj.pose][getAnimFrame() + 1], cellD * x - 13, cellD * y - 13)
		end
	end
	
	--draw overlay if present
	if obj.overlayQuad then
		love.graphics.draw(sheet_effects, obj.overlayQuad, cellD * x - 13, cellD * y - 13)
	end
end

function drawUI()
	--HP
	love.graphics.draw(ui, quads_ui.hp, 2, 57)
	for i = 1, hero.hp.max do
		if i <= hero.hp.shown then
			love.graphics.draw(ui, quads_ui.hpT, 9 + i * 4, 57)
		else
			love.graphics.draw(ui, quads_ui.hpF, 9 + i * 4, 57)
		end
	end

	--AP
	love.graphics.draw(ui, quads_ui.ap, 2, 50)
	for i = 1, hero.ap.max do
		if i <= hero.ap.shown then
			love.graphics.draw(ui, quads_ui.apT1, 6 + i * 6, 50)
		else
			love.graphics.draw(ui, quads_ui.apF1, 6 + i * 6, 50)
		end
	end

	--SP
	love.graphics.draw(ui, quads_ui.sp, 33, 50)
	for i = 1, hero.sp.max do
		if i <= hero.sp.shown then
			love.graphics.draw(ui, quads_ui.spT1, 37 + i * 6, 50)
		else
			love.graphics.draw(ui, quads_ui.spF1, 37 + i * 6, 50)
		end
	end
end

function loadTitleScreen()
end

----------------------------------------------------------------------------------------------------------------------------------------------------

function white()
	love.graphics.setColor(255, 255, 255, 255)
end

function shuffle(arr)
	--TODO
	return arr
end

function clear()
	return {class = "clear"}
end

function empty()
	return {contents = clear()}
end

function getAnimFrame()
	return math.floor(frame % 2)
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
	
	--AP reduction
	hero.ap.actual = hero.ap.actual - 1
	queue(actuationEvent(hero.ap, -1))
	
	--move or fight
	if destClass == "clear" then
		heroMove(y, x, dy, dx)
	end
	
	if destClass == "enemy" then
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
	stage.field[ty][tx].reserved = true
	stage.field[y][x].vacating = true
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
	local ty, tx = y + dy, x + dx
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
	
	--dead? queue removal
	if target.hp.actual <= 0 then
		queue(cellOpEvent(ty, tx, clear()))
	end
	
	processNow()
end

function heroSpecialAttack()
	if hero.sp.actual <= 0 then
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

function locateHero()
	for y,r in ipairs(stage.field) do
		for x,c in ipairs(r) do
			if c and c.contents and c.contents.class and c.contents.class == "hero" then
				return y, x
			end
		end
	end
end

function allEmptiesNotReserved()
	local empties = {}

	for y, r in ipairs(stage.field) do
		for x, c in ipairs(r) do
			--"empty and not reserved or vacating and not reserved"
			if c and c.contents and c.contents.class and c.contents.class == "clear" and not c.reserved or c.vacating and not c.reserved then
				push(empties, {fieldY = y, fieldX = x})
				print(y, x, "is clear")
			end
		end
	end
	print("spawning in those places")
	
	return empties
end

--TODO. enemies should spawn in empty spaces first, then replace powerups if there's nowhere else
-- function allEmptiesShuffled()
-- end
--
-- function allEmptiesThenPowerups()
-- end