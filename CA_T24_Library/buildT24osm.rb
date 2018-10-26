require 'openstudio'
require 'csv'

#create new model
model = OpenStudio::Model::Model.new

#read in schedule limit types and transform to array of hashes
raw_data =  CSV.table("#{Dir.pwd}/resources/ScheduleTypeLimits.csv")
schedule_type_limits_hash = raw_data.map { |row| row.to_hash }
schedule_type_limits_hash.each do |s|
  schedule_type_limit = OpenStudio::Model::ScheduleTypeLimits.new(model)
  schedule_type_limit.setName(s[:name])

  if s[:lowerlimitvalue]
    schedule_type_limit.setLowerLimitValue(s[:lowerlimitvalue])
  end
  if s[:upperlimitvalue]
    schedule_type_limit.setUpperLimitValue(s[:upperlimitvalue])
  end
  if s[:numerictype]
    schedule_type_limit.setNumericType(s[:numerictype])
  end
  if s[:unittype]
    schedule_type_limit.setUnitType(s[:unittype])
  end
end
schedule_type_limits = model.getScheduleTypeLimitss

def findObject(array,name)
  array.each do |item|
    if item.name.to_s == name
      return item
    end
  end
  puts "ERROR! Unable to find object with name #{name} in array. Make sure name being called is correct, and matches available names in array."
  nil
end


##SCHEDULES
#read in schedule days and transform to array of hashes
raw_data =  CSV.table("#{Dir.pwd}/resources/T24_ScheduleDays.csv")
schedule_day_hash = raw_data.map { |row| row.to_hash }
#for each schedule, make a ScheduleDay object
schedule_day_hash.each do |sch|
  schedule_day = OpenStudio::Model::ScheduleDay.new(model)
  schedule_day.setName(sch[:scheduledayname])

  sch_type_limit = findObject(schedule_type_limits,sch[:scheduletypelimits])
  schedule_day.setScheduleTypeLimits(sch_type_limit)

  (1..24).each do |i|
    if ((i < 24) && (sch[:"#{i}"] == sch[:"#{i+1}"]))
      #skip to avoid duplicate values
    else
      schedule_day.addValue(OpenStudio::Time.new(0, i, 0, 0), sch[:"#{i}"])
    end    
  end  
end
schedule_days = model.getScheduleDays

#read in schedule weeks and transform to array of hashes
raw_data =  CSV.table("#{Dir.pwd}/resources/T24_ScheduleRulesets_Partial.csv")
schedule_ruleset_hash = raw_data.map { |row| row.to_hash }
#for each schedule ruleset, make a ScheduleRuleset object
schedule_ruleset_hash.each do |sch|
  schedule_ruleset = OpenStudio::Model::ScheduleRuleset.new(model)
  schedule_ruleset.setName(sch[:scheduleyearname])
  schedule_ruleset.defaultDaySchedule.setName("#{sch[:scheduleyearname]} Default")
  default_day = findObject(schedule_days,sch[:mon])
  times = default_day.times
  values = default_day.values
  i = 0
  times.each do |t|
      schedule_ruleset.defaultDaySchedule.addValue(t,values[i])
    i += 1
  end
  
  #date = OpenStudio::Date.new(OpenStudio::MonthOfYear.new(sch[:endmonth]), sch[:endday])
  schedule_rule = OpenStudio::Model::ScheduleRule.new(schedule_ruleset, findObject(schedule_days,sch[:sat]))
  schedule_rule.setName("#{sch[:scheduleyearname]} Sat") 
  schedule_rule.setApplySaturday(true)
  schedule_rule = OpenStudio::Model::ScheduleRule.new(schedule_ruleset, findObject(schedule_days,sch[:sun]))
  schedule_rule.setName("#{sch[:scheduleyearname]} Sun") 
  schedule_rule.setApplySunday(true)
  schedule_ruleset.setWinterDesignDaySchedule(findObject(schedule_days,sch[:htgdd]))
  schedule_ruleset.setSummerDesignDaySchedule(findObject(schedule_days,sch[:clgdd]))

  end
schedule_rulesets = model.getScheduleRulesets

##Alternative Approach defining Schedule:Week and Schedule:Year objects
##if using this approach, pass schedule_years instead of schedule_rulesets in the schedule_group loop
# #read in schedule weeks and transform to array of hashes
# raw_data =  CSV.table("#{Dir.pwd}/resources/T24_ScheduleWeeks.csv")
# schedule_week_hash = raw_data.map { |row| row.to_hash }
# #for each schedule week, make a ScheduleWeek object
# schedule_week_hash.each do |sch|
  # schedule_week = OpenStudio::Model::ScheduleWeek.new(model)
  # schedule_week.setName(sch[:scheduleweekname])
  # schedule_week.setMondaySchedule(findObject(schedule_days,sch[:mon]))
  # schedule_week.setTuesdaySchedule(findObject(schedule_days,sch[:tue]))
  # schedule_week.setWednesdaySchedule(findObject(schedule_days,sch[:wed]))
  # schedule_week.setThursdaySchedule(findObject(schedule_days,sch[:thu]))
  # schedule_week.setFridaySchedule(findObject(schedule_days,sch[:fri]))
  # schedule_week.setSaturdaySchedule(findObject(schedule_days,sch[:sat]))
  # schedule_week.setSundaySchedule(findObject(schedule_days,sch[:sun]))
  # schedule_week.setHolidaySchedule(findObject(schedule_days,sch[:hol]))
  # schedule_week.setSummerDesignDaySchedule(findObject(schedule_days,sch[:clgdd]))
  # schedule_week.setWinterDesignDaySchedule(findObject(schedule_days,sch[:htgdd]))
# end
# schedule_weeks = model.getScheduleWeeks

# #read in schedule years and transform to array of hashes
# raw_data =  CSV.table("#{Dir.pwd}/resources/T24_ScheduleYears_Partial.csv")
# schedule_year_hash = raw_data.map { |row| row.to_hash }
# #for each schedule year, make a ScheduleYear object
# schedule_year_hash.each do |sch|
  # schedule_year = OpenStudio::Model::ScheduleYear.new(model)
  # schedule_year.setName(sch[:scheduleyearname])

  # #add weeks here.  for now, just first columns
  # date = OpenStudio::Date.new(OpenStudio::MonthOfYear.new(sch[:endmonth]), sch[:endday])
  # schedule_year.addScheduleWeek(date, findObject(schedule_weeks,sch[:schedulewk]))
# end
# schedule_years = model.getScheduleYears

#read in schedule groups and transform to array of hashes
raw_data =  CSV.table("#{Dir.pwd}/resources/T24_ScheduleGroups_Partial.csv")
schedule_group_hash = raw_data.map { |row| row.to_hash }
#for each schedule year, make a ScheduleYear object
schedule_group_hash.each do |sch_grp|
  default_schedule_set = OpenStudio::Model::DefaultScheduleSet.new(model)
  default_schedule_set.setName("#{sch_grp[:funcgroup]} Default Schedule Set")
  #add defaults for this group
  default_schedule_set.setNumberofPeopleSchedule(findObject(schedule_rulesets,sch_grp[:occschref]))
  default_schedule_set.setElectricEquipmentSchedule(findObject(schedule_rulesets,sch_grp[:recptschref]))
  default_schedule_set.setHotWaterEquipmentSchedule(findObject(schedule_rulesets,sch_grp[:hotwtrhtgschref]))
  default_schedule_set.setLightingSchedule(findObject(schedule_rulesets,sch_grp[:intltgregschref]))
  default_schedule_set.setGasEquipmentSchedule(findObject(schedule_rulesets,sch_grp[:procgasschref]))
  default_schedule_set.setInfiltrationSchedule(findObject(schedule_rulesets,sch_grp[:infschref]))
  default_schedule_set.setHoursofOperationSchedule(findObject(schedule_rulesets,sch_grp[:availschref]))
end
default_schedule_sets = model.getDefaultScheduleSets


##SPACE TYPES
#read in space types and transform to array of hashes
raw_data =  CSV.table("#{Dir.pwd}/resources/T24_SpaceTypes_Partial.csv")
space_type_hash = raw_data.map { |row| row.to_hash }

#for each space type, remove commas and spaces 
space_type_hash.each do |spc|
  spc[:functype] = spc[:functype].gsub(/[\s,]/ ,"")
end

#for each space type, make the load objects and assign the default schedule
space_type_hash.each do |spc|
  space_type = OpenStudio::Model::SpaceType.new(model)
  space_type.setName("#{spc[:functype]}")

  space_type.setDefaultScheduleSet(findObject(default_schedule_sets,"#{spc[:funcschgrp]} Default Schedule Set"))
  
  #create a space infiltration design flow rate, matched to 189.1-2009
  space_infiltration_obj = OpenStudio::Model::SpaceInfiltrationDesignFlowRate.new(model)
  space_infiltration_obj.setName("#{spc[:functype]} Infiltration")
  space_infiltration_obj.setFlowperExteriorSurfaceArea(0.00030226)
  space_infiltration_obj.setSpaceType(space_type)
  
  #create new people definition
  if spc[:occdens] > 0
    people_def = OpenStudio::Model::PeopleDefinition.new(model)
    people_def.setName("#{spc[:functype]} PeopleDef")
    people = OpenStudio::Model::People.new(people_def)
    people.setName("#{spc[:functype]} People")
    
    #create and set activity level schedule
    activity_level_sch = OpenStudio::Model::ScheduleConstant.new(model)
    activity_level_sch.setName("#{spc[:functype]} ActivitySch")
    occ_sens = spc[:occsenshtrt]
    occ_lat = spc[:occlathtrt]
    occ_tot = occ_sens + occ_lat
    sensible_fraction = occ_sens/occ_tot
    people_def.setSensibleHeatFraction(sensible_fraction)
    activity_level_sch.setValue(OpenStudio.convert(occ_tot,"Btu/h","W").get)
    people.setActivityLevelSchedule(activity_level_sch) 
    ppl_dens = OpenStudio.convert(1000/spc[:occdens],"ft^2","m^2").get
    space_type.setSpaceFloorAreaPerPerson(ppl_dens,people)
  end
  
  #create new electric equipment definition
  if spc[:recptpwrdens] > 0
    elec_equip_def = OpenStudio::Model::ElectricEquipmentDefinition.new(model)
    elec_equip_def.setName("#{spc[:functype]} ElecEquipDef")
    elec_equip_def.setFractionRadiant(0.3)
    elec_equip = OpenStudio::Model::ElectricEquipment.new(elec_equip_def)
    elec_equip.setName("#{spc[:functype]} ElecEquip")
    epd = OpenStudio.convert(spc[:recptpwrdens],"m^2","ft^2").get
    space_type.setElectricEquipmentPowerPerFloorArea(epd,elec_equip)
  end

  #create new gas equipment definition
  if spc[:gaseqppwrdens] > 0
    gas_equip_def = OpenStudio::Model::GasEquipmentDefinition.new(model)
    gas_equip_def.setName("#{spc[:functype]} GasEquipDef")
    gas_equip = OpenStudio::Model::GasEquipment.new(gas_equip_def)
    gas_equip.setName("#{spc[:functype]} GasEquip")
    gas_epd = OpenStudio.convert(spc[:gaseqppwrdens]/3600,"Btu","J").get
    gas_epd = OpenStudio.convert(gas_epd,"m^2","ft^2").get
    space_type.setGasEquipmentPowerPerFloorArea(gas_epd,gas_equip)
  end
  
  #create new lighting equipment definition
  if spc[:intlpdreg] > 0
  light_def = OpenStudio::Model::LightsDefinition.new(model)
  light_def.setName("#{spc[:functype]} LightingDef")
  #assume Surface Mounted, T5HO from InputOutputReference
  light_def.setFractionRadiant(0.27)
  light_def.setFractionVisible(0.23)
  light = OpenStudio::Model::Lights.new(light_def)
  light.setName("#{spc[:functype]} Lighting")
  lpd = OpenStudio.convert(spc[:intlpdreg],"m^2","ft^2").get
  space_type.setLightingPowerPerFloorArea(lpd,light)  
  end

  #create design specification outdoor air objects
  design_spec_oa = OpenStudio::Model::DesignSpecificationOutdoorAir.new(model)
  design_spec_oa.setName("#{spc[:functype]} DesignSpecOA")
  vent_area_min = OpenStudio.convert(spc[:codeventperarea],"cfm/ft^2","m/s").get
  design_spec_oa.setOutdoorAirFlowperFloorArea(vent_area_min)
  space_type.setDesignSpecificationOutdoorAir(design_spec_oa)
  if spc[:codetotalventperarea] > 0
    vent_area_total = OpenStudio.convert(spc[:codetotalventperarea],"cfm/ft^2","m/s").get
    vent_diff = vent_area_total - vent_area_min
    if vent_diff > 0
      vent_per_person = ppl_dens*vent_diff
      design_spec_oa.setOutdoorAirFlowperPerson(vent_per_person)
    end    
  end

end #end space_type_hash.each 


##MATERIALS
#read in space types and transform to array of hashes
raw_data =  CSV.table("#{Dir.pwd}/resources/T24_MaterialData.csv")
material_hash = raw_data.map { |row| row.to_hash }

#for each space type, remove commas and spaces 
material_hash.each do |mat|
  thickness = OpenStudio.convert(mat[:thickness],"in","m").get
  resistance = OpenStudio.convert(mat[:resistance],"ft^2*h*R/Btu","m^2*K/W").get
  conductivity = OpenStudio.convert(mat[:conductivity],"Btu/ft*h*R","W/m*K").get
  density = OpenStudio.convert(mat[:density],"lb/ft^3","kg/m^3").get
  specificheat = OpenStudio.convert(mat[:specificheat],"Btu/lb*R","J/kg*K").get
  roughness = mat[:roughness].to_s

  if mat[:materialcategory] == "Air"    
    air_gap_mat = OpenStudio::Model::AirGap.new(model, resistance)  
    air_gap_mat.setName(mat[:materialname])
  else
    standard_mat = OpenStudio::Model::StandardOpaqueMaterial.new(model, roughness, thickness, conductivity, density, specificheat)
    standard_mat.setName(mat[:materialname])
  end  
end

#save model
model.save("#{Dir.pwd}/T24library.osm",true)