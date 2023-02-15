_, CraftSim = ...

---@class CraftSim.CraftResult
---@field recipeID number
---@field recipeName number
---@field profit number
---@field expectedAverageProfit number
---@field expectedAverageSavedCosts number
---@field craftResultItems CraftSim.CraftResultItem[]
---@field expectedQuality number
---@field craftingChance number
---@field triggeredInspiration boolean
---@field triggeredMulticraft boolean
---@field triggeredResourcefulness boolean
---@field savedReagents CraftSim.CraftResultSavedReagent[]

CraftSim.CraftResult = CraftSim.Object:extend()

---@param craftingItemResultData CraftingItemResultData[]
function CraftSim.CraftResult:new(recipeData, craftingItemResultData)
    self.craftResultItems = {}
    self.savedReagents = {}
    self.expectedQuality = recipeData.resultData.expectedQuality
    self.triggeredInspiration = false
    self.triggeredMulticraft = false
    self.triggeredResourcefulness = false

    for _, craftingItemResult in pairs(craftingItemResultData) do
        
        if craftingItemResult.isCrit then
            self.triggeredInspiration = true
        end
        
        if craftingItemResult.multicraft and craftingItemResult.multicraft > 0 then
            self.triggeredMulticraft = true
        end
        
        table.insert(self.craftResultItems, CraftSim.CraftResultItem(craftingItemResult.hyperlink, craftingItemResult.quantity, craftingItemResult.multicraft, craftingItemResult.craftingQuality))
    end

    -- just take resourcefulness from the first craftResult
    -- this is because of a blizzard bug where the same proc is listed in every craft result
    if craftingItemResultData[1].resourcesReturned then
        self.triggeredResourcefulness = true
        for _, craftingResourceReturnInfo in pairs(craftingItemResultData[1].resourcesReturned) do
            table.insert(self.savedReagents, CraftSim.CraftResultSavedReagent(recipeData, craftingResourceReturnInfo.itemID, craftingResourceReturnInfo.quantity))
        end
    end

    local inspChance = ((recipeData.supportsCraftingStats and recipeData.supportsInspiration) and recipeData.professionStats.inspiration:GetPercent(true)) or 1
    local mcChance = ((recipeData.supportsCraftingStats and recipeData.supportsMulticraft) and recipeData.professionStats.multicraft:GetPercent(true)) or 1
    local resChance = ((recipeData.supportsCraftingStats and recipeData.supportsResourcefulness) and recipeData.professionStats.resourcefulness:GetPercent(true)) or 1
    
    self.expectedAverageSavedCosts = (recipeData.supportsCraftingStats and CraftSim.CALC:getResourcefulnessSavedCostsOOP(recipeData)*resChance) or 0

    if inspChance < 1 then
        inspChance = (self.triggeredInspiration and inspChance) or (1-inspChance)
    end

    if mcChance < 1 then
        mcChance = (self.triggeredMulticraft and mcChance) or (1-mcChance)
    end

    local totalResChance = 1
    local numProcced = #self.savedReagents
    if resChance < 1 and self.triggeredResourcefulness then
        totalResChance = resChance ^ numProcced
    elseif resChance < 1 then
        totalResChance = (1-resChance) ^ numProcced
    end

    self.craftingChance = inspChance*mcChance*totalResChance

    local craftProfit = CraftSim.CRAFT_RESULTS:GetProfitForCraftOOP(recipeData, self) 

    self.profit = craftProfit
    self.expectedAverageProfit = CraftSim.CALC:GetMeanProfitOOP(recipeData)
end

function CraftSim.CraftResult:Debug()
    local debugLines = {
        "profit: " .. CraftSim.UTIL:FormatMoney(self.profit, true),
        "expectedAverageProfit: " .. CraftSim.UTIL:FormatMoney(self.expectedAverageProfit, true),
        "expectedAverageSavedCosts: " .. CraftSim.UTIL:FormatMoney(self.expectedAverageSavedCosts, true),
        "expectedQuality: " .. tostring(self.expectedQuality),
        "craftingChance: " .. tostring((self.craftingChance or 0)*100) .. "%",
        "triggeredInspiration: " .. tostring(self.triggeredInspiration),
        "triggeredMulticraft: " .. tostring(self.triggeredMulticraft),
        "triggeredResourcefulness: " .. tostring(self.triggeredResourcefulness),
    }
    if #self.craftResultItems > 0 then
        table.insert(debugLines, "Items:")
        table.foreach(self.craftResultItems, function (_, resultItem)
            local lines = resultItem:Debug()
            lines = CraftSim.UTIL:Map(lines, function (line) return "-" .. line end)
            debugLines = CraftSim.UTIL:Concat({debugLines, lines})
        end)
    end

    if #self.savedReagents > 0 then
        table.insert(debugLines, "SavedReagents:")
        table.foreach(self.savedReagents, function (_, savedReagent)
            local lines = savedReagent:Debug()
            lines = CraftSim.UTIL:Map(lines, function (line) return "-" .. line end)
            debugLines = CraftSim.UTIL:Concat({debugLines, lines})
        end)
    end
    

    return debugLines
end