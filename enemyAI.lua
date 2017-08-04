function queueEnemyTurn()
	--DEBUG
	queue(bgEvent("night1", 0.5))
	-- hero.sp.actual = hero.sp.actual - 1
	-- queue(actuationEvent(hero.sp, -1))
	queue(bgEvent("night1", 1)) --fake "wait"
	hero.ap.actual = 3
	queueSet({
		bgEvent("day1", 0.5),
		actuationEvent(hero.ap, 3)
	})
end

--[[
loop while enemy has AP

weigh available options: approach hero, escape hero, attack, heal (if applicable) -> do favorite

before moving, must check destination cell to see if it's already reserved.
]]

function meleeTurn()
end

function rangerTurn()
end

function healerTurn()
end