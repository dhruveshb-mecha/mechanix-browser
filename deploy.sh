flutter-elinux clean
flutter-elinux pub get
 flutter-elinux build elinux --release   --target-arch=arm64   --target-compiler-triple=aarch64-linux-gnu   --target-sysroot=/home/spider/Work/sysroot-comet
aarch64-linux-gnu-strip --strip-unneeded ./build/elinux/arm64/release/bundle/lib/libcef.so

sshpass -p 'mecha' scp -r ./build/elinux/arm64/release/bundle/* mecha@192.168.29.145:/home/mecha/browser

