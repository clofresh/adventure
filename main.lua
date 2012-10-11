debugMode = false
math.randomseed(1)

-- Global imports
Class = require('lib/hump/class')
graphics = require('src/graphics')
util = require('src/util')

local ATL = require("lib/Advanced-Tiled-Loader").Loader
local World = require('src/world').World

local world

function love.load()
  graphics.load()
  local map = ATL.load('maps/meadow.tmx')
  world = World(map)
  local player = world.sprites.player
  player:followPath(world:findPath(player.pos, vector(world.triggers.goal.x, world.triggers.goal.y)))
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
