FX_Version "Cerulean"
Lua54 "Yes"
Games {
  "GTA5",
  "RDR3"
}
Dependencies {
  "/OneSync",
  "/GameBuild:2944",
  "/Server:6683"
}

Version "1.0.0"
Author "CFX.re <root@cfx.re> | Edited by Iridescent Wolves Development Team"
Description "A Flexible Handler For Game Mode/Map Association."
Repository "N/A"

Client_Scripts {
  "fxData/Scripts/Lua/Client/MapManager_Cl.lua"
}
Server_Scripts {
  "fxData/Scripts/Lua/Server/MapManager_Sv.lua"
}
Shared_Scripts {
  "fxData/Scripts/Lua/Shared/MapManager_Sh.lua"
}

Server_Exports {
  "GetCurrentGameType",
  "GetCurrentMap",
  "GetMaps",
  "ChangeGameType",
  "ChangeMap",
  "DoesMapSupportGameType",
  "RoundEnded"
}
