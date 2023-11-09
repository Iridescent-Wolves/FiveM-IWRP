AddEventHandler("onClientMapStart", function()
  Exports.SpawnManager:SetAutoSpawn(true)
  Exports.SpawnManager:ForceRespawn()
end)
