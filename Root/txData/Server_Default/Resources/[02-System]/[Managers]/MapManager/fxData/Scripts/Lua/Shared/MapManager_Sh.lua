-- Functions
function AddMap(File, OwningResource)
  if not MapFiles[OwningResource] then
    MapFiles[OwningResource] = {}
  end

  table.insert(MapFiles[OwningResource], File)
end
function LoadMap(Resource)
  local Map = MapFiles[Resource]

  if Map then
    for _, File in ipairs(Map) do
      ParseMap(File, Resource)
    end
  end
end
function UnloadMap(Resource)
  local CB = UndoCallbacks[Resource]

  if CB then
    for _, Callback in ipairs(CB) do
      Callback()
    end

    MapFiles[Resource] = nil
    UndoCallbacks[Resource] = nil
  end
end
function ParseMap(File, OwningResource)
  local FileData = LoadResourceFile(OwningResource, File)
  local MapFunction, Error = load(FileData, File, "t", Environment)
  local Environment = {
    Math = math,
    Pairs = pairs,
    IPairs = ipairs,
    Next = next,
    ToNumber = tonumber,
    ToString = tostring,
    Type = type,
    Table = table,
    String = string,
    _G = Environment,
    Vector = vec,
    Vector2 = vector2,
    Vector3 = vector3,
    Quat = quat
  }
  local MT = {
    __index = function(T, K)
      local F = function()
        return F
      end

      if rawget(T, K) ~= nil then
        return rawget(T, K)
      end

      return function()
        return F
      end
    end
  }

  if not UndoCallbacks[OwningResource] then
    UndoCallbacks[OwningResource] = {}
  end

  TriggerEvent("GetMapDirectives", function(Key, Callback, UndoCB)
    Environment[Key] = function(...)
      local Result = Callback(...)
      local Arguments = table.pack(...)
      local State = {}

      State.Add = function(K, V)
        State[K] = V
      end

      table.insert(UndoCallbacks[OwningResource], function()
        UndoCB(State)
      end)

      return Result
    end
  end)

  SetMetaTable(Environment, MT)

  if not MapFunction then
    Citizen.Trace("Couldn't Load Map "..File..": "..Error.." (Type of FileData: "..type(FileData)..")\n")
    return
  end

  MapFunction()
end

-- Body
MapFiles = {}
UndoCallbacks = {}
