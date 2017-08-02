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
	
	--init quads
	quads_idle = {}
	quads_idle[0] = love.graphics.newQuad(0, 0, 16, 16, 64, 64)
	quads_idle[1] = love.graphics.newQuad(0, 16, 16, 16, 64, 64)
	
	--load sound
	
	--init canvas stuff
	gameCan = love.graphics.newCanvas(64, 64)
	gameCan:setFilter("nearest")
	
	--find & load autosave
	
	--init game variables
	frame = 0
	stage = {}
	stage.field = {{"empty", "empty", "empty"}, {"empty", "empty", "empty"}, {"empty", "empty", "empty"}}
	
	hero = {id = "hero"}
	stage.field[2][2] = hero
	
	drawStage()
	
	--display title
end

function love.update(dt)
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
	
end

--------------------------------------------------------------------------

function drawStage()
	love.graphics.draw(bg_day)
	love.graphics.draw(grid)
	
	for k,r in ipairs(stage.field) do
		for l,c in ipairs(r) do			
			if c.id then
				if c.id == "hero" then
					-- print(hero, k, l)
					love.graphics.draw(sheet_player, quads_idle[getAnimFrame()], cellD * k - 13, cellD * l - 13)
				end
			end
		end
	end
	
end

function loadTitleScreen()
end

--------------------------------------------------------------------------

function white()
	love.graphics.setColor(255, 255, 255, 255)
end

function getAnimFrame()
	return math.floor(frame % 2)
end