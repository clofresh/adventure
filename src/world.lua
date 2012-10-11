local Camera = require 'lib/hump/camera'
local HC = require 'lib/HardonCollider'

local pathing = require 'src/pathing'
local sprite = require 'src/sprite'

local World = Class{function(self, map)
  self.cam = Camera.new(980, 1260, 1, 0)
  self.collider = HC(100, function(dt, shapeA, shapeB, mtvX, mtvY)
    --self:onCollide(dt, shapeA, shapeB, mtvX, mtvY)
  end)

  self.keyInputEnabled = true
  self.focus = nil
  self.map = map
  self.turn = 1
  self._keysPressed = {}

  -- Build up an index of obstructions by position
  local obstructions = {}
  for name, layer in pairs(map.layers) do
    if layer.properties and layer.properties.obstruction then
      for x, y, tile in layer:iterate() do
        if not obstructions[x] then
          obstructions[x] = {y=tile}
        else
          obstructions[x][y] = tile
        end
      end
    end
  end
  self.obstructions = obstructions

  -- Navigation mesh
  self.navmesh = {}
  self.navlookup = {}
  for i, obj in pairs(map("nav").objects) do
    log(obj.name)
    local nw, ne, se, sw, polygon
    nw = vector(obj.x,                 obj.y)
    -- n  = vector(obj.x + obj.width / 2, obj.y)
    ne = vector(obj.x + obj.width,     obj.y)
    -- e  = vector(obj.x + obj.width,     obj.y + obj.height / 2)
    se = vector(obj.x + obj.width,     obj.y + obj.height)
    -- s  = vector(obj.x + obj.width / 2, obj.y + obj.height)
    sw = vector(obj.x,                 obj.y + obj.height)
    -- w  = vector(obj.x,                 obj.y + obj.height / 2)

    local nbrs
    if type(obj.properties.neighbors) == 'string' then
      nbrs = string.split(obj.properties.neighbors, ',')
    elseif type(obj.properties.neighbors) == 'number' then
      nbrs = {tostring(obj.properties.neighbors)}
    end

    polygon = {
      object    = obj,
      vertexes  = {nw, ne, se, sw},
      neighbors = nbrs
    }
    self.navmesh[obj.name] = polygon 

    -- Build up navlookup into a spatial hash mapping tile number to
    -- navmesh polygon. From there you can do a path search.
    -- Tile number is an enumeration of the map's tile in row order, 
    -- starting from 0 (not 1, like is conventional in Lua)
    for i = obj.y, obj.y + obj.height - 1, map.tileHeight do
      local row = i / map.tileHeight
      for j = obj.x, obj.x + obj.width - 1, map.tileWidth do
        local col = j / map.tileWidth
        local tileNum = row * map.width + col
        self.navlookup[tileNum] = polygon
        log("(%d, %d), tileNum: %f, navpoly: %s", col, row, tileNum, polygon.object.name)
      end
    end
  end

  -- triggers
  self.triggers = {}
  for i, trigger in pairs(map("triggers").objects) do
    self.triggers[trigger.name] = trigger
  end

  -- Instantiate the sprites
  local spriteLayer = map("sprites")
  self.sprites = {}
  for i, obj in pairs(spriteLayer.objects) do
    local spr = sprite.fromTmx(obj)
    self:register(spr)
    if spr.name == spriteLayer.properties.focus then
      self:focusOn(spr)
    end
  end

  -- sprite update callback
  spriteLayer.update = function(layer, dt)
    for name, spr in pairs(self.sprites) do
      spr:update(dt, self)
    end
  end

  -- sprite draw callback
  spriteLayer.draw = function(layer)
    local drawOrder = {}
    local i = 1
    for name, spr in pairs(self.sprites) do
      drawOrder[i] = spr
      i = i + 1
    end
    table.sort(drawOrder, function(a, b)
      return a.pos and b.pos and a.pos.y < b.pos.y
    end)
    for i, spr in ipairs(drawOrder) do
      --if spr.tostring then
      --  log("Drawing %s", spr:tostring())
      --end
      spr:draw()
    end
  end

end}

function World:register(spr)
  local shape = spr:initShape(self.collider)
  self.sprites[spr.name] = spr
end

function World:unregister(spr)
  self.collider:remove(spr.shape)
  self.sprites[spr.name] = nil
end

function World:update(dt)
  self.map:callback("update", dt)
  if self.focus then
    self.cam.x = self.focus.pos.x
    self.cam.y = self.focus.pos.y
  end
  self.collider:update(dt)
end

function World:draw()
  --log("Drawing turn %d", self.turn)
  self.cam:draw(function()
    self.map:draw()
  end)
  love.graphics.print(string.format("(%f, %f)", self.cam.x, self.cam.y), 1, 1)

  self.turn = self.turn + 1
end

function World:focusOn(spr)
  self.focus = spr
end

function World:onCollide(dt, shapeA, shapeB, mtvX, mtvY)
  local spriteA, spriteB
  spriteA = self.sprites[shapeA]
  spriteB = self.sprites[shapeB]
  spriteA:onCollide(dt, spriteB, mtvX, mtvY, self)
  spriteB:onCollide(dt, spriteA, mtvX, mtvY, self)
end

function World:pressedKey(key)
  if self.keyInputEnabled then
    self._keysPressed[key] = true
  end
end

function World:releasedKey(key)
  self._keysPressed[key] = nil
end

function World:keysPressed()
  return self._keysPressed
end

function World:isObstructed(gridPos)
  local x = gridPos.x
  local y = gridPos.y
  return x < 1 or x > self.map.width
      or y < 1 or y > self.map.height
      or (self.obstructions[x] and self.obstructions[x][y])
end

function World:findPath(startGridPos, endGridPos)
  log("Finding path from %s to %s", tostring(startGridPos), tostring(endGridPos))
  local query = pathing.PathSearch(startGridPos, endGridPos, self)
  return pathing.search(query)
end

function World:vectorToTileNum(vec)
  return (vec.y / self.map.tileHeight) * self.map.width + (vec.x / self.map.tileWidth)
end

function World:posVectorToTileVector(vec)
  return vector(vec.x / self.map.tileWidth, vec.y / self.map.tileHeight)
end

return {
  World = World,
}
