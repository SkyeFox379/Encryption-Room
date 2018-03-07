Player = class {}

function Player:new(x, y)
	self.pos = Vec2(x, y)
	self.size = 28
	self.weapon = {}
	self.weapon.damage = 100
	self.dir = 0
end

function Player:getRect()
	return Rectangle(self.pos.x, self.pos.y, self.size, self.size)
end

local lastDrop = false
function Player:update(dt, world)
	local velocity = Vec2(0, 0)

	if love.keyboard.isDown("up", "w") then
		velocity.y = velocity.y - 1
		self.dir = 0
	end
	if love.keyboard.isDown("down", "s") then
		velocity.y = velocity.y + 1
		self.dir = 2
	end
	if love.keyboard.isDown("left", "a") then
		velocity.x = velocity.x - 1
		self.dir = 3
	end
	if love.keyboard.isDown("right", "d") then
		velocity.x = velocity.x + 1
		self.dir = 1
	end

	local speed = 128
	if love.keyboard.isDown("lshift") then
		speed = 256
	end

	local dropPressed = love.keyboard.isDown("q")
	if not lastDrop and dropPressed then
		world:addGlowstick(spriteCurrTile(self):split())
	end
	lastDrop = dropPressed

	velocity = velocity:normalized() * speed * dt

	if velocity.x ~= 0 or velocity.y ~= 0 then
		local t = moveSprite(self, velocity, world.tilemap, 10)
		if t == TileType.Stairs then
			world:complete()
		end
	end
end

function Player:draw()
	love.graphics.setColor(255, 255, 255)
	love.graphics.draw(TEXTURES.player, self.pos.x + 16, self.pos.y+16, (math.pi / 2) * self.dir, 1, 1, 16,16)
--	love.graphics.rectangle("fill", self.pos.x, self.pos.y, self.size, self.size)
end

function spriteCurrTile(sprite)
	return Vec2(math.floor((sprite.pos.x + sprite.size / 2) / TileSize)
			  , math.floor((sprite.pos.y + sprite.size / 2) / TileSize))
end

function moveSprite(sprite, vel, tilemap, steps)
	local sct = spriteCurrTile(sprite)
	local tileRects = tilemap:getRects(sct.x, sct.y, 4)
	local tileHit = -1

	function move(dx, dy)
		local d = Vec2(dx, dy)
		sprite.pos = sprite.pos + d
		local sprRect = sprite:getRect()

		local worked = true
		for _, trs in pairs(tileRects) do
			for _, tr in pairs(trs) do
				if sprRect:intersects(tr[1]) then
					sprite.pos = sprite.pos - d
					tileHit = tr[2]
					worked = false
					break
				end
			end
		end

		return worked
	end

	local dvel = vel * (1 / steps)
	local dx = dvel.x
	local dy = dvel.y

	local xdone = false
	local ydone = false
	for i = 1, steps do
		if not xdone and not move(dx, 0) then xdone = true end
		if not ydone and not move(0, dy) then ydone = true end
	end

	return tileHit
end
