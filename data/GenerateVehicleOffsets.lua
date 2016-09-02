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

vehicleIDs = {
    602, 545, 496, 517, 401, 410, 518, 600, 527, 436, 589, 580, 419, 439, 533, 549, 526, 491, 474, 445, 467, 604, 426, 507, 547, 585, 405, 587,
    409, 466, 550, 492, 566, 546, 540, 551, 421, 516, 529, 592, 553, 577, 488, 511, 497, 548, 563, 512, 476, 593, 447, 425, 519, 520, 460, 417,
    469, 487, 513, 581, 510, 509, 522, 481, 461, 462, 448, 521, 468, 463, 586, 472, 473, 493, 595, 484, 430, 453, 452, 446, 454, 485, 552, 431,
    438, 437, 574, 420, 525, 408, 416, 596, 433, 597, 427, 599, 490, 432, 528, 601, 407, 428, 544, 523, 470, 598, 499, 588, 609, 403, 498, 514,
    524, 423, 532, 414, 578, 443, 486, 515, 406, 531, 573, 456, 455, 459, 543, 422, 583, 482, 478, 605, 554, 530, 418, 572, 582, 413, 440, 536,
    575, 534, 567, 535, 576, 412, 402, 542, 603, 475, 449, 537, 538, 570, 441, 464, 501, 465, 564, 568, 557, 424, 471, 504, 495, 457, 539, 483,
    508, 571, 500, 444, 556, 429, 411, 541, 559, 415, 561, 480, 560, 562, 506, 565, 451, 434, 558, 494, 555, 502, 477, 503, 579, 400, 404, 489,
    505, 479, 442, 458, 606, 607, 610, 590, 569, 611, 584, 608, 435, 450, 591, 594
}

addCommandHandler("generate-vehicle-offset-data",
    function (commandName)
        local vehicleOffsets = {}
        for _,vehicleID in ipairs(vehicleIDs) do
            local vehicle = createVehicle(vehicleID, 0, 0, 0)
            setElementStreamable(vehicle, false)

            local vehicleOffset = getElementDistanceFromCentreOfMassToBaseOfModel(vehicle)
            if (vehicleOffset and (vehicleOffset ~= 0)) then
                vehicleOffsets[vehicleID] = string.format("%.14f", vehicleOffset)
            end

            destroyElement(vehicle)
        end

        outputConsole("--[[")
        outputConsole("vehicleOffsets = {")

        local vehicleID, vehicleOffset = next(vehicleOffsets)
        if (vehicleID) then
            local i = 0
            local outputLine = ""
            local maxLineLength = 120
            while true do
                local addOutputLine = "[\"" .. vehicleID .. "\"] = " .. vehicleOffset .. ", "

                if ((4 + #outputLine + #addOutputLine - 1) < maxLineLength) then
                    outputLine = outputLine .. addOutputLine
                else
                    outputConsole("    " .. string.sub(outputLine, 1, (#outputLine - 1)))
                    outputLine = addOutputLine
                end

                i = i + 1
                vehicleID, vehicleOffset = next(vehicleOffsets, vehicleID)
                if (not vehicleID) then
                    outputConsole("    " .. string.sub(outputLine, 1, (#outputLine - 2)))
                    break
                end
            end
        end

        outputConsole("}")
        outputConsole("--]]")
    end
)
