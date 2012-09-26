local Class = require 'lib/hump/class'
local anim8 = require 'lib/anim8/anim8'
local animations = {}

function load()
  local alex = love.graphics.newImage('rivercityransom_alex_sheet.png')
  local g = anim8.newGrid(40, 40, alex:getWidth(), alex:getHeight())
  animations.alex = AnimationSet(alex, {
    idle = anim8.newAnimation('once', g('1,1'), 0.1),
    walking = anim8.newAnimation('loop', g('2-3,1'), 0.1),
    punching = anim8.newAnimation('once', g('1-3,2'), 0.1),
    uppercutting = anim8.newAnimation('once', g('7-9,2'), 0.1, {0.2, 0.1, 0.2}),
    sidekicking = anim8.newAnimation('once', g('1-3,3'), 0.1),
    lowkicking = anim8.newAnimation('once', g('5,3'), 0.1),
    crouching = anim8.newAnimation('once', g('7,1'), 0.1),
  })

  local ryan = love.graphics.newImage('rivercityransom_ryan_sheet.png')
  local g = anim8.newGrid(40, 40, ryan:getWidth(), ryan:getHeight())
  animations.ryan = AnimationSet(ryan, {
      idle = anim8.newAnimation('once', g('1,1'), 0.1),
      walking = anim8.newAnimation('loop', g('2-3,1'), 0.1),
      punching = anim8.newAnimation('once', g('1-3,2'), 0.1),
      uppercutting = anim8.newAnimation('once', g('7-9,2'), 0.1, {0.2, 0.1, 0.2}),
      sidekicking = anim8.newAnimation('once', g('1-3,3'), 0.1),
      highkicking = anim8.newAnimation('once', g('1-4,3'), 0.1),
      crouching = anim8.newAnimation('once', g('7,1'), 0.1),
      hurt = anim8.newAnimation('once', g('3,5'), 0.1),
    })
end

AnimationSet = Class{function(self, image, animations)
  self.image = image
  self.animations = animations
  self.currentAnimation = nil
end}

function AnimationSet:setAnimation(name)
  self.currentAnimation = self.animations[name]:clone()
end
function AnimationSet:update(dt, sprite)
  self.currentAnimation:update(dt)
end
function AnimationSet:draw(sprite)
  self.currentAnimation:draw(self.image, sprite.pos.x, sprite.pos.y, 0, sprite.pos.dir, 1, 0, 0)
end
function AnimationSet:isFinished()
  return self.currentAnimation and self.currentAnimation.status == 'finished'
end

return {
  load = load,
  animations = animations,
}
