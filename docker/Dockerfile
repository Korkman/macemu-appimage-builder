FROM debian:bullseye AS buildenv

ENV DEBIAN_FRONTEND='noninteractive'

# download dependencies
RUN apt-get update
RUN apt-get -y install \
	# for macemu \
	git \
	automake gcc \
	libgtk2.0-dev libsdl2-dev \
	libvdeplug-dev \
	x11proto-xf86dga-dev \
	libxxf86dga-dev \
	# for xen \
	bin86 bcc liblzma-dev python \
	python-dev iasl libncurses5-dev \
	wget libaio-dev libyajl-dev \
	# for appimage \
	fuse3 libfuse2 \
	# to convert .ico files \
	graphicsmagick


# download xen (libvhd source)
WORKDIR /usr/local/src/xen
RUN git clone --depth 1 https://github.com/mirage/xen.git .

# download linuxdeploy (AppImage builder)
WORKDIR /usr/local/bin
RUN wget https://github.com/linuxdeploy/linuxdeploy/releases/download/continuous/linuxdeploy-x86_64.AppImage -O linuxdeploy
# extract linuxdeploy to use it without FUSE within build process
RUN chmod a+x linuxdeploy && \
	./linuxdeploy --appimage-extract && \
	rm ./linuxdeploy && \
	ln -s /usr/local/bin/squashfs-root/AppRun /usr/local/bin/linuxdeploy

# compile libvhd from Xen
WORKDIR /usr/local/src/xen/tools
RUN ./configure
WORKDIR /usr/local/src/xen/tools/blktap2/vhd/lib
# patch Makefile to allow some impurities
RUN mv Makefile Makefile.strict && cat Makefile.strict | sed 's/-Werror/-Wno-error/g' > Makefile && rm Makefile.strict
RUN make -j $(nproc)
RUN DESTDIR=/usr/lib make install
RUN cp /usr/local/src/xen/tools/blktap2/include/*.h /usr/local/include/

# download macemu (BasiliskII and SheepShaver source)
WORKDIR /usr/local/src/macemu

# some variants of source to build
RUN git clone --depth 1 https://github.com/kanjitalk755/macemu .
#RUN git clone --depth 1 --branch v1.0.0 https://github.com/kanjitalk755/macemu .
#RUN git clone --depth 1 https://github.com/cebix/macemu .

# required for older codebases
#RUN apt-get -y install libsdl1.2-dev
RUN apt-get -y install gtk2-engines

COPY build /build
RUN mkdir -p /output/installFiles
RUN mkdir -p /output/macemuAppImages

FROM buildenv AS BasiliskII

# compile basiliskII
WORKDIR /usr/local/src/macemu/BasiliskII/src/Unix
RUN NO_CONFIGURE=1 ./autogen.sh
RUN \
	./configure \
	--enable-sdl-video=yes \
	--enable-sdl-audio=yes \
	--with-bincue \
	--with-libvhd \
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
RUN APPDIR=./AppDir /build/bundle-gtk2.sh
RUN gm convert /usr/local/src/macemu/BasiliskII/src/Windows/BasiliskII.ico ./BasiliskII.png && \
	gm convert /usr/local/src/macemu/BasiliskII/src/Windows/BasiliskIIGUI.ico ./BasiliskIIGUI.png
RUN cp ./BasiliskII.png /output/installFiles/ && \
	cp ./BasiliskIIGUI.png /output/installFiles/ && \
	cp /build/BasiliskII.desktop /output/installFiles/ && \
	cp /build/BasiliskIIGUI.desktop /output/installFiles/
RUN linuxdeploy \
		--appdir AppDir \
		--custom-apprun /build/AppRun.sh \
		--executable ./BasiliskII \
		--library /usr/lib/x86_64-linux-gnu/libpango-1.0.so.0 \
		--library /usr/lib/x86_64-linux-gnu/libpangoft2-1.0.so.0 \
		--library /usr/lib/x86_64-linux-gnu/libpangocairo-1.0.so.0 \
		--library /usr/lib/x86_64-linux-gnu/libgdk_pixbuf-2.0.so.0 \
		--desktop-file=/build/BasiliskII.desktop \
		--icon-file=BasiliskII.png \
		--output appimage 2>&1 | tee /tmp/linuxdeploy-BasiliskII
RUN mv BasiliskII-*.AppImage BasiliskII.AppImage && cp ./*.AppImage /output/macemuAppImages/

FROM buildenv AS SheepShaver

# compile SheepShaver
WORKDIR /usr/local/src/macemu/SheepShaver
RUN make links
WORKDIR /usr/local/src/macemu/SheepShaver/src/Unix
RUN NO_CONFIGURE=1 ./autogen.sh
RUN  \
	./configure \
	--enable-sdl-video=yes \
	--enable-sdl-audio=yes \
	--with-bincue \
	--with-libvhd \
	--with-x \
	--without-esd \
	--with-vdeplug \
	;

#	--enable-standalone-gui \ # combining the standalone gui with bincue breaks the build

RUN make -j $(nproc)
RUN strip SheepShaver
RUN make install DESTDIR=AppDir
# copy theme files to AppDirs
WORKDIR /usr/local/src/macemu/SheepShaver/src/Unix
RUN mkdir -p AppDir/usr/share/themes/ && cp -r /usr/share/themes AppDir/usr/share/

RUN cp /build/SheepShaver.desktop ./AppDir/
RUN APPDIR=./AppDir /build/bundle-gtk2.sh
RUN gm convert /usr/local/src/macemu/SheepShaver/src/Windows/SheepShaver.ico ./SheepShaver.png && \
	gm convert /usr/local/src/macemu/SheepShaver/src/Windows/SheepShaverGUI.ico ./SheepShaverGUI.png
RUN cp ./SheepShaver.png /output/installFiles/ && \
	cp ./SheepShaverGUI.png /output/installFiles/ && \
	cp /build/SheepShaver.desktop /output/installFiles/ && \
	cp /build/SheepShaverGUI.desktop /output/installFiles/
RUN linuxdeploy \
		--appdir AppDir \
		--custom-apprun /build/AppRun.sh \
		--executable ./SheepShaver \
		--library /usr/lib/x86_64-linux-gnu/libpango-1.0.so.0 \
		--library /usr/lib/x86_64-linux-gnu/libpangoft2-1.0.so.0 \
		--library /usr/lib/x86_64-linux-gnu/libpangocairo-1.0.so.0 \
		--library /usr/lib/x86_64-linux-gnu/libgdk_pixbuf-2.0.so.0 \
		--desktop-file=/build/SheepShaver.desktop \
		--icon-file=SheepShaver.png \
		--output appimage 2>&1 | tee /tmp/linuxdeploy-SheepShaver
RUN mv SheepShaver-*.AppImage SheepShaver.AppImage && cp ./*.AppImage /output/macemuAppImages/

FROM buildenv AS final

COPY --from=BasiliskII /output /output
COPY --from=SheepShaver /output /output
# rename output files to be more readable, add helpers
RUN cp /build/helpers/* /output/

WORKDIR /usr/local/src/macemu

CMD [ "/bin/bash", "-c", "echo -n '.'; rm -rf /externalOutput/*; echo -n '.'; cp -ax /output/* /externalOutput/" ]
