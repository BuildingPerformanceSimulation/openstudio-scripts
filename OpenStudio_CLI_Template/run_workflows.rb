# run_workflows.rb
#
# runs all workflow.osw files in subdirectories under the "workflows" directory
# requires OpenStudio 2.+ with the command line interface installed
# use generate_workflows.rb or generate_workflows_parametric.rb 
# output results are in the "reports" folder under each subdirectory
require 'fileutils'

puts "Finding workflows to run..."
jobs = []
workflow_directories = Dir.glob("workflows/*")
workflow_directories.each do |directory|
  workflow = "#{directory}/workflow.osw"
  if !File.file?(workflow)
    puts "no workflow.osw file found for #{directory}"
  else
    jobs << "openstudio run -w '#{workflow}'"
    #puts "#{workflow} added to jobs"
  end
end
puts "Found #{jobs.length} workflows to run."

# gem for running jobs in parallel
require 'parallel'
num_parallel = 4
Parallel.each(jobs, in_threads: num_parallel) do |job|
  puts job
  system(job)
end