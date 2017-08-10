function stageStart(n)
	--stage initialization
	stage = {}
	stage.field = {
		{empty(), empty(), empty()}, 
		{empty(), empty(), empty()}, 
		{empty(), empty(), empty()}
	}

	--reset hero position & stats. yes, it's OK to do this here. don't panic. possibly change/move later when you implement Continue TODO
	cellAt(2,2).contents = hero
	hero.hp.actual = hero.hp.max
	hero.hp.shown = hero.hp.max
	hero.ap.actual = hero.ap.max
	hero.ap.shown = hero.ap.max
	hero.sp.actual = hero.sp.max
	hero.sp.shown = hero.sp.max
	
	--fetch and shuffle stage's enemies 
	stage.startingEnemyList, stage.enemyList, stage.boss = allEnemiesAndBossForStage(n)
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
	stage.enemyCount = {max = 0, actual = 0, shown = 0, posSound = "tick", negSound = nil, quick = false} --TODO remove "quick". it's not a thing
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
	queue(fadeOutEvent())
	queue(gameStateEvent("state", "night"))
	queue(bgEvent("night1", 0))
	-- currentBGM:play() --TODO a queueable music event, i think?
	queue(bgmEvent("battleAIntro", "battleA"))
	queue(fadeInEvent())
	
	--spawn starting enemies
	queue(actuationEvent(stage.enemyCount, stage.enemyCount.actual))
	spawnEnemies(stage.startingEnemyList)
	print("queue enemy info popup here")
	
	---aaand begin
	startHeroTurn()
end

function allEnemiesAndBossForStage(n)
	if n == 1 then
		return 
		{"algy"},--, "toxy", "sewy", "garby", "algy", "plasty", "pharma", "nukey"}, --DEBUG
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
		{{"garby"}, {"garby"}, {"garby"}, {"garby"}, {"plasty"}, {"garby", "garby"}},
		"invasive species"
	elseif n == 2 then
		print("stage 2 enemies...")
	end
end