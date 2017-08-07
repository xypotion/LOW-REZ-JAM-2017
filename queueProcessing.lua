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
		--TODO this stack of ifs is just awfs. DO SOMETHIIING EEHHHH
		if not e.finished then
			-- print("processing "..e.class)
		
			if e.class == "gameState" then
				processGameStateEvent(e)
			end
		
			if e.class == "cellOp" then
				processCellOpEvent(e)
			end
		
			if e.class == "actuation" then
				processActuationEvent(e)
			end
		
			if e.class == "status" then
				processStatusEvent(e)
			end
			
			if e.class == "pose" then
				processPoseEvent(e)
			end
			
			if e.class == "anim" then
				processAnimEvent(e)
			end
			
			if e.class == "bg" then
				processBgEvent(e)
			end
			
			if e.class == "wait" then
				processWaitEvent(e)
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

function processGameStateEvent(e)
	print(e.variable, e.value)
	game[e.variable] = e.value
	e.finished = true
end

--TODO sound? moving, enemy kills...
function processCellOpEvent(e)
	stage.field[e.fieldY][e.fieldX].contents = e.payload
		
	e.finished = true
end

--TODO "quick" actuations
--TODO pos/neg sounds
function processActuationEvent(e)
	--decrement shown and increment delta OR vice-versa, as long as shown is not already at max or 0
	if e.delta > 0 and e.counter.shown < e.counter.max then
		e.counter.shown = e.counter.shown + 1
		e.delta = e.delta - 1
	elseif e.delta < 0 and e.counter.shown > 0 then
		e.counter.shown = e.counter.shown - 1
		e.delta = e.delta + 1
	end
	
	--finished if delta is depleted OR shown is at max or shown is at 0
	if e.delta == 0 or e.counter.shown >= e.counter.max or e.counter.shown <= 0 then
		e.finished = true
	end
end

function processStatusEvent(e)
	local id = e.fieldY * 10 + e.fieldX --hacky, but... it's a game jam!
	
	hero.statusAfflictors[id] = e.status
	
	print("statuses: set "..id.." as "..e.status)
	
	e.finished = true
end

function processPoseEvent(e)
	-- print(table.getn(e.frames))
	local f = pop(e.frames)
	-- print(table.getn(e.frames))
	
	stage.field[e.fieldY][e.fieldX].contents.pose = f.pose
	stage.field[e.fieldY][e.fieldX].contents.yOffset = f.yOffset
	stage.field[e.fieldY][e.fieldX].contents.xOffset = f.xOffset
	
	if not peek(e.frames) then
		-- print("finished")
		e.finished = true
	end
end


function processAnimEvent(e)
	if peek(e.frames) then
		stage.field[e.fieldY][e.fieldX].overlayQuad = pop(e.frames)
	else
		stage.field[e.fieldY][e.fieldX].overlayQuad = nil
		e.finished = true
	end
end


function processSoundEvent()
end


function processScreenEvent()
end

function processBgEvent(e)
	if not bgNext then
		bgNext = {graphic = e.graphic, alpha = 0}
	end
	
	--what if e.time is 0? TODO
	
	bgNext.alpha = bgNext.alpha + math.ceil(256 * eventFrameLength / e.time)
	
	--fade completed? then we're done
	if bgNext.alpha >= 255 then
		bgMain = bgNext
		bgNext = nil
		e.finished = true
	end
end

function processWaitEvent(e)	
	if e.time >= 0 then
		e.time = e.time - eventFrameLength
	else
		e.finished = true
	end
end

----------------------------------------------------------------------------------------------------------------------------------------------------

--force queue set to be processed immediately, not at next scheduled interval. should start normally again after this
function processNow()
	eventFrame = eventFrameLength
end
