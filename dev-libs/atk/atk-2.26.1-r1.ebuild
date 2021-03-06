# Copyright 1999-2018 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6
inherit gnome-meson multilib-minimal

DESCRIPTION="GTK+ & GNOME Accessibility Toolkit"
HOMEPAGE="https://wiki.gnome.org/Accessibility"

LICENSE="LGPL-2+"
SLOT="0"
KEYWORDS="~alpha ~amd64 ~arm ~arm64 ~hppa ~ia64 ~mips ~ppc ~ppc64 ~s390 ~sh ~sparc ~x86 ~amd64-fbsd ~x86-fbsd ~amd64-linux ~arm-linux ~x86-linux ~ppc-macos ~x64-macos ~x86-macos ~sparc-solaris ~sparc64-solaris ~x64-solaris ~x86-solaris ~x86-winnt"
IUSE="+introspection nls test"

RDEPEND="
	>=dev-libs/glib-2.34.3:2[${MULTILIB_USEDEP}]
	introspection? ( >=dev-libs/gobject-introspection-1.32:= )
"
DEPEND="${RDEPEND}
	>=dev-lang/perl-5
	dev-util/gtk-doc-am
	>=virtual/pkgconfig-0-r1[${MULTILIB_USEDEP}]
	nls? ( >=sys-devel/gettext-0.19.2 )
"

src_prepare() {
	gnome-meson_src_prepare

	if ! use test; then
		# don't waste time building tests (bug #226353)
		sed 's/^\(SUBDIRS =.*\)tests\(.*\)$/\1\2/' -i Makefile.am Makefile.in \
			|| die "sed failed"
	fi

	# Building out of sources fails, https://bugzilla.gnome.org/show_bug.cgi?id=752507
	#multilib_copy_sources
	eapply_user
}

multilib_src_configure() {
#	ECONF_SOURCE=${S} \
	gnome-meson_src_configure \
		-Denable_docs=false \
		-Ddisable_introspection=$(multilib_native_usex introspection false true)

}

multilib_src_compile() {
	gnome-meson_src_compile
}

multilib_src_test() {
	meson_src_test
}

multilib_src_install() {
	gnome-meson_src_install
}
