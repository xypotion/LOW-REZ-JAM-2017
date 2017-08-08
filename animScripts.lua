function initAnimFrames()
	quads_animation = {
		spark = {
			love.graphics.newQuad(0, 0, 16, 16, 128, 64),
			love.graphics.newQuad(0, 16, 16, 16, 128, 64),
			love.graphics.newQuad(0, 32, 16, 16, 128, 64),
			love.graphics.newQuad(0, 48, 16, 16, 128, 64),
		},
		glow = {
			love.graphics.newQuad(16, 0, 16, 16, 128, 64),
			love.graphics.newQuad(16, 16, 16, 16, 128, 64),
			love.graphics.newQuad(16, 32, 16, 16, 128, 64),
			love.graphics.newQuad(16, 48, 16, 16, 128, 64),
		}
	}
end

function sparkAnimFrames()
	return {
		quads_animation.spark[1],
		quads_animation.spark[2],
		quads_animation.spark[3],
		quads_animation.spark[4],
		quads_animation.spark[1],
		quads_animation.spark[2],
		quads_animation.spark[3],
		quads_animation.spark[4],
	}
end

function glowAnimFrames()
	return {
		quads_animation.glow[1],
		quads_animation.glow[2],
		quads_animation.glow[3],
		quads_animation.glow[4],
		quads_animation.glow[1],
		quads_animation.glow[2],
		quads_animation.glow[3],
		quads_animation.glow[4],
	}
end
		