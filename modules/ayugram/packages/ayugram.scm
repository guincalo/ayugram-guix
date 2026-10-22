;;; ayugram-guix --- AyuGram Desktop for GNU Guix
;;;
;;; This file is free software; you can redistribute it and/or modify it
;;; under the terms of the GNU General Public License as published by
;;; the Free Software Foundation; either version 3 of the License, or (at
;;; your option) any later version.
;;;
;;; Based on the telegram-desktop package of GNU Guix,
;;; gnu/packages/telegram.scm.

(define-module (ayugram packages ayugram)
  #:use-module (gnu packages)
  #:use-module (gnu packages aidc)
  #:use-module (gnu packages animation)
  #:use-module (gnu packages assembly)
  #:use-module (gnu packages audio)
  #:use-module (gnu packages autotools)
  #:use-module (gnu packages boost)
  #:use-module (gnu packages c)
  #:use-module (gnu packages check)
  #:use-module (gnu packages cmake)
  #:use-module (gnu packages compression)
  #:use-module (gnu packages cpp)
  #:use-module (gnu packages crypto)
  #:use-module (gnu packages digest)
  #:use-module (gnu packages documentation)
  #:use-module (gnu packages fcitx5)
  #:use-module (gnu packages freedesktop)
  #:use-module (gnu packages gl)
  #:use-module (gnu packages glib)
  #:use-module (gnu packages gnome)
  #:use-module (gnu packages gnupg)
  #:use-module (gnu packages gperf)
  #:use-module (gnu packages gtk)
  #:use-module (gnu packages hunspell)
  #:use-module (gnu packages image)
  #:use-module (gnu packages kde-frameworks)
  #:use-module (gnu packages language)
  #:use-module (gnu packages libevent)
  #:use-module (gnu packages linux)
  #:use-module (gnu packages llvm)
  #:use-module (gnu packages lua)
  #:use-module (gnu packages lxqt)
  #:use-module (gnu packages messaging)
  #:use-module (gnu packages perl)
  #:use-module (gnu packages php)
  #:use-module (gnu packages pkg-config)
  #:use-module (gnu packages protobuf)
  #:use-module (gnu packages pulseaudio)
  #:use-module (gnu packages python)
  #:use-module (gnu packages python-check)
  #:use-module (gnu packages python-web)
  #:use-module (gnu packages python-xyz)
  #:use-module (gnu packages qt)
  #:use-module (gnu packages readline)
  #:use-module (gnu packages rust)
  #:use-module (gnu packages security-token)
  #:use-module (gnu packages telegram)
  #:use-module (gnu packages telephony)
  #:use-module (gnu packages textutils)
  #:use-module (gnu packages tls)
  #:use-module (gnu packages video)
  #:use-module (gnu packages web)
  #:use-module (gnu packages webkit)
  #:use-module (gnu packages xdisorg)
  #:use-module (gnu packages xiph)
  #:use-module (gnu packages xorg)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (guix packages)
  #:use-module (guix gexp)
  #:use-module (guix git-download)
  #:use-module (guix build-system gnu)
  #:use-module (guix build-system qt)
  #:use-module (guix utils))

;; These two lines are rewritten by the update workflow.
(define %ayugram-version "7.2.9")
(define %ayugram-hash "1y93sa7nbyh034ya0haymqxpynkwwjvi8kya1jh9lx6nwwkmcmi6")

;; Not exported by (gnu packages telegram).
(define tde2e (@@ (gnu packages telegram) tde2e))

;; Rust Lottie renderer that replaced rlottie in tdesktop 7.x.  Built as a
;; static library with the C API, as upstream's Linux build does.
(define-public tlottie-for-telegram-desktop
  (let ((commit "31f1b542f88e7b4be9a01e749920d857535fc715")
        (revision "0"))
    (hidden-package
     (package
       (name "tlottie-for-telegram-desktop")
       (version (git-version "0.1.0" revision commit))
       (source
        (origin
          (method git-fetch)
          (uri (git-reference
                (url "https://github.com/dkaraush/tlottie")
                (commit commit)))
          (file-name (git-file-name name version))
          (sha256
           (base32 "0v3vj6ifgssipcackpajy7p80mscp1c7pa86hcnphkfqaz8l3i16"))
          ;; From desktop-app/patches, as applied by upstream's build.
          (patches
           (list (local-file
                  (canonicalize-path
                   (search-path
                    %load-path
                    "ayugram/packages/patches/tlottie-telegram-desktop.patch")))))))
       (build-system gnu-build-system)
       (arguments
        (list
         #:tests? #f
         #:phases
         #~(modify-phases %standard-phases
             (replace 'configure
               (lambda _
                 ;; The C API needs no crates; drop the optional no-std and
                 ;; wasm dependencies so cargo never asks for a registry.
                 (substitute* "Cargo.toml"
                   (("^hashbrown = .*$") "")
                   (("^dlmalloc = .*$") "")
                   (("^no-std = .*$") ""))
                 (delete-file "Cargo.lock")
                 ;; __cpuid is a safe function only since Rust 1.94.
                 (substitute* "src/renderer/cpu/simd/cpuid.rs"
                   (("(__cpuid(_count)?\\([^)]*\\))" call)
                    (string-append "unsafe { " call " }")))
                 (setenv "CARGO_HOME" (string-append (getcwd) "/.cargo"))))
             (replace 'build
               (lambda _
                 (invoke "cargo" "rustc" "--offline" "--lib" "--release"
                         "--features" "c-api"
                         "--crate-type" "staticlib")))
             (replace 'install
               (lambda _
                 (install-file "target/release/libtlottie.a"
                               (string-append #$output "/lib"))
                 (install-file "include/tlottie.h"
                               (string-append #$output "/include/tlottie")))))))
       (native-inputs (list rust (list rust "cargo")))
       (home-page "https://github.com/dkaraush/tlottie")
       (synopsis "Lottie renderer used by Telegram Desktop")
       (description "tlottie is a Lottie animation renderer written in Rust,
used by Telegram Desktop for stickers and emoji animations.")
       (license license:expat)))))

(define-public ayugram-desktop
  (package
    (inherit telegram-desktop)
    (name "ayugram-desktop")
    (version %ayugram-version)
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
             (url "https://github.com/AyuGram/AyuGramDesktop")
             (commit (string-append "v" version))
             (recursive? #t)))
       (file-name (git-file-name name version))
       (sha256 (base32 %ayugram-hash))))
    (arguments
     (list #:qtbase qtbase
           #:tests? #f
           ;; Keep going so one CI run shows every compile error.
           #:make-flags #~(list "-k")
           #:imported-modules
           `(,@%qt-build-system-modules
             (guix build glib-or-gtk-build-system))
           #:modules
           '((guix build qt-build-system)
             ((guix build glib-or-gtk-build-system)
              #:prefix glib-or-gtk:)
             (guix build utils))
           #:configure-flags
           #~(list
              "-DCMAKE_BUILD_TYPE=Release"
              ;; Same credentials as Guix's telegram-desktop (official snap).
              "-DTDESKTOP_API_ID=611335"
              "-DTDESKTOP_API_HASH=d524b414d21f4d37f08684c1df41ac9c"
              "-DDESKTOP_APP_DISABLE_CRASH_REPORTS=ON"
              "-DDESKTOP_APP_DISABLE_AUTOUPDATE=ON"
              "-DDESKTOP_APP_DISABLE_QT_PLUGINS=ON")
           #:phases
           #~(modify-phases %standard-phases
               ;; The recursive checkout already carries every submodule
               ;; (lib_*, cmake helpers, bundled cppgir, ThirdParty).
               ;; Libraries Guix provides are found through pkg-config and
               ;; CMake; the rest falls back to the bundled copies.
               (add-after 'unpack 'fix-sources
                 (lambda _
                   ;; The fixes Guix applies to telegram-desktop.
                   (substitute* "Telegram/lib_tl/tl/tl_basic_types.h"
                     (("#include <QtCore/QVector>")
                      "#include <QtCore/QVector>\n#include <cstring>"))
                   (substitute*
                       "Telegram/SourceFiles/platform/linux/current_geo_location_linux.cpp"
                     (("#include <gio/gio.h>")
                      "#include <QGuiApplication>\n#include <gio/gio.h>"))
                   (substitute* "Telegram/lib_webview/webview/webview_interface.h"
                     (("constexpr ") ""))
                   ;; QAccessible::Attribute::Orientation needs Qt 6.10;
                   ;; Guix has 6.9.  Report no attributes instead.
                   (substitute* "Telegram/lib_ui/ui/accessible/ui_accessible_widget.cpp"
                     (("result\\.append\\(QAccessible::Attribute::Orientation\\);")
                      "")
                     (("key == QAccessible::Attribute::Orientation")
                      "false"))))
               (add-after 'install 'glib-or-gtk-compile-schemas
                 (assoc-ref glib-or-gtk:%standard-phases
                            'glib-or-gtk-compile-schemas))
               (add-after 'glib-or-gtk-compile-schemas 'glib-or-gtk-wrap
                 (assoc-ref glib-or-gtk:%standard-phases 'glib-or-gtk-wrap)))))
    (native-inputs
     (list cpp-ada-url-parser
           `(,glib "bin")
           gobject-introspection
           `(,gtk+ "bin")
           pkg-config
           python-wrapper
           qtshadertools))
    (inputs
     (list abseil-cpp-20250127
           alsa-lib
           boost
           c++-gsl
           crc32c
           expected-lite
           fcitx5-qt
           ffmpeg
           glib
           glibmm-2.76
           gtk+
           hime
           hunspell
           kcoreaddons
           kimageformats
           libavif
           libexpected
           libfido2
           libjpeg-turbo
           libjxl
           libvpx
           libxcb
           lz4
           minizip
           nimf
           openal
           openh264
           openssl
           opus
           plasma-wayland-protocols
           pulseaudio
           protobuf
           qrcodegen-cpp
           qtdeclarative
           qtimageformats
           qtsvg
           qtwayland
           range-v3
           rnnoise
           tde2e
           tlottie-for-telegram-desktop
           wayland
           wayland-protocols
           webkitgtk-for-gtk3
           webrtc-for-telegram-desktop
           xcb-util-keysyms
           xxhash
           zlib))
    (synopsis "Telegram Desktop fork with ghost mode and message history")
    (description "AyuGram Desktop is a fork of Telegram Desktop that adds
ghost mode, a local history of deleted and edited messages, and other
client-side features.")
    (home-page "https://github.com/AyuGram/AyuGramDesktop")
    (license
     (list license:lgpl3
           license:gpl3+))))
