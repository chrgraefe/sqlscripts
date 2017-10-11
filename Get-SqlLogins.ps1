Import-Module dbatools

#Get a list of instances where you will run the command through
$SQLServers = @( "localhost\SQL2016", "localhost\SQL2016" )

#If the folder does not exists create it
$newFolder = "C:\temp\ExportLogins\$(Get-Date -f MM-dd-yyyy_HH_mm_ss)"
if ((Test-Path -LiteralPath $newFolder) -eq $false) {
    New-Item -Type Directory -Path $newFolder
}

#For each instance 
Foreach ($InstanceName in $SQLServers) {
    
    #generate a filename
    $fileName = $InstanceName -replace ",", "_"
    $fileName = $fileName -replace "\\", "_"

    #run the Export-SqlLogin command
    Export-DbaLogin -SqlInstance $InstanceName -FilePath "$newFolder\$fileName.sql" 
}