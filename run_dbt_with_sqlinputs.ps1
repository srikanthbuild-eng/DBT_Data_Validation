# PowerShell script to read inputs and call batch file

# SQL query to fetch one active row
$query = "SELECT HealthPlan, ProcessID FROM NonDelegatedClaims.dbo.DBT_NDC_Validation_Process_input WHERE IsActive = 1 ORDER BY ID"

# Connection string
$connectionString = "Server=ITGBIDATACA2.headquarters.newcenturyhealth.com;Database=NonDelegatedClaims;Integrated Security=True;"

# Execute query
$connection = New-Object System.Data.SqlClient.SqlConnection
$connection.ConnectionString = $connectionString
$connection.Open()

$command = $connection.CreateCommand()
$command.CommandText = $query

$reader = $command.ExecuteReader()

#Loop through each active row and call batch script
while ($reader.Read()) {
    $healthplan = $reader["HealthPlan"]
    $processid = $reader["ProcessID"]

    Write-Host "Running DBT for HealthPlan: $healthplan, ProcessID: $processid"

    # Now call batch script with parameters
    Start-Process -NoNewWindow -Wait -FilePath "C:\Users\SIReddy\NDC_Data_Validation\run_dbt_with_inputs.bat" -ArgumentList $healthplan, $processid
}


$reader.Close()
$connection.Close()