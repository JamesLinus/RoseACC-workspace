#!/bin/bash -e

function create_environment() {
  local name=$1
  local tag=$2
  local directory=$3
  local extra_ld_library_path=$4

  mkdir -p $directory
  pushd $directory > /dev/null

  > $name-environment.rc
  echo "export ${tag}_WORKSPACE_DIR=$directory" >> $name-environment.rc
  echo "" >> $name-environment.rc
  echo "export PATH=\$${tag}_WORKSPACE_DIR/opt/bin:\$PATH" >> $name-environment.rc
  echo "export LD_LIBRARY_PATH=\$${tag}_WORKSPACE_DIR/opt/lib64:\$${tag}_WORKSPACE_DIR/opt/lib:\$LD_LIBRARY_PATH" >> $name-environment.rc
  if [ ! -z $extra_ld_library_path ]; then
    echo "" >> rose-environment.rc
    echo "export LD_LIBRARY_PATH=$extra_ld_library_path:\$LD_LIBRARY_PATH" >> rose-environment.rc
  fi
  chmod +x $name-environment.rc

  popd > /dev/null
}

function install_software() {
  local tag=$1
  local url=$2
  local ext=$3
  local deps=$(echo $4 | tr ':' ' ')
  local directory=$5
  local num_parallel_make_jobs=$6

  dep_list=""
  for dep in $deps; do
    dep_list=$dep_list" --with-$dep=$directory/opt"
  done

  filename=$tag.tar.$ext

  if   [ $ext == "gz"  ]; then tar_cmd="tar xzf";
  elif [ $ext == "bz2" ]; then tar_cmd="tar xjf";
  else exit 1
  fi

  [ -z "$tar_cmd" ] && exit 2

  mkdir -p $directory/src
  pushd $directory/src > /dev/null

  if [ ! -e $tag ]; then
    [ ! -e $filename ] && wget $url/$filename
    $tar_cmd $filename
    cd $tag
    ./configure --prefix=$directory/opt $dep_list

    make -j$num_parallel_make_jobs
    make install
  fi

  popd > /dev/null
}

function install_boost() {
  local version=$1
  local directory=$2
  local num_parallel_make_jobs=$3

  tag=boost_$(echo $version | tr '.' '_')
  filename=$tag.tar.gz
  url=http://sourceforge.net/projects/boost/files/boost/$version

  mkdir -p $directory/src
  pushd $directory/src > /dev/null

  if [ ! -e $tag ]; then
    [ ! -e $filename ] && wget $url/$filename
    tar xzf $filename
    cd $tag
    ./bootstrap.sh --prefix=$directory/opt
    ./b2 -j$num_parallel_make_jobs
    ./b2 install
  fi

  popd > /dev/null
}

function usage() {
  echo "Usage:"
  echo " > $0 -h"
  echo " > $0 -d directory ..."
  echo "   -d: directory where to install the GCC/Boost toolchain."
  echo "   -n: name of the workspace (used in file and directory names)"
  echo "   -t: tag for the workspace (used for environment variable)"
  echo "   -L: addition to LD_LIBRARY_PATH"
  echo "   -j: number of parallel jobs used by make [default:\"$(cat /proc/cpuinfo | grep processor | wc -l)\"]"
}

name="roseacc"
tag="ROSEACC"
directory="$(pwd)"
extra_ld_library_path=""
num_parallel_make_jobs=$(cat /proc/cpuinfo | grep processor | wc -l)

if [ -z "$1" ]; then
  usage
  exit 2
fi
if [ "$1" == "-h" ]; then
  usage
  exit 0
fi
while [ ! -z $1 ]; do
  if   [ "$1" == "-d" ]; then directory=$2              ; shift 2
  elif [ "$1" == "-n" ]; then name=$2                   ; shift 2
  elif [ "$1" == "-t" ]; then tag=$2                    ; shift 2
  elif [ "$1" == "-L" ]; then extra_ld_library_path=$2  ; shift 2
  elif [ "$1" == "-j" ]; then num_parallel_make_jobs=$2 ; shift 2
  else
    echo "Error: Unrecognized option: $1"
    echo
    usage
    exit 2
  fi
done
if [ -z "$directory" ] || [ -z "$name" ] || [ -z "$tag" ]; then
  usage
  exit 3
fi

source_file=$directory/$name-environment.rc
create_environment $name $tag $directory $extra_ld_library_path
source $source_file

install_software "autoconf-2.69"   "http://ftp.gnu.org/gnu/autoconf"            "gz"  ""             $directory $num_parallel_make_jobs
install_software "automake-1.14.1" "http://ftp.gnu.org/gnu/automake"            "gz"  ""             $directory $num_parallel_make_jobs
install_software "libtool-2.4"     "http://gnu.mirror.vexxhost.com/libtool"     "gz"  ""             $directory $num_parallel_make_jobs
install_software "flex-2.5.39"     "http://sourceforge.net/projects/flex/files" "gz"  ""             $directory $num_parallel_make_jobs
install_software "gmp-5.1.2"       "https://gmplib.org/download/gmp"            "bz2" ""             $directory $num_parallel_make_jobs
install_software "mpfr-3.1.3"      "http://www.mpfr.org/mpfr-current"           "gz"  "gmp"          $directory $num_parallel_make_jobs
install_software "mpc-1.0.3"       "ftp://ftp.gnu.org/gnu/mpc"                  "gz"  "gmp:mpfr"     $directory $num_parallel_make_jobs
install_software "gcc-4.4.7"       "https://ftp.gnu.org/gnu/gcc/gcc-4.4.7"      "gz"  "gmp:mpfr:mpc" $directory $num_parallel_make_jobs

install_boost "1.45.0" $directory $num_parallel_make_jobs

