local colors = {
	{ 255, 255,   0 };
	{   0,   0, 255 };	
	{   0, 255,   0 };	
	{ 255,   0, 255 };	
}

World = class {}

function World:new(console, w, h, rooms, puzzles, time)
	self.completed = false
	self.console = console
	self.rooms = {}
	self.masterRoom = -1

	self.player = Player(0, 0)
	self.tilemap = Tilemap(w, h)

	self.glowsticks = {}
	self.objects = {}
	self.closestObject = nil

	self.objectives = {}
	self.timer = time
	self.left = 0
	self.generated = puzzles

	DungeonGen(self, rooms):generate(self.player)
	self:generateObjectives()

	self.playerLightId =
		self.tilemap:addLight(math.floor((self.player.pos.x + TileSize / 2) / TileSize),
							  math.floor((self.player.pos.y + TileSize / 2) / TileSize), 6)
	self.tilemap:calculateLight(0, 0)
	self.tilemap:calculateWalls()
end

function World:generateObjectives()
	local usedSpaces = {}

	local roomSide = {
		{ 0, 0, 1, 0, -4, 0, -1, 0 }; --Left
		{ 0, 0, 0, 1, 0, -4, 0, -1 }; --Up
		{ 1, 0, 1, 0,  4, 0,  1, 0 }; --Right
		{ 0, 1, 0, 1, 0,  4, 0,  1 }; --Down
	}

	local function placeSomething(thing, color)
		local done = false
		repeat
			local room = math.floor(love.math.random(1, #self.rooms))
			if room ~= self.masterRoom then
				local done2 = false
				repeat
					local side = math.floor(love.math.random(0, 3))	
					local rs = roomSide[side + 1]
					local max = rs[3] * (self.rooms[room].h - 1) + rs[4] * (self.rooms[room].w - 1)

					local dist = math.floor(love.math.random(1, max))
					local x = self.rooms[room].x + (self.rooms[room].w - 1) * rs[1] + dist * rs[4]
					local y = self.rooms[room].y + (self.rooms[room].h - 1) * rs[2] + dist * rs[3]

					works = true
					for _, o in pairs(usedSpaces) do
						if o[1] == x and o[2] == y then
							works = false
						end
					end

					if works then
						if self.tilemap:getTile(x + rs[7], y + rs[8], {id = -1}).id == TileType.Wall then
							local obj = thing((x + rs[7]) * TileSize, (y + rs[8]) * TileSize, side * math.pi / 2, color)
							print ("at", x, y, side)
							table.insert(usedSpaces, {x, y})
							self:addObject(obj)
							done2 = true
						end
					end
				until done2
				done = true
			end
		until done
	end

	local function placeButton(color)
		print ("Placing a button with color ")
		placeSomething(Button, color)
	end

	local function placeLever(color)
		print ("Placing a lever with color ")
		placeSomething(Lever, color)
	end

	placeButton(1)
	placeButton(2)
	placeButton(3)
	placeButton(4)
	placeLever(1)
	placeLever(2)
	placeLever(3)
	placeLever(4)

	local stmts = generateUniqueStatements(self.generated)
	self.consoleMessage = {}
	for _, stmt in pairs(stmts) do
		table.insert(self.objectives, stmt)
		table.insert(self.consoleMessage, "???: |verbs," .. stmt[1] .. "||color," .. stmt[2] .. "||nouns," .. stmt[3] .. "||number," .. stmt[4] .. "|")
	end
end

function World:addObject(object)
	table.insert(self.objects, object)
end

function World:addGlowstick(x, y)
	local gs = Glowstick(x, y)
	gs:addToTilemap(self.tilemap)
	table.insert(self.glowsticks, gs)
end

function World:checkForComplete()
	if #self.objectives == 0 then
		self:completion()
	end
end

function World:completion()
	local mr = self.rooms[self.masterRoom]
	self.tilemap:setTile(mr.x + math.floor(mr.w / 2), mr.y + math.floor(mr.h / 2), createTile(TileType.Stairs))
end

function World:complete()
	self.completed = true
end

function World:update(dt)
	self.player:update(dt, self)
	self.timer = self.timer - dt
	local x, y = spriteCurrTile(self.player):split()
	self.tilemap.lights[self.playerLightId].x = x
	self.tilemap.lights[self.playerLightId].y = y

	self.closestObject = nil
	local c = TileSize
	for _, o in pairs(self.objects) do
		o:update(dt)

		local rect = o:getRect()
		local dist = (Vec2(rect.x, rect.y) - self.player.pos):length()
		if dist < c then
			c = dist
			self.closestObject = o
		end
	end

	local actionDown = love.keyboard.isDown("space", " ")
	if self.closestObject ~= nil and actionDown and not self.lastActionDown then
		self.closestObject:onInteract(self, self.console)
	end
	self.lastActionDown = actionDown

	self.tilemap:calculateLight(self.player.pos.x, self.player.pos.y)
end

function World:draw()
	self.tilemap:draw(self.player.pos.x, self.player.pos.y)
	for _, o in pairs(self.objects) do
		o:draw()
	end

	if self.closestObject ~= nil then
		love.graphics.setColor(255, 255, 0, 100)
		love.graphics.rectangle("fill", self.closestObject:getRect():split())
	end

	self.tilemap:drawLighting(self.player.pos.x, self.player.pos.y)

	for _, gs in pairs(self.glowsticks) do
		gs:draw()
	end
	self.player:draw()
end

Button = class {}
function Button:new(x, y, rotation, color)
	self.x = x
	self.y = y
	self.w = 32
	self.h = 32
	self.rot = rotation or 0
	self.color = color or 1

	self.pressedTimer = 0
	self.pressed = false
end

function Button:onInteract(world, console)
	if self.pressed then return end
	self.pressed = true
	self.pressedTimer = 0.5
	console:addLine("You pushed the button.")

	local needed = false
	local index = -1
	for i, o in ipairs(world.objectives) do
		if o[1] == 1 and o[3] == 1 and o[2] == self.color and o[4] >= 1 then
			needed = true
			index = i
		end
	end

	if needed then
		if world.objectives[index][4] > 1 then
			world.objectives[index][4] = world.objectives[index][4] - 1
		else
			table.remove(world.objectives, index)
			world.left = world.left + 1
			console:addLine("You heard a click.")

			world:checkForComplete()
		end
	else
		world.timer = world.timer - 10
	end
end

function Button:getRect()
	return Rectangle(self.x + 4, self.y + 4, 24, 24)
end

function Button:update(dt)
	if self.pressed then
		self.pressedTimer = self.pressedTimer - dt

		if self.pressedTimer <= 0 then
			self.pressed = false
		end
	end
end

function Button:draw()
	love.graphics.setColor(colors[self.color])
	if self.pressed then
		love.graphics.draw(TEXTURES.button_in, self.x + self.w / 2, self.y + self.h / 2, self.rot, 1, 1, self.w / 2, self.h / 2)
	else
		love.graphics.draw(TEXTURES.button_out, self.x + self.w / 2, self.y + self.h / 2, self.rot, 1, 1, self.w / 2, self.h / 2)
	end
end

Lever = class {}
function Lever:new(x, y, rotation, color)
	self.x = x
	self.y = y
	self.w = 32
	self.h = 32
	self.rot = rotation or 0
	self.color = color or 1

	self.flipped = false
end

function Lever:onInteract(world, console)
	self.flipped = not self.flipped

	console:addLine("You pulled the lever.")

	local needed = false
	local index = -1
	for i, o in ipairs(world.objectives) do
		if o[1] == 2 and o[3] == 2 and o[2] == self.color and o[4] >= 1 then
			needed = true
			index = i
		end
	end

	if needed then
		if world.objectives[index][4] > 1 then
			world.objectives[index][4] = world.objectives[index][4] - 1
		else
			table.remove(world.objectives, index)
			world.left = world.left + 1
			console:addLine("You heard a click.")

			world:checkForComplete()
		end
	else
		world.timer = world.timer - 10
	end
end

function Lever:getRect()
	return Rectangle(self.x + 4, self.y + 4, 24, 24)
end

function Lever:update(dt)
end

function Lever:draw()
	love.graphics.setColor(colors[self.color])
	if self.flipped then
		love.graphics.draw(TEXTURES.lever_up, self.x + self.w / 2, self.y + self.h / 2, self.rot, 1, 1, self.w / 2, self.h / 2)
	else
		love.graphics.draw(TEXTURES.lever_down, self.x + self.w / 2, self.y + self.h / 2, self.rot, 1, 1, self.w / 2, self.h / 2)
	end
end


TileSize = 32;

TileType = {
	Empty = 0;
	Floor = 1;
	Wall = 3;
	Door = 4;
	Stairs = 5;
	Button = 6;
	Blockade = 7;
}

Tiles = {
	[TileType.Empty] = {
		color = { 0, 0, 0 }
	};
	[TileType.Floor] = {
		texture = "floor",
		color = { 0, 150, 150 }
	};
	[TileType.Wall] = {
		--texture = "wall.png",
		color = { 255, 0, 0 }
	};
	[TileType.Door] = {
		color = { 0, 0, 255 }	
	};
	[TileType.Stairs] = {
		texture = "stairs";	
		color = { 0, 255, 0 }
	};
	[TileType.Blockade] = {
		color = { 60, 60, 60 }
	}
}

function createTile(id, ...) 
	local args = { ... }

	if id == TileType.Wall then
		return {
			id = id,	
			edge = args[1];
			light = 1.0
		}
	elseif id == TileType.Floor then
		return {
			id = id,
			light = 1.0
		}
	else
		return { id = id, light = 1.0 }
	end
end

function computeWall(tilemap, x, y)
	allLocal()

	texture = ""
	rot = 0.0

	up = tilemap:getTile(x, y - 1, { id = 0 }).id
	dn = tilemap:getTile(x, y + 1, { id = 0 }).id
	lf = tilemap:getTile(x - 1, y, { id = 0 }).id
	rt = tilemap:getTile(x + 1, y, { id = 0 }).id

	floor_up = up == TileType.Floor
	floor_dn = dn == TileType.Floor
	floor_lf = lf == TileType.Floor
	floor_rt = rt == TileType.Floor

	empty_up = up == TileType.Empty
	empty_dn = dn == TileType.Empty
	empty_lf = lf == TileType.Empty
	empty_rt = rt == TileType.Empty

	wall_up = up == TileType.Wall
	wall_dn = dn == TileType.Wall
	wall_lf = lf == TileType.Wall
	wall_rt = rt == TileType.Wall

	if wall_up and wall_dn then
		if floor_lf then
			texture = "straight_wall"
			rot = 180.0
		else
			texture = "straight_wall"
			rot = 0.0
		end
	elseif wall_rt and wall_lf then
		if floor_up then
			texture = "straight_wall"
			rot = 270.0
		else
			texture = "straight_wall"
			rot = 90.0
		end
	elseif wall_up and wall_lf then
		if floor_rt and floor_dn then
			texture = "exclosed_corner"
			rot = 90.0
		elseif empty_rt and empty_dn then
			texture = "inclosed_corner"
			rot = 270.0
		end
	elseif wall_up and wall_rt then
		if floor_dn and floor_lf then
			texture = "exclosed_corner"
			rot = 180.0
		elseif empty_dn and empty_lf then
			texture = "inclosed_corner"
			rot = 0.0
		end
	elseif wall_rt and wall_dn then
		if floor_lf and floor_up then
			texture = "exclosed_corner"
			rot = 270.0
		elseif empty_lf and empty_up then
			texture = "inclosed_corner"
			rot = 90.0
		end
	elseif wall_dn and wall_lf then
		if floor_up and floor_rt then
			texture = "exclosed_corner"
			rot = 0.0
		elseif empty_up and empty_rt then
			texture = "inclosed_corner"
			rot = 180.0
		end
	end

	tile = {
		id = TileType.Wall;
		texture = texture;
		rotation = rot * math.pi / 180
	}

	tilemap:setTile(x, y, tile)
end

function getTileRect(tilemap, x, y)
	allLocal()
	tile = tilemap:getTile(x, y, { id = -1 })

	if tile.id == TileType.Wall then
		up = tilemap:getTile(x, y - 1, { id = 0 }).id
		dn = tilemap:getTile(x, y + 1, { id = 0 }).id
		lf = tilemap:getTile(x - 1, y, { id = 0 }).id
		rt = tilemap:getTile(x + 1, y, { id = 0 }).id

		floor_up = up == TileType.Floor
		floor_dn = dn == TileType.Floor
		floor_lf = lf == TileType.Floor
		floor_rt = rt == TileType.Floor

		empty_up = up == TileType.Empty
		empty_dn = dn == TileType.Empty
		empty_lf = lf == TileType.Empty
		empty_rt = rt == TileType.Empty

		wall_up = up == TileType.Wall
		wall_dn = dn == TileType.Wall
		wall_lf = lf == TileType.Wall
		wall_rt = rt == TileType.Wall

		if wall_up and wall_dn then
			if floor_lf then
				return { { Rectangle(x * TileSize + TileSize / 2, y * TileSize, TileSize / 2, TileSize), TileType.Wall } }
			else
				return { { Rectangle(x * TileSize, y * TileSize, TileSize / 2, TileSize), TileType.Wall } }
			end
		elseif wall_rt and wall_lf then
			if floor_up then
				return { { Rectangle(x * TileSize, y * TileSize + TileSize / 2, TileSize, TileSize / 2), TileType.Wall } }
			else
				return { { Rectangle(x * TileSize, y * TileSize, TileSize, TileSize / 2), TileType.Wall } }
			end
		elseif wall_up and wall_lf then
			if floor_rt and floor_dn then
				return { { Rectangle(x * TileSize, y * TileSize, TileSize / 2, TileSize / 2 ), TileType.Wall } } 
			elseif empty_rt and empty_dn then
				return { { Rectangle(x * TileSize + TileSize / 2, y * TileSize, TileSize / 2, TileSize), TileType.Wall } 
					   , { Rectangle(x * TileSize, y * TileSize + TileSize / 2, TileSize, TileSize / 2), TileType.Wall } }
			end
		elseif wall_up and wall_rt then
			if floor_dn and floor_lf then
				return { { Rectangle(x * TileSize + TileSize / 2, y * TileSize, TileSize / 2, TileSize / 2 ), TileType.Wall } }
			elseif empty_dn and empty_lf then
				return { { Rectangle(x * TileSize, y * TileSize, TileSize / 2, TileSize), TileType.Wall } 
					   , { Rectangle(x * TileSize, y * TileSize + TileSize / 2, TileSize, TileSize / 2), TileType.Wall } }
			end
		elseif wall_rt and wall_dn then
			if floor_lf and floor_up then
				return { { Rectangle(x * TileSize + TileSize / 2, y * TileSize + TileSize / 2, TileSize / 2, TileSize / 2 ), TileType.Wall } }
			elseif empty_lf and empty_up then
				return { { Rectangle(x * TileSize, y * TileSize, TileSize, TileSize / 2), TileType.Wall } 
					   , { Rectangle(x * TileSize, y * TileSize, TileSize / 2, TileSize), TileType.Wall } }
			end
		elseif wall_dn and wall_lf then
			if floor_up and floor_rt then
				return { { Rectangle(x * TileSize, y * TileSize + TileSize / 2, TileSize / 2, TileSize / 2 ), TileType.Wall } }
			elseif empty_up and empty_rt then
				return { { Rectangle(x * TileSize, y * TileSize, TileSize, TileSize / 2), TileType.Wall } 
					   , { Rectangle(x * TileSize + TileSize / 2, y * TileSize, TileSize / 2, TileSize), TileType.Wall } }
			end
		end

		return nil
	elseif tile.id == TileType.Stairs then
		return { { Rectangle(x * TileSize, y * TileSize, TileSize, TileSize ), TileType.Stairs } }
	end

	return nil
end


Tilemap = class({})
function Tilemap:new(w, h)
	self.width = w
	self.height = h
	self.tiles = {}
	self.lights = {}

	for i = 1, (w * h) do
		table.insert(self.tiles, createTile(TileType.Floor))
	end
end

function Tilemap:addLight(x, y, rad, int)
	int = int or 1.0
	local id = math.floor(love.math.random(0, 10000000))
	self.lights[id] = {
		x = x,
		y = y,
		radius = rad,	
		intensity = int
	}

	return id
end

function Tilemap:calculateLight(px, py)
	px = math.floor(px / TileSize)
	py = math.floor(py / TileSize)
	local tx1 = math.max(px - 20, 0)
	local ty1 = math.max(py - 10, 0)
	local tx2 = math.min(px + 10, self.width - 1)
	local ty2 = math.min(py + 10, self.height - 1)

	for i = 1, self.width * self.height do
		self.tiles[i].light = 0.0
	end

	for y = ty1, ty2 do
		for x = tx1, tx2 do
			local l = 0.0

			for _, light in pairs(self.lights) do
				local dx = light.x - x
				local dy = light.y - y
				local dist = math.sqrt(dx * dx + dy * dy)
				local ratio = dist / light.radius
				ratio = math.max(1.0 - ratio * ratio, 0) * light.intensity

				l = math.sqrt(l * l + ratio * ratio)
				l = math.min(l, 1.0)
			end

			self:getTile(x, y).light = l
		end
	end
end

function Tilemap:calculateWalls()
	for y = 0, self.height - 1 do
		for x = 0, self.width - 1 do
			if self:getTile(x, y).id == TileType.Wall then
				computeWall(self, x, y)
			end
		end
	end	
end

function Tilemap:getRects(x, y, rad)
	local rects = {}

	local tx1 = math.max(x - rad, 0)
	local tx2 = math.min(x + rad, self.width - 1)
	local ty1 = math.max(y - rad, 0)
	local ty2 = math.min(y + rad, self.height - 1)

	for yy = ty1, ty2 do
		for xx = tx1, tx2 do
			local t = self:getTile(xx, yy)
			local r = getTileRect(self, xx, yy)
			if r ~= nil then
				table.insert(rects, r)
			end
		end
	end	

	return rects
end

function Tilemap:getTile(x, y, default)
	default = default or nil
	if x < 0 or y < 0 or x >= self.width or y >= self.height then return default end
	return self.tiles[x + y * self.width + 1]
end

function Tilemap:setTile(x, y, t)
	if x < 0 or y < 0 or x >= self.width or y >= self.height then return end
	self.tiles[x + y * self.width + 1] = t
end

function Tilemap:draw(px, py)
	px = math.floor(px / TileSize)
	py = math.floor(py / TileSize)
	local tx1 = math.max(px - 20, 0)
	local ty1 = math.max(py - 10, 0)
	local tx2 = math.min(px + 11, self.width - 1)
	local ty2 = math.min(py + 11, self.height - 1)

	for y = ty1, ty2 do
		for x = tx1, tx2 do
			local t = self:getTile(x, y)
			local color = Tiles[t.id].color
			local texture = t.texture or Tiles[t.id].texture

			if TEXTURES[texture] ~= nil then
				rotation = t.rotation or 0.0

				if t.id == TileType.Wall or t.id == TileType.Stairs then
					love.graphics.setColor(255, 255, 255)
					love.graphics.draw(TEXTURES["floor"], x * TileSize, y * TileSize)
				end

				love.graphics.setColor(255, 255, 255)
				love.graphics.draw(TEXTURES[texture], x * TileSize + TileSize / 2, y * TileSize + TileSize / 2, rotation, 1, 1, TileSize / 2, TileSize / 2)
			else
				love.graphics.setColor(color)
				love.graphics.rectangle("fill", x * TileSize, y * TileSize, TileSize, TileSize)
			end
		end
	end
end

function Tilemap:drawLighting(px, py)
	px = math.floor(px / TileSize)
	py = math.floor(py / TileSize)
	local tx1 = math.max(px - 20, 0)
	local ty1 = math.max(py - 10, 0)
	local tx2 = math.min(px + 11, self.width - 1)
	local ty2 = math.min(py + 11, self.height - 1)

	for y = ty1, ty2 do
		for x = tx1, tx2 do
			local t = self:getTile(x, y)
			local light = t.light ~= nil and t.light or 1.0
			love.graphics.setColor(0, 0, 0, 255 * (1.0 - light))
			love.graphics.rectangle("fill", x * TileSize, y * TileSize, TileSize, TileSize)
		end
	end
end


DungeonGen = class {}
function DungeonGen:new(world, numRooms)
	self.world = world
	self.tilemap = world.tilemap
	self.w = self.tilemap.width
	self.h = self.tilemap.height
	self.numRooms = numRooms

	self.rooms = {}
end

function DungeonGen:generateRoom()
	local size = math.floor(1 + love.math.random(1, 3)) * 4 + 1
	local x = math.floor(love.math.random(2, self.w - size - 2) / 4) * 4 + 1
	local y = math.floor(love.math.random(2, self.h - size - 2) / 4) * 4 + 1
	return Rectangle(x, y, size, size)
end

function DungeonGen:removeWall(pos)
	self.tilemap:setTile(pos.x, pos.y, createTile(TileType.Floor))
end

function DungeonGen:placeDoor(room, unusedSides)
	local roomSide = {
		{ 0, 0, 0, 1, 0, -4, 0, -3 }; --Up
		{ 0, 1, 0, 1, 0,  4, 0,  3 }; --Down
		{ 0, 0, 1, 0, -4, 0, -3, 0 }; --Left
		{ 1, 0, 1, 0,  4, 0,  3, 0 }; --Right
	}

	local done = false
	local side = -10
	local tries = 0
	local tx, ty
	repeat
		tries = tries + 1
		if tries >= 50 then return -1 * unusedSides[1] end
		side = math.floor(love.math.random(1, 4))

		local works = false
		for _, v in pairs(unusedSides) do
			if side == v then works = true end
		end

		if works then
			local s = roomSide[side]
			local e = math.floor(love.math.random(1, room.w - 2))

			tx = room.x + (room.w - 1) * s[1] + e * s[4] + s[5]
			ty = room.y + (room.h - 1) * s[2] + e * s[3] + s[6]
			local t = self.tilemap:getTile(tx, ty)

			if t ~= nil and t.id == TileType.Floor then
				tx = room.x + (room.w - 1) * s[1] + e * s[4] + s[7]
				ty = room.y + (room.h - 1) * s[2] + e * s[3] + s[8]
				self.tilemap:setTile(room.x + (room.w - 1) * s[1] + e * s[4] + s[7] / 3
									,room.y + (room.h - 1) * s[2] + e * s[3] + s[8] / 3, createTile(TileType.Floor))
				self.tilemap:setTile(room.x + (room.w - 1) * s[1] + e * s[4] + 2 * s[7] / 3
									,room.y + (room.h - 1) * s[2] + e * s[3] + 2 * s[8] / 3, createTile(TileType.Floor))
				self.tilemap:setTile(room.x + (room.w - 1) * s[1] + e * s[4] + s[7]
									,room.y + (room.h - 1) * s[2] + e * s[3] + s[8], createTile(TileType.Floor))
				done = true
			end

			if t == nil or t.id == TileType.Empty then return -1 * side end
		end
	until done

	return side, { tx, ty }
end

function DungeonGen:generate(player)
	allLocal()
	-- Fill every tile with a wall
	for y = 0, self.h - 1 do
		for x = 0, self.w - 1 do
			self.tilemap:setTile(x, y, createTile(TileType.Wall))
		end
	end

	--Generate all the rooms
	done = false
	repeat 
		self.rooms = {}
		roomsLeft = self.numRooms
		tries = 0

		done = true
		repeat
			tries = tries + 1
			if tries < 100 then
				local room = self:generateRoom()

				local works = true
				for _, r in pairs(self.rooms) do
					if room:intersects(r) then
						works = false
						break
					end
				end

				if works then
					table.insert(self.rooms, room)
					roomsLeft = roomsLeft - 1
				end
			else
				done = false
				break
			end
		until roomsLeft == 0
	until done

	-- "Carve" the rooms into the tilemap and place lights because why not
	for _, room in pairs(self.rooms) do
		room.w = room.w - 4
		room.h = room.h - 4
		for y = 0, room.h - 1 do
			for x = 0, room.w - 1 do
				self.tilemap:setTile(room.x + x, room.y + y, createTile(TileType.Floor, "room"))
			end
		end

		local hsize = math.floor(room.w / 2)
		self.tilemap:addLight(room.x + hsize, room.y + hsize, hsize + 2, 0.5)
	end

	--Find a place to start the maze
	start = Vec2(0, 0)

	done = false
	repeat
		start.x = math.floor(love.math.random(0, self.w - 1) / 4) * 4 + 1
		start.y = math.floor(love.math.random(0, self.h - 1) / 4) * 4 + 1

		done = true
		for _, r in pairs(self.rooms) do
			if r:intersects(Rectangle(start.x, start.y, 1, 1)) then
				done = false
			end
		end
	until done

	Directions = {
		Up = Vec2(0, -1);
		Down = Vec2(0, 1);
		Left = Vec2(-1, 0);
		Right = Vec2(1, 0);
	}

	cellStack = Stack()
	cellStack:push(start)

	lastDir = nil
	lastCount = 0

	--Generate the maze
	cell = nil
	while not cellStack:isEmpty() do
		cell = cellStack:top()

		availableDirections = {}

		for _, dir in pairs(Directions) do
			local dest = cell + dir * 4
			local tile = self.tilemap:getTile(dest.x, dest.y)
			if tile ~= nil then
				if tile.id == TileType.Wall then
					table.insert(availableDirections, dir)
				end
			end
		end

		if #availableDirections ~= 0 then
			local dir = nil

			local hasLast = false			
			for _, d in pairs(availableDirections) do
				if lastDir == d then
					hasLast = true
					break
				end
			end

			if hasLast and love.math.random(1, 100) >= 70 then
				dir = lastDir
			else
				dir = availableDirections[love.math.random(1, #availableDirections)]
			end

			self:removeWall(cell + dir)
			self:removeWall(cell + dir * 2)
			self:removeWall(cell + dir * 3)
			self:removeWall(cell + dir * 4)

			cellStack:push(cell + dir * 4)
			lastDir = dir
		else
			cellStack:pop()

			lastDir = nil
		end
	end

	--Place the doors on the rooms
	masterRoom = 1
	doorCoords = { -1, -1 }

	for i, room in ipairs(self.rooms) do	
		local numDoors = i == masterRoom and 1 or 2
		unusedSides = {1, 2, 3, 4}

		for i = 1, numDoors do
			local side = -10
			local tries = 0
			local coords
			repeat
				tries = tries + 1
				if tries > 10 then
					self.rooms = {}
					print "Recursively calling generate"
					self:generate(player)
					return
				end
				side, coords = self:placeDoor(room, unusedSides)
			until side > 0

			if i == masterRoom then
				doorCoords = coords
			end

			for i, v in ipairs(unusedSides) do
				if v == side then
					unusedSides[i] = nil
				end
			end

			if #unusedSides == 0 then
				break
			end
		end
	end

	--Delete the dead ends
	done = false
	repeat
		done = true

		for y = 1, self.h - 2 do
			for x = 1, self.w - 2 do
				if self.tilemap:getTile(x, y).id == TileType.Floor then
					local exits = 0
					for _, dir in pairs(Directions) do
						if self.tilemap:getTile(x + dir.x, y + dir.y).id ~= TileType.Wall then
							exits = exits + 1
						end
					end

					if exits == 1 then
						done = false
						self.tilemap:setTile(x, y, createTile(TileType.Wall))
					end
				end
			end
		end
	until done

	Directions.DOWN_RIGHT = Vec2(1, 1)
	Directions.DOWN_LEFT = Vec2(-1, 1)
	Directions.UP_RIGHT = Vec2(1, -1)
	Directions.UP_LEFT = Vec2(-1, -1)

	for y = 0, self.h - 1 do
		for x = 0, self.w - 1 do
			local t = self.tilemap:getTile(x, y)
			if t.id == TileType.Wall then
				local unneeded = true

				for _, dir in pairs(Directions) do
					local t2 = self.tilemap:getTile(x + dir.x, y + dir.y)
					if t2 ~= nil then
						if t2.id == TileType.Floor then
							unneeded = false
							break
						end
					end
				end

				if unneeded then
					self.tilemap:setTile(x, y, createTile(TileType.Empty))
				end
			end
		end
	end

	spawnIndex = masterRoom
	spawnRoom = nil
	repeat
		spawnIndex = love.math.random(1, #self.rooms)
		spawnRoom = self.rooms[spawnIndex]
	until spawnIndex ~= masterRoom

	player.pos.x = (spawnRoom.x + math.floor(spawnRoom.w / 2)) * TileSize
	player.pos.y = (spawnRoom.y + math.floor(spawnRoom.h / 2)) * TileSize


	self.world.rooms = self.rooms
	self.world.masterRoom = masterRoom
	self.world.doorCoord = doorCoords

end

Glowstick = class {}
function Glowstick:new(x, y)
	self.tx = x
	self.ty = y
	self.x = x * TileSize + math.floor(love.math.random(4, 28))
	self.y = y * TileSize + math.floor(love.math.random(4, 28))
	self.lightId = -1
end

function Glowstick:addToTilemap(tilemap)
	self.lightId = tilemap:addLight(self.tx, self.ty, 4, 0.8)
end

function Glowstick:draw()
	love.graphics.setColor(255, 255, 255)
	love.graphics.draw(TEXTURES.glowstick, self.x, self.y, 1, 1)
end