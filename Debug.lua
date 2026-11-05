local _, ns = ...

local GoonTools = LibStub("AceAddon-3.0"):GetAddon("GoonTools")


-- /gt names
function GoonTools:DumpNames()
    for guid, member in pairs(self.guildMembers) do
        if member.online then
            self:Print(guid .. " " .. tostring(member.name))
        end
    end
end


-- /gt levels [name]   (no name: all online members)
function GoonTools:DumpLevels(value)
    value = (value or ""):lower()

    for guid, member in pairs(self.guildMembers) do
        local name = tostring(member.name)
        local matches = name:lower() == value or tostring(ns.ShortName(member.name)):lower() == value

        if matches or (value == "" and member.online) then
            self:Print(name .. " " .. guid .. " " .. member.level)
        end
    end
end


-- /gt peers
function GoonTools:DumpPeers()
    for guid in pairs(self.peers) do
        local member = self.guildMembers[guid]
        self:Print(guid .. " " .. tostring(member and member.name) .. (member and member.online and "" or " (offline)"))
    end

    self:Print("Announcer: " .. (self:IsAnnouncer() and "you" or "someone else"))
end
