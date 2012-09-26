local Camera = require 'lib/hump/camera'
local Class = require 'lib/hump/class'
local HC = require 'lib/HardonCollider'

World = Class{function(self, map)
  self.map = map
  self.sprites = {}
  self.collider = HC(100, function(dt, shapeA, shapeB, mtvX, mtvY)
    self:onCollide(dt, shapeA, shapeB, mtvX, mtvY)
  end)
  self.cam = Camera.new(980, 1260, 1, 0)
  self.focus = nil
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
  for shape, sprite in pairs(self.sprites) do
    sprite:update(dt, self)
  end
  if self.focus then
    self.cam.x = self.focus.pos.x
    self.cam.y = self.focus.pos.y
  end
  self.collider:update(dt)
end

function World:draw()
  self.cam:draw(function()
    self.map:draw()
    for shape, sprite in pairs(self.sprites) do
      sprite:draw()
    end
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

return {
  World = World,
}
