local Camera = require 'lib/hump/camera'
local Class = require 'lib/hump/class'
local HC = require 'lib/HardonCollider'

local World = Class{function(self, map)
  self.collider = HC(100, function(dt, shapeA, shapeB, mtvX, mtvY)
    self:onCollide(dt, shapeA, shapeB, mtvX, mtvY)
  end)
  self.sprites = {}

  -- prepare the map object
  map.drawObjects = false
  map:newCustomLayer("sprites", 4, {
    update = function(layer, dt)
      for shape, sprite in pairs(self.sprites) do
        sprite:update(dt, self)
      end
    end,
    draw = function(layer)
      for shape, sprite in pairs(self.sprites) do
        sprite:draw()
      end
    end
  })
  local shape
  for i, obj in pairs( map("trees").objects ) do
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
  self.focus = nil
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
  self.cam:draw(function()
    self.map:draw()
  end)
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
