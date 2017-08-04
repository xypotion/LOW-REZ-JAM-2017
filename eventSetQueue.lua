function cellOpEvent(y, x, thing)
	local e = {
		class = "cellOp",
		fieldY = y,
		fieldX = x,
		payload = thing
	}
	
	return e
end

---counter = {actual, shown, posSound, negSound, quick}

function actuationEvent(c, d)
	local e = {
		class = "actuation",
		counter = c,
		delta = d
	}
	
	return e
end

function poseEvent(y, x, f)
	local e = {
		class = "pose",
		fieldY = y, --location of drawable entity (cell contents)
		fieldX = x,	
		frames = f	--frames = { {pose, yOffset, xOffset}s }
	}
	
	return e
end

function animEvent()
	local e = {
		class = "anim",
		--location of drawable entity (cell overlay)
		--named effect (column of effects sheet)
		--frames = { quads (row on effects sheet) }
	}
	
	return e
end

function soundEvent()
	local e = {
		class = "sound",
		--what sound to start
		--TODO what if you're fading music in or out?
	}
	
	return e
end

function screenEvent()
	local e = {
		class = "screen",
		--graphic to display
		--frames = {{xOffset, yOffset, alpha}s }
	}
	
	return e
end

--bgEvent()?

--------------------------------------------------------------------------

function queue(event)
	print("pushing event: ", event.class)
	push(eventSetQueue, {event})
end

function queueSet(eventSet)
	print("pushing eventSet with "..#eventSet.." members")
	push(eventSetQueue, eventSet)
end

--------------------------------------------------------------------------

function peek(q)
	return q[1]
end

function pop(q)
	local item = q[1]
	
	for i = 1, table.getn(q) do
		q[i - 1] = q[i]
	end
	
	q[table.getn(q)] = nil

	return item
end

function push(q, item)
	table.insert(q, item)
end