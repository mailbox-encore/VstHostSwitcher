param(
[string]$arguments
)


#Write-Host $arguments
if($arguments.StartsWith("E:\Vstplugins\")) {
  #Write-Host x86
  &'E:\Hosts\Tone2 - NanoHost\NanoHost32bit.exe' $arguments
}else {
  #Write-Host x64
  &'E:\Hosts\Tone2 - NanoHost\NanoHost64bit.exe' $arguments
}