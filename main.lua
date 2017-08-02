function love.load()
	--initial setup stuff
	math.randomseed(os.time())
	love.window.setMode(512, 512)
	
	--load graphics
	bg_day = love.graphics.newImage("bg_day1.png")
	
	--load sound
	
	--init canvas stuff
	gameCan = love.graphics.newCanvas(64, 64)
	gameCan:setFilter("nearest")
	
	--find & load autosave
	
	--init game variables
	
	--display title
end

function love.update(dt)
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
	
end

function loadTitleScreen()
end

--------------------------------------------------------------------------

function white()
	love.graphics.setColor(255, 255, 255, 255)
end