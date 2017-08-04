require "queueProcessing"
require "eventSetQueue"
require "enemyAI"

function love.load()
	--initial setup stuff & constants
	math.randomseed(os.time())
	love.window.setMode(512, 512)
	
	love.graphics.setLineWidth(1)
	
	cellD = 15 --D as in "dimension"
	
	--load graphics
	grid = love.graphics.newImage("grid.png")
	sheet_player = love.graphics.newImage("sheet_player.png")
	sheet_enemy = love.graphics.newImage("sheet_enemy.png")
	ui = love.graphics.newImage("ui.png")
	
	backgrounds = {
		day1 = love.graphics.newImage("bg_day1.png"),
		night1 = love.graphics.newImage("bg_night1.png")
	}
	
	--init quads
	quads_idle = {} --TODO probably quads_poses or something would be better, and put them all in here
	quads_idle[0] = love.graphics.newQuad(0, 0, 16, 16, 64, 64)
	quads_idle[1] = love.graphics.newQuad(0, 16, 16, 16, 64, 64)
	
	--quads_animation = {}
	
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
	
	--load sounds
	
	--init canvas stuff
	gameCanvas = love.graphics.newCanvas(64, 64)
	gameCanvas:setFilter("nearest")

	--find & load autosave for hi scores. also info panels that have been seen? AND maybe change title screen if game beaten?
	
	--init mechanical variables
	frame = 0 --for idle animations only? figure it out TODO
	eventFrame = 0
	eventFrameLength = 0.05
	eventSetQueue = {}
	inputLevel = "normal" --TODO should be a stack, not a string
	
	--init game variables
	stage = {}
	stage.field = {
		{empty(), empty(), empty()}, 
		{empty(), empty(), empty()}, 
		{empty(), empty(), empty()}
	}
	bgMain = {graphic = "day1", alpha = 255}
	bgNext = nil
	
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
	stage.field[2][1] = hero
	stage.field[2][3] = enemy()
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
				print(y, x, c.class)
			end
			print()
		end
	end
	if key == "p" then
		--test spawn
		-- spawnEnemy()
		local xxx, yyy = math.random(3), math.random(3)
		if stage.field[yyy][xxx].class == "clear" then
			queue(cellOpEvent(yyy, xxx, enemy()))
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
			drawCellContents(c, y, x)
		end
	end
end

function drawCellContents(obj, y, x)
	---VERY DEBUGGY
	if obj.hp then love.graphics.print(obj.hp.shown, x * 15 - 5, y * 15 - 5) end
	
	if obj.class == "hero" then
		love.graphics.draw(sheet_player, quads_idle[getAnimFrame()], cellD * x - 13 + obj.xOffset, cellD * y - 13 + obj.yOffset)
	end
	if obj.class == "enemy" then
		love.graphics.draw(sheet_enemy, quads_idle[getAnimFrame()], cellD * x - 13, cellD * y - 13)
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

function empty()
	return {class = "clear"}
end

function enemy()
	return {
		class = "enemy",
		species = "garby", --used for graphics
		ai = "melee", --or ranged or healer
		hp = {max = 5, actual = 5, shown = 5, posSound = nil, negSound = nil, quick = true},
		ap = {max = 1, actual = 1, shown = 1, posSound = nil, negSound = nil, quick = false},
		attack = 1
	}
end

function getAnimFrame()
	return math.floor(frame % 2)
end

function heroImpetus(dy, dx) --TODO rename playerImpetus
	local y, x = locateHero()
	
	--see what lies ahead TODO this can still be optimized
	local destClass = nil
	if stage.field[y + dy] and stage.field[y + dy][x + dx] then
		destClass = stage.field[y + dy][x + dx].class
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
	-- local frames = {
	-- 	-- {pose = "idle", yOffset = dy * -15, xOffset = dx * -15},
	-- 	{pose = "idle", yOffset = dy * -12, xOffset = dx * -12},
	-- 	{pose = "idle", yOffset = dy * -9, xOffset = dx * -9},
	-- 	{pose = "idle", yOffset = dy * -6, xOffset = dx * -6},
	-- 	{pose = "idle", yOffset = dy * -3, xOffset = dx * -3},
	-- 	{pose = "idle", yOffset = 0, xOffset = 0},
	-- }

	local frames = {
		{pose = "idle", yOffset = dy * -15, xOffset = dx * -15},
		{pose = "idle", yOffset = dy * -10, xOffset = dx * -10},
		{pose = "idle", yOffset = dy * -5, xOffset = dx * -5},
		{pose = "idle", yOffset = 0, xOffset = 0},
	}	

	queueSet({
		cellOpEvent(y + dy, x + dx, hero),
		cellOpEvent(y, x, empty()),
		poseEvent(y + dy, x + dx, frames)
	})
	
	processNow()
end

--TODO clean up, maybe rename
function heroFight(y, x, dy, dx)
	local hy, hx = locateHero()
	local ty, tx = y + dy, x + dx
	local target = stage.field[ty][tx]
	
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
		queue(cellOpEvent(ty, tx, empty()))
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
	for y,r in ipairs(stage.field) do
		for x,c in ipairs(r) do
			if c and c.class and c.class == "enemy" then
				c.hp.actual = c.hp.actual - 1
				push(attacky, actuationEvent(c.hp, -1))
			end
		end
	end
	queueSet(attacky)
	killy = {}
	for y,r in ipairs(stage.field) do
		for x,c in ipairs(r) do
			if c and c.class and c.class == "enemy" then
				if c.hp.actual <= 0 then
					push(killy, cellOpEvent(y, x, empty()))
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
			if c and c.class and c.class == "hero" then
				return y, x
			end
		end
	end
end