#!/bin/sh
SOURCE="$1"
fail() {
  echo "$1" >&2
  exit 1
}
verbose() {
  echo "$@"
  "$@"
}
grep ^File Install_00/Install.ini|sed 's/","/ /;s/"//g;s|\\|/|'|while read _ _ lname rname; do
  test -f "${SOURCE}/${rname}" || fail "${rname} not found"
  verbose cp "${SOURCE}/${rname}" "Install_00/${lname}"
done
