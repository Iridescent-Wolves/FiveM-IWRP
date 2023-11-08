FX_Version "Cerulean"
Lua54 "Yes"
Games {
  "GTA4",
  "GTA5"
}
Dependencies {
  "/OneSync",
  "/GameBuild:2944",
  "/Server:6683"
}

Version "1.0.0"
Author "CFX.re <root@cfx.re> | Edited by Iridescent Wolves Development Team"
Description "Handles 'Host Lock' For Non-OneSync Servers. Do Not Disable."
Repository "N/A"

Client_Scripts {
  "fxData/Scripts/Lua/Client/SessionManager_Cl.lua"
}
Server_Scripts {
  "fxData/Scripts/Lua/Server/SessionManager_Sv.lua"
}
