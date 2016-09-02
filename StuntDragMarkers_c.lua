-- PhrozenByte Stunt Drag Markers (SDM)
--
-- Copyright (C) 2015-2016  Daniel Rudolf <http://www.daniel-rudolf.de/>
--
-- This program is free software: you can redistribute it and/or modify it
-- under the terms of the GNU Affero General Public License as published
-- by the Free Software Foundation, version 3 of the License only.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU Affero General Public License for more details.
--
-- You should have received a copy of the GNU Affero General Public License
-- along with this program.  If not, see <http://www.gnu.org/licenses/>.

-- import phrozenbyte-debug as debug
debug, debugResourceName = exports["phrozenbyte-debug"], "phrozenbyte-debug"
addEventHandler("onClientResourceStart", root, function (res) if (getResourceName(res) == debugResourceName) then debug = exports[debugResourceName] end end)

--
-- editor mode
--
function onStart()
    debug:notice("edfClientScriptReader.onStart(stunt-drag-markers)")
    addEventHandler("onClientRender", root, drawEditorStuntDragMarker)
end

function onStop()
    debug:notice("edfClientScriptReader.onStop(stunt-drag-markers)")
    removeEventHandler("onClientRender", root, drawEditorStuntDragMarker)
end

function drawEditorStuntDragMarker()
    local marker = exports["editor_main"]:getSelectedElement()
    if (marker) then
        if (getElementData(marker, "edf:rep", false)) then marker = getElementParent(marker) end

        local markerType = exports["edf"]:edfGetElementProperty(marker, "type")
        if (string.sub(getElementType(marker), 1, 3) == "sdm") then
            if ((markerType == "ring") or ((getElementType(marker) == "sdmTeleportTarget") and (markerType == "checkpoint"))) then
                -- ignore rotation on Y axis, the marker acts mirror-inverted otherwise
                local markerPosition = Vector3(exports["edf"]:edfGetElementPosition(marker))
                local markerRotation = Vector3(exports["edf"]:edfGetElementRotation(marker))
                local markerMatrix = Matrix(markerPosition, Vector3(markerRotation.x, 0, markerRotation.z))

                local markerTarget = markerPosition + markerMatrix.forward
                setMarkerTarget(marker, markerTarget.x, markerTarget.y, markerTarget.z)
            end
        end
    end
end

--
-- vehicle magnet marker
--
magnetEnabled = false
magnetVehicles = {}
magnetLastRenderTick = nil
magnetGravityBaseFps = 50
magnetDebugIDs = nil

function enableVehicleMagnet(vehicle, mode)
    if ((vehicle == nil) or (getElementType(vehicle) ~= 'vehicle')) then
        vehicle = getPedOccupiedVehicle(localPlayer)

        if (not vehicle) then
            return
        end
    end
    if (mode == nil) then
        mode = "default"
    end

    local vehicleMagnetEnabled = false
    for _,checkVehicle in ipairs(magnetVehicles) do
        if (checkVehicle == vehicle) then
            vehicleMagnetEnabled = true
            break
        end
    end

    if (not vehicleMagnetEnabled) then
        -- add onClientRender event to render vehicle magnets
        if (#magnetVehicles == 0) then
            magnetEnabled = true
            magnetLastRenderTick = nil
            addEventHandler("onClientRender", root, renderVehicleMagnet)
        end

        -- remember mode
        setElementData(vehicle, "sdmVehicleMagnetMode", mode, false)

        -- remember old vehicle gravity as adjustment for the magnet gravity
        local adjustGravityX, adjustGravityY, adjustGravityZ = getVehicleGravity(vehicle)
        setElementData(vehicle, "sdmVehicleMagnetAdjustGravityX", adjustGravityX, false)
        setElementData(vehicle, "sdmVehicleMagnetAdjustGravityY", adjustGravityY, false)
        setElementData(vehicle, "sdmVehicleMagnetAdjustGravityZ", adjustGravityZ, false)

        -- disable GTAs gravity
        setVehicleGravity(vehicle, 0, 0, 0)

        -- register vehicle
        table.insert(magnetVehicles, vehicle)

        -- enable debugging
        enableVehicleMagnetDebugging(vehicle, mode)
    else
        -- reset debugging
        if (mode ~= getElementData(vehicle, "sdmVehicleMagnetMode", false)) then
            disableVehicleMagnetDebugging()
            enableVehicleMagnetDebugging(vehicle, mode)
        end

        -- update mode
        setElementData(vehicle, "sdmVehicleMagnetMode", mode, false)
    end
end

addEvent("onClientEnableVehicleMagnet", true)
addEventHandler("onClientEnableVehicleMagnet", resourceRoot, enableVehicleMagnet)

function disableVehicleMagnet(vehicle)
    if ((vehicle == nil) or getElementType(vehicle) ~= 'vehicle') then
        vehicle = getPedOccupiedVehicle(localPlayer)

        if (not vehicle) then
            return
        end
    end

    local vehicleIndex = nil
    for i,checkVehicle in ipairs(magnetVehicles) do
        if (checkVehicle == vehicle) then
            vehicleIndex = i
            break
        end
    end

    local mode = getElementData(vehicle, "sdmVehicleMagnetMode", false)
    if (vehicleIndex ~= nil) then
        -- unregister vehicle
        table.remove(magnetVehicles, i)

        -- use adjusted gravity to restore GTAs gravity
        -- please note: if a gravity marker is hit while the magnet was enabled,
        -- the gravity will be reset to the gravity of this marker!
        local adjustGravityX = getElementData(vehicle, "sdmVehicleMagnetAdjustGravityX", false)
        local adjustGravityY = getElementData(vehicle, "sdmVehicleMagnetAdjustGravityY", false)
        local adjustGravityZ = getElementData(vehicle, "sdmVehicleMagnetAdjustGravityZ", false)
        setVehicleGravity(vehicle, (adjustGravityX or 0), (adjustGravityY or 0), (adjustGravityZ or -1))

        -- remove gravity mode and forced/adjusted gravity
        setElementData(vehicle, "sdmVehicleMagnetMode", nil, false)

        setElementData(vehicle, "sdmVehicleMagnetAdjustGravityX", nil, false)
        setElementData(vehicle, "sdmVehicleMagnetAdjustGravityY", nil, false)
        setElementData(vehicle, "sdmVehicleMagnetAdjustGravityZ", nil, false)

        -- remove onClientRender as soon as the last vehicle is removed
        if (#magnetVehicles == 0) then
            removeEventHandler("onClientRender", root, renderVehicleMagnet)
            magnetEnabled = false
        end

        -- disable debugging
        disableVehicleMagnetDebugging()
    end
end

addEvent("onClientDisableVehicleMagnet", true)
addEventHandler("onClientDisableVehicleMagnet", resourceRoot, disableVehicleMagnet)

addEventHandler("onClientElementDestroy", root,
    function ()
        if (getElementType(source) == "vehicle") then
            -- unregister magnet vehicle
            for _,vehicle in ipairs(magnetVehicles) do
                if (source == vehicle) then
                    disableVehicleMagnet(vehicle)
                    break
                end
            end
        end
    end
)

function enableVehicleMagnetDebugging(vehicle, mode)
    local debugLevel = debug:getDebugLevel()
    if ((vehicle == getPedOccupiedVehicle(localPlayer)) and (debugLevel >= 3)) then
        -- init on-screen debug strings
        magnetDebugIDs = {}

        if (debug:getOnScreenLogCount("center") > 0) then
            magnetDebugIDs["-"] = debug:initOnScreenLog(resourceRoot)
        end

        if (mode == "default") then
            magnetDebugIDs.fly = debug:initOnScreenLog(resourceRoot, "SDM Fly Magnet: [ %.3f / %.3f / %.3f ]", 25, "center", 0, 0, 255, 255)
            magnetDebugIDs.magnet = debug:initOnScreenLog(resourceRoot, "SDM Default Magnet: [ %.3f; %.3f; %.3f ]", 25)
            magnetDebugIDs.ground = debug:initOnScreenLog(resourceRoot, "Ground: [ %.3f / %.3f / %.3f ] --> Distance: %.3f abs, %.3f add'l Z-gravity", 25)
        else
            magnetDebugIDs.magnet = debug:initOnScreenLog(resourceRoot, "SDM Magnet: [ %.3f; %.3f; %.3f ]", 25)
        end

        -- disable debugging when the vehicle gets destroyed
        addEventHandler("onElementDestroy", vehicle, function () disableVehicleMagnetDebugging() end)
    end
end

function disableVehicleMagnetDebugging()
    if (magnetDebugIDs) then
        -- clear on-screen debug strings
        for _,magnetDebugID in pairs(magnetDebugIDs) do
            debug:clearOnScreenLog(magnetDebugID)
        end
        magnetDebugIDs = nil
    end
end

function renderVehicleMagnet()
    local currentTick = getTickCount()
    if (magnetLastRenderTick ~= nil) then
        for _,vehicle in ipairs(magnetVehicles) do
            local currentFps = (1000 / (currentTick - magnetLastRenderTick))

            -- calculate gravity
            local mode = getElementData(vehicle, "sdmVehicleMagnetMode", false)
            local gravityX, gravityY, gravityZ = getVehicleMagnetGravity(vehicle, mode)

            -- debugging
            if (magnetDebugIDs and (vehicle == getPedOccupiedVehicle(localPlayer))) then
                debug:updateOnScreenLog(magnetDebugIDs.magnet, { gravityX, gravityY, gravityZ }, "avg")

                local gravityPoint = vehicle.position + Vector3(gravityX, gravityY, gravityZ) * 1000
                dxDrawLine3D(
                    vehicle.position.x, vehicle.position.y, vehicle.position.z,
                    gravityPoint.x, gravityPoint.y, gravityPoint.z,
                    tocolor(0, 0, 0, 150), 20
                )
            end

            -- apply gravity to vehicle velocity
            local gravity = getGravity() * getGameSpeed() * (magnetGravityBaseFps / currentFps)
            local velocityX, velocityY, velocityZ = getElementVelocity(vehicle)
            setElementVelocity(vehicle, velocityX + gravityX * gravity, velocityY + gravityY * gravity, velocityZ + gravityZ * gravity)
        end
    end

    magnetLastRenderTick = currentTick
end

function getVehicleMagnetGravity(vehicle, mode)
    -- calculate gravity
    local gravity = Vector3(0, 0, -1)
    if (mode == "default") then
        gravity = getVehicleMagnetDefaultGravity(vehicle)
    elseif (mode == "fly") then
        gravity = getVehicleMagnetFlyGravity(vehicle)
    end

    -- apply adjusted gravity
    gravity = applyVehicleMagnetAdjustedGravity(vehicle, gravity)

    return gravity.x, gravity.y, gravity.z
end

function getVehicleMagnetDefaultGravity(vehicle)
    -- default mode is a improved version of fly mode
    local gravity = getVehicleMagnetFlyGravity(vehicle)

    -- get the coordinates of the point where the vehicle hits a object in the direction of the "fly" gravity point
    -- this is the point where gravity heads the vehicle to and is so to speak the "ground"
    local maxDrawDistance = 1000
    local gravityDirection = vehicle.position + gravity * maxDrawDistance

    local hit, hitX, hitY, hitZ = processLineOfSight(
        vehicle.position.x, vehicle.position.y, vehicle.position.z,
        gravityDirection.x, gravityDirection.y, gravityDirection.z,
        true, false, false, true, false, false, false
    )

    -- debugging
    if (magnetDebugIDs and (vehicle == getPedOccupiedVehicle(localPlayer))) then
        debug:updateOnScreenLog(magnetDebugIDs.fly, { gravity.x, gravity.y, gravity.z }, "avg")

        if (hit) then
            dxDrawLine3D(
                vehicle.position.x, vehicle.position.y, vehicle.position.z,
                hitX, hitY, hitZ,
                tocolor(0, 0, 255, 150), 20
            )
        end
    end

    -- when the hitted object is far away, its gravity effect is lower than that of a near object
    --
    -- at a distance of about 50 meters, the additional gravitational pull to the Z coordinate
    -- is about the same power as the fly mode gravity in all directions (including the Z coordinate)
    -- the variance is spread using a quadratic function
    if (hit) then
        local groundOffset = Vector3(math.abs(vehicle.position.x - hitX), math.abs(vehicle.position.y - hitY), math.abs(vehicle.position.z - hitZ))
        local groundDistance = math.max(0, (groundOffset.length - getVehicleBaseOffset(vehicle)))

        local balancePoint, exponent = 50, 2
        local groundGravityZ = math.pow((groundDistance / balancePoint), exponent)

        local newGravity = gravity + Vector3(0, 0, -groundGravityZ)
        newGravity:normalize()

        -- debugging
        if (magnetDebugIDs and (vehicle == getPedOccupiedVehicle(localPlayer))) then
            debug:updateOnScreenLog(magnetDebugIDs.ground, { groundOffset.x, groundOffset.y, groundOffset.z, groundDistance, -groundGravityZ }, "avg")
        end

        return newGravity
    else
        -- debugging
        if (magnetDebugIDs and (vehicle == getPedOccupiedVehicle(localPlayer))) then
            debug:updateOnScreenLog(magnetDebugIDs.ground, { math.huge, math.huge, math.huge, math.huge, math.huge }, "avg")

            dxDrawLine3D(
                vehicle.position.x, vehicle.position.y, vehicle.position.z,
                vehicle.position.x, vehicle.position.y, (vehicle.position.z - maxDrawDistance),
                tocolor(0, 0, 255, 150), 20
            )
        end

        -- infinite distance to the "ground"
        return Vector3(0, 0, -1)
    end
end

function getVehicleMagnetFlyGravity(vehicle)
    return (- vehicle.matrix.up)
end

function applyVehicleMagnetAdjustedGravity(vehicle, gravity)
    local gravityBoost = (getElementData(vehicle, "sdmVehicleGravityBoost", false) == "true")
    local adjustGravityX = getElementData(vehicle, "sdmVehicleMagnetAdjustGravityX", false)
    local adjustGravityY = getElementData(vehicle, "sdmVehicleMagnetAdjustGravityY", false)
    local adjustGravityZ = getElementData(vehicle, "sdmVehicleMagnetAdjustGravityZ", false)

    if (adjustGravityX and adjustGravityY and adjustGravityZ) then
        if (gravityBoost) then
            return gravity *  (- adjustGravityZ)
        else
            return Vector3(
                (gravity.x * (1 - adjustGravityX)),
                (gravity.y * (1 - adjustGravityY)),
                (gravity.z * (0 - adjustGravityZ))
            )
        end
    end

    return gravity
end

--
-- player gravity marker
--
addEvent("onClientSetGravity", true)
addEventHandler("onClientSetGravity", resourceRoot,
    function (gravity)
        gravity = (tonumber(gravity) or 0.008)
        setGravity(gravity)
    end
)

--
-- vehicle gravity marker
--
addEvent("onClientSetVehicleGravity", true)
addEventHandler("onClientSetVehicleGravity", resourceRoot,
    function (vehicle, mode, gravityX, gravityY, gravityZ)
        if ((vehicle == nil) or (getElementType(vehicle) ~= 'vehicle')) then
            vehicle = getPedOccupiedVehicle(localPlayer)
        end

        gravityX, gravityY, gravityZ = tonumber(gravityX), tonumber(gravityY), tonumber(gravityZ)
        if ((not gravityX) or (not gravityY) or (not gravityZ)) then
            gravityX, gravityY, gravityZ = 0, 0, -1
        end

        setElementData(vehicle, "sdmVehicleGravityBoost", tostring(mode == "vehicle-boost"), false)

        -- if the magnet is enabled, adjust the magnet gravity accordingly
        if (magnetEnabled) then
            local vehicleMagnetEnabled = false
            for _,checkVehicle in ipairs(magnetVehicles) do
                if (checkVehicle == vehicle) then
                    vehicleMagnetEnabled = true
                    break
                end
            end

            if (vehicleMagnetEnabled) then
                setElementData(vehicle, "sdmVehicleMagnetAdjustGravityX", gravityX, false)
                setElementData(vehicle, "sdmVehicleMagnetAdjustGravityY", gravityY, false)
                setElementData(vehicle, "sdmVehicleMagnetAdjustGravityZ", gravityZ, false)
                return
            end
        end

        setVehicleGravity(vehicle, gravityX, gravityY, gravityZ)
    end
)

--
-- sky marker
--
addEvent("onClientSetSkyGradient", true)
addEventHandler("onClientSetSkyGradient", resourceRoot,
    function (topColor, bottomColor)
        if ((topColor == "#00000000") and (bottomColor == "#00000000")) then
            resetSkyGradient()
        else
            local topRed, topGreen, topBlue, topAlpha = getColorFromString(topColor)
            if ((not topRed) or (not topGreen) or (not topBlue) or (not topAlpha)) then
                -- default: weather 0 (Blue Sky, Sunny) at 12:00
                topRed, topGreen, topBlue, topAlpha = getColorFromString("#4475D2")
            elseif (topAlpha < 255) then
                topRed = ((255 - topRed) * (topAlpha / 255) + topRed)
                topGreen = ((255 - topGreen) * (topAlpha / 255) + topGreen)
                topBlue = ((255 - topBlue) * (topAlpha / 255) + topBlue)
            end

            local bottomRed, bottomGreen, bottomBlue, bottomAlpha = getColorFromString(bottomColor)
            if ((not bottomRed) or (not bottomGreen) or (not bottomBlue) or (not bottomAlpha)) then
                -- default: weather 0 (Blue Sky, Sunny) at 12:00
                bottomRed, bottomGreen, bottomBlue, bottomAlpha = getColorFromString("#2475C6")
            elseif (bottomAlpha < 255) then
                bottomRed = ((255 - bottomRed) * (bottomAlpha / 255) + bottomRed)
                bottomGreen = ((255 - bottomGreen) * (bottomAlpha / 255) + bottomGreen)
                bottomBlue = ((255 - bottomBlue) * (bottomAlpha / 255) + bottomBlue)
            end

            setSkyGradient(topRed, topGreen, topBlue, bottomRed, bottomGreen, bottomBlue)
        end
    end
)

--
-- water marker
--
addEvent("onClientSetWaterColor", true)
addEventHandler("onClientSetWaterColor", resourceRoot,
    function (color)
        if (color == "#00000000") then
            resetWaterColor()
        else
            local red, green, blue, alpha = getColorFromString(color)
            if ((not red) or (not green) or (not blue)) then
                -- default: weather 0 (Blue Sky, Sunny) at 12:00
                red, green, blue, alpha = getColorFromString("#59A9A9F0")
            end

            setWaterColor(red, green, blue, alpha)
        end
    end
)
