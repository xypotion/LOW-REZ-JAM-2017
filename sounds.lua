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
	}
	
	bgm = {
		--just all sources; event can set next, repeat is implied, fade is a separate action
	}
	
	-- currentBGM = 
	-- currentBGM.setLooping(true)
	-- nextBGM = 
	
	masterVolume = 1
end

function setVolume()
	--TODO
	print("attempting to set volume")
end