{smcl}
{* *! version 1.3.0 18oct2026 Arman Mahmud}{...}
{viewerjumpto "Syntax" "odkrepeatmerge##syntax"}{...}
{viewerjumpto "Description" "odkrepeatmerge##description"}{...}
{viewerjumpto "Before you run" "odkrepeatmerge##files"}{...}
{viewerjumpto "Options" "odkrepeatmerge##options"}{...}
{viewerjumpto "Remarks" "odkrepeatmerge##remarks"}{...}
{viewerjumpto "Examples" "odkrepeatmerge##examples"}{...}
{viewerjumpto "Stored results" "odkrepeatmerge##results"}{...}
{viewerjumpto "Author" "odkrepeatmerge##author"}{...}
{hline}
help for {bf:odkrepeatmerge} {right:version 1.3.0 18oct2026}
{hline}

{title:Title}

{p 4 4 2}
{bf:odkrepeatmerge} {hline 2} Merge ODK repeat-group data into one wide dataset in questionnaire order


{marker syntax}{...}
{title:Syntax}

{p 8 16 2}
{cmd:odkrepeatmerge}{cmd:,}
{opt formid(string)}
{opt xls:form(filename)}
[{opt formloc(path)}
{cmd:saving(}{it:filename} [{cmd:, replace}]{cmd:)}
{opt replace}
{opt sep:arator}
{opt all:string}]

{synoptset 28 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Required}
{synopt:{opt formid(string)}}form ID; the main CSV is {it:formid}{cmd:.csv}{p_end}
{synopt:{opt xls:form(filename)}}XLSForm file used to collect the data{p_end}

{syntab:Optional}
{synopt:{opt formloc(path)}}folder holding the files; default is the current working directory{p_end}
{synopt:{cmd:saving(}{it:filename} [{cmd:, replace}]{cmd:)}}output file; default is {it:formid}{cmd:.dta} in the data folder{p_end}
{synopt:{opt replace}}overwrite the output file if it exists{p_end}
{synopt:{opt sep:arator}}name variables {cmd:q1_11} instead of {cmd:q111}{p_end}
{synopt:{opt all:string}}import all columns as strings (keeps leading zeros){p_end}
{synoptline}
{p 4 6 2}{opt formtitle()} is accepted as a synonym for {opt xlsform()}.{p_end}


{marker description}{...}
{title:Description}

{p 4 4 2}
{cmd:odkrepeatmerge} combines the main CSV file and the repeat-group CSV files
exported from ODK Central into one Stata dataset with one row per submission.
It reads the XLSForm to find the repeat groups and how they are nested,
reshapes each repeat group to wide form, merges it into its parent, and
orders all variables to follow the questionnaire.

{p 4 4 2}
The data in memory are not changed; the result is saved as a {cmd:.dta}
file.  {cmd:odkrepeatmerge} requires Stata 14 or newer; it was developed
and tested on Stata 17.


{marker files}{...}
{title:Before you run}

{p 4 4 2}
Put all input files in {bf:one folder} (the data folder):

{p 8 11 2}
{c -} the main (parent) CSV: {it:formid}{cmd:.csv}{p_end}
{p 8 11 2}
{c -} one child CSV per repeat group: {it:formid}{cmd:-}{it:groupname}{cmd:.csv}{p_end}
{p 8 11 2}
{c -} the XLSForm ({cmd:.xlsx}) used to collect the data{p_end}

{p 4 4 2}
{cmd:odkrepeatmerge} looks for these files in the {opt formloc()} folder.
{bf:If you do not specify formloc(), it looks in the current working}
{bf:directory, so that directory must be the data folder.}  Either:

{p 8 11 2}
1. change to the data folder first, then run the command without
{opt formloc()}:{p_end}
{phang3}{cmd:. cd "D:/survey/data"}{p_end}
{phang3}{cmd:. odkrepeatmerge, formid("hh_survey") xlsform("HH Survey.xlsx")}{p_end}

{p 8 11 2}
2. or stay where you are and point to the data folder with {opt formloc()}:{p_end}
{phang3}{cmd:. odkrepeatmerge, formid("hh_survey") xlsform("HH Survey.xlsx") formloc("D:/survey/data")}{p_end}

{p 4 4 2}
In both cases the output is saved in the data folder as
{it:formid}{cmd:.dta} ({cmd:hh_survey.dta} above), unless you use
{opt saving()}.


{marker options}{...}
{title:Options}

{dlgtab:Required}

{phang}
{opt formid(string)} is the form ID: the name of the main CSV without
{cmd:.csv} (also the {cmd:form_id} on the {bf:settings} sheet of the
XLSForm).  The child files must be named {it:formid}{cmd:-}{it:groupname}{cmd:.csv}.

{phang}
{opt xlsform(filename)} is the file name of the XLSForm, e.g.
{cmd:"HH Survey.xlsx"}.  Give only the file name; its folder is set by
{opt formloc()} or the current working directory.  The form is read from its
{cmd:survey} sheet, which must have {cmd:type} and {cmd:name} columns.
{opt formtitle()} is an older name for this option and still works.

{dlgtab:Optional}

{phang}
{opt formloc(path)} is the data folder that holds the XLSForm and all CSV
files.  If omitted, the current working directory is used (see
{help odkrepeatmerge##files:Before you run}).  Forward slashes work on all
platforms, e.g. {cmd:formloc("D:/My drive/survey")}.

{phang}
{cmd:saving(}{it:filename} [{cmd:, replace}]{cmd:)} saves the result under
another name.  A file name without a folder is saved in the current working
directory.  Add {cmd:, replace} inside the parentheses to overwrite an
existing file.

{phang}
{opt replace} overwrites the output file if it already exists.  Without
{opt replace} (here or inside {opt saving()}), {cmd:odkrepeatmerge} never
overwrites a file; use it when you run the command again.

{phang}
{opt separator} puts an underscore between a question name and its instance
number: {cmd:q1_11} instead of {cmd:q111}.  Use it when two questions differ
only by trailing digits (e.g. {cmd:q1} and {cmd:q11}); without it their
names would clash and {cmd:odkrepeatmerge} stops with an error.

{phang}
{opt allstring} imports every CSV column as a string.  By default numbers
are detected automatically, so codes such as {cmd:007} become {cmd:7}.
Use {helpb destring} afterwards for the variables you want as numbers.


{marker remarks}{...}
{title:Remarks}

{pstd}
{bf:Variable names.} Repeat-group questions get the instance number added:
{cmd:age2} is question {cmd:age} for member 2.  For a repeat nested inside
another, the numbers are listed innermost first: {cmd:ill_type2_1} is
question {cmd:ill_type} for illness 2 of member 1 ({cmd:ill_type_2_1} with
{opt separator}).

{pstd}
{bf:Order.} Variables follow the order of the {cmd:survey} sheet, with each
repeat instance kept together.  Columns that are not in the XLSForm (for
example from an older form version) are placed at the end and listed on
screen.  ODK Central system columns such as {cmd:SubmissionDate} are placed at
the end without being listed.

{pstd}
{bf:Group names.} ODK Central may name fields inside groups
{it:group}{cmd:-}{it:field}.  These prefixes are removed automatically, so
exports with or without "Remove group names" both work.


{marker examples}{...}
{title:Examples}

{pstd}Data folder is the current working directory:{p_end}
{phang2}{cmd:. cd "D:/survey/data"}{p_end}
{phang2}{cmd:. odkrepeatmerge, formid("hh_survey") xlsform("HH Survey.xlsx")}{p_end}

{pstd}Data folder given with {opt formloc()}:{p_end}
{phang2}{cmd:. odkrepeatmerge, formid("hh_survey") xlsform("HH Survey.xlsx") formloc("D:/survey/data")}{p_end}

{pstd}Run again and overwrite the previous output:{p_end}
{phang2}{cmd:. odkrepeatmerge, formid("hh_survey") xlsform("HH Survey.xlsx") formloc("D:/survey/data") replace}{p_end}

{pstd}Save under another name, keep codes as strings, use underscore names:{p_end}
{phang2}{cmd:. odkrepeatmerge, formid("hh_survey") xlsform("HH Survey.xlsx") formloc("D:/survey/data") saving("D:/survey/hh_wide.dta", replace) allstring separator}{p_end}
{phang2}{cmd:. use "D:/survey/hh_wide.dta", clear}{p_end}


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:odkrepeatmerge} stores the following in {cmd:r()}:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:r(N)}}number of observations in the output{p_end}
{synopt:{cmd:r(k)}}number of variables in the output{p_end}
{synopt:{cmd:r(n_repeat)}}number of repeat groups in the XLSForm{p_end}
{synopt:{cmd:r(n_unmatched)}}number of variables not found in the XLSForm{p_end}

{p2col 5 20 24 2: Macros}{p_end}
{synopt:{cmd:r(fn)}}output file name{p_end}
{synopt:{cmd:r(unmatched)}}variables not found in the XLSForm{p_end}


{marker author}{...}
{title:Author}

{pstd}
Arman Mahmud{break}
Email: {browse "mailto:armanmahmud.du18@gmail.com":armanmahmud.du18@gmail.com}{break}
Web: {browse "https://www.arman-mahmud.com":arman-mahmud.com}{break}
Issues: {browse "https://github.com/armanmahmud1/odkrepeatmerge/issues"}


{title:Also see}

{psee}
{helpb import_delimited:import delimited}, {helpb reshape}, {helpb merge};
{help odkmeta} (if installed), {help odksplit} (if installed)
{p_end}
