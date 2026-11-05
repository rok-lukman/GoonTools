local _, ns = ...

local GoonTools = LibStub("AceAddon-3.0"):GetAddon("GoonTools")


function GoonTools:OnEnable()
    self.playerGUID = UnitGUID("player")

    self:RegisterEvent("PLAYER_GUILD_UPDATE")
    self:RegisterEvent("GUILD_ROSTER_UPDATE")
    self:RegisterEvent("PARTY_INVITE_REQUEST")
    self:RegisterEvent("CHAT_MSG_WHISPER")
    self:RegisterEvent("PLAYER_LEVEL_UP")

    self:RegisterComm(ns.COMM_PREFIX, "OnGoonToolsComm")

    -- Nothing fills the roster at login unless someone asks for it.
    if IsInGuild() then
        self:RequestGuildRoster()
    end
end


function GoonTools:PLAYER_LEVEL_UP()
    if not self:GetDingScreenshot() then
        return
    end

    -- Two seconds seems to capture the level up banner!
    C_Timer.After(2, function()
        Screenshot()
    end)
end


function GoonTools:PARTY_INVITE_REQUEST(_, _, _, _, _, _, _, inviterGUID)
    if not self:GetPartyInvite() then
        return
    end

    if self:GetGuildPartyInvite() then
        if not inviterGUID or ns.IsSecret(inviterGUID) or not IsGuildMember(inviterGUID) then
            return
        end
    end

    AcceptGroup()

    -- Mark the popup accepted first, or hiding it declines the invite.
    local popup = StaticPopup_FindVisible and StaticPopup_FindVisible("PARTY_INVITE")

    if popup then
        popup.inviteAccepted = 1
    end

    StaticPopup_Hide("PARTY_INVITE")
end


function GoonTools:CHAT_MSG_WHISPER(_, text, playerName, _, _, _, _, _, _, _, _, _, guid)
    if not self:GetWhisperInvite() then
        return
    end

    if ns.IsSecret(text, playerName, guid) or ns.IsRestricted() then
        return
    end

    if guid == self.playerGUID then
        return
    end

    if self:GetGuildWhisperInvite() and not (guid and IsGuildMember(guid)) then
        return
    end

    if not self.inviteKeywords[ns.GetKeyword(text)] then
        return
    end

    if not ns.CanInvite() then
        return
    end

    C_PartyInfo.InviteUnit(playerName)
end


function GoonTools:PLAYER_GUILD_UPDATE(_, unit)
    if unit and unit ~= "player" then
        return
    end

    if not IsInGuild() then
        self:ResetGuildState()

        return
    end

    -- Switched guilds: forget the old roster so the new one isn't "welcomed".
    local guildName = GetGuildInfo("player")

    if guildName and self.guildName and guildName ~= self.guildName then
        self:ResetGuildState()
    end

    if not self.rosterInitialized then
        self:RequestGuildRoster()
    end
end


function GoonTools:GUILD_ROSTER_UPDATE()
    if not IsInGuild() or ns.IsRestricted() then
        return
    end

    if self.rosterInitialized then
        self:UpdateGuildRoster()
    else
        self:InitializeRoster()
    end
end
