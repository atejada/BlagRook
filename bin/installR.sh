#!/bin/bash
 
# NOTE: Heroku Cedar Stack
#  gcc needs to be 4.3
 
# See http://cran.r-project.org/doc/manuals/R-admin.html for details on building R
 
## HELPERS
 
function download() {
  if [ ! -f "$2" ]; then
    echo Downloading $2...
    curl $1 -o $2
  else
    echo Got $2...
  fi
}
 
function build() {
  echo ----------------------------------------------------------------------
  echo Building $@...
  echo ----------------------------------------------------------------------
  echo
  pushd $1
    ./configure --prefix=$vendordir/$2 ${@:3} && make && make install && make clean
  popd > /dev/null
  echo
  echo
 
  # add to libraries and pkg-config
  export LD_LIBRARY_PATH="$vendordir/$2:$LD_LIBRARY_PATH"
  export PKG_CONFIG_PATH="$vendordir/$2/lib/pkgconfig:$PKG_CONFIG_PATH"
 
}
 
## SCRIPT
 
set -e
 
r_version="${1:-2.13.1}"
r_version_major=${r_version:0:1}
 
if [ -z "$r_version" ]; then
  echo "USAGE: $0 VERSION"
  exit 1
fi
 
basedir="$( cd -P "$( dirname "$0" )" && pwd )"
 
# create output directory
vendordir=/app/vendor
mkdir -p $vendordir
 
echo ======================================================================
echo Downloading and unpacking dependancies...
echo ======================================================================

# We need to install xz to be able to unzip the gcc package we're going to download in a minute
curl http://gfortran.com/download/x86_64/xz.tar.gz -o xz.tar.gz
tar xzvf xz.tar.gz 

# Get and unpack gcc-4.3 binary, including gfortran
curl http://gfortran.com/download/x86_64/snapshots/gcc-4.3.tar.xz -o gcc-4.3.tar.xz
./usr/bin/unxz gcc-4.3.tar.xz 
tar xvf gcc-4.3.tar 
 
# http://www.freetype.org/freetype2/
freetype_version=2.5.0
download http://www.mirrorservice.org/sites/download.savannah.gnu.org/releases/freetype/freetype-$freetype_version.tar.gz freetype-$freetype_version.tar.gz
tar xzf freetype-$freetype_version.tar.gz
 
# http://directfb.org/
directfb_version=1.2.9
directfb_ver_major=${directfb_version:0:3}
download http://directfb.org/downloads/Core/DirectFB-$directfb_ver_major/DirectFB-$directfb_version.tar.gz DirectFB-$directfb_version.tar.gz
tar xzf DirectFB-$directfb_version.tar.gz
 
# http://www.libpng.org/pub/png/libpng.html
libpng_version=1.2.50
download ftp://ftp.simplesystems.org/pub/libpng/png/src/libpng12/libpng-$libpng_version.tar.gz libpng-$libpng_version.tar.gz
tar xzf libpng-$libpng_version.tar.gz
 
# http://www.cairographics.org
pixman_version=0.29.4
download http://www.cairographics.org/snapshots/pixman-$pixman_version.tar.gz pixman-$pixman_version.tar.gz
tar xzf $basedir/pixman-$pixman_version.tar.gz
 
# http://www.freedesktop.org/software/fontconfig
fontconfig_version=2.9.0
download http://www.freedesktop.org/software/fontconfig/release/fontconfig-$fontconfig_version.tar.gz fontconfig-$fontconfig_version.tar.gz
tar xzf $basedir/fontconfig-$fontconfig_version.tar.gz
 
# http://www.cairographics.org
cairo_version=1.9.14
download http://www.cairographics.org/snapshots/cairo-$cairo_version.tar.gz cairo-$cairo_version.tar.gz
tar xzf $basedir/cairo-$cairo_version.tar.gz
 
# http://www.pango.org
#pango_ver=1.35
#pango_version=$pango_ver.0
#download http://ftp.gnome.org/pub/GNOME/sources/pango/$pango_ver/pango-$pango_version.tar.xz pango-$pango_version.tar.xz
#tar xJf $basedir/pango-$pango_version.tar.xz
 
# R
download http://cran.r-project.org/src/base/R-$r_version_major/R-$r_version.tar.gz R-$r_version.tar.gz
tar xzf R-$r_version.tar.gz
 
# http://gcc.gnu.org/wiki/GFortran
gcc_version=4.3
download http://gfortran.com/download/x86_64/snapshots/gcc-$gcc_version.tar.xz gcc-$gcc_version.tar.xz
tar xJf $basedir/gcc-$gcc_version.tar.xz -C $vendordir
 
# patch gcc features.h file
# see http://permalink.gmane.org/gmane.comp.gcc.help/40166
mkdir -p $vendordir/gcc-$gcc_version/lib/gcc/x86_64-unknown-linux-gnu/$gcc_version/include-fixed
cp $basedir/features.h $vendordir/gcc-$gcc_version/lib/gcc/x86_64-unknown-linux-gnu/$gcc_version/include-fixed/features.h
 
# https://www.gnu.org/software/libc/
glibc_version=2.7
glibc_version_x=2.7ds1
download ftp://ftp.gunadarma.ac.id/linux/debian/pool/main/g/glibc/glibc_2.7.orig.tar.gz glibc_$glibc_version.tar.gz
tar xzf $basedir/glibc_$glibc_version.tar.gz -C $vendordir
tar xjf $vendordir/glibc-$glibc_version/glibc-$glibc_version_x.tar.bz2 -C $vendordir
 
echo ============================================================
echo Building dependencies...
echo ======================================================================
 
build "$basedir/freetype-$freetype_version" freetype
build "$basedir/DirectFB-$directfb_version" DirectFB
build "$basedir/libpng-$libpng_version" libpng
build "$basedir/pixman-$pixman_version" pixman
build "$basedir/fontconfig-$fontconfig_version" fontconfig
build "$basedir/cairo-$cairo_version" cairo
 
# copy over missing header files
cp $basedir/cairo-$cairo_version/src/*.h $vendordir/cairo/include
 
#build $basedir/pango-$pango_version pango
 
# build R
echo ============================================================
echo Building R
echo ============================================================
cd $basedir/R-$r_version/
 
export LDFLAGS="-L$vendordir/gcc-$gcc_version/lib64"
export CPPFLAGS="-I$vendordir/glibc-$glibc_version/string/ -I$vendordir/glibc-$glibc_version/time"
export PATH="$vendordir/gcc-$gcc_version/bin:$PATH"
 
echo ----------------------------------------------------------------------
echo LD_LIBRARY_PATH=$LD_LIBRARY_PATH
echo PKG_CONFIG_PATH=$PKG_CONFIG_PATH
echo ----------------------------------------------------------------------
 
./configure --prefix=$vendordir/R --enable-R-shlib --with-readline=no --with-x=yes
make

cd /app/bin
#ln -s R-2.15-1/bin/R
ln -s R-2.13.1/bin/R 

rm gcc-4.3.tar 
rm glibc_2.7.orig.tar.gz 
rm R.tar.gz 
rm xz.tar.gz 
rm -rf usr/
rm -rf gcc-4.3/bin
rm -rf gcc-4.3/lib
rm -rf gcc-4.3/libexec
rm -rf gcc-4.3/info
rm -rf gcc-4.3/man
rm -rf gcc-4.3/share
rm -rf gcc-4.3/include

rm glibc-2.7/*.tar.bz 
cd bin/glibc-2.7/
rm -rf abilist/ abi-tags aclocal.m4  argp assert/ b* BUGS  C* c* d* e* F* g* h* i* I* l* m* M* N* aout/ LICENSES  n* o* p* P* R* r* scripts/ setjmp/ shadow/ shlib-versions signal/ socket/ soft-fp/ stdio-common/ stdlib/ streams/ sunrpc/ sysdeps/ sysvipc/ termios/ test-skeleton.c timezone tls.make.c version.h Versions.def wcsmbs/ wctype/ WUR-REPORT 

cd ../R-2.13.1
rm -rf src
rm Make*
rm -rf doc
rm NEWS*
rm -rf test
rm config*
rm O* README ChangeLog COPYING INSTALL SVN-REVISION VERSION
NEED etc