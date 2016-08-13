
WinLIRC plug-in for jetAudio
============================

WinLIRC plug-in for jetAudio (internally `jflirc`) is, as its name suggests, a plug-in for the Windows [jetAudio](http://www.cowonamerica.com/products/jetaudio/) media player that makes it possible to control jetAudio with a remote controller via the [WinLIRC protocol](http://winlirc.sourceforge.net/). This repository contains the Delphi 4 source code of the plug-in.

Obtaining the Source Code
-------------------------

First make sure that you have the [Git client](https://git-scm.com/) (`git`) installed. Then open a Windows command prompt window (Git Bash isn't supported). In command prompt, run these commands:
```
> git clone https://github.com/tdebaets/jflirc.git jflirc
> cd jflirc
```

Finally, run the `postclone.bat` script. This will take care of further setting up the repository, installing Git hooks, creating output directories etc.:
```
> postclone.bat
```

To keep your clone updated, run the `update.bat` script. This script essentially runs a `git pull` but also performs some basic checks before pulling. It also runs a `git submodule update` after the pull to keep the `common`submodule up-to-date.

If you want to contribute to this project, don't clone its main repository, but create your own fork first and clone that fork instead. Then commit your work on a topic branch and submit a pull request. For details, see the [generic instructions for contributing to projects](https://github.com/tdebaets/common/blob/master/CONTRIBUTING.md) in `common`.
