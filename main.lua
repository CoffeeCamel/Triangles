require "math"

--																			   |
--TODO																		   |
--- Optionally draw positive cones of individual edges.						   |
--- Draw sub-triangles showing the area of the barycentric weights.			   |
--- Perspective projection.													   |
--- Affine texture mapping.                                                    |
--- Don't port to Julia but force 16-bit depth buffer with fixed-point math?   |
--- Port to Julia/SDL2, 16-bit depth buffer to induce z-fighting.			   |
--- Flyable and smooth orbiting camera system.								   |
--- Generalise internal model structure.	(GoldRender?)					   |
--- Load model data from file.		(GoldRender?)							   |
--																			   |
--																			   |


--D/O: Rewrite to draw from array of points around point of any even radius?   |
function bigPoint(point)
	love.graphics.points(point.x-2, point.y-2,   point.x-1, point.y-2,   point.x, point.y-2,   point.x+1, point.y-2,   point.x+2, point.y-2,
						 point.x-2, point.y-1,   point.x-1, point.y-1,   point.x, point.y-1,   point.x+1, point.y-1,   point.x+2, point.y-1,
						 point.x-2, point.y,     point.x-1, point.y,     point.x, point.y,     point.x+1, point.y,     point.x+2, point.y,
						 point.x-2, point.y+1,   point.x-1, point.y+1,   point.x, point.y+1,   point.x+1, point.y+1,   point.x+2, point.y+1,
					 	 point.x-2, point.y+2,   point.x-1, point.y+2,   point.x, point.y+2,   point.x+1, point.y+2,   point.x+2, point.y+2)
end


--LOVE.LOAD()																   |
function love.load()
--SELF-EXPLANATORY CODE														   |
	love.window.setTitle("Barycentric Coordinates / Triangle Interpolation")

	font = love.graphics.newFont("Cardo-Regular.ttf", 14)
	love.graphics.setFont(font)

	screen = {}
	screen.width  = love.graphics.getWidth()
	screen.height = love.graphics.getHeight()
	screen.centre = {}
	screen.centre.x = screen.width / 2
	screen.centre.y = screen.height / 2


--DEPTH BUFFER																   |
	nearPlane = -100
	farPlane = 100
	depthBuffer = {}
	for x = 0, screen.width do
		depthBuffer[x] = {}
		for y = 0, screen.height do
			depthBuffer[x][y] = 0
		end
	end


--DEFINING OUR TRIANGLE														   |
--Two-dimensional points for now, with an arbitrary	additional field of data.  |
	A = {}
	A.x = screen.centre.x - 120
	A.y = screen.centre.y + 80
	A.banana = 20

	B = {}
	B.x = screen.centre.x + 80
	B.y = screen.centre.y - 80
	B.banana = -30

	C = {}
	C.x = screen.centre.x + 160
	C.y = screen.centre.y + 120
	C.banana = 60

--DEFINING OTHER OBJECTS													   |
--An arbitrarily placed point for demonstrating barycentric coordinates.       |
	P = {}
	P.x = screen.centre.x
	P.y = screen.centre.y
	P.w1 = 0
	P.w2 = 0
	P.w3 = 0
	P.banana = 0

--The cursor for iterating over rasterArea.									   |
	cursor = {}
	cursor.x = 0
	cursor.y = 0
	cursor.w1 = 0
	cursor.w2 = 0
	cursor.w3 = 0
	cursor.banana = 0

--A bounding box for our triangle to reduce the area over which the cursor has |
--to travel to find points within the triangle.                                |
	rasterArea = {}
	rasterArea.x1 = screen.centre.x
	rasterArea.x2 = screen.centre.x
	rasterArea.y1 = screen.centre.y
	rasterArea.y2 = screen.centre.y
end

--LOVE.UPDATE()																   |
function love.update()
--CONTROLS																	   |
--Move point P around the screen using WASD.								   |
--The user cannot move up and down or left and right at the same time but may  |
--move a direction on each axis at the same time to travel diagonally.		   |
	if love.keyboard.isDown("w") then
		P.y = P.y - 1
	elseif love.keyboard.isDown("s") then
		P.y = P.y + 1
	end
	if love.keyboard.isDown("a") then
		P.x = P.x - 1
	elseif love.keyboard.isDown("d") then
		P.x = P.x + 1
	end

--RASTER AREA																   |
--Determining the bounding box rasterArea of the triangle ABC by comparing its |
--points and finding the extremes of the triangle's dimensions.				   |
	rasterArea.x1 = math.min(A.x, B.x, C.x)
	rasterArea.x2 = math.max(A.x, B.x, C.x)
	rasterArea.y1 = math.min(A.y, B.y, C.y)
	rasterArea.y2 = math.max(A.y, B.y, C.y)


--BARYCENTRIC WEIGHTS														   |
--WEIGHT ONE:																   |
		--  Ax(Cy-Ay)+(Py-Ay)(Cx-Ax)-Px(Cy-Ay)								   |
	--W1 = ------------------------------------ 							   |
		--    (By-Ay)(Cx-Ax)-(Bx-Ax)(Cy-Ay)									   |
				--															   |
	P.w1 = ((A.x*(C.y-A.y)) + ((P.y-A.y)*(C.x-A.x)) - (P.x*(C.y-A.y)))  /  (((B.y-A.y)*(C.x-A.x)) - ((B.x-A.x)*(C.y-A.y)))
--WEIGHT TWO:																   |
	--		Py-Ay-W1(By-Ay)													   |
	--W2 = -----------------												   |
	--			Cy-Ay														   |
	-- 																		   |
	P.w2 = (P.y - A.y - (P.w1*(B.y-A.y)))  /  (C.y-A.y)
--WEIGHT THREE:																   |
	--W3 = 1 - (W1 + W2)											  		   |
	P.w3 = 1 - (P.w1 - P.w2)


--DETERMINE BANANA															   |
--Linear interpolation between the 3 banana fields of the triangle's vertices  |
--by the weights of the vertices to determine what the banana field of P is.   |
	P.banana = (B.banana * P.w1) + (C.banana * P.w2) + (A.banana * P.w3)
end


--LOVE.DRAW()																   |
function love.draw()
	love.graphics.setBackgroundColor(.3, 0, .2)
--DRAW THE RASTER AREA														   |
--Set draw colour to a faded green.											   |
	love.graphics.setColor(0,.5,0)
--Draw at a constant value on one axis between the edges of the other axis to  |
--make a box.																   |
	love.graphics.line(rasterArea.x1, rasterArea.y1, rasterArea.x1, rasterArea.y2)
	love.graphics.line(rasterArea.x2, rasterArea.y1, rasterArea.x2, rasterArea.y2)
	love.graphics.line(rasterArea.x1, rasterArea.y1, rasterArea.x2, rasterArea.y1)
	love.graphics.line(rasterArea.x1, rasterArea.y2, rasterArea.x2, rasterArea.y2)
	love.graphics.setColor(1,1,1)


--FILL/RASTERISE THE TRIANGLE												   |
	for y = rasterArea.y1, rasterArea.y2 do
		for x = rasterArea.x1, rasterArea.x2 do
			cursor.x = x --D/O: Iterate with cursor fields directly?	   	   |
			cursor.y = y

--BARYCENTRIC WEIGHTS														   |
--WEIGHT ONE:																   |
			--		Ax(Cy-Ay)+(Py-Ay)(Cx-Ax)-Px(Cy-Ay)						   |
			--W1 = ------------------------------------ 					   |
			--		(By-Ay)(Cx-Ax)-(Bx-Ax)(Cy-Ay)							   |
			--																   |
			cursor.w1 = ((A.x*(C.y-A.y)) + ((cursor.y-A.y)*(C.x-A.x)) - (cursor.x*(C.y-A.y)))  /  (((B.y-A.y)*(C.x-A.x)) - ((B.x-A.x)*(C.y-A.y)))
--WEIGHT TWO:																   |
			--		Py-Ay-W1(By-Ay)											   |
			--W2 = -----------------										   |
			--			Cy-Ay												   |
			-- 																   |
			cursor.w2 = (cursor.y - A.y - (cursor.w1*(B.y-A.y)))  /  (C.y-A.y)
--WEIGHT THREE:																   |
			--W3 = 1 - (W1 + W2)											   |
			cursor.w3 = 1 - (cursor.w1 + cursor.w2)


--DETERMINE BANANA															   |
--Linear interpolation between the 3 banana fields of the triangle's vertices, |
--by the weights of the vertices, to determine what the banana field of the    |
--pixel under the cursor is. 												   |
			cursor.banana = (B.banana * cursor.w1) + (C.banana * cursor.w2) + (A.banana * cursor.w3)


--TRIANGLE EDGE TEST														   |
--The pixel under the cursor is inside the triangle IF:					 	   |
--1. W1 ≥ 0																	   |
--2. W2 ≥ 0																	   |
--3. W1+W2 ≤ 1															 	   |
--																			   |
			if cursor.w1 >= 0 and cursor.w2 >= 0 and (cursor.w1 + cursor.w2) <= 1 then
				--z = ((farPlane+nearPlane) / (farPlane-nearPlane)) + ((1/cursor.banana) * ((-2*farPlane*nearPlane) / (farPlane-nearPlane)))
				z = (2 * ((cursor.banana-nearPlane) / (farPlane-nearPlane))) - 1
				z = .5 * (z+1)
				depthBuffer[x][y] = z
				--For now the fill of the triangle is just random colour noise.|
				--love.graphics.setColor(math.random(), math.random(), math.random())
				love.graphics.setColor(z,z,0)
				love.graphics.points(cursor.x, cursor.y)
				love.graphics.setColor(1,1,1)
			end
		end
	end


--DRAW THE EDGES OF THE TRIANGLE											   |
	--[[love.graphics.setColor(1,1,1)
	love.graphics.line(A.x, A.y, B.x, B.y)
	love.graphics.line(B.x, B.y, C.x, C.y)
	love.graphics.line(C.x, C.y, A.x, A.y)]]


	--DRAW DEPTH BUFFER															   |
	--[[for x = 0, screen.width do
		for y = 0, screen.height do
			z = depthBuffer[x][y]
			love.graphics.setColor(z,z,0)
			love.graphics.points(x,y)
		end
	end]]


--DRAW THE POINTS OF THE TRIANGLE											   |
	bigPoint(A)
	--Colour point B red.													   |
	love.graphics.setColor(1,0,0)
	bigPoint(B)
	--Colour point C blue.													   |
	love.graphics.setColor(0,0,1)
	bigPoint(C)


--DRAW POINT P																   |
	love.graphics.setColor(.5,0,.5)
	bigPoint(P)


--DRAW DEBUG INFORMATION AT TOP-LEFT OF THE SCREEN							   |
	love.graphics.setColor(1,1,1)
	love.graphics.print("A", A.x - 20, A.y - 10)
	love.graphics.print("B", B.x + 10, B.y - 10)
	love.graphics.print("C", C.x + 10, C.y - 10)
	love.graphics.print("P", P.x + 10, P.y - 10)
	--^^^^^^SEPARATE FROM DEBUG, PUT WITH POINTS!!!!!!!

	love.graphics.print("Weight 1: " .. P.w1, 10, 10)
	love.graphics.print("Weight 2: " .. P.w2, 10, 25)
	love.graphics.print("Weight 3: " .. 1 - (P.w1 + P.w2), 10, 40)
	--Test if point P is inside the triangle for debug purposes.			   |
	if P.w1 >= 0 and P.w2 >= 0 and (P.w1 + P.w2) <= 1 then
		love.graphics.print("P is in ABC", 10, 55)
	else
		love.graphics.print("P is not in ABC", 10, 55)
	end
	love.graphics.print("Banana of A: " .. A.banana, 10, 70)
	love.graphics.print("Banana of B: " .. B.banana, 10, 85)
	love.graphics.print("Banana of C: " .. C.banana, 10, 100)
	love.graphics.print("Banana of P: " .. P.banana, 10, 115)
	love.graphics.print("Depth Buffer at P: " .. depthBuffer[P.x][P.y], 10, 130)
end
