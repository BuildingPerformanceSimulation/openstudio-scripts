# T24OSLibrary
OpenStudio Library for Title 24 models

##Ruby Script to Build T24 Schedules, Load Definitions, and Space Types
run ```ruby buildT24osm.rb``` to build the ```T24library.osm``` file.

Schedules and Space Types are available online in the [CBECC-COM T24 Documentation](https://sourceforge.net/p/cbecc-com/code/HEAD/tree/trunk/Documentation/T24N/) and in the ```resources``` folder.

You can make these space types and schedule sets available for assignment in your OpenStudio model through "File->Load Library".

##Important notes: 
  - Schedules are built using Schedule:Year, which are not editable in the app.  If you want to adjust a schedule, you will need to make a new Ruleset Schedule.
  - Infiltration Design Flow rate is defaulted to 0.595 cfm/sf exterior, the 189.1-2009 value for ASHRAE climate zones 1-3.
  - Design Specification Outdoor Air is set to sum people and floor per area to get the total ventilation rate.  Only a few spaces have vent per person values such that the total ventilation rate is higher than the floor area minimum.  These values are different from ASHRAE 62.1.
  - Temperature Setpoints for each space type are available in the model as Schedule:Year objects, and can be assigned to thermal zones.
  - The schedule resources include water mains temperature, but these are not yet included in this T24OSMlibrary
  - The "Computer Room" space type is not included - it has special weekly month by month, so was omitted for now.
  - Materials, Constructions, and Construction Sets are not yet included but will be added soon.