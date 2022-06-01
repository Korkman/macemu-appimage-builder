#! /bin/bash
{
    set -eu
    
    LIBDIR=/usr/lib/
    for ARCHDIR in x86_64-linux-gnu i386-linux-gnu arm-linux-gnueabi arm-linux-gnueabihf aarch64-linux-gnu lib64 lib32
    do
        if [ -e "${LIBDIR}${ARCHDIR}" ]
        then
            echo "${ARCHDIR}/" > /ARCHDIR
            break
        fi
    done
    
    if [ ! -e /ARCHDIR ]
    then
        ls /usr/lib
        echo "Archdir not found - is this correct?"
        exit 4
    fi
    
    exit
}
