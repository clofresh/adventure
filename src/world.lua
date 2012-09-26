local Class = require 'lib/hump/class'
local HC = require 'lib/HardonCollider'

World = Class{function(self)
  self.sprites = {}
  self.collider = HC(100, function(dt, shapeA, shapeB, mtvX, mtvY)
    self:onCollide(dt, shapeA, shapeB, mtvX, mtvY)
  end)

end}

function World:register(sprite)
  shape = sprite:initShape(self.collider)
  self.sprites[shape] = sprite
end

function World:update(dt)
  for shape, sprite in pairs(self.sprites) do
    sprite:update(dt)
  end
  self.collider:update(dt)
end

function World:draw()
  for shape, sprite in pairs(self.sprites) do
    sprite:draw()
  end
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
