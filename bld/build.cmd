@echo off
SET GspPath=%CD%\GalleryServerPro
SET PackagingPath=%CD%\GalleryServerProPackaging
Set StartPath=%CD%

cd %GspPath%
for /f %%i in ('git tag') do set Version=%%i
echo Version: %Version%

IF "%msbuild%"=="" THEN SET msbuild=%ProgramFiles(x86)%\MsBuild\12.0\Bin\MSBuild.exe

:VERSION
SET GspDeploy=%GspPath%\Build.proj
CALL "%msbuild%" %GspDeploy% /t:Version /p:Configuration=Release /p:BUILD_NUMBER=%Version% /nologo

:COMPILE
SET Solution=%GspPath%\TIS.GSP.sln
SET DeployProfile=%PackagingPath%\bld\publishprofile.pubxml

echo compile solution %Solution% using publishing profile %DeployProfile%
CALL "%msbuild%" %Solution% /p:Configuration=Release /p:DeployOnBuild=true /p:PublishProfile=%DeployProfile%

:EXIT
echo Done!
CD %StartPath%