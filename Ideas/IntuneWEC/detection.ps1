#=============================================================================================================================
#
# Script Name:     Detect_Expired_Issuer_Certificates.ps1
# Description:     Detect expired certificates issued by "CN=<your CA here>" in either Machine
#                  or User certificate store
# Notes:           Change the value of the variable $strMatch from "CN=<your CA here>" to "CN=..."
#                  For testing purposes the value of the variable $expiringDays can be changed to a positive integer
#                  Don't change the $results variable
#
#=============================================================================================================================

# Define Variables
$EventLog = $null
$LogName = 'Application'
$GeneratedAfter = ((Get-Date).AddHours(-1))
$InstanceId = '3221233670'

try {
	$EventLog = Get-EventLog -LogName $LogName -After $GeneratedAfter -InstanceId $InstanceId | ForEach-Object {
		# return a new object with the required information
		[PSCustomObject]@{
			Time        = $_.TimeGenerated.ToString('yyyy-MM-dd HH:MM:ss')
			# index 0 contains the name of the update
			EventID     = $_.EventID
			MachineName = $_.MachineName
			Index       = $_.Index
			User        = $_.UserName
			Message     = $_.Message
		}
	}

	if ($null -ne $EventLog) {
		#Below necessary for Intune as of 10/2019 will only remediate Exit Code 1
		Write-Host "Found: $($($EventLog | Measure-Object).count) events"
		$Timestamp = (Get-Date)
		$FileTimeStamp = $Timestamp.ToString('yyyyMMddhhmm')
		$null = $EventLog | Export-Csv -Path "$PSScriptRoot\$($FileTimeStamp)_eventlogs.csv" -NoTypeInformation
		if ((Get-ChildItem $PSScriptRoot *_eventlogs.csv | Measure-Object).Count -eq 1) {
			exit 1
		} elseif (((Get-ChildItem $PSScriptRoot *_eventlogs.csv | Sort-Object LastWriteTime -Descending)[1].name -split '_')[0] -lt $($Timestamp.AddMinutes(-30)).ToString('yyyyMMddhhmm')) {
			exit 1
		} elseif (Test-Path $PSScriptRoot\eventlogs.sent) {
			Remove-Item -Path $PSScriptRoot\remediate.ps1 -Force
			exit 0
		}
	} else {
		#No matching certificates, do not remediate
		Write-Host "No events"
		exit 0
	}
} catch {
	$errMsg = $_
	Write-Error $errMsg
	#exit 1
}