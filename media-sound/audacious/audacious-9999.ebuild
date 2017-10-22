# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=5
inherit autotools eutils git-r3 l10n

DESCRIPTION="Audacious Player - Your music, your way, no exceptions"
HOMEPAGE="http://audacious-media-player.org/"
EGIT_REPO_URI="https://github.com/${PN}-media-player/${PN}.git"

SRC_URI="mirror://gentoo/gentoo_ice-xmms-0.2.tar.bz2"

LICENSE="BSD-2"
SLOT="0"
KEYWORDS=""

IUSE="gtk3 nls qt5"
REQUIRED_USE="
	^^ ( gtk3 qt5 )
"
DOCS="AUTHORS"

RDEPEND=">=dev-libs/dbus-glib-0.60
	>=dev-libs/glib-2.28
	>=x11-libs/cairo-1.2.6
	>=x11-libs/pango-1.8.0
	virtual/freedesktop-icon-theme
	gtk3? ( x11-libs/gtk+:3 )
	qt5? ( dev-qt/qtcore:5
	      dev-qt/qtgui:5
	      dev-qt/qtwidgets:5 )"

DEPEND="${RDEPEND}
	virtual/pkgconfig
	nls? ( dev-util/intltool )"

PDEPEND="~media-plugins/audacious-plugins-${PV}"

src_unpack() {
	default
	if use !gtk3; then
		EGIT_BRANCH="master"
		EGIT_COMMIT="$EGIT_BRANCH"
		git-r3_src_unpack
	else
		EGIT_BRANCH="master-gtk3"
		EGIT_COMMIT="$EGIT_BRANCH"		
		git-r3_src_unpack
	fi
}

src_prepare() {
	eautoreconf

	rm_loc() {
		rm -vf "po/${1}.po" || die
		sed -i s/${1}.po// po/Makefile || die
	}
	l10n_find_plocales_changes po "" ".po"
	l10n_for_each_disabled_locale_do rm_loc
}

src_configure() {
	if use gtk3 ;then
		gtk="--enable-gtk"
	else
		gtk="--disable-gtk"
	fi
	# D-Bus is a mandatory dependency, remote control,
	# session management and some plugins depend on this.
	# Building without D-Bus is *unsupported* and a USE-flag
	# will not be added due to the bug reports that will result.
	# Bugs #197894, #199069, #207330, #208606
	econf \
		--enable-dbus \
		${gtk} \
		$(use_enable nls) \
		$(use_enable qt5 qt)
}

src_install() {
	default

	# Gentoo_ice skin installation; bug #109772
	insinto /usr/share/audacious/Skins/gentoo_ice
	doins "${WORKDIR}"/gentoo_ice/*
	docinto gentoo_ice
	dodoc "${WORKDIR}"/README
}
