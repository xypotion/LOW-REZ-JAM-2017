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
	
	--load sound
	
	--init canvas stuff
	gameCan = love.graphics.newCanvas(64, 64)
	gameCan:setFilter("nearest")

	--find & load autosave
	
	--init mechanical variables
	frame = 0
	animFPS = 10
	eventSetQueue = {}
	
	--init game variables
	stage = {}
	stage.field = {{empty(), empty(), empty()}, {empty(), empty(), empty()}, {empty(), empty(), empty()}}
	
	--init hero
	hero = {
		class = "hero",
		maxHP = 9,
		hp = 9,
		maxAP = 3,
		ap = 3,
		maxSP = 3,
		sp = 3,
		attack = 3,
		powers = {}
	}
		
	--display title
	

	--DEBUG
	stage.field[2][1] = hero
	stage.field[2][3] = enemy()
end

function love.update(dt)
	processEventSets(dt)
	
	frame = frame + dt * 2
	frame = frame % 24
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
				print(y, x, c.class, c.hp)
			end
			print()
		end
	end

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
	if obj.class == "hero" then
		love.graphics.draw(sheet_player, quads_idle[getAnimFrame()], cellD * x - 13, cellD * y - 13)
	end
	
	if obj.class == "enemy" then
		love.graphics.draw(sheet_enemy, quads_idle[getAnimFrame()], cellD * x - 13, cellD * y - 13)
	end
end

function loadTitleScreen()
end

function processEventSets(dt)
	--stop if there are no events to process
	if #eventSetQueue == 0 then return end
	
	local e = peek(eventSetQueue)
	
	eventSetStep(e, dt)
	
	if e.finished then
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

function white()
	love.graphics.setColor(255, 255, 255, 255)
end

function empty()
	return {class = "clear"}
end

function enemy()
	return {
		class = "enemy",
		maxHP = 5,
		hp = 5,
		maxAP = 1,
		ap = 1,
		attack = 1
	}
end

function getAnimFrame()
	return math.floor(frame % 2)
end

function heroImpetus(dy, dx)
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

function heroMove(y, x, dy, dx)
	stage.field[y + dy][x + dx] = stage.field[y][x]
	stage.field[y][x] = empty()
end

function heroFight(y, x, dy, dx)
	local ty, tx = y + dy, x + dx
	local target = stage.field[ty][tx]
	
	-- stage.field[y + dy][x + dx] = empty()
	target.hp = target.hp - hero.attack
	
	if target.hp <= 0 then
		killEnemy(target, ty, tx)
	end
end

function killEnemy(t, ty, tx)
	--play sound
	
	--queue enemy death animation
	stage.field[ty][tx] = empty()
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
	q.insert(item)
end