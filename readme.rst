====================================
Drake: A Runtime Library for gcc-Ada
====================================

What's this?
------------

Drake is a runtime library written completely in Ada to replace the GNAT runtime.

A primary project goal is re-implementing the `Predefined Language Environment`_ in Annex A,
for real world applications.

Please, read the wiki_ for more information.

Environment
-----------

- Darwin (from 10.5, x86, 32bit/64bit)
- FreeBSD (from 8, x86, 32bit/64bit)
- Linux (from 2.6, x86, 32bit/64bit)
- Windows (from XP, x86, 32bit/64bit) [#experimental]_

Required tools and libraries
----------------------------

gcc
 Use of gcc_ instead of the *GNAT GPL Edition* is required.
translated headers
 Install headmaster_ to convert the headers on your system,
 or download them from `pre-translated headers page`_.

Downloads
---------

Clone this repository. ::

 $ git clone git://github.com/ytomino/drake.git

The *master* branch is targeted for gcc 6.
Please checkout a branch corresponds to the version of your gcc. ::

 $ git checkout gcc-5 # for example

How to build
------------

Run the ``make`` command with some variables, specify a translated headers path
to ``IMPORTDIR`` and a destination path to ``RTSDIR``. ::

 $ make IMPORTDIR=... RTSDIR=...

Read the `build page`_ for details.

A short example
---------------

1. Prepare the source code of a sample application. ::
   
    $ cat > hello.adb
    with Ada.Text_IO;
    procedure hello is
    begin
       Ada.Text_IO.Put_Line ("Hello, Drake runtime!");
    end hello;
    ^D

2. Build drake. ::
   
    $ make -C ~/Downloads/drake/source \ # drake source path
      IMPORTDIR=~/Downloads/i686-apple-darwin9 \ # translated headers path
      RTSDIR=$PWD/rts-drake # destination path

3. Build the sample application. ::
   
    $ gnatmake hello.adb --RTS=rts-drake

   Specify ``--RTS`` option of ``gnatmake`` to use the alternative runtime.

4. Run the sample application. ::
   
    $ ./hello
    Hello, Drake runtime!

Limitations
-----------

Many features are unimplemented and there are several intentional ACATS violations for usability.
See `incompatibility features page`_.

.. _`Predefined Language Environment`: http://www.adaic.org/resources/add_content/standards/12rm/html/RM-A.html
.. _gcc: http://gcc.gnu.org/
.. _headmaster: http://github.com/ytomino/headmaster
.. _wiki: https://github.com/ytomino/drake/wiki
.. _`pre-translated headers page`: https://github.com/ytomino/drake/wiki/Pre-translated-headers
.. _`build page`: https://github.com/ytomino/drake/wiki/Build
.. _`incompatibility features page`: https://github.com/ytomino/drake/wiki/Incompatibility
.. [#experimental] 64bit Windows support is under construction,
                   limited and experimental.
