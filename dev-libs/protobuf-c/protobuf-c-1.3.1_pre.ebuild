# Copyright 1999-2018 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=6

inherit autotools multilib-minimal poly-c_ebuilds

REAL_PV="${MY_PV/_/-}"
REAL_P="${PN}-${REAL_PV}"

DESCRIPTION="Protocol Buffers implementation in C"
HOMEPAGE="https://github.com/protobuf-c/protobuf-c"
SRC_URI="https://github.com/${PN}/${PN}/releases/download/v${REAL_PV}/${REAL_P}.tar.gz"

LICENSE="BSD-2"
# Subslot == SONAME version
SLOT="0/1.0.0"
KEYWORDS="~alpha ~amd64 ~arm ~arm64 ~hppa ~ia64 ~mips ~ppc ~ppc64 ~s390 ~sparc ~x86"
IUSE="static-libs test"

RDEPEND=">=dev-libs/protobuf-2.6.0:0=[${MULTILIB_USEDEP}]"
DEPEND="${RDEPEND}
	virtual/pkgconfig[${MULTILIB_USEDEP}]"

S="${WORKDIR}/${REAL_P}"

src_prepare() {
	default
	if ! use test; then
		eapply "${FILESDIR}"/${PN}-1.3.0-no-build-tests.patch
	fi

	eautoreconf
}

multilib_src_configure() {
	ECONF_SOURCE="${S}" \
	econf \
		$(use_enable static-libs static)
}
