@echo off
setlocal enabledelayedexpansion

set healthplan=%1
set processid=%2

REM Capture Start Time (formatted cleanly)
for /f "tokens=2 delims==" %%I in ('"wmic os get localdatetime /value"') do set datetime=%%I
set starttime=%datetime:~0,4%-%datetime:~4,2%-%datetime:~6,2% %datetime:~8,2%:%datetime:~10,2%:%datetime:~12,2%

REM Run DBT Profiling
dbt run --select tag:profiling --vars "{\"healthplan\": \"%healthplan%\", \"processid\": \"%processid%\"}"
if %errorlevel% neq 0 (
    set profiling_status=FAIL
) else (
    set profiling_status=SUCCESS
)

REM Run DBT Validations
dbt test --select tag:validation --vars "{\"healthplan\": \"%healthplan%\", \"processid\": \"%processid%\"}"
if %errorlevel% neq 0 (
    set validation_status=FAIL
) else (
    set validation_status=SUCCESS
)

REM Capture End Time (formatted cleanly)
for /f "tokens=2 delims==" %%I in ('"wmic os get localdatetime /value"') do set datetime=%%I
set endtime=%datetime:~0,4%-%datetime:~4,2%-%datetime:~6,2% %datetime:~8,2%:%datetime:~10,2%:%datetime:~12,2%

REM Insert into SQL Server Log Table using Windows Authentication (-E flag)

sqlcmd -S ITGBIDATACA2.headquarters.newcenturyhealth.com -d NonDelegatedClaims -E -Q "INSERT INTO dbo.DBT_NDC_Validation_RunLog (RunStartTime, RunEndTime, HealthPlan, ProcessID, ProfilingStatus, ValidationStatus) VALUES ('%starttime%', '%endtime%', '%healthplan%', '%processid%', '%profiling_status%', '%validation_status%')"
sqlcmd -S ITGBIDATACA2.headquarters.newcenturyhealth.com -d NonDelegatedClaims -E -Q "UPDATE dbo.DBT_NDC_Validation_Process_input SET IsActive = 0 WHERE HealthPlan = '%healthplan%' AND ProcessID = '%processid%'"

pause