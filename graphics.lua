function loadGraphics()
	-- grid = love.graphics.newImage("img/grid.png") --TODO remove, i guess
	
	sheet_player = love.graphics.newImage("img/sheet_player.png")
	
	enemySheets = {
		toxy = love.graphics.newImage("img/sheet_toxy.png"),
		mercuri = love.graphics.newImage("img/sheet_mercuri.png"),
		algy = love.graphics.newImage("img/sheet_algy.png"),
		sewy = love.graphics.newImage("img/sheet_sewy.png"),
		garby = love.graphics.newImage("img/sheet_garby.png"),
		plasty = love.graphics.newImage("img/sheet_plasty.png"),
		pharma = love.graphics.newImage("img/sheet_pharma.png"),
		nukey = love.graphics.newImage("img/sheet_nukey 3.png"),
		oil = love.graphics.newImage("img/sheet_oil.png"),
		heat = love.graphics.newImage("img/sheet_nukey.png"),
		noise = love.graphics.newImage("img/sheet_noise_pollution.png"),
		light = love.graphics.newImage("img/sheet_light_pollution.png"),
		invasive = love.graphics.newImage("img/sheet_invasive_species.png"),
		xps = love.graphics.newImage("img/sheet_xps.png"),
		gluttony = love.graphics.newImage("img/sheet_gluttony.png"),
		greed = love.graphics.newImage("img/sheet_greed.png"),
		apathy = love.graphics.newImage("img/sheet_apathy.png"),
	}
	
	sheet_effects = love.graphics.newImage("img/effects.png")
	
	ui = love.graphics.newImage("img/ui.png")
	
	powerSheet = love.graphics.newImage("img/powers.png")
	
	backgrounds = {
		title1 = love.graphics.newImage("img/title1.png"),
		day1 = love.graphics.newImage("img/bg_day2.png"),
		night1 = love.graphics.newImage("img/bg_night2.png")
	}
	
	blackOverlay = {graphic = love.graphics.newImage("img/black.png"), alpha = 255}
end

function loadQuads()	
	overlayImageQuad = love.graphics.newQuad(0, 0, 16, 16, 64, 64)
	
	characterQuads = {
		idle = {
			love.graphics.newQuad(0, 0, 16, 16, 64, 64),
			love.graphics.newQuad(0, 16, 16, 16, 64, 64),
			love.graphics.newQuad(0, 32, 16, 16, 64, 64),
			love.graphics.newQuad(0, 48, 16, 16, 64, 64)
		},
		casting = {
			love.graphics.newQuad(16, 0, 16, 16, 64, 64),
			love.graphics.newQuad(16, 16, 16, 16, 64, 64),
			love.graphics.newQuad(16, 32, 16, 16, 64, 64),
			love.graphics.newQuad(16, 48, 16, 16, 64, 64)
		},
		stuck = {
			love.graphics.newQuad(32, 0, 16, 16, 64, 64),
			love.graphics.newQuad(32, 16, 16, 16, 64, 64),
			love.graphics.newQuad(32, 32, 16, 16, 64, 64),
			love.graphics.newQuad(32, 48, 16, 16, 64, 64)
		}
	}
	
	powerQuads = {
		blueFish = {
			love.graphics.newQuad(0, 0, 16, 16, 64, 64),
			love.graphics.newQuad(0, 16, 16, 16, 64, 64),
		},
		redFish = {
			love.graphics.newQuad(0, 32, 16, 16, 64, 64),
			love.graphics.newQuad(0, 48, 16, 16, 64, 64),
		}
	}
	
	quads_ui = {
		hp = love.graphics.newQuad(0, 0, 9, 5, 64, 64),
		hpT = love.graphics.newQuad(10, 0, 3, 5, 64, 64),
		hpF = love.graphics.newQuad(14, 0, 3, 5, 64, 64),
		ap = love.graphics.newQuad(0, 6, 9, 5, 64, 64),
		apT1 = love.graphics.newQuad(10, 6, 5, 5, 64, 64),
		apF1 = love.graphics.newQuad(16, 6, 5, 5, 64, 64),
		apT2 = love.graphics.newQuad(22, 6, 4, 5, 64, 64),
		apF2 = love.graphics.newQuad(27, 6, 4, 5, 64, 64),
		sp = love.graphics.newQuad(0, 12, 9, 5, 64, 64),
		spT1 = love.graphics.newQuad(10, 12, 5, 5, 64, 64),
		spF1 = love.graphics.newQuad(16, 12, 5, 5, 64, 64),
		spT2 = love.graphics.newQuad(22, 12, 4, 5, 64, 64),
		spF2 = love.graphics.newQuad(27, 12, 4, 5, 64, 64),
		stink = {
			love.graphics.newQuad(0, 18, 30, 5, 64, 64),
			love.graphics.newQuad(0, 24, 30, 5, 64, 64),
		},
		enemiesLeft = love.graphics.newQuad(52, 0, 12, 5, 64, 64),
		enemyAlive = love.graphics.newQuad(52, 6, 3, 2, 64, 64),
		-- enemyDead = love.graphics.newQuad(56, 6, 3, 2, 64, 64), --TODO decide if you actually want this
		boss = {
			love.graphics.newQuad(52, 9, 12, 5, 64, 64),
			love.graphics.newQuad(52, 15, 12, 5, 64, 64),
		},
		tinyHeart = {
			love.graphics.newQuad(0, 30, 8, 7, 64, 64),
			love.graphics.newQuad(9, 30, 8, 7, 64, 64),
		},
		volume = love.graphics.newQuad(27, 0, 22, 5, 64, 64)
	}
end