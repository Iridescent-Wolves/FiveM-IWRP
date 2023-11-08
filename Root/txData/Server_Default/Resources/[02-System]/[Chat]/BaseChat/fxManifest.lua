FX_Version "Cerulean"
Lua54 "Yes"
Games {
  "GTA5",
  "RDR3"
}
Dependencies {
  "/OneSync",
  "/GameBuild:2944",
  "/Server:6683",
  "WebPack",
  "Yarn"
}

Version "1.0.0"
Author "CFX.re <root@cfx.re> | Edited by Iridescent Wolves Development Team"
Description "Provides Baseline Chat Functionality Using An NUI-Based Interface."
Repository "N/A"

UI_Page "WebData/Dist/ui.html"

Client_Scripts {
  "BaseChat_Cl.lua"
}
Server_Scripts {
  "BaseChat_Sv.lua"
}
Files {
  "WebData/Dist/ui.html",
  "WebData/Dist/index.css",
  "WebData/HTML/Vendor/*.css",
  "WebData/HTML/Vendor/Fonts/*.woff2"
}

WebPack_Config "WebData/WebPack.Config.js"
