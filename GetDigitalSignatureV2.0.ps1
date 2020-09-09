param($Folders=@('c:\Program Files\Avest','c:\Program Files\SafeNet',
    'c:\Program Files (x86)\Avest','c:\Program Files (x86)\Common Files\Avest',
    'c:\Program Files (x86)\Prior'))
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
$resultFile = [string](Get-Date -format "ddMMyyyy_HHmmss")
$resultFullName = $PSScriptRoot +"\" + $resultFile + "_NotValidSignature.txt"
$count = 0
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Dictionary prevents from duplicated entries
$Dictionary = New-Object -ComObject "Scripting.Dictionary"

Write-Host "Report file created"
New-Item -Path $PSScriptRoot -Name "$($resultFile)_NotValidSignature.txt" -Type File | Out-Null

Add-Content  $resultFullName -Value $Folders
$count = 0
Write-Host "Folder for executables created"
New-Item -Path $PSScriptRoot -Name "$($resultFile)_Exe" -ItemType directory | Out-Null
$folderPath = "$PSScriptRoot\$($resultFile)_Exe"
Write-Host "Start processing files"

$apps = Get-ChildItem -Path $Folders -Include '*.exe', '*.dll' -Recurse -Force -File

$CountFolders = 0
if($Apps.Count -eq 0){
    Write-Host "Any executables were found" -BackgroundColor Blue
    Exit
}

Write-Host "Found $($Apps.Count) files"

    $str=''
    foreach ($app in $apps)
    {
        $fullPath = "$($app.Directory)\$($app.Name)"
        if ((Get-AuthenticodeSignature $fullPath).Status -eq 'NotSigned')
        {
            $str = $fullPath
            Add-Content $resultFullName -Value $str    
            $count++
        }

        [float]$folderSize = "{0:N2}" -f ((Get-ChildItem -Path "$PSScriptRoot\$($resultFile)_Exe" | Measure-Object -Property Length -Sum).Sum / 1mb)

        if($folderSize -gt 450){
           Compress-Archive -Path $folderPath -DestinationPath "$($folderPath)_$($CountFolders).zip"
           Remove-Item -Path "$PSScriptRoot\$($resultFile)_Exe\*.*" -Force -Recurse
           $CountFolders++
        }
        Copy-Item -Path $fullPath -Destination $folderPath -Force

    }

Write-Host "End processing Files"

if($CountFolders -eq 0){
    Compress-Archive -Path "$folderPath\*.*" -DestinationPath "$($folderPath).zip"
}

Remove-Item -Path "$PSScriptRoot\$($resultFile)_Exe" -Force -Recurse

If($count -eq 0){
    Write-Host "All files has valid digital signature" -ForegroundColor Green
}
else{
    Write-Host "$count files has not valid digital signature. Please take a look at file $resultFullName" -ForegroundColor Red
}
