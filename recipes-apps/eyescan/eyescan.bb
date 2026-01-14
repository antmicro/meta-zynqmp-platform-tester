SUMMARY = "Connect to the DAC38J8x using JTAG and perform eyescan test"
LICENSE = "Apache-2.0"

SRC_URI = "git://github.com/antmicro/dac-eyescan-test.git;branch=main;protocol=http"
SRCREV = "b3a672514a6d62c0016a0399fecb350ae8fb5504"

LIC_FILES_CHKSUM = "file://LICENSE;md5=86d3f3a95c324c9479bd8986968f4327"

S = "${WORKDIR}/git"

RDEPENDS:${PN} = " python3-ftd2xx "
DEPENDS += " python3-setuptools-scm-native "

inherit python_setuptools_build_meta
