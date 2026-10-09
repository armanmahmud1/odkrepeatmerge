{smcl}
{* *! version 1.1.0 09oct2026 Arman Mahmud}{...}
{viewerjumpto "Syntax" "odkrepeatmerge##syntax"}{...}
{viewerjumpto "Description" "odkrepeatmerge##description"}{...}
{viewerjumpto "Options" "odkrepeatmerge##options"}{...}
{viewerjumpto "Examples" "odkrepeatmerge##examples"}{...}
{viewerjumpto "Stored results" "odkrepeatmerge##results"}{...}
{viewerjumpto "Author" "odkrepeatmerge##author"}{...}
{viewerjumpto "Also see" "odkrepeatmerge##alsosee"}{...}
{hline}
help for {bf:odkrepeatmerge} {right:version 1.1.0 09oct2026}
{hline}

{title:Title}

{p 4 4 2}
{bf:odkrepeatmerge} {hline 2} Integrate ODK repeat-group data following questionnaire order


{marker syntax}{...}
{title:Syntax}

{p 8 16 2}
{cmd:odkrepeatmerge}{cmd:,}
{cmdab:formid(}{it:string}{cmd:)}
{cmdab:formtitle(}{it:string}{cmd:)}
[{cmdab:formloc(}{it:string}{cmd:)}]

{synoptset 24 tabbed}{...}
{synopthdr}
{synoptline}
{p2coldent:* {opt formid(string)}}the form ID from the Settings tab of the ODK form{p_end}
{p2coldent:* {opt formtitle(string)}}filename of the XLSForm (e.g., {it:"My Survey.xlsx"}){p_end}
{synopt:{opt formloc(string)}}directory path where the form and CSV files are stored; defaults to the current working directory{p_end}
{synoptline}
{p 4 4 2}* {opt formid()} and {opt formtitle()} are required.


{marker description}{...}
{title:Description}

{p 4 4 2}
{cmd:odkrepeatmerge} automates the integration of repeat-group CSV files
exported from ODK Central (or compatible tools) into a single Stata dataset.
It reads the XLSForm to identify repeat groups, merges nested groups bottom-up
via {cmd:reshape wide}, and reorders all variables to match the original
questionnaire sequence.

{p 4 4 2}
The resulting {bf:.dta} file is saved to the directory specified in
{opt formloc()}, or to the current working directory if {opt formloc()} is
omitted.  The filename is {it:formid}{bf:.dta}.

{p 4 4 2}
The command expects CSV files named {it:formid}{bf:-}{it:groupname}{bf:.csv}
for each repeat group, following the ODK Central export convention.

{p 4 4 2}
{bf:Note:} The command uses {cmd:preserve} internally; data in memory is
restored after the command finishes (including on error).


{marker options}{...}
{title:Options}

{phang}
{opt formid(string)} specifies the form ID, which can be found in the
{bf:Settings} tab of the ODK XLSForm.  This is also the stem of the main CSV
filename (e.g., if {it:formid} is {cmd:"my_survey"}, the main data file is
{cmd:my_survey.csv}).

{phang}
{opt formtitle(string)} specifies the filename of the XLSForm Excel file
(e.g., {cmd:"My Survey ODK.xlsx"}).  The file must contain columns named
{cmd:type} and {cmd:name}.

{phang}
{opt formloc(string)} specifies the directory path where the XLSForm and all
CSV data files are stored.  If omitted, the current working directory is used.
Use forward slashes in paths (e.g., {cmd:"D:/My drive/test"}).


{marker examples}{...}
{title:Examples}

{p 4 4 2}
Merge repeat-group data from files in a specific directory:

{phang2}{cmd:. odkrepeatmerge, formid("rmg_environmental_survey") formtitle("RMG Environmental Survey ODK.xlsx") formloc("D:/My drive/test")}

{p 4 4 2}
Merge repeat-group data from the current working directory:

{phang2}{cmd:. odkrepeatmerge, formid("my_survey") formtitle("my_survey.xlsx")}


{marker results}{...}
{title:Stored results}

{p 4 4 2}
{cmd:odkrepeatmerge} does not store any results in {cmd:r()}, {cmd:e()}, or {cmd:s()}.
The output is a {bf:.dta} file written to disk.


{marker author}{...}
{title:Author}

{p 4 4 2}
Arman Mahmud{p_end}
{p 4 4 2}
Email: {browse "mailto:armanmahmud.du18@gmail.com":armanmahmud.du18@gmail.com}{p_end}
{p 4 4 2}
Web: {browse "https://www.arman-mahmud.com":arman-mahmud.com}{p_end}


{marker alsosee}{...}
{title:Also see}

{p 4 4 2}
{help odkmeta:odkmeta} (if installed),
{help odksplit:odksplit} (if installed),
{help reshape:reshape},
{help merge:merge}
{p_end}
