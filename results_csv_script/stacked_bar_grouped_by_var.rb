# this will load a CSV made by OpenStudio Server, and create an HTML plot
# One variable is used as a key to group by.
# Initially the key for grouping will be the scenario, which is unique to this specific workflow

# requires
require 'csv'
require 'erb'
require 'json'

# load in CSV file
csv_file = 'PAT_model_articulation_testing-full_hvacfix.csv'

# variable used to add to html
output = []
data_end_use = []
data_heat_gain = []
data_heat_loss = []

# variable for data to put in scenario csv
csv_out_rows = []

csv_hash = {}
CSV.foreach(csv_file, :headers => true, :header_converters => :symbol, :converters => :all) do |row|
  short_name = row.fields[1].split(" ").first
  csv_hash[short_name] = Hash[row.headers[1..-1].zip(row.fields[1..-1])]
end
puts "CSV has #{csv_hash.size} entries."
#puts csv_hash.first

# create hash to store group of datapoints
grouped_hash = {}

# todo - loop through datapoints to group
csv_hash.each do |k,v|

	# get variables for this datapoint	
	building_type = v[:openstudio_model_articulation_testing_scenario_builderbuilding_type]
	climate_zone = v[:openstudio_model_articulation_testing_scenario_builderclimate_zone]
	template = v[:openstudio_model_articulation_testing_scenario_buildertemplate]

	# store key
	description_key = building_type + " " + climate_zone + " " + template

	# get key variable 
	scenario = v[:openstudio_model_articulation_testing_scenario_builderscenario]

	# todo - store outputs needed for plotting
	datapoint_hash = {}

	# end use value
	end_use_hash = {}
	end_use_hash['Exterior Equipment'] = v[:openstudio_resultsend_use_exterior_equipment]
	end_use_hash['Interior Equipment'] = v[:openstudio_resultsend_use_interior_equipment]
	end_use_hash['Exterior Lighting'] = v[:openstudio_resultsend_use_exterior_lighting]
	end_use_hash['Interior Lighting'] = v[:openstudio_resultsend_use_interior_lighting]
	end_use_hash['Refrigeration'] = v[:openstudio_resultsend_use_refrigeration]
	end_use_hash['Water Systems'] = v[:openstudio_resultsend_use_water_systems]
	end_use_hash['Heat Recovery'] = v[:openstudio_resultsend_use_heat_recovery]
	end_use_hash['Humidification'] = v[:openstudio_resultsend_use_humidification]
	end_use_hash['Heat Rejection'] = v[:openstudio_resultsend_use_heat_rejection]
	end_use_hash['Fans'] = v[:openstudio_resultsend_use_fans]
	end_use_hash['Pumps'] = v[:openstudio_resultsend_use_pumps]
	end_use_hash['Cooling'] = v[:openstudio_resultsend_use_cooling]
	end_use_hash['Heating'] = v[:openstudio_resultsend_use_heating]
	datapoint_hash['End Use'] = end_use_hash

	# metrics
	datapoint_metrics = {}
	datapoint_metrics['Sum of Absolute End Use Errors Divided by EUI of Previous Scenario'] = nil
	datapoint_metrics['Sum of End Use Errors Divided by EUI of Previous Scenario'] = nil
	datapoint_metrics['Largest Contributor to Absolute End Use Error'] = nil
	datapoint_metrics['EUI Error Versus Prototype as Percentage'] = nil
	datapoint_hash['Metrics'] = datapoint_metrics

	# heat gain values
	heat_gain_hash = {}
	heat_gain_hash['Heat Gain Electric Equipment'] = v[:envelope_and_internal_load_breakdownelectric_equipment_total_heating_energy_annual]
	heat_gain_hash['Heat Gain Gas Equipment'] = v[:envelope_and_internal_load_breakdowngas_equipment_total_heating_energy_annual]
	heat_gain_hash['Heat Gain Lights'] = v[:envelope_and_internal_load_breakdownzone_lights_total_heating_energy_annual]
	heat_gain_hash['Heat Gain People'] = v[:envelope_and_internal_load_breakdownzone_people_sensible_heating_energy_annual]
	heat_gain_hash['Heat Gain Infiltration'] = v[:envelope_and_internal_load_breakdownzone_infiltration_sensible_heat_gain_energy_annual]
	heat_gain_hash['Heat Gain Ground'] = v[:envelope_and_internal_load_breakdownground_heat_gain]
	heat_gain_hash['Heat Gain Walls'] = v[:envelope_and_internal_load_breakdownext_wall_heat_gain]
	heat_gain_hash['Heat Gain Windows'] = v[:envelope_and_internal_load_breakdownsurface_window_heat_gain_energy_annual]
	heat_gain_hash['Heat Gain Roof'] = v[:envelope_and_internal_load_breakdownext_roof_heat_gain]
	datapoint_hash['Heat Gain'] = heat_gain_hash

	# heat loss values
	heat_loss_hash = {}
	heat_loss_hash['Heat Loss Infiltration'] = v[:envelope_and_internal_load_breakdownzone_infiltration_sensible_heat_loss_energy_annual]
	heat_loss_hash['Heat Loss Ground'] = v[:envelope_and_internal_load_breakdownground_heat_loss]
	heat_loss_hash['Heat Loss Window'] = v[:envelope_and_internal_load_breakdownsurface_window_heat_loss_energy_annual]
	heat_loss_hash['Heat Loss Wall'] = v[:envelope_and_internal_load_breakdownext_wall_heat_loss]
	heat_loss_hash['Heat Loss Roof'] = v[:envelope_and_internal_load_breakdownext_roof_heat_loss]
	datapoint_hash['Heat Loss'] = heat_loss_hash

	# general values
	general_hash = {}
	general_hash['Description'] = description_key
	general_hash['Scenario'] = scenario
	general_hash['Building Type'] = building_type
	general_hash['Climate Zone'] = climate_zone
	general_hash['Template'] = template
	general_hash['EUI'] = v[:openstudio_resultstotal_site_eui]
	general_hash['Unmet Hours Occupied Cooling'] = v[:openstudio_resultsunmet_hours_during_occupied_cooling]
	general_hash['Unmet Hours Occupied Heating'] = v[:openstudio_resultsunmet_hours_during_occupied_heating]
	datapoint_hash['General'] = general_hash

	# populate primary hash
	if grouped_hash.has_key?(description_key)
		grouped_hash[description_key][scenario] = datapoint_hash
	else
		grouped_hash[description_key] = {}
		grouped_hash[description_key][scenario] = datapoint_hash
	end

end

# populate header for scenario csv
headers = []
grouped_hash.values.first.values.first['General'].keys.each do |key|
	headers << key
end
grouped_hash.values.first.values.first['End Use'].keys.each do |key|
	headers << key
end
grouped_hash.values.first.values.first['Heat Gain'].keys.each do |key|
	headers << key
end
grouped_hash.values.first.values.first['Heat Loss'].keys.each do |key|
	headers << key
end
grouped_hash.values.first.values.first['Metrics'].keys.each do |key|
	headers << key
end

# loop through groups and generate plots
output << "grouped hash has #{grouped_hash.size} items<br>"
grouped_hash.keys.sort.each { |k| grouped_hash[k] = grouped_hash.delete k }
grouped_hash.each do |k,v|

	# setup has to store last scenario
	last_scen_vals = {}

	# flag for failed run in group
	failed_group = false

	# loop through datapoints in group
	v.keys.sort.each { |k| v[k] = v.delete k }
	v.each do |k2,v2|

		# shows up as text
		output << "Scenario #{k2}<br>"
		output << "EUI is #{v2['General']['EUI']}. Scenario 0 EUI is #{v.values.first['General']['EUI']}<br>"
		output << "Heating is #{v2['End Use']['Heating']}<br>"		

		if last_scen_vals.size > 0

			# skip this group of it hits a datapoint that didn't run
			if failed_group || v2['General']['EUI'].nil?
				failed_group = true
				# store empty metrics
				v2['Metrics']['Sum of Absolute End Use Errors Divided by EUI of Previous Scenario'] = nil
				v2['Metrics']['Sum of End Use Errors Divided by EUI of Previous Scenario'] = nil
				v2['Metrics']['Largest Contributor to Absolute End Use Error'] = nil
				v2['Metrics']['EUI Error Versus Prototype as Percentage'] = nil
			else

				# calculate the absolute and 
				# calculate non-absolute delta from previous scenario
				# identify with string largest contributor to overall absolute error
				end_use_abs_error = {}
				end_use_error = {}
				v2['End Use'].each do |k3,v3|
					end_use_abs_error[k3] = (last_scen_vals[k3] - v3).abs
					end_use_error[k3] = last_scen_vals[k3] - v3
				end
				abs_end_use_error_norm = 100 * end_use_abs_error.values.inject(:+)/last_scen_vals.values.inject(:+)
				end_use_error_norm = 100 * end_use_error.values.inject(:+)/last_scen_vals.values.inject(:+)
				if end_use_abs_error.values.max > 0
					end_use_max_error = end_use_abs_error.key(end_use_abs_error.values.max)
				else
					end_use_max_error = 'NA'
				end

				# store metrics
				v2['Metrics']['Sum of Absolute End Use Errors Divided by EUI of Previous Scenario'] = abs_end_use_error_norm
				v2['Metrics']['Sum of End Use Errors Divided by EUI of Previous Scenario'] = end_use_error_norm
				v2['Metrics']['Largest Contributor to Absolute End Use Error'] = end_use_max_error
				if v.values.first['General']['EUI'] > 0
					v2['Metrics']['EUI Error Versus Prototype as Percentage'] = -100 * (1 - v2['General']['EUI']/v.values.first['General']['EUI'])
				else
					v2['Metrics']['EUI Error Versus Prototype as Percentage'] = ''
				end
			end

		end

		# store values from last scenario
		v2['End Use'].each do |k3,v3|
			last_scen_vals[k3] = v3
		end

		# populate CSV
	  arr_row = []
	  v2['General'].keys.each {|header| arr_row.push(v2['General'].key?(header) ? v2['General'][header] : nil)}
	  v2['End Use'].keys.each {|header| arr_row.push(v2['End Use'].key?(header) ? v2['End Use'][header] : nil)}
	  v2['Heat Gain'].keys.each {|header| arr_row.push(v2['Heat Gain'].key?(header) ? v2['Heat Gain'][header] : nil)}
	  v2['Heat Loss'].keys.each {|header| arr_row.push(v2['Heat Loss'].key?(header) ? v2['Heat Loss'][header] : nil)}
	  v2['Metrics'].keys.each {|header| arr_row.push(v2['Metrics'].key?(header) ? v2['Metrics'][header] : nil)}
	  csv_out_row = CSV::Row.new(headers, arr_row)
	  csv_out_rows.push(csv_out_row) 

	end
end

# read in template
html_in_path = "report.html.in"
html_in = ''
File.open(html_in_path, 'r') do |file|
  html_in = file.read
end

# configure template with variable values
renderer = ERB.new(html_in)
html_out = renderer.result(binding)

# write html file
html_out_path = './report.html'
File.open(html_out_path, 'w') do |file|
  file << html_out
  # make sure data is written to the disk one way or the other
  begin
    file.fsync
  rescue StandardError
    file.flush
  end
end

# save csv
csv_table = CSV::Table.new(csv_out_rows)
path_report = "scenario_results.csv"
puts "saving csv file to #{path_report}"
File.open(path_report, 'w'){|file| file << csv_table.to_s}

# todo - start with puts statement, then relace with plots
# todo - there will be three plots per group (end use, heat gain, heat loss)