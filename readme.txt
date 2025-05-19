# build
docker build -t glibc-builder .
docker run --rm -it \
    -v "$(pwd)/build.sh:/src/build.sh" \
    -v "/opt/glibc:/opt/glibc" \
    -v "$(pwd):/src" \
    glibc-builder \
    ./build.sh x64 2.27

# test glibc build (https://stackoverflow.com/a/52454710)
./test_glibc.sh /opt/glibc/x64/2.27/
or
/opt/glibc/x64/2.27/lib/ld-2.27.so --library-path /opt/glibc/x64/2.27/lib ./binary_program


# fix glibc-2.23
---| problem solve
https://stackoverflow.com/questions/51279418/how-to-build-older-version-of-glibc/51419951#51419951
git cherry-pick 388b4f1a02f3a801965028bbfcd48d905638b797

# fix glibc-2.19
../configure --prefix=/opt/glibc/x86/2.24/  --disable-werror --enable-debug=yes --host=i686-linux-gnu --build=i686-linux-gnu CC="gcc -m32" CXX="g++ -m32";make -j `nproc`;make install -j `nproc`
patch -i patchfile.patch -o updatedfile