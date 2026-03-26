local ADDON_NAME, ns = ...

local REVENDRETH_ZONE_ID = 1525

local function DebugPrint(...)
    if VenthyrMirrorGroups_DB.debugMode then
        print("|cffb48ef7[VenthyrMirrorGroups]|r", ...)
    end
end

local Print = function(msg)
    DEFAULT_CHAT_FRAME:AddMessage("|cFF33FF99VenthyrMirrorGroups:|r " .. msg)
end

local function InitDB()
    if VenthyrMirrorGroups_DB == nil then
        VenthyrMirrorGroups_DB = {
            debugMode = false,
            enableNonVenthyr = false,
            enableBelowTransport3 = false,
            showUnavailableMirrors = true,
        }
    end
end
InitDB()

local function CreateSettingsPanel()
    -- Settings panel
    local panel = CreateFrame("Frame", "VenthyrMirrorGroupsSettingsPanel")
    panel.name = "Venthyr Mirror Groups"

    local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText("Venthyr Mirror Groups")

    local desc = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    desc:SetPoint("TOPLEFT", transportCheckbox, "BOTTOMLEFT", 0, -12)
    desc:SetWidth(400)
    desc:SetText("These options allow the addon to run even when normal Venthyr requirements are not met.")

    -- Checkbox for enabling functionality when not Venthyr
    local nonVenthyrCheckbox = CreateFrame("CheckButton", nil, panel, "InterfaceOptionsCheckButtonTemplate")

    nonVenthyrCheckbox:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -16)
    nonVenthyrCheckbox.Text:SetText("Enable when not Venthyr")

    nonVenthyrCheckbox:SetChecked(VenthyrMirrorGroups_DB.enableNonVenthyr)

    nonVenthyrCheckbox:SetScript("OnClick", function(self)
        VenthyrMirrorGroups_DB.enableNonVenthyr = self:GetChecked()
    end)

    -- Checkbox for enabling functionality when Transport Network is below level 3
    local transportCheckbox = CreateFrame("CheckButton", nil, panel, "InterfaceOptionsCheckButtonTemplate")

    transportCheckbox:SetPoint("TOPLEFT", nonVenthyrCheckbox, "BOTTOMLEFT", 0, -8)
    transportCheckbox.Text:SetText("Enable when Transport Network is below level 3")

    transportCheckbox:SetChecked(VenthyrMirrorGroups_DB.enableBelowTransport3)

    transportCheckbox:SetScript("OnClick", function(self)
        VenthyrMirrorGroups_DB.enableBelowTransport3 = self:GetChecked()
    end)

    -- Checkbox for showing unavailable mirrors on the map
    local unavailableCheckbox = CreateFrame("CheckButton", nil, panel, "InterfaceOptionsCheckButtonTemplate")

    unavailableCheckbox:SetPoint("TOPLEFT", debugCheckbox, "BOTTOMLEFT", 0, -8)
    unavailableCheckbox.Text:SetText("Show Unavailable Mirrors")

    unavailableCheckbox:SetChecked(VenthyrMirrorGroups_DB.showUnavailableMirrors)

    unavailableCheckbox:SetScript("OnClick", function(self)
        VenthyrMirrorGroups_DB.showUnavailableMirrors = self:GetChecked()
    end)

    -- Checkbox for enabling debug mode
    local debugCheckbox = CreateFrame("CheckButton", nil, panel, "InterfaceOptionsCheckButtonTemplate")

    debugCheckbox:SetPoint("TOPLEFT", transportCheckbox, "BOTTOMLEFT", 0, -16)
    debugCheckbox.Text:SetText("Enable Debug Mode")

    debugCheckbox:SetChecked(VenthyrMirrorGroups_DB.debugMode)

    debugCheckbox:SetScript("OnClick", function(self)
        VenthyrMirrorGroups_DB.debugMode = self:GetChecked()
    end)

    -- Register the settings panel
    local category = Settings.RegisterCanvasLayoutCategory(panel, "Venthyr Mirror Groups")
    Settings.RegisterAddOnCategory(category)
end



-- -------------------------------------------------------------

local frame = CreateFrame("Frame")

local data = {
    ["Group1"] = {
        "29.49 37.26 1 Room with Cooking Pot",
        "27.15 21.63 1 Room with Elite Spider",
        "40.41 73.34 1 Inside House with Sleeping Wildlife"
    },
    ["Group2"] = {
        "39.09 52.18 2 Room on Ground Floor",
        "58.80 67.80 2 Inside House with Stonevigil",
        "70.97 43.63 2 Room with Disciples"
    },
    ["Group3"] = {
        "72.60 43.65 3 Inside Crypt with Disciples",
        "40.30 77.16 3 Inside House with Wildlife",
        "77.17 65.43 3 Inside House with several Elite Mobs"
    },
    ["Group4"] = {
        "29.60 25.89 4 Room with Elite Soulbinder",
        "20.75 54.26 4 Inside Villa at Entrance",
        "55.12 35.67 4 Inside Crypt with Nobles"
    }
}
local ActiveMirrorGroup = nil

-- /way reset #1525 40.30 77.16 3 Inside House with Wildlife

local MarkMap = function(groupID)
    local group = data[groupID]
    if not group then
        Print("Invalid group ID: " .. tostring(groupID))
        return
    end
    
    for _, entry in ipairs(group) do
        SlashCmdList["TOMTOM_WAY"]("#" .. REVENDRETH_ZONE_ID .. " " .. entry)
    end
end

local function ClearMap()
    SlashCmdList["TOMTOM_WAY"]("reset #" .. REVENDRETH_ZONE_ID)
end

local function FindActiveMirrorGroup()
    local quests = {61879, 61883, 61885, 61886}
    for g,n in pairs(quests) do
        C_QuestLog.RemoveWorldQuestWatch(n) 
        WorldQuestAdded = C_QuestLog.AddWorldQuestWatch(n) 
        WorldQuestCompleted = C_QuestLog.IsQuestFlaggedCompleted(n) 
        if WorldQuestAdded or WorldQuestCompleted then 
            ActiveMirrorGroup = g
            Print("\124cff00FE00Mirror Group " .. g .. " active\124r")
            return ActiveMirrorGroup
        end 
    end
end

local function FindAndMarkActiveMirrorGroup()
    local activeMirrorGroup = FindActiveMirrorGroup()
    MarkMap("Group" .. activeMirrorGroup)
    if not ActiveMirrorGroup then
        Print("No active mirror group found.")
    end
end

local function IsVenthyr()
    local covenantID = C_Covenants.GetActiveCovenantID()
    return covenantID == Enum.CovenantType.Venthyr
end

local function GetTransportLevel()
    local trees = C_Garrison.GetTalentTrees()
    if not trees then return 0 end

    for _, tree in ipairs(trees) do
        if tree.treeType == Enum.GarrisonTalentTreeType.Transport then
            return tree.talentTier or 0
        end
    end

    return 0
end

local function AutomaticMarking()

    -- Default is to only run when Venthyr and Transport Network 3 are active, but allow overrides in settings
    local isVenthyr = IsVenthyr()

    if not isVenthyr and not VenthyrMirrorGroups_DB.enableNonVenthyr then
        DebugPrint("Not in Venthyr covenant. Addon functionality disabled. Enable 'Enable when not Venthyr' in settings to override.")
        return
    end

    if isVenthyr and not VenthyrMirrorGroups_DB.enableBelowTransport3 then
        local transportLevel = GetTransportLevel()
        if transportLevel < 3 then
            DebugPrint("Transport Network level is below 3. Addon functionality disabled. Enable 'Enable when Transport Network is below level 3' in settings to override.")
            return
        end
    end

    -- Clear any existing waypoints in Revendreth to avoid confusion
    ClearMap()
    FindAndMarkActiveMirrorGroup()
end

-- Event Functions

local function OnZoneChange()
    local currentZoneID = C_Map.GetBestMapForUnit("player")
    if currentZoneID == REVENDRETH_ZONE_ID then -- Revendreth Zone ID
        AutomaticMarking()
    end
end

-- Slash command handler
local function SlashHandler(msg)
    local args = {}
    for word in msg:gmatch("%S+") do
        table.insert(args, word)
    end
    
    local cmd = args[1] and args[1]:lower() or ""

    if cmd == "1" or cmd == "2" or cmd == "3" or cmd == "4" then
        MarkMap("Group" .. cmd)
    elseif cmd == "all" then
        for i = 1, 4 do
            MarkMap("Group" .. i)
        end
    elseif cmd == "clear" then
        ClearMap()
    else
        FindAndMarkActiveMirrorGroup()
    end
end

-- Event handler
local function OnEvent(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == ADDON_NAME then
        
        DebugPrint("Addon loaded, initializing...")

        -- Register slash commands
        SLASH_VMG1 = "/vmg"
        SlashCmdList["VMG"] = SlashHandler
        
        Print("Usage:")
        Print("    /vmg - Mark active mirror group on the map.")
        Print("    /vmg [1-4] - Mark specific mirror groups on the map.")
        Print("    /vmg all - Mark all mirror groups on the map.")
        Print("    /vmg clear - Clear all mirror group waypoints from the map.")
        Print("Change automatic marking behavior in the settings panel.")
        
        CreateSettingsPanel()

        AutomaticMarking()
        
        frame:UnregisterEvent("ADDON_LOADED")
    elseif event == "ZONE_CHANGED_NEW_AREA" then
        DebugPrint("Zone changed, checking for Revendreth...")
        OnZoneChange()
    end
end

-- Register events
frame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
frame:RegisterEvent("ADDON_LOADED")
frame:SetScript("OnEvent", OnEvent)
