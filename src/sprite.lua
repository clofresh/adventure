local Class = require 'lib/hump/class'

local Position = Class{function(self, x, y, dir)
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

local Dimensions = Class{function(self, w, h)
  self.w = w
  self.h = h
end}

local Sprite = Class{function(self, name, pos, dim, animationSet, state)
  self.name = name
  self.pos = pos
  self.dim = dim
  self.animationSet = animationSet
  self.state = state
end}

function Sprite:initShape(collider)
  self.shape = collider:addRectangle(self.pos.x + (self.dim.w / 2), self.pos.y + (self.dim.h / 2),
                                     self.dim.w, self.dim.h)
  return self.shape
end

function Sprite:animationFinished()
  return self.animationSet and self.animationSet:isFinished()
end

function Sprite:setAnimation(name)
  if self.animationSet then
    self.animationSet:setAnimation(name)
  end
end

function Sprite:update(dt, world)
  if self.state then
    self.state = self.state(dt, world, self)
  end
  self.shape:moveTo(self.pos.x + (self.dim.w / 2), self.pos.y + (self.dim.h / 2))
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

function Sprite:applyDamage(attacker, amount, mtvX, mtvY)
  self.pos:move(mtvX, mtvY)
end

local NPC = Class{inherits=Sprite, function(self, name, pos, dim, animationSet, state)
  Sprite.construct(self, name, pos, dim, animationSet, state)
end}

function NPC:applyDamage(attacker, amount, mtvX, mtvY)
  self.state = Sprite.Hurt
  self:setAnimation('hurt')
  Sprite.applyDamage(self, attacker, amount, mtvX, mtvY)
end

local Player = Class{inherits=Sprite, function(self, name, pos, dim, animationSet, state)
  Sprite.construct(self, name, pos, dim, animationSet, state)
end}

function Player:onCollide(dt, otherSprite, mtvX, mtvY)
  self.pos:move(mtvX, mtvY)
end

local Attack = Class{inherits=Sprite, function(self, name, pos, dim, type)
  Sprite.construct(self, name, pos, dim)
  self.type = type
end}

function Attack:onCollide(dt, otherSprite, mtvX, mtvY)
  otherSprite:applyDamage(self, 10, mtvX, mtvY)
end

function Sprite.Idle(dt, world, sprite)
  return Sprite.Idle
end

function Sprite.Hurt(dt, world, sprite)
  if sprite:animationFinished() then
    sprite:setAnimation('idle')
    return Sprite.Idle
  else
    return Sprite.Hurt
  end
end

function Player.Uppercutting(dt, world, sprite)
  local nextState
  if sprite:animationFinished() and sprite.attack then
    world:unregister(sprite.attack)
    sprite.attack = nil
    nextState = Player.Idle
    sprite:setAnimation('idle')
  else
    nextState = Player.Uppercutting
  end
  return nextState
end

function Player.Idle(dt, world, sprite)
  local keysPressed = world:keysPressed()
  local nextState = Player.Idle
  if keysPressed['u'] then
    nextState = Player.Uppercutting
    sprite:setAnimation('uppercutting')
    local attackPos = sprite.pos:clone():move(24, 12)
    local attackDim = Dimensions(4, 4)
    sprite.attack = Attack('uppercut', attackPos, attackDim, 'mid')
    world:register(sprite.attack)
  else
    local moved = false
    if keysPressed["w"] then
      sprite.pos:moveY(-2)
      moved = true
    end
    if keysPressed["s"] then
      sprite.pos:moveY(2)
      moved = true
    end
    if keysPressed["a"] then
      sprite.pos:moveX(-2)
      moved = true
    end
    if keysPressed["d"] then
      sprite.pos:moveX(2)
      moved = true
    end

    if moved then
      nextState = Player.Walking
      sprite:setAnimation('walking')
    end
  end

  return nextState
end

function Player.Walking(dt, world, sprite)
  local keysPressed = world:keysPressed()
  local moved = false
  local nextState
  if keysPressed["w"] then
    sprite.pos:moveY(-2)
    moved = true
  end
  if keysPressed["s"] then
    sprite.pos:moveY(2)
    moved = true
  end
  if keysPressed["a"] then
    sprite.pos:moveX(-2)
    moved = true
  end
  if keysPressed["d"] then
    sprite.pos:moveX(2)
    moved = true
  end

  if moved then
    nextState = Player.Walking
  else
    nextState = Player.Idle
    sprite:setAnimation('idle')
  end
  return nextState
end


return {
  Position   = Position,
  Dimensions = Dimensions,
  Sprite     = Sprite,
  Player     = Player,
  NPC        = NPC
}

