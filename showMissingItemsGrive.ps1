    $sourceFolder = "E:\#FILMS\"
    $destFolder = "G:\Other computers\MINI\#FILMS\"
    $outputDirsLocal="C:\Users\alexr\dirsOnDrive.txt"
    $outputDirsOnGDrive="C:\Users\alexr\dirsOnGDrive.txt"
    $outputDirsMissingOnGDrive="C:\Users\alexr\dirsMissingOnGDrive.txt"
    $output="C:\Users\alexr\notInGoogleDrive.txt"


#Determine which side you are idenmtifying missing files or folders from using the =>s
filter rightside {
param(
        [Parameter(Position=0, Mandatory=$true,ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [PSCustomObject]
        $obj
    )

    $obj|?{$_.sideindicator -eq '<='}

}

#10, 31
#Create two arrays of the folder contents in the source and destination - use the Write-host to determine the lenght of the substring to shave off the root path
$snap3 = [System.IO.Directory]::EnumerateDirectories($sourceFolder, '*', [System.IO.SearchOption]::AllDirectories)  | 
    ForEach-Object { return $_.SubString(10) }
    
  Write-Host $snap3

$snap4 = [System.IO.Directory]::EnumerateDirectories($destFolder, '*', [System.IO.SearchOption]::AllDirectories)  | 
    ForEach-Object { return $_.SubString(31) }
    
  Write-Host $snap4

#Compare the two arrays and send to file a list of the missing folders
 Compare-Object -ReferenceObject $snap3 -DifferenceObject $snap4 | rightside | Select-Object -ExpandProperty 'InputObject'  |  Out-File -FilePath $outputDirsMissingOnGDrive
  
#Create two arrays of the file contents in the source and destination - use the Write-host to determine the lenght of the substring to shave off the root path 10, 31
$snap1 = [System.IO.Directory]::EnumerateFiles($sourceFolder, '*', [System.IO.SearchOption]::AllDirectories) | 
    ForEach-Object { return $_.SubString(10) } 

   write-host $snap1

$snap2 = [System.IO.Directory]::EnumerateFiles($destFolder, '*', [System.IO.SearchOption]::AllDirectories) | 
    ForEach-Object { return $_.SubString(31) } 

   
  write-host $snap2

  #Compare the two arrays and send to file a list of the missing files
   Compare-Object -ReferenceObject $snap1 -DifferenceObject $snap2 | rightside | Select-Object -ExpandProperty 'InputObject'   |  Out-File -FilePath $output