# read_results.rb
#
# reads results from subdirectories under the "workflows" directory and copy to a .csv file
require 'csv'
require 'openstudio'

puts "Checking status..."
model_dirs = Dir.entries('workflows').select {|entry| File.directory? File.join('workflows',entry) and !(entry =='.' || entry == '..') }

run_dirs = []
missing_run_dirs = []
report_dirs = []
missing_report_dirs = []
model_dirs.each do |model_dir|
  if File.directory?("workflows/#{model_dir}/run")
    run_dirs << "workflows/#{model_dir}/run"
  else
    missing_run_dirs << model_dir
  end
  if File.directory?("workflows/#{model_dir}/reports")
    report_dirs << "workflows/#{model_dir}/reports"
  else
    missing_report_dirs << model_dir
  end
end

puts "There are #{model_dirs.size} workflow folders, #{run_dirs.size} run folders, and #{report_dirs.size} report folders."

if report_dirs.size < model_dirs.size
  puts "Model results incomplete."
  
  if run_dirs.size < model_dirs.size
    puts "These workflows have not yet run:"
    puts missing_run_dirs
  end
  
  puts "These workflows are still running or have errors:"
  puts missing_report_dirs - missing_run_dirs
  
else

  puts "Reports exist for all workflows. Reading results..."

  model_areas = []
  model_site_energys = []
  model_peak_elecs = []
  model_site_elecs = []
  model_site_gass = []
  model_site_heating_elecs = []
  model_site_heating_gass = []
  model_site_cooling_elecs = []
  model_site_interior_lighting_elecs = []
  model_site_exterior_lighting_elecs = []
  model_site_interior_equipment_elecs = []
  model_site_exterior_equipment_elecs = []
  model_site_fans_elecs = []
  model_site_pumps_elecs = []
  model_site_heat_rejection_elecs = []
  model_site_humidification_elecs = []
  model_site_heat_recovery_elecs = []
  model_site_water_systems_elecs = []
  model_site_water_systems_gass = []
  model_site_refrigeration_elecs = []
  model_site_generators_elecs = []

  run_dirs.each do |run_dir|

    ####################
    # parse eplusout.sql
    sql_file_path = OpenStudio::Path.new("#{run_dir}/eplusout.sql")
    sql = OpenStudio::SqlFile.new(sql_file_path)

    # total site energy
    if !sql.totalSiteEnergy.empty?
      model_site_energys << sql.totalSiteEnergy.get
    else
      model_site_energys << 0.0
    end

    # peak electricity demand
    electric_peak  = sql.execAndReturnFirstDouble("SELECT Value FROM tabulardatawithstrings WHERE ReportName='EnergyMeters' AND ReportForString='Entire Facility' AND TableName='Annual and Peak Values - Electricity' AND RowName='Electricity:Facility' AND ColumnName='Electricity Maximum Value' AND Units='W'")
    if !electric_peak.empty?
      model_peak_elecs << electric_peak.get
    else
      electric_peak = 0.0
    end

    building_area = sql.execAndReturnFirstDouble("SELECT Value FROM tabulardatawithstrings WHERE TableName='Building Area' AND RowName='Total Building Area'")
    if !building_area.empty?
      model_areas << building_area.get
    else
      model_areas << 0.0
    end

    # site total electricity
    if !sql.electricityTotalEndUses.empty?
      model_site_elecs << sql.electricityTotalEndUses.get
    else
      model_site_elecs << 0.0
    end

    # site total gas
    if !sql.naturalGasTotalEndUses.empty?
      model_site_gass << sql.naturalGasTotalEndUses.get
    else
      model_site_gass << 0.0
    end

    # electric heating
    if !sql.electricityHeating.empty?
      model_site_heating_elecs << sql.electricityHeating.get
    else
      model_site_heating_elecs << 0.0
    end

    # gas heating
    if !sql.naturalGasHeating.empty?
      model_site_heating_gass << sql.naturalGasHeating.get
    else
      model_site_heating_gass << 0.0
    end

    # site cooling
    if !sql.electricityCooling.empty?
      model_site_cooling_elecs << sql.electricityCooling.get
    else
      model_site_cooling_elecs << 0.0
    end

    # site interior lighting
    if !sql.electricityInteriorLighting.empty?
      model_site_interior_lighting_elecs << sql.electricityInteriorLighting.get
    else
      model_site_interior_lighting_elecs << 0.0
    end

    # site exterior lighting
    if !sql.electricityExteriorLighting.empty?
      model_site_exterior_lighting_elecs << sql.electricityExteriorLighting.get
    else
      model_site_exterior_lighting_elecs << 0.0
    end
    
    # site interior equipment
    if !sql.electricityInteriorEquipment.empty?
      model_site_interior_equipment_elecs << sql.electricityInteriorEquipment.get
    else
      model_site_interior_equipment_elecs << 0.0
    end

    # site exterior equipment
    if !sql.electricityExteriorEquipment.empty?
      model_site_exterior_equipment_elecs << sql.electricityExteriorEquipment.get
    else
      model_site_exterior_equipment_elecs << 0.0
    end

    # site fans
    if !sql.electricityFans.empty?
      model_site_fans_elecs << sql.electricityFans.get
    else
      model_site_fans_elecs << 0.0
    end

    # site pumps
    if !sql.electricityPumps.empty?
      model_site_pumps_elecs << sql.electricityPumps.get
    else
      model_site_pumps_elecs << 0.0
    end

    # site heat rejection
    if !sql.electricityHeatRejection.empty?
      model_site_heat_rejection_elecs << sql.electricityHeatRejection.get
    else
      model_site_heat_rejection_elecs << 0.0
    end

    # site humidification
    if !sql.electricityHumidification.empty?
      model_site_humidification_elecs << sql.electricityHumidification.get
    else
      model_site_humidification_elecs << 0.0
    end

    # site heat recovery
    if !sql.electricityHeatRecovery.empty?
      model_site_heat_recovery_elecs << sql.electricityHeatRecovery.get
    else
      model_site_heat_recovery_elecs << 0.0
    end
      
    # site water systems electricity
    if !sql.electricityWaterSystems.empty?
      model_site_water_systems_elecs << sql.electricityWaterSystems.get
    else
      model_site_water_systems_elecs << 0.0
    end

    # site water systems gas
    if !sql.naturalGasWaterSystems.empty?
      model_site_water_systems_gass << sql.naturalGasWaterSystems.get
    else
      model_site_water_systems_gass << 0.0
    end

    # site refrigeration
    if !sql.electricityRefrigeration.empty?
      model_site_refrigeration_elecs << sql.electricityRefrigeration.get
    else
      model_site_refrigeration_elecs << 0.0
    end

    # site generators
    if !sql.electricityGenerators.empty?
      model_site_generators_elecs << sql.electricityGenerators.get
    else
      model_site_generators_elecs << 0.0
    end
  end

  #Write csv file
  puts "Writing results..."
  write_tbl = []
  write_tbl << model_dirs.unshift("model")
  write_tbl << model_areas.unshift("Total Building Area [m2]")
  write_tbl << model_site_energys.unshift("Model Site Energy [GJ]")
  write_tbl << model_site_elecs.unshift("Model Site Electricity [GJ]")
  write_tbl << model_site_gass.unshift("Model Site Natural Gas [GJ]")
  write_tbl << model_peak_elecs.unshift("Model Peak Electricity Demand [W]")
  write_tbl << model_site_heating_elecs.unshift("Heating Electricity [GJ]")
  write_tbl << model_site_heating_gass.unshift("Heating Natural Gas [GJ]")
  write_tbl << model_site_cooling_elecs.unshift("Cooling Electricity [GJ]")
  write_tbl << model_site_interior_lighting_elecs.unshift("Interior Lighting Electricity [GJ]")
  write_tbl << model_site_exterior_lighting_elecs.unshift("Exterior Lighting Electricity [GJ]")
  write_tbl << model_site_interior_equipment_elecs.unshift("Interior Equipment Electricity [GJ]")
  write_tbl << model_site_exterior_equipment_elecs.unshift("Exterior Equipment Electricity [GJ]")
  write_tbl << model_site_fans_elecs.unshift("Fans Electricity [GJ]")
  write_tbl << model_site_pumps_elecs.unshift("Pumps Electricity [GJ]")
  write_tbl << model_site_heat_rejection_elecs.unshift("Heat Rejection Electricity [GJ]")
  write_tbl << model_site_humidification_elecs.unshift("Humidification Electricity [GJ]")
  write_tbl << model_site_heat_recovery_elecs.unshift("Heat Recovery Electricity [GJ]")
  write_tbl << model_site_water_systems_elecs.unshift("Water Systems Electricity [GJ]")
  write_tbl << model_site_water_systems_gass.unshift("Water Systems Natural Gas [GJ]")
  write_tbl << model_site_refrigeration_elecs.unshift("Refrigeration Electricity [GJ]")
  write_tbl << model_site_generators_elecs.unshift("Generators Electricity [GJ]")
  #write_tbl = write_tbl.transpose

  CSV.open("results.csv", "wb") do |csv|
    write_tbl.each do |line|
      csv << line
    end
  end

end