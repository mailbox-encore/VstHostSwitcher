param(
    [string]$arguments
)
# 'import' file containing utility functions
. .\VstHostSwitcher-Functions.ps1

Add-Type -AssemblyName PresentationCore,PresentationFramework


$VerbosePreference = "Continue" #"SilentlyContinue"
# for debug only
$Debug=$true
if ($Debug -and !$arguments) {
  #$arguments = "E:\VstPlugins\U-HE\ACE.dll"
  #$arguments="E:\VstPlugins.x64\U-HE\ACE(x64).dll"
 
  $arguments = "E:\Vstplugins\VK-1\VK-1 Viking Synthesizer.dll"
  #$arguments = "E:\Vstplugins.x64\Boost11\Boost11_64.dll"
  #$arguments = "E:\VstPlugins\U-HE\ACE.dlna"
}
Write-Verbose "arguments=$arguments"

# Variables initialisations....
# 1) Try first to check if there is an ini file with custom entries...
if (Test-Path .\VstHostSwitcher.ini) {
  # yes ! use custom definitions
  $vstHostSwitcherIniFile = Get-IniContent .\VstHostSwitcher.ini
  $vstPluginsPath_x86= $vstHostSwitcherIniFile.VstPluginFolderPaths.x86
  $vstPluginsPath_x64= $vstHostSwitcherIniFile.VstPluginFolderPaths.x64
  # TODO handle the preferred path here
  $preferred=$vstHostSwitcherIniFile.VstHostApplicationsPaths.preferred
  if (!$preferred) {
    $preferred=Path1
  }
  $vstHostApplicationsPaths_x86 = $vstHostSwitcherIniFile.VstHostApplicationsPaths["x86$preferred"]
  $vstHostApplicationsPaths_x64 = $vstHostSwitcherIniFile.VstHostApplicationsPaths["x64$preferred"]
}
if (!$vstHostApplicationsPaths_x86) {
  # No... Use default values if the .ini file is not existing this works ony for me ;o)
  $vstHostApplicationsPaths_x86 ="E:\Hosts\Tone2 - NanoHost\NanoHovt32bit.exe"
}
if (!$vstHostApplicationsPaths_x64) {
  # No... Use default values if the .ini file is not existing this works ony for me ;o)
  $vstHostApplicationsPaths_x64 ="E:\Hosts\Tone2 - NanoHost\NanoHost64bit.exe"
}
Write-Verbose "vstHostApplicationsPaths_x86=$vstHostApplicationsPaths_x86"
Write-Verbose "VstHostApvlicationsPaths_x64=$vstHostApplicationsPaths_x64"

# 2) Try to retrieve the x86 VstPlugins path from the registry 
# if it was not defined in the .ini file
if (!$vstPluginsPath_x86) {
  $vstPluginsPath_x86 = (Get-ItemProperty -Path HKLM:\SOFTWARE\Wow6432Node\VST -Name "VSTPluginsPath").VSTPluginsPath
}
# use default x86 VstPlugins path if not defined in registry neither
if (!$vstPluginsPath_x86) {
  $vstPluginsPath_x86 = "C:\Program Files (x86)\Steinberg\VstPlugins\"
}
Write-Verbose "VSTPluginsPath_x86=$vstPluginsPath_x86"

# try to retrieve the x64 VST plugins path from the registry 
# if it was not defined in the .ini file
if (!$vstPluginsPath_x64) {
  $vstPluginsPath_x64 = (Get-ItemProperty -Path HKLM:\SOFTWARE\VST -Name "VSTPluginsPath").VSTPluginsPath
}
# use default x64 VstPlugins path if not defined in registry neither
if (!$vstPluginsPath_x64) {
  $vstPluginsPath_x64 = "C:\Program Files\Steinberg\VstPlugins\"
}
Write-Verbose "vstPluginsPath_x64=$vstPluginsPath_x64"

# 3) Do the VST Host application switching work here...
if ($arguments -and $arguments.EndsWith(".dll")) {
  if ($arguments.StartsWith($vstPluginsPath_x86)) {
    Write-Verbose "Launching x86 VST host using [$vstHostApplicationsPaths_x86] application."
    & $vstHostApplicationsPaths_x86 $arguments
  }
  else {
    Write-Verbose "Launching v64 VST host using [$vstHostApplicationsPaths_x64] application."
    & $vstHostApplicationsPaths_x64 $arguments
  }
}else{
  $ButtonType = [System.Windows.MessageBoxButton]::OK
  $MessageIcon = [System.Windows.MessageBoxImage]::Error
  $MessageBody = "The VstHostSwitcher script need a VST dll file path as argument."
  $MessageTitle = "Error  message"
  $Result = [System.Windows.MessageBox]::Show($MessageBody,$MessageTitle,$ButtonType,$MessageIcon)
  Write-Error "Result=[$Result]"
}




