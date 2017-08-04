function love.load()
	--initial setup stuff & constants
	math.randomseed(os.time())
	love.window.setMode(512, 512)
	
	love.graphics.setLineWidth(1)
	
	cellD = 15
	
	--load graphics
	bg_day = love.graphics.newImage("bg_day1.png")
	grid = love.graphics.newImage("grid.png")
	sheet_player = love.graphics.newImage("sheet_player.png")
	sheet_enemy = love.graphics.newImage("sheet_enemy.png")
	
	--init quads
	quads_idle = {}
	quads_idle[0] = love.graphics.newQuad(0, 0, 16, 16, 64, 64)
	quads_idle[1] = love.graphics.newQuad(0, 16, 16, 16, 64, 64)
	
	--load sounds
	
	--init canvas stuff
	gameCan = love.graphics.newCanvas(64, 64)
	gameCan:setFilter("nearest")

	--find & load autosave
	
	--init mechanical variables
	frame = 0 --for idle animations only? figure it out TODO
	eventFrame = 0
	eventFrameLength = 0.1
	eventSetQueue = {}
	inputLevel = "normal"
	
	--init game variables
	stage = {}
	stage.field = {{empty(), empty(), empty()}, {empty(), empty(), empty()}, {empty(), empty(), empty()}}
	
	--init hero
	hero = {
		class = "hero",
		hp = {max = 9, actual = 9, shown = 9, posSound = nil, negSound = nil, quick = false},
		ap = {max = 3, actual = 3, shown = 3, posSound = nil, negSound = nil, quick = false},
		sp = {max = 3, actual = 3, shown = 3, posSound = nil, negSound = nil, quick = false},
		attack = 3,
		powers = {}
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
	love.graphics.setCanvas(gameCan)
	
	white()
	
	drawStage()
	
	--draw gameCan
	love.graphics.setCanvas()
	love.graphics.draw(gameCan, 0, 0, 0, 8, 8)
end

function love.keypressed(key)
	--DEBUG
	if key == "escape" then
		love.event.quit()
	end
	if key == "return" then
		print("\nstuff:")
		for y,r in ipairs(stage.field) do
			for x,c in ipairs(r) do
				print(y, x, c.class)
			end
			print()
		end
	end

	if inputLevel == "normal" then
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
	end
	
end

--------------------------------------------------------------------------

function drawStage()
	love.graphics.draw(bg_day)
	love.graphics.draw(grid)
	
	for y,r in ipairs(stage.field) do
		for x,c in ipairs(r) do			
			-- if c.id then
				-- if c.id == "hero" then
					-- print(hero, k, l)
					--love.graphics.draw(sheet_player, quads_idle[getAnimFrame()], cellD * x - 13, cellD * y - 13)
					drawCellContents(c, y, x)
				-- end
			-- end
		end
	end
end

function drawCellContents(obj, y, x)
	
	---VERY DEBUGGY
	if obj.hp then love.graphics.print(obj.hp.shown, x * 15 - 5, y * 15 - 5) end
	
	if obj.class == "hero" then
		love.graphics.draw(sheet_player, quads_idle[getAnimFrame()], cellD * x - 13, cellD * y - 13)
	end
	if obj.class == "enemy" then
		love.graphics.draw(sheet_enemy, quads_idle[getAnimFrame()], cellD * x - 13, cellD * y - 13)
	end
end

function loadTitleScreen()
end

--------------------------------------------------------------------------

function queue(event)
	print("pushing event: ", event.class)
	push(eventSetQueue, {event})
end

function queueSet(eventSet)
	print("pushing eventSet with "..#eventSet.." members")
	push(eventSetQueue, eventSet)
end

function processEventSets(dt)
	--stop and allow input if there are no events to process
	if #eventSetQueue == 0 then 
		inputLevel = "normal"
		return
	end
	
	inputLevel = "none"
	
	local es = peek(eventSetQueue)
	local numFinished = 0
	
	-- touch them all
	for k, e in pairs(es) do
		print("processing "..e.class)
		
		if e.class == "actuation" then
			processActuationEvent(e)
		end
		
		if e.class == "cellOp" then
			processCellOpEvent(e)
		end
		
		--tally finished events in set
		if e.finished then
			numFinished = numFinished + 1
		end
	end
	
	--pop event if all finished
	if numFinished == #es then
		pop(eventSetQueue)
	end
end

function eventSetStep(e, dt)
	--first-frame events
	if e.progress == 0 then
		--play e.sound
		
		--change subject states
		-- for 
		--set subject.beingDamaged
	end
	
	--change animation frame
	e.anim.frame = math.floor((e.progress + dt) * e.fps)
	
	--are we all done? if so, reset subjects' states, remove event set
	e.progress = e.progress + dt
	if e.progress >= e.duration then
		e.finished = true
	end
end

--DEBUG kinda
function newEventSet(enemy)
	local set = {
		--sound = ?
		finishedCount = 0,
		progress = 0,
		frame = 0,
		events = {}
	}
	
	--hero attacks
	set.events[1] = {
		subject = hero,
		frames = {
			"attack", --will need to be directional
		}
	}
	
	--enemy gets attacked
	set.events[2] = {
		subject = enemy,
		frames = {
			"victim",			--literally a quad on the sheet
			-- "idle",
			-- "victim"
		}
	}
end

--------------------------------------------------------------------------

function cellOpEvent(y, x, thing)
	local e = {
		class = "cellOp",
		fieldY = y,
		fieldX = x,
		payload = thing
	}
	
	return e
end

---counter = {actual, shown, posSound, negSound, quick}

function actuationEvent(c, d)
	local e = {
		class = "actuation",
		counter = c,
		delta = d
	}
	
	return e
end

function animEvent()
	local e = {
		class = "anim",
		--what drawable entity
		--frames = { {pose, xOffset, yOffset}s }
	}
	
	return e
end

function soundEvent()
	local e = {
		class = "sound",
		--what sound to start
		--TODO what if you're fading music in or out?
	}
	
	return e
end

function screenEvent()
	local e = {
		class = "screen",
		--graphic to display
		--frames = {{xOffset, yOffset, alpha}s }
	}
	
	return e
end

--bgEvent()?

--------------------------------------------------------------------------

--TODO sound? moving, enemy kills...
function processCellOpEvent(e)
	stage.field[e.fieldY][e.fieldX] = e.payload
	
	e.finished = true
end

--TODO "quick" actuations
--TODO regardless of delta, shown should never go over max or under 0; finish if you hit those
--TODO pos/neg sounds
function processActuationEvent(e)
	--decrement shown and increment delta OR vice-versa
	if e.delta > 0 then
		e.counter.shown = e.counter.shown + 1
		e.delta = e.delta - 1
		print("increment shown")
	elseif e.delta < 0 then
		e.counter.shown = e.counter.shown - 1
		e.delta = e.delta + 1
		print("decrement shown")
	end
	
	--finished if delta is depleted
	if e.delta == 0 then
		e.finished = true
	end
end

function processAnimEvent()
end

function processSoundEvent()
end

function processScreenEvent()
end

--------------------------------------------------------------------------

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
	end
	
	--move or fight
	if destClass == "clear" then
		heroMove(y, x, dy, dx)
	end
	
	if destClass == "enemy" then
		heroFight(y, x, dy, dx)
	end			
end

--TODO queueing for this, probably rename
function heroMove(y, x, dy, dx)
	stage.field[y + dy][x + dx] = stage.field[y][x]
	stage.field[y][x] = empty()
end

--TODO clean up, maybe rename
function heroFight(y, x, dy, dx)
	local ty, tx = y + dy, x + dx
	local target = stage.field[ty][tx]
	
	-- stage.field[y + dy][x + dx] = empty()
	target.hp.actual = target.hp.actual - hero.attack
	
	--queue damage actuation
	queue(actuationEvent(target.hp, -hero.attack))
	
	--dead? queue removal
	if target.hp.actual <= 0 then
		-- killEnemy(target, ty, tx)
		
		queue(cellOpEvent(ty, tx, empty()))
	end
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

function peek(q)
	return q[1]
end

function pop(q)
	local item = q[1]
	
	q[1] = nil
	
	for i = 1, #q do
		q[i - 1] = q[i]
	end
	
	q[#q] = nil
	
	return item
end

function push(q, item)
	table.insert(q, item)
end