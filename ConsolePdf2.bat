@echo off
cls
echo Converting to console executables
for %%f in (pdf2*.exe) do win2con.exe %%f
