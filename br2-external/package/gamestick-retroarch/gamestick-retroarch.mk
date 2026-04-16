################################################################################
#
# gamestick-retroarch
#
################################################################################

GAMESTICK_RETROARCH_VERSION = v1.20.0
GAMESTICK_RETROARCH_SITE = $(call github,libretro,RetroArch,$(GAMESTICK_RETROARCH_VERSION))
GAMESTICK_RETROARCH_LICENSE = GPL-3.0+
GAMESTICK_RETROARCH_LICENSE_FILES = COPYING
GAMESTICK_RETROARCH_DEPENDENCIES = alsa-lib freetype gamestick-bios gamestick-input gamestick-libretro-cores-r1 gamestick-libudev-zero gamestick-mali-r25p0-wayland-runtime gamestick-retroarch-assets host-python3 libdrm rockchip-mali zlib
GAMESTICK_RETROARCH_ENV = \
	CROSS_COMPILE="$(TARGET_CROSS)" \
	PKG_CONF_PATH="$(PKG_CONFIG_HOST_BINARY)" \
	PKG_CONFIG="$(PKG_CONFIG_HOST_BINARY)"

GAMESTICK_RETROARCH_CONF_OPTS = \
	--prefix=/usr \
	--disable-x11 \
	--disable-wayland \
	--disable-vulkan \
	--disable-opengl1 \
	--disable-opengl_core \
	--disable-networking \
	--disable-networkgamepad \
	--disable-netplaydiscovery \
	--disable-online_updater \
	--disable-update_cores \
	--disable-update_core_info \
	--disable-update_assets \
	--disable-cheevos \
	--disable-discord \
	--disable-translate \
	--disable-ssl \
	--disable-pulse \
	--disable-oss \
	--disable-jack \
	--disable-sdl \
	--disable-sdl2 \
	--disable-qt \
	--enable-udev \
	--enable-alsa \
	--enable-egl \
	--enable-freetype \
	--enable-kms \
	--enable-opengles

define GAMESTICK_RETROARCH_CONFIGURE_CMDS
	(cd $(@D); \
		$(GAMESTICK_RETROARCH_ENV) \
		$(TARGET_CONFIGURE_OPTS) \
		CPPFLAGS="$(TARGET_CPPFLAGS)" \
		CFLAGS="$(TARGET_CFLAGS)" \
		CXXFLAGS="$(TARGET_CXXFLAGS)" \
		LDFLAGS="$(TARGET_LDFLAGS)" \
		./configure $(GAMESTICK_RETROARCH_CONF_OPTS))
endef

define GAMESTICK_RETROARCH_BUILD_CMDS
	$(TARGET_MAKE_ENV) $(GAMESTICK_RETROARCH_ENV) $(MAKE) -C $(@D)
endef

define GAMESTICK_RETROARCH_INSTALL_TARGET_CMDS
	$(TARGET_MAKE_ENV) $(GAMESTICK_RETROARCH_ENV) $(MAKE) -C $(@D) DESTDIR=$(TARGET_DIR) install
	$(INSTALL) -D -m 0755 $(@D)/retroarch \
		$(TARGET_DIR)/usr/bin/retroarch
	$(INSTALL) -D -m 0755 $(BR2_EXTERNAL_GAMESTICK_PATH)/package/gamestick-retroarch/retroarch-kms \
		$(TARGET_DIR)/usr/bin/retroarch-kms
	$(INSTALL) -D -m 0755 $(BR2_EXTERNAL_GAMESTICK_PATH)/package/gamestick-retroarch/gamestick-retroarch-session \
		$(TARGET_DIR)/usr/bin/gamestick-retroarch-session
	$(INSTALL) -D -m 0644 $(BR2_EXTERNAL_GAMESTICK_PATH)/package/gamestick-retroarch/retroarch.cfg \
		$(TARGET_DIR)/etc/retroarch.cfg
	$(INSTALL) -D -m 0644 $(BR2_EXTERNAL_GAMESTICK_PATH)/package/gamestick-retroarch/asound.conf \
		$(TARGET_DIR)/etc/asound.conf
	mkdir -p $(TARGET_DIR)/usr/share/retroarch/autoconfig/udev
	cp -a $(BR2_EXTERNAL_GAMESTICK_PATH)/package/gamestick-retroarch/autoconfig/udev/. \
		$(TARGET_DIR)/usr/share/retroarch/autoconfig/udev/
	mkdir -p $(TARGET_DIR)/usr/share/gamestick/retroarch-defaults
	rm -rf $(TARGET_DIR)/usr/share/gamestick/retroarch-defaults/config
	rm -rf $(TARGET_DIR)/usr/share/gamestick/retroarch-defaults/shaders
	rm -rf $(TARGET_DIR)/usr/share/gamestick/retroarch-defaults/overlays
	cp -R $(BR2_EXTERNAL_GAMESTICK_PATH)/package/gamestick-retroarch/defaults/config \
		$(TARGET_DIR)/usr/share/gamestick/retroarch-defaults/
	cp -R $(BR2_EXTERNAL_GAMESTICK_PATH)/package/gamestick-retroarch/defaults/shaders \
		$(TARGET_DIR)/usr/share/gamestick/retroarch-defaults/
	mkdir -p $(TARGET_DIR)/usr/share/gamestick/retroarch-defaults/overlays
	mkdir -p $(TARGET_DIR)/usr/share/gamestick/retroarch-defaults/config/system-bezels
	cp -R $(BR2_EXTERNAL_GAMESTICK_PATH)/package/gamestick-retroarch/defaults/overlays/. \
		$(TARGET_DIR)/usr/share/gamestick/retroarch-defaults/overlays/
	$(INSTALL) -D -m 0644 $(BR2_EXTERNAL_GAMESTICK_PATH)/package/gamestick-retroarch/seed/cheats/README.txt \
		$(TARGET_DIR)/usr/share/gamestick/retroarch-seed/cheats/README.txt
	$(HOST_DIR)/bin/python3 \
		$(BR2_EXTERNAL_GAMESTICK_PATH)/package/gamestick-retroarch/tools/generate_retroarch_bezels.py \
		--systems-tsv $(BR2_EXTERNAL_GAMESTICK_PATH)/package/gamestick-esde/supported-systems.tsv \
		--asset-dir $(BR2_EXTERNAL_GAMESTICK_PATH)/package/gamestick-retroarch/batocera/default_unglazed/systems \
		--overlay-dir $(TARGET_DIR)/usr/share/gamestick/retroarch-defaults/overlays \
		--overlay-image-dir $(TARGET_DIR)/usr/share/gamestick/retroarch-defaults/overlays/images \
		--system-bezel-dir $(TARGET_DIR)/usr/share/gamestick/retroarch-defaults/config/system-bezels
endef

$(eval $(generic-package))
