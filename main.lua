debugMode = true 

local ATL = require("lib/Advanced-Tiled-Loader").Loader
local Class = require 'lib/hump/class'

local sprite = require('src/sprite')
local Sprite = sprite.Sprite
local Position = sprite.Position
local Dimensions = sprite.Dimensions
local World = require('src/world').World
local graphics = require('src/graphics')

local player, npc, world

function love.load()
  graphics.load()
  world = World(ATL.load('world.tmx'))
  player = Player("Player", Position(100, 100, 1), Dimensions(16, 32), graphics.animations.alex, 'idle')
  player:setState('idle')
  npc = Sprite("NPC", Position(100, 200, 1), Dimensions(16, 32), graphics.animations.ryan, 'idle')
  world:register(player)
  world:register(npc)
  world:focusOn(player)
end

function love.update(dt)
  world:update(dt)
end

function love.draw()
  world:draw()
end


