local Class = require 'lib/hump/class'
local vector = require 'lib/hump/vector-light'
local graphics = require('src/graphics')

local Position = Class{function(self, x, y, dirX, dirY)
  self.x = x
  self.y = y
  self.dirX = dirX
  self.dirY = dirY
end}

function Position:move(x, y)
  self.x = self.x + x
  self.y = self.y + y
  self.dirX, self.dirY = vector.normalize(x, y)
  return self
end

function Position:spriteDir()
  local dir
  if math.abs(self.dirX) > math.abs(self.dirY) then
    if self.dirX < 0 then
      dir = "W"
    else
      dir = "E"
    end
  else
    if self.dirY < 0 then
      dir = "N"
    else
      dir = "S"
    end
  end
  return dir
end

function Position:clone()
  return Position(self.x, self.y, self.dirX, self.dirY)
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

function Sprite:setAnimation(name, retainFramePos)
  if self.animationSet then
    self.animationSet:setAnimation(name, retainFramePos)
  end
end

function Sprite:update(dt, world)
  if self.state then
    self.state = self.state(dt, world, self)
  end
  self.shape:moveTo(self.pos.x + 32, self.pos.y + 40)
  if self.animationSet then
    self.animationSet:update(dt, self)
  end
end

function Sprite:draw()
  if debugMode then
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

local Bee = Class{inherits=Sprite, function(self, name, pos, dim, animationSet, state)
  Sprite.construct(self, name, pos, dim, animationSet, state)
end}

function Bee:applyDamage(attacker, amount, mtvX, mtvY)
  self.state = Sprite.Hurt
  self:setAnimation('hurt')
  Sprite.applyDamage(self, attacker, amount, mtvX, mtvY)
end

function Bee.Idle(dt, world, sprite)
  if sprite:animationFinished() or not sprite.animationSet.currentAnimation then
    sprite:setAnimation('idle'..sprite.pos:spriteDir(), false)
  end
  return Bee.Idle
end

local Player = Class{inherits=Sprite, function(self, name, pos, dim, animationSet, state)
  Sprite.construct(self, name, pos, dim, animationSet, state)
end}

function Player:onCollide(dt, otherSprite, mtvX, mtvY)
  self.pos:move(mtvX, mtvY)
  if otherSprite.properties and otherSprite.properties.obstruction then
    self.pos:move(-2.0 * mtvX, -2.0 * mtvY)
  end
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
  sprite:setAnimation('idle'..sprite.pos:spriteDir(), false)
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
    local dx, dy
    dx, dy = 0, 0
    if keysPressed["w"] then
      dy = -2
      moved = true
    elseif keysPressed["s"] then
      dy = 2
      moved = true
    end
    if keysPressed["a"] then
      dx = -2
      moved = true
    elseif keysPressed["d"] then
      dx = 2
      moved = true
    end


    if moved then
      sprite.pos:move(dx, dy)
      nextState = Player.Walking
      sprite:setAnimation('walking'..sprite.pos:spriteDir(), false)
    end
  end

  return nextState
end

function Player.Walking(dt, world, sprite)
  prevSpriteDir = sprite.pos:spriteDir()
  local keysPressed = world:keysPressed()
  local moved = false
  local nextState
  local dx, dy
  dx, dy = 0, 0
  if keysPressed["w"] then
    dy = -2
    moved = true
  elseif keysPressed["s"] then
    dy = 2
    moved = true
  end
  if keysPressed["a"] then
    dx = -2
    moved = true
  elseif keysPressed["d"] then
    dx = 2
    moved = true
  end


  if moved then
    sprite.pos:move(dx, dy)
    nextState = Player.Walking
    local newSpriteDir = sprite.pos:spriteDir()
    if prevSpriteDir ~= newSpriteDir then
      sprite:setAnimation('walking'..newSpriteDir, true)
    end
  else
    nextState = Player.Idle
    sprite:setAnimation('idle'..sprite.pos:spriteDir(), false)
  end
  return nextState
end

local exports = {
  Position   = Position,
  Dimensions = Dimensions,
  Sprite     = Sprite,
  Player     = Player,
  Bee        = Bee,
}

function fromTmx(obj)
  print("Loading " .. obj.type)
  local cls = exports[obj.type]
  return cls(
    obj.name,
    Position(obj.x, obj.y, obj.properties.dirX, obj.properties.dirY),
    Dimensions(obj.width, obj.height),
    graphics.animations[obj.properties.animationSet],
    cls[obj.properties.state]
  )
end

exports.fromTmx = fromTmx
return exports

