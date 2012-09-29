local Class = require 'lib/hump/class'
local anim8 = require 'lib/anim8/anim8'
local animations = {}

local AnimationSet = Class{function(self, image, animations)
  self.image = image
  self.animations = animations
  self.currentAnimation = nil
end}

function AnimationSet:setAnimation(name, retainFramePos)
  if self.animations[name] then
    local startPos
    if self.currentAnimation and retainFramePos then
      startPos = self.currentAnimation.position
    else
      startPos = 1
    end

    self.currentAnimation = self.animations[name]:clone()
    if startPos < #self.currentAnimation.frames then
      self.currentAnimation:gotoFrame(startPos)
    end
  end
end
function AnimationSet:update(dt, sprite)
  if self.currentAnimation then
    self.currentAnimation:update(dt)
  end
end
function AnimationSet:draw(sprite)
  if self.currentAnimation then
    self.currentAnimation:draw(self.image, sprite.pos.x - (sprite.dim.w / 2), sprite.pos.y - (sprite.dim.h / 2), 0, sprite.pos.dir, 1, 0, 0)
  end
end
function AnimationSet:isFinished()
  return self.currentAnimation and self.currentAnimation.status == 'finished'
end

function load()
  local player = love.graphics.newImage('maps/tilesets/astraea_walkcycle_norocket.png')
  local g = anim8.newGrid(64, 64, player:getWidth(), player:getHeight())
  animations.player = AnimationSet(player, {
    idleN = anim8.newAnimation('once', g('1,1'), 0.1),
    idleW = anim8.newAnimation('once', g('1,2'), 0.1),
    idleS = anim8.newAnimation('once', g('1,3'), 0.1),
    idleE = anim8.newAnimation('once', g('1,4'), 0.1),
    walkingN = anim8.newAnimation('loop', g('2-9,1'), 0.1),
    walkingW = anim8.newAnimation('loop', g('2-9,2'), 0.1),
    walkingS = anim8.newAnimation('loop', g('2-9,3'), 0.1),
    walkingE = anim8.newAnimation('loop', g('2-9,4'), 0.1),
    --punching = anim8.newAnimation('once', g('1-3,3'), 0.1),
    --uppercutting = anim8.newAnimation('once', g('1-3,4'), 0.1, {0.2, 0.1, 0.2}),
    -- sidekicking = anim8.newAnimation('once', g('1-3,3'), 0.1),
    -- lowkicking = anim8.newAnimation('once', g('5,3'), 0.1),
    -- crouching = anim8.newAnimation('once', g('7,1'), 0.1),
  })

  local bee = love.graphics.newImage('maps/tilesets/bee.png')
  local g = anim8.newGrid(32, 32, bee:getWidth(), bee:getHeight())
  animations.bee = AnimationSet(bee, {
    idleN = anim8.newAnimation('once', g('1-3,1'), 0.1),
    idleW = anim8.newAnimation('once', g('1-3,2'), 0.1),
    idleS = anim8.newAnimation('once', g('1-3,3'), 0.1),
    idleE = anim8.newAnimation('once', g('1-3,4'), 0.1),
    })
end

return {
  load = load,
  animations = animations,
}
