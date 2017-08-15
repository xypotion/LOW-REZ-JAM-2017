function gameStateEvent(v, to)
	local e = {
		class = "gameState",
		variable = v,
		value = to
	}
	
	return e
end

function cellOpEvent(y, x, thing)
	local e = {
		class = "cellOp",
		y = y,
		x = x,
		payload = thing
	}
	
	return e
end

--for updating visible counters to their actual values
--counter = {actual, shown, posSound, negSound}
function actuationEvent(c, d)
	local e = {
		class = "actuation",
		counter = c,
		delta = d --or c.actual - c.shown --i wish this worked, but it mis-calculates/actuates if the same counter is changed in multiple queued events
	}
		
	return e
end

--basically just for applying and removing sticks
function statusEvent(ey, ex, s)
	local e = {
		class = "status",
		y = ey,
		x = ex,
		status = s
	}
	
	return e
end

--for making battle entities change poses and/or move around
function poseEvent(y, x, f)
	local e = {
		class = "pose",
		y = y, --location of drawable entity (cell contents)
		x = x,	
		frames = f	--frames = { {pose, yOffset, xOffset}s }
	}
	
	return e
end

--for fancy battle graphics. automatically targets cells' invisible animation overlays
function animEvent(y, x, f)--fx, f)
	local e = {
		class = "anim",
		y = y,		--location of drawable entity (cell overlay)
		x = x,
		frames = f		--frames = { quad pointers (row on effects sheet) }
	}
	
	return e
end

--for starting or stopping sounds
function soundEvent(name)
	local e = {
		class = "sound",
		soundName = name
		--repeatTimes TODO probably the best way to do a good gluttony sound
	}
	
	return e
end

function bgmEvent(nowName, nextName)
	local e = {
		class = "bgm",
		current = nowName,
		next = nextName
	}
	
	return e
end

function bgmFadeEvent()
	local e = {
		class = "bgmFade"
	}
	
	return e
end

--for changing backgrounds
function bgEvent(bg, time)
	local e = {
		class = "bg",
		graphic = bg, --night, day, title, etc.; all named graphics to fade into background layer
		time = time or 0.5 --seconds to draw out fade
	}
	
	return e
end

--for changing backgrounds
function waitEvent(time)
	local e = {
		class = "wait",
		time = time or 0.5 --seconds to draw out fade
	}
	
	return e
end

function fadeOutEvent(time)
	local e = {
		class = "fadeOut",
		time = time or 0.25
	}
	
	return e
end

function fadeInEvent(time)
	local e = {
		class = "fadeIn",
		time = time or 0.25
	}
	
	return e
end

--for overlays and such. text or image flies up from the bottom & is then dismissed either after a wait or a keypress
function screenEvent(text, kr, bd, im) --TODO should actually be an overlay graphic's name, but just text for now
	local e = {
		class = "screen",
		text = text,
		keypressRequired = kr,
		backdrop = bd,
		image = im
	}
		
	return e
end

--when processed, causes a function to be called with args
--is this the worst thing i've done yet? or should i have done this a long time ago?
function functionEvent(func, arg1)
	local e = {
		class = "function",
		func = func,
		arg1 = arg1 --messy, messy, messy. oh, well.
	}
	
	return e
end

--------------------------------------------------------------------------

function queue(event)
	push(eventSetQueue, {event})
end

function queueSet(eventSet)
	push(eventSetQueue, eventSet)
end

--------------------------------------------------------------------------