################################################################################
#
# gamestick-bios
#
################################################################################

GAMESTICK_BIOS_VERSION = local
GAMESTICK_BIOS_SITE = $(BR2_EXTERNAL_GAMESTICK_PATH)/package/gamestick-bios/seed
GAMESTICK_BIOS_SITE_METHOD = local
GAMESTICK_BIOS_LICENSE = Proprietary
GAMESTICK_BIOS_REDISTRIBUTE = NO

define GAMESTICK_BIOS_INSTALL_TARGET_CMDS
	mkdir -p $(TARGET_DIR)/usr/share/gamestick/retroarch-seed/bios
	cp -R $(@D)/. $(TARGET_DIR)/usr/share/gamestick/retroarch-seed/bios/
	$(INSTALL) -D -m 0644 \
		$(BR2_EXTERNAL_GAMESTICK_PATH)/package/gamestick-bios/bios-manifest.tsv \
		$(TARGET_DIR)/usr/share/gamestick/retroarch-seed/bios-manifest.tsv
endef

$(eval $(generic-package))
