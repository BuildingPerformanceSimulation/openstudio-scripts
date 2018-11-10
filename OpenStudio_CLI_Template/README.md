# OpenStudio Command Line Interface Template
----
*This is a template for running parametrics using the command line interface in OpenStudio.*

## Why this template?
The OpenStudio Parametric Analysis Tool (PAT) is the first method of choice for evaluating series of energy efficiency measures.  PAT launches a local server for small jobs, and integrates with Amazon Web Services (AWS) for larger sensitivity, uncertainty, or other algorithmic runs that require hundreds or thousands of simulations.  For a complete parametric analysis, use the Design of Experiments (DOE) algorithm set to "full_factorial".  
However, if the project has multiple baseline models, multiple weather files, or combines measures in complex and unique measure packages that would be difficult to specify in PAT, using the OpenStudio Command Line Interface (CLI) directly can be faster.

## Contents
  - *files* directory that contains baseline *.osm* and *.epw* files.
  - *measures* directory that contains all OpenStudio measures in the project.
  - *workflows* directory houses a subdirectory for each simulation.
  - This *README.md* file.
  - *generate_workflows.rb* writes an OpenStudio workflow *.osw* file for each simulation.  Measure specification and logic to parameterize runs goes here.
  - *run_workflows.rb* runs each *.osw* file.  Specify how many simulations to run in parallel.  Limit to <=4 if using the computer for other things while running simulations.
  - *read_results.rb* extracts energy use data from each *eplusout.sql* file for each simulation and writes it to a *results.csv* file.
  - *results_spreadsheet.xlsx* takes the results file and makes energy use graphics for the project.

## Software Installation
  1. Install OpenStudio version 2.+ with the CLI module.  
    - Make sure that the directories containing the ruby executable and openstudio executable are added to the PATH environment variable in command prompt.  This is a checkbox available during the OpenStudio installation.
    - Check the software is installed by running ```openstudio -h``` and ```ruby -v``` in command prompt.
    - On windows, add the directory paths manually here: *System -> Advanced System Settings -> Environment Variables -> System variables -> PATH -> edit*

## Setting Up The Analysis
  1. **Construct baseline OpenStudio models.**
  - If any OpenStudio measure requires selecting a construction, schedule, or other object in the model, add these in the baseline model.
  2. **Create a directory containing:**
  - The *generate_workflows.rb* *run_workflows.rb* and *read_results.rb* ruby scripts.
  - *files* directory that contains baseline *.osm* and *.epw* files.
  - *measures* directory that contains all OpenStudio measures in the project.
  - **All files and folders in the project should not contain whitespace in their names, e.g. *underscored_path/to/files/my_model.osm* not *whitespace path/to/files/my model.osm***.
  3. **Selecting, editing, writing, and testing measures**
  - Copy measures from BCL or add custom measures to the *mesaures* directory.
  - Test each measure individually in the OpenStudio app and resolve errors.

## Running The Analysis
Run the following commands in command line.  Pressing tab in command line will autocomplete a filename in the current directory.
  1. Run *openstudio generate_workflows.rb*
  2. Run *run_workflows.rb*.  Errors that show up in command line mean a measure or an EnergyPlus simulation failed.  Read the error prompt and resolve.
  3. Run *read_results.rb*.  If there is an error, it likely means that one of the workflows does not contain an *eplusout.sql* file.  This could be because a simulation is not yet finished, or a simulation failed.
  4. Copy the *results.csv* file to the *results* worksheet of the *results_spreadsheet.xlsx* spreadsheet, and add any post-processing that applies to the project.
