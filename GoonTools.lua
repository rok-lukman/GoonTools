local _, ns = ...

local GoonTools = LibStub("AceAddon-3.0"):NewAddon(
    "GoonTools",
    "AceConsole-3.0",
    "AceEvent-3.0",
    "AceComm-3.0"
)

ns.GoonTools = GoonTools


ns.COMM_PREFIX = "GT_REG"

-- More unknown members than this in one roster update means a resync
-- (partial roster, guild change), not people joining: don't welcome them.
local MAX_JOIN_ANNOUNCEMENTS = 2

-- With "Capstone levels only" on, only these levels are announced.
local CAPSTONE_INTERVAL = 10


GoonTools.inviteKeywords = {
    inv = true,
    invite = true,
}


GoonTools.guildMessages = {
    joined = {
        "%n just joined the guild!",
        "%n has joined the guild!",
        "%n welcome to the guild!",
        "Welcome to the guild %n!",
        "Everyone say hello to our newest member %n!",
    },

    levelUp = {
        "Gratz %n on level %l!",
        "%n just reached level %l!",
        "Congratulations to %n for reaching level %l!",
        "A warm applause for %n who just leveled up to %l!",
        "A small celebration for %n who just dinged %l!",
    },
}


GoonTools.playerGUID = nil


function GoonTools:OnInitialize()
    self:InitializeUI()
    self:ResetGuildState()
end


function GoonTools:ResetGuildState()
    self.guildMembers = {}
    self.peers = {}            -- GUIDs of guild members running GoonTools
    self.rosterInitialized = false
    self.guildName = nil
    self.helloSent = false
end


function GoonTools:RequestGuildRoster()
    if C_GuildInfo and C_GuildInfo.GuildRoster then
        C_GuildInfo.GuildRoster()
    elseif GuildRoster then
        GuildRoster()
    end
end


function GoonTools:SendGuildMessage(message)
    if not message or message == "" then
        return
    end

    local send = (C_ChatInfo and C_ChatInfo.SendChatMessage) or SendChatMessage
    send(message, "GUILD")
end


function GoonTools:RandomMessage(category, values)
    local options = self.guildMessages[category]

    if not options or #options == 0 then
        return nil
    end

    return ns.FormatMessage(options[math.random(#options)], values)
end


local function ForEachGuildMember(callback)
    local numMembers = GetNumGuildMembers() or 0

    for i = 1, numMembers do
        local name, _, _, level, _, zone, _, _, isOnline, _, _, _, _, _, _, _, guid = GetGuildRosterInfo(i)

        if guid and name and level and level > 0 then
            callback(guid, name, level, zone, isOnline)
        end
    end

    return numMembers
end


function GoonTools:InitializeRoster()
    local numMembers = ForEachGuildMember(function(guid, name, level, zone, isOnline)
        self.guildMembers[guid] = ns.CreateGuildMember(isOnline, name, level, zone)
    end)

    -- The roster is empty until the server has sent it; wait for the next update.
    if numMembers == 0 then
        return
    end

    self.rosterInitialized = true
    self.guildName = GetGuildInfo("player")

    self:SendHello()
end


function GoonTools:UpdateGuildRoster()
    local joined, dinged = {}, {}
    local ownLevel

    ForEachGuildMember(function(guid, name, level, zone, isOnline)
        local member = self.guildMembers[guid]

        if not member then
            self.guildMembers[guid] = ns.CreateGuildMember(isOnline, name, level, zone)
            joined[#joined + 1] = name

            return
        end

        member.name = name
        member.zone = zone
        member.online = isOnline

        if level > member.level then
            member.level = level

            if not self:IsAnnouncedLevel(level) then
                return
            end

            if guid == self.playerGUID then
                ownLevel = level
            elseif isOnline then
                dinged[#dinged + 1] = { n = ns.ShortName(name), l = level }
            end
        end
    end)

    self.guildName = self.guildName or GetGuildInfo("player")

    if not self:GetGratzGuild() then
        return
    end

    -- Everyone announces their own ding.
    if ownLevel then
        self:SendGuildMessage("Ding, level " .. ownLevel .. "!")
    end

    -- Only one GoonTools user in the guild welcomes and congratulates others.
    if not self:IsAnnouncer() then
        return
    end

    if #joined <= MAX_JOIN_ANNOUNCEMENTS then
        for _, name in ipairs(joined) do
            self:SendGuildMessage(self:RandomMessage("joined", { n = ns.ShortName(name) }))
        end
    end

    for _, values in ipairs(dinged) do
        self:SendGuildMessage(self:RandomMessage("levelUp", values))
    end
end


function GoonTools:IsAnnouncedLevel(level)
    return not self:GetCapstoneOnly() or level % CAPSTONE_INTERVAL == 0
end


-- The online GoonTools user with the lowest GUID is the announcer, so only
-- one "Gratz" is posted per level up however many members run the addon.
function GoonTools:IsAnnouncer()
    local lowest = self.playerGUID

    if not lowest then
        return false
    end

    for guid in pairs(self.peers) do
        local member = self.guildMembers[guid]

        if member and member.online and guid < lowest then
            lowest = guid
        end
    end

    return lowest == self.playerGUID
end


-- Addon presence protocol (guild addon channel, prefix GT_REG):
--   HELLO:<guid>  sent once when our roster is loaded
--   HI:<guid>     reply to a HELLO, so the newcomer learns about us
function GoonTools:SendHello()
    if self.helloSent or not self.playerGUID then
        return
    end

    self.helloSent = true
    self:SendCommMessage(ns.COMM_PREFIX, "HELLO:" .. self.playerGUID, "GUILD")
end


function GoonTools:ScheduleHi()
    if self.hiPending then
        return
    end

    -- Random delay so a burst of HELLOs is answered with a single HI.
    self.hiPending = true

    C_Timer.After(1 + math.random() * 4, function()
        self.hiPending = false

        if IsInGuild() and self.playerGUID then
            self:SendCommMessage(ns.COMM_PREFIX, "HI:" .. self.playerGUID, "GUILD")
        end
    end)
end


function GoonTools:OnGoonToolsComm(_, message, distribution)
    if ns.IsSecret(message, distribution) then
        return
    end

    if distribution ~= "GUILD" or type(message) ~= "string" or not self.rosterInitialized then
        return
    end

    local kind, guid = message:match("^(%u+):(Player%-[%w%-]+)$")

    if not kind then
        -- 0.0.3 broadcast a bare GUID
        guid = message:match("^Player%-[%w%-]+$")
        kind = "HI"
    end

    if not guid or guid == self.playerGUID then
        return
    end

    local member = self.guildMembers[guid]

    if not member then
        return
    end

    self.peers[guid] = true
    member.addon = true

    if kind == "HELLO" then
        self:ScheduleHi()
    end
end
