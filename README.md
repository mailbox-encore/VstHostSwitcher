# VstHostSwitcher

## Description

The purpose of these sripts is to simplify automatic switching between 32 and 64 bits VST plugins hosts.

If you you have both x86 and x64 version of VST PLugins and you do not always have to open a big DAW to launch them you may already use a VST plugin host line the following ones: (but there are a lot more available)

> - [Tone 2 Nanohost](https://www.tone2.com/nanohost.html)
> - [Image-Line MiniHostModular](https://forum.image-line.com/viewtopic.php?f=1919&t=123031)
> - [Hermannseib vsthost](http://www.hermannseib.com/english/vsthost.htm)

## Scripts file structure

## Customization

As there is not really any standardisation for the VST plugins and host location it is possible to define your own directory structure to store your VST plugins and host locations.
These settings are therefore stored in the ``VstHostSwitcher.ini`` file which must be stored oin the same directory as the previously described scripts.
This ``VstHostSwitcher.ini`` file has the following structure:

Definitions for the x86 and x64 VstPlugin folder paths:

> \[VstPluginFolderPaths\]  
> x86=\[enter your x86 VST plugins path here\]  
> x64=\[enter your x64 VST plugins path here\]  

Notice that if no path is defined, the script will try to get it from the MS Widnwos registry or use the following default values rspectively for the x86 and x64 default VST plugin path location:

> - C:\Program Files (x86)\Steinberg\VstPlugins\
> - C:\Program Files\Steinberg\VstPlugins\
