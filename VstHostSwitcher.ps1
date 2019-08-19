param(
  [string]$arguments
)

#############################################################################################
# IMPORTANT: the executable deployment location must be hardcode in the variable below BEFORE
# building the executable  because, at runtime, the current location will be the one of the
# VST .dll file and therfore the .ini file could not be found.
#############################################################################################
$applicationExePath="Enter the full path to VstSwitcher.exe here please"

# Uncomment the following line to debug 
#$Debug=$true
if ($Debug -and !$arguments) {
  $VerbosePreference = "Continue" 
  #$arguments = "E:\VstPlugins\U-HE\ACE.dll"
  #$arguments="E:\VstPlugins.x64\U-HE\ACE(x64).dll"
 
 #$arguments = "E:\Vstplugins\VK-1\VK-1 Viking Synthesizer.dll"
  #$arguments = "E:\Vstplugins.x64\Boost11\Boost11_64.dll"
  #$arguments = "E:\VstPlugins\U-HE\ACE.dlna"
  $applicationExePath="E:\Hosts\VstHostSwitcher"
  if (!(Test-Path $applicationExePath)) {
    # USE current location during development
    $applicationExePath=Get-Location
  }
  Write-Verbose "applicationExePath=[$applicationExePath]"
  Write-Verbose "arguments=[$arguments]"
}

if (!$arguments -or !$arguments.EndsWith(".dll")) {
  Add-Type -AssemblyName PresentationCore,PresentationFramework
  $ButtonType = [System.Windows.MessageBoxButton]::OK
  $MessageIcon = [System.Windows.MessageBoxImage]::Error
  $MessageBody = "VstHostSwitcher needs a VST .dll file path as argument."
  $MessageTitle = "Error  message"
  $result=[System.Windows.MessageBox]::Show($MessageBody,$MessageTitle,$ButtonType,$MessageIcon)
  Write-Verbose  "result=[$result]"
  Exit
}

# Utility functions to parse .ini  files
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



# Variables initialisations....
# 1) Try first to check if there is an ini file with custom entries...
$iniFilePath="$applicationExePath\VstHostSwitcher.ini"
if (Test-Path $iniFilePath) {
  # yes ! use custom definitions
  $vstHostSwitcherIniFile = Get-IniContent  $iniFilePath
  $vstPluginsPath_x86= $vstHostSwitcherIniFile.VstPluginFolderPaths.x86
  $vstPluginsPath_x64= $vstHostSwitcherIniFile.VstPluginFolderPaths.x64
  # TODO handle the preferred path here
  $preferred=$vstHostSwitcherIniFile.VstHostApplicationsPaths.preferred
  if (!$preferred) {
    $preferred=Path1
  }
  $vstHostApplicationsPaths_x86 = $vstHostSwitcherIniFile.VstHostApplicationsPaths["x86$preferred"]
  $vstHostApplicationsPaths_x64 = $vstHostSwitcherIniFile.VstHostApplicationsPaths["x64$preferred"]
}else{
  Write-Error  "Cannot found: $iniFilePath"
}
if (!$vstHostApplicationsPaths_x86) {
  # No... Use default values if the .ini file is not existing this works ony for me ;o)
  $vstHostApplicationsPaths_x86 ="E:\Hosts\Tone2 - NanoHost\NanoHost32bit.exe"
}
if (!$vstHostApplicationsPaths_x64) {
  # No... Use default values if the .ini file is not existing this works ony for me ;o)
  $vstHostApplicationsPaths_x64 ="E:\Hosts\Tone2 - NanoHost\NanoHost64bit.exe"
}
Write-Verbose "vstHostApplicationsPaths_x86=$vstHostApplicationsPaths_x86"
Write-Verbose "vstHostApplicationsPaths_x64=$vstHostApplicationsPaths_x64"

# 2) Try to retrieve the x86 VstPlugins path from the registry 
# if it was not defined in the .ini file
if (!$vstPluginsPath_x86) {
  $vstPluginsPath_x86 = (Get-ItemProperty -Path HKLM:\SOFTWARE\Wow6432Node\VST -Name "VSTPluginsPath").VSTPluginsPath
}
# use default x86 VstPlugins path if not defined in registry neither
if (!$vstPluginsPath_x86) {
  $vstPluginsPath_x86 = "C:\Program Files (x86)\Steinberg\VstPlugins\"
}
Write-Verbose "vstPluginsPath_x86=$vstPluginsPath_x86"

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
if ($arguments.StartsWith($vstPluginsPath_x86)) {
  Write-Verbose "Launching x86 VST host using [$vstHostApplicationsPaths_x86] application."
  & $vstHostApplicationsPaths_x86 $arguments
}
else {
  Write-Verbose "Launching v64 VST host using [$vstHostApplicationsPaths_x64] application."
  & $vstHostApplicationsPaths_x64 $arguments
}
