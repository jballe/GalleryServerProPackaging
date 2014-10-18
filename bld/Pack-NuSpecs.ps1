param(
    [string]$SourcePath,
    [string]$PackagesPath,
    [string]$Counter
)

Write-Host "Configuration:"
Write-Host " SourcePath:  $SourcePath"
Write-Host " Counter:     $Counter"

$versionPath = "ver/version.txt"

$path = Join-Path $SourcePath $versionPath

if((test-path $path) -eq $false) {
    throw "File $path does not exists"
}

$version = Get-Content $path

if($Counter -ne $null) {
    $version += ".$Counter"
}

$packages = Get-ChildItem $PackagesPath -Filter *.nuspec
$count = $packages.Length

Write-Host "Found $count packages"

$batchFile = "$PSScriptRoot\execute.cmd"
Set-Content $batchFile "@echo off" -Encoding Ascii
foreach($nuspec in $packages) {
    $path = join-path $PackagesPath $nuspec
    Write-Host "Building command for $path"
    Add-Content -Path $batchFile -Encoding Ascii "echo Building $nuspec"
    Add-Content -Path $batchFile -Encoding Ascii "nuget pack $path -Version $version"
    Add-Content -Path $batchFile -Encoding Ascii ""
}

Start-Process -NoNewWindow -Wait -FilePath $batchFile