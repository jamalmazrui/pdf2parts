@echo off
cls
for %%f in (%2) do %~dp0%1 "%%f"
