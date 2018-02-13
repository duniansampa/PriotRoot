#!/bin/bash
# Installs Qt from source code (current version: 5.9.1).
 
# Dependencies
: <<'END'
http://doc.qt.io/qt-5/linux-requirements.html
http://doc.qt.io/qt-5/qtwebengine-platform-notes.html
END
 
INSTALLDIR=$HOME/Qt/Qt5.9.1/5.9/gcc
PATH="$INSTALLDIR/bin":$PATH
export PATH
 
BINDIR=$HOME/
BINFILE=qt-everywhere-opensource-src-5.9.1.tar.xz
BINPATH=$BINDIR$BINFILE
BINFILETARFOLDER=qt-everywhere-opensource-src-5.9.1
SHADOWBUILDDIR=$HOME/tmp/
SHADOWBUILDPATH="$SHADOWBUILDDIR$BINFILETARFOLDER"
SOURCEDIR=$HOME/src/
SOURCEFOLDER=qt-everywhere-opensource-src-5.9.1/
SOURCEPATH="$SOURCEDIR$SOURCEFOLDER"
SYSTEMLIB=/usr/lib
HARDWARETHREADS=$1
 
echo -n "It's recommended to extract the source files to $SOURCEPATH. Do you wish to continue?(y/n): "
read READY
if [ $READY == "y" ]; then
if [ -d "$SOURCEPATH" ]; then
    echo "Removing folder $SOURCEPATH..."
    rm -R "$SOURCEPATH"
fi
    echo -n "Recreating folder $SOURCEPATH..."
    mkdir -p "$SOURCEPATH"
    echo "done."
    cd "$SOURCEDIR"
    echo "Ready to start source code file extraction to $SOURCEPATH. Press ENTER to continue."
    read READY
    tar -xvf "$BINPATH"
    echo "Source code file extraction done"
else
    echo "Source code extraction skipped"
fi
 
echo -n "It's recommended to install the dependencies for Qt build. Do you wish to continue?(y/n): "
read READY
if [ $READY == "y" ]; then
    yum update -y
    yum groupinstall -y "Development Tools"
    yum groupinstall -y "GNOME Desktop"
    yum install -y mesa-libGL* mesa-libEGL* mercurial autoconf213 glibc-static libstdc++-static

    # There is no epel-release 32-bit version. Improvising from alternative sources.
    yum install -y https://buildlogs.centos.org/c7-epel/yasm/20160811005924/1.2.0-4.el7.i686/yasm-1.2.0-4.el7.i686.rpm

    yum install -y libXt-* gstreamer* pulseaudio-libs-devel pulseaudio-libs-glib2 alsa-lib-devel openssl openssl-libs fontconfig-devel freetype-devel libX11-devel libXext-devel libXfixes-devel libXi-devel libXrender-devel libxcb-devel libxcb xcb-util xcb-util-keysyms-devel xcb-util-image-devel xcb-util-wm
 
    # There is no epel-release 32-bit version. Improvising from alternative sources.
    yum install -y https://buildlogs.centos.org/c7-epel/gyp/20160817130211/0.1-0.11.1617svn.el7.i686/gyp-0.1-0.11.1617svn.el7.noarch.rpm
 
    yum install -y GConf2 gperf libcap-devel GConf2-devel libgcrypt-devel libgnome-keyring-devel nss-devel libpciaccess pciutils-devel gvncpulse-devel libgudev1-devel systemd-devel libXtst-devel pygtk2-devel openssl-devel libXcursor-devel libXcomposite-devel libXdamage-devel libXrandr-devel bzip2-devel libdrm-devel flex-devel bison-devel libXScrnSaver-devel atkmm-devel libicu-devel libxslt-devel
    echo "Finished installing Qt build dependencies"
else
    echo "Qt build dependencies skipped"
fi
 
echo -n "Press ENTER if you want to configure the build in $SHADOWBUILDPATH: "
read READY
echo "Wait..."
 
# Shadow build.
# https://wiki.qt.io/Qt_shadow_builds
if [ -d "$SHADOWBUILDPATH" ]; then
    rm -fR "$SHADOWBUILDPATH"
fi
 
mkdir -p "$SHADOWBUILDPATH"
cd "$SHADOWBUILDPATH"
 
# Other parameters:
# -developer-build
# -force-debug-info
"$SOURCEPATH/configure" -v -release -nomake examples -nomake tests -opensource -confirm-license -gstreamer -icu -qt-xcb -alsa -no-opengl -prefix $INSTALLDIR > Configure.log 2>&1
 
echo -n "Done. Finished configuring Qt for build phase. Press ENTER if you want to start the build in $SHADOWBUILDPATH: "
read READY
 
echo "Wait..."
make -j$HARDWARETHREADS > Make.log 2>&1
 
echo -n "Done. Finished building Qt. Press ENTER if you want to install: "
read READY
 
# Check INSTALLDIR: you may require sudo to 'make install'.
echo "Wait..."
make install > MakeInstall.log 2>&1

cp *.log $INSTALLDIR
cp *.sh $INSTALLDIR

cp $SYSTEMLIB/libicu* $INSTALLDIR/lib
# Making a copy of the resource files to the gcc folder, like the Qt5.5.1 distribution.
# This will avoid breaking the build configurations in TeamCity (NpWebView).
cp $INSTALLDIR/resources/*.* $INSTALLDIR/
 
echo -n "Done. Qt install complete. Do you want to clean (delete) the temporary build files?(y/n): "
read READY
if [ $READY == "y" ]; then
    echo "Wait..."
    rm -R "$SHADOWBUILDPATH"
    echo -n "Done. "
fi
 
echo -n "Do you want to delete the source code files?(y/n): "
read READY
if [ $READY == "y" ]; then
    echo "Wait..."
    rm -R "$SOURCEPATH"
else
    echo "Finished deleting the source code files."
fi
echo "Done. Qt has been installed."
