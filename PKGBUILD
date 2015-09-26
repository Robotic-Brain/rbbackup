# This is an example PKGBUILD file. Use this as a start to creating your own,
# and remove these comments. For more information, see 'man PKGBUILD'.
# NOTE: Please fill out the license field for your package! If it is unknown,
# then please put 'unknown'.

# The following guidelines are specific to BZR, GIT, HG and SVN packages.
# Other VCS sources are not natively supported by makepkg yet.

# Maintainer: Robotic-Brain <github@roboticbrain.de>
pkgname=rbbackup-git
pkgver=0.0.1
pkgrel=1
pkgdesc="An incremental backup script"
arch=('any')
url=""
license=('GPL3')
groups=()
depends=('rsync')
makedepends=('git')
provides=("${pkgname%-git}")
conflicts=("${pkgname%-git}")
replaces=()
backup=()
options=()
install=
source=('FOLDER::VCS+URL#FRAGMENT')
noextract=()
md5sums=('SKIP')

pkgver() {
	cd "$srcdir/${pkgname%-git}"
	printf "%s" "$(git describe --long | sed 's/\([^-]*-\)g/r\1/;s/-/./g')"
}

check() {
	cd "$srcdir/${pkgname%-git}"
	cd scripts
	./testRunner.sh realRun.sh
	./testRunner.sh dryRun.sh
	./testRunner.sh 2ndRun.sh
	./testRunner.sh argument_validation.sh
}

package() {
	cd "$srcdir/${pkgname%-git}"
	cp "scripts/rbbackup.sh" "$pkgdir/usr/bin/rbbackup"
	cp -a "config/rbbackup.d" "$pkgdir/etc/"
	cp "config/rbbackup.conf" "$pkgdir/etc/"
}
