param([string]$SolutonPath = "", [string]$TargetFolder = "", [string]$NuspecSkeleton = "")

[System.Collections.ArrayList]$coreFiles = New-Object System.Collections.ArrayList
[System.Collections.ArrayList]$webFiles = New-Object System.Collections.ArrayList
$dependencies = @{}
$contentFiles = @{}


function DoExecute 
{
	ReadPackages

	$dependencies = @{}
	ReadDependencies $coreFiles
	$contentFiles = @{}
	$contentFiles.Add("$SolutionFolder\TIS.GSP.Business\bin\Release\GalleryServerPro.*.dll", "lib/net40")
	MakeNuspec -Id "GalleryServerPro.Core" -Summary "Assemblies with Business Logic for GalleryServerPro" -Description "Use this for extending functionality for GalleryServerPro"


	$dependencies = @{}
	ReadDependencies $webFiles
	$dependencies.Add("GalleryServerPro.Core", "[`$version$]")
	$contentFiles = @{}
	$contentFiles.Add("$SolutionFolder\Website\bin\GalleryServerPro.Web.dll", "lib/net40")
	$contentFiles.Add("$SolutionFolder\Website\App_GlobalResources\**\*.resx", "content\App_GlobalResources")
	$contentFiles.Add("$SolutionFolder\Website\gs\**\*.ascx", "content\gs")
	$contentFiles.Add("$SolutionFolder\Website\gs\**\*.aspx", "content\gs")
	$contentFiles.Add("$SolutionFolder\Website\gs\**\*.ashx", "content\gs")
	$contentFiles.Add("$SolutionFolder\Website\scripts\*.*", "content\scripts")    
	$contentFiles.Add("$SolutionFolder\Website\web.config", "content\web.galeryserverpro.config")  

	MakeNuspec -Id "GalleryServerPro.Web" -Summary "Website for GalleryServerPro" -Description "Use this to create website with GalleryServerPro"
}

function ReadPackages
{
	$projects = Get-ChildItem $SolutionFolder -Directory

	foreach($projectfolder in $projects) {
		$packageFile = $projectfolder.FullName + "\packages.config"
		if(test-path $packageFile) {

			if($webFolders.Contains($projectfolder.Name)) {
				$webFiles.Add($packageFile) | Out-Null
			} else {
				$coreFiles.Add($packageFile) | Out-Null
			}
		}
	}
}

function ReadDependencies([System.Collections.ArrayList]$files) {
	if($files -eq $null) {
		Write-Error "ReadDependencies call with invalid null argument"
		Return
	}

	foreach($file in $files.ToArray()) {
		if (Test-Path -Path $file) 
		{
			ReadDependenciesForFile($file)
		}
	}
}

function MakeNuspec([string]$Id, [string]$Summary, [string]$Description) {

	$path = Join-Path -Path $TargetFolder -ChildPath "$Id.nuspec"

	write-host ""
	write-host "Making nuspec '$path'..."
	write-host ""

	[xml]$nuspec = Get-Content $NuspecSkeleton
	$mgr = New-Object System.Xml.XmlNamespaceManager($nuspec.NameTable)
	$namespace = $nuspec.DocumentElement.NamespaceURI
	$mgr.AddNamespace("ns", $namespace)

	$nuspec.SelectSingleNode("//ns:id", $mgr).InnerText = $Id
	$nuspec.SelectSingleNode("//ns:summary", $mgr).InnerText = $Summary
	$nuspec.SelectSingleNode("//ns:description", $mgr).InnerText = $Description
		
	$dependenciesNode = $nuspec.SelectSingleNode("//ns:dependencies", $mgr)
	foreach($dependencyPackage in $dependencies.Keys) {
		$dependencyVersion = $dependencies[$dependencyPackage]

		$node = $nuspec.CreateElement("", "dependency", $namespace)
			
		$idattr = $nuspec.CreateAttribute("id")
		$versionattr = $nuspec.CreateAttribute("version")
		($idattr.InnerText = $dependencyPackage) | Out-Null
		($versionattr.InnerText = $dependencyVersion) | Out-Null

		$node.Attributes.Append($idattr) | Out-Null
		$node.Attributes.Append($versionattr) | Out-Null

		$dependenciesNode.AppendChild($node) | Out-Null
	}

	if($contentFiles.Count -ne 0) {
		$files = FindOrCreateElement -Doc $nuspec -ParentElementXpath "/ns:package" -ElementName "files"
		foreach($contentFile in $contentFiles.Keys) {
			$target = $contentFiles[$contentFile]

			$node = $nuspec.CreateElement("", "file", $namespace)

			$srcAttr = $nuspec.CreateAttribute("src")
			$targetAttr = $nuspec.CreateAttribute("target")
			($srcAttr.InnerText = $contentFile) | Out-Null
			($targetAttr.InnerText = $target) | Out-Null

			$node.Attributes.Append($srcAttr) | Out-Null
			$node.Attributes.Append($targetAttr) | Out-Null

			$files.AppendChild($node) | Out-Null
		}
	}

	$nuspec.Save($path)
}

function FindOrCreateElement($Doc, $ParentElementXpath, $ElementName) {
	$mgr = New-Object System.Xml.XmlNamespaceManager($doc.NameTable)
	$namespace = $nuspec.DocumentElement.NamespaceURI
	$mgr.AddNamespace("ns", $namespace)
		
	$parent = $doc.SelectSingleNode($ParentElementXpath, $mgr)
	$child = $parent.SelectSingleNode("/ns:$ElementName", $mgr)
	if ($child -eq $null) {
		$child = $doc.CreateElement("", $ElementName, $namespace)
		$parent.AppendChild($child) | Out-Null
	}

	return $child
}


function ReadDependenciesForFile([string] $file) {

	[xml] $doc = Get-Content -Path $file
	$nodes = $doc.SelectNodes("//package")
	Foreach($packageNode in $nodes) {
		[System.Xml.XmlNode] $node = $packageNode
		$packageName = $node.Attributes["id"].Value
		$packageVersion = $node.Attributes["version"].Value
		RegisterDependency -Name $packageName -Version $packageVersion
	}
}

function RegisterDependency([string]$Name, [string]$Version) {
	#Write-Host "Will register dependency for package $Name version $Version ..."

	$existingVersion = $null
	if($dependencies.ContainsKey($Name)) {
		$existingVersion = $dependencies.Get_Item($Name)
	}
	if($existingVersion -eq $null -or $existingVersion -eq "") {
		$dependencies.Remove($Name) | Out-Null
		$existingVersion = $null
	}

	if($existingVersion -ne $null) {
		if($existingVersion -eq $Version) {
			#Write-Host "Already registered..."
			return
		} else {
			#Write-Error "Contains dependency for package $Name with both version $existingVersion and $Version"
			return
		}
	} else {
		$dependencies.Add($Name, $Version) | Out-Null
		$count = $dependencies.Count
		#Write-Host "Registered... Now $count entries"
	}

}

DoExecute