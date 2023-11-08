---@diagnostic disable:redundant-value, err-eq-as-assign

-- Locals
local SpawnLock = false
local AutoSpawnEnabled = false
local SpawnNum = 1
local DiedAt = nil
local RespawnForced = nil
local AutoSpawnCallback = nil
local SpawnPoints = {}

local function FreezePlayer(ID, Freeze)
  local Player = ID

  SetPlayerControl(Player, not Freeze, false)

  if not Freeze then
    local Ped = GetPlayerPed(Player)

    if not IsEntityVisible(Ped) then
      SetEntityVisible(Ped, true)
    end

    if not IsPedInAnyVehicle(Ped) then
      SetEntityCollision(Ped, true)
    end

    FreezeEntityPosition(Ped, false)
    SetPlayerInvincible(Player, false)
  else
    local Ped = GetPlayerPed(Player)

    if IsEntityVisible(Ped) then
      SetEntityVisible(Ped, false)
    end

    SetEntityCollision(Ped, false)
    FreezeEntityPosition(Ped, true)
    SetPlayerInvincible(Player, true)

    if not IsPedFatallyInjured(Ped) then
      ClearPedTasksImmediately(Ped)
    end
  end
end

-- Functions
function AddSpawnPoint(Spawn)
  local Model = Spawn.Model

  if not tonumber(Spawn.X) or not tonumber(Spawn.Y) or not tonumber(Spawn.Z) then
    error("Invalid Spawn Position!")
  end

  if not tonumber(Spawn.Heading) then
    error("Invalid Spawn Heading!")
  end

  if not tonumber(Spawn.Model) then
    Model = GetHashKey(Spawn.Model)
  end

  if not IsModelInCDImage(Model) then
    error("Invalid Spawn Model!")
  end

  Spawn.Model = Model
  Spawn.Index = SpawnNum
  SpawnNum = SpawnNum + 1
  table.insert(SpawnPoints, Spawn)
  return Spawn.Index
end
function RemoveSpawnPoint(Spawn)
  for SpawnIndex = 1, #SpawnPoints do
    if SpawnPoints[SpawnIndex].Index == Spawn then
      table.remove(SpawnPoints, SpawnIndex)
      return
    end
  end
end
function LoadSpawns(SpawnString)
  local Data = JSON.Decode(SpawnString)

  if not Data.Spawns then
    error("No 'Spawns' In JSON Data!")
  end

  for I, Spawn in ipairs(Data.Spawns) do
    AddSpawnPoint(Spawn)
  end
end
function SpawnPlayer(SpawnIndex, Callback)
  if SpawnLock then
    return
  end

  SpawnLock = true

  Citizen.CreateThread(function()
    local Ped = PlayerPedID()
    local Time = GetGameTimer()
    local Spawn = nil

    if not SpawnIndex then
      SpawnIndex = GetRandomIntInRange(1, #SpawnPoints + 1)
    end

    if type(SpawnIndex) == "table" then
      Spawn = SpawnIndex
      Spawn.X = Spawn.X + 0.00
      Spawn.Y = Spawn.Y + 0.00
      Spawn.Z = Spawn.Z + 0.00
      Spawn.Heading = Spawn.Heading and (Spawn.Heading + 0.00) or 0
    else
      Spawn = SpawnPoints[SpawnIndex]
    end

    if not Spawn.SkipFade then
      DoScreenFadeOut(500)

      while not IsScreenFadedOut() do
        Wait(10)
      end
    end

    if not Spawn then
      Trace("Tried To Spawn An Invalid Spawn Index!\n")
      SpawnLock = false
      return
    end

    FreezePlayer(PlayerID(), true)

    if Spawn.Model then
      RequestModel(Spawn.Model)

      while not HasModelLoaded(Spawn.Model) do
        Wait(10)
      end

      SetPlayerModel(PlayerID(), Spawn.Model)
      SetModelAsNoLongerNeeded(Spawn.Model)

      if N_0x283978A15512B2FE then
        N_0x283978A15512B2FE(Ped, true)
      end
    end

    RequestCollisionAtCoord(Spawn.X, Spawn.Y, Spawn.Z)
    SetEntityCoordsNoOffset(Ped, Spawn.X, Spawn.Y, Spawn.Z, false, false, false, true)
    NetworkResurrectLocalPlayer(Spawn.X, Spawn.Y, Spawn.Z, Spawn.Heading, true, true, false)
    ClearPedTasksImmediately(Ped)
    RemoveAllPedWeapons(Ped)
    ClearPlayerWantedLevel(PlayerID())

    while not HasCollisionLoadedAroundEntity(Ped) and (GetGameTimer() - Time) < 5000 do
      Wait(10)
    end

    ShutdownLoadingScreen()

    if not IsScreenFadedOut() then
      DoScreenFadeIn(500)

      while not IsScreenFadedIn() do
        Wait(10)
      end
    end

    FreezePlayer(PlayerID(), false)
    TriggerEvent("playerSpawned", Spawn)

    if Callback then
      Callback(Spawn)
    end

    SpawnLock = false
  end)
end
function ForceRespawn()
  SpawnLock = false
  RespawnForced = true
end
function SetAutoSpawn(Enabled)
  AutoSpawnEnabled = Enabled
end
function SetAutoSpawnCallback(Callback)
  AutoSpawnEnabled = true
  AutoSpawnCallback = Callback
end
function LoadScene(X, Y, Z)
  if not NewLoadSceneStart then
    return
  end

  NewLoadSceneStart(X, Y, Z, 0.0, 0.0, 0.0, 20.0, 0)

  while IsNewLoadSceneActive() do
    NetworkTimer = GetNetworkTimer()
    NetworkUpdateLoadScene()
  end
end

-- Handlers
AddEventHandler("getMapDirectives", function(Add)
    if not S then
      Trace(E.."\n")
    end

  Add("SpawnPoint", function(State, Model)
    local function ReturnFunction(Options)
      local X, Y, Z, Heading = nil, nil, nil, nil
      local S, E = pcall(function()
        local Spwn = {
          X = X,
          Y = Y,
          Z = Z,
          Heading = Heading,
          Model = Model
        }

        if Options.X then
          X = Options.X,
          Y = Options.Y,
          Z = Options.Z
        else
          X = Options[1],
          Y = Options[2],
          Z = Options[3]
        end

        X = X + 0.0001
        Y = Y + 0.0001
        Z = Z + 0.0001
        Heading = Options.Heading and (Options.Heading + 0.01) or 0
        AddSpawnPoint(Spwn)

        if not tonumber(Model) then
          Model = GetHashKey(Model, _r)
        end

        State.Add("XYZ", {X, Y, Z})
        State.Add("Model", Model)

        if not S then
          Trace(E.."\n")
        end
      end)
    end

    return ReturnFunction()
  end, function(State, Arguments)
    for Idx, Spwn in ipairs(SpawnPoints) do
      if Spwn.X == State.XYZ[1] and Spwn.Y == State.XYZ[2] and Spwn.Z == State.XYZ[3] and Spwn.Model == State.Model then
        table.remove(SpawnPoints, Idx)
        return
      end
    end
  end)
end)

-- Threads
Citizen.CreateThread(function()
  local Ped = PlayerPedID()
  while true do
    Wait(50)

    if Ped and Ped ~= -1 then
      local Player = PlayerID()

      if AutoSpawnEnabled and NetworkIsPlayerActive(Player) then
        local Time = GetGameTimer()

        if DiedAt and math.abs(GetTimeDifference(Time, DiedAt)) > 2000 or RespawnForced then
          if AutoSpawnCallback then
            AutoSpawnCallback()
          else
            SpawnPlayer()
          end

          RespawnForced = false
        end
      end

      if IsEntityDead(Ped) then
        if not DiedAt then
          DiedAt = GetGameTimer()
        end
      else
        DiedAt = nil
      end
    end
  end
end)

-- Exports
Exports("AddSpawnPoint", AddSpawnPoint)
Exports("RemoveSpawnPoint", RemoveSpawnPoint)
Exports("LoadSpawns", LoadSpawns)
Exports("SpawnPlayer", SpawnPlayer)
Exports("ForceRespawn", ForceRespawn)
Exports("SetAutoSpawn", SetAutoSpawn)
Exports("SetAutoSpawnCallback", SetAutoSpawnCallback)
