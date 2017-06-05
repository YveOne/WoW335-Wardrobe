
-----------------------------------------------------------------------------------
local ADDONNAME, THIS = ...;
-----------------------------------------------------------------------------------
local AceLocale = LibStub:GetLibrary("AceLocale-3.0")
local L = AceLocale:NewLocale(ADDONNAME, "deDE")
if ( not L ) then return end
-----------------------------------------------------------------------------------

L["title"] = "Kleiderschrank"
L["undress"] = "Entkleiden"

L["defaultBG"] = "Standardhintergr\195\188nde"
L["customBG"] = "Eigene Hintergr\195\188nde"

L["OK"] = "OK"
L["yes"] = "Ja"
L["no"] = "N\195\182"
L["cancel"] = "Abbrechen"
L["default"] = "Standard"

L["BackgroundBloodElf"]   = "Blutelf"
L["BackgroundDraenei"]    = "Draenei"
L["BackgroundTauren"]     = "Tauren"
L["BackgroundDwarf"]      = "Zwerg/Gnom"
L["BackgroundOrc"]        = "Orc"
L["BackgroundScourge"]    = "Gei\195\159el"
L["BackgroundHuman"]      = "Mensch"
L["BackgroundNightelf"]   = "Nachtelf"

L["yourOutfits"] = "Deine gespeicherten Outfits"
L["yourOptions"] = "Optionen"

L["newOutfit"] = "Neues Outfit"
L["createUndressedOutfit"] = "Outfit erstellen (entkleidet)"
L["createDressedOutfit"] = "Outfit erstellen"
L["deleteOutfit"] = "Dieses Outfit l\195\182schen"
L["renameOutfit"] = "Dieses Outfit umbenennen"
L["noOutfits"] = "Noch keine Outfits (erstell eines!)"
L["enterNameOfOutfit"] = "Name des Outfits"
L["confirmDeleteOutfit"] = "M\195\182chtest Du Dein Outfit '%s' wirklich l\195\182schen?"

L["menuRarity"] = "Seltenheit"
L["menuItemName"] = "Gegenstandsname"
L["menuSlots"] = "Gegenstandspl\195\164tze"
L["menuItemID"] = "ID-Bereich"
L["menuItemLvl"] = "Stufenreichweite"
L["menuRequireLvl"] = "Bis Charakter Stufe"
L["menuSearch"] = "Suchen"
L["menuNotSearchedYet"] = "Noch keine Suche gestartet"
L["menuSearchItemStatus"] = "Gegenstand %s - %s von %s"
L["menuSearchPageStatus"] = "%s/%s"

L["shield"] = "Schild"
L["weapon"] = "Waffen"
L["armor"] = "R\195\188stung"

L["asc"] = "Aufsteigend"
L["desc"] = "Absteigend"

L["sortByID"] = "Nach Item ID sortieren"
L["sortByName"] = "Nach Namen sortieren"
L["sortByPrice"] = "Nach Verkaufspreis sortieren"
L["sortByRarity"] = "Nach Seltenheit sortieren"
L["sortByItemLevel"] = "Nach Item Stufe sortieren"
L["sortByReqLevel"] = "Nach ben\195\182tigter Charakterstufe sortieren"

L["about"] = "Info"
L["aboutText1"] = "Fabriziert von: "
L["aboutText2"] = "Beschwerden und Spam an: %s"
L["aboutText3"] = "Das Ding hier gibt's auch auf Github:\n%s"
