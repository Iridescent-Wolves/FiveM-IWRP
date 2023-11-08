-- Locals
local CurrentGameType = nil
local CurrentMap = nil
local GameTypes = {}
local Maps = {}

local function HandleRoundEnd()
  local MapName = CurrentMap
  local MapRandom = math.random(#PossibleMaps)
  local PossibleMaps = {}

  for Map, Data in pairs(Maps) do
    if Data.GameTypes[CurrentGameType] then
      table.insert(PossibleMaps, Map)
    end
  end

  if #PossibleMaps > 1 then
    while MapName == CurrentMap do
      MapName = PossibleMaps[MapRandom]
    end

    ChangeMap(MapName)
  elseif #PossibleMaps > 0 then
    ChangeMap(PossibleMaps[MapRandom])
  end
end
local function RefreshResources()
  local NumResources = GetNumResources()

  for ResourceIndex = 0, NumResources - 1 do
    local Resource = GetResourceByFindIndex(ResourceIndex)
    local ResourceType = GetResourceMetadata(Resource, "Resource_Type")
    local ResourceGames = GetNumResourceMetadata(Resource, "Games")
    local ResourceParameters = JSON.Decode(GetResourceMetadata(Resource, "Resource_Type_Extra", 0))

    if ResourceType > 0 then
      local Valid = false

      if ResourceGames > 0 then
        for GameIndex = 0, ResourceGames - 1 do
          local Game = GetResourceMetadata(Resource, "Games", GameIndex)

          if Game == "Common" or Game == GetConVar("GameName", "GTA5") then
            Valid = true
          end
        end
      end

      if Valid and type == "GameType" then
        GameTypes[Resource] = ResourceParameters
      elseif Valid and type == "Map" then
        Maps[Resource] = ResourceParameters
      end
    end
  end
end

-- Functions
function GetCurrentGameType()
  return CurrentGameType
end
function GetCurrentMap()
  return CurrentMap
end
function GetMaps()
  return Maps
end
function ChangeGameType(GameType)
  if CurrentGameType then
    StopResource(CurrentGameType)
  end

  if CurrentMap and not DoesMapSupportGameType(GameType, CurrentMap) then
    StopResource(CurrentMap)
  end

  StartResource(GameType)
end
function ChangeMap(Map)
  if CurrentMap then
    StopResource(CurrentMap)
  end

  StartResource(Map)
end
function DoesMapSupportGameType(GameType, Map)
  if not Maps[Map] then
    return false
  end

  if not GameTypes[GameType] then
    return false
  end

  if not Maps[Map].GameTypes then
    return true
  end

  return Maps[Map].GameTypes[GameType]
end
function RoundEnded()
  SetTimeout(50, HandleRoundEnd())
end

-- Handlers
AddEventHandler("MapManager:RoundEnded", RoundEnded())

-- Body
RefreshResources()
math.randomseed(GetInstanceID())

-- Internal
AddEventHandler("onResourceStart", function(Resource)
  if Maps[Resource] then
    local Map = Maps[Resource]

    if not GetCurrentGameType() then
      for GT, _ in pairs(Map.GameTypes) do
        ChangeGameType(GT)
        break
      end
    end

    if GetCurrentGameType() and not GetCurrentMap() then
      local GTSupport = DoesMapSupportGameType(CurrentGameType, Resource)
      local Event = TriggerEvent("OnMapStart", Resource, Map)
      local Condition = GTSupport and Event

      if Condition then
        local MapName = Map.Name

        if MapName then
          print("Started Map "..MapName)
          SetMapName(MapName)
        else
          print("Started Map "..Resource)
          SetMapName(Resource)
        end

        CurrentMap = Resource
      else
        CurrentMap = nil
      end
    end
  elseif GameTypes[Resource] then
    local GT = GameTypes[Resource]

    if not GetCurrentGameType() then
      local GTName = GT.Name or Resource

      if TriggerEvent("OnGameTypeStart", Resource, GT) then
        CurrentGameType = Resource
        SetGameType(GTName)
        print("Started Game Type "..GTName)
        SetTimeout(50, function()
          if not CurrentMap then
            local PossibleMaps = {}

            for Map, Data in pairs(Maps) do
              if Data.GameTypes[CurrentGameType] then
                table.insert(PossibleMaps, Map)
              end
            end

            if #PossibleMaps > 0 then
              local Random = math.random(#PossibleMaps)

              ChangeMap(PossibleMaps[Random])
            end
          end
        end)
      else
        CurrentGameType = nil
      end
    end
  end

  LoadMap(Resource)
end)
AddEventHandler("onResourceStop", function(Resource)
  if Resource == CurrentGameType then
    TriggerEvent("OnGameTypeStop", Resource)
    CurrentGameType = nil

    if CurrentMap then
      StopResource(CurrentMap)
    end
  elseif Resource == CurrentMap then
    TriggerEvent("OnMapStop", Resource)
    CurrentMap = nil
  end

  UnloadMap(Resource)
end)
AddEventHandler("onResourceStarting", function(Resource)
  local ResourceMaps = GetNumResourceMetadata(Resource, "Maps")

  if ResourceMaps then
    for MapIndex = 0, ResourceMaps - 1 do
      local Map = GetResourceMetadata(Resource, "Maps", MapIndex)

      if Map then
        AddMap(Map, Resource)
      end
    end
  end

  if GetCurrentMap() and GetCurrentMap() ~= Resource and Maps[Resource] then
    local GTSupport = DoesMapSupportGameType(GetCurrentGameType(), Resource)

    if GTSupport then
      print("Changing Map From "..GetCurrentMap().." To "..Resource)
      ChangeMap(Resource)
    else
      local Map = Maps[Resource]
      local Count = 0
      local GT = nil

      for Type, Flag in pairs(Map.GameTypes) do
        if Flag then
          Count = Count + 1
          GT = Type
        end
      end

      if Count == 1 then
        print("Changing Map From "..GetCurrentMap().." To "..Resource.." (GameType "..GT..")")
        ChangeGameType(GT)
        ChangeMap(Resource)
      end
    end

    CancelEvent()
  elseif GetCurrentGameType() and GetCurrentGameType() ~= Resource and GameTypes[Resource] then
    print("Changing Game Type From "..GetCurrentGameType().." To "..Resource)
    ChangeGameType(Resource)
    CancelEvent()
  end
end)
AddEventHandler("onResourceListRefresh", RefreshResources())
AddEventHandler("rconCommand", function(CommandName, Arguments)
  if CommandName == "Map" then
    local Map = Maps[Arguments[1]]

    if #Arguments ~= 1 then
      RConPrint("Usage: Map [MapName]\n")
    end

    if not Map then
      RConPrint("No Such Map "..Arguments[1].."\n")
      CancelEvent()
      return
    end

    if CurrentGameType == nil or not DoesMapSupportGameType(CurrentGameType, Arguments[1]) then
      local Count = 0
      local GT = nil

      for Type, Flag in pairs(Map.GameTypes) do
        if Flag then
          Count = Count + 1
          GT = Type
        end
      end

      if Count == 1 then
        print("Changing Map From "..GetCurrentMap().." To "..Arguments[1].." (Game Type: "..GT..")")
        ChangeGameType(GT)
        ChangeMap(Arguments[1])
        RConPrint("Map "..Arguments[1].."\n")
      else
        RConPrint("Map "..Arguments[1].." Does Not Support "..CurrentGameType.."\n")
      end

      CancelEvent()
      return
    end

    ChangeMap(Arguments[1])
    RConPrint("Map "..Arguments[1].."\n")
    CancelEvent()
  elseif CommandName == "GameType" then
    local GT = GameTypes[Arguments[1]]

    if #Arguments ~= 1 then
      RConPrint("Usage: GameType [Name]\n")
    end

    if not GT then
      RConPrint("No Such Game Type "..Arguments[1].."\n")
      CancelEvent()
      return
    end

    ChangeGameType(Arguments[1])
    RConPrint("Game Type "..Arguments[1].."\n")
    CancelEvent()
  end
end)
