param([string]$ProjectPath = "d:\Priv\Github\GalleryServerPro", [int]$Counter = 0)

function Main {
    $currentDir = $PWD
     cd $ProjectPath

     # Get version
     $Version = [string](git describe --tags)
     $Version = "$Version.$Counter"
     write-host "Version: $Version"

     # Fix packages.config
     Get-ChildItem $ProjectPath -Recurse -Force "packages.config" -ErrorAction Stop | ForEach-Object {
        $Path = $_.FullName
        MarkDependenciesAsDevelopment -Path $Path
     }

     #Build and pack
     BuildProjectWithVersion -Version $Version
     RenameWebConfig
     CopyNuspec -SourceDir $currentDir
     PackProject -Version $Version -OutputDirectory $currentDir

     cd $currentDir
}

function MarkDependenciesAsDevelopment($Path) {
    write-host "Processing $Path..."

    [xml]$xml = Get-Content -Path $Path

    MarkDependencyAsDevelopment -Xml $xml -PackageId "ErikEJ.SqlCeBulkCopy"
    MarkDependencyAsDevelopment -Xml $xml -PackageId "ErikEJ.SqlCeBulkCopy"
    MarkDependencyAsDevelopment -Xml $xml -PackageId "EntityFramework.SqlServerCompact"
    MarkDependencyAsDevelopment -Xml $xml -PackageId "Microsoft.AspNet.Providers.SqlCE"
    MarkDependencyAsDevelopment -Xml $xml -PackageId "Microsoft.SqlServer.Compact"
    MarkDependencyAsDevelopment -Xml $xml -PackageId "SqlServerCompact"
    MarkDependencyAsDevelopment -Xml $xml -PackageId "MSBuildTasks"

    $xml.Save($Path)
}

function MarkDependencyAsDevelopment([System.Xml.XmlDocument]$Xml, [string]$PackageId) {
    $Selector ="/packages/package[@id='$PackageId']"
    $Node = $Xml.SelectSingleNode($Selector)
    If($Node -ne $null) {
        $Node.SetAttribute("developmentDependency", "true")
    }
}

function BuildProjectWithVersion($Version) {
     (nuget restore)

    $Cmd = "c:\Program Files (x86)\MSBuild\12.0\Bin\MSBuild.exe"
    $arg1 = "/nologo"
    $arg2 = "/p:Version=$Version"
    $arg3 = "/p:FileVersion=$Version"
    $arg4 = "/p:BuildConfiguration=Release"
    $file = Join-Path $ProjectPath "Build.proj"

    & $Cmd $arg1 $arg2 $arg3 $arg4 $file
}

function RenameWebConfig {
    $Source = Join-Path $ProjectPath "Website\web.config"
    $Target = Join-Path $ProjectPath "Website\web.config.example"

    if(Test-Path $Source) {
        Rename-Item $Source $Target
    }
}

function CopyNuspec($SourceDir) {
    $Filename = "Website.nuspec"
    $Source = Join-Path $SourceDir $Filename
    $Target = Join-Path $ProjectPath "Website"
    $TargetFile = Join-Path $Target $Filename

    if(Test-Path $TargetFile) {
        Remove-Item $TargetFile
    }

    Copy-Item $Source $Target
}

function PackProject($Version, $OutputDirectory) {
    $Cmd = "nuget"
    $arg1 = "pack"
    $arg2 = "-IncludeReferencedProjects"
    $arg3 = "-ExcludeEmptyDirectories"
    $arg4 = "-Properties"
    $arg5 = "Configuration=Release"
    $arg6 = "-Build"
    $arg7 =  "-Version"
    $arg8 =  "$Version"
    $arg9 = "-NonInteractive"
    $arg10 = "-Symbol"
    $arg11 = "-OutputDirectory"
    $arg12 = "$OutputDirectory"

    $file = Join-Path $ProjectPath "Website\Website.csproj"

    & $Cmd $arg1 $arg2 $arg3 $arg4 $arg5 $arg6 $arg7 $arg8 $arg9 $arg10 $arg11 $arg12 $file
}

Main