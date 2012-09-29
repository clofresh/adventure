debugMode = false

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

function love.load()
  local map, music
  music = love.audio.newSource("audio/Calmtown.ogg")
  music:setLooping(true)
  love.audio.play(music)
  local sprites = {}

  graphics.load()
  map = ATL.load('maps/meadow.tmx')
  for i, obj in pairs(map("sprites").objects) do    
    table.insert(sprites, sprite.fromTmx(obj))
  end
  world = World(map, sprites)
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
