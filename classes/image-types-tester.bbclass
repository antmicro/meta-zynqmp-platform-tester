#
# Copyright OpenEmbedded Contributors
#
# SPDX-License-Identifier: MIT
#

# Based on the poky image_types, used to allow us to exclude files from
# certain filetypes.  This allows the distro to construct a single rootfs
# that is appropriate for different filesystem types, i.e.:
#
# wic/ext4 - good for sd cards (full filesystem)
# cpio - good for ramdisks/jtag loading (smaller, so skip /boot/* files)

# Format of this needs to be argument(s) to find, such as:
# To skip /boot directory
#    TESTER_IMAGE_CPIO_SKIP = "! -path './boot/*'"
# Note the matching path needs to be '.' for ${IMAGE_ROOTFS}, and any
# globbing needs to be quoted to prevent expansion.
TESTER_IMAGE_CPIO_SKIP ?= ""
IMAGE_CMD:cpio () {
	(cd ${IMAGE_ROOTFS} && find . ${TESTER_IMAGE_CPIO_SKIP} | sort | cpio --reproducible -o -H newc >${IMGDEPLOYDIR}/${IMAGE_NAME}${IMAGE_NAME_SUFFIX}.cpio)
	# We only need the /init symlink if we're building the real
	# image. The -dbg image doesn't need it! By being clever
	# about this we also avoid 'touch' below failing, as it
	# might be trying to touch /sbin/init on the host since both
	# the normal and the -dbg image share the same WORKDIR
	if [ "${IMAGE_BUILDING_DEBUGFS}" != "true" ]; then
		if [ ! -L ${IMAGE_ROOTFS}/init ] && [ ! -e ${IMAGE_ROOTFS}/init ]; then
			if [ -L ${IMAGE_ROOTFS}/sbin/init ] || [ -e ${IMAGE_ROOTFS}/sbin/init ]; then
				ln -sf /sbin/init ${WORKDIR}/cpio_append/init
			else
				touch ${WORKDIR}/cpio_append/init
			fi
			(cd  ${WORKDIR}/cpio_append && echo ./init | cpio -oA -H newc -F ${IMGDEPLOYDIR}/${IMAGE_NAME}${IMAGE_NAME_SUFFIX}.cpio)
		fi
	fi
}

# Format of this needs to be argument(s) to find, such as:
# To skip /boot directory
#    TESTER_IMAGE_JFFS2_SKIP = "! -path './boot/*'"
# Note the matching path needs to be '.' for ${IMAGE_ROOTFS}, and any
# globbing needs to be quoted to prevent expansion.
TESTER_IMAGE_JFFS2_SKIP ?= ""
do_image_jffs2[cleandirs] += "${WORKDIR}/jffs2"
IMAGE_CMD:jffs2 () {
	(cd ${IMAGE_ROOTFS} && find . ${TESTER_IMAGE_JFFS2_SKIP} | sort | cpio -o -H newc) | cpio -i -d -m --sparse -D ${WORKDIR}/jffs2

	mkfs.jffs2 --root=${WORKDIR}/jffs2 --faketime --output=${IMGDEPLOYDIR}/${IMAGE_NAME}${IMAGE_NAME_SUFFIX}.jffs2 ${EXTRA_IMAGECMD}
}

# Format of this needs to be argument(s) to find, such as:
# To skip /boot directory
#    TESTER_IMAGE_UBI_SKIP = "! -path './boot/*'"
# Note the matching path needs to be '.' for ${IMAGE_ROOTFS}, and any
# globbing needs to be quoted to prevent expansion.
# Affects ubi, ubifs and multiubi
TESTER_IMAGE_UBI_SKIP ?= ""

do_image_ubifs[cleandirs] += "${WORKDIR}/multiubi"
multiubi_mkfs() {
	local mkubifs_args="$1"
	local ubinize_args="$2"

        # Added prompt error message for ubi and ubifs image creation.
        if [ -z "$mkubifs_args" ] || [ -z "$ubinize_args" ]; then
            bbfatal "MKUBIFS_ARGS and UBINIZE_ARGS have to be set, see http://www.linux-mtd.infradead.org/faq/ubifs.html for details"
        fi

	write_ubi_config "$3"

	if [ -n "$vname" ]; then
		(cd ${IMAGE_ROOTFS} && find . ${TESTER_IMAGE_UBI_SKIP} | sort | cpio -o -H newc) | cpio -i -d -m --sparse -D ${WORKDIR}/multiubi
		mkfs.ubifs -r ${WORKDIR}/multiubi -o ${IMGDEPLOYDIR}/${IMAGE_NAME}${vname}${IMAGE_NAME_SUFFIX}.ubifs ${mkubifs_args}
	fi
	ubinize -o ${IMGDEPLOYDIR}/${IMAGE_NAME}${vname}${IMAGE_NAME_SUFFIX}.ubi ${ubinize_args} ubinize${vname}-${IMAGE_NAME}.cfg

	# Cleanup cfg file
	mv ubinize${vname}-${IMAGE_NAME}.cfg ${IMGDEPLOYDIR}/

	# Create own symlinks for 'named' volumes
	if [ -n "$vname" ]; then
		cd ${IMGDEPLOYDIR}
		if [ -e ${IMAGE_NAME}${vname}${IMAGE_NAME_SUFFIX}.ubifs ]; then
			ln -sf ${IMAGE_NAME}${vname}${IMAGE_NAME_SUFFIX}.ubifs \
			${IMAGE_LINK_NAME}${vname}.ubifs
		fi
		if [ -e ${IMAGE_NAME}${vname}${IMAGE_NAME_SUFFIX}.ubi ]; then
			ln -sf ${IMAGE_NAME}${vname}${IMAGE_NAME_SUFFIX}.ubi \
			${IMAGE_LINK_NAME}${vname}.ubi
		fi
		cd -
	fi
}

do_image_ubifs[cleandirs] += "${WORKDIR}/ubifs"
IMAGE_CMD:ubifs () {
	(cd ${IMAGE_ROOTFS} && find . ${TESTER_IMAGE_UBI_SKIP} | sort | cpio -o -H newc) | cpio -i -d -m --sparse -D ${WORKDIR}/ubifs
	mkfs.ubifs -r ${WORKDIR}/ubifs -o ${IMGDEPLOYDIR}/${IMAGE_NAME}${IMAGE_NAME_SUFFIX}.ubifs ${MKUBIFS_ARGS}
}

do_image_tester_qspi[cleandirs] += "${WORKDIR}/tester_qspi"
IMAGE_CMD:tester_qspi () {
	cd ${IMAGE_ROOTFS}
	find . ${TESTER_IMAGE_CPIO_SKIP} | sort | cpio --reproducible -o -H newc >${WORKDIR}/${IMAGE_NAME}${IMAGE_NAME_SUFFIX}.cpio
	gzip ${WORKDIR}/${IMAGE_NAME}${IMAGE_NAME_SUFFIX}.cpio
	OUTPUT_FILE=${IMGDEPLOYDIR}/${IMAGE_NAME}${IMAGE_NAME_SUFFIX}.qspi
	dd conv=notrunc bs=1 if=${DEPLOY_DIR_IMAGE}/boot.bin of=${OUTPUT_FILE} seek=0
	dd conv=notrunc bs=1 if=${DEPLOY_DIR_IMAGE}/u-boot.itb of=${OUTPUT_FILE} seek=393216 # 0x60000
	dd conv=notrunc bs=1 if=${DEPLOY_DIR_IMAGE}/Image of=${OUTPUT_FILE} seek=1765376 # 0x1AF000
	dd conv=notrunc bs=1 if=${DEPLOY_DIR_IMAGE}/${KERNEL_DEVICETREE} of=${OUTPUT_FILE} seek=24834048 # 0x17AF000
	dd conv=notrunc bs=1 if=${WORKDIR}/${IMAGE_NAME}${IMAGE_NAME_SUFFIX}.cpio.gz of=${OUTPUT_FILE} seek=25882624 # 0x18AF000
    cd ${IMGDEPLOYDIR}
    ln -sf ${IMAGE_NAME}${IMAGE_NAME_SUFFIX}.qspi ${IMAGE_LINK_NAME}.qspi
    cd -
}

CONVERSIONTYPES:append = " sd-fatimg"

BOOT_VOLUME_ID ?= "BOOT"
BOOT_SPACE ?= "1047552"
IMAGE_ALIGNMENT ?= "1024"

# This creates FAT partitioned SD image containing
# BOOT.bin, boot.scr, Image, system.dtb, rootfs.cpio.gz.u-boot.
# Usage: IMAGE_FSTYPES:append = " cpio.gz.u-boot.sd-fatimg"
CONVERSION_CMD:sd-fatimg () {
    SD_IMG="${IMAGE_NAME}${IMAGE_NAME_SUFFIX}.${type}.sd-fatimg"
    BOOT_SPACE_ALIGNED=$(expr ${BOOT_SPACE} + ${IMAGE_ALIGNMENT} - 1)
    BOOT_SPACE_ALIGNED=$(expr ${BOOT_SPACE_ALIGNED} - ${BOOT_SPACE_ALIGNED} % ${IMAGE_ALIGNMENT})
    SDIMG_SIZE=$(expr ${IMAGE_ALIGNMENT} + ${BOOT_SPACE_ALIGNED})
    dd if=/dev/zero of=${SD_IMG} bs=1024 count=0 seek=${SDIMG_SIZE}
    parted -s ${SD_IMG} mklabel msdos
    parted -s ${SD_IMG} unit KiB mkpart primary fat32 ${IMAGE_ALIGNMENT} $(expr ${BOOT_SPACE_ALIGNED} \+ ${IMAGE_ALIGNMENT} \- 1)
    parted -s ${SD_IMG} set 1 boot on
    parted ${SD_IMG} print
    BOOT_BLOCKS=$(LC_ALL=C parted -s ${SD_IMG} unit b print | awk '/ 1 / { print substr($4, 1, length($4 -1)) / 512 /2 }')
    rm -f ${WORKDIR}/${BOOT_VOLUME_ID}.img
    mkfs.vfat -n "${BOOT_VOLUME_ID}" -S 512 -C ${WORKDIR}/${BOOT_VOLUME_ID}.img $BOOT_BLOCKS
    if [ -e ${WORKDIR}/rootfs/boot/BOOT.bin ]; then
        mcopy -i ${WORKDIR}/${BOOT_VOLUME_ID}.img -s  ${WORKDIR}/rootfs/boot/BOOT.bin ::/
    fi
    if [ -e ${WORKDIR}/rootfs/boot/boot.scr ]; then
        mcopy -i ${WORKDIR}/${BOOT_VOLUME_ID}.img -s  ${WORKDIR}/rootfs/boot/boot.scr ::/
    fi
    if [ -e ${WORKDIR}/rootfs/boot/Image ]; then
        mcopy -i ${WORKDIR}/${BOOT_VOLUME_ID}.img -s  ${WORKDIR}/rootfs/boot/Image ::/
    fi
    if [ -e ${WORKDIR}/rootfs/boot/system.dtb ]; then
        mcopy -i ${WORKDIR}/${BOOT_VOLUME_ID}.img -s  ${WORKDIR}/rootfs/boot/system.dtb ::/
    fi
    if [ x"${INITRAMFS_IMAGE_BUNDLE}" != "x1" ]; then
        mcopy -i ${WORKDIR}/${BOOT_VOLUME_ID}.img -s  ${IMAGE_NAME}.${type} ::rootfs.cpio.gz.u-boot
    fi
    dd if=${WORKDIR}/${BOOT_VOLUME_ID}.img of=${SD_IMG} conv=notrunc seek=1 bs=$(expr ${IMAGE_ALIGNMENT} \* 1024)
}

CONVERSION_DEPENDS_sd-fatimg = "mtools-native:do_populate_sysroot \
                dosfstools-native:do_populate_sysroot \
                parted-native:do_populate_sysroot"
