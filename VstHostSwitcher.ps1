param(
    [string]$arguments
)
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

 #$VerbosePreference = "Continue" #"SilentlyContinue"
# for debug only
if (!$arguments) {
     $arguments = "E:\VstPlugins\U-HE\ACE.dll"
    # $arguments="E:\VstPlugins.x64\U-HE\ACE(x64).dll"
}
Write-Verbose $arguments

# For x86 plugins (on 64bit system)
$VSTPluginsPath_x86 = (Get-ItemProperty -Path HKLM:\SOFTWARE\Wow6432Node\VST -Name "VSTPluginsPath").VSTPluginsPath
Write-Verbose $VSTPluginsPath_x86

# For x64 plugins
$VSTPluginsPath_x64 = (Get-ItemProperty -Path HKLM:\SOFTWARE\VST -Name "VSTPluginsPath").VSTPluginsPath
Write-Verbose $VSTPluginsPath_x64


$VstHostSwitcherIniFile = Get-IniFile .\VstHostSwitcher.ini
$VstHostApplicationsPaths_x86 = $VstHostSwitcherIniFile.VstHostApplicationsPaths3.x86
$VstHostApplicationsPaths_x64 = $VstHostSwitcherIniFile.VstHostApplicationsPaths3.x64

if ($arguments) {
    if ($arguments.StartsWith($VSTPluginsPath_x86)) {
        Write-Verbose "Launching x86 VST host using:  $VstHostApplicationsPaths_x86"
        & $VstHostApplicationsPaths_x86 $arguments
    }
    else {
        Write-Verbose "Launching x64 VST host using:  $VstHostApplicationsPaths_x64"
        & $VstHostApplicationsPaths_x64 $arguments
    }
}else{
  Write-Error "This scripts need an argument."
}




