################################################################################
#
# gamestick-retroarch-assets
#
################################################################################

GAMESTICK_RETROARCH_ASSETS_VERSION = 1.0
GAMESTICK_RETROARCH_ASSETS_SITE = $(BR2_EXTERNAL_GAMESTICK_PATH)/package/gamestick-retroarch-assets/src
GAMESTICK_RETROARCH_ASSETS_SITE_METHOD = local
GAMESTICK_RETROARCH_ASSETS_LICENSE = CC-BY-4.0 and various free font licenses
GAMESTICK_RETROARCH_ASSETS_LICENSE_FILES = COPYING glui/README.md pkg/chinese-fallback-font.txt pkg/korean-fallback-font.txt
GAMESTICK_RETROARCH_ASSETS_REDISTRIBUTE = NO

define GAMESTICK_RETROARCH_ASSETS_INSTALL_TARGET_CMDS
	mkdir -p $(TARGET_DIR)/usr/share/retroarch/assets/xmb
	cp -aT $(@D)/ozone $(TARGET_DIR)/usr/share/retroarch/assets/ozone
	cp -aT $(@D)/glui $(TARGET_DIR)/usr/share/retroarch/assets/glui
	cp -aT $(@D)/pkg $(TARGET_DIR)/usr/share/retroarch/assets/pkg
	cp -aT $(@D)/sounds $(TARGET_DIR)/usr/share/retroarch/assets/sounds
	cp -aT $(@D)/xmb/monochrome $(TARGET_DIR)/usr/share/retroarch/assets/xmb/monochrome
endef

$(eval $(generic-package))
