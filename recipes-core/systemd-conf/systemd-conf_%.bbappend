FILESEXTRAPATHS:prepend := "${THISDIR}/files:"
SRC_URI:append = "\
    file://watchdog.conf \
"

do_install:append() {
    install -D -m 0644 ${WORKDIR}/watchdog.conf ${D}${systemd_unitdir}/system.conf.d/99-watchdog.conf
}
