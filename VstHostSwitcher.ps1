param(
  [string]$arguments
)

###############################################################################################
# IMPORTANT: the executable deployment location must be hardcoded in the variable below BEFORE
# building the executable  because, at runtime, the current location will be the one of the
# VST .dll or .vst3 file and therfore the .ini file could not be found.
###############################################################################################
#$applicationExePath="Enter the full path to VstSwitcher.exe here please"
$applicationExePath="E:\Hosts\VstHostSwitcher"

# Uncomment the following line to switch to 'debug' mode to test this script 
# withouts having to associate it to a .dll or .vst3 file
#$Debug=$true
if ($Debug) {
  $VerbosePreference = "Continue" 
  if (!$arguments){
    #$arguments = "E:\VstPlugins\discoDSP\Obxd.dll"
    #$arguments = "E:\VstPlugins.x64\AAS\AAS Player.dll"
    $arguments = "E:\VST3.x86\Chromaphone 2.vst3"
    #$arguments = "E:\VST3.x64\ACE(x64).vst3"
  }
  Write-Verbose "arguments=[$arguments]"
  $applicationExePath="C:\Dev\Workspace\VstHostSwitcher"
  if (!(Test-Path $applicationExePath)) {
    # USE current location during development
    $applicationExePath=Get-Location
  }
  Write-Verbose "applicationExePath=[$applicationExePath]"
}

if (!$arguments -or !($arguments.EndsWith(".dll") -or $arguments.EndsWith(".vst3"))) {
  Add-Type -AssemblyName PresentationCore,PresentationFramework
  $ButtonType = [System.Windows.MessageBoxButton]::OK
  $MessageIcon = [System.Windows.MessageBoxImage]::Error
  $MessageBody = "VstHostSwitcher needs a VST .dll or .vst3 file path as argument."
  $MessageTitle = "Error  message"
  $result=[System.Windows.MessageBox]::Show($MessageBody,$MessageTitle,$ButtonType,$MessageIcon)
  Write-Verbose  "result=[$result]"
  Exit
}

# Utility functions to parse .ini files found here:
# https://gallery.technet.microsoft.com/scriptcenter/ea40c1ef-c856-434b-b8fb-ebd7a76e8d91
Function Get-IniContent {  
  [CmdletBinding()]  
  Param(  
      [ValidateNotNullOrEmpty()]  
      [ValidateScript({(Test-Path $_) -and ((Get-Item $_).Extension -eq ".ini")})]  
      [Parameter(ValueFromPipeline=$True,Mandatory=$True)]  
      [string]$FilePath  
  )  
    
  Begin  
      {Write-Verbose "$($MyInvocation.MyCommand.Name):: Function started"}  
        
  Process  
  {  
      Write-Verbose "$($MyInvocation.MyCommand.Name):: Processing file: $Filepath"  
            
      $ini = @{}  
      switch -regex -file $FilePath  
      {  
          "^\[(.+)\]$" # Section  
          {  
              $section = $matches[1]  
              $ini[$section] = @{}  
              $CommentCount = 0  
          }  
          "^(;.*)$" # Comment  
          {  
              if (!($section))  
              {  
                  $section = "No-Section"  
                  $ini[$section] = @{}  
              }  
              $value = $matches[1]  
              $CommentCount = $CommentCount + 1  
              $name = "Comment" + $CommentCount  
              $ini[$section][$name] = $value  
          }   
          "(.+?)\s*=\s*(.*)" # Key  
          {  
              if (!($section))  
              {  
                  $section = "No-Section"  
                  $ini[$section] = @{}  
              }  
              $name,$value = $matches[1..2]  
              $ini[$section][$name] = $value  
          }  
      }  
      Write-Verbose "$($MyInvocation.MyCommand.Name):: Finished Processing file: $FilePath"  
      Return $ini  
  }  
        
  End  
      {Write-Verbose "$($MyInvocation.MyCommand.Name):: Function ended"}  
}

#########################################
# Variables initialisations START....
#########################################
$vstPluginsPath_x86ArrayList= New-Object System.Collections.ArrayList

# 1) Try first to check if there is an ini file with custom entries...
$iniFilePath="$applicationExePath\VstHostSwitcher.ini"
if (Test-Path $iniFilePath) {
  # yes ! use custom definitions
  $vstHostSwitcherIniFile = Get-IniContent  $iniFilePath
 
  # Read ALL defined x86VstPluginFolderPaths and store them in an Arraylist
  $i = 0
  do {
    $i++
    $vstPluginsPath=$vstHostSwitcherIniFile.x86VstPluginFolderPaths["Path$i"]
    if ($vstPluginsPath) { 
      [void]$vstPluginsPath_x86ArrayList.Add($vstPluginsPath)
    }
  } until(!$vstPluginsPath)
  
  # TODO handle the preferredPath variable here
  $preferredPath=$vstHostSwitcherIniFile.VstHostApplicationsPaths.preferredPath
  if (!$preferredPath) {
    $preferredPath=1
  }
  $vstHostApplicationsPaths_x86VST2 = $vstHostSwitcherIniFile.VstHostApplicationsPaths["x86VST2Path$preferredPath"]
  $vstHostApplicationsPaths_x64VST2 = $vstHostSwitcherIniFile.VstHostApplicationsPaths["x64VST2Path$preferredPath"]
  $vstHostApplicationsPaths_x86VST3 = $vstHostSwitcherIniFile.VstHostApplicationsPaths["x86VST3Path$preferredPath"]
  $vstHostApplicationsPaths_x64VST3 = $vstHostSwitcherIniFile.VstHostApplicationsPaths["x64VST3Path$preferredPath"]
}else{
  Write-Error  "Cannot found: $iniFilePath"
}

# 2) Check if variables were defined in the VstHostSwitcher.ini file values 
# => otherwise use default values
# Try to retrieve the x86 VstPlugins path from the registry 
if ($vstPluginsPath_x86ArrayList.Count -eq 0) {
  $vstPluginsPath=(Get-ItemProperty -Path HKLM:\SOFTWARE\Wow6432Node\VST -Name "VSTPluginsPath").VSTPluginsPath
  if ($vstPluginsPath) { 
    $vstPluginsPath_x86ArrayList.add($vstPluginsPath)
  }
}
# use default x86 VstPlugins path if neither defined in the .ini file nor in the registry 
if ($vstPluginsPath_x86ArrayList.Count -eq 0) {
  $vstPluginsPath_x86ArrayList.add("C:\Program Files (x86)\Steinberg\VstPlugins\")
  $vstPluginsPath_x86ArrayList.add("C:\Program Files (x86)\Common Files\VST3\")
}
Write-Verbose "vstPluginsPath_x86=$vstPluginsPath_x86ArrayList"

# Use default values for vstHostApplicationsPaths
if (!$vstHostApplicationsPaths_x86VST2) {
  # No... Use default values if the .ini file is not existing this works ony for me ;o)
  $vstHostApplicationsPaths_x86VST2 ="E:\Hosts\SaviHost\x86\VST2\savihost.exe"
}
Write-Verbose "vstHostApplicationsPaths_x86VST2=$vstHostApplicationsPaths_x86VST2"
if (!$vstHostApplicationsPaths_x64VST2) {
  # No... Use default values if the .ini file is not existing this works ony for me ;o)
  $vstHostApplicationsPaths_x64VST2 ="=E:\Hosts\SaviHost\x64\VST2\savihost.exe"
}
Write-Verbose "vstHostApplicationsPaths_x64VST2=$vstHostApplicationsPaths_x64VST2"

if (!$vstHostApplicationsPaths_x86VST3) {
  # No... Use default values if the .ini file is not existing this works ony for me ;o)
  $vstHostApplicationsPaths_x86VST3 ="E:\Hosts\SaviHost\x86\VST3\savihost.exe"
}
Write-Verbose "vstHostApplicationsPaths_x86VST3=$vstHostApplicationsPaths_x86VST3"
if (!$vstHostApplicationsPaths_x64VST3) {
  # No... Use default values if the .ini file is not existing this works ony for me ;o)
  $vstHostApplicationsPaths_x64VST3 ="=E:\Hosts\SaviHost\x64\VST3\savihost.exe"
}
Write-Verbose "vstHostApplicationsPaths_x64VST3=$vstHostApplicationsPaths_x64VST3"

# Function to check if the script arguments are potentially containing a x86 VST plugin path 
# => otherwise the VST plugin .dll/.vst3 argument will be considered as a x64 one.
function IsX86VstPluginPath(){
    foreach ($vstPluginsPath_x86 in $vstPluginsPath_x86ArrayList){
      if ($arguments.StartsWith($vstPluginsPath_x86, $true, $null)){
        return $true
      }
    }
    return $false
}

# Function to check if the script arguments are potentially containing a .dll plugin path 
# => otherwise the VST plugin argument will be considered as a .vst3 one.
function IsDllPluginPath(){
  if ($arguments.EndsWith(".dll", $true, $null)){
    return $true
  }
  return $false
}


#########################################
# Variables initialisations END....
#########################################

# 3) Do the VST Host application switching work here...
if (IsDllPluginPath) {
  if (IsX86VstPluginPath) {
    Write-Verbose "Launching x86 VST2 host using [$vstHostApplicationsPaths_x86VST2] application."
    & $vstHostApplicationsPaths_x86VST2 $arguments
  }
  else {
    Write-Verbose "Launching v64 VST2 host using [$vstHostApplicationsPaths_x64VST2] application."
    & $vstHostApplicationsPaths_x64VST2 $arguments
  }
}else{
  if (IsX86VstPluginPath) {
    Write-Verbose "Launching x86 VST3 host using [$vstHostApplicationsPaths_x86VST3] application."
    & $vstHostApplicationsPaths_x86VST3 $arguments
  }
  else {
    Write-Verbose "Launching v64 VST3 host using [$vstHostApplicationsPaths_x64VST3] application."
    & $vstHostApplicationsPaths_x64VST3 $arguments
  }
}
