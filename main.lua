require "draw"
require "queueProcessing"
require "eventSetQueue"
require "heroActions"
require "enemyAI"
require "enemySpawns"
require "animScripts"
require "powers"
require "sounds"
require "stage"
require "graphics"

function love.load()
	--initial setup stuff & constants
	math.randomseed(os.time())
	love.window.setMode(540, 740) --only works on desktop. TODO change back to 512x512 later, i guess, for desktop. also allow resizing!
	love.window.setTitle("Heart's Desire: Blue Sea")
	
	--load graphics & quads
	loadGraphics()
	loadQuads()
	
	initAnimFrames()
	
	--load sounds
	loadSounds()
	
	--init canvas & other graphics stuff
	gameCanvas = love.graphics.newCanvas(64, 64)
	gameCanvas:setFilter("nearest")
	
	bgMain = {graphic = "title0", alpha = 255}
	love.graphics.setFont(love.graphics.newFont(8))
	overlay = {xOffset = 0, text = ""}
	love.graphics.setLineWidth(1)
	cellD = 15 --D as in "dimension"
	
	--collect some device info, then derive mobile-specific graphics things
	screen = {}
	screen.w, screen.h, screen.flags = love.window.getMode()
	if screen.w < screen.h then
		scaleFactor = math.floor(screen.w / 64)
		screen.yOffset = (screen.h - 64 * scaleFactor) / 2
		screen.xOffset = (screen.w - 64 * scaleFactor) / 2
	else
		scaleFactor = 6 -- TODO
	end

	--find & load autosave for progress, hero's current inventory (8 bools, i think), and enemy info panels seen. pretty simple
	
	--init mechanical variables
	frame = 0 --for idle animations and UI animations only
	eventFrame = 0 --for other animations (casting, poseEvents, etc)
	eventFrameLength = 0.05
	eventSetQueue = {}
	inputLevel = "normal" --TODO should be a stack, not a string?
	game = {
		state = "title",
		maxStage = 1,
		lastStage = 9,
		-- lastStage = 1,
		seenPopups = {},
		started = true,--false, --DEBUG
		beaten = false,
		deaths = 0,
		days = 0,
	}
	bossHPRatio = 0 --hhaaaack
	titleMenuCursorPos = 1
	volumePopupAlpha = 0
	
	--initialize hero and stage objects
	initStage()
	initHero()
		
	--fade in to title
	queue(bgmEvent("titleIntro", "title"))
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
		
		--TODO consolidate with exact same code in day section below
		if stage and stage.boss then
			--saving draw() some math by determining hp bar size here
			bossHPRatio = math.ceil(stage.boss.hp.shown * 27 / stage.boss.hp.max)
		end
		
		--if event queue is empty, 
		if not peek(eventSetQueue) then
			--continue or finish enemy turn
				--currently not shuffling here so that such as mercuris can take their turns consecutively, but this is lazy. can also break if they change rows
				--TODO a much better solution is to do it in order of distance from hero. left-to-right is not equivalent to right-to-left if you go in order
					--something something cellsInDistanceRange. loop through 1-2-3-4, break when you find one with AP?
					--ooh, or chain turns with functionEvents? TODO maybe the cleanest idea to try
				local en = locationsOfAllEnemiesWithAP()[1]
		
				-- if there was at least one enemy with AP...
				if en then
					--...queue a turn!
					queueFullEnemyTurn(en.y, en.x)
				else
					--otherwise, no enemies found that have AP, so spawn enemies or boss, then back to player
					if stage.enemyCount.shown > 0 then
						spawnEnemies()
					elseif not stage.boss then
						spawnBossAndSwitchUI()
					end
			
					startHeroTurn()
				end
			-- end
		end
	elseif game.state == "day" then
		--checking sewy adjacency here instead of in draw()
		hero.sewyAdjacent = sewyAdjacent() 
	
		--boss stuff happening? update HP, see if defeated...
		if stage and stage.boss then
			--saving draw() some math by determining hp bar size here
			bossHPRatio = math.ceil(stage.boss.hp.shown * 27 / stage.boss.hp.max)
		
			--boss defeated; dump powerups (and for now, move on to next stage immediately)
			if stage.boss.hp.shown <= 0 and not peek(eventSetQueue) then
				--stage over!
				queue(screenEvent("\n\nSTAGE "..game.maxStage.."\nCOMPLETE!"))
				-- queue(screenEvent("\n\n  STAGE "..game.maxStage.."\n  COMPLETE!\n\n Choose reward:"))
			
				--check if that was the final boss TODO make this a little less hacky, lol
				if game.maxStage == game.lastStage then
					startEnding()
				else
					--queue rare powerups
					queueRarePowerups()
			
					--TODO should happen in heroActions
					collectRarePowerup()
					
					stageEnd()
					stageStart(game.maxStage)
				end
			end
		end
		
		--if out of events & AP, queue night and end of player turn
		if not peek(eventSetQueue) and hero.ap.actual <= 0 then
			startEnemyTurn()
		end
	end
	
	checkBGMTimerAndTransition(dt)
	
	--fade volume popup
	if volumePopupAlpha > 0 then
		volumePopupAlpha = volumePopupAlpha - 2
	end
end

function love.keypressed(key)
	--DEBUG
	--[ [
	if key == "escape" then
		--merry quitmas
		love.event.quit()
	end
	if key == "e" then startEnding() end
	if key == "t" then print("deaths:", game.deaths, "days", game.days) end
	if key == "i" then
		--inspect grid
		print("\ninfo:")
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
	if key == "t" then tablePrint(stage.enemyList) end
	if key == "x" then 
		queue(screenEvent("\n\nGARBY\nConsumes anything in reach.", true, true, enemySheets.garby))
		queue(screenEvent("\n\nPLASTY\nHard to break down!", true, true, enemySheets.plasty))
		queue(screenEvent("\n\nTOXY\nA meanie that hurts from afar.", true, true, enemySheets.toxy))
		queue(screenEvent("\n\nMERCURI\nQuick like quicksilver!", true, true, enemySheets.mercuri))
		queue(screenEvent("\n\nPHARMA\nGood for you... or not?", true, true, enemySheets.pharma))
		queue(screenEvent("\n\nSEWY\nUnbearably smelly! Yuck!!", true, true, enemySheets.sewy))
		queue(screenEvent("\n\nNUKEY\nDANGER: UNSTABLE ELEMENTS", true, true, enemySheets.nukey))
		queue(screenEvent("\n\nALGY\nSticky - don't touch it!", true, true, enemySheets.algy))
	end
	if key == "z" then 
		queue(screenEvent("\n\n- BOSS -\n\nNOISE\nPOLLUTION", true, true, enemySheets.noise))
		queue(screenEvent("\n\n- BOSS -\n\nHEAT\nPOLLUTION", true, true, enemySheets.heat))
		queue(screenEvent("\n\n- BOSS -\n\nLIGHT\nPOLLUTION", true, true, enemySheets.light))
		queue(screenEvent("\n\n- BOSS -\n\nINVASIVE\nSPECIES", true, true, enemySheets.invasive))
		queue(screenEvent("\n\n- BOSS -\n\nOIL\nSPILL", true, true, enemySheets.oil))
		queue(screenEvent("\n\n- BOSS -\n\nXPS", true, true, enemySheets.xps))
		queue(screenEvent("\n\n- BOSS -\n\nGLUTTONY", true, true, enemySheets.gluttony))
		queue(screenEvent("\n\n- BOSS -\n\nGREED", true, true, enemySheets.greed))
		queue(screenEvent("\n\n- BOSS -\n\nAPATHY", true, true, enemySheets.apathy))
	end
	--]]
	--END DEBUG
	
	if key == "v" then 
		cycleVolume() 
		volumePopupAlpha = 255
	end

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
			if key == "space" or key == "return" then
				heroSpecialAttack()
			end
		end	
	elseif game.state == "title" and table.getn(eventSetQueue) == 0 then		
		if key == "up" or key == "w" then
			titleMenuCursorPos = (titleMenuCursorPos - 2) % 3 + 1
		elseif key == "down" or key == "s" then
			titleMenuCursorPos = titleMenuCursorPos % 3 + 1
		elseif key == "return" or key == "space" then
			if titleMenuCursorPos == 1 then	--START
				queue(fadeOutEvent())
				game.maxStage = 1
				game.started = true
				game.deaths = 0
				game.days = 0
				stageStart(1)
				queue(screenEvent("Welcome to the blue sea... but look at all this garbage! I've created you to purify my oceans.", true, true))
				queue(screenEvent("Move with WASD or the arrow keys. Bump into pollution to break it down.", true, true))
				queue(screenEvent("SPACE or ENTER does a special move that can hit up to 3 enemies. ZAP!", true, true))
				queue(screenEvent("Blue fish restore your HP. Red fish recharge your powers. Good luck! Love, Mother Nature", true, true))
			elseif titleMenuCursorPos == 2 and game.started then --CONTINUE
				queue(fadeOutEvent())
				stageStart(game.maxStage)
			elseif titleMenuCursorPos == 3 then --CREDITS
				queue(fadeOutEvent())
				queue(screenEvent("\nCredits:\nAll art, sound, design, and code by Max Wunderlich", true))
				-- queue(screenEvent("\nCredits:\nAll art, sound, design, and code by Max Wunderlich\nxypotion.itch.io", true))
				queue(screenEvent("\nArt created in Pixen\n\npixenapp.com", true))
				queue(screenEvent("\nMusic composed in Beepbox\n\nbeepbox.co", true))
				queue(screenEvent("\nSFX created in CFXR\n\nthirdcog.eu/\napps/cfxr", true))
				queue(screenEvent("Made with Löve for LOW REZ JAM 2017\n\nitch.io/jam/lowrezjam2017", true))
				queue(screenEvent("Special thanks:\nDustin Cogswell\n&\nlove2d.org\n<3", true))
				queue(fadeInEvent())
			end
		end
	end
end

----------------------------------------------------------------------------------------------------------------------------------------------------

function love.mousereleased(mx, my)
	print("raw tap:", my, mx)
	local gy, gx = convertScreenCoords(my, mx)
	print("converted tap:", gy, gx)
	local cy, cx = getTappedCell(gy, gx)
	print("cell tapped:", cy, cx)
	local cell = cellAt(cy, cx)
	-- print("cell tapped contains:", cell.contents.class)
	
	--DEBUG kinda
	if game.state == "day" then
		if inputLevel == "normal" then
			local hy, hx = locateHero()
			print("accepting input... hero is at", hy, hx)
			if cy == hy and cx == hx then
				heroSpecialAttack()
			elseif heroAdjacentToEnemy(cy, cx) then --TODO change function name? this is yucky
				heroImpetus(cy - hy, cx - hx)
			end
		end
	elseif game.state == "title" and table.getn(eventSetQueue) == 0 then
		--very DEBUG
		queue(fadeOutEvent())
		stageStart(game.maxStage)
	end
	
	--also DEBUG
	if gy < 0 or gy >= 64 or gx < 0 or gx >= 64 then
		cycleVolume() 
		volumePopupAlpha = 255
	end
	
end

function convertScreenCoords(sy, sx)
	local gy = math.floor((sy - screen.yOffset) / scaleFactor)
	local gx = math.floor((sx - screen.xOffset) / scaleFactor)
	
	return gy, gx
end

function convertGameCoords(gy, gx)
end

function getTappedCell(gy, gx)
	local cy = math.ceil((gy - 2) / 15)
	local cx = math.ceil((gx - 2) / 15)
	
	return cy, cx
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
	--slight hack to give Noise Pollution the same effect as Sewy
	if stage and stage.boss and stage.boss.species == "noise" then
		return true
	end
	
	--check for adjacent Sewies
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

function peek(q)
	return q[1]
end

function pop(q)
	local item = q[1]
	
	for i = 2, table.getn(q) do
		q[i - 1] = q[i]
	end
	
	q[table.getn(q)] = nil

	return item
end

function push(q, item)
	table.insert(q, item)
end

--an old helper function i made in 2014 :)
function tablePrint(table, offset)
	offset = offset or "  "
	
	for k,v in pairs(table) do
		if type(v) == "table" then
			print(offset.."sub-table ["..k.."]:")
			tablePrint(v, offset.."  ")
		else
			print(offset.."["..k.."] = "..tostring(v))
		end
	end	
end