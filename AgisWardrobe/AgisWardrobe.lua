
-----------------------------------------------------------------------------------
local ADDONNAME, THIS = ...;
-----------------------------------------------------------------------------------
Wardrobe = LibStub("AceAddon-3.0"):NewAddon(CreateFrame("Frame"), ADDONNAME)
local L = LibStub("AceLocale-3.0"):GetLocale(ADDONNAME, true)
local AgiTimers = LibStub("AgiTimers")
local AgiDialogs  = LibStub("AgiDialogs")
-----------------------------------------------------------------------------------

-----------------------------------------------------------------------------------
-- LOCAL FUNCTIONS
------------------------------------------------------------------------

local floor, ceil, min, max = math.floor, math.ceil, math.min, math.max
local strmatch, strsub, strupper, strlower = string.match, string.sub, string.upper, string.lower
local tonumber, pairs, getglobal, select = tonumber, pairs, getglobal, select
local sort = table.sort
local GetCursorPosition, GetCursorInfo, ResetCursor, CursorUpdate, PickupItem = GetCursorPosition, GetCursorInfo, ResetCursor, CursorUpdate, PickupItem
local FauxScrollFrame_Update, FauxScrollFrame_GetOffset = FauxScrollFrame_Update, FauxScrollFrame_GetOffset
local UIDropDownMenu_SetText, UIDropDownMenu_Refresh, UIDropDownMenu_Initialize, UIDropDownMenu_AddButton, ToggleDropDownMen = UIDropDownMenu_SetText, UIDropDownMenu_Refresh, UIDropDownMenu_Initialize, UIDropDownMenu_AddButton, ToggleDropDownMen
local GetInventorySlotInfo, GetInventoryItemID, GetInventoryItemTexture, GetItemInfo, GetItemQualityColor = GetInventorySlotInfo, GetInventoryItemID, GetInventoryItemTexture, GetItemInfo, GetItemQualityColor

local function treverse(tbl)
    for i=1, floor(#tbl / 2) do
        tbl[i], tbl[#tbl - i + 1] = tbl[#tbl - i + 1], tbl[i]
    end
end

local function strrep(s, n)
    return n > 0 and s .. strrep(s, n-1) or ""
end

local function GetAbsoluteCursorPosition()
    local s = UIParent:GetEffectiveScale()
    local x, y = GetCursorPosition()
    return x/s, y/s
end

local function ItemInfoByLink(itemLink)
    return strmatch(itemLink, "item%:(%d+)%:.+%[(.-)%]")
end

local function pairsByKeys(t, f)
    local a = {}
    for n in pairs(t) do
        a[#a+1] = n
    end
    sort(a, f)
    local i = 0
    local iter = function()
        i = i + 1
        if a[i] == nil then return nil
        else return a[i], t[a[i]]
        end
     end
     return iter
end

local function FauxScrollFrame_ScrollToTop(frame)
    local scrollBar = getglobal(frame:GetName().."ScrollBar");
    scrollBar:SetValue(0)
end

------------------------------------------------------------------------
-- CONSTANTS
------------------------------------------------------------------------

local STRLEN_ITEMID = 5
local STRLEN_ITEMLVL = 3
local STRLEN_ITEMPRICE = 8
local STRLEN_CHARLVL = 2

local SORTBY_ASC = "asc"
local SORTBY_DESC = "desc"

local MIN_ITEMID = 1
local MAX_ITEMID = 60000
local MIN_ITEMLVL = 1
local MAX_ITEMLVL = 284
local MAX_CHARLVL = 80
local MIN_RARITY = 0
local MAX_RARITY = 5

local ROWS_ON_MINIMIZED = 2
local ROWS_ON_MAXIMIZED = 7
local ROWS_HEIGHT = 40
local ITEMS_PER_PAGE = 7

local SORTBY_ITEMID         = "sortByID"
local SORTBY_ITEMNAME       = "sortByName"
local SORTBY_ITEMLVL        = "sortByItemLevel"
local SORTBY_ITEMRARITY     = "sortByRarity"
local SORTBY_ITEMPRICE      = "sortByPrice"
local SORTBY_ITEMREQLVL     = "sortByReqLevel"
local SORTBY_OPTIONS = {
    SORTBY_ITEMID,
    SORTBY_ITEMNAME,
    SORTBY_ITEMLVL,
    SORTBY_ITEMRARITY,
    SORTBY_ITEMPRICE,
    SORTBY_ITEMREQLVL,
}

local SLOTNAMES = {
    HeadSlot            = "",
    ShoulderSlot        = "",
    BackSlot            = "",
    ChestSlot           = "",
    ShirtSlot           = "",
    TabardSlot          = "",
    WristSlot           = "",
    HandsSlot           = "",
    WaistSlot           = "",
    LegsSlot            = "",
    FeetSlot            = "",
    MainHandSlot        = "",
    SecondaryHandSlot   = "",
    RangedSlot          = "",
}
for k,v in pairs(SLOTNAMES) do
    SLOTNAMES[k] = getglobal(strupper(k))
end

local ITEMTYPE_WEAPON, ITEMTYPE_ARMOR =  GetAuctionItemClasses()
local ITEMSUBTYPES_WEAPON = {GetAuctionItemSubClasses(1)}
local ITEMSUBTYPES_ARMOR = {GetAuctionItemSubClasses(2)}

local ITEMLOC2ITEMTYPE = {
    INVTYPE_HEAD        = ITEMTYPE_ARMOR,
    INVTYPE_SHOULDER    = ITEMTYPE_ARMOR,
    INVTYPE_CLOAK       = ITEMTYPE_ARMOR,
    INVTYPE_CHEST       = ITEMTYPE_ARMOR,
    INVTYPE_ROBE        = ITEMTYPE_ARMOR,
    INVTYPE_BODY        = ITEMTYPE_ARMOR,
    INVTYPE_WAIST       = ITEMTYPE_ARMOR,
    INVTYPE_LEGS        = ITEMTYPE_ARMOR,
    INVTYPE_TABARD      = ITEMTYPE_ARMOR,
    INVTYPE_WRIST       = ITEMTYPE_ARMOR,
    INVTYPE_HAND        = ITEMTYPE_ARMOR,
    INVTYPE_FEET        = ITEMTYPE_ARMOR,
    INVTYPE_RANGED          = ITEMTYPE_WEAPON,
    INVTYPE_THROWN          = ITEMTYPE_WEAPON,
    INVTYPE_RANGEDRIGHT     = ITEMTYPE_WEAPON,
    INVTYPE_RELIC           = ITEMTYPE_WEAPON,
    INVTYPE_WEAPON          = ITEMTYPE_WEAPON,
    INVTYPE_2HWEAPON        = ITEMTYPE_WEAPON,
    INVTYPE_WEAPONMAINHAND  = ITEMTYPE_WEAPON,
    INVTYPE_WEAPONOFFHAND   = ITEMTYPE_WEAPON,
    INVTYPE_SHIELD      = ITEMTYPE_ARMOR,
    INVTYPE_HOLDABLE    = ITEMTYPE_ARMOR,
}

local ITEMLOC_REMOVES = {
    INVTYPE_2HWEAPON = { "SecondaryHandSlot", },
}

--TODO: throw weapon + sec hand = possible ?
local ITEMLOC_HIDES = {
    INVTYPE_RANGED          = { "MainHandSlot", "SecondaryHandSlot" },
    INVTYPE_THROWN          = { "RangedSlot", "SecondaryHandSlot" },
    INVTYPE_RANGEDRIGHT     = { "MainHandSlot", "SecondaryHandSlot" },
    INVTYPE_RELIC           = { "MainHandSlot", "SecondaryHandSlot" },
    INVTYPE_WEAPON          = { "RangedSlot" },
    INVTYPE_2HWEAPON        = { "RangedSlot" },
    INVTYPE_WEAPONMAINHAND  = { "RangedSlot" },
    INVTYPE_SHIELD          = { "RangedSlot" },
    INVTYPE_WEAPONOFFHAND   = { "RangedSlot", "MainHandSlot" },
    INVTYPE_HOLDABLE        = { "RangedSlot" },
}

local ITEMLOC2SLOTNAME = {
    INVTYPE_HEAD        = "HeadSlot",
    INVTYPE_SHOULDER    = "ShoulderSlot",
    INVTYPE_CLOAK       = "BackSlot",
    INVTYPE_CHEST       = "ChestSlot",
    INVTYPE_ROBE        = "ChestSlot",
    INVTYPE_BODY        = "ShirtSlot",
    INVTYPE_WAIST       = "WaistSlot",
    INVTYPE_LEGS        = "LegsSlot",
    INVTYPE_TABARD      = "TabardSlot",
    INVTYPE_WRIST       = "WristSlot",
    INVTYPE_HAND        = "HandsSlot",
    INVTYPE_FEET        = "FeetSlot",
    INVTYPE_RANGED      = "RangedSlot",
    INVTYPE_THROWN      = "MainHandSlot",
    INVTYPE_RANGEDRIGHT = "RangedSlot",
    INVTYPE_RELIC       = "RangedSlot",
    INVTYPE_WEAPON      = "MainHandSlot",
    INVTYPE_2HWEAPON    = "MainHandSlot",
    INVTYPE_WEAPONMAINHAND = "MainHandSlot",
    INVTYPE_SHIELD      = "SecondaryHandSlot",
    INVTYPE_WEAPONOFFHAND = "SecondaryHandSlot",
    INVTYPE_HOLDABLE    = "SecondaryHandSlot",
}

------------------------------------------------------------------------
-- FUNCTIONS
------------------------------------------------------------------------

-- INITIALIZATION
local InitializeDatabase
local InitializeModelFeatures
local InitializeFrontend
local InitializeBackgroundDropDown
local InitializeOutfitsDropDown
local InitializeOutfitsOptionsDropDown
local InitializeWardrobeDropDowns

-- FUNCTIONS: SEARCHING & PAGING
local searchingShowPage
local searchingShowNextPage
local searchingShowPrevPage
local searchingStart

-- FUNCTIONS: DRESSSLOT DIALOG
local UpdateSlotDialog
local ToggleSlotDialog
local CloseSlotDialog

-- FUNCTIONS: DRESSSLOTS
local HideDressSlots
local ShowDressSlots
local ClearDressSlots
local SetDressSlotItem
local SetDressSlotsToInventory
local TryOnDressItem

-- FUNCTIONS: MODEL REFRESH
local ResetDressUpModel
local ResetDressUpModel2Default
local ResetDressUpModel2Outfit

-- FUNCTIONS: OUTFITS
local setDefaultOutfit
local createOutfit
local deleteOutfit
local selectOutfit
local renameOutfit

-- FUNCTIONS: REFRESH FUNCTIONS
local refreshOutfitsMenu
local refreshOutfitsOptionsMenu
local refreshWardrobeInputs
local refreshWardrobeItemTypeMenu

------------------------------------------------------------------------
-- VARIABLES
------------------------------------------------------------------------

local DBOUTFITS

local selectedOutfit
local dressSlots = {}
local dressSlotItems = {}
local currentSelectedSlotName

local ResetDressUpModelInterval
local IsTryingOnOnShow

local itemOnCursorCameFromSlot
local cursorOverSlotDialogButton

local searchMinItemID = MIN_ITEMID
local searchMaxItemID = MAX_ITEMID
local searchMinItemLvl = MIN_ITEMLVL
local searchMaxItemLvl = MAX_ITEMLVL
local searchMaxCharLvl = MAX_CHARLVL
local searchRarities = {}
local searchEquipLoc = {}
local searchSubTypes = {}
local searchSortBy = SORTBY_ITEMID
local searchSortOrder = SORTBY_ASC
local searchItemsPerPage = ITEMS_PER_PAGE

local searchingItemsPerPage = 0
local searchingCurrentPage = 0
local searchingPagesCount = 0
local searchingFoundItems = {}
local searchingRowsFrames = {}
local searchingRowsItems = {}

local DressUpDefaultTexturePath = DressUpTexturePath()
local DressUpCustomTexturePaths = {}
local DressUpCustomLocalization = {}
local DressUpDefaultTexturePaths = {
    BloodElf    = "",
    Draenei     = "",
    Tauren      = "",
    Dwarf       = "",
    Orc         = "",
    Scourge     = "",
    Human       = "",
    Nightelf    = "",
}
for k,v in pairs(DressUpDefaultTexturePaths) do
    DressUpDefaultTexturePaths[k] = "Interface\\DressUpFrame\\DressUpBackground-"..k
end

StaticPopupDialogs["WARDROBE_DIALOG"] = {
    text = "",
    button1 = "",
    button2 = "",
    OnAccept = function(self, ...) end,
    OnCancel = function(self, ...) end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = false,
    preferredIndex = 3,
}

------------------------------------------------------------------------

------------------------------------------------------------------------
-- INITIALIZATION
------------------------------------------------------------------------

InitializeDatabase = function()
InitializeDatabase = function() end

    if ( AgisWardrobeDB == nil ) then
        AgisWardrobeDB = {
            _dbv = 1,
            CFG = {},
            outfits   = {},
        }
    end

    --------------------
    -- updates start

    -- updates end
    --------------------

    DBOUTFITS = AgisWardrobeDB.outfits

end

InitializeModelFeatures = function()
InitializeModelFeatures = function() end

    local mouseCurX = 0
    local mouseCurY = 0
    local mouseLastX = 0
    local mouseLastY = 0
    local mouseButtonDown = nil

    local modelX = 0
    local modelY = 0
    local modelZ = 0
    local modelRotationPerPixel = math.pi / DressUpModel:GetWidth()
    local modelRotation = 0.1

    DressUpModel:EnableMouse(true)
    DressUpModel:EnableMouseWheel(true)
    DressUpModel:SetRotation(modelRotation)

    DressUpModel:SetScript("OnMouseWheel", function(self, delta)
        delta = delta / 5

        if ( (modelZ+delta) < 0) then
            modelX = 0
            modelY = 0
            modelZ = 0
            DressUpModel:SetPosition(modelZ, modelX, modelY)
            return
        elseif ( (modelZ+delta) > 5 ) then
            return
        end

        modelZ = modelZ + delta

        -- zoom in
        if ( delta > 0 ) then
            local centerX, centerY = DressUpModel:GetCenter()
            modelX = modelX + ((centerX - mouseCurX) / (DressUpModel:GetWidth()/2) * 0.06)
            modelY = modelY + ((centerY - mouseCurY) / (DressUpModel:GetHeight()/2) * 0.09)
        -- zoom out
        else
            local d = 1 / (modelZ-delta) * modelZ
            modelX = modelX * d
            modelY = modelY * d
        end
        DressUpModel:SetPosition(modelZ, modelX, modelY)
    end)

    DressUpModel:SetScript("OnUpdate", function(self, elapsed)
        mouseCurX, mouseCurY = GetAbsoluteCursorPosition()
        if ( mouseButtonDown == "RightButton" ) then
            modelRotation = modelRotation + (modelRotationPerPixel * (mouseCurX-mouseLastX))
            DressUpModel:SetRotation(modelRotation)
        elseif ( mouseButtonDown == "LeftButton" ) then
            modelX = modelX + ((mouseCurX-mouseLastX) * 0.0115 / (modelZ+1))
            modelY = modelY + ((mouseCurY-mouseLastY) * 0.0115 / (modelZ+1))
            modelX = max(-1.5, min(1.5, modelX))
            modelY = max(-2.0, min(2.0, modelY))
            DressUpModel:SetPosition(modelZ, modelX, modelY)
        end
        mouseLastX = mouseCurX
        mouseLastY = mouseCurY
    end)

    DressUpModel:SetScript("OnMouseDown", function(self, button)
        mouseButtonDown = button
    end)

    DressUpModel:SetScript("OnMouseUp", function()
        mouseButtonDown = nil
    end)

    function DressUpModel:ResetPosition()
        modelX = 0
        modelY = 0
        modelZ = 0
        modelRotation = 0.1
        DressUpModel:SetPosition(modelZ, modelX, modelY)
        DressUpModel:SetRotation(modelRotation)
    end

end

------------------------------------------------------------------------

InitializeFrontend = function()
InitializeFrontend = function() end

    DressUpFrameDescriptionText:SetText("")

    getglobal("DressUpModelRotateLeftButton"):Hide()
    getglobal("DressUpModelRotateRightButton"):Hide()

    DressUpFrameUndressButton:SetText(L["undress"])
    DressUpFrameWardrobeButton:SetText(L["title"])

    WardrobeFrameTitleText:SetText(L["title"])
    WardrobeFrameAboutButton:SetText(L["about"])

    WardrobeMenuFrameItemIDLabel:SetText(L["menuItemID"])
    WardrobeMenuFrameItemLevelLabel:SetText(L["menuItemLvl"])
    WardrobeMenuFrameItemRequireLevelLabel:SetText(L["menuRequireLvl"])
    WardrobeMenuFrameItemNameLabel:SetText(L["menuItemName"])

    UIDropDownMenu_SetText(WardrobeMenuFrameItemRarityButton, L["menuRarity"])
    UIDropDownMenu_SetText(WardrobeMenuFrameItemSlotButton, L["menuSlots"])

    WardrobeFrameSubmitButton:SetText(L["menuSearch"])
    WardrobeFrameItemStatus:SetText(L["menuNotSearchedYet"])

end

-----------------------------------------------------------------------------------

InitializeBackgroundDropDown = function()
InitializeBackgroundDropDown = function() end

    local dropDownButton = DressUpFrameBackgroundButton
    local dropDownMenu = DressUpFrameBackgroundButtonMenu

    local selectedValue = ""
    local optionButtons = {}
    local _optionButton

    local function OptionButtonFunc(self, arg1, arg2, checked)

        dropDownButton.selectedValue = self.value
        UIDropDownMenu_SetText(dropDownButton, self.text)
        UIDropDownMenu_Refresh(dropDownButton)

        local texture = DressUpDefaultTexturePaths[self.value] or DressUpCustomTexturePaths[self.value]

        DressUpBackgroundTopLeft:SetTexture(texture..1);
        DressUpBackgroundTopRight:SetTexture(texture..2);
        DressUpBackgroundBotLeft:SetTexture(texture..3);
        DressUpBackgroundBotRight:SetTexture(texture..4);

    end

    UIDropDownMenu_Initialize(dropDownButton, function()

        UIDropDownMenu_AddButton({
            text = L["defaultBG"],
            isTitle = true,
            notCheckable = true,
        })

        for k,v in pairs(DressUpDefaultTexturePaths) do
            _optionButton = {
                text = L["Background"..k],
                value = k,
                keepShownOnClick = true,
                func = OptionButtonFunc,
                checked = false,
            }
            optionButtons[k] = _optionButton
            UIDropDownMenu_AddButton(_optionButton)
        end

        UIDropDownMenu_AddButton({
            text = L["customBG"],
            isTitle = true,
            notCheckable = true,
        })

        local gameLocale = GetLocale()
        if gameLocale == "enGB" then
            gameLocale = "enUS"
        end

        for k,v in pairs(DressUpCustomTexturePaths) do
            _optionButton = {
                text = DressUpCustomLocalization[k][gameLocale] or k,
                value = k,
                keepShownOnClick = true,
                func = OptionButtonFunc,
                checked = false,
            }
            optionButtons[k] = _optionButton
            UIDropDownMenu_AddButton(_optionButton)
        end

    end)

    for k,v in pairs(DressUpDefaultTexturePaths) do
        if ( v == DressUpDefaultTexturePath ) then
            dropDownButton.selectedValue = k
            UIDropDownMenu_SetText(dropDownButton, optionButtons[k].text)
            UIDropDownMenu_Refresh(dropDownButton)
        end
    end

end

------------------------------------------------------------------------

InitializeOutfitsDropDown = function()
InitializeOutfitsDropDown = function() end

    local dropDownButton = DressUpFrameOutfitsButton
    local dropDownMenu = DressUpFrameOutfitsButtonMenu

    local SelectButtonFunc = function(self, arg1, arg2, checked)
        local outfitName = self.value
        if ( outfitName == "" ) then
            outfitName = nil
        end
        selectOutfit(outfitName)
        dropDownButton.selectedValue = selectedOutfit or ""
        UIDropDownMenu_Refresh(dropDownButton)
    end

    refreshOutfitsMenu = function()
        UIDropDownMenu_Initialize(dropDownButton, function()

            UIDropDownMenu_AddButton({
                text = L["yourOutfits"],
                isTitle = true,
                notCheckable = true,
            })

            UIDropDownMenu_AddButton({
                text = L["default"],
                value = "",
                func = SelectButtonFunc,
                keepShownOnClick = true,
                checked = false,
            })

            UIDropDownMenu_AddButton({
                text = "                                                                     ",
                isTitle = true,
                notCheckable = true,
            })

            local count = 0
            for k,v in pairs(DBOUTFITS) do
                UIDropDownMenu_AddButton({
                    text = k,
                    value = k,
                    func = SelectButtonFunc,
                    keepShownOnClick = true,
                    checked = false,
                })
                count = count + 1
            end
            if ( count == 0 ) then
                UIDropDownMenu_AddButton({
                    text = "|cff777777"..L["noOutfits"].."|r",
                    isTitle = true,
                })
            end

        end)
        dropDownButton.selectedValue = selectedOutfit or ""
        UIDropDownMenu_Refresh(dropDownButton)
    end
    refreshOutfitsMenu()
end

------------------------------------------------------------------------

InitializeOutfitsOptionsDropDown = function()
InitializeOutfitsOptionsDropDown = function() end

    local dropDownButton = DressUpFrameOutfitsOptionsButton
    local dropDownMenu = DressUpFrameOutfitsOptionsButtonMenu

    local TitleButton = {
                text = L["yourOptions"],
                isTitle = true,
                notCheckable = true,
            }

    local CreateUndressedButton = {
                text = L["createUndressedOutfit"],
                func = function(self, arg1, arg2, checked)
                    self.checked = false
                    AgiDialogs:Show("WARDROBE_DIALOG", {
                        text = L["enterNameOfOutfit"],
                        hasEditBox = true,
                        button1 = L["OK"],
                        button2 = L["cancel"],
                        OnAccept = function(self)
                            createOutfit(self.editBox:GetText())
                            refreshOutfitsMenu()
                        end,
                        OnCancel = function(self)
                        end,
                    })
                end,
            }
    local CreateDressedButton = {
                text = L["createDressedOutfit"],
                func = function(self, arg1, arg2, checked)
                    self.checked = false
                    AgiDialogs:Show("WARDROBE_DIALOG", {
                        text = L["enterNameOfOutfit"],
                        hasEditBox = true,
                        button1 = L["OK"],
                        button2 = L["cancel"],
                        OnAccept = function(self)
                            createOutfit(self.editBox:GetText(), 1)
                            refreshOutfitsMenu()
                        end,
                        OnCancel = function(self)
                        end,
                    })
                end,
            }
    local DeleteButton = {
                text = L["deleteOutfit"],
                func = function(self, arg1, arg2, checked)
                    self.checked = false
                    AgiDialogs:Show("WARDROBE_DIALOG", {
                        text = format(L["confirmDeleteOutfit"], selectedOutfit),
                        hasEditBox = false,
                        button1 = L["yes"],
                        button2 = L["no"],
                        OnAccept = function(self)
                            deleteOutfit(selectedOutfit)
                            refreshOutfitsMenu()
                        end,
                        OnCancel = function(self)
                        end,
                    })
                end,
            }
    local RenameButton = {
                text = L["renameOutfit"],
                func = function(self, arg1, arg2, checked)
                    self.checked = false
                    AgiDialogs:Show("WARDROBE_DIALOG", {
                        text = L["enterNameOfOutfit"],
                        hasEditBox = true,
                        button1 = L["OK"],
                        button2 = L["cancel"],
                        OnAccept = function(self)
                            renameOutfit(selectedOutfit, self.editBox:GetText())
                            refreshOutfitsMenu()
                        end,
                        OnCancel = function(self)
                        end,
                        OnShow = function(self)
                            self.editBox:SetText(selectedOutfit)
                        end,
                    })
                end,
            }

    refreshOutfitsOptionsMenu = function()
        UIDropDownMenu_Initialize(dropDownButton, function()
            DeleteButton.disabled = not selectedOutfit
            RenameButton.disabled = not selectedOutfit
            UIDropDownMenu_AddButton(TitleButton)
            UIDropDownMenu_AddButton(CreateDressedButton)
            UIDropDownMenu_AddButton(CreateUndressedButton)
            UIDropDownMenu_AddButton(DeleteButton)
            UIDropDownMenu_AddButton(RenameButton)
        end)
    end
    refreshOutfitsOptionsMenu()
end

------------------------------------------------------------------------

InitializeWardrobeDropDowns = function()
InitializeWardrobeDropDowns = function() end

    do

        local SelectButtonFunc = function(self, arg1, arg2, checked)
            searchEquipLoc[self.value] = self.checked or nil
            --searchSubTypes = {}
            refreshWardrobeItemTypeMenu()
            ToggleDropDownMenu(1, nil, WardrobeMenuFrameItemSlotButton)
        end

        UIDropDownMenu_Initialize(WardrobeMenuFrameItemSlotButton, function()
            local sortedList = {}
            for k,v in pairs(ITEMLOC2SLOTNAME) do
                if ( k == "INVTYPE_SHIELD" ) then
                    sortedList[_G[k].." ("..L["shield"]..")"] = k
                elseif ( k == "INVTYPE_WEAPONOFFHAND" ) then
                    sortedList[_G[k].." ("..L["weapon"]..")"] = k
                else
                sortedList[_G[k]] = k
                end
            end
            for k,v in pairsByKeys(sortedList) do
                UIDropDownMenu_AddButton({
                    text = k,
                    value = v,
                    func = SelectButtonFunc,
                    keepShownOnClick = true,
                    checked = ( searchEquipLoc[v] ),
                })
            end
        end)

    end
    do

        local SelectButtonFunc = function(self, arg1, arg2, checked)
            searchRarities[self.value] = self.checked or nil
        end

        UIDropDownMenu_Initialize(WardrobeMenuFrameItemRarityButton, function()
            for i=MIN_RARITY,MAX_RARITY do
                local r, g, b, hex = GetItemQualityColor(i)
                UIDropDownMenu_AddButton({
                    text = hex.._G["ITEM_QUALITY"..i.."_DESC"].."|r",
                    value = i,
                    func = SelectButtonFunc,
                    keepShownOnClick = true,
                    checked = ( searchRarities[i] ),
                })
            end
        end)

    end
    do

        refreshWardrobeInputs = function()
            WardrobeMenuFrameItemIDMinInput:SetText(searchMinItemID)
            WardrobeMenuFrameItemIDMaxInput:SetText(searchMaxItemID)
            WardrobeMenuFrameItemLevelMinInput:SetText(searchMinItemLvl)
            WardrobeMenuFrameItemLevelMaxInput:SetText(searchMaxItemLvl)
            WardrobeMenuFrameRequireLevelInput:SetText(searchMaxCharLvl)
        end
        refreshWardrobeInputs()

    end
    do

        local SelectButtonFunc = function(self, arg1, arg2, checked)
            searchSortBy = self.value
            WardrobeMenuFrameSortByButton.selectedValue = searchSortBy
            UIDropDownMenu_Refresh(WardrobeMenuFrameSortByButton)
        end

        UIDropDownMenu_Initialize(WardrobeMenuFrameSortByButton, function()
            for i=1,#SORTBY_OPTIONS do
                UIDropDownMenu_AddButton({
                    text = L[SORTBY_OPTIONS[i]],
                    value = SORTBY_OPTIONS[i],
                    func = SelectButtonFunc,
                    keepShownOnClick = true,
                })
            end
        end)
        WardrobeMenuFrameSortByButton.selectedValue = searchSortBy
        UIDropDownMenu_Refresh(WardrobeMenuFrameSortByButton)

    end
    do

        local SelectButtonFunc = function(self, arg1, arg2, checked)
            searchSortOrder = self.value
            WardrobeMenuFrameSortOrderButton.selectedValue = searchSortOrder
            UIDropDownMenu_Refresh(WardrobeMenuFrameSortOrderButton)
        end

        UIDropDownMenu_Initialize(WardrobeMenuFrameSortOrderButton, function()
            UIDropDownMenu_AddButton({
                text = L[SORTBY_ASC],
                value = SORTBY_ASC,
                func = SelectButtonFunc,
                keepShownOnClick = true,
            })
            UIDropDownMenu_AddButton({
                text = L[SORTBY_DESC],
                value = SORTBY_DESC,
                func = SelectButtonFunc,
                keepShownOnClick = true,
            })
        end)
        WardrobeMenuFrameSortOrderButton.selectedValue = searchSortOrder
        UIDropDownMenu_Refresh(WardrobeMenuFrameSortOrderButton)

    end
    do

        local SelectButtonFunc = function(self, arg1, arg2, checked)
            searchSubTypes[self.value] = self.checked or nil
        end

        refreshWardrobeItemTypeMenu = function()
            UIDropDownMenu_Initialize(WardrobeMenuFrameItemTypeButton, function()

                local listWeapon = false
                local listArmor = false
                local anyLocationChecked = false
                for k,v in pairs(searchEquipLoc) do
                    anyLocationChecked = true
                    if ( ITEMLOC2ITEMTYPE[k] == ITEMTYPE_ARMOR ) then
                        listArmor = true
                    end
                    if ( ITEMLOC2ITEMTYPE[k] == ITEMTYPE_WEAPON ) then
                        listWeapon = true
                    end
                end
                if ( not anyLocationChecked ) then
                        listArmor = true
                        listWeapon = true
                end

                if ( listArmor ) then
                    UIDropDownMenu_AddButton({
                        text = L["armor"],
                        isTitle = true,
                        notCheckable = true,
                    })
                    for i=1,#ITEMSUBTYPES_ARMOR do
                        UIDropDownMenu_AddButton({
                            text = ITEMSUBTYPES_ARMOR[i],
                            value = ITEMTYPE_ARMOR..ITEMSUBTYPES_ARMOR[i],
                            func = SelectButtonFunc,
                            keepShownOnClick = true,
                            checked = ( searchSubTypes[ITEMTYPE_ARMOR..ITEMSUBTYPES_ARMOR[i]] ),
                        })
                    end
                end

                if ( listWeapon ) then
                    UIDropDownMenu_AddButton({
                        text = L["weapon"],
                        isTitle = true,
                        notCheckable = true,
                    })
                    for i=1,#ITEMSUBTYPES_WEAPON do
                        UIDropDownMenu_AddButton({
                            text = ITEMSUBTYPES_WEAPON[i],
                            value = ITEMTYPE_WEAPON..ITEMSUBTYPES_WEAPON[i],
                            func = SelectButtonFunc,
                            keepShownOnClick = true,
                            checked = ( searchSubTypes[ITEMTYPE_WEAPON..ITEMSUBTYPES_WEAPON[i]] ),
                        })
                    end
                end

            end)
        end
        refreshWardrobeItemTypeMenu()

    end

end

------------------------------------------------------------------------

------------------------------------------------------------------------
-- FUNCTIONS: OUTFITS
------------------------------------------------------------------------

createOutfit = function(newName, copyCurrent)
    if ( not newName ) then
        newName = L["newOutfit"]
    end
    newName = strtrim(newName)
    if ( newName == "" ) then
        return
    end
    if ( DBOUTFITS[newName] ) then
        local i = 1
        local j = newName
        while ( DBOUTFITS[newName] ) do
            newName = j.." ("..i..")"
            i = i + 1
        end
    end
    DBOUTFITS[newName] = {}
    for slotName,v in pairs(SLOTNAMES) do
        DBOUTFITS[newName][slotName] = {}
    end

    if ( copyCurrent ) then
        for slotName,v in pairs(dressSlotItems) do
            DBOUTFITS[newName][slotName][1] = v.shownItemID
        end
    end

    selectedOutfit = newName
    DressUpModel:Dress()
end

deleteOutfit = function(outfitName)
    if ( not outfitName ) then
        return
    end
    DBOUTFITS[outfitName] = nil
    if ( outfitName == selectedOutfit ) then
        selectedOutfit = nil
    end
    DressUpModel:Dress()
end

setDefaultOutfit = function()
    selectedOutfit = nil
    DressUpModel:Dress()
end

selectOutfit = function(outfitName)
    if ( not outfitName ) then
        selectedOutfit = nil
        DressUpModel:Dress()
        return
    end
    if ( not DBOUTFITS[outfitName] ) then
        return
    end
    selectedOutfit = outfitName
    DressUpModel:Dress()
end

renameOutfit = function(oldName, newName)
    if ( not oldName or not newName ) then
        return
    end
    if ( not DBOUTFITS[oldName] ) then
        return
    end
    if ( oldName == newName ) then
        return
    end
    newName = strtrim(newName)
    if ( newName == "" ) then
        return
    end
    local oldOutfit = DBOUTFITS[oldName]
    DBOUTFITS[oldName] = nil
    if ( DBOUTFITS[newName] ) then
        local i = 1
        local j = newName
        while ( DBOUTFITS[newName] ) do
            newName = j.." ("..i..")"
            i = i + 1
        end
    end
    DBOUTFITS[newName] = oldOutfit
    if ( oldName == selectedOutfit ) then
        selectedOutfit = newName
    end
    DressUpModel:Dress()
end

------------------------------------------------------------------------

------------------------------------------------------------------------
-- FUNCTIONS: MODEL REFRESH
------------------------------------------------------------------------

local DressUpModelDress = DressUpModel.Dress
ResetDressUpModel2Default = function()

    -- we came from OnShow... 
    local tryOnItemID = IsTryingOnOnShow
    IsTryingOnOnShow = nil

    DressUpModelDress(DressUpModel)
    -- update: dont show dress slots on normal dress
    --SetDressSlotsToInventory()
    HideDressSlots()

end

ResetDressUpModel2Outfit = function()

    -- we came from OnShow... 
    local tryOnItemID = IsTryingOnOnShow
    IsTryingOnOnShow = nil

    DressUpModel:Undress()

    -- update: show dress slots on on outfits
    ShowDressSlots()

    local slotName
    local outfit = DBOUTFITS[selectedOutfit]

    for slotName,slotItems in pairs(outfit) do
        if ( slotName ~= "MainHandSlot" and slotName ~= "SecondaryHandSlot" and slotName ~= "RangedSlot") then
            if ( slotItems[1] ) then
                --SetDressSlotItem(slotName, slotItems[1])
                DressUpModel:TryOn(slotItems[1])
            end
        end
    end

    -- tryon weapons backwards because
    -- on normal model reset only the main hand weapon is shown

    slotName = "RangedSlot"
    if ( outfit[slotName] and outfit[slotName][1] ) then
        DressUpModel:TryOn(outfit[slotName][1])
    end
    slotName = "SecondaryHandSlot"
    if ( outfit[slotName] and outfit[slotName][1] ) then
        DressUpModel:TryOn(outfit[slotName][1])
    end
    slotName = "MainHandSlot"
    if ( outfit[slotName] and outfit[slotName][1] ) then
        DressUpModel:TryOn(outfit[slotName][1])
    end

    -- we came from OnShow... 
    if ( tryOnItemID ) then
        DressUpModel:TryOn(tryOnItemID)
    end

end

ResetDressUpModel = function()
    ResetDressUpModelInterval = AgiTimers:SetInterval(function()
        AgiTimers:ClearInterval(ResetDressUpModelInterval)
        ResetDressUpModelInterval = nil
        if ( selectedOutfit ) then
            ResetDressUpModel2Outfit()
        else
            ResetDressUpModel2Default()
        end
    end, 0.01)
end

------------------------------------------------------------------------

------------------------------------------------------------------------
-- FUNCTIONS: DRESSSLOTS
------------------------------------------------------------------------

SetDressSlotItem = function(slotName, itemID, textureName)
    if ( itemID ) then
        if ( not dressSlotItems[slotName] ) then
            dressSlotItems[slotName] = {
                shownItemID     = nil,
                shownTexture    = nil,
                isLocked        = nil
            }
        end
        if ( not textureName ) then
            textureName = select(10, GetItemInfo(itemID))
        end
        dressSlotItems[slotName].shownItemID = itemID
        dressSlotItems[slotName].shownTexture = textureName
        dressSlotItems[slotName].isLocked = nil
    else
        dressSlotItems[slotName] = nil
    end
    DressUpFrameSlotButton_Update(getglobal("DressUpFrame"..slotName))
    DressUpFrameSlotButton_UpdateLock(getglobal("DressUpFrame"..slotName))
end

ClearDressSlots = function()
    for slotName,v in pairs(dressSlotItems) do
        SetDressSlotItem(slotName, nil)
    end
end

SetDressSlotsToInventory = function()
    local slotName, slotID, slotTex, slotRelic, itemID, textureName
    for slotName,v in pairs(SLOTNAMES) do
        slotID, slotTex, slotRelic = GetInventorySlotInfo(slotName)
        itemID = GetInventoryItemID("player", slotID)
        textureName = GetInventoryItemTexture("player", slotID)
        SetDressSlotItem(slotName, itemID, textureName)
    end
    -- the range item is not shown on reset
    slotName = "RangedSlot"
    if ( dressSlotItems[slotName] ) then
        dressSlotItems[slotName].isLocked = 1
        DressUpFrameSlotButton_UpdateLock(getglobal("DressUpFrame"..slotName))
    end
    -- check hidden cloak
    if ( not ShowingCloak() ) then
        slotName = "BackSlot"
        if ( dressSlotItems[slotName] ) then
            dressSlotItems[slotName].isLocked = 1
            DressUpFrameSlotButton_UpdateLock(getglobal("DressUpFrame"..slotName))
        end
    end
    -- check hidden helm
    if ( not ShowingHelm() ) then
        slotName = "HeadSlot"
        if ( dressSlotItems[slotName] ) then
            dressSlotItems[slotName].isLocked = 1
            DressUpFrameSlotButton_UpdateLock(getglobal("DressUpFrame"..slotName))
        end
    end

end

HideDressSlots = function()
    for slotName,slotButton in pairs(dressSlots) do
        slotButton:Hide()
    end
end

ShowDressSlots = function()
    for slotName,slotButton in pairs(dressSlots) do
        slotButton:Show()
    end
end

TryOnDressItem = function(itemID)

    local itemName, itemLink, _, _, _, itemType, itemSubType, _, equipLoc = GetItemInfo(itemID)
    if ( not ITEMLOC2SLOTNAME[equipLoc] ) then
        return
    end
    local slotName = ITEMLOC2SLOTNAME[equipLoc]
    local clears   = ITEMLOC_REMOVES[equipLoc]
    local hides    = ITEMLOC_HIDES[equipLoc]

    if ( slotName ) then
        SetDressSlotItem(slotName, itemID)
    end

    if ( clears ) then
        for i=1,#clears do
            SetDressSlotItem(clears[i], nil)
        end
    end

    if ( slotName == "SecondaryHandSlot" ) then
        if ( dressSlotItems["MainHandSlot"] ) then
            local _itemID = dressSlotItems["MainHandSlot"].shownItemID
            local _itemLoc = select(9, GetItemInfo(_itemID))
            if ( ITEMLOC_REMOVES[_itemLoc] ) then
                clears = ITEMLOC_REMOVES[_itemLoc]
                if ( clears ) then
                    for i=1,#clears do
                        if ( clears[i] == "SecondaryHandSlot" ) then
                            SetDressSlotItem("MainHandSlot", nil)
                        end
                    end
                end
            end
        end
    end

    if ( hides ) then
        local _slotName, __slotName
        for i=1,#hides do
            _slotName = hides[i]
            if ( dressSlotItems[_slotName] ) then
                dressSlotItems[_slotName].isLocked = true
                DressUpFrameSlotButton_UpdateLock(getglobal("DressUpFrame".._slotName))
            end
        end
    end

end

------------------------------------------------------------------------

------------------------------------------------------------------------
-- FUNCTIONS: DRESSSLOT DIALOG
------------------------------------------------------------------------

CloseSlotDialog = function()
    if ( currentSelectedSlotName ) then
        getglobal("DressUpFrame"..currentSelectedSlotName).highlight:Hide()
        if ( slotName == currentSelectedSlotName ) then
            slotName = nil
        end
        currentSelectedSlotName = nil
    end
    DressUpFrameSlotDialog:Hide()
    DressUpFrameOutfitsButton:Show()
end

UpdateSlotDialog = function()
    if ( not selectedOutfit or not currentSelectedSlotName ) then
        return
    end
    local slotName = currentSelectedSlotName
    local savedOutfit = DBOUTFITS[selectedOutfit]
    local itemID, textureName, button
    for i=1,#DressUpFrameSlotDialog.itemButtons do
        button = DressUpFrameSlotDialog.itemButtons[i]
        itemID = savedOutfit[slotName][i] or 0
        textureName = select(10, GetItemInfo(itemID))
        if ( textureName ) then
            button.hasItem = 1
        else
            button.hasItem = nil
        end
        SetItemButtonTexture(button, textureName)
    end
    -- force slot highlight
    -- if cursor holds item BEFORE showing dialog
    for i=1,#DressUpFrameSlotDialog.itemButtons do
        DressUpFrameSlotDialogButton_OnEvent(DressUpFrameSlotDialog.itemButtons[i], "CURSOR_UPDATE")
    end
end

ToggleSlotDialog = function(slotName)
    if ( currentSelectedSlotName ) then
        getglobal("DressUpFrame"..currentSelectedSlotName).highlight:Hide()
        if ( slotName == currentSelectedSlotName ) then
            slotName = nil
        end
        currentSelectedSlotName = nil
        DressUpFrameSlotDialog:Hide()
        DressUpFrameOutfitsButton:Show()
    end
    if ( slotName and selectedOutfit ) then
        currentSelectedSlotName = slotName
        getglobal("DressUpFrame"..currentSelectedSlotName).highlight:Show()
        DressUpFrameSlotDialog:Show()
        DressUpFrameOutfitsButton:Hide()
        UpdateSlotDialog()
    end
end

------------------------------------------------------------------------

------------------------------------------------------------------------
-- FUNCTIONS: SEARCHING & PAGING
------------------------------------------------------------------------

searchingShowPage = function()

    if ( searchingCurrentPage == 1 ) then
        WardrobeFramePrevPageButton:Disable()
    else
        WardrobeFramePrevPageButton:Enable()
    end

    if ( searchingCurrentPage == searchingPagesCount ) then
        WardrobeFrameNextPageButton:Disable()
    else
        WardrobeFrameNextPageButton:Enable()
    end

    local searchingIndexStart = (searchingCurrentPage-1) * searchingItemsPerPage
    local searchingIndexEnd   = min(searchingIndexStart+searchingItemsPerPage, #searchingFoundItems)
    searchingIndexStart = searchingIndexStart + 1

    searchingRowsItems = {}
    for searchingIndex=searchingIndexStart,searchingIndexEnd do
        searchingRowsItems[#searchingRowsItems+1] = searchingFoundItems[searchingIndex]
    end
    WardrobeItemsFrameScrollFrame_Update()

    WardrobeFrameItemStatus:SetText(format(L["menuSearchItemStatus"], searchingIndexStart, searchingIndexEnd, #searchingFoundItems))
    WardrobeFramePageStatus:SetText(format(L["menuSearchPageStatus"], searchingCurrentPage, searchingPagesCount))

end

searchingShowNextPage = function()
    searchingCurrentPage = searchingCurrentPage + 1
    FauxScrollFrame_ScrollToTop(WardrobeItemsFrameScrollFrame)
    searchingShowPage()
end

searchingShowPrevPage = function()
    searchingCurrentPage = searchingCurrentPage - 1
    FauxScrollFrame_ScrollToTop(WardrobeItemsFrameScrollFrame)
    searchingShowPage()
end

searchingStart = function()

    local searchIgnoreRarities = true
    for k,v in pairs(searchRarities) do
        searchIgnoreRarities = false
    end

    local searchIgnoreEquipLoc = true
    for k,v in pairs(searchEquipLoc) do
        searchIgnoreEquipLoc = false
    end

    local searchIgnoreItemType = true
    for k,v in pairs(searchSubTypes) do
        searchIgnoreItemType = false
    end

    searchMinItemID = tonumber(WardrobeMenuFrameItemIDMinInput:GetText()) or MIN_ITEMID
    searchMaxItemID = tonumber(WardrobeMenuFrameItemIDMaxInput:GetText()) or searchMinItemID
    searchMinItemLvl = tonumber(WardrobeMenuFrameItemLevelMinInput:GetText()) or MIN_ITEMLVL
    searchMaxItemLvl = tonumber(WardrobeMenuFrameItemLevelMaxInput:GetText()) or MAX_ITEMLVL
    searchMaxCharLvl = tonumber(WardrobeMenuFrameRequireLevelInput:GetText()) or MAX_CHARLVL
    local searchBySubStr = strupper(strtrim(WardrobeMenuFrameItemNameInput:GetText() or ""))

    if ( searchMinItemID > searchMaxItemID ) then
        local _ = searchMinItemID
        searchMinItemID = searchMaxItemID
        searchMaxItemID = _
    end
    searchMinItemID = max(searchMinItemID, MIN_ITEMID)
    searchMaxItemID = min(searchMaxItemID, MAX_ITEMID)

    if ( searchMinItemLvl > searchMaxItemLvl ) then
        local _ = searchMinItemLvl
        searchMinItemLvl = searchMaxItemLvl
        searchMaxItemLvl = _
    end
    searchMinItemLvl = max(searchMinItemLvl, MIN_ITEMLVL)
    searchMaxItemLvl = min(searchMaxItemLvl, MAX_ITEMLVL)

    searchMaxCharLvl = min(80, max(1, searchMaxCharLvl))

    local _, itemName, itemLink, itemRarity, itemLevel, itemReqLevel, itemClass, itemSubClass, itemMaxStack, itemEquipLoc, itemTexture, itemPrice

    local function searchingCheckItem(itemID)
        if ( itemLevel > searchMaxItemLvl ) then return nil end
        if ( itemLevel < searchMinItemLvl ) then return nil end
        if ( itemReqLevel > searchMaxCharLvl ) then return nil end
        if ( itemRarity < MIN_RARITY ) then return nil end
        if ( itemRarity > MAX_RARITY ) then return nil end
        if ( not searchIgnoreRarities ) then
            if ( not searchRarities[itemRarity] ) then
                return nil
            end
        end
        if ( not ITEMLOC2SLOTNAME[itemEquipLoc] ) then return nil end
        if ( not searchIgnoreEquipLoc ) then
            if ( not searchEquipLoc[itemEquipLoc] ) then
                return nil
            end
        end
        if ( not searchIgnoreItemType ) then
            if ( not searchSubTypes[itemClass..itemSubClass] ) then
                return nil
            end
        end
        if ( searchBySubStr ) then
            if ( not strfind(itemName, searchBySubStr) ) then
                return nil
            end
        end
        return 1
    end

    local searchingSortKeyToIndex = {}
    local searchingSortIndexToItem = {}
    local i = 0
    for itemID=searchMinItemID,searchMaxItemID do
        itemName, itemLink, itemRarity, itemLevel, itemReqLevel, itemClass, itemSubClass, itemMaxStack, itemEquipLoc, itemTexture, itemPrice = GetItemInfo(itemID)
        if ( itemName ) then
            itemName = strupper(itemName)
            if ( searchingCheckItem(itemID) ) then
                i = i + 1

                if ( searchSortBy == SORTBY_ITEMID ) then
                    _ = itemID..""
                    _ = strrep("0", STRLEN_ITEMID-strlen(_)).._
                elseif ( searchSortBy == SORTBY_ITEMNAME ) then
                    _ = itemName
                elseif ( searchSortBy == SORTBY_ITEMLVL ) then
                    _ = itemLevel..""
                    _ = strrep("0", STRLEN_ITEMLVL-strlen(_)).._
                elseif ( searchSortBy == SORTBY_ITEMRARITY ) then
                    _ = itemRarity..""
                elseif ( searchSortBy == SORTBY_ITEMPRICE ) then
                    _ = itemPrice..""
                    _ = strrep("0", STRLEN_ITEMPRICE-strlen(_)).._
                elseif ( searchSortBy == SORTBY_ITEMREQLVL ) then
                    _ = itemReqLevel..""
                    _ = strrep("0", STRLEN_CHARLVL-strlen(_)).._
                end
                searchingSortKeyToIndex[_..i] = i
                searchingSortIndexToItem[i] = itemID
            end
        end
    end

    searchingCurrentPage = 0
    searchingItemsPerPage = searchItemsPerPage
    searchingPagesCount = ceil(i / searchingItemsPerPage)
    searchingFoundItems = {}

    i = 1
    for k,v in pairsByKeys(searchingSortKeyToIndex) do
        searchingFoundItems[i] = searchingSortIndexToItem[v]
        i = i + 1
    end

    if ( searchSortOrder == SORTBY_ASC ) then
        -- do nothing
    else
        treverse(searchingFoundItems)
    end

    searchingShowNextPage()
    refreshWardrobeInputs()
end

------------------------------------------------------------------------

------------------------------------------------------------------------
-- EVENTS: SLOT BUTTONS
------------------------------------------------------------------------

function DressUpFrameSlotButton_OnLoad(self)
    self:RegisterForDrag("LeftButton")
    self:RegisterForClicks("LeftButtonUp", "RightButtonUp")
	self:RegisterEvent("MODIFIER_STATE_CHANGED")
    local slotButtonName = self:GetName()
    local slotName = strsub(slotButtonName,13)
    local id, textureName, checkRelic = GetInventorySlotInfo(slotName)
    self:SetID(id)
    local texture = getglobal(slotButtonName.."IconTexture")
    texture:SetTexture(textureName)
    self.backgroundTextureName = textureName
    self:SetFrameLevel(100) -- set icon in front of model
    --self.UpdateTooltip = DressUpFrameSlotButton_OnEnter
    self.highlight = getglobal(slotButtonName.."Highlight")
    dressSlots[slotName] = self
end

function DressUpFrameSlotButton_OnEnter(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    local slotButtonName = self:GetName()
    local slotName = strsub(slotButtonName,13)
    if ( dressSlotItems[slotName] ) then
        local itemName, itemLink = GetItemInfo(dressSlotItems[slotName].shownItemID)
        if (itemLink) then
            GameTooltip:SetHyperlink(itemLink)
        else
            GameTooltip:SetText(SLOTNAMES[slotName])
        end
    else
        GameTooltip:SetText(SLOTNAMES[slotName])
    end
    --GameTooltip:Show()
    self.isMouseOver = true
    CursorUpdate(self)
end

function DressUpFrameSlotButton_OnLeave(self)
    self.isMouseOver = nil
    GameTooltip:Hide()
    ResetCursor()
end

function DressUpFrameSlotButton_OnClick(self, button)
    local slotButtonName = self:GetName()
    local slotName = strsub(slotButtonName,13)
    if ( button == "LeftButton" ) then
        if ( IsControlKeyDown() ) then
            if ( dressSlotItems[slotName] ) then
                DressUpModel:TryOn(dressSlotItems[slotName].shownItemID)
            end
        else
            ToggleSlotDialog(slotName)
        end
    elseif ( button == "RightButton" ) then
    end
end

function DressUpFrameSlotButton_OnShow(self)
    DressUpFrameSlotButton_Update(self)
end

function DressUpFrameSlotButton_OnHide(self)
-- nothing
end

function DressUpFrameSlotButton_OnEvent(self, event, ...)
    local arg1, arg2 = ...;
    if ( event == "MODIFIER_STATE_CHANGED" and self.isMouseOver ) then
        CursorUpdate(self)
        return
    end
end

function DressUpFrameSlotButton_Update(self)
    local slotButtonName = self:GetName()
    local slotName = strsub(slotButtonName,13)
    if ( dressSlotItems[slotName] ) then
        local itemID = dressSlotItems[slotName].shownItemID or 0
        local textureName = dressSlotItems[slotName].shownTexture or nil
        SetItemButtonTexture(self, textureName)
        self.hasItem = 1
    else
        SetItemButtonTexture(self, self.backgroundTextureName);
        self.hasItem = nil
    end
end

function DressUpFrameSlotButton_OnDragStart(self)
    local slotButtonName = self:GetName()
    local slotName = strsub(slotButtonName,13)
    if ( dressSlotItems[slotName] and currentSelectedSlotName ) then
        local itemID = dressSlotItems[slotName].shownItemID
        PickupItem(itemID)
    end
end

function DressUpFrameSlotButton_OnDragStop(self)
    if ( cursorOverSlotDialogButton ) then
        DressUpFrameSlotDialogButton_OnEnter(cursorOverSlotDialogButton)
    else
        ClearCursor()
    end
end

function DressUpFrameSlotButton_OnReceiveDrag(self)
-- nothing
end

function DressUpFrameSlotButton_UpdateLock(self)
    local slotButtonName = self:GetName()
    local slotName = strsub(slotButtonName,13)
    if ( dressSlotItems[slotName] and dressSlotItems[slotName].isLocked ) then
        SetItemButtonDesaturated(self, 1, 0.5, 0.5, 0.5)
    else
        SetItemButtonDesaturated(self, nil)
    end
end

------------------------------------------------------------------------

------------------------------------------------------------------------
-- EVENTS: SLOT DIALOG BUTTONS
------------------------------------------------------------------------

function DressUpFrameSlotDialogButton_OnLoad(self)
    self:RegisterForDrag("LeftButton")
    self:RegisterForClicks("LeftButtonUp", "RightButtonUp")
	self:RegisterEvent("MODIFIER_STATE_CHANGED")
    local slotButtonName = self:GetName()
    self.highlight = getglobal(slotButtonName.."Highlight")
end

function DressUpFrameSlotDialogButton_OnShow(self)
    self:RegisterEvent("CURSOR_UPDATE")
end

function DressUpFrameSlotDialogButton_OnHide(self)
    self:UnregisterEvent("CURSOR_UPDATE")
end

function DressUpFrameSlotDialogButton_OnEvent(self, event, ...)
    local arg1, arg2 = ...
    if ( event == "MODIFIER_STATE_CHANGED" ) then
        if ( cursorOverSlotDialogButton == self ) then
            CursorUpdate(self)
        end
        return
    end
    if ( event == "CURSOR_UPDATE" ) then

        if ( selectedOutfit) then
            if ( itemOnCursorCameFromSlot ) then
                DBOUTFITS[selectedOutfit][currentSelectedSlotName][itemOnCursorCameFromSlot.ID] = nil
                itemOnCursorCameFromSlot = nil
                UpdateSlotDialog()
            end
        end

        self:UnlockHighlight()
        local cursorInfo, itemID = GetCursorInfo()
        if ( cursorInfo == "item" ) then
            local itemName, itemLink, _, _, _, _, _, _, equipLoc = GetItemInfo(itemID)
            if ( currentSelectedSlotName and ITEMLOC2SLOTNAME[equipLoc] == currentSelectedSlotName ) then
                self:LockHighlight()
            end
        end
        return
    end
end

function DressUpFrameSlotDialogButton_OnEnter(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    cursorOverSlotDialogButton = self
    local savedOutfit = DBOUTFITS[selectedOutfit]
    local itemID = savedOutfit[currentSelectedSlotName][self.ID]
    if ( itemID ) then
        local itemName, itemLink = GetItemInfo(itemID)
        if (itemLink) then
            GameTooltip:SetHyperlink(itemLink)
        end
    end
    self.isMouseOver = true
    CursorUpdate(self)
end

function DressUpFrameSlotDialogButton_OnLeave(self)
    cursorOverSlotDialogButton = nil
    GameTooltip:Hide()
    self.isMouseOver = nil
    ResetCursor()
end

function DressUpFrameSlotDialogButton_OnItemDrop(self)

    local savedOutfit = DBOUTFITS[selectedOutfit]
    local cursorInfo, itemID = GetCursorInfo()
    if ( cursorInfo == "item" ) then

        local itemName, itemLink, _, _, _, _, _, _, equipLoc = GetItemInfo(itemID)
        if ( ITEMLOC2SLOTNAME[equipLoc] ) then

            local slotName = ITEMLOC2SLOTNAME[equipLoc]
            if ( slotName == currentSelectedSlotName ) then

                if ( itemOnCursorCameFromSlot ) then
                    savedOutfit[currentSelectedSlotName][itemOnCursorCameFromSlot.ID] = nil
                    itemOnCursorCameFromSlot = nil
                end

                -- its the first slot so tryon automaticly
                if ( self.ID == 1 ) then
                    DressUpModel:TryOn(itemID)
                end

                local _itemID = savedOutfit[slotName][self.ID]
                savedOutfit[slotName][self.ID] = itemID
                if ( _itemID and _itemID ~= itemID ) then
                    PickupItem(_itemID)
                else
                    ClearCursor()
                end
                UpdateSlotDialog()
                DressUpFrameSlotDialogButton_OnEnter(self) -- force tooltip
            end
        end
    end
end

function DressUpFrameSlotDialogButton_OnClick(self, button)
    local savedOutfit = DBOUTFITS[selectedOutfit]
    local itemID = savedOutfit[currentSelectedSlotName][self.ID]
    if ( button == "LeftButton" ) then
        if ( IsControlKeyDown() ) then
            if ( itemID ) then
                DressUpModel:TryOn(itemID)
            end
        else
            if ( GetCursorInfo() == "item" ) then
                DressUpFrameSlotDialogButton_OnItemDrop(self)
            else
                if ( itemID ) then
                    PickupItem(itemID)
                    itemOnCursorCameFromSlot = self
                end
            end
        end
    elseif ( button == "RightButton" ) then
    end
end

function DressUpFrameSlotDialogButton_OnDragStart(self)
    local savedOutfit = DBOUTFITS[selectedOutfit]
    local itemID = savedOutfit[currentSelectedSlotName][self.ID]
    if ( itemID ) then
        PickupItem(itemID)
    end
end

function DressUpFrameSlotDialogButton_OnDragStop(self)
    local savedOutfit = DBOUTFITS[selectedOutfit]
    savedOutfit[currentSelectedSlotName][self.ID] = nil
    if ( not cursorOverSlotDialogButton ) then
        UpdateSlotDialog()
        ClearCursor()
    end
end

function DressUpFrameSlotDialogButton_OnReceiveDrag(self)
    if ( GetCursorInfo() == "item" ) then
        DressUpFrameSlotDialogButton_OnItemDrop(self)
    end
end

------------------------------------------------------------------------

------------------------------------------------------------------------
-- EVENTS: WARDROBE MENU
------------------------------------------------------------------------

function WardrobeItemsFrameScrollFrame_Update(self)

    local showRowsCount = 0
    if ( WardrobeMenuFrame:IsShown() ) then
        showRowsCount = ROWS_ON_MINIMIZED
    else
        showRowsCount = ROWS_ON_MAXIMIZED
    end
    FauxScrollFrame_Update(WardrobeItemsFrameScrollFrame, #searchingRowsItems, showRowsCount, ROWS_HEIGHT)

    local r, g, b, lineplusoffset
    local itemID, itemName, itemLink, itemRarity, itemLevel, itemReqLevel, itemClass, itemSubClass, itemMaxStack, itemEquipLoc, itemTexture, itemPrice

    for line=1,showRowsCount do
        lineplusoffset = line + FauxScrollFrame_GetOffset(WardrobeItemsFrameScrollFrame)
        if ( lineplusoffset <= #searchingRowsItems ) then

            itemID = searchingRowsItems[lineplusoffset]
            itemName, itemLink, itemRarity, itemLevel, itemReqLevel, itemClass, itemSubClass, itemMaxStack, itemEquipLoc, itemTexture, itemPrice = GetItemInfo(itemID) 
            r, g, b = GetItemQualityColor(itemRarity)

            searchingRowsFrames[line].name:SetText(itemName)
            searchingRowsFrames[line].name:SetTextColor(r, g, b)
            searchingRowsFrames[line].icon.texture:SetTexture(itemTexture)
            searchingRowsFrames[line]:Show()
        else
            searchingRowsFrames[line]:Hide()
        end
    end
    for line=showRowsCount+1,ROWS_ON_MAXIMIZED do
        searchingRowsFrames[line]:Hide()
    end

end

function WardrobeFrameSeperateUpButton_OnClick(self)
    WardrobeFrameSeperateDownButton:Show()
    self:Hide()
    WardrobeMenuFrame:Hide()
    WardrobeSeparateFrame:ClearAllPoints()
    WardrobeSeparateFrame:SetPoint("TOPLEFT", WardrobeContainer, "TOPLEFT")
    WardrobeItemsFrameScrollFrame_Update()
end

function WardrobeFrameSeperateDownButton_OnClick(self)
    WardrobeFrameSeperateUpButton:Show()
    self:Hide()
    WardrobeMenuFrame:Show()
    WardrobeSeparateFrame:ClearAllPoints()
    WardrobeSeparateFrame:SetPoint("TOPLEFT", WardrobeMenuFrame, "BOTTOMLEFT")
    WardrobeItemsFrameScrollFrame_Update()
end

function WardrobeFrameNextPageButton_OnClick(self)
    searchingShowNextPage()
end

function WardrobeFramePrevPageButton_OnClick(self)
    searchingShowPrevPage()
end

function WardrobeFrameSubmitButton_OnClick(self)
    searchingStart()
end

function WardrobeFrame_OnLoad(self)
    WardrobeFramePrevPageButton:Disable()
    WardrobeFrameNextPageButton:Disable()
    for i=1,ROWS_ON_MAXIMIZED do
        searchingRowsFrames[i] = getglobal("WardrobeItemsFrameItem"..i)
        searchingRowsFrames[i].ID = i
        searchingRowsFrames[i].icon.ID = i
    end
end

------------------------------------------------------------------------

------------------------------------------------------------------------
-- EVENTS: WARDROBE MENU ITEM BUTTONS
------------------------------------------------------------------------

function WardrobeItemsFrameItem_OnLoad(self)
    self:RegisterForDrag("LeftButton")
    self:RegisterForClicks("LeftButtonUp", "RightButtonUp")
	self:RegisterEvent("MODIFIER_STATE_CHANGED")
	self.hasItem = 1 -- if this slot has no item it will be hidden, so...
    self.texture = getglobal(self:GetName().."IconTexture")
end

function WardrobeItemsFrameItem_OnEvent(self, event, ...)
    local arg1, arg2 = ...
    if ( event == "MODIFIER_STATE_CHANGED" ) then
        if ( self.isMouseOver ) then
            CursorUpdate(self)
        end
        return
    end
end

function WardrobeItemsFrameItem_OnEnter(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    local itemID = searchingRowsItems[self.ID]
    local itemName, itemLink = GetItemInfo(itemID)
    if (itemLink) then
        GameTooltip:SetHyperlink(itemLink)
    end
    self.isMouseOver = true
    CursorUpdate(self)
end

function WardrobeItemsFrameItem_OnLeave(self)
    GameTooltip:Hide()
    self.isMouseOver = nil
    ResetCursor()
end

function WardrobeItemsFrameItem_OnClick(self, button)
    local itemID = searchingRowsItems[self.ID]
    if ( button == "LeftButton" ) then
        if ( IsControlKeyDown() ) then
            DressUpModel:TryOn(itemID)
        else
            PickupItem(itemID)
        end
    elseif ( button == "RightButton" ) then
    end
end

function WardrobeItemsFrameItem_OnDragStart(self)
    local itemID = searchingRowsItems[self.ID]
    PickupItem(itemID)
end

function WardrobeItemsFrameItem_OnDragStop(self)
    if ( cursorOverSlotDialogButton ) then
        DressUpFrameSlotDialogButton_OnEnter(cursorOverSlotDialogButton)
    else
        ClearCursor()
    end
end

function WardrobeItemsFrameItem_OnReceiveDrag(self)
    ClearCursor()
end

------------------------------------------------------------------------

------------------------------------------------------------------------
-- EVENTS: FRAMES AND BUTTONS
------------------------------------------------------------------------

function DressUpFrameUndressButton_OnClick(self)
    DressUpModel:Undress()
end

function DressUpFrameBackgroundButton_OnClick(self)
    refreshOutfitsMenu()
    ToggleDropDownMenu(1, nil, DressUpFrameBackgroundMenu, DressUpFrameBackgroundButton, 0, 0)
end

function DressUpFrameWardrobeButton_OnClick(self)
    if ( WardrobeFrame:IsShown() ) then
        WardrobeFrame:Hide()
    else
        WardrobeFrame:Show()
    end
end

function WardrobeFrameAboutButton_OnClick(self)
    local version = GetAddOnMetadata(ADDONNAME, "Version")
    local author = GetAddOnMetadata(ADDONNAME, "Author")
    local title = GetAddOnMetadata(ADDONNAME, "Title")
    local email = GetAddOnMetadata(ADDONNAME, "X-Email")
    local github = GetAddOnMetadata(ADDONNAME, "X-Github")
    print(title.."("..version..")")
    print(format(L["aboutText1"], author))
    print(format(L["aboutText2"], email))
    print(format(L["aboutText3"], github))
end

------------------------------------------------------------------------

------------------------------------------------------------------------
-- HOOKS
------------------------------------------------------------------------

-- we need to do a pre-hook here because
-- we need to reset position BEFORE Dress()

function DressUpModel:Dress()
    DressUpModel:ResetPosition()
    ResetDressUpModel()
end

hooksecurefunc(DressUpModel, "Undress", function(self)
    ClearDressSlots()
end)

hooksecurefunc(DressUpModel, "TryOn", function(self, item)
    -- first find item id
    local itemName, itemLink = GetItemInfo(item)
    local itemID   = ItemInfoByLink(itemLink)

    -- we came from OnShow
    if ( IsTryingOnOnShow ) then
        IsTryingOnOnShow = itemID
    end

    TryOnDressItem(itemID)
end)

DressUpFrame:HookScript("OnShow", function(self)
    IsTryingOnOnShow = 1
    ResetDressUpModel()
end)

DressUpFrame:HookScript("OnHide", function()
    WardrobeFrame:Hide()
end)

------------------------------------------------------------------------

------------------------------------------------------------------------
-- API / INIT
------------------------------------------------------------------------

function Wardrobe:AddCustomBackground(name, loca)
    if ( DressUpDefaultTexturePaths[name] ) then
        return false
    end
    DressUpCustomTexturePaths[name] = "Interface\\AddOns\\AgisWardrobe\\Textures\\"..name.."\\"
    DressUpCustomLocalization[name] = loca or {}
    return true
end

function Wardrobe:OnInitialize()
function Wardrobe:OnInitialize() end
    InitializeDatabase()
    InitializeModelFeatures()
    InitializeFrontend()
    InitializeBackgroundDropDown()
    InitializeOutfitsOptionsDropDown()
    InitializeOutfitsDropDown()
    InitializeWardrobeDropDowns()
end

------------------------------------------------------------------------
