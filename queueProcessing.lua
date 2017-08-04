--TODO sound? moving, enemy kills...
function processCellOpEvent(e)
	stage.field[e.fieldY][e.fieldX] = e.payload
	
	e.finished = true
end


--TODO "quick" actuations
--TODO regardless of delta, shown should never go over max or under 0; finish if you hit those
--TODO pos/neg sounds
function processActuationEvent(e)
	--decrement shown and increment delta OR vice-versa
	if e.delta > 0 then
		e.counter.shown = e.counter.shown + 1
		e.delta = e.delta - 1
	elseif e.delta < 0 then
		e.counter.shown = e.counter.shown - 1
		e.delta = e.delta + 1
	end
	
	--finished if delta is depleted
	if e.delta == 0 then
		e.finished = true
	end
end


function processAnimEvent()
end


function processSoundEvent()
end


function processScreenEvent()
end