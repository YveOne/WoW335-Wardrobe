
-----------------------------------------------------------------------------------
local ADDONNAME, THIS = ...;
-----------------------------------------------------------------------------------
local AceLocale = LibStub:GetLibrary("AceLocale-3.0")
local L = AceLocale:NewLocale(ADDONNAME, "enUS", true)
if ( not L ) then return end
-----------------------------------------------------------------------------------

L["title"] = "Wardrobe"
L["undress"] = "Undress"

L["defaultBG"] = "Default backgrounds"
L["customBG"] = "Custom backgrounds"

L["OK"] = "OK"
L["yes"] = "Yes"
L["no"] = "No"
L["cancel"] = "cancel"
L["default"] = "Default"

L["BackgroundBloodElf"]   = "Blood Elf"
L["BackgroundDraenei"]    = "Draenei"
L["BackgroundTauren"]     = "Tauren"
L["BackgroundDwarf"]      = "Dwarf/Gnome"
L["BackgroundOrc"]        = "Orc"
L["BackgroundScourge"]    = "Scourge"
L["BackgroundHuman"]      = "Human"
L["BackgroundNightelf"]   = "Nightelf"

L["yourOutfits"] = "Your saved outfits"
L["yourOptions"] = "Options"

L["newOutfit"] = "New outfit"
L["createOutfit"] = "Create a new outfit"
L["deleteOutfit"] = "Delete this outfit"
L["renameOutfit"] = "Rename this outfit"
L["noOutfits"] = "No outfits yet (create one!)"
L["enterNameOfOutfit"] = "Enter the name of the outfit"
L["confirmDeleteOutfit"] = "Do you realy wanna delete the outfit '%s'?"

L["menuRarity"] = "Rarity"
L["menuItemName"] = "Item name / substring"
L["menuSlots"] = "Equip Location"
L["menuItemID"] = "Item ID range"
L["menuItemLvl"] = "Item level range"
L["menuRequireLvl"] = "Max char level"
L["menuSearch"] = "Search"
L["menuNotSearchedYet"] = "No search started yet"
L["menuSearchItemStatus"] = "Showing item %s - %s of %s"
L["menuSearchPageStatus"] = "%s/%s"

L["shield"] = "Shield"
L["weapon"] = "Weapon"
L["armor"] = "Weapon"

L["asc"] = "Ascending"
L["desc"] = "Descending"

L["sortByID"] = "Sort by Item Id"
L["sortByName"] = "Sort by names"
L["sortByPrice"] = "Sort by sellprice"
L["sortByRarity"] = "Sort by rarity"
L["sortByItemLevel"] = "Sort by item level"
L["sortByReqLevel"] = "Sort by required charakter level"

L["about"] = "About"
L["aboutText1"] = "Manufactured by: %s"
L["aboutText2"] = "Complaints and spam go to: %s"
L["aboutText3"] = "This thing here is also available on Github:\n%s"
