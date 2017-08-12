require "queueProcessing"
require "eventSetQueue"
require "heroActions"
require "enemyAI"
require "animScripts"
require "powers"
require "sounds"
require "stage"
require "graphics"

function love.load()
	--initial setup stuff & constants
	math.randomseed(os.time())
	love.window.setMode(512, 512)
	
	love.graphics.setLineWidth(1)
	
	cellD = 15 --D as in "dimension"
	
	--load graphics & quads
	loadGraphics()
	loadQuads()
	
	initAnimFrames()
	
	--load sounds
	loadSounds()
	
	--init canvas & other graphics stuff
	gameCanvas = love.graphics.newCanvas(64, 64)
	gameCanvas:setFilter("nearest")
	bgMain = {graphic = "title1", alpha = 255} --TODO opening title changes if you've beaten the game. do if time!
	love.graphics.setFont(love.graphics.newFont(7))

	--find & load autosave for progress, hero's current inventory (8 bools, i think), and enemy info panels seen. pretty simple
	
	--init mechanical variables
	frame = 0 --for idle animations and UI animations only
	eventFrame = 0 --for other animations (casting, poseEvents, etc)
	eventFrameLength = 0.05
	eventSetQueue = {}
	inputLevel = "normal" --TODO should be a stack, not a string?
	game = {
		state = "title"
	}
	
	--initialize hero
	initHero()
		
	--fade in to title
	queue(fadeInEvent(1))
end

function love.update(dt)
	frame = (frame + dt * 4)
	
	--process events on a set interval
	eventFrame = eventFrame + dt
	if eventFrame >= eventFrameLength then
		processEventSets(dt)
		eventFrame = eventFrame % eventFrameLength
	end
	
	--queue enemy turns one by one
	--TODO maybe move elsewhere
	if game.state == "night" then
		--if event queue is empty, 
		if not peek(eventSetQueue) then
			
			--currently not shuffling here so that such as mercuris can take their turns consecutively, but this is lazy. can also break if they change rows
			--TODO a much better solution is to do it in order of distance from hero. left-to-right is not equivalent to right-to-left if you go in order
				--something something cellsInDistanceRange. loop through 1-2-3-4, break when you find one with AP?
			local en = locationsOfAllEnemiesWithAP()[1]
			
			-- if there was at least one enemy with AP...
			if en then
				--...queue a turn!
				queueFullEnemyTurn(en.y, en.x)
			else
				--otherwise, no enemies found that have AP, so spawn enemies or boss, then back to player
				if stage.enemyCount.shown > 0 then
					spawnEnemies()
				elseif not stage.bossMode then
					spawnBossAndSwitchUI()
				end
				
				startHeroTurn()
			end
		end
	elseif game.state == "day" then --really?
		--checking sewy adjacency here instead of in draw()
		hero.sewyAdjacent = sewyAdjacent() 
	end
	
	checkBGMTimerAndTransition(dt)
end

function love.draw()
	--switch to gameCanvas
	love.graphics.setCanvas(gameCanvas)
	
	white()
	
	-- drawStage()
	
	if game.state == "title" then
		drawTitleScreen()
	elseif game.state == "day" or game.state == "night" then
		drawStage()
	end
	
	--overlay
	love.graphics.setColor(255, 255, 255, blackOverlay.alpha)
	love.graphics.draw(blackOverlay.graphic, 0, 0)
	
	white()
		
	--DEBUG
	-- love.graphics.printf("The quick brown fox jumps over the lazy dog.", 0, 0, 64)
	
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
		if cellAt(yyy, xxx).contents.class == "clear" then
			queue(cellOpEvent(yyy, xxx, enemy("algy")))
		else
			print(yyy, xxx, "occupied!")
		end
	end
	if key == "h" then
		hero.hp.actual = hero.hp.actual + 3
		queue(actuationEvent(hero.hp, 3))
	end
	if key == "x" then sfx.pop:play() end
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
			startEnemyTurn()
		end
	elseif game.state == "title" then
		--start game
		stageStart(1)
		--kinda DEBUG TODO an actual menu! Start, Continue, Credits
	end
end

----------------------------------------------------------------------------------------------------------------------------------------------------

function drawBackgrounds()
	love.graphics.draw(backgrounds[bgMain.graphic])
	
	if bgNext then
		love.graphics.setColor(255, 255, 255, bgNext.alpha)
		love.graphics.draw(backgrounds[bgNext.graphic])
	end
end

function drawTitleScreen()
	drawBackgrounds()
end

function drawStage()
	drawBackgrounds()
	
	white()
	
	--grid & UI
	-- love.graphics.draw(grid)

	drawUI()
	
	--draw cells' contents + overlays
	for y, r in ipairs(stage.field) do
		for x, c in ipairs(r) do
			drawCellContents(c.contents, y, x)

			--draw enemy HP bars
			if cellAt(y, x).contents.class == "enemy" then
				drawEnemyHP(y, x)
			end

			--draw overlay if present
			if c.overlayQuad then
				drawCellOverlay(c, y, x)
			end
		end
	end
	
	drawEnemyUI()
	
	--this is suuuuch a hack to get gluttons to draw on top of their food. OK if it doesn't hurt performance. shame on you, either way.
	for i, c in pairs(getAllCells("enemy")) do
		if cellAt(c.y, c.x).contents.ai == "glutton" and cellAt(c.y, c.x).contents.pose == "casting" then
			drawCellContents(cellAt(c.y, c.x).contents, c.y, c.x)
		end
	end
end

function drawCellContents(obj, y, x)
	--draw hero or enemy --TODO optimize/clean up
	if obj.class == "hero" then
		if heroStuck() then
			love.graphics.draw(sheet_player, characterQuads["stuck"][getCharacterAnimFrame()], cellD * x - 13 + obj.xOffset, cellD * y - 13 + obj.yOffset)
		else
			--does this make sense? (if you ever get around to adding a casting animation for the hero,) won't you still want the "stuck" sprite? TODO
			love.graphics.draw(sheet_player, characterQuads[obj.pose][getCharacterAnimFrame()], cellD * x - 13 + obj.xOffset, cellD * y - 13 + obj.yOffset)
		end
	elseif obj.class == "enemy" then
		if obj.pose == "idle" then
			love.graphics.draw(enemySheets[obj.species], characterQuads["idle"][getCharacterAnimFrame()], cellD * x - 13 + obj.xOffset, cellD * y - 13 + obj.yOffset) --TODO maybe refactor the mathy parts here...
		elseif obj.pose == "casting" then
			love.graphics.draw(enemySheets[obj.species], characterQuads["casting"][getCharacterCastingFrame()], cellD * x - 13 + obj.xOffset, cellD * y - 13 + obj.yOffset) --TODO maybe refactor the mathy parts here...
		end
	elseif obj.class == "power" then
		love.graphics.draw(powerSheet, powerQuads[obj.type][getNonCharacterAnimFrame()], cellD * x - 13, cellD * y - 13)
	end
end

function drawEnemyHP(ey, ex)
	local enemy = cellAt(ey, ex).contents
	
	love.graphics.setColor(0, 0, 0, 127)
	for x = (ex - 1) * 15 + 5, (ex - 1) * 15 + 4 + enemy.hp.max do
		love.graphics.points(x + enemy.xOffset, (ey - 1) * 15 + 18 + enemy.yOffset)
	end
	
	love.graphics.setColor(255, 0, 0, 127)
	for x = (ex - 1) * 15 + 5, (ex - 1) * 15 + 4 + enemy.hp.shown do
		love.graphics.points(x + enemy.xOffset, (ey - 1) * 15 + 18 + enemy.yOffset)
	end
	
	white()
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
		love.graphics.draw(ui, quads_ui.stink[getNonCharacterAnimFrame()], 33, 50)
	end
end

function drawEnemyUI()
	if stage.bossMode then
		--boss UI
		love.graphics.draw(ui, quads_ui.boss[getNonCharacterAnimFrame()], 51, 8)
		--boss HP
	else
		if stage.enemyCount.shown > 0 then
			--draw enemy counter
			love.graphics.draw(ui, quads_ui.enemiesLeft, 51, 8)
			for i = 0, stage.enemyCount.shown - 1 do
				-- love.graphics.draw(ui, quads_ui.enemyAlive, 51 - i, 14 + i)
				love.graphics.draw(ui, quads_ui.enemyAlive, 51 + (i % 3) * 4, 14 + math.floor(i / 3) * 3)
			end
		else
			--flashing "left?"
			love.graphics.setColor(255, getNonCharacterAnimFrame() * 127, getNonCharacterAnimFrame() * 127)
			love.graphics.draw(ui, quads_ui.enemiesLeft, 51, 8)
			white()
		end
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

function getCharacterAnimFrame()
	return math.floor(frame % 4 + 1)
end

function getCharacterCastingFrame()
	return math.floor((4 * frame) % 4 + 1)
end

function getNonCharacterAnimFrame()
	return math.floor(frame % 2 + 1)
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
		if cellAt(c.y, c.x).contents.species == "sewy" then
			return true
		end
	end
	
	return false
end

--i'm honestly a little freaked out that you can use this to SET cell attributes, but i guess that's what "pass by reference" is all about. ok! i guess!!
function cellAt(y, x)
	if stage.field[y] then
		return stage.field[y][x]
	else
		return nil
	end
end