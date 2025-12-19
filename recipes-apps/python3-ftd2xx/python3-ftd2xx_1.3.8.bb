
SUMMARY = "Python interface to ftd2xx.dll from FTDI using ctypes based on d2xx by Pablo Bleyer"
HOMEPAGE = "https://github.com/ftd2xx/ftd2xx"
AUTHOR = "Pablo Bleyer"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://LICENSE;md5=ceecbf5741792618dd094f047f1d04ca"

SRC_URI = "https://files.pythonhosted.org/packages/6f/81/d6acdc629eeba37be56e736378095b9f8c1daec990739a277b292c01883e/ftd2xx-1.3.8.tar.gz"
SRC_URI[md5sum] = "c55197bb9a7f64e11dc54d05a961b6fd"
SRC_URI[sha256sum] = "9de74ba300cfb1f3516af98e8097533d5d76692adfcc424694cc261b1b03e5e5"

S = "${WORKDIR}/ftd2xx-1.3.8"

RDEPENDS:${PN} = " libftd2xx "
DEPENDS += " python3-hatch-vcs-native python3-hatchling-native "

inherit python_setuptools_build_meta
