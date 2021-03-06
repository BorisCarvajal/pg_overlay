# Copyright 1999-2018 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6
WANT_AUTOCONF="2.1"
MOZ_ESR=""
MOZ_LIGHTNING_VER="6.2"
MOZ_LIGHTNING_GDATA_VER="4.4.1"

# This list can be updated using scripts/get_langs.sh from the mozilla overlay
MOZ_LANGS=(en en-GB en-US ru )

# Convert the ebuild version to the upstream mozilla version, used by mozlinguas
MOZ_PV="${PV/_beta/b}"

# Patches
PATCHTB="thunderbird-60.0-patches-0"
PATCHFF="firefox-60.0-patches-02"

MOZ_HTTP_URI="https://archive.mozilla.org/pub/${PN}/releases"

# ESR releases have slightly version numbers
if [[ ${MOZ_ESR} == 1 ]]; then
	MOZ_PV="${MOZ_PV}esr"
fi
MOZ_P="${PN}-${MOZ_PV}"

MOZCONFIG_OPTIONAL_JIT=1

inherit check-reqs flag-o-matic toolchain-funcs gnome2-utils mozcoreconf-v6 pax-utils xdg-utils autotools mozlinguas-v2

DESCRIPTION="Thunderbird Mail Client"
HOMEPAGE="http://www.mozilla.com/en-US/thunderbird/"

KEYWORDS="~amd64 ~x86 ~x86-fbsd ~amd64-linux ~x86-linux"
SLOT="0"
LICENSE="MPL-2.0 GPL-2 LGPL-2.1"
IUSE="bindist crypt dbus debug hardened lightning mozdom pulseaudio selinux startup-notification
	system-harfbuzz system-icu system-jpeg system-libevent system-sqlite system-libvpx wifi"
RESTRICT="!bindist? ( bindist )"

PATCH_URIS=( https://dev.gentoo.org/~{anarchy,axs,polynomial-c}/mozilla/patchsets/{${PATCHTB},${PATCHFF}}.tar.xz )
SRC_URI="${SRC_URI}
	${MOZ_HTTP_URI}/${MOZ_PV}/source/${MOZ_P}.source.tar.xz
	https://dev.gentoo.org/~axs/distfiles/lightning-${MOZ_LIGHTNING_VER}.tar.xz
	lightning? ( https://dev.gentoo.org/~axs/distfiles/gdata-provider-${MOZ_LIGHTNING_GDATA_VER}.tar.xz )
	${PATCH_URIS[@]}"

ASM_DEPEND=">=dev-lang/yasm-1.1"

CDEPEND="
	>=dev-libs/nss-3.28.3
	>=dev-libs/nspr-4.13.1
	>=app-text/hunspell-1.5.4:=
	dev-libs/atk
	dev-libs/expat
	>=x11-libs/cairo-1.10[X]
	>=x11-libs/gtk+-2.18:2
	>=x11-libs/gtk+-3.4.0:3
	x11-libs/gdk-pixbuf
	>=x11-libs/pango-1.22.0
	>=media-libs/libpng-1.6.34:0=[apng]
	>=media-libs/mesa-10.2:*
	media-libs/fontconfig
	>=media-libs/freetype-2.4.10
	kernel_linux? ( !pulseaudio? ( media-libs/alsa-lib ) )
	virtual/freedesktop-icon-theme
	dbus? ( >=sys-apps/dbus-0.60
		>=dev-libs/dbus-glib-0.72 )
	startup-notification? ( >=x11-libs/startup-notification-0.8 )
	>=x11-libs/pixman-0.19.2
	>=dev-libs/glib-2.26:2
	>=sys-libs/zlib-1.2.3
	>=virtual/libffi-3.0.10
	virtual/ffmpeg
	x11-libs/libX11
	x11-libs/libXcomposite
	x11-libs/libXdamage
	x11-libs/libXext
	x11-libs/libXfixes
	x11-libs/libXrender
	x11-libs/libXt
	system-icu? ( >=dev-libs/icu-59.1:= )
	system-jpeg? ( >=media-libs/libjpeg-turbo-1.2.1 )
	system-libevent? ( >=dev-libs/libevent-2.0:0= )
	system-sqlite? ( >=dev-db/sqlite-3.20.1:3[secure-delete,debug=] )
	system-libvpx? ( >=media-libs/libvpx-1.5.0:0=[postproc] )
	system-harfbuzz? ( >=media-libs/harfbuzz-1.4.2:0= >=media-gfx/graphite2-1.3.9-r1 )
	wifi? (	kernel_linux? ( >=sys-apps/dbus-0.60
			>=dev-libs/dbus-glib-0.72
			net-misc/networkmanager ) )
	kde? (	kde-apps/kdialog:5
			kde-misc/kmozillahelper )
	"

DEPEND="${CDEPEND}
	app-arch/zip
	app-arch/unzip
	>=sys-devel/binutils-2.16.1
	sys-apps/findutils
	pulseaudio? ( media-sound/pulseaudio )
	elibc_glibc? ( || (
		( >=dev-lang/rust-1.24.0[-extended(-)] >=dev-util/cargo-0.25.0 )
		>=dev-lang/rust-1.24.0[extended]
		( >=dev-lang/rust-bin-1.24.0 >=dev-util/cargo-0.25.0 )
	) )
	elibc_musl? ( || ( >=dev-lang/rust-1.24.0
		>=dev-util/cargo-0.25.0
	) )

	>=sys-devel/llvm-4.0.1
	>=sys-devel/clang-4.0.1
	amd64? ( ${ASM_DEPEND} virtual/opengl )
	x86? ( ${ASM_DEPEND} virtual/opengl )"

RDEPEND="${CDEPEND}
	pulseaudio? ( || ( media-sound/pulseaudio
		>=media-sound/apulse-0.1.9 ) )
	selinux? ( sec-policy/selinux-mozilla
		sec-policy/selinux-thunderbird
	)
	crypt? ( >=x11-plugins/enigmail-1.9.8.3-r1 )
"

S="${WORKDIR}/${MOZ_P%b[0-9]*}"

BUILD_OBJ_DIR="${S}/tbird"

pkg_setup() {
	moz_pkgsetup

	#export MOZILLA_DIR="${S}/mozilla"

	if ! use bindist ; then
		elog "You are enabling official branding. You may not redistribute this build"
		elog "to any users on your network or the internet. Doing so puts yourself into"
		elog "a legal problem with Mozilla Foundation"
		elog "You can disable it by emerging ${PN} _with_ the bindist USE-flag"
		elog
	fi

	addpredict /proc/self/oom_score_adj
}

pkg_pretend() {
	# Ensure we have enough disk space to compile
	CHECKREQS_DISK_BUILD="4G"
	check-reqs_pkg_setup
}

src_unpack() {
	unpack ${A}

	# Unpack language packs
	mozlinguas_src_unpack

	# this version of lightning is a .tar.xz, no xpi needed
	#xpi_unpack lightning-${MOZ_LIGHTNING_VER}.xpi

	# this version of gdata-provider is a .tar.xz , no xpi needed
	#use lightning && xpi_unpack gdata-provider-${MOZ_LIGHTNING_GDATA_VER}.xpi
}

src_prepare() {
	# Apply our patchset from firefox to thunderbird as well
	rm -f   "${WORKDIR}"/firefox/2007_fix_nvidia_latest.patch \
		"${WORKDIR}"/firefox/2005_ffmpeg4.patch \
		|| die
	eapply "${WORKDIR}/firefox"
	eapply "${FILESDIR}"/fix-setupterm.patch

	# Ensure that are plugins dir is enabled as default
	sed -i -e "s:/usr/lib/mozilla/plugins:/usr/lib/nsbrowser/plugins:" \
		"${S}"/xpcom/io/nsAppFileLocationProvider.cpp || die "sed failed to replace plugin path for 32bit!"
	sed -i -e "s:/usr/lib64/mozilla/plugins:/usr/lib64/nsbrowser/plugins:" \
		"${S}"/xpcom/io/nsAppFileLocationProvider.cpp || die "sed failed to replace plugin path for 64bit!"

	# Don't error out when there's no files to be removed:
	sed 's@\(xargs rm\)$@\1 -f@' \
		-i "${S}"/toolkit/mozapps/installer/packager.mk || die

	# Don't exit with error when some libs are missing which we have in
	# system.
	sed '/^MOZ_PKG_FATAL_WARNINGS/s@= 1@= 0@' \
		-i "${S}"/comm/mail/installer/Makefile.in || die

	# Apply our Thunderbird patchset
	pushd "${S}"/comm &>/dev/null || doe
	eapply "${WORKDIR}"/thunderbird

	# simulate old directory structure just in case it helps eapply_user
	ln -s .. mozilla || die
	# Allow user to apply any additional patches without modifing ebuild
	eapply_user
	# remove the symlink
	rm -f mozilla

	# Confirm the version of lightning being grabbed for langpacks is the same
	# as that used in thunderbird
	local THIS_MOZ_LIGHTNING_VER=$(${PYTHON} calendar/lightning/build/makeversion.py ${PV})
	if [[ ${MOZ_LIGHTNING_VER} != ${THIS_MOZ_LIGHTNING_VER} ]]; then
		eqawarn "The version of lightning used for localization differs from the version"
		eqawarn "in thunderbird.  Please update MOZ_LIGHTNING_VER in the ebuild from ${MOZ_LIGHTNING_VER}"
		eqawarn "to ${THIS_MOZ_LIGHTNING_VER}"
	fi

	popd &>/dev/null || die

	# OpenSUSE-KDE patchset
	use kde && for i in $(cat "${FILESDIR}/kde-opensuse/series");do eapply "${FILESDIR}/kde-opensuse/$i";done
	# Debian pacthes
	for i in $(cat "${FILESDIR}/debian-patchset/series");do eapply "${FILESDIR}/debian-patchset/$i";done

	eautoreconf old-configure.in
	# Ensure we run eautoreconf in spidermonkey to regenerate configure
	cd "${S}"/js/src || die
	eautoconf old-configure.in
}

src_configure() {
	MEXTENSIONS="default"

	####################################
	#
	# mozconfig, CFLAGS and CXXFLAGS setup
	#
	####################################

	mozconfig_init
	# common config components
	mozconfig_annotate 'system_libs' \
		--with-system-zlib \
		--with-system-bz2

	# Stylo is only broken on x86 builds
	use x86 && mozconfig_annotate 'Upstream bug 1341234' --disable-stylo

	# Must pass release in order to properly select linker
	mozconfig_annotate 'Enable by Gentoo' --enable-release

	# Must pass --enable-gold if using ld.gold
	if tc-ld-is-gold ; then
		mozconfig_annotate 'tc-ld-is-gold=true' --enable-gold
	else
		mozconfig_annotate 'tc-ld-is-gold=false' --disable-gold
	fi

	# It doesn't compile on alpha without this LDFLAGS
	use alpha && append-ldflags "-Wl,--no-relax"

	# Add full relro support for hardened
	use hardened && append-ldflags "-Wl,-z,relro,-z,now"

	# Modifications to better support ARM, bug 553364
	if use neon ; then
		mozconfig_annotate '' --with-fpu=neon
		mozconfig_annotate '' --with-thumb=yes
		mozconfig_annotate '' --with-thumb-interwork=no
	fi
	if [[ ${CHOST} == armv* ]] ; then
		mozconfig_annotate '' --with-float-abi=hard
		if ! use system-libvpx ; then
			sed -i -e "s|softfp|hard|" \
				"${S}"/media/libvpx/moz.build
		fi
	fi

	mozconfig_use_enable !bindist official-branding
	# Enable position independent executables
	mozconfig_annotate 'enabled by Gentoo' --enable-pie

	mozconfig_use_enable debug
	mozconfig_use_enable debug tests
	if ! use debug ; then
		mozconfig_annotate 'disabled by Gentoo' --disable-debug-symbols
	else
		mozconfig_annotate 'enabled by Gentoo' --enable-debug-symbols
	fi
	# These are enabled by default in all mozilla applications
	mozconfig_annotate '' --with-system-nspr --with-nspr-prefix="${SYSROOT}${EPREFIX}"/usr
	mozconfig_annotate '' --with-system-nss --with-nss-prefix="${SYSROOT}${EPREFIX}"/usr
	mozconfig_annotate '' --x-includes="${SYSROOT}${EPREFIX}"/usr/include \
		--x-libraries="${SYSROOT}${EPREFIX}"/usr/$(get_libdir)
        mozconfig_annotate '' --prefix="${EPREFIX}"/usr
        mozconfig_annotate '' --libdir="${EPREFIX}"/usr/$(get_libdir)
        mozconfig_annotate 'Gentoo default' --enable-system-hunspell
        mozconfig_annotate '' --disable-crashreporter
        mozconfig_annotate 'Gentoo default' --with-system-png
        mozconfig_annotate '' --enable-system-ffi
        mozconfig_annotate '' --disable-gconf
        mozconfig_annotate '' --with-intl-api
        mozconfig_annotate '' --enable-system-pixman
	# Instead of the standard --build= and --host=, mozilla uses --host instead
	# of --build, and --target intstead of --host.
	# Note, mozilla also has --build but it does not do what you think it does.
	# Set both --target and --host as mozilla uses python to guess values otherwise
	mozconfig_annotate '' --target="${CHOST}"
	mozconfig_annotate '' --host="${CBUILD:-${CHOST}}"
	if use system-libevent; then
		mozconfig_annotate '' --with-system-libevent="${SYSROOT}${EPREFIX}"/usr
	fi

	# skia has no support for big-endian platforms
	if [[ $(tc-endian) == "big" ]]; then
		mozconfig_annotate 'big endian target' --disable-skia
	else
		mozconfig_annotate '' --enable-skia
	fi

	# use the gtk3 toolkit (the only one supported at this point)
	mozconfig_annotate '' --enable-default-toolkit=cairo-gtk3

	mozconfig_use_enable startup-notification
	mozconfig_use_enable system-sqlite
	mozconfig_use_with system-jpeg
	mozconfig_use_with system-icu
	mozconfig_use_with system-libvpx
	mozconfig_use_with system-harfbuzz
	mozconfig_use_with system-harfbuzz system-graphite2
	mozconfig_use_enable pulseaudio
	# force the deprecated alsa sound code if pulseaudio is disabled
	if use kernel_linux && ! use pulseaudio ; then
		mozconfig_annotate '-pulseaudio' --enable-alsa
	fi


	# Other tb-specific settings
	mozconfig_annotate '' --with-user-appdir=.thunderbird

	mozconfig_annotate '' --enable-ldap
	if use hardened; then
		append-ldflags "-Wl,-z,relro,-z,now"
		mozconfig_use_enable hardened hardening
	fi

	# Settings
	mozconfig_annotate '' --enable-default-toolkit=cairo-gtk3
	mozconfig_annotate '' --enable-install-strip
	#mozconfig_annotate '' --enable-hardening
	mozconfig_annotate '' --enable-linker=gold
	mozconfig_annotate '' --enable-rust-simd
	mozconfig_annotate '' --enable-strip
	mozconfig_annotate '' --disable-crashreporter
	mozconfig_annotate '' --disable-updater

	mozlinguas_mozconfig

	# Bug #72667
	if use mozdom; then
		MEXTENSIONS="${MEXTENSIONS},inspector"
	fi

	mozconfig_annotate '' --enable-extensions="${MEXTENSIONS}"
	mozconfig_annotate '' --enable-calendar

	# Use an objdir to keep things organized.
	echo "mk_add_options MOZ_OBJDIR=${BUILD_OBJ_DIR}" >> "${S}"/.mozconfig
	echo "mk_add_options XARGS=/usr/bin/xargs" >> "${S}"/.mozconfig

	# Finalize and report settings
	mozconfig_final

	####################################
	#
	#  Configure and build
	#
	####################################

	# Disable no-print-directory
	MAKEOPTS=${MAKEOPTS/--no-print-directory/}

	if [[ $(gcc-major-version) -lt 4 ]]; then
		append-cxxflags -fno-stack-protector
	fi

	# workaround for funky/broken upstream configure...
	SHELL="${SHELL:-${EPREFIX}/bin/bash}" MOZ_NOSPAM=1 \
	./mach configure || die
}

src_compile() {
	MOZ_MAKE_FLAGS="${MAKEOPTS}" SHELL="${SHELL:-${EPREFIX}/bin/bash}" MOZ_NOSPAM=1 \
	./mach build --verbose || die
}

src_install() {
	declare emid
	cd "${BUILD_OBJ_DIR}" || die

	# Pax mark xpcshell for hardened support, only used for startupcache creation.
	pax-mark m "${BUILD_OBJ_DIR}"/dist/bin/xpcshell

	# Copy our preference before omnijar is created.
	cp "${FILESDIR}"/thunderbird-gentoo-default-prefs.js-2 \
		"${BUILD_OBJ_DIR}/dist/bin/defaults/pref/all-gentoo.js" \
		|| die


        # set dictionary path, to use system hunspell
        echo "pref(\"spellchecker.dictionary_path\", \"${EPREFIX}/usr/share/myspell\");" \
                >>"${BUILD_OBJ_DIR}/dist/bin/defaults/pref/all-gentoo.js" || die

        # force the graphite pref if system-harfbuzz is enabled, since the pref cant disable it
        if use system-harfbuzz ; then
                echo "sticky_pref(\"gfx.font_rendering.graphite.enabled\",true);" \
	                >>"${BUILD_OBJ_DIR}/dist/bin/defaults/pref/all-gentoo.js" || die
        fi

        # force cairo as the canvas renderer on platforms without skia support
        if [[ $(tc-endian) == "big" ]] ; then
                echo "sticky_pref(\"gfx.canvas.azure.backends\",\"cairo\");" \
	                >>"${BUILD_OBJ_DIR}/dist/bin/defaults/pref/all-gentoo.js" || die
                echo "sticky_pref(\"gfx.content.azure.backends\",\"cairo\");" \
	                >>"${BUILD_OBJ_DIR}/dist/bin/defaults/pref/all-gentoo.js" || die
        fi

	# dev-db/sqlite does not have FTS3_TOKENIZER support.
	# gloda needs it to function, and bad crashes happen when its enabled and doesn't work
	if use system-sqlite ; then
		echo "sticky_pref(\"mailnews.database.global.indexer.enabled\", false);" \
			>>"${BUILD_OBJ_DIR}/dist/bin/defaults/pref/all-gentoo.js" || die
	fi

	if use kde ; then
		cat "${FILESDIR}"/kde-opensuse/kde.js-1 >> \
		"${BUILD_OBJ_DIR}/dist/bin/defaults/pref/all-gentoo.js" \
		|| die
	fi

	cd "${S}" || die
	MOZ_MAKE_FLAGS="${MAKEOPTS}" SHELL="${SHELL:-${EPREFIX}/bin/bash}" MOZ_NOSPAM=1 \
	DESTDIR="${D}" ./mach install

	# Install language packs
	mozlinguas_src_install

	local size sizes icon_path icon
	if ! use bindist; then
		icon_path="${S}/comm/mail/branding/thunderbird"
		icon="${PN}-icon"

		domenu "${FILESDIR}"/icon/${PN}.desktop
	else
		icon_path="${S}/comm/mail/branding/nightly"
		icon="${PN}-icon-unbranded"

		newmenu "${FILESDIR}"/icon/${PN}-unbranded.desktop \
			${PN}.desktop

		sed -i -e "s:Mozilla\ Thunderbird:EarlyBird:g" \
			"${ED}"/usr/share/applications/${PN}.desktop
	fi

	# Install a 48x48 icon into /usr/share/pixmaps for legacy DEs
	newicon "${icon_path}"/default48.png "${icon}".png
	# Install icons for menu entry
	sizes="16 22 24 32 48 256"
	for size in ${sizes}; do
		newicon -s ${size} "${icon_path}/default${size}.png" "${icon}.png"
	done

	local emid
	# stage extra locales for lightning and install over existing
	rm -f "${ED}"/${MOZILLA_FIVE_HOME}/distribution/extensions/${emid}.xpi || die
	mozlinguas_xpistage_langpacks "${BUILD_OBJ_DIR}"/dist/bin/distribution/extensions/${emid} \
		"${WORKDIR}"/lightning-${MOZ_LIGHTNING_VER} lightning calendar

	emid='{e2fda1a4-762b-4020-b5ad-a41df1933103}'
	mkdir -p "${T}/${emid}" || die
	cp -RLp -t "${T}/${emid}" "${BUILD_OBJ_DIR}"/dist/bin/distribution/extensions/${emid}/* || die
	insinto ${MOZILLA_FIVE_HOME}/distribution/extensions
	doins -r "${T}/${emid}"

	if use lightning; then
		# move lightning out of distribution/extensions and into extensions for app-global install
		mv "${ED}"/${MOZILLA_FIVE_HOME}/{distribution,}/extensions/${emid} || die

		# stage extra locales for gdata-provider and install app-global
		mozlinguas_xpistage_langpacks "${BUILD_OBJ_DIR}"/dist/xpi-stage/gdata-provider \
			"${WORKDIR}"/gdata-provider-${MOZ_LIGHTNING_GDATA_VER}
		emid='{a62ef8ec-5fdc-40c2-873c-223b8a6925cc}'
		mkdir -p "${T}/${emid}" || die
		cp -RLp -t "${T}/${emid}" "${BUILD_OBJ_DIR}"/dist/xpi-stage/gdata-provider/* || die
		insinto ${MOZILLA_FIVE_HOME}/extensions
		doins -r "${T}/${emid}"
	fi

	# Required in order to use plugins and even run thunderbird on hardened.
	pax-mark pm "${ED}"${MOZILLA_FIVE_HOME}/{thunderbird,thunderbird-bin,plugin-container}
}

pkg_preinst() {
	gnome2_icon_savelist
}

pkg_postinst() {
	xdg_desktop_database_update
	gnome2_icon_cache_update

	if use crypt; then
		elog
		elog "USE=crypt will be dropped from thunderbird with version 52.6.0 as"
		elog "x11-plugins/enigmail-1.9.8.3-r1 and above is now a fully standalone"
		elog "package.  For continued enigmail support in thunderbird please add"
		elog "x11-plugins/enigmail to your @world set."
	fi

	elog
	elog "If you experience problems with plugins please issue the"
	elog "following command : rm \${HOME}/.thunderbird/*/extensions.sqlite ,"
	elog "then restart thunderbird"

	if ! use lightning; then
		elog
		elog "If calendar fails to show up in extensions please open config editor"
		elog "and set extensions.lastAppVersion to 38.0.0 to force a reload. If this"
		elog "fails to show the calendar extension after restarting with above change"
		elog "please file a bug report."
	fi
}

pkg_postrm() {
	xdg_desktop_database_update
	gnome2_icon_cache_update
}
