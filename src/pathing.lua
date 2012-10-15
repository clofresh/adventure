local PriorityQueue = require("lib/binary_heap")

local PathSearch = Class{function(self, startPos, goal, world)
    self.startPos = startPos
    self.goal = goal
    goal.pos = util.getCenter(goal)

    self.goalNavpoly = world.navlookup[world:vectorToTileNum(goal.pos)]
    self.world = world
end}

function PathSearch:getStartState()
    return self.startPos
end

function PathSearch:isGoalState(state)
    if state == nil then
        return false
    else
        return state == self.goal.pos
    end
end

function PathSearch:getSuccessors(state)
    -- given an (x, y) position, state
    -- figure out what tile number that is
    -- look up the tile number in world.navlookup to get the nav poly
    -- successor states are polygon.vetexes
    -- successor actions are the difference between the vertex and the (x,y)
    -- the cost is the len of the difference
    local tileVector = self.world:posVectorToTileVector(state)
    local tileNum = tileVector.y * self.world.map.width + tileVector.x

    local successors = {}
    local navpoly = self.world.navlookup[tileNum]
    if navpoly == nil then
        return successors
    end
    log("%s is in navpoly %d", tostring(tileVector), navpoly.object.name)
    for i, neighborName in pairs(navpoly.neighbors) do
        log("navpoly %d, neighbor %d", navpoly.object.name, neighborName)
        local neighbor = self.world.navmesh[neighborName]

        if neighbor.object.name == self.goalNavpoly.object.name then
            log("Adding goal.pos %s to successors", tostring(self.goal.pos))
            local delta = self.goal.pos - state
            table.insert(successors, {
                state = self.goal.pos,
                action = delta,
                cost = delta:len()
            })
        end
        for j, vertex in pairs(neighbor.vertexes) do
            local delta = vertex - state
            table.insert(successors, {
                state = vertex,
                action = delta,
                cost = delta:len()
            })
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
    -- heuristic: euclidean distance from goal
    return self.goal.pos:dist(state)
end

local Plan = Class{function(self, state, actions)
    self.state = state
    if actions == nil then
        self.actions = util.Queue()
    else
        self.actions = actions
    end
    self._cost = nil
end}

function Plan:cost()
    if self._cost == nil then
        local totalCost = 0
        for k, action in pairs(self.actions.q) do
            totalCost = totalCost + action:len()
        end
        self._cost = totalCost
    end
    return self._cost
end

function Plan:__tostring()
    local output = ''
    for k, action in pairs(self.actions.q) do
        output = output .. tostring(action)
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
        if     plan1 == nil and plan2 == nil then return false
        elseif plan1 == nil and plan2 ~= nil then return true
        elseif plan1 ~= nil and plan2 == nil then return false
        else return query:totalCost(plan1) < query:totalCost(plan2) end
    end)
    fringe:insert(Plan(query:getStartState()))

    local plan = {}
    local seenAlready = {}
    while not query:isGoalState(plan.state) do
        plan = fringe:pop()
        local stateKey = plan.state.x .. ',' .. plan.state.y
        while seenAlready[stateKey] do
            plan = fringe:pop()
            stateKey = plan.state.x .. ',' .. plan.state.y
        end
        seenAlready[stateKey] = true

        log("[%d] Expanding %s", n, tostring(query.world:posVectorToTileVector(plan.state)))

        if plan == nil then
            error("Fringe is empty, but goal was never found")
        end
        -- Current state isn't the goal, add its successors to the fringe
        -- and try the next highest priority one
        for i, successor in ipairs(query:getSuccessors(plan.state)) do
            local newActions = plan.actions:copy()
            newActions:push(successor.action)
            log("[%d] adding %s", n, tostring(query.world:posVectorToTileVector(successor.state)))
            fringe:insert(Plan(successor.state, newActions))
        end
        n = n + 1
    end

    print("Found goal in "..tostring((os.clock() - startTime)*1000.0).."ms trying "..tostring(n).." states. Returning actions: "..tostring(plan))
    return plan.actions.q
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
