-- Заранее инициализируем ссылки на имена классов, которые понадобятся,
-- ибо вышестоящие классы будут использовать часть нижестоящих.
local Ship, Bullet, Asteroid, Field

Ship = {}
-- У всех таблиц, метатаблицей которых является ship,
-- дополнительные методы будут искаться в таблице ship.
Ship.__index = Ship 

-- Задаём общее поле для всех членов класса, для взаимодействия разных объектов
Ship.type = 'ship'

local cameraX, cameraY = 0, 0
-- Двоеточие - хитрый способ передать таблицу первым скрытым аргументом 'self'.
local zoom = 1 -- начальное значение зума

local timer = 0

function love.load()
    -- Другие параметры инициализации
end

function love.wheelmoved(x, y)
    -- Увеличиваем или уменьшаем масштаб в зависимости от направления прокрутки
    if y > 0 then
        zoom = zoom + 0.1
    elseif y < 0 then
        zoom = zoom - 0.1
    end

    -- Ограничиваем минимальный и максимальный зум
    zoom = math.max(0.5, math.min(zoom, 3))
end

function Ship:new(field, x, y)
	-- Сюда, в качестве self, придёт таблица Ship.

	-- Переопределяем self на новый объект, self как таблица Ship больше не понадобится.
	self = setmetatable({}, self)

	-- Мы будем передавать ссылку на игровой менеджер, чтобы командовать им.
	self.field = field
	screen_width, screen_height = love.graphics.getDimensions()
	-- Координаты:
	self.x = screen_width / 2 or 100 -- 100 - дефолт
	self.y = screen_height / 2 or 100

	-- Текущий угол поворота:
	self.angle = 0
	
	-- И заполняем всё остальное:
	
	-- Вектор движения:
	self.vx = 0
	self.vy = 0

	self.direction = 0
	-- Ускорение, пикс/сек:
	self.acceleration  = 500
    self.speed  = 200
	
	-- -- Скорость поворота:
	self.rotation      = 2 * math.pi
	
	-- Всякие таймеры стрельбы:
	self.shoot_timer = 0
	self.shoot_delay = 0.3
	
	-- Радиус, для коллизии:
	self.radius   = 5
		
	-- Список вершин полигона, для отрисовки нашего кораблика:
	self.vertexes = {0, -10, 10, 10, 0, 5, -10, 10}
	
	-- Возвращаем объект.
	return self 
end

function Ship:update(dt)
	-- Декрементов нема, и инкрементов тоже, но это не очень страшно, правда?
	-- dt - дельта времени, промежуток между предыдущим и текущим кадром.
	self.shoot_timer = self.shoot_timer - dt
	
	
	-- Управление:
	
	if love.mouse.isDown(1) then
		local mouseX, mouseY = love.mouse.getPosition()
        self.angle = math.atan2(mouseY - screen_height / 2, mouseX - screen_width / 2)
	end

	-- "Если зажата кнопка и таймер истёк" - спавним новую пулю.
	if love.mouse.isDown(1) and self.shoot_timer < 0 then
		self.field:spawn(Bullet:new(self.field, self.x, self.y, self.angle))

		-- И сбрасываем таймер, потому что мы не хотим непрерывных струй из пуль, 
		-- хоть это и забавно.
		self.shoot_timer = self.shoot_delay
	end
	
	if love.keyboard.isDown("x") and self.shoot_timer < 0 then
		self.field:spawn(Swort:new(self.field, self.x, self.y, self.angle))

		-- И сбрасываем таймер, потому что мы не хотим непрерывных струй из пуль, 
		-- хоть это и забавно.
		self.shoot_timer = self.shoot_delay
	end


	if love.keyboard.isDown("w") then
		self.y = self.y - self.speed * dt
        cameraY = cameraY - self.speed * dt
    end
    if love.keyboard.isDown("s") then
		self.y = self.y + self.speed * dt
        cameraY = cameraY + self.speed * dt
    end
    if love.keyboard.isDown("a") then
		self.x = self.x - self.speed * dt
        cameraX = cameraX - self.speed * dt
    end
    if love.keyboard.isDown("d") then
		self.x = self.x + self.speed * dt
        cameraX = cameraX + self.speed * dt
    end
	
	if love.keyboard.isDown("d") and love.keyboard.isDown("w") then
		self.direction = - math.pi / 4
	elseif love.keyboard.isDown("d") and love.keyboard.isDown("s") then
		self.direction = math.pi / 4
	elseif love.keyboard.isDown("a") and love.keyboard.isDown("s") then
		self.direction = 3 * math.pi / 4
	elseif love.keyboard.isDown("a") and love.keyboard.isDown("w") then
		self.direction = - 3 * math.pi / 4
	elseif love.keyboard.isDown("d") then
		self.direction = 0
	elseif love.keyboard.isDown("s") then
		self.direction = math.pi / 2
	elseif love.keyboard.isDown("a") then
		self.direction = math.pi
	elseif love.keyboard.isDown("w") then
		self.direction = - math.pi / 2
	end


	local angleDifference = (self.direction - self.angle + math.pi) % (2 * math.pi) - math.pi

    self.angle = self.angle + angleDifference * self.rotation * dt


end

function Ship:draw()
	
	love.graphics.setColor(255,255,255)
	
	love.graphics.push()
	love.graphics.translate (self.x, self.y)
	love.graphics.rotate (self.angle + math.pi/2)
	love.graphics.polygon('line', self.vertexes)
	love.graphics.pop()
	
end


Bullet = {}
Bullet.__index = Bullet


Bullet.type = 'bullet'
Bullet.speed = 300

function Bullet:new(field, x, y, angle)
  self = setmetatable({}, self)
	
	-- Аналогично задаём параметры
	self.field = field
	self.x      = x
	self.y      = y
	self.radius = 3

	-- время жизни
	self.life_time = 5
	
	-- Нам надо бы вычислить 
	-- вектор движения из угла поворота и скорости:
	self.vx = math.cos(angle) * self.speed
	self.vy = math.sin(angle) * self.speed
	-- Так как у объекта self нет поля speed, 
	-- поиск параметра продолжится в таблице под полем 
	-- __index у метатаблицы
	
	return self
end

function Bullet:update(dt)
	-- Управляем временем жизни:
	self.life_time = self.life_time - dt
	
	if self.life_time < 0 then
		-- У нас пока нет такого метода,
		-- но это тоже неплохо.
		self.field:destroy(self)
		return
	end
	
	-- Те же векторы
	self.x = self.x + self.vx * dt
	self.y = self.y + self.vy * dt

end

function Bullet:draw()
	love.graphics.setColor(255,255,255)
	
	-- Обещанная простая функция отрисовки.
	-- Полигоны, увы, так просто вращать не получится
	love.graphics.circle('fill', self.x, self.y, self.radius)
end

Swort = {}
Swort.__index = Swort


Swort.type = 'swort'
Swort.rotation = 4*math.pi
Swort.lenght = 150

function Swort:new(field, x, y, angle)
  self = setmetatable({}, self)
	
	-- Аналогично задаём параметры
	self.field = field
	self.x      = x
	self.y      = y
	self.angle  = angle
	self.angle_0 = self.angle
	return self
end

function Swort:update(dt)
	self.angle = self.angle - self.rotation * dt
	-- if math.fabs(self.angle - self.angle_0) > math.pi then
	-- 	self.field:destroy(self)
	-- end
end



function Swort:draw()
	for object in pairs(self.field:getObjects()) do
		-- Вот за этим мы выставляли типы.
		if object.type == 'ship' then
			self.x = object.x
			self.y = object.y
		end
	end

	local function rotation_x(x, y, alfa)
		return y*math.sin(alfa) + x*math.cos(alfa) + self.x
	end
	
	local function rotation_y(x, y, alfa)
		return y*math.cos(alfa) + x*math.sin(alfa) + self.y
	end

	love.graphics.setColor(255,255,255)
	x1 = rotation_x(-5, -5, self.angle)
	y1 = rotation_y(-5, -5, self.angle)
	x2 = rotation_x(0, - -Swort.lenght, self.angle)
	y2 = rotation_y(0, - -Swort.lenght, self.angle)
	x3 = rotation_x(5, -5, self.angle)
	y3 = rotation_y(5, -5, self.angle)
	-- love.graphics.polygon('line', {-5 + self.x, 5 + self.y, 0 + self.x, 50 + self.y, 5 + self.x, -5 + self.y})
	love.graphics.polygon('line', {x1, y1, x2, y2, x3, y3})
end


-- В кого стрелять? В мимопролетающие астероиды, конечно.
Asteroid = {}
Asteroid.__index = Asteroid
Asteroid.type = 'asteroid'

function Asteroid:new(field, x, y, size)
  self = setmetatable({}, self)

	self.field  = field
	self.x      = x
	self.y      = y

	-- Размерность астероида будет варьироваться 1-N.
	self.size   = size or 4
		
	-- Векторы движения будут - случайными и неизменными.
	self.vx     = math.random(-20, 20)
	self.vy     = math.random(-20, 20)

	self.radius = size * 15 -- модификатор размера
	
	self.hp = 2 * size -- + math.random(1)
	
	-- Пусть они будут ещё и разноцветными.
	self.color = {math.random(255), math.random(255), math.random(255)}
	return self
end

-- Тут сложный метод, поэтому выделяем его отдельно
function Asteroid:applyDamage(dmg)

	-- если урон не указан - выставляем единицу
	dmg = dmg or 1
	self.hp = self.hp - 1
	if self.hp < 0 then
		-- Подсчёт очков - самое главное
		self.field.score = self.field.score + 100 * 2 ^ (self.size - 1)
		self.field:destroy(self)
		if self.size > 1 then
			-- Количество обломков слегка рандомизируем.
			for i = 1, 4 do
				self.field:spawn(Asteroid:new(self.field, self.x, self.y, self.size - 1))
			end
		end
		
		-- Если мы были уничтожены, вернём true, это удобно для некоторых случаев.
		return true
	end
end

-- Мы довольно часто будем применять эту функцию ниже
local function collide(x1, y1, r1, x2, y2, r2)
	-- Измеряем расстояния между точками по Теореме Пифагора:
  local distance = (x2 - x1) ^ 2 + (y2 - y1) ^ 2

	-- Коль это расстояние оказалось меньше суммы радиусов - мы коснулись.
	-- Возводим в квадрат чтобы сэкономить пару тактов на невычислении корней.
	local rdist = (r1 + r2) ^ 2
	return distance < rdist
end

function Asteroid:update(dt)

	self.x = self.x + self.vx * dt
	self.y = self.y + self.vy * dt

	-- Астероиды у нас взаимодействуют и с пулями и с корабликом,
	-- поэтому можно запихнуть обработку взаимодействия в класс астероидов:

	for object in pairs(self.field:getObjects()) do
		-- Вот за этим мы выставляли типы.
		if object.type == 'bullet' then
			if collide(self.x, self.y, self.radius, object.x, object.y, object.radius) then
				-- self.field:destroy(object)
				-- А за этим - возвращали true.
				if self:applyDamage() then
					return
				end
			end
		elseif object.type == 'ship' then
			if collide(self.x, self.y, self.radius, object.x, object.y, object.radius) then
				-- Показываем messagebox и завершаем работу.
				-- Лучше выделить отдельно, но пока и так неплохо.
				
				local head = 'You loose!'
				local body = 'Score is: '..self.field.score..'\nRetry?'
				local keys = {"Yea!", "Noo!"}
				local key_pressed = love.window.showMessageBox(head, body, keys)
				-- Была нажата вторая кнопка "Noo!":
				if key_pressed == 2 then
					love.event.quit()
				end
				self.field:init()
				return
			end
		elseif object.type == 'swort' then
			dr = 4
			for i = 0, object.lenght, dr do
				if collide(self.x, self.y, self.radius, object.x + i*math.cos(object.angle), object.y + i*math.sin(object.angle), 0) then
					if self:applyDamage() then
						return
					end
				end
			end
		end
	end
end

function Asteroid:draw()
	-- Указываем текущий цвет астероида:
	love.graphics.setColor(self.color)
	
	-- Полигоны, увы, так просто вращать не получится
	love.graphics.circle('line', self.x, self.y, self.radius)
end


-- Наконец, пишем класс который соберёт всё воедино:

Field = {}
Field.type = 'Field'
-- Это будет синглтон, создавать много игровых менеджеров мы не собираемся,
-- поэтому тут даже __index не нужен, ибо не будет объектов, 
-- которые ищут методы в этой таблице.

-- А вот инициализация/сброс параметров - очень даже пригодятся.
function Field:init()
	self.score   = 0

	-- Таблица для всех объектов на поле
	self.objects = {}

	local ship = Ship:new(self, 100, 200)
	print(ship)
	self:spawn(ship)
end


function Field:spawn(object)
	
	-- Это немного нестандартное применение словаря:
	-- в качестве ключа и значения указывается сам объект.
	self.objects[object] = object
end

function Field:destroy(object)

	-- Зато просто удалять.
	self.objects[object] = nil
end

function Field:getObjects()
	return self.objects
end

function Field:update(dt)

	-- Мы хотим создавать новые астероиды, когда все текущие сломаны.
	-- Сюда можно добавлять любые игровые правила.
	local asteroids_count = 0
	
	for object in pairs(self.objects) do
		-- Проверка на наличие метода
		if object.update then
			object:update(dt)
		end
		
		if object.type == 'asteroid' then
			asteroids_count = asteroids_count + 1
		end
	end
	
	local spavn = 1

	if timer > spavn then
		timer = timer - spavn

		local r = math.random(400, 700)
		local alfa = math.random(0, 2*math.pi)
		local n = math.random(2,4)
		self:spawn(Asteroid:new(self, cameraX + screen_width / 2 + r * math.cos(alfa), cameraY + screen_height / 2 + r * math.sin(alfa), n))
		
	end
end

function Field:draw()
	for object in pairs(self.objects) do
		if object.draw then
			object:draw()
		end
	end
	love.graphics.print('\n  Score: '..self.score, cameraX, cameraY)
end


-- Последние штрихи: добавляем наши классы и объекты в игровые циклы:

function love.load()
	Field:init()
end


function love.update(dt)
	timer = timer + dt
	Field:update(dt)
end

function love.draw()
	-- Применяем зум
    love.graphics.push()
    love.graphics.translate(screen_width / 2, screen_height / 2)
	
    love.graphics.scale(zoom, zoom)

    love.graphics.translate(-screen_width / 2, -screen_height / 2)
	
	love.graphics.translate(-cameraX, -cameraY)
	Field:draw()
	
    love.graphics.pop()

	
end