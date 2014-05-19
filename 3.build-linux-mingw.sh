#!/usr/bin/env bash
#

LINK=`readlink -f $0`
if [[ -z ${LINK} ]]; then
LINK=$0
fi
DIRNAME=`dirname ${LINK}`

exit_error() {
    echo $1;
    exit 1;
}

procParmL()
{ 
   [ -z "$1" ] && return 1 
   if [ "${2#$1=}" != "$2" ] ; then 
      cRes="${2#$1=}" 
      return 0 
   fi 
   return 1 
}

while [ 1 ] ; do 
   if procParmL "--threads" "$1" ; then 
      THREADS="$cRes" 
   elif [ -z "$1" ] ; then 
      break
   else 
      exit_error "Error: Invalid key"
   fi 
   shift 
done

if [ "${!THREADS[@]}" ]; then
    JOB_FLAG="-j"
    if [ $THREADS ]; then
        echo "Build using $THREADS threads"
    else
        echo "Build using MAX threads"
    fi
else
    echo "Build using single thread."
fi

RELEASE_VERSION="0.8.0"
SOURCE_DESTDIR=${DIRNAME}/dependencies
RELEASE_PUBLISH_DIR=releases
TARGET_PLATFORMS=("mingw32")
WORKSPACE=${DIRNAME}

for CUR_PLATFORM in ${TARGET_PLATFORMS}; do
    if [ -z ${CUR_PLATFORM} ]; then
        exit_error "NO target platform given."
    fi

    # ensure platform base directory exist:
    platform_src_dir=${SOURCE_DESTDIR}/$CUR_PLATFORM
    [ -d ${platform_src_dir} ] || exit_error "INVALID platform given, or missing platformdir"

    mkdir -p ${WORKSPACE}/release
    
    # quite ugly case...
    case "${CUR_PLATFORM}" in
        mingw32)
            rm -f ${WORKSPACE}/release/bitcoin-qt.exe
            rm -f ${WORKSPACE}/release/bitcoind.exe
        
            # qt client:
            echo "Building bitcoin qt client..."
            cd ${WORKSPACE} || exit_error "Failed to change to workspace dir"
            make distclean
            make -C bitcoin-qt/src -f makefile.unix clean USE_NATIVE_I2P=1
            make -C bitcoin-qt/src -f makefile.linux-mingw clean USE_NATIVE_I2P=1
            echo "goto ${WORKSPACE}"
            cd ${WORKSPACE} || exit_error "Failed to change to workspace dir"
            PATH=${platform_src_dir}/qt/bin:$PATH ${platform_src_dir}/qt/bin/qmake -spec unsupported/win32-g++-cross MINIUPNPC_LIB_PATH=${platform_src_dir}/miniupnpc-1.6 MINIUPNPC_INCLUDE_PATH=${platform_src_dir} BDB_LIB_PATH=${platform_src_dir}/db-4.8.30.NC/build_unix BDB_INCLUDE_PATH=${platform_src_dir}/db-4.8.30.NC/build_unix BOOST_LIB_PATH=${platform_src_dir}/boost_1_50_0/stage/lib BOOST_INCLUDE_PATH=${platform_src_dir}/boost_1_50_0 BOOST_LIB_SUFFIX=-mt BOOST_THREAD_LIB_SUFFIX=_win32-mt OPENSSL_LIB_PATH=${platform_src_dir}/openssl-1.0.1c OPENSSL_INCLUDE_PATH=${platform_src_dir}/openssl-1.0.1c/include QRENCODE_LIB_PATH=${platform_src_dir}/qrencode-3.4.2/.libs QRENCODE_INCLUDE_PATH=${platform_src_dir}/qrencode-3.4.2 USE_UPNP=1 USE_QRCODE=1 INCLUDEPATH=${platform_src_dir} DEFINES="BOOST_THREAD_USE_LIB BOOST_THREAD_PROVIDES_GENERIC_SHARED_MUTEX_ON_WIN FD_SETSIZE=1024" QMAKE_LRELEASE=lrelease USE_BUILD_INFO=1 BITCOIN_NEED_QT_PLUGINS=1 RELEASE=1 || exit_error "qmake failed"
            PATH=${platform_src_dir}/qt/bin:$PATH make $JOB_FLAG $THREADS || exit_error "Make failed"
            cp -f ${WORKSPACE}/bitcoin-qt/release/bitcoin-qt.exe ${WORKSPACE}/release

            # bitcoin headless daemon:
            echo "Building bitcoin headless daemon..."
            cd ${WORKSPACE}/bitcoin-qt/src/ || exit_error "Failed to change to bitcoin src/"
            make distclean
            make -f makefile.unix clean USE_NATIVE_I2P=1
            make -f makefile.linux-mingw clean USE_NATIVE_I2P=1
#            cd ${WORKSPACE}/src/leveldb/ || exit_error "Failed to change to src/leveldb/"
#            PATH=/usr/i586-mingw32msvc/bin/:$PATH TARGET_OS="OS_WINDOWS_CROSSCOMPILE" CXX=i586-mingw32msvc-c++ CC=i586-mingw32msvc-cc LD=i586-mingw32msvc-ld OPT="-I${platform_src_dir}/boost_1_50_0" make libmemenv.a libleveldb.a || exit_error "Failed to build leveldb"
            cd ${WORKSPACE}/bitcoin-qt/src/ || exit_error "Failed to change to src/"
            export MINGW_EXTRALIBS_DIR=${platform_src_dir}
            make $JOB_FLAG $THREADS -f makefile.linux-mingw DEPSDIR=${platform_src_dir} USE_NATIVE_I2P=1 || exit_error "make failed"
            /usr/i586-mingw32msvc/bin/strip bitcoind.exe || exit_error "strip failed"
            [ -f ${WORKSPACE}/bitcoin-qt/src/bitcoind.exe ] || exit_error "UNABLE to find generated bitcoind.exe"
            echo "bitcoind compile success."           
            cp -f ${WORKSPACE}/bitcoin-qt/src/bitcoind.exe ${WORKSPACE}/release

        ;;

        *)
            exit_error "Not Yet Implemented"
        ;;
    esac

done