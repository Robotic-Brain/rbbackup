# -*- mode: shell-script; -*-
# Maintainer: Robotic-Brain <github@roboticbrain.de>
pkgname=rbbackup-git
pkgver=0.0.2
pkgrel=1
pkgdesc="An incremental backup script"
arch=('any')
url="https://github.com/Robotic-Brain/rbbackup"
license=('GPL3')
groups=()
depends=('rsync' 'gzip')
makedepends=('git')
provides=("${pkgname%-git}")
conflicts=("${pkgname%-git}")
replaces=()
backup=('etc/rbbackup.conf' 'etc/rbbackup.d/rsync_filter.txt')
options=()
install=
source=(
	'git+https://github.com/Robotic-Brain/rbbackup.git'
	'git+https://github.com/kward/shunit2.git'
)
noextract=()
md5sums=(
	'SKIP'
	'SKIP'
)

pkgver() {
	cd "$srcdir/${pkgname%-git}"
	# TODO: Use alternate method if no tags are available
	printf "%s" "$(git describe --long --first-parent | sed 's/\([^-]*-\)g/r\1/;s/-/./g')"
}

check() {
	cd "$srcdir/${pkgname%-git}"
	git submodule init
	git config submodule.external/shunit2.url $srcdir/shunit2
	git submodule update
	cd scripts
	./testRunner.sh realRun.sh >/dev/null
	./testRunner.sh dryRun.sh >/dev/null
	./testRunner.sh 2ndRun.sh >/dev/null
	./testRunner.sh argument_validation.sh >/dev/null
}

package() {
	cd "$srcdir/${pkgname%-git}"
	mkdir -p "$pkgdir/usr/bin"
	mkdir -p "$pkgdir/etc"
	cp "scripts/rbbackup.sh" "$pkgdir/usr/bin/rbbackup"
	cp "config/rbbackup.conf" "$pkgdir/etc/"
	cd "config/rbbackup.d"
	find . -type d -exec mkdir -p "$pkgdir/etc/rbbackup.d/{}" \;
	find . -type f -exec cp "{}" "$pkgdir/etc/rbbackup.d" \;
}
