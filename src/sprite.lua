
local State = Class{function(self, name, updateCallback)
  self.name = name
  self.updateCallback = updateCallback
end}

function State:update(dt, world, sprite)
  return self:updateCallback(dt, world, sprite)
end

function State:transitionIn(prevState, dt, world, sprite)
  if prevState ~= self then
    local p
    if prevState then
      p = prevState:tostring()
    else
      p = 'nil'
    end

    util.log("%s: %s -> %s", sprite.name, p, self:tostring())
  end
  return self
end

function State:tostring()
  return string.format("state: %s", self.name)
end

local Sprite = Class{function(self, name, pos, dim, animationSet)
  self.name = name
  self.pos = pos
  self.dim = dim
  self.animationSet = animationSet
  self:setAnimation('idle')
  self.toDo = {} -- treat as a deque
  self.cooldown = 0
end}

function Sprite:initShape(collider)
  self.shape = collider:addRectangle(self.pos.x, self.pos.y,
                                     self.dim.w, self.dim.h)
  return self.shape
end

function Sprite:setAnimation(animationType)
  local animationName = animationType..self.pos:spriteDir()
  local animation = self.animationSet:getAnimation(animationName)
  if self.animationSet.currentAnimation ~= animation then
    self.animationSet:setAnimation(animation)
  end
end

function Sprite:animationFinished()
  return self.animation and self.animation:isFinished()
end

function Sprite:update(dt, world)
  self:planActions(dt, world)
  self:act(dt, world)
  self.shape:moveTo(self.pos.x, self.pos.y)
  if self.animationSet then
    self.animationSet:update(dt, self)
  end
end

function Sprite:planActions(dt, world)
end

function Sprite:act(dt, world)
  self.cooldown = self.cooldown - dt
  if self.cooldown < 0 then
    self.cooldown = 0
  end
  if self.cooldown == 0 then
    local action = self.toDo[1]
    if action then
      action:execute(dt, world)
      if action.elapsed > action.duration then
        table.remove(self.toDo, 1)
      end
    else
      self:idle(dt, world)
    end
  end
  local leftToDo = #self.toDo
  if leftToDo > 0 then
    util.log("%s has %d left to do", self.name, leftToDo)
  end
end

function Sprite:idle(dt, world)
  self:setAnimation('idle')
end

function Sprite:draw()
  if debugMode then
    self.shape:draw('fill')
  end
  if self.animationSet then
    self.animationSet:draw(self)
  end
end

function Sprite:onCollide(dt, otherSprite, mtvX, mtvY)
end

function Sprite:applyDamage(attacker, amount, mtvX, mtvY)
  self.pos:move(mtvX, mtvY)
end

function Sprite:tostring()
  return string.format("%s (%s; %s)", self.name, self.pos:tostring(),
    self.dim:tostring())
end


local Player = Class{inherits=Sprite, function(self, name, pos, dim, animationSet)
  Sprite.construct(self, name, pos, dim, animationSet)
  self.velocity = 120
end}

function Player:onCollide(dt, otherSprite, mtvX, mtvY)
  if otherSprite.properties and otherSprite.properties.obstruction then
    self.pos:move(mtvX, mtvY)
  end
end

local Action = Class{function(self, duration, toExecute)
  self.duration = duration
  self.elapsed = 0
  self.toExecute = toExecute
end}

function Action:execute(dt, world)
  self.elapsed = self.elapsed + dt
  self:toExecute(dt, world)
end

function Player:planActions(dt, world)
  local keysPressed = world:keysPressed()
  local direction = ""

  -- Don't let the actions queue get too long
  if #self.toDo > 20 then
    return
  end

  -- if keysPressed["1"] then
  --   local duration = 0
  --   local directions = {{"E", 50, 90}, {"N", 10, 120}}
  --   for i, direction in pairs(directions) do
  --     local action = self:move(direction[1], direction[2], direction[3])
  --     table.insert(self.toDo, action)
  --   end
  --   world:releasedKey("1")
  -- end

  if keysPressed["w"] then
    direction = direction .. "N"
  elseif keysPressed["s"] then
    direction = direction .. "S"
  end
  if keysPressed["a"] then
    direction = direction .. "W"
  elseif keysPressed["d"] then
    direction = direction .. "E"
  end

  if direction ~= "" then
    local duration = 0.01
    table.insert(self.toDo, self:move(direction, 1))
  end
end

function Player:move(direction, distance, velocity)
  if distance == nil then
    distance = 1
  end
  if velocity == nil then
    velocity = self.velocity
  end
  local action = Action(distance / velocity, function(self, dt)
    local dx, dy
    local step = velocity * dt
    if     direction == "N"  then dx, dy = 0, -step
    elseif direction == "NE" then dx = math.sqrt(step); dy = -dx
    elseif direction == "E"  then dx, dy = step, 0
    elseif direction == "SE" then dx = math.sqrt(step); dy = dx
    elseif direction == "S"  then dx, dy = 0, step
    elseif direction == "SW" then dx = -math.sqrt(step); dy = -dx
    elseif direction == "W"  then dx, dy = -step, 0
    elseif direction == "NW" then dx = -math.sqrt(step); dy = dx
    end
    if dx ~= nil and dy ~= nil then
      self.sprite.pos:move(dx, dy)
      self.sprite:setAnimation('walking')
    end
  end)
  action.sprite = self
  return action
end


function Player:followPath(directions)
  local direction = directions:pop()
  self:move(direction)

  for i, direction in pairs(directions) do
    self:move(direction)
  end
end

local exports = {
  Sprite     = Sprite,
  Player     = Player,
  Bee        = Bee,
  Nadira     = Nadira,
  State      = State,
}

function fromTmx(obj)
  local cls = exports[obj.type]
  local s = cls(
    obj.name,
    util.Position(obj.x, obj.y, obj.properties.dirX, obj.properties.dirY),
    util.Dimensions(obj.width, obj.height),
    graphics.animations[obj.name]
  )
  util.log("Loaded %s", s:tostring())
  return s
end

exports.fromTmx = fromTmx
return exports

