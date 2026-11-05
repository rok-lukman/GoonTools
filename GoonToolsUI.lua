local _, ns = ...

local GoonTools = LibStub("AceAddon-3.0"):GetAddon("GoonTools")


local defaults = {
    profile = {
        dingScreenshot = true,
        gratzGuild = false,
        capstoneOnly = true,
        partyInvite = true,
        guildPartyInvite = true,
        whisperInvite = true,
        guildWhisperInvite = true,
    },
}


local options = {
    type = "group",
    name = "GoonTools Configuration",
    args = {
        featuresConfig = {
            type = "group",
            name = "Features",
            inline = true,
            order = 1,
            args = {
                dingScreenshot = {
                    type = "toggle",
                    name = "Ding Screenshot",
                    desc = "Make a screenshot whenever the player reaches the next level.",
                    order = 1,

                    get = function()
                        return GoonTools:GetDingScreenshot()
                    end,

                    set = function(_, value)
                        GoonTools:SetDingScreenshot(value)
                    end,
                },
                gratzGuild = {
                    type = "toggle",
                    name = "Gratz!",
                    desc = "Welcome new guild members, congratulate members who level up and announce your own dings. Only one GoonTools user in the guild posts the welcome and gratz messages.",
                    order = 2,

                    get = function()
                        return GoonTools:GetGratzGuild()
                    end,

                    set = function(_, value)
                        GoonTools:SetGratzGuild(value)
                    end,
                },
                capstoneOnly = {
                    type = "toggle",
                    name = "Capstone levels only",
                    desc = "Only announce level ups at every 10th level (10, 20, 30, ...).",
                    order = 3,

                    disabled = function()
                        return not GoonTools:GetGratzGuild()
                    end,

                    get = function()
                        return GoonTools:GetCapstoneOnly()
                    end,

                    set = function(_, value)
                        GoonTools:SetCapstoneOnly(value)
                    end,
                },
            },
        },
        partyInviteConfig = {
            type = "group",
            name = "Party/raid invites",
            inline = true,
            order = 2,
            args = {
                partyInvite = {
                    type = "toggle",
                    name = "Party / Raid invite",
                    desc = "Automagically accept party and raid invites.",
                    order = 1,

                    get = function()
                        return GoonTools:GetPartyInvite()
                    end,

                    set = function(_, value)
                        GoonTools:SetPartyInvite(value)
                    end,
                },
                guildPartyInvite = {
                    type = "toggle",
                    name = "Guild Only",
                    desc = "Automagically accept party and raid invites sent by guild members.",
                    order = 2,

                    disabled = function()
                        return not GoonTools:GetPartyInvite()
                    end,

                    get = function()
                        return GoonTools:GetGuildPartyInvite()
                    end,

                    set = function(_, value)
                        GoonTools:SetGuildPartyInvite(value)
                    end,
                },
            },
        },
        whisperInviteConfig = {
            type = "group",
            name = "Whisper invites",
            inline = true,
            order = 3,
            args = {
                whisperInvite = {
                    type = "toggle",
                    name = "Whisper invite",
                    desc = "Invite someone who whispers a magic keyword (inv, invite).",
                    order = 1,
                    get = function()
                        return GoonTools:GetWhisperInvite()
                    end,

                    set = function(_, value)
                        GoonTools:SetWhisperInvite(value)
                    end,
                },
                guildWhisperInvite = {
                    type = "toggle",
                    name = "Guild Only",
                    desc = "Invite a guild member when they whisper a magic keyword.",
                    order = 2,

                    disabled = function()
                        return not GoonTools:GetWhisperInvite()
                    end,
                    get = function()
                        return GoonTools:GetGuildWhisperInvite()
                    end,

                    set = function(_, value)
                        GoonTools:SetGuildWhisperInvite(value)
                    end,
                },
            },
        },
    },
}


function GoonTools:GetDingScreenshot()
    return self.db.profile.dingScreenshot
end

function GoonTools:SetDingScreenshot(value)
    self.db.profile.dingScreenshot = value
end


function GoonTools:GetGratzGuild()
    return self.db.profile.gratzGuild
end

function GoonTools:SetGratzGuild(value)
    self.db.profile.gratzGuild = value
end


function GoonTools:GetCapstoneOnly()
    return self.db.profile.capstoneOnly
end

function GoonTools:SetCapstoneOnly(value)
    self.db.profile.capstoneOnly = value
end


function GoonTools:GetPartyInvite()
    return self.db.profile.partyInvite
end

function GoonTools:SetPartyInvite(value)
    self.db.profile.partyInvite = value
end

function GoonTools:GetGuildPartyInvite()
    return self.db.profile.guildPartyInvite
end

function GoonTools:SetGuildPartyInvite(value)
    self.db.profile.guildPartyInvite = value
end


function GoonTools:GetWhisperInvite()
    return self.db.profile.whisperInvite
end

function GoonTools:SetWhisperInvite(value)
    self.db.profile.whisperInvite = value
end

function GoonTools:GetGuildWhisperInvite()
    return self.db.profile.guildWhisperInvite
end

function GoonTools:SetGuildWhisperInvite(value)
    self.db.profile.guildWhisperInvite = value
end


function GoonTools:InitializeUI()
    self.db = LibStub("AceDB-3.0"):New(
        "GoonToolsDB",
        defaults
    )

    -- Older versions collected zone names here; nothing uses them.
    self.db.global.zoneNames = nil

    local AceConfig = LibStub("AceConfig-3.0")
    local AceConfigDialog = LibStub("AceConfigDialog-3.0")

    AceConfig:RegisterOptionsTable(
        "GoonTools Configuration",
        options,
        {"gtc"}
    )

    self.optionsFrame = AceConfigDialog:AddToBlizOptions(
        "GoonTools Configuration",
        "GoonTools"
    )

    self:RegisterChatCommand("gt", "HandleSlashCommand")
    self:RegisterChatCommand("ffa", "SetLootFreeForAll")
    self:RegisterChatCommand("gl", "SetLootGroupLoot")
    self:RegisterChatCommand("pl", "LeaveGroup")
end


function GoonTools:HandleSlashCommand(input)
    local command, rest = (input or ""):match("^%s*(%S*)%s*(.-)%s*$")
    command = command:lower()

    if command == "" then
        Settings.OpenToCategory(self.optionsFrame.name)
    elseif command == "names" then
        self:DumpNames()
    elseif command == "levels" then
        self:DumpLevels(rest)
    elseif command == "peers" then
        self:DumpPeers()
    else
        self:Print("Usage: /gt [names | levels [name] | peers]")
    end
end


function GoonTools:SetLootMethod(method, label)
    if not ns.IsGroupLeader() then
        self:Print("You must be the group leader to change the loot method.")

        return
    end

    if not (C_PartyInfo.SetLootMethod and method) then
        self:Print("Changing the loot method is not supported on this client.")

        return
    end

    C_PartyInfo.SetLootMethod(method)
    self:Print("Loot set to " .. label .. ".")
end


function GoonTools:SetLootFreeForAll()
    self:SetLootMethod(Enum.LootMethod and Enum.LootMethod.Freeforall, "Free For All")
end


function GoonTools:SetLootGroupLoot()
    self:SetLootMethod(Enum.LootMethod and Enum.LootMethod.GroupLoot, "Group Loot")
end


function GoonTools:LeaveGroup()
    if not IsInGroup() then
        self:Print("You are not in a group.")

        return
    end

    C_PartyInfo.LeaveParty()
end
