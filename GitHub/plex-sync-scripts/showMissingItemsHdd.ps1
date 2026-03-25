
    $sourceFolder = "G:\Other computers\MINI\#FILMS\"
    $destFolder = "E:\#FILMS\"
    $output="C:\Users\alexr\notOnHdd.txt"

    $outputDirsLocal="C:\Users\alexr\dirsOnDrive.txt"
    $outputDirsOnGDrive="C:\Users\alexr\dirsOnGDrive.txt"
    $outputDirsMissingOnHDD="C:\Users\alexr\dirsMissingOnHDD.txt"


filter rightside {
param(
        [Parameter(Position=0, Mandatory=$true,ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [PSCustomObject]
        $obj
    )

    $obj|?{$_.sideindicator -eq '<='}

}

#Create two arrays of the folder contents in the source and destination - use the Write-host to determine the lenght of the substring to shave off the root path
$snap3 = [System.IO.Directory]::EnumerateDirectories($sourceFolder, '*', [System.IO.SearchOption]::AllDirectories)  | 
    ForEach-Object { return $_.SubString(31) }
    
  #Write-Host $snap3

$snap4 = [System.IO.Directory]::EnumerateDirectories($destFolder, '*', [System.IO.SearchOption]::AllDirectories)  | 
    ForEach-Object { return $_.SubString(10) }
    
  #Write-Host $snap4

  Compare-Object -ReferenceObject $snap3 -DifferenceObject $snap4 | rightside | Select-Object -ExpandProperty 'InputObject' |  Out-File -FilePath $outputDirsMissingOnHDD

         
$snap1 = [System.IO.Directory]::EnumerateFiles($sourceFolder, '*', [System.IO.SearchOption]::AllDirectories)  | 
    ForEach-Object { return $_.SubString(31) }

$snap2 = [System.IO.Directory]::EnumerateFiles($destFolder, '*', [System.IO.SearchOption]::AllDirectories)  | 
    ForEach-Object { return $_.SubString(10) } 

    Compare-Object -ReferenceObject $snap1 -DifferenceObject $snap2 | rightside | Select-Object -ExpandProperty 'InputObject'  |  Out-File -FilePath $output