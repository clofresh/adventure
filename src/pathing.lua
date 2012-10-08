Class = require 'lib/hump/class'
local PriorityQueue = require("lib/binary_heap")

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

local PathSearch = Class{function(self, startPos, goalPos)
    self.startPos = startPos
    self.goalPos = goalPos
end}

function PathSearch:getStartState()
    return self.startPos
end

function PathSearch:isGoalState(state)
    if state == nil then
        return false
    else
        return state.x == self.goalPos.x and state.y == self.goalPos.y
    end
end

function PathSearch:getSuccessors(state)
    local unitCost = function() return 1 end
    local successors = {
        {state = {x=state.x - 1, y=state.y},
            action={dir='w', cost=unitCost}},
        {state = {x=state.x + 1, y=state.y},
            action={dir='e', cost=unitCost}},
        {state = {x=state.x, y=state.y + 1},
            action={dir='s', cost=unitCost}},
        {state = {x=state.x, y=state.y - 1},
            action={dir='n', cost=unitCost}},
    }
    for i, successor in pairs(successors) do
        if successor.state.x < 1 or successor.state.x > 1000
            or successor.state.y < 1 or successor.state.y > 1000 then
            table.remove(successors, i)
        end
    end

    return successors
end

function PathSearch:totalCost(plan)
    local c0 = plan:cost()
    local c1 = self:estimatedForwardCost(plan.state)
    return c0 + c1
end

function PathSearch:estimatedForwardCost(state)
    -- heuristic: manhattan distance from goal
    return math.abs(state.x - self.goalPos.x) + math.abs(state.y - self.goalPos.y)
end

local Plan = Class{function(self, state, actions)
    self.state = state
    if actions == nil then
        self.actions = Queue()
    else
        self.actions = actions
    end
    self._cost = nil
end}

function Plan:cost()
    if self._cost == nil then
        local totalCost = 0
        for k, action in pairs(self.actions.q) do
            totalCost = totalCost + action:cost(self.state)
        end
        self._cost = totalCost
    end
    return self._cost
end

function Plan:__tostring()
    local output = ''
    for k, action in pairs(self.actions.q) do
        output = output .. action.dir
    end
    return output
end

function Plan.compare(query, plan1, plan2)
    if     plan1 == nil and plan2 == nil then return false
    elseif plan1 == nil and plan2 ~= nil then return true
    elseif plan1 ~= nil and plan2 == nil then return false
    else return query:totalCost(plan1) < query:totalCost(plan2) end
end

function search(query)
    local n = 1
    local startTime = os.clock()

    local fringe = PriorityQueue(function(plan1, plan2)
        return Plan.compare(query, plan1, plan2)
    end)
    fringe:insert(Plan(query:getStartState()))

    local plan = {}
    local seenAlready = {}
    while not query:isGoalState(plan.state) do
        plan = fringe:pop()

        if plan == nil then
            error("Fringe is empty, but goal was never found")
        end
        -- Current state isn't the goal, add its successors to the fringe
        -- and try the next highest priority one
        for i, successor in ipairs(query:getSuccessors(plan.state)) do
            local stateKey = successor.state.x .. ',' .. successor.state.y
            if not seenAlready[stateKey] then
                local newActions = plan.actions:copy()
                newActions:push(successor.action)
                --print("adding x:"..successor.state.x..", y:"..successor.state.y)
                fringe:insert(Plan(successor.state, newActions))
                seenAlready[stateKey] = true
            end
        end
        n = n + 1
    end

    print("Found goal in "..tostring((os.clock() - startTime)*1000.0).."ms trying "..tostring(n).." states. Returning actions: "..tostring(plan))
    return plan.actions
end

function profile()
    local profiler = require "profiler"
    profiler.start('search_profile.csv')
    search(PathSearch({x=1, y=10}, {x=200, y=200}))
    profiler.stop()
end

--profile()

return {
    search     = search,
    PathSearch = PathSearch,
    profile    = profile,
}
