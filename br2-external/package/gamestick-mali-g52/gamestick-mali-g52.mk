################################################################################
#
# gamestick-mali-g52
#
################################################################################

GAMESTICK_MALI_G52_VERSION = 6ab9d7ce7a991f997460697013fc54029fcac681
GAMESTICK_MALI_G52_SITE = $(call github,rtissera,a311d2-mali-g52,$(GAMESTICK_MALI_G52_VERSION))
GAMESTICK_MALI_G52_LICENSE = Proprietary
GAMESTICK_MALI_G52_LICENSE_FILES = END_USER_LICENCE_AGREEMENT.txt
GAMESTICK_MALI_G52_INSTALL_STAGING = YES
GAMESTICK_MALI_G52_DEPENDENCIES = host-patchelf libdrm libglvnd wayland

define GAMESTICK_MALI_G52_INSTALL_COMMON_CMDS
	mkdir -p $(1)/etc
	mkdir -p $(1)/usr/include
	mkdir -p $(1)/usr/lib
	rm -f $(1)/usr/lib/libMali.so
	rm -f $(1)/usr/lib/libmali.so
	rm -f $(1)/usr/lib/libmali.so.*
	rm -f $(1)/usr/lib/libmali-bifrost-*.so
	rm -f $(1)/usr/lib/libEGL.so
	rm -f $(1)/usr/lib/libEGL.so.*
	rm -f $(1)/usr/lib/libGLESv1_CM.so
	rm -f $(1)/usr/lib/libGLESv1_CM.so.*
	rm -f $(1)/usr/lib/libGLESv2.so
	rm -f $(1)/usr/lib/libGLESv2.so.*
	rm -f $(1)/usr/lib/libgbm.so
	rm -f $(1)/usr/lib/libgbm.so.*
	rm -f $(1)/usr/lib/libwayland-egl.so
	rm -f $(1)/usr/lib/libwayland-egl.so.*
	cp -a $(@D)/etc/. $(1)/etc/
	cp -a $(@D)/usr/include/. $(1)/usr/include/
	cp -a $(@D)/usr/lib/aarch64-linux-gnu/. $(1)/usr/lib/
endef

define GAMESTICK_MALI_G52_INSTALL_STAGING_CMDS
	$(call GAMESTICK_MALI_G52_INSTALL_COMMON_CMDS,$(STAGING_DIR))
endef

define GAMESTICK_MALI_G52_INSTALL_TARGET_CMDS
	$(call GAMESTICK_MALI_G52_INSTALL_COMMON_CMDS,$(TARGET_DIR))
endef

$(eval $(generic-package))
