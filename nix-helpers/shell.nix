{
  pkgs ? import <nixpkgs> { },
  ...
}:

with pkgs;
mkShell {
  buildInputs = [
    gnat
    florist
    gnumake
    autoconf-archive
    autoconf
    autoreconfHook
    automake
    libtool
  ];

  shellHook = ''

    #
    # Sorts Mill Autoconf Archive. This may not yet be packaged for Nix.
    #
    # See https://bitbucket.org/sortsmill/sortsmill-autoconf-archive
    #
    # Here I include the autoconf macros directly from my uninstalled
    # sources, rather than from an installed aclocal directory.
    #
    sortsmill_autoconf_archive=$HOME/src/sortsmill/sortsmill-autoconf-archive

    export ac_cv_build=x86_64-unknown-linux-gnu
    export ac_cv_host=x86_64-unknown-linux-gnu
    export ac_cv_target=x86_64-unknown-linux-gnu
    export ACLOCAL_PATH="$ACLOCAL_PATH''${ACLOCAL_PATH+:}$sortsmill_autoconf_archive:${autoconf-archive}/aclocal"
    export PATH="${gnat}/bin:${gnumake}/bin:${autoconf}/bin:${autoreconfHook}/bin:${automake117x}/bin:${libtool}/bin:$PATH"

    cp -R "${florist}"/floristlib .
    chmod -R +w floristlib
    export FLORISTLIB=`pwd`/floristlib
  '';
}
