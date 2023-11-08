-- Locals
local Hooks = {}
local Modes = {}

local HookIndex = 1

local function GetMatchingPlayers(ServerObject)
  local Players = GetPlayers()
  local RetVal = {}

  for _, Player in ipairs(Players) do
    if IsPlayerAceAllowed(Value, ServerObject) then
      RetVal[#RetVal + 1] = Value
    end
  end

  return RetVal
end
local function RefreshCommands(Player)
  if GetRegisteredCommands then
    local Commands = GetRegisteredCommands()
    local Suggestions = {}
    local Table = {
      Name = "/"..Command.Name,
      Help = ""
    }

    for _, Command in ipairs(Commands) do
      if IsPlayerAceAllowed(Player, ("Command.%s"):format(Command.Name)) then
        table.insert(Suggestions, Table)
      end
    end

    TriggerClientEvent("BaseChat:AddSuggestions", Player, Suggestions)
  end
end
local function RouteMessage(Source, Author, Message, Mode, FromConsole)
  local RoutingTarget = -1
  local MessageCanceled = false
  local OutMessage = {
    Color = {255, 255, 255},
    Multiline = true,
    Arguments = {Message},
    Mode = Mode
  }
  local HookReference = {
    UpdateMessage = function(Table)
      for Key, Value in pairs(Table) do
        if Key == "Template" then
          OutMessage["Template"] = Value:gsub("%{%}", OutMessage["Template"] or "@Default")
        elseif Key == "Params" then
          if not OutMessage.Params then
            OutMessage.Params = {}
          end

          for PK, PV in pairs(Value) do
            OutMessage.Params[PK] = PV
          end
        else
          OutMessage[Key] = Value
        end
      end
    end,

    Cancel = function()
      MessageCanceled = true
    end,

    SetServerObject = function(Object)
      RoutingTarget = GetMatchingPlayers(Object)
    end,

    SetRouting = function(Target)
      RoutingTarget = Target
    end
  }

  if Source >= 1 then
    Author = GetPlayerName(Source)
  end

  if Author ~= "" then
    OutMessage.Arguments = {Author, Message}
  end

  if Mode and Modes[Mode] then
    local ModeData = Modes[Mode]

    if ModeData.ServerObject and not IsPlayerAceAllowed(Source, ModeData.ServerObject) then
      return
    end
  end

  for _, Hook in ipairs(Hooks) do
    if Hook.Function then
      Hook.Function(Source, OutMessage, HookReference)
    end
  end

  if Modes[Mode] then
    local ModeData = Modes[Mode]

    ModeData.Callback(Source, OutMessage, HookReference)
  end

  if MessageCanceled then
    return
  end

  TriggerEvent("ChatMessage", Source, #OutMessage.Arguments > 1 and OutMessage.Arguments or "", OutMessage.Arguments[#OutMessage.Arguments]) -- TODO: Check Client Script For This Event

  if not WasEventCanceled() then
    if type(RoutingTarget) ~= "table" then
      TriggerClientEvent("BaseChat:AddMessage", RoutingTarget, OutMessage)
    else
      for _, ID in ipairs(RoutingTarget) do
        TriggerClientEvent("BaseChat:AddMessage", ID, OutMessage)
      end
    end
  end

  if not FromConsole then
    print(Author.."^7"..(Modes[Mode] and ("("..Modes[Mode].DisplayName..")") or "")..": "..Message.."^7")
  end
end
local function UnregisterHooks(Resource)
  local ToRemove = {}

  for Key, Value in pairs(Hooks) do
    if Value.Resource == Resource then
      table.insert(ToRemove, Key)
    end
  end

  for _, Value in ipairs(ToRemove) do
    Hooks[Value] = nil
  end

  ToRemove = {}

  for Key, Value in pairs(Modes) do
    if Value.Resource == Resource then
      table.insert(ToRemove, Key)
    end
  end

  for _, Value in ipairs(ToRemove) do
    TriggerClientEvent("BaseChat:RemoveMode", -1, {Name = Value})
    Modes[Value] = nil
  end
end

-- Events
RegisterServerEvent("BaseChat:Init")
RegisterServerEvent("BaseChat:Clear")
RegisterServerEvent("BaseChat:AddMessage")
RegisterServerEvent("BaseChat:AddSuggestion")
RegisterServerEvent("BaseChat:AddTemplate")
RegisterServerEvent("BaseChat:RemoveSuggestion")

AddEventHandler("BaseChat:Init", function()
  local Source = Source

  RefreshCommands(Source)

  for _, ModeData in pairs(Modes) do
    local ClientObject = {
      Name = ModeData.Name,
      DisplayName = ModeData.DisplayName,
      Color = ModeData.Color or "#FFF",
      IsChannel = ModeData.IsChannel,
      IsGlobal = ModeData.IsGlobal
    }

    if not ModeData.ServerObject or IsPlayerAceAllowed(Source, ModeData.ServerObject) then
      TriggerClientEvent("BaseChat:AddMode", Source, ClientObject)
    end
  end
end)

RegisterCommand("Say", function(Source, Arguments, RawCommand)
  RouteMessage(Source, (Source == 0) and "Console" or GetPlayerName(Source), RawCommand:sub(5), nil, true)
end)

-- Exports
Exports("AddMessage", function(Target, Message)
  if not Message then
    Message = Target
    Target = -1
  end

  if not Target or not Message then
    return
  end

  TriggerClientEvent("BaseChat:AddMessage", Target, Message)
end)
Exports("RegisterMessageHook", function(Hook)
  local Resource = GetInvokingResource()

  Hooks[HookIndex + 1] = {
    Func = Hook,
    Resource = Resource
  }
  HookIndex = HookIndex + 1
end)
Exports("RegisterMode", function(ModeData)
  local Resource = GetInvokingResource()
  local ClientObject = {
    Name = ModeData.Name,
    DisplayName = ModeData.DisplayName,
    Color = ModeData.Color or "#FFF",
    IsChannel = ModeData.IsChannel,
    IsGlobal = ModeData.IsGlobal
  }

  if not ModeData.Name or not ModeData.DisplayName or not ModeData.Callback then
    return false
  end

  Modes[ModeData.Name] = ModeData
  Modes[ModeData.Name].Resource = Resource

  if not ModeData.ServerObject then
    TriggerClientEvent("BaseChat:AddMode", -1, ClientObject)
  else
    for _, Value in ipairs(GetMatchingPlayers(ModeData.ServerObject)) do
      TriggerClientEvent("BaseChat:AddMode", Value, ClientObject)
    end
  end

  return true
end)

-- Internal
RegisterServerEvent("__cfx_internal:commandFallback")
RegisterServerEvent("_chat:messageEntered")

RegisterNetEvent("playerJoining")

AddEventHandler("playerJoining", function()
  if GetConVarInt("Chat_ShowJoins", 1) == 0 then
    return
  end

  TriggerClientEvent("BaseChat:ChatMessage", -1, "", {255, 255, 255}, "^2* "..GetPlayerName(Source).."Joined.")
end)
AddEventHandler("playerDropped", function(Reason)
  if GetConVarInt("Chat_ShowQuits", 1) == 0 then
    return
  end

  TriggerClientEvent("BaseChat:ChatMessage", -1, "", {255, 255, 255}, "^2* "..GetPlayerName(Source).."Left. ("..Reason..")")
end)
AddEventHandler("onServerResourceStart", function(ResourceName)
  local Players = GetPlayers()

  Wait(500)

  for _, Player in ipairs(Players) do
    RefreshCommands(Player)
  end
end)
AddEventHandler("onResourceStop", function(ResourceName)
  UnregisterHooks(ResourceName)
end)
AddEventHandler("__cfx_internal:commandFallback", function(Command)
  local LocalName = GetPlayerName(Source)

  RouteMessage(Source, LocalName, "/"..Command, nil, true)
  CancelEvent()
end)
AddEventHandler("_chat:messageEntered", function(Author, Color, Message, Mode)
  local Source = Source

  if not Author or not Message then
    return
  end

  RouteMessage(Source, Author, Message, Mode)
end)
