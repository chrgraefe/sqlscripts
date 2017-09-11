Install-Module dbatools -Scope CurrentUser

#Get a list of instances where you will run the command through
$SQLServers = { "dummy.sv.db.de\ENTWICKLUNG", "dummy.sv.db.de" }

#If the folder does not exists create it
$newFolder = "D:\WORKING\temp\ExportLogins\$(Get-Date -f MM-dd-yyyy_HH_mm_ss)"
if ((Test-Path -LiteralPath $newFolder) -eq $false) {
    New-Item -Type Directory -Path $newFolder
}

#For each instance 
$SQLServers | Foreach-Object {
    
    #generate a filename
    $fileName = $_.InstanceConnection -replace ",", "_"
    $fileName = $fileName -replace "\\", "_"

    #run the Export-SqlLogin command
    Export-SqlLogin -SqlInstance $_.InstanceConnection -FilePath "$newFolder\$fileName.sql" 
}