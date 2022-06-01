ARG DISTRO=debian:bullseye


FROM $DISTRO AS buildenv
ARG SKIP_VHD="n"
ARG PACKAGING="linuxdeploy"
ARG LXDEPLOY_ARCH=""

ENV DEBIAN_FRONTEND='noninteractive'

# download dependencies
RUN apt-get update
RUN apt-get -y install \
	# for macemu \
	git \
	automake gcc \
	libgtk2.0-dev libsdl2-dev \
	libvdeplug-dev \
	# for xen \
	bin86 bcc liblzma-dev python \
	python-dev iasl libncurses5-dev \
	wget libaio-dev libyajl-dev \
	# for appimage \
	fuse3 libfuse2 \
	# to convert .ico files \
	graphicsmagick

#	x11proto-xf86dga-dev \
#	libxxf86dga-dev \

COPY build /build

# get some architecture "variables" going
SHELL [ "/bin/bash", "-c" ]
RUN /build/detect-archdir.sh
RUN echo "ARCHDIR: $(</ARCHDIR)"


# download xen (libvhd source)
WORKDIR /usr/local/src/xen
RUN [ "$SKIP_VHD" = y ] || git clone --depth 1 https://github.com/mirage/xen.git .

# download linuxdeploy (AppImage builder)
WORKDIR /usr/local/bin
		
RUN [ "$PACKAGING" != "linuxdeploy" ] || wget https://github.com/linuxdeploy/linuxdeploy/releases/download/continuous/linuxdeploy-${LXDEPLOY_ARCH}.AppImage -O linuxdeploy
# extract linuxdeploy to use it without FUSE within build process
RUN [ "$PACKAGING" != "linuxdeploy" ] || (chmod a+x linuxdeploy && \
	./linuxdeploy --appimage-extract && \
	rm ./linuxdeploy && \
	ln -s /usr/local/bin/squashfs-root/AppRun /usr/local/bin/linuxdeploy)

# compile libvhd from Xen
# added for attempting to compile libvhd on Xen arm64:
RUN [ "$SKIP_VHD" = y ] || apt-get -y install libfdt-dev
WORKDIR /usr/local/src/xen/tools
RUN [ "$SKIP_VHD" = y ] || ./configure
WORKDIR /usr/local/src/xen/tools/blktap2/vhd/lib
# patch Makefile to allow some impurities
RUN [ "$SKIP_VHD" = y ] || (mv Makefile Makefile.strict && cat Makefile.strict | sed 's/-Werror/-Wno-error/g' > Makefile && rm Makefile.strict)
# build xentools libvhd
RUN [ "$SKIP_VHD" = y ] || make -j $(nproc)
RUN [ "$SKIP_VHD" = y ] || DESTDIR=/usr/lib make install
RUN [ "$SKIP_VHD" = y ] || cp /usr/local/src/xen/tools/blktap2/include/*.h /usr/local/include/

# download macemu (BasiliskII and SheepShaver source)
WORKDIR /usr/local/src/macemu

# some variants of source to build
ARG MACEMU_GIT_ARGS="--depth 1 https://github.com/kanjitalk755/macemu"
RUN git clone $MACEMU_GIT_ARGS .

# required for older codebases
#RUN apt-get -y install libsdl1.2-dev

# including themes for a fallback startup option APP_GTK_THEME=X
RUN apt-get -y install gtk2-engines

RUN mkdir -p /output/installFiles
RUN mkdir -p /output/macemuAppImages



FROM buildenv AS buildenv-basilisk2
ARG SKIP_VHD="n"
ARG SKIP_BINCUE="n"
ARG PACKAGING="linuxdeploy"

# compile basiliskII
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
# copy theme files to AppDirs
WORKDIR /usr/local/src/macemu/BasiliskII/src/Unix
RUN mkdir -p AppDir/usr/share/themes/ && cp -r /usr/share/themes AppDir/usr/share/

RUN cp /build/BasiliskII.desktop ./AppDir/
RUN [ "$PACKAGING" != "tarball" ] || ( \
	mkdir -p AppDir/usr/lib && \
	cp /build/AppRun.sh AppDir/ && \
	chmod a+x AppDir/AppRun.sh \
	)
RUN APPDIR=./AppDir /build/bundle-gtk2.sh
RUN gm convert /usr/local/src/macemu/BasiliskII/src/Windows/BasiliskII.ico ./BasiliskII.png && \
	gm convert /usr/local/src/macemu/BasiliskII/src/Windows/BasiliskIIGUI.ico ./BasiliskIIGUI.png
RUN cp ./BasiliskII.png /output/installFiles/ && \
	cp ./BasiliskIIGUI.png /output/installFiles/ && \
	cp /build/BasiliskII.desktop /output/installFiles/ && \
	cp /build/BasiliskIIGUI.desktop /output/installFiles/
RUN [ "$PACKAGING" != "linuxdeploy" ] || linuxdeploy \
		--appdir AppDir \
		--custom-apprun /build/AppRun.sh \
		--executable ./BasiliskII \
		--library /usr/lib/$(</ARCHDIR)libpango-1.0.so.0 \
		--library /usr/lib/$(</ARCHDIR)libpangoft2-1.0.so.0 \
		--library /usr/lib/$(</ARCHDIR)libpangocairo-1.0.so.0 \
		--library /usr/lib/$(</ARCHDIR)libgdk_pixbuf-2.0.so.0 \
		--desktop-file=/build/BasiliskII.desktop \
		--icon-file=BasiliskII.png \
		--output appimage 2>&1 | tee /tmp/linuxdeploy-BasiliskII
RUN [ "$PACKAGING" != "linuxdeploy" ] || (echo "Packaging with linuxdeploy" && mv BasiliskII-*.AppImage BasiliskII.AppImage && cp ./*.AppImage /output/macemuAppImages/)
RUN [ "$PACKAGING" != "tarball" ] || (echo "Packaging as tarball" && tar -czf /output/macemuAppImages/BasiliskII.AppDir.tar.gz AppDir)
COPY --from=buildenv /build/helpers/Install /output/
COPY --from=buildenv /build/helpers/BasiliskII /output/
COPY --from=buildenv /build/helpers/BasiliskIIGUI /output/



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
# copy theme files to AppDirs
WORKDIR /usr/local/src/macemu/SheepShaver/src/Unix
RUN mkdir -p AppDir/usr/share/themes/ && cp -r /usr/share/themes AppDir/usr/share/

RUN cp /build/SheepShaver.desktop ./AppDir/
RUN [ "$PACKAGING" != "tarball" ] || ( \
	mkdir -p AppDir/usr/lib && \
	cp /build/AppRun.sh AppDir/ && \
	chmod a+x AppDir/AppRun.sh \
	)
RUN APPDIR=./AppDir /build/bundle-gtk2.sh
RUN gm convert /usr/local/src/macemu/SheepShaver/src/Windows/SheepShaver.ico ./SheepShaver.png && \
	gm convert /usr/local/src/macemu/SheepShaver/src/Windows/SheepShaverGUI.ico ./SheepShaverGUI.png
RUN cp ./SheepShaver.png /output/installFiles/ && \
	cp ./SheepShaverGUI.png /output/installFiles/ && \
	cp /build/SheepShaver.desktop /output/installFiles/ && \
	cp /build/SheepShaverGUI.desktop /output/installFiles/
RUN [ "$PACKAGING" != "linuxdeploy" ] || linuxdeploy \
		--appdir AppDir \
		--custom-apprun /build/AppRun.sh \
		--executable ./SheepShaver \
		--library /usr/lib/$(</ARCHDIR)libpango-1.0.so.0 \
		--library /usr/lib/$(</ARCHDIR)libpangoft2-1.0.so.0 \
		--library /usr/lib/$(</ARCHDIR)libpangocairo-1.0.so.0 \
		--library /usr/lib/$(</ARCHDIR)libgdk_pixbuf-2.0.so.0 \
		--desktop-file=/build/SheepShaver.desktop \
		--icon-file=SheepShaver.png \
		--output appimage 2>&1 | tee /tmp/linuxdeploy-SheepShaver
RUN [ "$PACKAGING" != "linuxdeploy" ] || (echo "Packaging with linuxdeploy" && mv SheepShaver-*.AppImage SheepShaver.AppImage && cp ./*.AppImage /output/macemuAppImages/)
RUN [ "$PACKAGING" != "tarball" ] || (echo "Packaging as tarball" && tar -czf /output/macemuAppImages/SheepShaver.AppDir.tar.gz AppDir)
COPY --from=buildenv /build/helpers/Install /output/
COPY --from=buildenv /build/helpers/SheepShaver /output/
COPY --from=buildenv /build/helpers/SheepShaverGUI /output/
COPY --from=buildenv /build/helpers/SheepShaverMmap /output/



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
