try {
    Import-Module ALTools -Force

    $invocationStartTime = [DateTime]::UtcNow
    Set-Location $env:TEMP
    $object = Import-Csv -Path $(Get-ChildItem -Path $env:TEMP -Filter *_eventlogs.csv | Sort-Object LastWriteTime -Descending)[0]
    $invocationEndTime = [DateTime]::UtcNow

    $writeToLogAnalyticsSplat = @{
        ALWorkspaceID       = 'e56ad07d-14a3-4f62-8a5a-6d58598c1ceb'
        invocationStartTime = $invocationStartTime
        PSObject            = $object
        ALTableIdentifier   = 'IntuneTEST' #Your name for Azure Logs
        invocationEndTime   = $invocationEndTime
        WorkspacePrimaryKey = 'XXXXXXXXXXXXXXXXXXX'
    }
    Write-ToLogAnalytics @writeToLogAnalyticsSplat
    $null = New-Item -Path $env:TEMP -Name 'eventlogs.sent' -ItemType File -Force
} catch {
    $errMsg = $_
    Write-Error "$errMsg"
    exit 1
}