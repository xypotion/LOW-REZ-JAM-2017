function stageStart(n)
	--stage initialization
	--TODO (enemies, powers, other stage attributes)
	
	--DEBUG
	-- queue(bgEvent("black", 1.5))
	queue(fadeOutEvent())
	queue(bgEvent("night1", 0))
	queue(fadeInEvent())
	-- queue(gameStateEvent("state", "night"))
	-- cellAt(2,2).contents = hero
	-- spawnEnemies(stage.startingEnemyList)
	-- -- queue(gameStateEvent("day"))
	startHeroTurn()
	-- love.graphics.setFont(love.graphics.newFont(7))
	currentBGM:play() --TODO a queueable music event, i think?
end