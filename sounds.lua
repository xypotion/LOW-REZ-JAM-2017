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
		tick = love.audio.newSource("sfx/tick.wav"),
		-- pop = love.audio.newSource("sfx/pop3.mp3"), --not really needed!
	}
	
	--reduce volume for all sfx
	for k, s in pairs(sfx) do
		s:setVolume(0.4)
	end
	
	bgm = {
		--just all sources; event can set next, repeat is implied, fade is a separate action
		titleIntro = love.audio.newSource("bgm/titleIntro.wav"),
		title = love.audio.newSource("bgm/title.wav"),
		battleAIntro = love.audio.newSource("bgm/battleAIntro1.wav"),
		battleA = love.audio.newSource("bgm/battleA1.wav"),
		battleBIntro = love.audio.newSource("bgm/battleBIntro1.wav"),
		battleB = love.audio.newSource("bgm/battleB1.wav"),
		finalIntro = love.audio.newSource("bgm/finalIntro.wav"),
		final = love.audio.newSource("bgm/final.wav"),
		endingIntro = love.audio.newSource("bgm/endingIntro.wav"),
		ending = love.audio.newSource("bgm/ending.wav"),
	}
	
	masterVolume = 1
	bgmVolume = 1
	cycleVolume()
	
	bgmTimer = 0
end

--called when "V" pressed; decreases volume by 25% or sets to 1 if at 0
function cycleVolume()
	masterVolume = (masterVolume - 0.25) % 1.25
	
	setVolume()
end

function setVolume()
	for k, s in pairs(sfx) do
		s:setVolume(masterVolume * 0.4)
	end
	
	for k, b in pairs(bgm) do
		b:setVolume(masterVolume * bgmVolume)
	end
end

--if there is a nextBGM and currentBGM has finished, set current to next and play that on loop
function checkBGMTimerAndTransition(dt)
	if nextBGM then --and currentBGM:isPlaying() then
		if bgmTimer >= currentBGM:getDuration() then
			--transition
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
		--?
	end
end