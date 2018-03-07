Console = class {}

function Console:new(world)
	self.world = world
	self.lines = { }
	self.scroll = 0

	self.upArrow = {
		rectangle = Rectangle(350, 70 + 540 - 197, 27, 26)
	}
	self.downArrow = {
		rectangle = Rectangle(350, 115 + 540 - 197, 27, 26)	
	}
end

function Console:addLine(msg)
	table.insert(self.lines, msg)
	self.scroll = self:getLineCount() * 24 - 5 * 24
end

function Console:update(dt)
	local button = isLeftButtonDown()
	if button and not self.lastButton then
		local x = love.mouse.getX()
		local y = love.mouse.getY()
		if self.upArrow.rectangle:contains(x, y) then
			self.scroll = self.scroll - 24
			if self.scroll < 0 then
				self.scroll = 0
			end
		end
		if self.downArrow.rectangle:contains(x, y) then
			self.scroll = self.scroll + 24
			if self.scroll >= self:getLineCount() * 24 then
				self.scroll = self:getLineCount() * 24 - 24
			end
		end
	end
	self.lastButton = button
end

function Console:getLineCount()
	local font = love.graphics.getFont()

	local lineCount = 0
	for i=1, #self.lines do
		local l = string.gsub(self.lines[i], "|(%a+), ?(%d+)|", " ")
		local width = font:getWidth(l)
		lineCount = lineCount + math.floor(width / 485)
		lineCount = lineCount + 1
	end

	return lineCount
end

function Console:draw()
	local y = 540 - 197

	love.graphics.setColor(255, 255, 255)
	love.graphics.draw(TEXTURES.console, 0, y)

	love.graphics.draw(TEXTURES.Arrow_up, self.upArrow.rectangle.x, self.upArrow.rectangle.y)
	love.graphics.draw(TEXTURES.Arrow_down, self.downArrow.rectangle.x, self.downArrow.rectangle.y)

	love.graphics.setColor(210, 210, 0)
	local fmt = string.format("%5.2f", self.world.timer)
	love.graphics.print(fmt, 127, 462, 0, 1.5)
	love.graphics.print(string.format("%6s", self.world.left .. "/" .. self.world.generated), 126, 407, 0, 1.5)
	
	love.graphics.setScissor(399, y + 45, 485, 132)	
	love.graphics.setColor(210, 210, 0)

	local font = love.graphics.getFont()
	local lineCount = 0
	for i=1, #self.lines do
		local l = string.gsub(self.lines[i], "|(%a+), ?(%d+)|", " ")
		love.graphics.printf(l, 410, y + 43 + lineCount * 24 - self.scroll, 485, "left")

		local symNum = 0
		for sym, index in string.gmatch(self.lines[i], "|(%a+), ?(%d+)|") do
			love.graphics.draw(lang.symbols[sym][tonumber(index)], 410 + 56 + 17 * symNum, y + 43 + lineCount * 24 - self.scroll, 0, 1.2)
			symNum = symNum + 1
		end

		local width = font:getWidth(l)

		lineCount = lineCount + math.floor(width / 485)
		lineCount = lineCount + 1
	end
	love.graphics.setScissor()
end