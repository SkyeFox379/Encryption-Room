require "utils"
require "sprites"
require "world"
require "book"
require "console"
require "symbols"

TEXTURES = {}

PauseState = class {}
function PauseState:new()
	self.parent = nil
	self.lastPauseButton = true
end

function PauseState:nowActive(parent)
	self.parent = parent
end

function PauseState:update(dt)
	if self.parent then
		--self.parent:update(dt)
	end
	local pauseButton = love.keyboard.isDown "escape"

	if not self.lastPauseButton and pauseButton then
		popState()
	end

	self.lastPauseButton = pauseButton
end

function PauseState:draw()
	if self.parent then
		self.parent:draw()
	end

	love.graphics.setColor(0, 0, 0, 175)
	love.graphics.rectangle("fill", 0, 0, 960, 540)

	love.graphics.setColor(255, 255, 255)
	love.graphics.print("Paused", 960 / 2 - 108, 540 / 2 - 18, 0, 3)
end

PlayState = class {}
function PlayState:new()
	self.world = World(nil, 43, 43, 2, 3, 2300)
	self.console = Console(self.world)
	self.console.lines = self.world.consoleMessage
	self.world.console = self.console
	self.book = Book()
	self.rooms = 2

	self.lastPauseButton = false
end

function PlayState:nowActive(parent)
end

function PlayState:nextLevel()
	self.rooms = self.rooms + 1
	self.world = World(nil, 35 + self.rooms * 4, 35 + self.rooms * 4, self.rooms, 3, self.rooms * 30)
	self.console = Console(self.world)
	self.console.lines = self.world.consoleMessage
	self.world.console = self.console
end

function PlayState:update(dt)
	self.console:update(dt)
	self.world:update(dt)
	self.book:update(dt)

	local pauseButton = love.keyboard.isDown "escape"

	if not self.lastPauseButton and pauseButton then
		addState(PauseState())
	end

	if self.world.timer <= 0 then
		self.world.timer = 0.0
		addState(GameOverState())
	end


	if self.world.completed then
		self:nextLevel()
	end

	self.lastPauseButton = pauseButton
end

function PlayState:draw()
	love.graphics.push()
	love.graphics.translate(320 - self.world.player.pos.x - 16 + 320, 200 - self.world.player.pos.y - 16)
	love.graphics.setScissor(0, 0, 960, 540 - 197)
	self.world:draw()
	love.graphics.setScissor()
	love.graphics.pop()

	self.console:draw()

	self.book:draw()
end


GameOverState = class {}
function GameOverState:new()
	self.parent = nil
	self.lastGameOver = true
	self.rectangle = Rectangle(960/2 -120, 540/2 +35, 340, 40)
end

function GameOverState:nowActive(parent)
	self.parent = parent
end

function GameOverState:update(dt)
	local x = love.mouse.getX()
	local y = love.mouse.getY()

	if self.rectangle:contains(x,y) then
		if(isLeftButtonDown()) then
			clearState()
			addState(MainMenuState())
		end
	end

end

function GameOverState:draw()
	if self.parent then
		self.parent:draw()
	end

	love.graphics.setColor(0, 0, 0, 0)
	love.graphics.rectangle("fill", 0, 0, 960, 540)

	love.graphics.setColor(255, 255, 255)
	love.graphics.print("GAME OVER", 960 / 2 - 108, 540 / 2 - 18, 0, 3)
	--love.graphics.rectangle("fill", self.rectangle:split())
	love.graphics.print("Go to Main Menu", 960/2 - 120, 540/2 + 35, 0, 2)
end

MainMenuState = class {}
function MainMenuState:new()
	self.parent = nil
	self.lastMainMenu = true
	self.start = Rectangle(580, 450, 135, 40)
	self.HowToPlay = Rectangle(235, 300, 300, 50)
	self.Tutorial = Rectangle(235, 365, 300, 50)
	self.Credits = Rectangle(235, 429, 300, 50)
end

function MainMenuState:nowActive(parent)
	self.parent = parent
end

function MainMenuState:update(dt)
	local x = love.mouse.getX()
	local y = love.mouse.getY()

	if self.start:contains(x,y) then
		if(isLeftButtonDown()) then
			addState(PlayState())
		end
	elseif self.HowToPlay:contains(x, y) then
		if isLeftButtonDown() then
			addState(ControlsState())
		end
	elseif self.Tutorial:contains(x, y) then
		if isLeftButtonDown() then
			addState(PlayState())
		end
	elseif self.Credits:contains(x, y) then
		if isLeftButtonDown() then
			addState(CreditsState())
		end
	end
end

function MainMenuState:draw()
	if self.parent then
		self.parent:draw()
	end
	love.graphics.setColor(255,255,255)
	love.graphics.draw(TEXTURES["title"],0,0)
end



ControlsState = class {}
function ControlsState:new()
	self.parent = nil
	self.rectangle = Rectangle(430, 450, 250, 40)
end

function ControlsState:nowActive(parent)
	self.parent = parent
end

function ControlsState:update(dt)
	local x = love.mouse.getX()
	local y = love.mouse.getY()

	if self.rectangle:contains(x,y) then
		if(isLeftButtonDown()) then
			clearState()
			addState(MainMenuState())
		end
	end

end

function ControlsState:draw()
	if self.parent then
		self.parent:draw()
	end

	love.graphics.setColor(255, 255, 255)
	love.graphics.draw(TEXTURES["howToPlay"],0,0)

	--love.graphics.print("Go to Main Menu", 0, 200, 0, 1.5)
end




CreditsState = class {}
function CreditsState:new()
	self.parent = nil
	self.rectangle = Rectangle(430, 450, 250, 40)
end

function CreditsState:nowActive(parent)
	self.parent = parent
end

function CreditsState:update(dt)
	local x = love.mouse.getX()
	local y = love.mouse.getY()

	if self.rectangle:contains(x,y) then
		if(isLeftButtonDown()) then
			clearState()
			addState(MainMenuState())
		end
	end

end

function CreditsState:draw()
	if self.parent then
		self.parent:draw()
	end

	love.graphics.setColor(255, 255, 255)
	love.graphics.draw(TEXTURES["credits"], 0 ,0)

--	love.graphics.setColor(255, 0, 0)
--	love.graphics.rectangle("fill", self.rectangle:split())

--	love.graphics.setColor(255, 255, 255)
--	love.graphics.print("Go to Main Menu", 0, 200, 0, 1.5)
end




function loadTextures()
	TEXTURES["straight_wall"] = love.graphics.newImage("res/textures/Straight_Wall.png")
	TEXTURES["inclosed_corner"] = love.graphics.newImage("res/textures/Inclosed_Corner.png")
	TEXTURES["exclosed_corner"] = love.graphics.newImage("res/textures/Exclosed_Corner.png")
	TEXTURES["console"] = love.graphics.newImage("res/textures/Bot.png")
	TEXTURES["floor"] = love.graphics.newImage("res/textures/Floor.png")
	TEXTURES["stairs"] = love.graphics.newImage("res/textures/Stairs.png")
	TEXTURES["book"] = love.graphics.newImage("res/textures/Book.png")
	TEXTURES["book_page1"] = love.graphics.newImage("res/textures/Numbers.png")
	TEXTURES["book_page2"] = love.graphics.newImage("res/textures/verb.png")
	TEXTURES["book_page3"] = love.graphics.newImage("res/textures/Noun.png")
	TEXTURES["book_page4"] = love.graphics.newImage("res/textures/Color.png")
	TEXTURES["book_page5"] = love.graphics.newImage("res/textures/opporators.png")
	TEXTURES["prevArrow"]  = love.graphics.newImage("res/textures/Arrows.png")
	TEXTURES["book_pencil"] = love.graphics.newImage("res/textures/pencil.png")
	TEXTURES["book_eraser"] = love.graphics.newImage("res/textures/eraser.png")
	TEXTURES["book_magnifier"] = love.graphics.newImage("res/textures/Magnifier.png")
	TEXTURES["button_out"] = love.graphics.newImage("res/textures/Button.png")
	TEXTURES["button_in"] = love.graphics.newImage("res/textures/Button_press.png")
	TEXTURES["lever_up"] = love.graphics.newImage("res/textures/Lever_up.png")
	TEXTURES["lever_down"] = love.graphics.newImage("res/textures/Lever_down.png")
	TEXTURES["player"] = love.graphics.newImage("res/textures/Character.png")
	TEXTURES["glowstick"] = love.graphics.newImage("res/textures/glow_stick.png")
	TEXTURES["Arrow_down"] = love.graphics.newImage("res/textures/Arrow_down.png")
	TEXTURES["Arrow_up"] = love.graphics.newImage("res/textures/Arrow_up.png")
	TEXTURES["title"] = love.graphics.newImage("res/textures/title.png")
	TEXTURES["credits"] = love.graphics.newImage("res/textures/Credits.png")
	TEXTURES["howToPlay"] = love.graphics.newImage("res/textures/howtoplay.png")


	loadSymbolTextures()
	linkSymbols()
end

local states = Stack()
function love.load()
	loadTextures()

	love.graphics.setFont(love.graphics.newFont("res/fonts/DroidSansMono.ttf", 18))

	addState(MainMenuState())

	-- This prevents love from using ugly bilinear filtering when scaling or rotating an image
	love.graphics.setDefaultFilter("nearest", "nearest", 0)

	print "Game loaded"
end

function addState(state)
	if state.nowActive then
		state:nowActive(states:top())
	end
	states:push(state)
end

function popState()
	states:pop()
end

function clearState()
	states = Stack()
end

function love.update(dt)
	if love.keyboard.isDown "p" then
		love.event.quit()
	end

	states:top():update(dt)
end

function love.draw()
	states:top():draw()
end
