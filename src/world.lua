local Camera = require 'lib/hump/camera'
local Class = require 'lib/hump/class'
local HC = require 'lib/HardonCollider'

local World = Class{function(self, map, sprites)
  local spriteLayer = map("sprites")

  self.collider = HC(100, function(dt, shapeA, shapeB, mtvX, mtvY)
    self:onCollide(dt, shapeA, shapeB, mtvX, mtvY)
  end)

  self.sprites = {}
  self.focus = nil
  for i, sprite in pairs(sprites) do
    self:register(sprite)
    if sprite.name == spriteLayer.properties.focus then
      self.focus = sprite
    end
  end

  -- prepare the map object
  map.drawObjects = false
  spriteLayer.update = function(layer, dt)
    for shape, sprite in pairs(self.sprites) do
      sprite:update(dt, self)
      if sprite.pos then
        local maxX = (self.map.width * self.map.tileWidth) - (sprite.dim.w / 2)
        local maxY = (self.map.height * self.map.tileHeight) - (sprite.dim.h / 2)

        if sprite.pos.x < 0 then
          sprite.pos.x = 0
        elseif sprite.pos.x > maxX then
          sprite.pos.x = maxX
        end
        if sprite.pos.y < 0 then
          sprite.pos.y = 0
        elseif sprite.pos.y > maxY then
          sprite.pos.y = maxY
        end
      end
    end
  end
  spriteLayer.draw = function(layer)
    local drawOrder = {}
    local i = 1
    for shape, sprite in pairs(self.sprites) do
      drawOrder[i] = sprite
      i = i + 1
    end
    table.sort(drawOrder, function(a, b)
      return a.pos and b.pos and a.pos.y < b.pos.y
    end)
    for i, sprite in ipairs(drawOrder) do
      --if sprite.tostring then
      --  log("Drawing %s", sprite:tostring())
      --end
      sprite:draw()
    end
  end

  local shape
  for i, obj in pairs( map("scenery").objects ) do
    obj.shape = self.collider:addRectangle(obj.x, obj.y,
      obj.width, obj.height)
    self.sprites[obj.shape] = obj
    obj.properties.obstruction = true
    obj.update = function(dt, world)
    end
    obj.onCollide = function(dt, otherSprite, mtvX, mtvY)
    end
    obj.draw = function()
      if debugMode then
        obj.shape:draw('fill')
      end
    end
  end

  self.map = map
  self.cam = Camera.new(980, 1260, 1, 0)
  self.turn = 1
  self._keysPressed = {}
end}

function World:register(sprite)
  shape = sprite:initShape(self.collider)
  self.sprites[shape] = sprite
end

function World:unregister(sprite)
  shape = sprite.shape
  self.collider:remove(shape)
  self.sprites[shape] = nil
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
  self.turn = self.turn + 1
end

function World:focusOn(sprite)
  self.focus = sprite
end

function World:onCollide(dt, shapeA, shapeB, mtvX, mtvY)
  local spriteA, spriteB
  spriteA = self.sprites[shapeA]
  spriteB = self.sprites[shapeB]
  spriteA:onCollide(dt, spriteB, mtvX, mtvY)
  spriteB:onCollide(dt, spriteA, mtvX, mtvY)
end

function World:pressedKey(key)
  self._keysPressed[key] = true
end

function World:releasedKey(key)
  self._keysPressed[key] = nil
end

function World:keysPressed()
  return self._keysPressed
end

return {
  World = World,
}
