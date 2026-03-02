local ADDON_NAME, ns = ...

local frame = CreateFrame("Frame")
local Print = function(msg)
    DEFAULT_CHAT_FRAME:AddMessage("|cFF33FF99VenthyrMirrorGroups:|r " .. msg)
end


local RevendrethZoneID = "#1525"
local data = {
    ["Group1"] = {
        "29.49, 37.26 1 Room with Cooking Pot",
        "27.15, 21.63 1 Room with Elite Spider",
        "40.41, 73.34 1 Inside House with Sleeping Wildlife"
    },
    ["Group2"] = {
        "39.09, 52.18 2 Room on Ground Floor",
        "58.80, 67.80 2 Inside House with Stonevigil",
        "70.97, 43.63 2 Room with Disciples"
    },
    ["Group3"] = {
        "72.60, 43.65 3 Inside Crypt with Disciples",
        "40.30, 77.16 3 Inside House with Wildlife",
        "77.17, 65.43 3 Inside House with several Elite Mobs"
    },
    ["Group4"] = {
        "29.60, 25.89 4 Room with Elite Soulbinder",
        "20.75, 54.26 4 Inside Villa at Entrance",
        "55.12, 35.67 4 Inside Crypt with Nobles"
    }
}
local ActiveMirrorGroup = nil

local MarkMap = function(groupID)
    local group = data[groupID]
    if not group then
        Print("Invalid group ID: " .. tostring(groupID))
        return
    end
    
    for _, entry in ipairs(group) do
        SlashCmdList["TOMTOM_WAY"](RevendrethZoneID .. " " .. entry)
    end
end

local function FindActiveMirrorGroup()
    local quests = {61879, 61883, 61885, 61886}
    for g,n in pairs(quests) do
        C_QuestLog.RemoveWorldQuestWatch(n) 
        WorldQuestAdded = C_QuestLog.AddWorldQuestWatch(n) 
        WorldQuestCompleted = C_QuestLog.IsQuestFlaggedCompleted(n) 
        if WorldQuestAdded or WorldQuestCompleted then 
            Print("\124cff00FE00Mirror Group " .. g .. " active\124r") 
            ActiveMirrorGroup = g
            MarkMap("Group" .. g)
        end 
    end
end

-- Slash command handler
local function SlashHandler(msg)
    local args = {}
    for word in msg:gmatch("%S+") do
        table.insert(args, word)
    end
    
    local cmd = args[1] and args[1]:lower() or ""

    if cmd ~= "" then
        MarkMap("Group" .. cmd)
    elseif cmd == "help" then
        Print("Usage: /mg [group number]")
        Print("Example: /mg 1 - Marks locations for Group 1")
    elseif cmd == "check" then
        FindActiveMirrorGroup()
    else
        FindActiveMirrorGroup()
    end
end

-- Event handler
local function OnEvent(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == ADDON_NAME then
        -- Register slash commands
        SLASH_VMG1 = "/vmg"
        SlashCmdList["VMG"] = SlashHandler
        
        Print("Loaded. Type /vmg help for commands.")
        
        frame:UnregisterEvent("ADDON_LOADED")        
    end
end

-- Register events
frame:RegisterEvent("ADDON_LOADED")
frame:SetScript("OnEvent", OnEvent)
