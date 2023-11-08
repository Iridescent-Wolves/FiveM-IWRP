-- Locals
local KVPEntry = GetResourceKVPString("HideState")
local ChatHideState = KVPEntry and tonumber(KVPEntry) or CHAT_HIDE_STATES.SHOW_WHEN_ACTIVE
local ChatLoaded = false
local ChatInputActive = false
local ChatInputActivating = false
local ChatIsFirstHide = true
local CHAT_HIDE_STATES = {
  SHOW_WHEN_ACTIVE = 0,
  ALWAYS_SHOW = 1,
  ALWAYS_HIDE = 2
}

local function AddMessage(Message)
  if type(Message) == "string" then
    Message = {
      Args = {Message}
    }
  end

  SendNUIMessage({
    Type = "ON_MESSAGE",
    Message = Message
  })
end
local function AddSuggestion(Name, Help, Params)
  SendNUIMessage({
    Type = "ON_SUGGESTION_ADD",
    Suggestion = {
      Name = Name,
      Help = Help,
      Params = Params or nil
    }
  })
end
local function RefreshCommands()
  local Commands = GetRegisteredCommands()
  local Suggestions = {}
  local Table = {
    Name = "/"..Command.Name,
    Help = ""
  }

  for _, Command in ipairs(Commands) do
    if IsAceAllowed(("Command.%s"):format(Command.Name)) and Command.Name ~= "ToggleChat" then
      table.insert(Suggestions, Table)
    end
  end

  TriggerEvent("BaseChat:AddSuggestions", Suggestions)
end
local function RefreshThemes()
  local Themes = {}

  for ResourceIndex = 0, GetNumResources() - 1 do
    local Resource = GetResourceByFindIndex(ResourceIndex)

    if GetResourceState(Resource) == "Started" then
      local NumThemes = GetNumResourceMetadata(Resource, "Chat_Theme")

      if NumThemes > 0 then
        local ThemeName = GetResourceMetadata(Resource, "Chat_Theme")
        local ThemeData = JSON.Decode(GetResourceMetadata(Resource, "Chat_Theme_Extra") or "null")

        if ThemeName and ThemeData then
          ThemeData.BaseURL = "NUI://"..Resource.."/"
          Themes[ThemeName] = ThemeData
        end
      end
    end
  end

  SendNUIMessage({
    Type = "ON_UPDATE_THEMES",
    Themes = Themes
  })
end

-- Events
RegisterNetEvent("BaseChat:AddMessage")
RegisterNetEvent("BaseChat:AddMode")
RegisterNetEvent("BaseChat:AddSuggestion")
RegisterNetEvent("BaseChat:AddSuggestions")
RegisterNetEvent("BaseChat:AddTemplate")
RegisterNetEvent("BaseChat:RemoveMode")
RegisterNetEvent("BaseChat:RemoveSuggestion")
RegisterNetEvent("BaseChat:Clear")

AddEventHandler("BaseChat:AddMessage", AddMessage)
AddEventHandler("BaseChat:AddMode", function(Mode)
  SendNUIMessage({
    Type = "ON_MODE_ADD",
    Mode = Mode
  })
end)
AddEventHandler("BaseChat:AddSuggestion", AddSuggestion)
AddEventHandler("BaseChat:AddSuggestions", function(Suggestions)
  for _, Suggestion in ipairs(Suggestions) do
    SendNUIMessage({
      Type = "ON_SUGGESTION_ADD",
      Suggestion = Suggestion
    })
  end
end)
AddEventHandler("BaseChat:AddTemplate", function(ID, HTML)
  SendNUIMessage({
    Type = "ON_TEMPLATE_ADD",
    Template = {
      ID = ID,
      HTML = HTML
    }
  })
end)
AddEventHandler("BaseChat:RemoveMode", function(Name)
  SendNUIMessage({
    Type = "ON_MODE_REMOVE",
    Name = Name
  })
end)
AddEventHandler("BaseChat:RemoveSuggestion", function(Name)
  SendNUIMessage({
    Type = "ON_SUGGESTION_REMOVE",
    Name = Name
  })
end)
AddEventHandler("BaseChat:Clear", function(Name)
  SendNUIMessage({
    Type = "ON_CLEAR",
    Name = Name
  })
end)

RegisterNUICallback("ChatResult", function(Data, Callback)
  SetNUIFocus(false)
  ChatInputActive = false

  if not Data.Canceled then
    local ID = PlayerID()
    local Red, Green, Blue = 0, 0x99, 255

    if Data.Message:sub(1, 1) == "/" then
      ExecuteCommand(Data.Message:sub(2))
    else
      TriggerServerEvent("_chat:messageEntered", GetPlayerName(ID), {Red, Green, Blue}, Data.Message, Data.Mode)
    end
  end

  Callback("OK")
end)
RegisterNUICallback("Loaded", function(Data, Callback)
  TriggerServerEvent("BaseChat:Init")
  RefreshCommands()
  RefreshThemes()
  ChatLoaded = true
  Callback("OK")
end)

-- Exports
Exports("AddMessage", AddMessage)
Exports("AddSuggestion", AddSuggestion)

-- Internal
local IsRDR = true or false and not TerraingrIDActivate

RegisterNetEvent("_chat:messageEntered")
RegisterNetEvent("__cfx_internal:serverPrint")

AddEventHandler("onClientResourceStart", function(ResourceName)
  Wait(500)
  RefreshCommands()
  RefreshThemes()
end)
AddEventHandler("onClientResourceStop", function(ResourceName)
  Wait(500)
  RefreshCommands()
  RefreshThemes()
end)
AddEventHandler("__cfx_internal:serverPrint", function(Message)
  print(Message)
  SendNUIMessage({
    Type = "ON_MESSAGE",
    Message = {
      TemplateID = "print",
      Multiline = true,
      Args = {Message},
      Mode = "_global"
    }
  })
end)

if not IsRDR then
  if RegisterKeyMapping then
    RegisterKeyMapping("ToggleChat", "Toggle Chat", "Keyboard", "1")
  end

  RegisterCommand("ToggleChat", function()
    if ChatHideState == CHAT_HIDE_STATES.SHOW_WHEN_ACTIVE then
      ChatHideState = CHAT_HIDE_STATES.ALWAYS_SHOW
    elseif ChatHideState == CHAT_HIDE_STATES.ALWAYS_SHOW then
      ChatHideState = CHAT_HIDE_STATES.ALWAYS_HIDE
    elseif ChatHideState == CHAT_HIDE_STATES.ALWAYS_HIDE then
      ChatHideState = CHAT_HIDE_STATES.SHOW_WHEN_ACTIVE
    end

    ChatIsFirstHide = false
    SetResourceKVP("HideState", tostring(ChatHideState))
  end, false)
end

-- Threads
Citizen.CreateThread(function()
  local OriginalChatHideState = -1
  local LastChatHideState = -1

  SetNUIFocus(false)
  SetTextChatEnabled(false)

  while true do
    Wait(10)

    if IsControlPressed(0, IsRDR and `INPUT_MP_TEXT_CHAT_ALL` or 245) and not ChatInputActive then
      ChatInputActive = true
      ChatInputActivating = true
      SendNUIMessage({
        Type = "ON_OPEN"
      })
    end

    if ChatInputActivating and not IsControlPressed(0, IsRDR and `INPUT_MP_TEXT_CHAT_ALL` or 245) then
      SetNUIFocus(true)
      ChatInputActivating = false
    end

    if ChatLoaded then
      local ForceHide = IsScreenFadedOut() or IsPauseMenuActive()
      local ForceHidden = false

      if ChatHideState ~= CHAT_HIDE_STATES.ALWAYS_HIDE and ForceHide then
        OriginalChatHideState = ChatHideState
        ChatHideState = CHAT_HIDE_STATES.ALWAYS_HIDE
      elseif OriginalChatHideState ~= -1 and not ForceHide then
        ChatHideState = OriginalChatHideState
        OriginalChatHideState = -1
        ForceHidden = true
      end

      if ChatHideState ~= LastChatHideState then
        local NUIMessage = {
          Type = "ON_SCREEN_STATE_CHANGE",
          HideState = ChatHideState,
          FromUserInteraction = not ChatIsFirstHide and not ForceHide and not ForceHidden
        }

        LastChatHideState = ChatHideState
        SendNUIMessage(NUIMessage)
        IsFirstHide = false
      end
    end
  end
end)

-- Deprecated
RegisterNetEvent("BaseChat:ChatMessage")

AddEventHandler("BaseChat:ChatMessage", function(Author, Color, Text)
  local Arguments = {Text}

  if Author ~= "" then
    table.insert(Arguments, 1, Author)
  end

  SendNUIMessage({
    Type = "ON_MESSAGE",
    Message = {
      Color = Color,
      Multiline = true,
      Args = Arguments
    }
  })
end)
