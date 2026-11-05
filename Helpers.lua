local _, ns = ...


-- issecretvalue only exists on clients with the 12.x "secret values" system.
local issecretvalue = issecretvalue or function()
    return false
end


function ns.IsSecret(...)
    for i = 1, select("#", ...) do
        if issecretvalue((select(i, ...))) then
            return true
        end
    end

    return false
end


function ns.IsRestricted()
    local inInstance, instanceType = IsInInstance()
    local isPvP = inInstance and instanceType == "pvp"

    return IsEncounterInProgress() or isPvP
end


function ns.GetKeyword(message)
    if type(message) ~= "string" then
        return nil
    end

    return message:lower():match("^%s*(.-)%s*$")
end


-- Drop the realm suffix where the client adds one.
function ns.ShortName(name)
    if Ambiguate and name then
        return Ambiguate(name, "guild")
    end

    return name
end


function ns.CreateGuildMember(isOnline, name, level, zone)
    return {
        online = isOnline,
        name = name,
        level = level,
        zone = zone,
        addon = false,
    }
end


-- Replaces %n, %l, ... with values.n, values.l, ...; unknown keys are left as is.
function ns.FormatMessage(template, values)
    return (template:gsub("%%([a-z])", function(key)
        local value = values[key]

        if value == nil then
            return "%" .. key
        end

        return tostring(value)
    end))
end


function ns.IsGroupLeader()
    return IsInGroup() and UnitIsGroupLeader("player")
end


function ns.CanInvite()
    if not IsInGroup() then
        return true
    end

    return UnitIsGroupLeader("player") or (IsInRaid() and UnitIsGroupAssistant("player"))
end
