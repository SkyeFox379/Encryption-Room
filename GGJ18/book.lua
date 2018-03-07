Book = class{}

function Book:new()
	self.CurrentPage = 1
	self.LastPage = 5

	self.nextArrow = {
		show = true;
		rectangle = Rectangle(258, 280, 20, 20)	
	}
	self.prevArrow = {
		show = false;
		rectangle = Rectangle(210, 280, 20, 20)	
	}

	self.paintRect = Rectangle(225, 30, 16, 16)
	self.eraseRect = Rectangle(245, 30, 16, 16)
	self.magnifyRect = Rectangle(265, 30, 16, 16)

	self.selectedTool = 0
	self.canvasRect = Rectangle(45, 45, 230, 230)
	self.canvasPages = {}
	for i = 1, self.LastPage do
		local canvas = love.graphics.newCanvas()
		table.insert(self.canvasPages, canvas)
	end

	self.state = {
		id = 0,
		scale = 0.0	
	};
end

function Book:getRect(rect)
	return (rect - Vec2(45, 45)) * (self.state.scale + 1.0) + Vec2(45, 45)
end

function Book:NextPage()
	self.CurrentPage = self.CurrentPage + 1
	if(self.CurrentPage == self.LastPage) then
		--remove the arrow pointing right
		self.nextArrow.show = false
	end
	if(self.CurrentPage ~= 1) then
		self.prevArrow.show = true
	end
end


function Book:PrevPage()
	self.CurrentPage = self.CurrentPage - 1
	if(self.CurrentPage == 1) then
		--remove the arrow pointing right
		self.prevArrow.show = false
	end
	if(self.CurrentPage ~= self.LastPage) then
		self.nextArrow.show = true
	end
end


function Book:update(dt)
	local buttonDown = isLeftButtonDown()

	local _, minor = love.getVersion()

	local x = love.mouse.getX()
	local y = love.mouse.getY()
	--local y = (love.mouse.getY() - 45) / (self.state.scale + 1.0) - 45
	if buttonDown and not self.lastButtonDown then
		if(self:getRect(self.nextArrow.rectangle):contains(x, y)) then
			if(self.nextArrow.show) then
				self:NextPage()
			end
		end
		if(self:getRect(self.prevArrow.rectangle):contains(x, y)) then
			if(self.prevArrow.show) then
				self:PrevPage()
			end
		end

		if self:getRect(self.paintRect):contains(x, y) then
			self.selectedTool = 0
		end
		if self:getRect(self.eraseRect):contains(x, y) then
			self.selectedTool = 1
		end
	end

	local tx = (x - 45) / (self.state.scale + 1.0) + 45
	local ty = (y - 45) / (self.state.scale + 1.0) + 45

	local cRect = self:getRect(self.canvasRect)
	if buttonDown and cRect:contains(x, y) then
		love.graphics.setCanvas(self.canvasPages[self.CurrentPage])
		if self.selectedTool == 0 then
			love.graphics.setColor(0, 0, 0, 255)
			love.graphics.setLineWidth(1)
			love.graphics.line(tx - cRect.x, ty - cRect.y
							 , self.lastX - cRect.x, self.lastY - cRect.y)
		else
			local imagedata = nil
			if minor == 10 then
				imagedata = self.canvasPages[self.CurrentPage]:newImageData()
			else
				imagedata = self.canvasPages[self.CurrentPage]:getImageData()
			end

			local tx1 = math.max(0, tx - cRect.x - 10)
			local ty1 = math.max(0, ty - cRect.y - 10)
			local tx2 = math.min(tx - cRect.x + 10, cRect.w)
			local ty2 = math.min(ty - cRect.y + 10, cRect.h)

			for xx = tx1, tx2 do
				for yy = ty1, ty2 do
					imagedata:setPixel(xx, yy, 0, 0, 0, 0)
				end
			end

			self.canvasPages[self.CurrentPage] = love.graphics.newCanvas()
			love.graphics.setCanvas(self.canvasPages[self.CurrentPage])
			love.graphics.draw(love.graphics.newImage(imagedata), 0, 0)
			love.graphics.setCanvas()
		end

		love.graphics.setCanvas()
	end

	if (buttonDown and self:getRect(self.magnifyRect):contains(x, y)) or love.keyboard.isDown "tab" then
		if self.state.id == 0 then
			self.state.id = 1
		elseif self.state.id == 2 then
			self.state.id = 3
		end
	end

	if self.state.id == 1 then
		self.state.scale = self.state.scale + 2.0 * dt
		if self.state.scale >= 0.85 then
			self.state.id = 2
		end
	elseif self.state.id == 3 then
		self.state.scale = self.state.scale - 2.0 * dt
		if self.state.scale <= 0.0 then
			self.state.scale = 0.0
			self.state.id = 0
		end
	end

	self.lastX = tx
	self.lastY = ty
	self.lastButtonDown = buttonDown
end


function Book:draw()
	love.graphics.push()
	love.graphics.translate(45, 45)
	love.graphics.scale(self.state.scale + 1.0, self.state.scale + 1.0)
	love.graphics.translate(-45, -45)
	love.graphics.setColor(255, 255, 255)
	love.graphics.draw(TEXTURES.book, 0, 5)

	love.graphics.draw(TEXTURES["book_page" .. self.CurrentPage], 40, 30)

	love.graphics.draw(self.canvasPages[self.CurrentPage], self.canvasRect.x, self.canvasRect.y)

	love.graphics.setColor(100, 100, 0, 150)
	love.graphics.rectangle("fill", self.paintRect.x + self.selectedTool * 20, self.paintRect.y, 16, 16, 4, 4, 20)

	love.graphics.setColor(255, 255, 255)
	love.graphics.draw(TEXTURES.book_pencil, self.paintRect.x, self.paintRect.y)
	love.graphics.draw(TEXTURES.book_eraser, self.eraseRect.x, self.eraseRect.y)
	love.graphics.draw(TEXTURES.book_magnifier, self.magnifyRect.x, self.magnifyRect.y)

	if self.nextArrow.show then
		love.graphics.draw(TEXTURES.prevArrow, 279, 280, 0, -1, 1)
	end

	if self.prevArrow.show then
		love.graphics.draw(TEXTURES.prevArrow, 208, 280)
	end

	love.graphics.pop()
end
