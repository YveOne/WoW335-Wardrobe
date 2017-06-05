
-----------------------------------------------------------------------------------
local MAJOR, MINOR = "AgiTimers", 2
local AgiTimers, OldMinor = LibStub:NewLibrary(MAJOR, MINOR)
if ( not AgiTimers ) then return end -- No Upgrade needed.
-----------------------------------------------------------------------------------

local SetIntervalFrame = CreateFrame("FRAME");
local SetIntervals = {}
local SetIntervalI = 0

function AgiTimers:SetInterval(cb, t)
    SetIntervalI = SetIntervalI + 1
    if ( t ) then
        local x = 0
        SetIntervals[SetIntervalI] = function(elapsed)
            x = x + elapsed
            if ( x >= t ) then
                cb(x)
                x = 0
            end
        end
    else
        SetIntervals[SetIntervalI] = cb
    end
    return SetIntervalI
end

function AgiTimers:ClearInterval(i)
    SetIntervals[i] = nil
end

do
    local i,cb
    function SetIntervalFrame:OnUpdate(elapsed)
        for i,cb in pairs(SetIntervals) do
            cb(elapsed)
        end
    end
    SetIntervalFrame:SetScript("OnUpdate", SetIntervalFrame.OnUpdate);
end

-----------------------------------------------------------------------------------

local waitForQueue = {}
local waitForQueueCount = 0
local waitForFrame = CreateFrame("FRAME");
local function waitForOnUpdate(self, elapsed)
    local w4, timedout, conditionReturn
    for i=waitForQueueCount,1,-1 do
        w4 = waitForQueue[i]
        while true do

            if ( w4[5] ) then
                tremove(waitForQueue, i)
                waitForQueueCount = waitForQueueCount - 1
                break
            end

            if ( w4[1] ~= nil and w4[2] <= 0 ) then
                if ( w4[4](nil) ) then
                    w4[2] = w4[1]
                else
                    tremove(waitForQueue, i)
                    waitForQueueCount = waitForQueueCount - 1
                    break
                end
            else
                if ( w4[3] ~= nil ) then
                    conditionReturn = w4[3]()
                    if ( conditionReturn ~= nil ) then
                        if ( w4[4](conditionReturn) ) then
                            w4[2] = w4[1]
                        else
                            tremove(waitForQueue, i)
                            waitForQueueCount = waitForQueueCount - 1
                            break
                        end
                    end
                end
            end
            w4[2] = w4[2] - elapsed
            break
        end
    end
end
waitForFrame:SetScript("OnUpdate", waitForOnUpdate);

function AgiTimers:WaitFor(condition, callback, timeout)
    if ( type(condition) ~= "function" ) then
        condition = nil
    end
    if ( type(callback) ~= "function" ) then
        callback = function()
            return false
        end
    end
    local timeoutLeft = timeout
    if ( type(timeout) ~= "number" or timeout <= 0 ) then
        timeout = nil
        timeoutLeft = 0
    end
    waitForQueueCount = waitForQueueCount + 1
    waitForQueue[waitForQueueCount] = {
        timeout,
        timeoutLeft,
        condition,
        callback,
        false
    }
    return waitForQueueCount
end

function AgiTimers:WaitEnd(i)
    if ( i <= waitForQueueCount ) then
        waitForQueue[i][5] = true
    end
end

-----------------------------------------------------------------------------------
