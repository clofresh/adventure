local anim8 = require 'anim8'
local HC = require 'lib/HardonCollider'

local player, Collider, dummy, sprites
sprites = {}

function initSprite(image, startPos, startDir, startState, startAnimation, animation, updateFunc, drawFunc)
  return {
    image = image,
    pos = startPos,
    direction = startDir,
    currentState = startState,
    currentAnimation = startAnimation,
    animation = animation,
    update = updateFunc,
    draw = drawFunc,
  }
end

function onCollide(dt, shapeA, shapeB)
  local p, d
  if shapeA == dummy then
    d = shapeA
  elseif shapeA == player.attackRegion then
    p = shapeA
  end

  if shapeB == dummy then
    d = shapeB
  elseif shapeB == player.attackRegion then
    p = shapeB
  end

  if d then
    d:move(1, 0)
  end
end

function love.load()
  local alex, ryan
  alex = love.graphics.newImage('rivercityransom_alex_sheet.png')
  ryan = love.graphics.newImage('rivercityransom_ryan_sheet.png')
  sprites.alex = {image=alex}
  local g = anim8.newGrid(40, 40, alex:getWidth(), alex:getHeight())
  sprites.alex.animation = {
      idle = anim8.newAnimation('once', g('1,1'), 0.1),
      walking = anim8.newAnimation('loop', g('2-3,1'), 0.1),
      punching = anim8.newAnimation('once', g('1-3,2'), 0.1),
      uppercutting = anim8.newAnimation('once', g('7-9,2'), 0.1, {0.2, 0.1, 0.2}),
      sidekicking = anim8.newAnimation('once', g('1-3,3'), 0.1),
      highkicking = anim8.newAnimation('once', g('1-4,3'), 0.1),
    }
  sprites.ryan = {image=ryan}
  local g = anim8.newGrid(40, 40, ryan:getWidth(), ryan:getHeight())
  sprites.ryan.animation = {
      idle = anim8.newAnimation('once', g('1,1'), 0.1),
      walking = anim8.newAnimation('loop', g('2-3,1'), 0.1),
      punching = anim8.newAnimation('once', g('1-3,2'), 0.1),
      uppercutting = anim8.newAnimation('once', g('7-9,2'), 0.1, {0.2, 0.1, 0.2}),
      sidekicking = anim8.newAnimation('once', g('1-3,3'), 0.1),
      highkicking = anim8.newAnimation('once', g('1-4,3'), 0.1),
    }

  player = initSprite(sprites.alex.image, {x=200, y=300}, 1, 'idle',
    sprites.alex.animation.idle, sprites.alex.animation,
    function(self, dt)
      if self.currentState == 'idle' or self.currentState == 'walking' then
        if love.keyboard.isDown("u") then
          self.currentAnimation = self.animation.uppercutting:clone()
          self.currentState = 'attacking'
        elseif love.keyboard.isDown("i") then
          self.currentAnimation = self.animation.punching:clone()
          self.currentState = 'attacking'
          self.attackRegion = Collider:addCircle(self.pos.x + 24, self.pos.y + 12, 4)
        elseif love.keyboard.isDown("j") then
          self.currentAnimation = self.animation.highkicking:clone()
          self.currentState = 'attacking'
        elseif love.keyboard.isDown("k") then
          self.currentAnimation = self.animation.sidekicking:clone()
          self.currentState = 'attacking'
        else
          local pressed = false
          if love.keyboard.isDown("w") then
            self.pos.y = self.pos.y - 1
            pressed = true
          end
          if love.keyboard.isDown("s") then
            self.pos.y = self.pos.y + 1
            pressed = true
          end
          if love.keyboard.isDown("a") then
            self.pos.x = self.pos.x - 1
            pressed = true
            self.direction = -1
          end
          if love.keyboard.isDown("d") then
            self.pos.x = self.pos.x + 1
            pressed = true
            self.direction = 1
          end


          if pressed then
            self.currentAnimation = self.animation.walking
            self.currentState = 'walking'
          else
            self.currentAnimation = self.animation.idle
            self.currentState = 'idle'
          end
        end
      elseif self.currentState == 'attacking' and self.currentAnimation.status == 'finished' then
        self.currentAnimation = self.animation.idle
        self.currentState = 'idle'
        self.attackRegion = nil
      end

      self.currentAnimation:update(dt)

    end,
    function(self)
      local ox, oy
      ox, oy = 0, 0
      -- need to compensate for the image not being centered when flipping
      if self.direction == -1 then
        ox = 24
        oy = 0
      end
      self.currentAnimation:draw(self.image, self.pos.x, self.pos.y, 0, self.direction, 1, ox, oy)
      if self.attackRegion then
        self.attackRegion:draw('fill', 16)
      end
    end)
  dummy = initSprite(sprites.ryan.image, {x=400, y=300}, -1, 'idle',
    sprites.ryan.animation.idle, sprites.ryan.animation,
    function(self, dt)
    end,
    function(self)
    end)

  Collider = HC(100, onCollide)
end

function love.update(dt)
  player:update(dt)
  dummy:update(dt)
  Collider:update(dt)
end

function love.draw()
  player:draw()
  dummy:draw()
end


