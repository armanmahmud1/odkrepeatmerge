# odkrepeatmerge
Use this command to merge repeat group data from ODK in alignment with the questionnaire's order. It ensures the data follows the original sequence of the survey.

## 🚧 odkrepeatmerge Status
⚠️ **Warning:** ``odkrepeatmerge`` is currently in the testing phase. Use it at your own risk — Author

## Descriptions
The `odkrepeatmerge` command is specifically crafted to streamline the integration of repeat group data collected through ODK forms. It automates the process of merging multiple repeat group files, ensuring that all entries are accurately consolidated without manual intervention. Once the data is merged, the command arranges the resulting variables to mirror the original questionnaire’s design, preserving both the logical flow and hierarchical structure of the survey. This ensures consistency in data analysis and simplifies downstream processing by maintaining the integrity of the survey’s intended sequence.

## Installing Process
```
net install odkrepeatmerge, from("https://raw.githubusercontent.com/armanmahmud1/odkrepeatmerge/main/") replace
```

## Example
```
    odkrepeatmerge,formid("rmg_environmental_survey") ///
	formtitle("RMG Environmental Survey ODK.xlsx") ///
	formloc("D:\My drive\test")
```

### Example Notes
  -> formtitle: The title of the form. <br>
	-> formid: This can be found in the Settings tab of your ODK form. <br>
	-> formloc: The directory path where the form is stored. For example, if your form is located at "D:\My drive\test\RMG Environmental Survey ODK.xlsx", then the formloc should be set to "D:\My drive\test". <br>
	-> formloc field is optional. If not specified, the current working directory will be used as the form location by default. <br>

## Issues
For any issues, report: https://github.com/armanmahmud1/odkrepeatmerge/issues

## Author
Arman Mahmud </br>
Email: armanmahmud.du18@gmail.com </br>
Web: https://sites.google.com/view/armanmahmud1/
