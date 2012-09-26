debugMode = true 

local Class = require 'lib/hump/class'
local sprite = require('src/sprite')
local Sprite = sprite.Sprite
local Position = sprite.Position
local Dimensions = sprite.Dimensions
local World = require('src/world').World

local player, npc, world


function love.load()
  world = World()
  player = Player("Player", Position(100, 100, 1), Dimensions(16, 32))
  npc = Sprite("NPC", Position(100, 200, 1), Dimensions(16, 32))
  world:register(player)
  world:register(npc)
end

function love.update(dt)
  world:update(dt)
end

function love.draw()
  world:draw()
end


