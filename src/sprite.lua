local Action = Class{function(self, duration, toExecute)
  self.duration = duration
  self.elapsed = 0
  self.toExecute = toExecute
end}

function Action:execute(dt, world)
  self.elapsed = self.elapsed + dt
  self:toExecute(dt, world)
end

local Sprite = Class{function(self, name, pos, dir, dim, animationSet)
  self.name = name
  self.pos = pos
  self.dir = dir
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
  local animationName = animationType..self.dir
  local animation = self.animationSet:getAnimation(animationName)
  if animation and self.animationSet.currentAnimation ~= animation then
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
  -- if leftToDo > 0 then
  --   util.log("%s has %d left to do", self.name, leftToDo)
  -- end
end

function Sprite:move(displacement, velocity)
  -- FIXME: Update distance to be a displacement vector, instead of a scalar,
  -- and update the pathfinding algorithm to return a list of displacement vectors
  -- instead of NSEW directions.
  local distance = displacement:len()
  if velocity == nil then
    velocity = self.velocity
  end
  local unitDisplacement = displacement:normalized()
  local action = Action(distance / velocity, function(self, dt)
    local step = (velocity * dt) * unitDisplacement
    self.sprite.pos = self.sprite.pos + step
    self.sprite:setAnimation('walking')

    if math.abs(step.x) > math.abs(step.y) then
      if step.x < 0 then
        self.sprite.dir = "W"
      else
        self.sprite.dir = "E"
      end
    else
      if step.y < 0 then
        self.sprite.dir = "N"
      else
        self.sprite.dir = "S"
      end
    end


  end)
  action.sprite = self
  return action
end

function Sprite:followPath(directions)
  for i, delta in pairs(directions) do
    table.insert(self.toDo, self:move(delta))
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
  return string.format("%s (%s; %s)", self.name, tostring(self.pos),
    self.dim:tostring())
end


-- Nadira
local Nadira = Class{inherits=Sprite, function(self, name, pos, dir, dim, animationSet)
  Sprite.construct(self, name, pos, dir, dim, animationSet)
  self.velocity = 110
end}


-- Player
local Player = Class{inherits=Sprite, function(self, name, pos, dir, dim, animationSet)
  Sprite.construct(self, name, pos, dir, dim, animationSet)
  self.velocity = 120

  self.sword = Sprite('sword', self.pos, self.dir, util.Dimensions(64, 64),
                     graphics.animations.sword)
  self.sword:setAnimation('slashing')

end}

function Player:onCollide(dt, otherSprite, mtvX, mtvY)
  if otherSprite.properties and otherSprite.properties.obstruction then
    self.pos:move(mtvX, mtvY)
  end
end

function Player:planActions(dt, world)
  local keysPressed = world:keysPressed()
  local direction = ""

  -- Don't let the actions queue get too long
  if #self.toDo > 20 then
    return
  end

  if keysPressed[" "] then
    if not world.sprites[self.sword.name] then
      self.sword.pos = self.pos - vector(32, 32)
      self.sword.dir = self.dir
      self.sword:setAnimation('slashing')
      world:register(self.sword)
    end
  else
    world:unregister(self.sword)
  end

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
    local dx, dy
    local step = 0.25

    if     direction == "N"  then dx, dy = 0, -step
    elseif direction == "NE" then dx = math.sqrt(step); dy = -dx
    elseif direction == "E"  then dx, dy = step, 0
    elseif direction == "SE" then dx = math.sqrt(step); dy = dx
    elseif direction == "S"  then dx, dy = 0, step
    elseif direction == "SW" then dx = -math.sqrt(step); dy = -dx
    elseif direction == "W"  then dx, dy = -step, 0
    elseif direction == "NW" then dx = -math.sqrt(step); dy = dx
    end
 
    table.insert(self.toDo, self:move(vector(dx, dy)))
  end
end




local exports = {
  Sprite     = Sprite,
  Player     = Player,
  Nadira     = Nadira,
}

function fromTmx(obj)
  local cls = exports[obj.type]
  local s = cls(
    obj.name,
    vector(obj.x, obj.y),
    "S",
    util.Dimensions(obj.width, obj.height),
    graphics.animations[obj.name]
  )
  util.log("Loaded %s", s:tostring())
  return s
end

exports.fromTmx = fromTmx
return exports

