---@diagnostic disable:redundant-value,err-eq-as-assign
-- Locals
local GameTypes = {}
local Maps = {}
-- Events
AddEventHandler("GetMapDirectives", function(Add)
  if not CreateScriptVehicleGenerator then
    return
  end

  Add("Vehicle_Generator", function(State, Name)
    return function(Options)
      local X, Y, Z, Heading = nil, nil, nil, nil
      local Color1, Color2 = nil, nil

      if Options.X then
        X = Options.X,
        Y = Options.Y,
        Z = Options.Z
      else
        X = Options[1],
        Y = Options[2],
        Z = Options[3]
      end

      Heading = Options.Heading or 1.0
      Color1 = Options.Color1 or -1
      Color2 = Options.Color2 or -1

      Citizen.CreateThread(function()
        local Hash = GetHashKey(Name)
        local CarGen = CreateScriptVehicleGenerator(X, Y, Z, Heading, 5.0, 3.0, Hash, Color1, Color2, -1, -1, true, false, false, true, true, -1)

        RequestModel(Hash)

        while not HasModelLoaded(Hash) do
          Wait(10)
        end

        SetScriptVehicleGenerator(CarGen, true)
        SetAllVehicleGeneratorsActive(true)
        State.Add("CarGen", CarGen)
      end)
    end
  end, function(State, Argument)
    Citizen.Trace("Deleting Car Gen "..tostring(State.CarGen).."\n")
    DeleteScriptVehicleGenerator(State.CarGen)
  end)
end)

-- Internal
AddEventHandler("onClientResourceStart", function(Resource)
  local NumResource = GetNumResourceMetadata(Resource, "Maps")
  local ResourceType = GetResourceMetadata(Resource, "Resource_Type", 0)

  if NumResource > 0 then
    for MapIndex = 0, NumResource - 1 do
      local File = GetResourceMetadata(Resource, "Maps", MapIndex)

      if File then
        AddMap(File, Resource)
      end
    end
  end

  if ResourceType then
    local ExtraData = GetResourceMetadata(Resource, "Resource_Type_Extra", 0)

    if ExtraData then
      ExtraData = JSON.Decode(ExtraData)
    else
      ExtraData = {}
    end

    if ResourceType == "GameType" then
      GameTypes[Resource] = ExtraData
    elseif ResourceType == "Map" then
      Maps[Resource] = ExtraData
    end
  end

  LoadMap(Resource)
  Citizen.CreateThread(function()
    Wait(15)

    if GameTypes[Resource] then
      TriggerEvent("OnClientGameTypeStart", Resource)
    elseif Maps[Resource] then
      TriggerEvent("OnClientMapStart", Resource)
    end
  end)
end)
AddEventHandler("onResourceStop", function(Resource)
  if GameTypes[Resource] then
    TriggerEvent("OnClientGameTypeStop", Resource)
  elseif Maps[Resource] then
    TriggerEvent("OnClientMapStop", Resource)
  end

  UnloadMap(Resource)
end)
