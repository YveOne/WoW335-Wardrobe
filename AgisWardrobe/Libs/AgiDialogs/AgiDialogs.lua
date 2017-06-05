
-----------------------------------------------------------------------------------
local MAJOR, MINOR = "AgiDialogs", 5
local AgiDialogs, OldMinor = LibStub:NewLibrary(MAJOR, MINOR)
if ( not AgiDialogs ) then return end -- No Upgrade needed.
-----------------------------------------------------------------------------------
local AgiTimers  = LibStub("AgiTimers")
-----------------------------------------------------------------------------------

local shownDialogsMax = 4
local shownDialogsQueue = {}
local shownDialogs = 0

local lastTempDialogName = nil

local tmpDialogsI = 0
local function GetTmpDialogName()
    tmpDialogsI = tmpDialogsI + 1
    return "AgiDialogs"..tmpDialogsI
end

local function DisplayLoop()
    if ( lastTempDialogName ) then
        local sp
        for i=1,shownDialogsMax do
            sp = getglobal("StaticPopup"..i)
            if ( sp and not sp._tmpName ) then
                sp._tmpName = lastTempDialogName
                sp:HookScript("OnHide", function(self)
                    if ( self._tmpName ) then
                        StaticPopupDialogs[self._tmpName] = nil
                        self._tmpName = nil
                    end
                    shownDialogs = shownDialogs - 1
                end)
                lastTempDialogName = nil
                return
            end
        end
    else
        if ( #shownDialogsQueue > 0 and shownDialogs < shownDialogsMax ) then

            local dialogData = tremove(shownDialogsQueue, 1)
            local dialogName     = dialogData.dialogName    or ""
            local dialogValues   = dialogData.values        or {}
            local dialogArg1     = dialogData.arg1          or nil
            local dialogArg2     = dialogData.arg2          or nil

            if ( StaticPopupDialogs[dialogName] == nil ) then return end

            local oriDialog = StaticPopupDialogs[dialogName]
            local tmpDialogName = GetTmpDialogName()
            StaticPopupDialogs[tmpDialogName] = {}
            local tmpDialog = StaticPopupDialogs[tmpDialogName]

            lastTempDialogName = tmpDialogName
            shownDialogs = shownDialogs + 1

            for k,v in pairs(oriDialog) do
                tmpDialog[k] = v
            end

            for k,v in pairs(dialogValues) do
                tmpDialog[k] = v
            end

            StaticPopup_Show(tmpDialogName, dialogArg1, dialogArg2)

        end
    end
end
AgiTimers:SetInterval(DisplayLoop, 0.1)

function AgiDialogs:Show(dialogName, values, arg1, arg2)
    shownDialogsQueue[#shownDialogsQueue+1] = {
        dialogName = dialogName,
        values = values,
        arg1 = arg1,
        arg2 = arg2,
    }
end
