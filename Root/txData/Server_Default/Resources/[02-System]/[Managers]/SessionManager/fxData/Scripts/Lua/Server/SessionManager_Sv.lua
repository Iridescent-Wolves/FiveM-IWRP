local CurrentHosting = nil
local HostReleaseCallbacks = {}

EnableEnhancedHostSupport(true)

RegisterServerEvent("HostedSession")
RegisterServerEvent("HostingSession")

AddEventHandler("HostedSession", function()
  if CurrentHosting ~= Source then
    --TODO: Drop Client As They're Clearly Lying
    print(CurrentHosting, "~=", Source)
    return
  end

  for _, Callback in ipairs(HostReleaseCallbacks) do
    Callback()
  end

  CurrentHosting = nil
end)
AddEventHandler("HostingSession", function() --TODO: Find Out What 'sessionHostResult' Is
  if CurrentHosting then
    TriggerClientEvent("sessionHostResult", Source, "Wait")
    table.insert(HostReleaseCallbacks, function()
      TriggerClientEvent("sessionHostResult", Source, "Free")
    end)
    return
  end

  if GetHostID() and GetPlayerLastMsg(GetHostID()) < 1000 then
    TriggerClientEvent("sessionHostResult", Source, "Conflict")
    return
  end

  TriggerClientEvent("sessionHostResult", Source, "Go")
  CurrentHosting = Source
  HostReleaseCallbacks = {}

  SetTimeout(5000, function()
    if not CurrentHosting then
      return
    end

    CurrentHosting = nil

    for _, Callback in ipairs(HostReleaseCallbacks) do
      Callback()
    end
  end)
end)
