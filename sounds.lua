--[[
sfx that need work:
- attack
- gluttony
- wish
- enemy spawn (pop)
- ap gain
]]

--features: fading, repeating, swapping to a new source when finished. do we need to separate music and sfx? yes, i think so

function loadSounds()
	sfx = {
		attack = love.audio.newSource("sfx/attack5.wav"),
		wish = love.audio.newSource("sfx/wish.wav"),
		hp = love.audio.newSource("sfx/hp heal.wav"),
		sp = love.audio.newSource("sfx/sp heal.wav"),
		rare = love.audio.newSource("sfx/rare power.wav"),
		gluttony = love.audio.newSource("sfx/gluttony4.wav"),
		pharma = love.audio.newSource("sfx/pharma.wav"),
		toxy = love.audio.newSource("sfx/toxy.wav"),
		nukey = love.audio.newSource("sfx/nukey2.wav"),
		kill = love.audio.newSource("sfx/kill.wav"),
		-- pop = love.audio.newSource("sfx/pop3.mp3"), --not really needed!
	}
	
	bgm = {
		--just all sources; event can set next, repeat is implied, fade is a separate action
		battleAIntro = love.audio.newSource("bgm/battleAIntro1.wav"),
		battleA = love.audio.newSource("bgm/battleA1.wav")
	}
	
	currentBGM = bgm.battleAIntro --DEBUG
	-- currentBGM:setLooping(true)
	nextBGM = bgm.battleA
	
	print(currentBGM:getDuration())
	print(nextBGM:getDuration())
	
	masterVolume = 1
end

function setVolume()
	--TODO
	print("attempting to set volume")
end

function checkBGMTimerAndTransition(dt)
	if nextBGM then
		if bgmTimer >= currentBGM:getDuration() then
			--transition
			print("transition!", bgmTimer, currentBGM:getDuration())
			currentBGM:stop()
			
			currentBGM = nextBGM
			nextBGM = nil
			bgmTimer = 0
			
			currentBGM:setLooping(true)
			currentBGM:play()
		else
			bgmTimer = bgmTimer + dt
		end
	else
		
	end
end