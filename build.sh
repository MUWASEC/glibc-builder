#!/bin/bash
# https://github.com/ray-cp/pwn_debug/blob/master/build.sh
# test on arch
mode="repo"
thread_cpu=4
log_file=".log.tmp"

# get the source of glibc
get_source(){
    source_ver="$1"
    mkdir -p /opt/glibc/source
    pushd /opt/glibc/source
    
    if [ $mode = "repo" ]; then
        # from sourceware repo (beware)
        if [ ! -d /opt/glibc/source/glibc_source ]; then
            echo "[*] Cloning the glibc repo ..."
            git clone git://sourceware.org/git/glibc.git "/opt/glibc/source/glibc_source"
        fi
        cd glibc_source
        git pull --all
        git rev-parse --verify --quiet "refs/remotes/origin/release/${source_ver}/master"
        git checkout "release/${source_ver}/master" -f
        git pull
        mkdir ../glibc-${source_ver}/
        cp -r * ../glibc-${source_ver}/
        cd -
    elif [ $mode = "source" ]; then
        # from third party repo
        if [ ! -f "/opt/glibc/source/glibc-${source_ver}.tar.gz" ]; then
            wget http://ftp.jaist.ac.jp/pub/GNU/glibc/glibc-${source_ver}.tar.gz
        else
            echo "[*] /opt/glibc/source/glibc-"${source_ver}" already exists..."
        fi
        tar xf glibc-${source_ver}.tar.gz

        # https://stackoverflow.com/questions/51279418/how-to-build-older-version-of-glibc/51419951#51419951
        if [ ${source_ver} = "2.23" ] || [ ${source_ver} = "2.24" ] || [ ${source_ver} = "2.25" ]; then
            echo "[*] Patching .symver on glibc-${source_ver}"
            cat <<EOF >> symver.patch
index 19d76c0..eaea7c3 100644 (file)
--- a/misc/regexp.c
+++ b/misc/regexp.c
@@ -29,14 +29,15 @@
 
 #if SHLIB_COMPAT (libc, GLIBC_2_0, GLIBC_2_23)
 
-/* Define the variables used for the interface.  */
-char *loc1;
-char *loc2;
+/* Define the variables used for the interface.  Avoid .symver on common
+   symbol, which just creates a new common symbol, not an alias.  */
+char *loc1 __attribute__ ((nocommon));
+char *loc2 __attribute__ ((nocommon));
 compat_symbol (libc, loc1, loc1, GLIBC_2_0);
 compat_symbol (libc, loc2, loc2, GLIBC_2_0);
 
 /* Although we do not support the use we define this variable as well.  */
-char *locs;
+char *locs __attribute__ ((nocommon));
 compat_symbol (libc, locs, locs, GLIBC_2_0);
EOF
            patch -i symver.patch glibc-${source_ver}/misc/regexp.c
            rm symver.patch
        fi
        popd

    fi
}

glibc_x64(){
    source_ver="$1"

    if [ -f "/opt/glibc/x64/"${source_ver}"/lib/libc-"${source_ver}".so" ];then
        echo "x64 glibc "${source_ver}" already installed!"
        return
    fi

    mkdir -p /opt/glibc/x64/${source_ver}
    pushd /opt/glibc/source/glibc-${source_ver}
    mkdir build
    cd build
    ../configure --prefix=/opt/glibc/x64/${source_ver}/ --disable-werror --enable-debug=yes
    make -j $thread_cpu
    make install -j $thread_cpu
    cat <<EOF >> /opt/glibc/x64/${source_ver}/etc/ld.so.conf
# Dynamic linker/loader configuration.
# See ld.so(8) and ldconfig(8) for details.

include /etc/ld.so.conf.d/*.conf
EOF
    rm -rf /opt/glibc/source/glibc-${source_ver}/
    popd
}


glibc_x86(){
    source_ver="$1"

    if [ -f "/opt/glibc/x86/"${source_ver}"/lib/libc-"${source_ver}".so" ];then
        echo "x86 glibc "${source_ver}" already installed!"
        return
    fi

    mkdir -p /opt/glibc/x86/${source_ver}
    
    pushd /opt/glibc/source/glibc-${source_ver}
    mkdir build && cd build
    ../configure --prefix=/opt/glibc/x86/${source_ver}/ --disable-werror --enable-debug=yes --host=i686-linux-gnu --build=i686-linux-gnu CC="gcc -m32" CXX="g++ -m32" 
    make -j $thread_cpu
    make install -j $thread_cpu
    cat <<EOF >> /opt/glibc/x86/${source_ver}/etc/ld.so.conf
# Dynamic linker/loader configuration.
# See ld.so(8) and ldconfig(8) for details.

include /etc/ld.so.conf.d/*.conf
EOF
    rm -rf /opt/glibc/source/glibc-${source_ver}/
    popd
}


glibc_no-tcache_x64(){
    source_ver="$1"

    if [ -f "/opt/glibc/no-tcache/x64/"${source_ver}"/lib/libc-"${source_ver}".so" ];then
        echo "x64 glibc non tcache "${source_ver}" already installed!"
        return
    fi

    mkdir -p /opt/glibc/no-tcache/x64/${source_ver}
    pushd /opt/glibc/source/glibc-${source_ver}
    mkdir build
    cd build
    ../configure --prefix=/opt/glibc/no-tcache/x64/${source_ver}/ --disable-werror --enable-debug=yes --disable-experimental-malloc
    make -j $thread_cpu
    make install -j $thread_cpu
    cat <<EOF >> /opt/glibc/no-tcache/x64/${source_ver}/etc/ld.so.conf
# Dynamic linker/loader configuration.
# See ld.so(8) and ldconfig(8) for details.

include /etc/ld.so.conf.d/*.conf
EOF
    rm -rf /opt/glibc/source/glibc-${source_ver}/
    popd
}

glibc_no-tcache_x86(){
    source_ver="$1"

    if [ -f "/opt/glibc/no-tcache/x86/"${source_ver}"/lib/libc-"${source_ver}".so" ];then
        echo "x86 glibc non tcache "${source_ver}" already installed!"
        return
    fi

    mkdir -p /opt/glibc/no-tcache/x86/${source_ver}
    
    pushd /opt/glibc/source/glibc-${source_ver}
    mkdir build
    cd build
    ../configure --prefix=/opt/glibc/no-tcache/x86/${source_ver}/ --disable-werror --enable-debug=yes --host=i686-linux-gnu --build=i686-linux-gnu CC="gcc -m32" CXX="g++ -m32" --disable-experimental-malloc
    make -j $thread_cpu
    make install -j $thread_cpu
    cat <<EOF >> /opt/glibc/no-tcache/x86/${source_ver}/etc/ld.so.conf
# Dynamic linker/loader configuration.
# See ld.so(8) and ldconfig(8) for details.

include /etc/ld.so.conf.d/*.conf
EOF
    rm -rf /opt/glibc/source/glibc-${source_ver}/
    popd
}


# main function
if [ "$EUID" -ne 0 ]; then 
    echo "Please run as root"
    exit 1
fi

# check
if [[ -z "$2" ]]  ||  [[ "$1" != "x64" &&  "$1" != "x86" &&  "$1" != "all" ]]; then
    echo "$0 <x64/x86/all> <version/all> <no-tcache>"
    exit 1
fi
ARCH=$1
GLIBC_VERSION=$2
OTHER=$3
echo "start at $(date)" >> "$log_file"
if [ "$GLIBC_VERSION" = "all" ]; then
    for GLIBC_VERSION in '2.19' '2.23' '2.25' '2.26' '2.27' '2.29' '2.31' '2.32'
    do
        get_source $GLIBC_VERSION;echo "get source ${GLIBC_VERSION} for x64" >> "$log_file";glibc_x64 $GLIBC_VERSION;echo "install glibc x64 ${GLIBC_VERSION}" >> "$log_file"
        get_source $GLIBC_VERSION;echo "get source ${GLIBC_VERSION} for x86" >> "$log_file";glibc_x86 $GLIBC_VERSION;echo "install glibc x86 ${GLIBC_VERSION}" >> "$log_file"
        if echo $GLIBC_VERSION | awk -F: '{ if ( $1 > 2.25 ) {print 1}  }' | grep -q 1 ; then
            get_source $GLIBC_VERSION;echo "get source ${GLIBC_VERSION} for x64 with no tcache" >> "$log_file";glibc_no-tcache_x64 $GLIBC_VERSION;echo "install glibc x64 with no tcache ${GLIBC_VERSION}" >> "$log_file"
            get_source $GLIBC_VERSION;echo "get source ${GLIBC_VERSION} for x86 with no tcache" >> "$log_file";glibc_no-tcache_x86 $GLIBC_VERSION;echo "install glibc x86 with no tcache ${GLIBC_VERSION}" >> "$log_file"
        fi
    done
else
    if [ "$OTHER" = "no-tcache" ]; then
        if ! echo $GLIBC_VERSION | awk -F: '{ if ( $1 > 2.25 ) {print 1}  }' | grep -q 1 ; then
            echo "this version doesn't have tcache!";echo "not a tcache version ${GLIBC_VERSION}" >> "$log_file"
            exit 1
        fi
        
        if [ "$ARCH" = "all" ]; then
        	get_source $GLIBC_VERSION;echo "get source ${GLIBC_VERSION} for x64 with no tcache" >> "$log_file";glibc_${OTHER}_x64 $GLIBC_VERSION;echo "install glibc x64 with no tcache ${GLIBC_VERSION}" >> "$log_file"
        	get_source $GLIBC_VERSION;echo "get source ${GLIBC_VERSION} for x86 with no tcache" >> "$log_file";glibc_${OTHER}_x86 $GLIBC_VERSION;echo "install glibc x86 with no tcache ${GLIBC_VERSION}" >> "$log_file"
        else
        	get_source $GLIBC_VERSION;echo "get source ${GLIBC_VERSION} for ${ARCH} with no tcache" >> "$log_file";glibc_${OTHER}_${ARCH} $GLIBC_VERSION;echo "install glibc ${ARCH} with no tcache ${GLIBC_VERSION}" >> "$log_file"
        fi
    else
    	
        if [ "$ARCH" = "all" ]; then
        	get_source $GLIBC_VERSION;echo "get source ${GLIBC_VERSION} for x64" >> "$log_file";glibc_x64 $GLIBC_VERSION;echo "install glibc x64 ${GLIBC_VERSION}" >> "$log_file"
        	get_source $GLIBC_VERSION;echo "get source ${GLIBC_VERSION} for x86" >> "$log_file";glibc_x86 $GLIBC_VERSION;echo "install glibc x86 ${GLIBC_VERSION}" >> "$log_file"
        else
        	get_source $GLIBC_VERSION;echo "get source ${GLIBC_VERSION} for ${ARCH}" >> "$log_file";glibc_${ARCH} $GLIBC_VERSION;echo "install glibc ${ARCH} ${GLIBC_VERSION}" >> "$log_file"
        fi
    fi
fi
echo "end at $(date)" >> "$log_file"