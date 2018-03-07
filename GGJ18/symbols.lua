lang = {}
lang.nouns = {"button", "lever"}
lang.verbs = {"push", "pull"}
lang.color = {"green", "blue", "red", "white"}
lang.number = {1,2,3,4,5,6,7,8,9, "room"}
lang.symbols = {}
lang.symbols.nouns = {1,2,3,4,5,6}
lang.symbols.verbs = {1,2,3,4,5}
lang.symbols.color = {1,2,3,4}
lang.symbols.number ={1,2,3,4,5,6,7,8,9,10} 


function generateStatement()
	--generate noun
	local noun = math.floor(love.math.random(1, #lang.nouns))

	--generate verb
	local verb
	if(math.floor(love.math.random(1,5)) == 1) then
		verb = #lang.verbs
	else
		verb = noun
	end

	--generate adjective
	local adj = math.floor(love.math.random(1, #lang.color))

	--generate number
	local num
	num = math.floor(love.math.random(1, 3))

	return {verb, adj, noun, num}
end

function isGenerated(statements, newStatement)
	for i = 1, #statements do
		if(newStatement[2] == statements[i][2]) then
			if(newStatement[3] == statements[i][3]) then
				return true
			end
		end
	end
	return false
end


function generateUniqueStatements(x)
	local statements = {}
	local newStatement
	for i = 1, x do
		repeat
			 newStatement = generateStatement()
		until not isGenerated(statements, newStatement)
		statements[i] = newStatement 	
	end
	return statements
end

function loadSymbolTextures()
	for i = 1, #lang.symbols.nouns do
		lang.symbols.nouns[i] = love.graphics.newImage("res/textures/nouns/" .. lang.symbols.nouns[i] .. ".png")
	end
	for i = 1, #lang.symbols.verbs do
		lang.symbols.verbs[i] = love.graphics.newImage("res/textures/verbs/" .. lang.symbols.verbs[i] .. ".png")
	end
	for i = 1, #lang.symbols.number do
		lang.symbols.number[i] = love.graphics.newImage("res/textures/numbers/" .. lang.symbols.number[i] .. ".png")
	end
	for i = 1, #lang.symbols.color do
		lang.symbols.color[i] = love.graphics.newImage("res/textures/colors/" .. lang.symbols.color[i] .. ".png")
	end
end

function linkSymbols()
	local function randomize(tab)
		local done = false
		local res = {}
		repeat
			local index = math.floor(love.math.random(1, #tab))
			local elem = tab[index]
			table.insert(res, elem)
			table.remove(tab, index)
			if #tab == 0 then
				done = true
			end
		until done
		return res
	end

	lang.symbols.number = randomize(lang.symbols.number)
	lang.symbols.verbs = randomize(lang.symbols.verbs)
	lang.symbols.color = randomize(lang.symbols.color)
	lang.symbols.nouns = randomize(lang.symbols.nouns)
end