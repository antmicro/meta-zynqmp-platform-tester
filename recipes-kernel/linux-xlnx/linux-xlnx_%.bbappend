FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI:append = " \
			file://0001-PATCH-nvmem-zynqmp_nvmem-unbreak-driver-after-cleanup.patch \
			file://max31785.cfg \
"
