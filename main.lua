require "queueProcessing"
require "eventSetQueue"
require "heroActions"
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
	enemySheets = {
		toxy = love.graphics.newImage("sheet_toxy.png"),
		mercuri = love.graphics.newImage("sheet_mercuri.png"),
		algy = love.graphics.newImage("sheet_algy.png"),
		sewy = love.graphics.newImage("sheet_sewy.png"),
		garby = love.graphics.newImage("sheet_garby.png")
	}
	sheet_effects = love.graphics.newImage("effects.png")
	ui = love.graphics.newImage("ui.png")
	
	backgrounds = {
		day1 = love.graphics.newImage("bg_day1.png"),
		night1 = love.graphics.newImage("bg_night1.png")
	}
	
	--init quads
	quads_idle = {
		love.graphics.newQuad(0, 0, 16, 16, 64, 64),
		love.graphics.newQuad(0, 16, 16, 16, 64, 64),
		love.graphics.newQuad(0, 32, 16, 16, 64, 64),
		love.graphics.newQuad(0, 48, 16, 16, 64, 64)
	} --TODO probably quads_poses or something would be better, and put them all in here
	-- quads_idle[0] = love.graphics.newQuad(0, 0, 16, 16, 64, 64)
	-- quads_idle[1] = love.graphics.newQuad(0, 16, 16, 16, 64, 64)
	
	characterQuads = {
		idle = {
			love.graphics.newQuad(0, 0, 16, 16, 64, 64),
			love.graphics.newQuad(0, 16, 16, 16, 64, 64),
			love.graphics.newQuad(0, 32, 16, 16, 64, 64),
			love.graphics.newQuad(0, 48, 16, 16, 64, 64)
		},
		stuck = {
			love.graphics.newQuad(32, 0, 16, 16, 64, 64),
			love.graphics.newQuad(32, 16, 16, 16, 64, 64),
			love.graphics.newQuad(32, 32, 16, 16, 64, 64),
			love.graphics.newQuad(32, 48, 16, 16, 64, 64)
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
		stink = {
			love.graphics.newQuad(0, 18, 30, 5, 64, 64),
			love.graphics.newQuad(0, 18, 30, 5, 64, 64),
			love.graphics.newQuad(0, 24, 30, 5, 64, 64),
			love.graphics.newQuad(0, 24, 30, 5, 64, 64),
		}
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
	game = {
		state = "day"
	}
	
	--init stage variables (KINDA DEBUG)
	stage = {}
	stage.field = {
		{empty(), empty(), empty()}, 
		{empty(), empty(), empty()}, 
		{empty(), empty(), empty()}
	}
	stage.startingEnemyList = {"mercuri", "toxy", "sewy", "garby", "algy"}
	-- stage.startingEnemyList = {"algy", "algy"}
	stage.enemyList = {
		{"toxy"},
		{"algy", "algy"},
		{"sewy", "sewy"}, 
		{"algy"},
	}
	stage.enemyList = shuffle(stage.enemyList)
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
		xOffset = 0,
		statusAfflictors = {},
		sewyAdjacent = false
	}
	
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
		
	--display title
	

	--DEBUG
	stage.field[2][2].contents = hero
	-- stage.field[2][3].contents = enemy("algy")
	spawnEnemies(stage.startingEnemyList)
end

function love.update(dt)	
	frame = frame + dt * 3
	frame = frame % 24
	
	--process events on a set interval
	eventFrame = eventFrame + dt
	if eventFrame >= eventFrameLength then
		processEventSets(dt)
		eventFrame = eventFrame % eventFrameLength
	end
	
	--figure out if stuck now, to save a little draw efficiency
	-- if hero.statusAfflictors[11] == "stick"
	-- or hero.statusAfflictors[12] == "stick"
	-- or hero.statusAfflictors[13] == "stick"
	-- or hero.statusAfflictors[21] == "stick"
	-- or hero.statusAfflictors[22] == "stick"
	-- or hero.statusAfflictors[23] == "stick"
	-- or hero.statusAfflictors[31] == "stick"
	-- or hero.statusAfflictors[32] == "stick"
	-- or hero.statusAfflictors[33] == "stick" then
	-- 	hero.stuck = true
	-- else
	-- 	hero.stuck = false
	-- end
	--on second thought, this is messier. draw() won't suffer that much
	
	--i WILL do this here, however. checking cells in draw() is yucky
	hero.sewyAdjacent = sewyAdjacent() 
	
	--queue enemy turns one by one
	--yes, q-p-q-p-q-p is less elegant than q-q-q-p-p-p, but there's no gameplay difference & grid logic is WAY cleaner than with the reserved/vacating stuff
	--TODO ...but maybe move elsewhere
	if game.state == "night" then
		--if event queue is empty...?
		if not peek(eventSetQueue) then
			--currently not shuffling here so that such as mercuris can take their turns consecutively, but this is lazy. can also break if they change rows
			--TODO a much better solution is to do it in order of distance from hero. left-to-right is not equivalent to right-to-left if you go in order
				--something something cellsInDistanceRange. loop through 1-2-3-4, break when you find one with AP?
			local en = locationsOfAllEnemiesWithAP()[1]
			
			-- if there was at least one with AP...
			if en then --? something else?
				--...queue a turn!
				queueFullEnemyTurn(en.y, en.x)
			else
				--otherwise, no enemies found that have AP, so back to player
				startHeroTurn()
			end
		end
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

	if game.state == "day" then
		--take directional input
		if inputLevel == "normal" then --TODO input levels should be a stack!
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
		
		--queue night & end of player turn TODO feels pretty weird to be doing this here tbh. at least move to playerAction() or something
		if hero.ap.actual <= 0 then
			-- queueEnemyTurn()
			startEnemyTurn()
		end
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
	
	--draw cells' contents + overlays
	for y, r in ipairs(stage.field) do
		for x, c in ipairs(r) do			
			drawCellContents(c.contents, y, x)

			--draw overlay if present
			if c.overlayQuad then
				drawCellOverlay(c, y, x)
			end
		end
	end
end

function drawCellContents(obj, y, x)
	---DEBUG FOR HP
	-- if obj.hp then love.graphics.print(obj.hp.shown, x * 15 - 5, y * 15 - 5) end
	
	--draw hero or enemy --TODO optimize/clean up
	if obj.class == "hero" then
		if heroStuck() then
			love.graphics.draw(sheet_player, characterQuads["stuck"][getAnimFrame() + 1], cellD * x - 13 + obj.xOffset, cellD * y - 13 + obj.yOffset)
		else
			love.graphics.draw(sheet_player, characterQuads[obj.pose][getAnimFrame() + 1], cellD * x - 13 + obj.xOffset, cellD * y - 13 + obj.yOffset)
		end
	end
	if obj.class == "enemy" then
		-- if obj.species == "algy" then
			-- love.graphics.draw(sheet_algy, enemyQuads[obj.pose][getAnimFrame() + 1], cellD * x - 13 + obj.xOffset, cellD * y - 13 + obj.yOffset)
		-- elseif obj.species == "toxy" then
			love.graphics.draw(enemySheets[obj.species], characterQuads[obj.pose][getAnimFrame() + 1], cellD * x - 13 + obj.xOffset, cellD * y - 13 + obj.yOffset)
		-- end
	end
end

function drawCellOverlay(cell, y, x)
	love.graphics.draw(sheet_effects, cell.overlayQuad, cellD * x - 13, cellD * y - 13)
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
	
	--sewy adjacent?
	if hero.sewyAdjacent then
		love.graphics.setColor(255, 255, 255, 127)
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
	
	white()
	
	--sewy adjacent?
	if hero.sewyAdjacent then
		love.graphics.draw(ui, quads_ui.stink[getAnimFrame() + 1], 33, 50)
	end
end

function loadTitleScreen()
end

----------------------------------------------------------------------------------------------------------------------------------------------------

function white()
	love.graphics.setColor(255, 255, 255, 255)
end

--mutates the input, so ONLY use this in the form foo = shuffle(foo)
function shuffle(arr)
	local new = {}
	
	for i = 1, table.getn(arr) do
		new[i] = table.remove(arr, math.random(table.getn(arr)))
	end
	
	return new
end

function clear()
	return {class = "clear"}
end

function empty()
	return {contents = clear()}
end

function getAnimFrame()
	-- return math.floor(frame % 2)
	return math.floor(frame % 4) --TODO you should be adding the 1 here
end

function heroStuck()
	if hero.statusAfflictors[11] == "stick"
	or hero.statusAfflictors[12] == "stick"
	or hero.statusAfflictors[13] == "stick"
	or hero.statusAfflictors[21] == "stick"
	or hero.statusAfflictors[22] == "stick"
	or hero.statusAfflictors[23] == "stick"
	or hero.statusAfflictors[31] == "stick"
	or hero.statusAfflictors[32] == "stick"
	or hero.statusAfflictors[33] == "stick" then
		return true
	else
		return false
	end
end

function sewyAdjacent()
	local hy, hx = locateHero()
	local enemyNeighbors = getAdjacentCells(hy, hx, "enemy")
	
	for i, c in pairs(enemyNeighbors) do
		if stage.field[c.fieldY][c.fieldX].contents.species == "sewy" then
			return true
		end
	end
	
	return false
end