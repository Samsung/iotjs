### Overall steps to build for Linux
1. Get the sources
2. Set build options
3. Build all at once

***

#### Build Host
Ubuntu 14.04 is recommended. Other Unix like platforms can be used. If it doesn't seem to work properly on other platforms, please look into [Issues](https://github.com/Samsung/iotjs/issues). Someone may have already tried. If you can't find any related one, please leave an issue for help.

#### Directory structure

This document assumes 'harmony' as the root directory. _JerryScript_, _libtuv_ and _libuv_ are included as sub-modules in deps folder.

* harmony
    * iotjs
        * deps
            * http-parser
            * jerry
            * libuv
            * libtuv


※ harmony? It's from initial code name of our project. (_Sounds good, isn't it? :)_)

#### Prerequisite

You need to install some packages to build IoT.js, as follows;

```
sudo apt-get install gyp cmake build-essential
```

gcc/g++ compiler 4.8 and upper versions are required to compile. If you have any problems upgrading to 4.8, please google. One of those helped me is [how-to-install-gcc-4-8](http://askubuntu.com/questions/271388/how-to-install-gcc-4-8).

### 1. Get the sources

Clone our repository to look around and test it. If it attracts you and want to try something interests, please fork it.

To get the source for this repository, 
```
cd harmony
git clone https://github.com/Samsung/iotjs.git
cd iotjs
```

Sub modules(_http-parser_, _JerryScript_, _libuv_ and _libtuv_) will be pulled. And matching hash will be checked out for your current IoT.js version when you run the build script.


### 2. Set build options

Some basic options are provided.

Existing build options are listed as follows;
```
buildtype=debug|release (debug is default)
builddir=build (build is default)
clean
buildlib (default is False)
target-arch=x86|x86_64|x64|i686|arm (depends on your host platform)
target-os=linux|nuttx|darwin|osx (linux is default)
target-board
cmake-param
compile-flag
link_flag
external-include-dir
external-static-lib
external-shared-lib
jerry-cmake-param
jerry-compile-flag
jerry-link-flag
jerry-lto
jerry-heap-section
jerry-heaplimit (default is 81, may change)
jerry-memstat (default is False)
no-init-submodule (default is init)
no-check-tidy (default is check)
no-check-test (default is check)
no-parallel-build
no-snapshot
nuttx-home= (no default value)
```

To give options, please use two dashes '--' before the option name as described in following sections.

Options that may need explanations.
* builddir: compile intermediate and output files are generated here.
* buildlib: generating _iotjs_ to a library if True(e.g. for NuttX). give __--buildlib__ to make it True.
* init-submodule: for normal cases you can ignore this, it will checkout matching revision of each sub-module library every time. but if you want to change something or checkout other revision, use __--no-init-submodule__.
* jerry-heaplimit: JerryScript default heap size (as of today) is 256Kbytes. This option is to change the size for embedded systems, nuttx for now, and current default is 81KB. For linux, this has no effect. While building nuttx if you see an error `region sram overflowed by xxxx bytes`, you may have to decrease about that amount.
* jerry-memstats: turn on the flag so that jerry dumps byte codes and literals and memory usage while parsing and execution.
* no-check-tidy: no checks codes are tidy. we recommend to check tidy.
* no-check-test: do not run all tests in test folder after build.
* nuttx-home: it's NuttX platform specific, to tell where the NuttX configuration and header files are.

If you want to more detail about options, please check [Build Script](https://github.com/Samsung/iotjs/wiki/Build%20Script).


### 3. Build all at once

IoT.js and required sub-modules are generated all at once in tools folder with build.py.

```
cd iotjs
./tools/build.py
```

#### Options example

It's a good practice to build in separate folder, like 'build'. IoT.js generates all outputs into separate **'build'** folder. You can change this by --builddir option. Usually you won't need to use this option. Target and architecture name are used as a name for a folder inside 'build' folder.

To build debug version and results to 'output' folder
```
./tools/build.py --builddir=output
```

If you want to build 32bit version in x86_64 and debug version only produce a library,
```
./tools/build.py --target-arch=i686 --buildlib
```

To build release version and with different jerry revision. assume you have already checked it out.
```
./tools/build.py --buildtype=release --no-init-submodule
```



#### Build only IoT.js with given build option

This section for explaining how to build only IoT.js when you did some modification. IoT.js uses [CMake](http://www.cmake.org/) for makefile generation. You can go inside the build folder and build with 'make' command. Go inside where your target platform name is, for example x86_64 linux,
```
cd build/x86_64-linux/release/iotjs
make
```

#### How to execute?

Executable name is **'iotjs'** and resides in (target-arch)-(target-os)/(buildtype)/iotjs. 
To run greetings JavaScript in test folder, for example;

```
./build/x86_64-linux/debug/iotjs/iotjs ./test/run_pass/test_console.js
```

#### What build script does

1. It will clone sub-modules, this will be done only once when version hash has not changed.
2. Checkout matching version for each sub-modules.
3. Build sub-modules, you can see the outputs at build/(target-arch)-(target-os)/(buildtype)/libs folder.
4. Build IoT.js


#### How to clean

Just remove the folder as follows;
```
rm -rf build
rm -rf deps/libuv/out
```
