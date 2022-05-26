FROM debian:bullseye

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
RUN chmod a+x linuxdeploy

# compile libvhd from Xen
WORKDIR /usr/local/src/xen/tools
RUN ./configure
WORKDIR /usr/local/src/xen/tools/blktap2/vhd/lib
# patch Makefile to allow some impurities
RUN mv Makefile Makefile.strict && cat Makefile.strict | sed 's/-Werror/-Wno-error/g' > Makefile && rm Makefile.strict
RUN make -j 10
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

# compile basiliskII
WORKDIR /usr/local/src/macemu/BasiliskII/src/Unix
RUN NO_CONFIGURE=1 ./autogen.sh
RUN \
	./configure \
	--enable-sdl-video=yes \
	--enable-sdl-audio=yes \
	--with-bincue \
	--enable-standalone-gui \
	--without-esd \
	--with-vdeplug \
	--with-libvhd \
	--with-x \
	;

# it's either SDL or those, SDL being the more commonly preferred gfx output
#	--enable-xf86-dga \
#	--enable-xf86-vidmode \
#	--enable-fbdev-dga \

RUN make -j 24
RUN strip BasiliskII
RUN strip BasiliskIIGUI
RUN make install DESTDIR=AppDir

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
	;

#	--enable-standalone-gui \ # combining the standalone gui with bincue breaks the build

RUN make -j 24
RUN strip SheepShaver
RUN make install DESTDIR=AppDir
RUN mv SheepShaver SheepShaver.good

# compile SheepShaverGUI
# same options except bincue
RUN make clean
RUN  \
	./configure \
	--enable-sdl-video=yes \
	--enable-sdl-audio=yes \
	--enable-standalone-gui \
	--with-libvhd \
	--with-x \
	--without-esd \
	;
RUN make -j 24
RUN strip SheepShaverGUI
RUN make install DESTDIR=AppDir
RUN rm SheepShaver
RUN mv SheepShaver.good SheepShaver

WORKDIR /usr/local/src/macemu
CMD [ "/bin/bash", "-c", "while true; do sleep 1; done" ]
