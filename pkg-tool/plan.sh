pkg_name=pkg-tool
pkg_origin=habitat
pkg_version="0.1.0"
pkg_maintainer="The Habitat Maintainers <humans@habitat.sh>"
pkg_build_deps=(core/go21)
pkg_bin_dirs=(bin)
pkg_description="lists all on prem builder packages and their dependencies in an origin."

do_build() {
  return 0
}

do_install() {
  CGO_ENABLED=0 go build -installsuffix 'static' -o "$pkg_prefix"/bin/pkg-tool main.go
}

do_strip() {
  return 0
}
