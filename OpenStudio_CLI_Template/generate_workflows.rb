###
# generate_workflows.rb
#
# creates workflow.osw files in subdirectories under a "workflows" directory
# requires OpenStudio 2.+ with the command line interface installed
#
# DIRECTIONS:
# - create a directory for the project and copy this script to it
# - create a sub directory called "files", and place your model .osm and weather .epw files here
# - create a sub directory called "measures" and copy all measures to that folder
# - edit the code below to add the measure(s) to the workflows
# - IMPORTANT: File and directory names cannot have spaces, as the OpenStudio command line interface will see these as two separate arguments.  Use snake_case or CamelCase and keep names short.
###

# dependencies
require 'csv'
require 'openstudio'
require 'fileutils'

# remove existing workflows directory if present and make a new one
puts "removing previous workflows"
begin
  FileUtils.remove_dir "workflows"
rescue
  puts "Directory workflows does not exist."
end
FileUtils.mkdir "workflows"

###
# Measure Documentation:
# https://github.com/NREL/OpenStudio/blob/develop/openstudiocore/src/utilities/filetypes/WorkflowStep.hpp
# Energy Efficiency Measure Definitions
# Each measure is defined as a OpenStudio::MeasureStep object, which has an argument field.  
# Each required argument in your measure should be assigned an appropriate string, double, or boolean value.
# You can see a measure's required arguments under the arguments definition in the measure.rb file
# There are three different kinds of measures: OpenStudio Measures, EnergyPlus Measures, and Reporting Measures.
# There isn't a difference in how these are specified, but you need to add them separately in measure steps below so they are added in the correct order.

# add hourly meters OpenStudio measure
add_hourly_meters = OpenStudio::MeasureStep.new("add_hourly_meters")

# OpenStudio results Reporting measure
os_results = OpenStudio::MeasureStep.new("OpenStudio Results")

# example OpenStudio measure step definition to set LPD to a specific value
eem_lpd_08 = OpenStudio::MeasureStep.new("Set Lighting Loads by LPD")
eem_lpd_08.setArgument("lpd",0.8)

# use a function formulation to make a measure step for any lpd value 
def make_eem_lpd(value)
  eem_lpd = OpenStudio::MeasureStep.new("Set Lighting Loads by LPD")
  eem_lpd.setArgument("lpd",value)
  return eem_lpd
end

# example that returns a DOE prototype measure step based on user arguments
def eem_DOE_prototype(building_type,template,climate_zone)
  eem_deer = OpenStudio::MeasureStep.new("create_DOE_prototype_building")
  eem_deer.setArgument("building_type",building_type)
  eem_deer.setArgument("template",template)
  eem_deer.setArgument("climate_zone",climate_zone)
  return eem_deer
end

### Model Workflows
# Workflow Documentation: 
# https://github.com/NREL/OpenStudio/blob/develop/openstudiocore/src/utilities/filetypes/WorkflowJSON.hpp
# Add the file paths to .osm and .epw files here, specified with as an OpenStudio::Path object.
empty_osm_filepath = OpenStudio::Path.new("#{File.join(Dir.pwd,"files/empty_model.osm")}")
example_osm_filepath = OpenStudio::Path.new("#{File.join(Dir.pwd,"files/office_chicago.osm")}")
example_epw_filepath = OpenStudio::Path.new("#{File.join(Dir.pwd,"files/USA_IL_Chicago-OHare.Intl.AP.725300_TMY3.epw")}")

# This function takes a run name, openstudio file path, epw filepath, and an array of measure steps (one argument for OpenStudio Measures, one for EnergyPlus measures, and one for Reporting Mesaures) and makes an OpenStudio workflow (.osw).
# Use naming convention for run_name that keeps the names short and doesn't include whitespace.
def makeOSW(run_name, osm_filepath, epw_filepath, model_measure_steps = [], energyplus_measure_steps = [], reporting_measure_steps = [])
  puts "Making directory #{run_name}"
  FileUtils.mkdir "workflows/#{run_name}"
  osw_filepath = OpenStudio::Path.new("#{Dir.pwd}/workflows/#{run_name}/workflow.osw")
  osw = OpenStudio::WorkflowJSON.new
  osw.setSeedFile(osm_filepath)
  osw.setWeatherFile(epw_filepath)
  if !model_measure_steps.empty?  
    measure_type = OpenStudio::MeasureType.new("ModelMeasure")
    check = osw.setMeasureSteps(measure_type, model_measure_steps)
    puts "check: #{check}"
  end
  if !energyplus_measure_steps.empty?
    measure_type = OpenStudio::MeasureType.new("EnergyPlusMeasure")
    osw.setMeasureSteps(measure_type, energyplus_measure_steps)
  end
  if !reporting_measure_steps.empty?
    measure_type = OpenStudio::MeasureType.new("ReportingMeasure")
    check2 = osw.setMeasureSteps(measure_type, reporting_measure_steps)
    puts "check2: #{check2}"
  end
  osw.saveAs(osw_filepath)
  puts "#{run_name} osw written"
  return true
end

# For a baseline run, we can just pass an empty array in place of our measure steps
makeOSW("baseline", example_osm_filepath, example_epw_filepath, [], [], [])

# Adding results measures, making sure to pass in measures into the correct array by the kind of measure (OpenStudio, EnergyPlus, or Reporting)
makeOSW("baseline_with_results", example_osm_filepath, example_epw_filepath, [add_hourly_meters], [], [os_results])

# For a single eem, include the eem name in the appropriate array argument
# If you want your results to match the order you specify runs below, add a lettering convention (a,b,c...) to the start of the run_name so that the subdirectories are ordered alphabetically.
makeOSW("single_eem", example_osm_filepath, example_epw_filepath, [eem_lpd_08], [], [os_results])

# Predefine an array that represents a measure package
package1_model_measure_steps = []
# Add the DOE prototype measure first, and then add the LPD measure
# The DOE protoype measure will replace both the model and weather file, so the .osm and .epw arguments can be anything
package1_model_measure_steps << eem_DOE_prototype('SecondarySchool','90.1-2007','ASHRAE 169-2006-5A')
package1_model_measure_steps << eem_lpd_08
makeOSW("doe_proto_lpd08", empty_osm_filepath, example_epw_filepath, package1_model_measure_steps, [], [os_results])

# If there are lots of runs to simulate, make the .osw files with parametrics
lpds = [0.4, 0.6, 0.8, 1.0]
lpds.each do |lpd|
  run_name = "eem_lpd_#{lpd.to_s.delete(".")}"
  eem_lpd = make_eem_lpd(lpd)
  makeOSW(run_name, example_osm_filepath, example_epw_filepath, [eem_lpd], [], [os_results])
end

# example parametrics for apply a measure to DOE prototypes
building_types = ['SecondarySchool',
                  'PrimarySchool']
templates = ['DOE Ref Pre-1980',
             '90.1-2013']
climate_zones = ['ASHRAE 169-2006-4A',
                 'ASHRAE 169-2006-5A']
# The run names can get unwieldy as subdirectory names with parametrics, so here the runs are labeled run1, run2, etc. and a separate file is saved to map run names to parametric inputs
run_names = []
i=1
building_types.each do |building_type|
  templates.each do |template|
    climate_zones.each do |climate_zone|
      run_names << ["run#{i}","#{building_type}","#{template}","#{climate_zone}"]
      makeOSW("run#{i}", empty_osm_filepath, example_epw_filepath, [eem_DOE_prototype(building_type, template, climate_zone), eem_lpd_08, add_hourly_meters], [], [os_results])
      i+=1
    end
  end
end

CSV.open("#{Dir.pwd}/run_names_map.csv", "w") do |csv|
  csv << ["id","building_type","template","climate_zone"]
  run_names.each do |r|
    csv << r
  end
end