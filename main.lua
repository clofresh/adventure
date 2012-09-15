local anim8 = require 'anim8'
local HC = require 'lib/HardonCollider'

local image, animation, player, Collider, dummy

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
  Collider = HC(100, onCollide)
  image = love.graphics.newImage('rivercityransom_alex_sheet.png')
  local g = anim8.newGrid(40, 40, image:getWidth(), image:getHeight())
  player = {
    animation = {
      idle = anim8.newAnimation('once', g('1,1'), 0.1),
      walking = anim8.newAnimation('loop', g('2-3,1'), 0.1),
      punching = anim8.newAnimation('once', g('1-3,2'), 0.1),
      uppercutting = anim8.newAnimation('once', g('7-9,2'), 0.1, {0.2, 0.1, 0.2}),
      sidekicking = anim8.newAnimation('once', g('1-3,3'), 0.1),
      highkicking = anim8.newAnimation('once', g('1-4,3'), 0.1),
    },
    pos = {x=100, y=200},
    direction = 1,
    currentState = 'idle'
  }
  player.currentAnimation = player.animation.idle
  dummy = Collider:addRectangle(200, 200, 100, 100)
end

function love.update(dt)
  if player.currentState == 'idle' or player.currentState == 'walking' then
    if love.keyboard.isDown("u") then
      player.currentAnimation = player.animation.uppercutting:clone()
      player.currentState = 'attacking'
    elseif love.keyboard.isDown("i") then
      player.currentAnimation = player.animation.punching:clone()
      player.currentState = 'attacking'
      player.attackRegion = Collider:addCircle(player.pos.x + 24, player.pos.y + 12, 4)
    elseif love.keyboard.isDown("j") then
      player.currentAnimation = player.animation.highkicking:clone()
      player.currentState = 'attacking'
    elseif love.keyboard.isDown("k") then
      player.currentAnimation = player.animation.sidekicking:clone()
      player.currentState = 'attacking'
    else
      local pressed = false
      if love.keyboard.isDown("w") then
        player.pos.y = player.pos.y - 1
        pressed = true
      end
      if love.keyboard.isDown("s") then
        player.pos.y = player.pos.y + 1
        pressed = true
      end
      if love.keyboard.isDown("a") then
        player.pos.x = player.pos.x - 1
        pressed = true
        player.direction = -1
      end
      if love.keyboard.isDown("d") then
        player.pos.x = player.pos.x + 1
        pressed = true
        player.direction = 1
      end


      if pressed then
        player.currentAnimation = player.animation.walking
        player.currentState = 'walking'
      else
        player.currentAnimation = player.animation.idle
        player.currentState = 'idle'
      end
    end
  elseif player.currentState == 'attacking' and player.currentAnimation.status == 'finished' then
    player.currentAnimation = player.animation.idle
    player.currentState = 'idle'
    player.attackRegion = nil
  end

  player.currentAnimation:update(dt)
  Collider:update(dt)
end

function love.draw()
  local ox, oy
  ox, oy = 0, 0
  -- need to compensate for the image not being centered when flipping
  if player.direction == -1 then
    ox = 24
    oy = 0
  end
  player.currentAnimation:draw(image, player.pos.x, player.pos.y, 0, player.direction, 1, ox, oy)
  if player.attackRegion then
    player.attackRegion:draw('fill', 16)
  end
  dummy:draw('fill')
end


