function processEventSets(dt)
	--block input during processing if there are any events, otherwise allow reenable input and break
	if peek(eventSetQueue) then 
		inputLevel = "none"
	else
		inputLevel = "normal"
		return
	end
	
	local es = peek(eventSetQueue)
	local numFinished = 0
	
	--process them all
	for k, e in pairs(es) do
		--if not already finished, process this event
		if not e.finished then
			-- print("processing "..e.class)
		
			if e.class == "actuation" then
				processActuationEvent(e)
			end
		
			if e.class == "cellOp" then
				processCellOpEvent(e)
			end
			
			if e.class == "pose" then
				processPoseEvent(e)
			end
		end
				
		--tally finished events in set
		if e.finished then
			numFinished = numFinished + 1
		end
	end
	
	--pop event if all finished
	if numFinished == #es then
		pop(eventSetQueue)
	end
end

----------------------------------------------------------------------------------------------------------------------------------------------------

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


function processPoseEvent(e)
	-- print(table.getn(e.frames))
	local f = pop(e.frames)
	-- print(table.getn(e.frames))
	
	stage.field[e.fieldY][e.fieldX].pose = f.pose
	stage.field[e.fieldY][e.fieldX].yOffset = f.yOffset
	stage.field[e.fieldY][e.fieldX].xOffset = f.xOffset
	
	if not peek(e.frames) then
		print("finished")
		e.finished = true
	end
end


function processAnimEvent()
end


function processSoundEvent()
end


function processScreenEvent()
end

----------------------------------------------------------------------------------------------------------------------------------------------------

--force queue set to be processed immediately, not at next scheduled interval. should start normally again after this
function processNow()
	eventFrame = eventFrameLength
end
