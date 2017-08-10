function stageStart(n)
	--stage initialization
	--TODO (enemies, powers, other stage attributes)
	stage = {}
	stage.field = {
		{empty(), empty(), empty()}, 
		{empty(), empty(), empty()}, 
		{empty(), empty(), empty()}
	}

	--reset hero position & stats
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
	
	--DEBUG kinda
	queue(fadeOutEvent())
	queue(bgEvent("night1", 0))
	-- currentBGM:play() --TODO a queueable music event, i think?
	queue(fadeInEvent())
	
	--spawn starting enemies
	spawnEnemies(stage.startingEnemyList)
	print("queue enemy info popup here")
	
	---aaand begin
	startHeroTurn()
end

function allEnemiesAndBossForStage(n)
	if n == 1 then
		return 
		{"mercuri", "toxy", "sewy", "garby", "algy", "plasty", "pharma", "nukey"}, --DEBUG
		{
			{"garby", "garby"},
			{"toxy", "toxy"},
			{"algy", "algy"},
			{"sewy", "sewy"}, 
			{"nukey", "nukey"},
			{"plasty", "plasty"},
			{"pharma", "pharma"},
			{"mercuri", "mercuri"},
		}, 
		--{{"garby"}, {"garby"}, {"garby"}, {"garby"}, {"plasty"}, {"garby", "garby"}},
		"invasive species"
	elseif n == 2 then
		print("stage 2 enemies...")
	end
end