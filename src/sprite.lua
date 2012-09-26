local Class = require 'lib/hump/class'

Position = Class{function(self, x, y, dir)
  self.x = x
  self.y = y
  self.dir = dir
end}

function Position:moveX(x)
  self.x = self.x + x
  return self
end
function Position:moveY(y)
  self.y = self.y + y
  return self
end
function Position:move(x, y)
  self:moveX(x)
  self:moveY(y)
  return self
end

function Position:clone()
  return Position(self.x, self.y, self.dir)
end

Dimensions = Class{function(self, w, h)
  self.w = w
  self.h = h
end}

Sprite = Class{function(self, name, pos, dim, animationSet, state)
  self.name = name
  self.pos = pos
  self.dim = dim
  self.animationSet = animationSet
  self:setState(state)
end}

function Sprite:initShape(collider)
  self.shape = collider:addRectangle(self.pos.x, self.pos.y,
                                     self.dim.w, self.dim.h)
  return self.shape
end

function Sprite:setState(state)
  self.state = state
  if self.animationSet then
    self.animationSet:setAnimation(state)
  end
end

function Sprite:animationFinished()
  return self.animationSet and self.animationSet:isFinished()
end

function Sprite:update(dt, world)
  if self:animationFinished() then
    self:setState('idle')
  end
  self.shape:moveTo(self.pos.x, self.pos.y)
  if self.animationSet then
    self.animationSet:update(dt, self)
  end
end

function Sprite:draw()
  if debug then
    self.shape:draw('fill')
  end
  if self.animationSet then
    self.animationSet:draw(self)
  end
end

function Sprite:onCollide(dt, otherSprite, mtvX, mtvY)
end

Player = Class{inherits=Sprite, function(self, name, pos, dim, animationSet, state)
  Sprite.construct(self, name, pos, dim, animationSet, state)
end}

function Player:update(dt, world)
  if self.state == 'idle' or self.state == 'walking' then
    if love.keyboard.isDown('u') then
      self:setState('uppercutting')
      local attackPos = self.pos:clone():move(24, 12)
      local attackDim = Dimensions(4, 4)
      self.attack = Attack('uppercut', attackPos, attackDim, 'mid')
      world:register(self.attack)
    else
      local moved = false
      if love.keyboard.isDown("w") then
        self.pos:moveY(-2)
        moved = true
      end
      if love.keyboard.isDown("s") then
        self.pos:moveY(2)
        moved = true
      end
      if love.keyboard.isDown("a") then
        self.pos:moveX(-2)
        moved = true
      end
      if love.keyboard.isDown("d") then
        self.pos:moveX(2)
        moved = true
      end

      if moved and self.state ~= 'walking' then
        self:setState('walking')
      elseif not moved and self.state == 'walking' then
        self:setState('idle')
      end
    end
  elseif self:animationFinished() then
    if self.attack then
      world:unregister(self.attack)
      self.attack = nil
    end
  end

  Sprite.update(self, dt)
end

function Player:onCollide(dt, otherSprite, mtvX, mtvY)
  self.pos:move(mtvX, mtvY)
end

Attack = Class{inherits=Sprite, function(self, name, pos, dim, type)
  Sprite.construct(self, name, pos, dim)
  self.type = type
end}

function Attack:onCollide(dt, otherSprite, mtvX, mtvY)
  otherSprite.pos:move(mtvX, mtvY)
  otherSprite:setState('hurt')
end

return {
  Position   = Position,
  Dimensions = Dimensions,
  Sprite     = Sprite,
}

