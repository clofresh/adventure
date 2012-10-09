local vector = require 'lib/hump/vector-light'

local Position = Class{function(self, x, y, dirX, dirY)
  self.x = x
  self.y = y
  self.dirX = dirX
  self.dirY = dirY
end}

function Position:move(x, y)
  self.x = self.x + x
  self.y = self.y + y
  self.dirX, self.dirY = vector.normalize(x, y)
  return self
end

function Position:spriteDir()
  local dir
  if math.abs(self.dirX) > math.abs(self.dirY) then
    if self.dirX < 0 then
      dir = "W"
    else
      dir = "E"
    end
  else
    if self.dirY < 0 then
      dir = "N"
    else
      dir = "S"
    end
  end
  return dir
end

function Position:clone()
  return Position(self.x, self.y, self.dirX, self.dirY)
end

function Position:tostring()
  return string.format("x: %d, y: %d, dx: %d, dy: %d", self.x, self.y,
                        self.dirX, self.dirY)
end

local Dimensions = Class{function(self, w, h)
  self.w = w
  self.h = h
end}

function Dimensions:tostring()
  return string.format("w: %d, h: %d", self.w, self.h)
end

local Queue = Class{function(self, initial)
    if initial == nil then
        self.q = {}
    else
        self.q = initial
    end
end}

function Queue:push(item)
    table.insert(self.q, item)
end

function Queue:pop()
    return table.remove(self.q, 1)
end

function Queue:extend(items)
  for k, val in pairs(items) do
    table.insert(self.q, item)
  end
end

function Queue:__tostring()
    local output = ''
    for i, val in ipairs(self.q) do
        output = output .. tostring(val)
    end
    return output
end

function Queue:copy()
    local q = {}
    for k, val in pairs(self.q) do
        q[k] = val
    end
    return Queue(q)
end
function log(msg, ...)
  print(os.date("%Y-%m-%dT%I:%M:%S%p") .. " - " .. string.format(msg, ...))
end

return {
  Position = Position,
  Dimensions = Dimensions,
  log = log,
  Queue = Queue,
}
