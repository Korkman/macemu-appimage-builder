#! /bin/sh
{
    set -eu

    SELF=$(readlink -f "$0")
    HERE=${SELF%/*}
    APPDIR=${SELF%/*}
    export PATH="${HERE}/usr/local/bin/:${HERE}/usr/local/sbin/:${HERE}/usr/bin/:${HERE}/usr/sbin/:${HERE}/usr/games/:${HERE}/bin/:${HERE}/sbin/${PATH:+:$PATH}"
    export LD_LIBRARY_PATH="${HERE}/usr/lib/:${HERE}/lib/${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
    export PYTHONPATH="${HERE}/usr/share/pyshared/${PYTHONPATH:+:$PYTHONPATH}"
    export XDG_DATA_DIRS="${HERE}/usr/share/${XDG_DATA_DIRS:+:$XDG_DATA_DIRS}"
    export PERLLIB="${HERE}/usr/share/perl5/:${HERE}/usr/lib/perl5/${PERLLIB:+:$PERLLIB}"
    export GSETTINGS_SCHEMA_DIR="${HERE}/usr/share/glib-2.0/schemas/${GSETTINGS_SCHEMA_DIR:+:$GSETTINGS_SCHEMA_DIR}"
    export QT_PLUGIN_PATH="${HERE}/usr/lib/qt4/plugins/:${HERE}/usr/lib/qt5/plugins/${QT_PLUGIN_PATH:+:$QT_PLUGIN_PATH}"
    
    # prepend architecture library paths
    for LIBDIR in /usr/lib/ /usr/local/lib/ /lib/ /
    do
        for ARCHDIR in x86_64-linux-gnu i386-linux-gnu arm-linux-gnueabi arm-linux-gnueabihf aarch64-linux-gnu lib64 lib32
        do
            if [ -e "${HERE}${LIBDIR}${ARCHDIR}" ]
            then
                export LD_LIBRARY_PATH="${HERE}${LIBDIR}${ARCHDIR}/${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
            fi
            if [ -e "${HERE}${LIBDIR}${ARCHDIR}/qt4" ]
            then
                export QT_PLUGIN_PATH="${HERE}${LIBDIR}${ARCHDIR}/qt4/plugins/${QT_PLUGIN_PATH:+:$QT_PLUGIN_PATH}"
            fi
            if [ -e "${HERE}${LIBDIR}${ARCHDIR}/qt5" ]
            then
                export QT_PLUGIN_PATH="${HERE}${LIBDIR}${ARCHDIR}/qt5/plugins/${QT_PLUGIN_PATH:+:$QT_PLUGIN_PATH}"
            fi
        done
    done

    # new series of environment overrides to bundle GTK
    if [ "${APP_GTK_THEME:-}" != "" ]
    then
        if [ "${APP_GTK_THEME}" = "yes" ]; then APP_GTK_THEME="Clearlooks"; fi
        export GTK_DATA_PREFIX="${HERE}"
        export GTK_EXE_PREFIX="${HERE}"
        export GTK2_RC_FILES="${HERE}/usr/share/themes/${APP_GTK_THEME}/gtk-2.0/gtkrc"
    fi

    # thank you https://github.com/aferrero2707/appimage-helper-scripts
    export GDK_PIXBUF_MODULEDIR="${HERE}/usr/lib/gdk-pixbuf-2.0/loaders"
    export GDK_PIXBUF_MODULE_FILE="${HERE}/usr/lib/gdk-pixbuf-2.0/loaders.cache"
    export LD_LIBRARY_PATH="$LD_LIBRARY_PATH:$GDK_PIXBUF_MODULEDIR"
    export GTK_PATH="$APPDIR/usr/lib/gtk-2.0"
    export GTK_IM_MODULE_FILE="$APPDIR/usr/lib/gtk-2.0:$GTK_PATH"
    #export PANGO_LIBDIR="$APPDIR/usr/lib"
    #echo "PANGO_LIBDIR=${PANGO_LIBDIR}"


    EXEC=$(grep -e '^Exec=.*' "${HERE}"/*.desktop | head -n 1 | cut -d "=" -f 2 | cut -d " " -f 1)
    exec "${EXEC}" "$@"
}