function class(c)
	c = setmetatable(c, {
		-- This is called when we try to make a new instance of the class
		__call = function(_, ...)
			-- We get "two" parameters: the table this metatable is controlling, aka c
			-- and a list of parameters that were passed in to the constructor

			-- We create an empty object that will store all of our instance variables
			local obj = {}

			local mt = { __index = c }

			-- This allows to define special functions like __add, and __sub
			for k, v in pairs(c) do
				if k:sub(0, 2) == "__" then
					mt[k] = v
				end
			end

			-- This is important, we tell the obj(ect) to look in the table c if it cannot find
			-- something in itself. This allows many instance objects to "point" to the main
			-- class table if they don't have something.
			setmetatable(obj, mt)

			-- If this class has a constructor, we initalize the object by calling the constructor	
			if c.new then
				c.new(obj, ...)
			end


			-- We return the object we created
			return obj
		end
	})

	return c
end

-- Kinda complicated lua-ness going on
-- Simply put all you have to do is put this at the top of a function and every variable
-- you declare will be "local"
function allLocal()
	local vars = {}
	local env = setmetatable({}, {
		__index = function(t, k)
			local val = vars[k]
			if val == nil then val = _G[k] end
			return val
		end;

		__newindex = function(t, k, v)
			vars[k] = v	
		end;
	})

	setfenv(2, env)
end

--Utility Vector2 class
--Used for positions, rectangles, and other math things
Vec2 = class {}

function Vec2:new(x, y)
	x = x or 0
	y = y or 0

	self.x = x
	self.y = y
end

function Vec2:__add(other)
	return Vec2(self.x + other.x, self.y + other.y)
end

function Vec2:__sub(other)
	return Vec2(self.x - other.x, self.y - other.y)
end

function Vec2:__mul(scalar)
	return Vec2(self.x * scalar, self.y * scalar)
end

function Vec2:__eq(other)
	return self.x == other.x and self.y == other.y
end

function Vec2:__len()
	return math.sqrt(self:squareMagnitude())
end

function Vec2:length()
	return math.sqrt(self:squareMagnitude())
end

function Vec2:squareMagnitude()
	return self.x * self.x + self.y * self.y
end

function Vec2:dot(other)
	return self.x * other.x + self.y * other.y
end

function Vec2:normalized()
	if self.x == 0 and self.y == 0 then return Vec2(0, 0) end
	local l = math.sqrt(self.x * self.x + self.y * self.y)
	return Vec2(self.x / l, self.y / l)
end

function Vec2:split()
	return self.x, self.y
end


Rectangle = class {}

function Rectangle:new(x, y, w, h)
	self.x = x	
	self.y = y	
	self.w = w	
	self.h = h	
end

function Rectangle:intersects(other)
	if self.x < other.x + other.w
		and self.x + self.w > other.x
		and self.y < other.y + other.h
		and self.y + self.h > other.y
		then
		return true
	else
		return false
	end
end

function Rectangle:contains(x, y)
	return x > self.x and x <= self.x + self.w and
		y > self.y and y <= self.y + self.h
end

function Rectangle:split()
	return self.x, self.y, self.w, self.h
end

function Rectangle:__add(vec)
	return Rectangle(vec.x + self.x, vec.y + self.y, self.w, self.h)	
end

function Rectangle:__sub(vec)
	return Rectangle(self.x - vec.x, self.y - vec.y, self.w, self.h)	
end

function Rectangle:__mul(scalar)
	return Rectangle(self.x * scalar, self.y * scalar, self.w * scalar, self.h * scalar)
end

Stack = class {}

function Stack:new()
	self.data = {}
end

function Stack:push(thing)
	table.insert(self.data, thing)
end

function Stack:pop()
	local ret = self.data[#self.data]
	table.remove(self.data, #self.data)
	return ret
end

function Stack:top()
	return self.data[#self.data]
end

function Stack:isEmpty()
	return #self.data == 0
end

function isLeftButtonDown()
	local buttonDown = false
	local major, minor = love.getVersion()
	if minor == 9 then
		buttonDown = love.mouse.isDown("l")
	else
		buttonDown = love.mouse.isDown(1)
	end
	return buttonDown
end