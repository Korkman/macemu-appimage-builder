ARG DISTRO=debian:bullseye
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

# python2 for xen
RUN apt-get -y --no-install-recommends install python2 python2-dev || apt-get -y --no-install-recommends install python python-dev
# instant "python-is-python2" (missing in ubuntu:jammy)
RUN if [ -e /usr/bin/python2 ] && [ ! -e /usr/bin/python ]; then ln -s /usr/bin/python2 /usr/bin/python; fi

ARG SKIP_VHD="n"
ARG PACKAGING="linuxdeploy"
ARG LXDEPLOY_ARCH=""
ARG MACEMU_GIT_ARGS="--depth 1 https://github.com/kanjitalk755/macemu"
ARG MACEMU_SOURCE="git"


# get some architecture "variables" going
SHELL [ "/bin/bash", "-c" ]
# copy only essential files from build directory (improves caching)
COPY build/detect-archdir.sh /build/
RUN /build/detect-archdir.sh
RUN echo "ARCHDIR: $(</ARCHDIR)"

# download xen (libvhd source)
WORKDIR /usr/local/src/xen
RUN [ "$SKIP_VHD" = y ] || git clone --depth 1 --branch RELEASE-4.8.1 https://github.com/mirage/xen.git .

# download linuxdeploy (AppImage builder)
WORKDIR /usr/local/bin
RUN [ "$PACKAGING" != "linuxdeploy" ] || wget https://github.com/linuxdeploy/linuxdeploy/releases/download/continuous/linuxdeploy-${LXDEPLOY_ARCH}.AppImage -O linuxdeploy
# extract linuxdeploy to use it without FUSE within build process
RUN [ "$PACKAGING" != "linuxdeploy" ] || ( \
	chmod a+x linuxdeploy && \
	./linuxdeploy --appimage-extract && \
	rm ./linuxdeploy && \
	ln -s /usr/local/bin/squashfs-root/AppRun /usr/local/bin/linuxdeploy \
)

# compile libvhd from Xen
# added for attempting to compile libvhd on Xen arm64:
RUN [ "$SKIP_VHD" = y ] || apt-get -y --no-install-recommends install libfdt-dev
WORKDIR /usr/local/src/xen/tools

RUN [ "$SKIP_VHD" = y ] || ./configure
WORKDIR /usr/local/src/xen/tools/blktap2/vhd/lib
# patch Makefile to allow some impurities
RUN [ "$SKIP_VHD" = y ] || (mv Makefile Makefile.strict && cat Makefile.strict | sed 's/-Werror/-Wno-error/g' > Makefile && rm Makefile.strict)
# build xentools libvhd
RUN [ "$SKIP_VHD" = y ] || make -j $(nproc)
RUN [ "$SKIP_VHD" = y ] || DESTDIR=/usr/lib make install
RUN [ "$SKIP_VHD" = y ] || cp /usr/local/src/xen/tools/blktap2/include/*.h /usr/local/include/

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


# download macemu (BasiliskII and SheepShaver source)
WORKDIR /usr/local/src

# copy fll build directory
COPY build /build

# some variants of source to build
RUN [ "$MACEMU_SOURCE" != "git" ] || git clone $MACEMU_GIT_ARGS macemu
RUN [ "$MACEMU_SOURCE" != "local" ] || ln -s /build/macemu /usr/local/src/macemu

WORKDIR /usr/local/src/macemu

RUN mkdir -p /output/installFiles
RUN mkdir -p /output/macemuAppImages



FROM buildenv AS buildenv-basilisk2
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

WORKDIR /usr/local/src/macemu/BasiliskII/src/Unix

RUN [ "$PACKAGING" != "tarball" ] || ( \
	mkdir -p AppDir/usr/lib && \
	cp /build/AppRun.sh AppDir/ && \
	chmod a+x AppDir/AppRun.sh \
)
RUN cp /build/BasiliskII.png /output/installFiles/ && \
	cp /build/BasiliskIIGUI.png /output/installFiles/ && \
	cp /build/BasiliskII.desktop /output/installFiles/ && \
	cp /build/BasiliskIIGUI.desktop /output/installFiles/ && \
	cp /build/helpers/Install /output/ && \
	cp /build/helpers/BasiliskII /output/ && \
	cp /build/helpers/BasiliskIIGUI /output/ \
;
RUN APPDIR=./AppDir /build/bundle-gtk2.sh
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
	cp ./*.AppImage /output/macemuAppImages/ && \
	./BasiliskII.AppImage --appimage-extract > /dev/null && \
	appdir-lint.sh squashfs-root && \
	rm -rf squashfs-root \
)
RUN [ "$PACKAGING" != "tarball" ] || (echo "Packaging as tarball" && tar -czf /output/macemuAppImages/BasiliskII.AppDir.tar.gz AppDir)



FROM buildenv AS buildenv-sheepshaver
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

WORKDIR /usr/local/src/macemu/SheepShaver/src/Unix

RUN [ "$PACKAGING" != "tarball" ] || ( \
	mkdir -p AppDir/usr/lib && \
	cp /build/AppRun.sh AppDir/ && \
	chmod a+x AppDir/AppRun.sh \
)
RUN cp /build/SheepShaver.png /output/installFiles/ && \
	cp /build/SheepShaverGUI.png /output/installFiles/ && \
	cp /build/SheepShaver.desktop /output/installFiles/ && \
	cp /build/SheepShaverGUI.desktop /output/installFiles/ && \
	cp /build/helpers/Install /output/ && \
	cp /build/helpers/SheepShaver /output/ && \
	cp /build/helpers/SheepShaverGUI /output/ && \
	cp /build/helpers/SheepShaverMmap /output/ \
;
RUN APPDIR=./AppDir /build/bundle-gtk2.sh
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
	cp ./*.AppImage /output/macemuAppImages/ && \
	./SheepShaver.AppImage --appimage-extract > /dev/null && \
	appdir-lint.sh squashfs-root && \
	rm -rf squashfs-root \
)
RUN [ "$PACKAGING" != "tarball" ] || (echo "Packaging as tarball" && tar -czf /output/macemuAppImages/SheepShaver.AppDir.tar.gz AppDir)


FROM buildenv AS merge
# merge outputs from builds

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

FROM scratch AS nothing
# dummy target to test gh actions
COPY build/helpers /
