#!/bin/sh
product=mpgedit_sdk_0-75dev2
install_root=/usr/local/mpgedit_sdk
extension_dir="$install_root/py_mpgedit-0.3beta"

include="decoder.h  editif.h  header.h  mp3time.h  mpegindx.h
         mpegstat.h  playif.h  portability.h  volumeif.h  xing_header.h"

lib="libmpgedit.so libdecoder_mpg123.so libdecoder_mad.so
     libdecoder_popen.so libmpglib_mpgedit.so"

examples="test_pympgedit.py simple_play.py simple_edit.py test1.mp3"
contribdir="contrib/python/py_mpgedit"
examples_contrib="$contribdir/test_pympgedit.py \
                  $contribdir/simple_play.py \
                  $contribdir/simple_edit.py \
                  test1.mp3"

py_mpgedit="pympgedit.py"
py_mpgedit_contrib="$contribdir/pympgedit.py"

Y_FLAG=NO
U_FLAG=NO

python_uninstall()
{
  python_packages=`python -c 'import sys; j = [ i for i in sys.path if i.endswith("site-packages")]; print j[0]'`

  for f in $py_mpgedit; do
    rm -f ${python_packages}/${f}
    rm -f ${python_packages}/${f}c
  done
}


python_install()
{
  if [ `python -c 'import ctypes' 2>&1 | grep -c ImportError` -gt 0 ]; then
    echo "Error: pympgedit requires the ctypes module for proper operation."
    echo         "Details about this package, and its installation are availabe from:"
    echo         "  http://python.net/crew/theller/ctypes/"
    exit 1
  fi
  python_packages=`python -c 'import sys; j = [ i for i in sys.path if i.endswith("site-packages")]; print j[0]'`

  if [ -d "$python_packages" ]; then
    [ -d $contribdir ]  && cp $py_mpgedit_contrib $python_packages
    [ ! -d $contribdir ]  && cp $py_mpgedit $python_packages
  else
    echo  =======
    echo "WARNING: Unable to determine python site-packages directory"
    echo "You must install the python extension yourself"
    echo  =======
  fi

  echo "Installing extension sources in '$extension_dir'"
  install -d $extension_dir
  [ -d "$contribdir" ]   && install $py_mpgedit_contrib $extension_dir
  [ ! -d "$contribdir" ] && install $py_mpgedit $extension_dir
}


do_install()
{
  get_install_root
  extension_dir="$install_root/py_mpgedit-0.3beta"
  if [ -d "$install_root" ]; then
    echo "Install directory '$install_root' already exists."
    echo "Do you want to continue?"
    read line
    line=`echo $line | tr '[A-Z]' '[a-z]'`
    if [ "$line" = "n" -o "$line" = "no" ]; then
      exit 1
    fi
  fi
  python_install

  echo "Installing '$product' in '$install_root'"
  install -d $install_root/include/mpgedit_sdk
  install -d $install_root/lib
  install -d $install_root/examples

  echo "Installing shared libraries ($install_root/lib)..."
  install $lib $install_root/lib

  echo "Installing header files ($install_root/include/mpgedit_sdk)..."
  install $include $install_root/include/mpgedit_sdk

  echo "Installing example files ($install_root/examples)..."

  [ ! -d "$contribdir" ] && install $examples $install_root/examples
  [ -d "$contribdir" ]   && install $examples_contrib $install_root/examples

  rm -f $install_root/lib/libmpgedit_decoder.so
  ln -s $install_root/lib/libdecoder_mpg123.so \
        $install_root/lib/libmpgedit_decoder.so

  if [ -f "/etc/ld.so.conf" ]; then
    line=`grep $install_root/lib /etc/ld.so.conf`
    if [ -z "$line" ]; then

      # Short-circuit interactive question if -y provided on command line
      #
      if [ $Y_FLAG = "NO" ]; then
        echo
        echo "$install_root/lib not found in /etc/ld.so.conf"
        echo "This is needed for proper operation of mpgedit"
        echo
        echo -n "  Do you want to add this now? [Y/n] "
        read line
        line=`echo $line | tr '[A-Z]' '[a-z]'`
      else
        line=$Y_FLAG
      fi
      if [ "$line" != "n" -a "$line" != "no" ]; then
        echo "updating /etc/ld.so.conf..."
        echo "$install_root/lib" >> /etc/ld.so.conf
      fi
    fi
     # Always run ldconfig, even if install path was previously in ld.so.conf,
     # because this install may have added new libraries not previously in
     # the library cache.
    /sbin/ldconfig
  fi

  echo "Finished installing '$product'"
  echo
}


do_uninstall()
{
  get_install_root "un"
  if [ ! -d "$install_root" ]; then
    echo "ERROR: uninstall directory does not exist"
    exit 1
  fi
  extension_dir="$install_root/py_mpgedit-0.3beta"

  echo "Uninstalling '$product' in '$install_root'"

  # Remove the extension from the Python site-packages directory
  #
  python_uninstall

  for i in $lib; do
    if [ -f $install_root/lib/$i ]; then
      echo "rm -f $install_root/lib/$i"
            rm -f $install_root/lib/$i
    fi
  done
  if [ -h $install_root/lib/libmpgedit_decoder.so ]; then
    echo "rm -f $install_root/lib/libmpgedit_decoder.so"
          rm -f $install_root/lib/libmpgedit_decoder.so
  fi
  rmdir $install_root/lib

  for i in $include; do
    if [ -f $install_root/include/mpgedit_sdk/$i ]; then
     echo "rm -f $install_root/include/mpgedit_sdk/$i"
           rm -f $install_root/include/mpgedit_sdk/$i
    fi
  done
  rmdir $install_root/include/mpgedit_sdk
  rmdir $install_root/include

  rm -rf $install_root/examples
  rm -rf $extension_dir
  rmdir $install_root
  echo "Finished uninstalling '$product' in '$install_root'"
}


get_install_root()
{
  prefix=$1
  echo "Current ${prefix}install location is '$install_root'"
  if [ $Y_FLAG = "NO" ]; then
    echo -n "  Change location? [y/N] "
    read line
    line=`echo $line | tr '[A-Z]' '[a-z]'`
    if [ "$line" = "y" -o "$line" = "yes" ]; then
      ok=no
      echo
      while [ "$ok" = "no" ]; do
        echo "Enter ${prefix}install directory"
        read new_install_root
        echo "New ${prefix}install directory: '$new_install_root'"
        echo -n "  Is this correct? "
        read line
        line=`echo $line | tr '[A-Z]' '[a-z]'`
        if [ "$line" = "y" -o "$line" = "yes" ]; then
          ok="yes"
        fi
      done
      install_root=$new_install_root
    fi
  fi
}

#
# ============================ main =======================
#
if [ `id -u` -ne 0 ]; then
  echo "ERROR: Can only install '$product' as root"
  exit 1;
fi
umask 0

while [ `echo "x$1" | grep -c 'x-'` = "1" ]; do
  t=`echo "x$1" | grep '^x-u$'`
  if [ "x$1" = "x-u" ]; then
    U_FLAG=YES
    un="un"
  elif [ "x$1" = "x-y" ]; then
    Y_FLAG=YES
  else
    echo "unrecognized option '$1'"
    exit 1
  fi
  shift
done

if [ $U_FLAG = "YES" ]; then
  do_uninstall
else
  do_install
  exit 0
fi
