SUMMARY = "FTDI D2XX Library"
SECTION = "libs"
LICENSE = "CLOSED"

COMPATIBLE_MACHINE = "^$"
COMPATIBLE_MACHINE:zynqmp = ".*"
COMPATIBLE_MACHINE:versal = ".*"
COMPATIBLE_MACHINE:versal-net = ".*"

PV = "1.4.34"
SRC_URI = "https://ftdichip.com/wp-content/uploads/2025/11/libftd2xx-linux-arm-v8-${PV}.tgz"
SRC_URI[sha256sum] = "e168d1b064c0f75891d3482d9fe1fbb85c6f131e674213394526ed38927849dc"

S = "${WORKDIR}"

ARCH_DIR:aarch64 = "linux-arm-v8"

INSANE_SKIP:${PN} = "ldflags dev-so"
FILES_SOLIBSDEV = ""
FILES:${PN} += "${libdir}/libftd2xx.so.${PV} ${libdir}/libftd2xx.so"

do_install () {
	install -m 0755 -d ${D}${libdir}
	oe_soinstall ${S}/${ARCH_DIR}/libftd2xx.so.${PV} ${D}${libdir}
	install -d ${D}${includedir}
	install -m 0755 ${S}/${ARCH_DIR}/*.h ${D}${includedir}
}
