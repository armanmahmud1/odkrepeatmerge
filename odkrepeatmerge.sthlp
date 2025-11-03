{smcl}
{* *! version 1.0.0 Arman Mahmud 25oct2025}{...}
{hline}
help for {bf:odkrepeatmerge} {right: }
{hline}

{title:Title}

{p 4 4 2}
{bf:odkrepeatmerge} Run this command to integrate repeat group data from ODK, following the questionnaire's sequence.

{title:Description}

{p 4 4 2}
{cmd:odkrepeatmerge} command is designed to seamlessly integrate repeat group data collected from ODK forms. Once all repeat group files are merged, it organizes the variables according to the structure and sequence of the original questionnaire.

{title:Example}
	
	odkrepeatmerge,formid("rmg_environmental_survey") \\\
	formtitle("RMG Environmental Survey ODK.xlsx") \\\
	formloc("D:\My drive\test")
	
	*formtitle: The title of the form.
	*formid: This can be found in the Settings tab of your ODK form.
	*formloc: The directory path where the form is stored. For example, if your form is located at D:\My drive\test\RMG Environmental Survey ODK.xlsx, then the formloc should be set to "D:\My drive\test".
	** formloc field is optional. If not specified, the current working directory will be used as the form location by default.

{title:Author}

{p 4 4 2}
Arman Mahmud{p_end}
{p 4 4 2}
Email: {browse "mailto:armanmahmud.du18@gmail.com":armanmahmud.du18@gmail.com}{p_end}
{p 4 4 2}
Web: {browse "https://sites.google.com/view/armanmahmud1/":website}{p_end}
