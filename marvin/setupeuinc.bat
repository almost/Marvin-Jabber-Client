@echo off
REM This batch file will set up the enviroment variables nesecery (in addition to the ones Euphoria sets by default) to run Marvin from source
REM It will then run whatever was passed on its command line

REM One line per section
SET EUINC=%EUINC%;..\alphablend
SET EUINC=%EUINC%;..\eebax
SET EUINC=%EUINC%;..\irregular
SET EUINC=%EUINC%;..\SkinX
SET EUINC=%EUINC%;..\xhtmlrtf
SET EUINC=%EUINC%;..\dragwin
SET EUINC=%EUINC%;..\jabber
SET EUINC=%EUINC%;..\PropList
SET EUINC=%EUINC%;..\systray
SET EUINC=%EUINC%;..\windraw
SET EUINC=%EUINC%;..\async

START %1 %2 %3 %4 %5 %6 %7 %8 %9