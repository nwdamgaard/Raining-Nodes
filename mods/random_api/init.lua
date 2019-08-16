
Random = {
    choices = {},
    probabilities = {},
    csum = {},
    sum = 0
}

function Random:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

-- important! choose() will not work if csum is not calculated!
function Random:calc_csum()
    local sum = 0
    for i, choice in ipairs(self.choices) do
        --ensure that each choice has a probability
        if self.probabilities[choice] == nil then
            minetest.log("error", "Random API: Table does not have a probability for each choice!")
            return
        end

        --create csum
        sum = sum + self.probabilities[choice]
        self.csum[choice] = sum
    end

    if sum ~= math.floor(sum) then
        minetest.log("error", "Random API: Sum of probability table must be an integer!")
        return
    end

    self.sum = sum
end

function Random:choose()
    local r = math.random() + math.random(0, self.sum - 1) --chooses decimal between 0 and sum inclusive
    for i, choice in pairs(self.choices) do
        if r < self.csum[choice] then
            return choice
        end
    end
end

function Random:add_choice(choice, probability)
    table.insert(self.choices, choice)
    self.probabilities[choice] = probability
end