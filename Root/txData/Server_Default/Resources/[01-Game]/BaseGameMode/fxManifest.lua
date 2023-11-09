FX_Version "Cerulean"
Lua54 "Yes"
Games {
  "Common",
  "GTA4",
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
Description "A Basic Free Mode Gametype Using Default Spawn Logic From SpawnManager."
Repository "N/A"

Resource_Type "Gametype" {Name = "FreeRoam"}

Client_Scripts {
  "fxData/Scripts/Lua/Client/BaseGameMode_Cl.lua"
}
