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
	print(stage.enemyCount.actual)
	
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
	
	queue(bgmEvent("battleAIntro", "battleA")) --DEBUG
	queue(fadeInEvent())
	
	--spawn starting enemies
	queue(actuationEvent(stage.enemyCount, stage.enemyCount.actual))
	
	queue(screenEvent("\n\n\n  STAGE "..game.maxStage)) --TODO use graphics, not text
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
	
	--fade music
	print("fading music") --TODO
	
	--quick fade before resetting hero pos & stats
	queue(fadeOutEvent())
	
	game.maxStage = game.maxStage + 1
end

function allEnemiesAndBossForStage(n)
	if n == 1 then
		return 
		-- {"heat", "gluttony", "noise", "invasive", "oil", "light", "xps", "greed"}, --DEBUG
		{"toxy", "sewy", "garby", "algy", "plasty", "pharma", "nukey", "mercuri"}, --DEBUG
		{
			{"garby", "garby"},
			{"toxy", "toxy"},
			{"algy", "algy"},
			{"sewy", "sewy"},
			-- {"nukey", "nukey"},
			-- {"plasty", "plasty"},
			-- {"pharma", "pharma"},
			-- {"mercuri", "mercuri"},
			{"toxy"}
		},
		-- {{"garby", "garby", "garby", "garby"}, },--, {"garby"}, {"garby"}, {"garby"}, {"plasty"}, {"garby", "garby"}},
		-- "invasive species"
		"oil"
	elseif n == 2 then
		return
		{"toxy", "sewy"},-- "garby", "algy", "plasty", "pharma"},--, "nukey", "mercuri"}, --DEBUG
		-- {
		-- 	{"garby", "garby"},
		-- 	{"toxy", "toxy"},
		-- 	{"algy", "algy"},
		-- 	{"sewy", "sewy"},
		-- 	{"nukey", "nukey"},
		-- 	{"plasty", "plasty"},
		-- 	{"pharma", "pharma"},
		-- 	{"mercuri", "mercuri"},
		-- },
		{{"pharma", "pharma"}},--, {"garby"}, {"garby"}, {"garby"}, {"plasty"}, {"garby", "garby"}},
		-- "invasive species"
		"garby"
	elseif n == 3 then
		print("stg 3 3n3mi3s")
	end
end

function unloadGameAndReturnToTitle()
	queueSet({
		gameStateEvent("state", "title"),
		bgEvent("title1", 0),
		functionEvent("initStage"), --queueing to happen again since this happens in love.load()
		functionEvent("initHero"), --queueing to happen again since this happens in love.load()
	})
	queue(fadeInEvent(1))
end