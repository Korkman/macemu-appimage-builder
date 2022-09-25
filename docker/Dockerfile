ARG DISTRO=debian:bullseye
ARG MACEMU_SOURCE="git"
FROM $DISTRO AS buildenv

ENV DEBIAN_FRONTEND='noninteractive'

# download dependencies
RUN apt-get update
RUN apt-get -y --no-install-recommends install \
	# for macemu \
	git \
	automake gcc \
	libgtk2.0-dev \
	libvdeplug-dev \
	uuid-dev \
	# for xen \
	bin86 bcc liblzma-dev  \
	iasl libncurses5-dev \
	wget libaio-dev libyajl-dev \
	libfdt-dev \
	# required for prefs editor (not pulled otherwise in debian:buster) \
	gvfs libgail-common libatk-adaptor \
	# include gtk gail and theme engines \
	gtk2-engines \
	# for git \
	ca-certificates \
	# some build-essentials \
	gettext build-essential git make cmake autoconf automake libtool pkg-config \
;

# libsdl2-dev 
#	# for appimage \
#	fuse3 libfuse2 \
# only for specific compile flags
#	x11proto-xf86dga-dev \
#	libxxf86dga-dev \
#	libsdl1.2-dev \

ARG SKIP_VHD="n"
ARG PACKAGING="linuxdeploy"
ARG LXDEPLOY_ARCH=""

# get some architecture "variables" going
SHELL [ "/bin/bash", "-c" ]
# copy only essential files from build directory (improves caching)
COPY build/detect-archdir.sh /build/
RUN /build/detect-archdir.sh && echo "ARCHDIR: $(</ARCHDIR)"

# download xen (libvhd source)
WORKDIR /usr/local/src/xen
# python2 for xen
RUN [ "$SKIP_VHD" = y ] || apt-get -y --no-install-recommends install python2 python2-dev || apt-get -y --no-install-recommends install python python-dev
# instant "python-is-python2" (missing in ubuntu:jammy)
RUN [ "$SKIP_VHD" = y ] || if [ -e /usr/bin/python2 ] && [ ! -e /usr/bin/python ]; then ln -s /usr/bin/python2 /usr/bin/python; fi
# added for attempting to compile libvhd on Xen arm64:
RUN [ "$SKIP_VHD" = y ] || apt-get -y --no-install-recommends install libfdt-dev
# xen 4.12 was the last to ship with blktap2, which contained libvhd
RUN [ "$SKIP_VHD" = y ] || git clone --depth 1 --branch 'stable-4.12' 'https://xenbits.xen.org/git-http/xen.git' .
# compile libvhd from Xen
WORKDIR /usr/local/src/xen/tools
RUN [ "$SKIP_VHD" = y ] || ./configure
WORKDIR /usr/local/src/xen/tools/blktap2/vhd/lib
# patch Makefile to allow some impurities
#RUN [ "$SKIP_VHD" = y ] || (mv Makefile Makefile.strict && cat Makefile.strict | sed 's/-Werror/-Wno-error/g' > Makefile && rm Makefile.strict)
# build xentools libvhd
RUN [ "$SKIP_VHD" = y ] || make -j $(nproc)
RUN [ "$SKIP_VHD" = y ] || DESTDIR=/usr/lib make install
RUN [ "$SKIP_VHD" = y ] || cp /usr/local/src/xen/tools/blktap2/include/*.h /usr/local/include/

# download linuxdeploy (AppImage builder)
WORKDIR /usr/local/bin
RUN [ "$PACKAGING" != "linuxdeploy" ] || wget https://github.com/linuxdeploy/linuxdeploy/releases/download/continuous/linuxdeploy-${LXDEPLOY_ARCH}.AppImage -O linuxdeploy
# extract linuxdeploy to use it without FUSE within build process
RUN [ "$PACKAGING" != "linuxdeploy" ] || ( \
	chmod a+x ./linuxdeploy && \
	./linuxdeploy --appimage-extract && \
	rm ./linuxdeploy && \
	mv squashfs-root linuxdeploy.appdir && \
	ln -s /usr/local/bin/linuxdeploy.appdir/AppRun /usr/local/bin/linuxdeploy \
)

# install SDL
RUN apt-get -y --no-install-recommends install libsdl2-dev

# compile SDL
#WORKDIR /usr/local/src/sdl
#RUN git clone --depth 1 --branch release-2.0.22 https://github.com/libsdl-org/SDL .
#RUN apt-get -y --no-install-recommends install libasound2-dev libpulse-dev libaudio-dev libjack-dev \
#libx11-dev libxext-dev libxrandr-dev libxcursor-dev libxfixes-dev libxi-dev \
#libxss-dev libgl1-mesa-dev libdbus-1-dev \
#libudev-dev libgles2-mesa-dev libegl1-mesa-dev libibus-1.0-dev \
#fcitx-libs-dev libsamplerate0-dev libsndio-dev libwayland-dev \
#libxkbcommon-dev libdrm-dev libgbm-dev
#WORKDIR /usr/local/src/sdl
#RUN ./configure
#RUN make -j $(nproc)
#RUN make install

# download appdir-lint.sh & deps
WORKDIR /usr/local/bin
RUN wget https://github.com/AppImage/pkg2appimage/raw/master/appdir-lint.sh -O appdir-lint.sh && chmod a+x appdir-lint.sh
RUN wget https://github.com/AppImage/pkg2appimage/raw/master/excludelist -O excludelist
RUN apt-get -y --no-install-recommends install desktop-file-utils libfile-mimeinfo-perl

RUN mkdir /output
WORKDIR /usr/local/src



# local macemu source
FROM buildenv AS buildenv-src-local
COPY build/macemu /usr/local/src/macemu
WORKDIR /usr/local/src/macemu



# download macemu (BasiliskII and SheepShaver source)
FROM buildenv AS buildenv-src-git
ARG MACEMU_GIT_ARGS="--depth 1 https://github.com/kanjitalk755/macemu"
RUN git clone $MACEMU_GIT_ARGS macemu
WORKDIR /usr/local/src/macemu



# basilisk2 thread
FROM buildenv-src-$MACEMU_SOURCE AS buildenv-basilisk2
ARG SKIP_VHD="n"
ARG SKIP_BINCUE="n"
ARG PACKAGING="linuxdeploy"

# compile BasiliskII
WORKDIR /usr/local/src/macemu/BasiliskII/src/Unix
RUN NO_CONFIGURE=1 ./autogen.sh
RUN \
	./configure \
	--enable-sdl-video=yes \
	--enable-sdl-audio=yes \
	$([ "$SKIP_BINCUE" = y ] && echo -n "" || echo -n "--with-bincue") \
	$([ "$SKIP_VHD" = y ] && echo -n "" || echo -n "--with-libvhd") \
	--with-x \
	--without-esd \
	--with-vdeplug \
;

# it's either SDL or those, SDL being the more commonly preferred gfx output
#	--enable-xf86-dga \
#	--enable-xf86-vidmode \
#	--enable-fbdev-dga \

RUN make -j $(nproc)
RUN strip BasiliskII
RUN make install DESTDIR=AppDir

# package BasiliskII
WORKDIR /build
COPY build/version-macemu-appimage-builder /build/
COPY build/generate-version-files.sh /build/
RUN /build/generate-version-files.sh

WORKDIR /usr/local/src/macemu/BasiliskII/src/Unix

RUN cp /build/version-* AppDir/usr/local/share/

# base build files referenced in linuxdeploy
COPY build/bundle-gtk2.sh     /build/bundle-gtk2.sh
COPY build/BasiliskII.desktop /build/BasiliskII.desktop
COPY build/BasiliskII.png     /build/BasiliskII.png
COPY build/AppRun.sh          /build/AppRun.sh
# extra files added to AppDir
COPY build/BasiliskII.appdata.xml    AppDir/usr/share/metainfo/
COPY build/BasiliskIIGUI.png         AppDir/usr/share/icons/
COPY build/BasiliskII.desktop.in     AppDir/BasiliskII.desktop.in
COPY build/BasiliskIIGUI.desktop.in  AppDir/BasiliskIIGUI.desktop.in

RUN APPDIR=./AppDir /build/bundle-gtk2.sh
COPY build/apprun-hook-help.sh AppDir/apprun-hooks/05-apprun-hook-help.sh
COPY build/apprun-hook-install.sh AppDir/apprun-hooks/10-apprun-hook-install.sh
RUN [ "$PACKAGING" != "linuxdeploy" ] || linuxdeploy \
	--appdir AppDir \
	--desktop-file=/build/BasiliskII.desktop \
	--icon-file=/build/BasiliskII.png \
	--custom-apprun /build/AppRun.sh \
	--executable ./BasiliskII \
	--library /usr/lib/$(</ARCHDIR)libpango-1.0.so.0 \
	--library /usr/lib/$(</ARCHDIR)libpangoft2-1.0.so.0 \
	--library /usr/lib/$(</ARCHDIR)libpangocairo-1.0.so.0 \
	--library /usr/lib/$(</ARCHDIR)gtk-2.0/modules/libatk-bridge.so \
	--library /usr/lib/$(</ARCHDIR)gtk-2.0/modules/libferret.so \
	--library /usr/lib/$(</ARCHDIR)gtk-2.0/modules/libgail.so \
	--library /usr/lib/$(</ARCHDIR)gvfs/libgvfscommon.so \
	--output appimage \
	2>&1 | tee /tmp/linuxdeploy-BasiliskII \
;
# simplify name, copy and lint
RUN [ "$PACKAGING" != "linuxdeploy" ] || ( \
	echo "Packaging with linuxdeploy" && \
	mv BasiliskII-*.AppImage BasiliskII.AppImage && \
	cp ./*.AppImage /output/ && \
	./BasiliskII.AppImage --appimage-extract > /dev/null && \
	appdir-lint.sh squashfs-root && \
	rm -rf squashfs-root \
)
RUN [ "$PACKAGING" != "tarball" ] || (echo "Packaging as tarball" && tar -czf /output/BasiliskII.AppDir.tar.gz AppDir)



# sheepshaver thread
FROM buildenv-src-$MACEMU_SOURCE AS buildenv-sheepshaver
ARG SKIP_VHD="n"
ARG SKIP_BINCUE="n"
ARG PACKAGING="linuxdeploy"

# compile SheepShaver
WORKDIR /usr/local/src/macemu/SheepShaver
RUN make links
WORKDIR /usr/local/src/macemu/SheepShaver/src/Unix
RUN NO_CONFIGURE=1 ./autogen.sh
RUN  \
	./configure \
	--enable-sdl-video=yes \
	--enable-sdl-audio=yes \
	$([ "$SKIP_BINCUE" = y ] && echo -n "" || echo -n "--with-bincue") \
	$([ "$SKIP_VHD" = y ] && echo -n "" || echo -n "--with-libvhd") \
	--with-x \
	--without-esd \
;

#	--enable-standalone-gui \ # combining the standalone gui with bincue breaks the build

RUN make -j $(nproc)
RUN strip SheepShaver
RUN make install DESTDIR=AppDir

# package SheepShaver
WORKDIR /build
COPY build/version-macemu-appimage-builder /build/
COPY build/generate-version-files.sh /build/
RUN /build/generate-version-files.sh

WORKDIR /usr/local/src/macemu/SheepShaver/src/Unix

RUN cp /build/version-* AppDir/usr/local/share/

# base build files referenced in linuxdeploy
COPY build/bundle-gtk2.sh      /build/bundle-gtk2.sh
COPY build/SheepShaver.desktop /build/SheepShaver.desktop
COPY build/SheepShaver.png     /build/SheepShaver.png
COPY build/AppRun.sh           /build/AppRun.sh
# extra files added to AppDir
COPY build/SheepShaver.appdata.xml   AppDir/usr/share/metainfo/
COPY build/SheepShaverGUI.png        AppDir/usr/share/icons/
COPY build/SheepShaver.desktop.in    AppDir/SheepShaver.desktop.in
COPY build/SheepShaverGUI.desktop.in AppDir/SheepShaverGUI.desktop.in

RUN APPDIR=./AppDir /build/bundle-gtk2.sh
COPY build/apprun-hook-help.sh AppDir/apprun-hooks/05-apprun-hook-help.sh
COPY build/apprun-hook-install.sh AppDir/apprun-hooks/10-apprun-hook-install.sh
COPY build/apprun-hook-mmap.sh AppDir/apprun-hooks/20-apprun-hook-mmap.sh
RUN [ "$PACKAGING" != "linuxdeploy" ] || linuxdeploy \
	--appdir AppDir \
	--desktop-file=/build/SheepShaver.desktop \
	--icon-file=/build/SheepShaver.png \
	--custom-apprun /build/AppRun.sh \
	--executable ./SheepShaver \
	--library /usr/lib/$(</ARCHDIR)libpango-1.0.so.0 \
	--library /usr/lib/$(</ARCHDIR)libpangoft2-1.0.so.0 \
	--library /usr/lib/$(</ARCHDIR)libpangocairo-1.0.so.0 \
	--library /usr/lib/$(</ARCHDIR)gtk-2.0/modules/libatk-bridge.so \
	--library /usr/lib/$(</ARCHDIR)gtk-2.0/modules/libferret.so \
	--library /usr/lib/$(</ARCHDIR)gtk-2.0/modules/libgail.so \
	--library /usr/lib/$(</ARCHDIR)gvfs/libgvfscommon.so \
	--output appimage \
	2>&1 | tee /tmp/linuxdeploy-SheepShaver \
;
# simplify name, copy and lint
RUN [ "$PACKAGING" != "linuxdeploy" ] || ( \
	echo "Packaging with linuxdeploy" && \
	mv SheepShaver-*.AppImage SheepShaver.AppImage && \
	cp ./*.AppImage /output/ && \
	./SheepShaver.AppImage --appimage-extract > /dev/null && \
	appdir-lint.sh squashfs-root && \
	rm -rf squashfs-root \
)
RUN [ "$PACKAGING" != "tarball" ] || (echo "Packaging as tarball" && tar -czf /output/SheepShaver.AppDir.tar.gz AppDir)



# merge outputs from builds
FROM buildenv-src-$MACEMU_SOURCE AS merge
COPY --from=buildenv-sheepshaver /output /output
COPY --from=buildenv-basilisk2 /output /output
WORKDIR /usr/local/src/macemu



# stripped down outputs
FROM scratch AS basilisk2
COPY --from=buildenv-basilisk2 /output /

FROM scratch AS sheepshaver
COPY --from=buildenv-sheepshaver /output /

FROM scratch AS combined
# reduce to final output
COPY --from=buildenv-sheepshaver /output /
COPY --from=buildenv-basilisk2 /output /



# dummy target to test gh actions
FROM scratch AS nothing
COPY build/BasiliskII.desktop /
