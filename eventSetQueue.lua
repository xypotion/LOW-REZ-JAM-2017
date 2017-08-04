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

function animEvent()
	local e = {
		class = "anim",
		--what drawable entity
		--frames = { {pose, xOffset, yOffset}s }
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

function peek(q)
	return q[1]
end

function pop(q)
	local item = q[1]
	
	q[1] = nil
	
	for i = 1, #q do
		q[i - 1] = q[i]
	end
	
	q[#q] = nil
	
	return item
end

function push(q, item)
	table.insert(q, item)
end