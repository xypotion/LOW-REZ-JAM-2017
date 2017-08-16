--this stuff just got too big for main.lua!

function love.draw()
	--switch to gameCanvas
	love.graphics.setCanvas(gameCanvas)
	
	white()
	
	if game.state == "title" then
		drawTitleScreen()
	elseif game.state == "day" or game.state == "night" then
		drawStage()
	elseif game.state == "ending" then
		drawBackgrounds()
	end

	--black overlay for screen fades
	love.graphics.setColor(255, 255, 255, blackOverlay.alpha)
	love.graphics.draw(blackOverlay.graphic, 0, 0)
	
	white()
				
	--display popup messages TODO one day replace with graphics, not just text?
	if overlay.backdrop then 
		love.graphics.setColor(0, 0, 127, 223)
		love.graphics.rectangle("fill", 1 + overlay.xOffset, 1, 62, 62)
		love.graphics.setColor(0, 127, 127, 255)
		love.graphics.rectangle("line", 1 + overlay.xOffset, 1, 62, 62)
		white()
	end
	
	if overlay.image then
		love.graphics.draw(overlay.image, overlayImageQuad, 24 + overlay.xOffset, 4)
	end
	
	love.graphics.printf(overlay.text, overlay.xOffset + 2, 2, 60, "center")
	
	--show volume popup
	if volumePopupAlpha > 0 then
		love.graphics.setColor(30, 37, 108, volumePopupAlpha)
		love.graphics.rectangle("fill", 0, 57, 31, 7)
		
		love.graphics.setColor(255, 255, 255, volumePopupAlpha)
		love.graphics.draw(ui, quads_ui.volume, 7, 58)

		love.graphics.rectangle("fill", 2, 62 - masterVolume * 4, 3, masterVolume * 4)
		
		white()
	end
		
	--draw gameCanvas
	love.graphics.setCanvas()
	love.graphics.draw(gameCanvas, 0, 0, 0, 8, 8)
end

function drawBackgrounds()
	love.graphics.draw(backgrounds[bgMain.graphic])
	
	if bgNext then
		love.graphics.setColor(255, 255, 255, bgNext.alpha)
		love.graphics.draw(backgrounds[bgNext.graphic])
	end
end

function drawTitleScreen()
	drawBackgrounds()
	
	love.graphics.draw(ui, quads_ui["tinyHeart"][getNonCharacterAnimFrame()], 6, 25 + titleMenuCursorPos * 8)
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
			if cellAt(y, x).contents.class == "enemy" and not cellAt(y, x).contents.isBoss then
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
		love.graphics.points(x + enemy.xOffset - 0.5, (ey - 1) * 15 + 17.5 + enemy.yOffset)
	end
	
	love.graphics.setColor(255, 0, 0, 127)
	for x = (ex - 1) * 15 + 5, (ex - 1) * 15 + 4 + enemy.hp.shown do
		love.graphics.points(x + enemy.xOffset - 0.5, (ey - 1) * 15 + 17.5 + enemy.yOffset)
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
	if stage.boss then
		--boss UI
		love.graphics.draw(ui, quads_ui.boss[getNonCharacterAnimFrame()], 51, 8)
		
		--boss hp bar = 4 rectangles
		love.graphics.setColor(0, 0, 0)
		love.graphics.rectangle("fill", 52, 15, 10, 31)
		white()
		love.graphics.rectangle("fill", 53, 16, 8, 29)
		love.graphics.setColor(127, 127, 127)
		love.graphics.rectangle("fill", 54, 17, 6, 27)
		love.graphics.setColor(255, 0, 0)
		love.graphics.rectangle("fill", 54, 44 - bossHPRatio, 6, bossHPRatio)
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
		end
	end
	
	white()
end