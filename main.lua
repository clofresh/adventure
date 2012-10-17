debugMode = false
math.randomseed(1)

-- Global imports
Class = require('lib/hump/class')
graphics = require('src/graphics')
util = require('src/util')

local World = require('src/world').World

local world

function love.load()
  graphics.load()
  world = World.fromTmx('maps/meadow.tmx')
  local nadira = world.sprites.nadira
  local e = util.getCenter(world.triggers.eastexit) - vector(nadira.dim.w / 2, nadira.dim.h / 2)
  local w = util.getCenter(world.triggers.westexit) - vector(nadira.dim.w / 2, nadira.dim.h / 2)
  local n = util.getCenter(world.triggers.northexit) - vector(nadira.dim.w / 2, nadira.dim.h / 2)

  local goWest
  local goEast = function(self, dt, world)
    if #self.toDo == 0 then
      log("Going to east exit")
      self:followPath(world:findPath(self, e))
      self.planActions = goWest
    end
  end
  goWest = function(self, dt, world)
    if #self.toDo == 0 then
      log("Going to west exit")
      self:followPath(world:findPath(self, w))
      self.planActions = goEast
    end
  end
  nadira.planActions = goEast
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
