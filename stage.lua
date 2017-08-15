function initStage()
	--stage initialization
	stage = {}
	stage.field = {
		{empty(), empty(), empty()},
		{empty(), empty(), empty()},
		{empty(), empty(), empty()}
	}
	--...not that simple, unfortunately. might have to reset things one by one TODO
end
	
function stageStart(n)
	
	--fade music
	print("fading music at end of stage", nextBGM, currentBGM) --TODO
	queue(bgmFadeEvent())
	--reset hero stats (will be actuated in a moment). yes, it's OK to do this here. don't panic. possibly change/move later when you implement Continue TODO
	hero.hp.actual = hero.hp.max
	hero.ap.actual = hero.ap.max
	hero.sp.actual = hero.sp.max
	
	--fetch and shuffle stage's enemies 
	stage.startingEnemyList, stage.enemyList, stage.bossSpecies = allEnemiesAndBossForStage(n)
	stage.enemyList = shuffle(stage.enemyList)
	
	--probably just hard-code ratios for drops instead of this TODO
	stage.powers = {} --DEBUG
	for i = 1, 10 do
		push(stage.powers, "blueFish")
		push(stage.powers, "blueFish")
		push(stage.powers, "redFish")
	end
	stage.powers = shuffle(stage.powers)
	
	--count enemies
	stage.enemyCount = {max = 0, actual = 0, shown = 0, posSound = "tick", negSound = nil}
	for k, v in pairs(stage.startingEnemyList) do
		stage.enemyCount.max = stage.enemyCount.max + 1
	end
	for k, v in pairs(stage.enemyList) do
		for l, w in pairs(v) do
			stage.enemyCount.max = stage.enemyCount.max + 1
		end
	end
	stage.enemyCount.actual = stage.enemyCount.max
	-- print(stage.enemyCount.actual)
	
	--DEBUG kinda
	--screen should be faded out at this point, either from title screen transition or stageEnd()
	
	--actuate those stats
	queueSet({
		actuationEvent(hero.hp, hero.hp.actual - hero.hp.shown),
		actuationEvent(hero.sp, hero.sp.actual - hero.sp.shown),
		actuationEvent(hero.ap, hero.ap.actual - hero.ap.shown),
	})
	
	--reset that field
	queueSet({
		cellOpEvent(1, 1, clear()),
		cellOpEvent(1, 2, clear()),
		cellOpEvent(1, 3, clear()),
		cellOpEvent(2, 1, clear()),
		cellOpEvent(2, 2, hero),
		cellOpEvent(2, 3, clear()),
		cellOpEvent(3, 1, clear()),
		cellOpEvent(3, 2, clear()),
		cellOpEvent(3, 3, clear()),
	})
	
	--night time ~
	queueSet({
		gameStateEvent("state", "night"),
		bgEvent("night1", 0)
	})
	
	--start up which music?
	if game.maxStage < game.lastStage then
		if game.maxStage % 2 == 0 then
			queue(bgmEvent("battleAIntro", "battleA"))
		else
			queue(bgmEvent("battleBIntro", "battleB"))
		end
	else
		--boss music			
		queue(bgmEvent("battleAIntro", "battleA")) --TODO actual boss music
	end
	print("queueing music at start of stage", nextBGM, currentBGM) --TODO
	
	queue(fadeInEvent())
	
	--spawn starting enemies
	queue(actuationEvent(stage.enemyCount, stage.enemyCount.actual))
	
	queue(screenEvent("\n\n\nSTAGE "..game.maxStage)) --TODO use graphics, not text
	-- queue(screenEvent("\n\n\n  STAGE "..game.maxStage.."\n\n    press SPACE", true)) --TODO use graphics, not text
	
	--and the awkward part... having these be called (via queue & processing) AFTER the above things ensures that enemy spawns never overwrite hero
	queue(functionEvent("spawnEnemies", stage.startingEnemyList))
	
	--also queueing this to occur later so to preserve the original order
	queue(functionEvent("startHeroTurn"))
	
	-- spawnEnemies(stage.startingEnemyList)
	-- print("queue enemy info popup here")
	
	-- ---aaand begin
	-- startHeroTurn()
end

function stageEnd()
	stage.boss = nil
	
	--quick fade before resetting hero pos & stats
	queue(fadeOutEvent())
	
	game.maxStage = game.maxStage + 1
end

function allEnemiesAndBossForStage(n)
	if n == 1 then
		return
		-- {"heat", "gluttony", "noise", "invasive", "oil", "light", "xps", "greed"}, --DEBUG
		-- {"toxy", "sewy", "garby", "algy", "plasty", "pharma", "nukey", "mercuri"}, --DEBUG
		{"garby"},
		{
			{"garby"},
			{"garby"},
			{"garby"},
			{"garby", "garby"}, --6
		},
		"heat"
	elseif n == 2 then
		return
		{"garby", "garby"},
		{
			{"plasty"},
			{"plasty"},
			{"garby", "garby"},
			{"garby"}, --8
		},
		"invasive"
	elseif n == 3 then
		return
		{"plasty", "plasty"},
		{
			{"garby"},
			{"mercuri"},
			{"mercuri"},
			{"mercuri"},
			{"garby", "plasty"},
			{"garby"},
			{"garby"}, --10
		},
		"oil"
	elseif n == 4 then
		return
		{"garby", "mercuri"},
		{
			{"plasty"},
			{"mercuri"},
			{"mercuri"},
			{"plasty", "garby"},
			{"toxy", "toxy"},
			{"toxy"},
			{"garby"},
			{"garby"}, --12
		},
		"light"
	elseif n == 5 then
		return
		{"toxy", "garby", "mercuri"},
		{
			{"algy"},
			{"mercuri"},
			{"algy"},
			{"plasty", "garby"},
			{"toxy", "algy"},
			{"toxy"},
			{"garby"},
			{"garby"},
			{"plasty"} --14
		},
		"xps"
	elseif n == 6 then
		return
		{"mercuri", "plasty"},
		{
			{"garby"},
			{"garby", "garby"},
			{"algy", "algy"},
			{"toxy", "toxy", "toxy"},
			{"plasty"},
			{"plasty"},
			{"sewy"},
			{"sewy"},
			{"sewy"},
			{"sewy"} --16
		},
		"noise"
	elseif n == 7 then
		return
		{"garby", "garby", "garby", "garby"},
		{
			{"plasty", "pharma"},
			{"algy", "pharma"},
			{"toxy", "pharma"},
			{"sewy"},
			{"sewy"},
			{"mercuri"},
			{"mercuri"},
			{"garby"},
			{"garby"},
			{"garby"},
			{"garby"} --18
		},
		"gluttony"
	elseif n == 8 then
		return
		{"pharma", "pharma"},
		{
			{"mercuri", "garby"},
			{"algy", "garby"},
			{"toxy", "garby"},
			{"plasty", "garby"},
			{"algy"},
			{"toxy"},
			{"mercuri"},
			{"sewy"},
			{"pharma"},
			{"nukey"},
			{"nukey", "nukey", "nukey", "nukey"} --20
		},
		"greed"
	elseif n == 9 then
		return
		{"toxy", "sewy", "garby", "algy", "plasty", "pharma", "nukey", "mercuri"}, --DEBUG
		{},
		"apathy"
	end
end

function gameOverIFHeroDead()
	if hero.hp.actual <= 0 then
		queue(bgmFadeEvent())
		queueSet({
			fadeOutEvent(),
			screenEvent("</3\nGAME OVER\n\n\"Please try again!\"\nMother Nature", true),
		})
		unloadGameAndReturnToTitle()
	end
end

function unloadGameAndReturnToTitle()
	queueSet({
		gameStateEvent("state", "title"),
		bgmFadeEvent(),
		bgEvent("title1", 0),
		functionEvent("initStage"), --queueing to happen again since this happens in love.load()
		functionEvent("initHero"), --queueing to happen again since this happens in love.load()
	})
	queue(bgmEvent("titleIntro", "title"))
	queue(fadeInEvent(1))
	titleMenuCursorPos = 2
end