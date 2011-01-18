WOMBLE - INSTALL
================

    These are very temporary instructions how to get the Womble
    code installed with narwhal.  Note that this will change;
    eventually Womble should just become a tusk package.

BASIC INSTALL
-------------

First, make a directory somewhere to hold the project and set 
an environment variable $WOMBLE.  This directory will
hold a narwhal environment.

    mkdir ~/Projects/Womble
    export WOMBLE=~/Projects/Womble

and inside that, make a local/ directory

    cd ${WOMBLE}
    mkdir local
    cd local

Now check out and activate narwhal:

    git clone git://github.com/280north/narwhal.git
    source narwhal/bin/activate

and install required packages:

    tusk install objective-j
    tusk install jack
    tusk install cappuccino
    tusk install jdbc-sqlite3
    tusk install jdbc-sqlite
    tusk install sqlite-jdbc
    tusk install ojunit

Now check out Womble:

    git clone git@github.com:quile/Womble.git

and set up the environment:

    export PATH=$PATH:${WOMBLE}/local/narwhal/bin:${WOMBLE}/bin
    export OBJJ_INCLUDE_PATHS=${WOMBLE}/Womble:${WOMBLE}/Womble/WM:${WOMBLE}/Womble/t

Now you should be able to run the tests.  I get a few deprecation errors now, but
all the tests pass.  There is a fair amount of log spewage;  even the ones that
say <ERROR> are actually OK: it's a test of the logging module.

    jake test
    
==========================

Tip: Set up an alias in your .bash_profile so you can just type

    Womble

and it will set up all your paths, etc:

    function Womble() {
        export PS1="<Womble \w>\$ "
        export WOMBLE=${HOME}/LocalProjects/Womble
        export PATH=$PATH:${WOMBLE}/local/narwhal/bin:${WOMBLE}/bin
        export OBJJ_INCLUDE_PATHS=${WOMBLE}/Womble:${WOMBLE}/Womble/WM:${WOMBLE}/t
        cd ${WOMBLE}
    }
