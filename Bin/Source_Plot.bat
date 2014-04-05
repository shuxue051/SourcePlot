@echo off
cd /d %~dp0

set FilePath=%1
set FileExtName=%FilePath:~-3,3%

if  /i "%FileExtName%"=="SQL"   perl SQL_Plot2.pl  %FilePath%
if  /i "%FileExtName%"=="FMB"   perl Form_Plot2.pl  %FilePath%
if  /i "%FileExtName%"=="RDF"   perl Report_Plot2.pl  %FilePath%




