param(
    [string]$arguments
)

# https://stackoverflow.com/questions/43690336/powershell-to-read-single-value-from-simple-ini-file
function Get-IniFile {  
  param(  
      [parameter(Mandatory = $true)] [string] $filePath  
  )  

  $anonymous = "NoSection"
  $ini = @{ }  
  switch -regex -file $filePath {  
      "^\[(.+)\]$" { # Section    
          $section = $matches[1]  
          $ini[$section] = @{ }  
          $CommentCount = 0  
      }  

      "^(;.*)$" { # Comment    
          if (!($section)) {  
              $section = $anonymous  
              $ini[$section] = @{ }  
          }  
          $value = $matches[1]  
          $CommentCount = $CommentCount + 1  
          $name = "Comment" + $CommentCount  
          $ini[$section][$name] = $value  
      }   

      "(.+?)\s*=\s*(.*)" { # Key    
          if (!($section)) {  
              $section = $anonymous  
              $ini[$section] = @{ }  
          }  
          $name, $value = $matches[1..2]  
          $ini[$section][$name] = $value  
      }  
  }  
  return $ini  
}  

$VerbosePreference = "Continue" #"SilentlyContinue"
# for debug only
$Debug=$true
if ($Debug -and !$arguments) {
  #$arguments = "E:\VstPlugins\U-HE\ACE.dll"
   $arguments="E:\VstPlugins.x64\U-HE\ACE(x64).dll"
  #$arguments = "E:\VstPlugins\U-HE\ACE.dlna"
}
Write-Verbose "arguments=$arguments"

# Variables initialisations....
# Try first to check if theer is an ini file with custom entries...
if (Test-Path .\VstHostSwitcher.ini) {
  # yes ! use custom definitions
  $VstHostSwitcherIniFile = Get-IniFile .\VstHostSwitcher.ini
  # TODO handle the preferred path here
  $VstHostApplicationsPaths_x86 = $VstHostSwitcherIniFile.VstHostApplicationsPaths.x86Pathn
  $VstHostApplicationsPaths_x64 = $VstHostSwitcherIniFile.VstHostApplicationsPaths.x64Pathn
  $VSTPluginsPath_x86= $VstHostSwitcherIniFile.VstPluginFolderPaths.x86
  $VSTPluginsPath_x64= $VstHostSwitcherIniFile.VstPluginFolderPaths.x64
}
if (!$VstHostApplicationsPaths_x86) {
  # No... Use default values if the .ini file is not existing this works ony for me ;o)
  $VstHostApplicationsPaths_x86 ="E:\Hosts\Tone2 - NanoHost\NanoHost32bit.exe"
}
if (!$VstHostApplicationsPaths_x64) {
  # No... Use default values if the .ini file is not existing this works ony for me ;o)
  $VstHostApplicationsPaths_x64 ="E:\Hosts\Tone2 - NanoHost\NanoHost64bit.exe"
}
Write-Verbose "VstHostApplicationsPaths_x86=$VstHostApplicationsPaths_x86"
Write-Verbose "VstHostApplicationsPaths_x64=$VstHostApplicationsPaths_x64"

# try to retrieve the x86 VstPlugins path from the registry 
# if it was not defined in the .ini file
if (!$VSTPluginsPath_x86) {
  $VSTPluginsPath_x86 = (Get-ItemProperty -Path HKLM:\SOFTWARE\Wow6432Node\VST -Name "VSTPluginsPath").VSTPluginsPath
}
# use default x86 VstPlugins path if not defined in registry neither
if (!$VSTPluginsPath_x86) {
  $VSTPluginsPath_x86 = "C:\Program Files (x86)\Steinberg\VstPlugins\"
}
Write-Verbose "VSTPluginsPath_x86=$VSTPluginsPath_x86"

# try to retrieve the x64 VST plugins path from the registry 
# if it was not defiend in the .ini file
if (!$VSTPluginsPath_x64) {
  $VSTPluginsPath_x64 = (Get-ItemProperty -Path HKLM:\SOFTWARE\VST -Name "VSTPluginsPath").VSTPluginsPath
}
# use default x64 VstPlugins path if not defined in registry neither
if (!$VSTPluginsPath_x64) {
  $VSTPluginsPath_x64 = "C:\Program Files\Steinberg\VstPlugins\"
}
Write-Verbose "VSTPluginsPath_x64=$VSTPluginsPath_x64"

# do the VST Host application switching work here...
if ($arguments -and $arguments.EndsWith(".dll")) {
  if ($arguments.StartsWith($VSTPluginsPath_x86)) {
    Write-Verbose "Launching x86 VST host using [$VstHostApplicationsPaths_x86] application."
    & $VstHostApplicationsPaths_x86 $arguments
  }
  else {
    Write-Verbose "Launching x64 VST host using [$VstHostApplicationsPaths_x64] application."
    & $VstHostApplicationsPaths_x64 $arguments
  }
}else{
  Write-Error "This scripts need a VST dll file path as argument."
}




