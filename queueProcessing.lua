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
			
			if e.class == "function" then
				-- print("...calling "..e.func)
				_G[e.func](e.arg1)
				e.finished = true
			end
		
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
				processHeroStatusEvent(e)
			end
			
			if e.class == "pose" then
				processPoseEvent(e)
			end
			
			if e.class == "anim" then
				processAnimEvent(e)
			end
			
			if e.class == "sound" then
				processSoundEvent(e)
			end
			
			if e.class == "bgm" then
				processBgmEvent(e)
			end
			
			if e.class == "bgmFade" then
				processBgmFadeEvent(e)
			end
			
			if e.class == "bg" then
				processBgEvent(e)
			end
			
			if e.class == "wait" then
				processWaitEvent(e)
			end
			
			if e.class == "fadeIn" then
				processFadeInEvent(e)
			end
			
			if e.class == "fadeOut" then
				processFadeOutEvent(e)
			end
			
			if e.class == "screen" then
				processScreenEvent(e)
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

function processCellOpEvent(e)
	cellAt(e.y, e.x).contents = e.payload
		
	e.finished = true
end

function processActuationEvent(e)
	--play sound
	if e.delta > 0 and e.counter.posSound then
		sfx[e.counter.posSound]:stop()
		sfx[e.counter.posSound]:play()
	elseif e.delta < 1 and e.counter.negSound then
		sfx[e.counter.negSound]:stop()
		sfx[e.counter.negSound]:play()
	end
	
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

function processHeroStatusEvent(e)
	local id = e.y * 10 + e.x --hacky, but... it's a game jam!
	
	hero.statusAfflictors[id] = e.status
		
	e.finished = true
end

function processPoseEvent(e)
	local f = pop(e.frames)
	
	cellAt(e.y, e.x).contents.pose = f.pose
	cellAt(e.y, e.x).contents.yOffset = f.yOffset
	cellAt(e.y, e.x).contents.xOffset = f.xOffset
	
	if not peek(e.frames) then
		e.finished = true
	end
end


function processAnimEvent(e)
	if peek(e.frames) then
		cellAt(e.y, e.x).overlayQuad = pop(e.frames)
	else
		cellAt(e.y, e.x).overlayQuad = nil
		e.finished = true
	end
end


function processSoundEvent(e)
	sfx[e.soundName]:stop()
	sfx[e.soundName]:play()
	
	e.finished = true
end

function processBgmEvent(e)
	currentBGM = bgm[e.current]
	currentBGM:play()
	bgmTimer = 0

	if bgmTimer == 0 then
		bgmVolume = 1
		setVolume()
	end
	
	--if there is a next, set up for transition later. otherwise, loop current now
	if e.next then
		nextBGM = bgm[e.next]
	print("just started music in queue processing", nextBGM, currentBGM) --TODO
	else
		currentBGM:setLooping(true)
		nextBGM = nil
	end
	
	e.finished = true
end

function processBgmFadeEvent(e)
	bgmVolume = bgmVolume - 0.05
	setVolume()
	
	if bgmVolume <= 0 then
		currentBGM:stop()
		nextBGM = nil
		
		e.finished = true
	end
end

function processBgEvent(e)
	if not bgNext then
		bgNext = {graphic = e.graphic, alpha = 0}
	end
	
	--what if e.time is 0? TODO
	
	bgNext.alpha = bgNext.alpha + 256 * eventFrameLength / e.time
	-- print(bgNext.alpha, bgMain.alpha)
	
	--fade completed? then we're done
	if bgNext.alpha >= 255 then
		bgMain = bgNext
		bgNext = nil
		e.finished = true
		-- print("finished\n")
	end
end

function processWaitEvent(e)	
	if e.time >= 0 then
		e.time = e.time - eventFrameLength
	else
		e.finished = true
	end
end

function processFadeOutEvent(e)
	if blackOverlay.alpha >= 255 then
		blackOverlay.alpha = 0
	else
		blackOverlay.alpha = blackOverlay.alpha + 256 * eventFrameLength / e.time
	end
	
	if blackOverlay.alpha >= 255 then
		blackOverlay.alpha = 255
		e.finished = true
	end
	-- print(blackOverlay.alpha)
end

function processFadeInEvent(e)
	if blackOverlay.alpha <= 0 then
		blackOverlay.alpha = 255
	else
		blackOverlay.alpha = blackOverlay.alpha - 256 * eventFrameLength / e.time
	end
	
	if blackOverlay.alpha <= 0 then
		blackOverlay.alpha = 0
		e.finished = true
	end
	-- print(blackOverlay.alpha)
end

--i hate hacking like this, but i'm out of patience for good architecture at the moment. simple effect but complicated to do nicely
function processScreenEvent(e)
	if not e.state then
		--begin
		overlay.text = e.text
		overlay.xOffset = 64
		e.state = "flyin"
		
		if e.backdrop then overlay.backdrop = true else overlay.backdrop = false end
		if e.image then overlay.image = e.image else overlay.image = nil end
	elseif e.state == "flyin" then
		overlay.xOffset = overlay.xOffset - 8
		
		if overlay.xOffset == 0 then
			e.state = "waiting"
			
			if e.keypressRequired then
				e.waitingForKeypress = true
			else
				e.expirationTime = 0.5
			end
		end
	elseif e.state == "waiting" then
		if e.waitingForKeypress then
			if love.keyboard.isDown("space", '1', '2', '3', '4', '5', '6', '7', '8', '9', '0', 'q', 'w', 'e', 'r', 't', 'y', 'u', 'i', 'o', 'p', 'a', 's', 'd', 'f', 'g', 'h', 'j', 'k', 'l', 'z', 'x', 'c', 'v', 'b', 'n', 'm', "return") then
				e.state = "flyout"
			end
		elseif e.expirationTime > 0 then
			e.expirationTime = e.expirationTime - eventFrameLength
		else
			e.state = "flyout"
		end
	elseif e.state == "flyout" then
		overlay.xOffset = overlay.xOffset - 8

		if overlay.xOffset <= -64 then
			e.finished = true
			overlay.text = ""
		end
	end
end

----------------------------------------------------------------------------------------------------------------------------------------------------

--force queue set to be processed immediately, not at next scheduled interval. should start normally again after this
function processNow()
	eventFrame = eventFrameLength
end
