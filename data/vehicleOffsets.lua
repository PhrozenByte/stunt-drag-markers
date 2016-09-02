vehicleOffsets = {
    ["417"] = 1.27300000190735, ["513"] = 1.78475689888000, ["419"] = 0.92999982833862, ["580"] = 0.90752363204956,
    ["421"] = 1.00000000000000, ["522"] = 0.66037744283676, ["519"] = 2.00007224082947, ["487"] = 1.26500010490417,
    ["527"] = 0.78314852714539, ["426"] = 0.81999969482422, ["510"] = 0.69584167003632, ["533"] = 0.79999989271164,
    ["492"] = 0.89999997615814, ["600"] = 0.84184813499451, ["602"] = 0.90000009536743, ["604"] = 0.91999995708466,
    ["496"] = 0.78772729635239, ["545"] = 0.94999980926514, ["547"] = 0.83999997377396, ["549"] = 0.86147683858871,
    ["551"] = 0.87999987602234, ["553"] = 3.23499989509583, ["439"] = 1.00000000000000, ["581"] = 0.69976079463959,
    ["529"] = 0.73788857460022, ["548"] = 2.90006184577942, ["563"] = 1.88574969768524, ["507"] = 0.95000004768372,
    ["445"] = 0.98999989032745, ["509"] = 0.59979707002640, ["447"] = 1.10000002384186, ["511"] = 2.51589751243591,
    ["512"] = 1.63399994373322, ["577"] = 1.07469987869263, ["516"] = 0.89999997615814, ["518"] = 0.79480773210526,
    ["520"] = 1.91957569122314, ["585"] = 0.69692599773407, ["587"] = 0.81000000238419, ["589"] = 0.71692603826523,
    ["425"] = 1.85100030899048, ["593"] = 1.55018246173859, ["476"] = 2.17015266418457, ["460"] = 2.21952772140503,
    ["497"] = 1.26500010490417, ["488"] = 1.26500010490417, ["540"] = 0.97950112819672, ["401"] = 0.86781448125839,
    ["592"] = 2.29732584953308, ["466"] = 0.91999995708466, ["467"] = 0.87000000476837, ["550"] = 0.92278164625168,
    ["469"] = 1.10000002384186, ["546"] = 0.84184813499451, ["405"] = 1.00000000000000, ["409"] = 0.92499983310699,
    ["410"] = 0.74999296665192, ["474"] = 0.89999991655350, ["526"] = 0.84999984502792, ["566"] = 0.90000015497208,
    ["436"] = 0.87799334526062, ["491"] = 0.89999997615814, ["517"] = 0.93566590547562
}

function getVehicleBaseOffset(vehicle)
    vehicle = (isElement(vehicle) and (getElementType(vehicle) == "vehicle") and getElementModel(vehicle) or nil)
    return (vehicle and (vehicleOffsets[tostring(vehicle)] or 0) or false)
end
