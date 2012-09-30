debugMode = false
math.randomseed(1)

local ATL = require("lib/Advanced-Tiled-Loader").Loader
local Class = require 'lib/hump/class'

local sprite = require('src/sprite')
local Sprite = sprite.Sprite
local Position = sprite.Position
local Dimensions = sprite.Dimensions
local Player = sprite.Player
local NPC = sprite.NPC
local World = require('src/world').World
local graphics = require('src/graphics')

local world

function log(msg, ...)
  print(os.date("%Y-%m-%dT%I:%M:%S%p") .. " - " .. string.format(msg, ...))
end

function love.load()
  local map, music
  music = love.audio.newSource("audio/Calmtown.ogg")
  music:setLooping(true)
  love.audio.play(music)
  local sprites = {}
  local triggers = {
    start = function(self, dt, otherSprite, mtvX, mtvY, world)
      log("Starting")
      world:unregister(self)
      local nadira = world:findSprite('nadira')
      local player = world:findSprite('player')
      nadira.state = nadira.Casting:transitionIn(nadira.state, 0, world, nadira)
      world.keyInputEnabled = false
      player.state = sprite.State("DoStuff", function(self, dt, world, sprite)
        local nextState = self
        self.elapsedTime = self.elapsedTime + dt
        if self.elapsedTime > 3.0 then
          log("Done")
          nextState = sprite.Idle
        world.keyInputEnabled = true
        elseif self.elapsedTime > 1.0 then
          log("Doing stuff: %f", dt)
          player.Walking:transitionIn(self, dt, world, sprite, 0, -1)
          player.Walking:update(dt, world, sprite)
        end
        return nextState:transitionIn(self, dt, world, sprite)
      end)
      player.state.elapsedTime = 0.0
    end
  }

  graphics.load()
  map = ATL.load('maps/meadow.tmx')
  for i, obj in pairs(map("sprites").objects) do    
    table.insert(sprites, sprite.fromTmx(obj))
  end
  world = World(map, sprites, triggers)
  --player = Player("Player", Position(200, 100, 0, 1), Dimensions(32, 48), graphics.animations.alex, Player.Idle)
  --player:setAnimation('idleS')
  --npc = NPC("NPC", Position(100, 200, 1), Dimensions(16, 32), graphics.animations.ryan, Sprite.Idle)
  --npc:setAnimation('idle')
  --world:register(npc)
  --world:focusOn(player)
end

function love.update(dt)
  world:update(dt)
end

function love.draw()
  world:draw()
end

function love.keypressed(key, unicode)
  world:pressedKey(key)
end

function love.keyreleased(key)
  world:releasedKey(key)
end
