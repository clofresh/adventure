local anim8 = require 'lib/anim8/anim8'
local HC = require 'lib/HardonCollider'
local Camera = require 'lib/hump/camera'
local loader = require("lib/Advanced-Tiled-Loader").Loader
local debug = false 
local player, Collider, dummy, sprites, cam, world
sprites = {}

function initSprite(name, image, startPos, startDir, startState, startAnimation, animation, updateFunc, drawFunc)
  local ox, oy
  if startDir == 1 then
    ox, oy = 11, 16
  elseif startDir == -1 then
    ox, oy = -11, 16
  end
  local shape = Collider:addRectangle(startPos.x + ox, startPos.y + oy, 16, 32)
  shape.name = name
  shape.sprite =  {
    image = image,
    pos = startPos,
    direction = startDir,
    currentState = startState,
    currentAnimation = startAnimation,
    animation = animation,
    update = updateFunc,
    draw = drawFunc,
    parent = shape,
  }
  return shape
end

function onCollide(dt, shapeA, shapeB)
  if shapeA == dummy and shapeB.type then
    if (shapeB.type == 'high' and (
            shapeA.sprite.currentState == 'idle' or shapeA.sprite.currentState == 'hurt')) or
       (shapeB.type == 'mid') then
      print("hit")
      shapeA:move(1, 0)
      shapeA.sprite.pos.x = shapeA.sprite.pos.x + 1
      shapeA.sprite.currentAnimation = shapeA.sprite.animation.hurt:clone()
      shapeA.sprite.currentState = 'hurt'
    end
  end
end

function love.load()
  Collider = HC(100, onCollide)
  world = loader.load('world.tmx')

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
      crouching = anim8.newAnimation('once', g('7,1'), 0.1),
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
      crouching = anim8.newAnimation('once', g('7,1'), 0.1),
      hurt = anim8.newAnimation('once', g('3,5'), 0.1),
    }

  cam = Camera.new(980, 1260, 1, 0)
  player = initSprite("alex", sprites.alex.image, {x=980, y=1260}, 1, 'idle',
    sprites.alex.animation.idle, sprites.alex.animation,
    function(self, dt)
      if self.currentState == 'idle' or self.currentState == 'walking' then
        if love.keyboard.isDown("u") then
          self.currentAnimation = self.animation.uppercutting:clone()
          self.currentState = 'attacking'
          if self.attackRegion == nil or (self.attackRegion and self.attackRegion.name ~= 'uppercut') then
            self.attackRegion = Collider:addCircle(self.pos.x + 24, self.pos.y + 12, 4)
            self.attackRegion.type = 'mid'
            self.attackRegion.name = 'uppercut'
          end
        elseif love.keyboard.isDown("i") then
          self.currentAnimation = self.animation.punching:clone()
          self.currentState = 'attacking'
          if self.attackRegion == nil or (self.attackRegion and self.attackRegion.name ~= 'punch') then
            self.attackRegion = Collider:addCircle(self.pos.x + 24, self.pos.y + 12, 4)
            self.attackRegion.type = 'high'
            self.attackRegion.name = 'punch'
          end
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
        if self.attackRegion then
          Collider:remove(self.attackRegion)
          self.attackRegion = nil
        end
      end

      self.currentAnimation:update(dt)
      self.parent:moveTo(self.pos.x + 11 , self.pos.y + 16)
      cam.x = self.pos.x
      cam.y = self.pos.y
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
      if self.attackRegion and debug then
        self.attackRegion:draw('fill', 16)
      end
    end)
  dummy = initSprite("ryan", sprites.ryan.image, {x=1080, y=1260}, -1, 'idle',
    sprites.ryan.animation.idle, sprites.ryan.animation,
    function(self, dt)
      if self.currentState == 'idle' and math.random(1, 10) == 1 then
        self.currentAnimation = self.animation.crouching
        self.currentState = 'crouching'
      elseif self.currentState == 'crouching' and math.random(1, 50) == 1 then
        self.currentAnimation = self.animation.idle
        self.currentState = 'idle'
      elseif self.currentState == 'hurt' and self.currentAnimation.status == 'finished' then
        self.currentAnimation = self.animation.idle
        self.currentState = 'idle'
      end
      self.currentAnimation:update(dt)
      self.parent:moveTo(self.pos.x - 11, self.pos.y + 16)
    end,
    function(self)
      self.currentAnimation:draw(self.image, self.pos.x, self.pos.y, 0, self.direction, 1, ox, oy)
    end)

end

function love.update(dt)
  player.sprite:update(dt)
  dummy.sprite:update(dt)
  Collider:update(dt)
end

function love.draw()
  cam:draw(function()
    world:draw()
    if debug then
      player:draw('fill')
      dummy:draw('fill')
    end
    player.sprite:draw()
    dummy.sprite:draw()
  end)
  love.graphics.print("Adventure game", 0, 0)
  love.graphics.print(string.format("(%d, %d)", cam.x, cam.y), 700, 0)
end


