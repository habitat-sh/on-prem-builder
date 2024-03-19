pkg_name=pkg-tool
pkg_origin=habitat
pkg_version="0.1.0"
pkg_maintainer="The Habitat Maintainers <humans@habitat.sh>"
pkg_deps=(core/glibc/2.34 core/gcc-libs/9.4.0)
pkg_build_deps=(core/curl core/patchelf)
pkg_bin_dirs=(bin)
pkg_description="lists all on prem builder packages and their dependencies in an origin."

do_build() {
  return 0
}

do_install() {
  cp "$PLAN_CONTEXT/pkg-tool" "${pkg_prefix}/bin/pkg-tool"
}

do_strip() {
  return 0
}
