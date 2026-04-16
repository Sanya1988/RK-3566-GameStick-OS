################################################################################
#
# gamestick-games-storage
#
################################################################################

GAMESTICK_GAMES_STORAGE_VERSION = 1.0
GAMESTICK_GAMES_STORAGE_SITE = $(BR2_EXTERNAL_GAMESTICK_PATH)/package/gamestick-games-storage
GAMESTICK_GAMES_STORAGE_SITE_METHOD = local
GAMESTICK_GAMES_STORAGE_LICENSE = MIT
GAMESTICK_GAMES_STORAGE_REDISTRIBUTE = NO
GAMESTICK_GAMES_STORAGE_DEPENDENCIES = exfat exfatprogs ntfs-3g util-linux
GAMESTICK_GAMES_STORAGE_FIRSTBOOT_ASSET_DIR = $(BR2_EXTERNAL_GAMESTICK_PATH)/package/gamestick-games-storage/assets/firstboot
GAMESTICK_GAMES_STORAGE_DEMO_ROM_DIR = $(BR2_EXTERNAL_GAMESTICK_PATH)/package/gamestick-games-storage/assets/demo-roms
GAMESTICK_GAMES_STORAGE_SCREENSAVER_DIR = $(BR2_EXTERNAL_GAMESTICK_PATH)/package/gamestick-games-storage/assets/screensaver

define GAMESTICK_GAMES_STORAGE_INSTALL_TARGET_CMDS
	$(INSTALL) -D -m 0755 $(@D)/S40gamestick-firstboot \
		$(TARGET_DIR)/etc/init.d/S40gamestick-firstboot
	$(INSTALL) -D -m 0755 $(@D)/S41gamestick-storage \
		$(TARGET_DIR)/etc/init.d/S41gamestick-storage
	$(INSTALL) -D -m 0755 $(@D)/gamestick-userdata-firstboot \
		$(TARGET_DIR)/usr/bin/gamestick-userdata-firstboot
	$(INSTALL) -D -m 0755 $(@D)/gamestick-firstboot-screen \
		$(TARGET_DIR)/usr/bin/gamestick-firstboot-screen
	$(INSTALL) -D -m 0644 $(@D)/gamestick-storage-common.sh \
		$(TARGET_DIR)/usr/lib/gamestick/storage-common.sh
	$(INSTALL) -D -m 0644 \
		$(BR2_EXTERNAL_GAMESTICK_PATH)/scripts/gamestick-userdata-seed.sh \
		$(TARGET_DIR)/usr/lib/gamestick/userdata-seed.sh
	rm -rf $(TARGET_DIR)/usr/share/gamestick/roms-seed
	mkdir -p $(TARGET_DIR)/usr/share/gamestick/roms-seed
	if [ -d "$(GAMESTICK_GAMES_STORAGE_DEMO_ROM_DIR)" ]; then \
		cp -R "$(GAMESTICK_GAMES_STORAGE_DEMO_ROM_DIR)/." \
			"$(TARGET_DIR)/usr/share/gamestick/roms-seed/"; \
	fi
	rm -rf $(TARGET_DIR)/usr/share/gamestick/screensaver-seed
	mkdir -p $(TARGET_DIR)/usr/share/gamestick/screensaver-seed
	if [ -d "$(GAMESTICK_GAMES_STORAGE_SCREENSAVER_DIR)" ]; then \
		cp -R "$(GAMESTICK_GAMES_STORAGE_SCREENSAVER_DIR)/." \
			"$(TARGET_DIR)/usr/share/gamestick/screensaver-seed/"; \
	fi
	mkdir -p $(TARGET_DIR)/usr/share/gamestick/firstboot
	@if [ -f "$(GAMESTICK_GAMES_STORAGE_FIRSTBOOT_ASSET_DIR)/firstboot-1.png" ]; then \
		$(INSTALL) -D -m 0644 \
			"$(GAMESTICK_GAMES_STORAGE_FIRSTBOOT_ASSET_DIR)/firstboot-1.png" \
			"$(TARGET_DIR)/usr/share/gamestick/firstboot/firstboot-1.png"; \
	else \
		rm -f "$(TARGET_DIR)/usr/share/gamestick/firstboot/firstboot-1.png"; \
	fi
	@if [ -f "$(GAMESTICK_GAMES_STORAGE_FIRSTBOOT_ASSET_DIR)/firstboot-transition.png" ]; then \
		$(INSTALL) -D -m 0644 \
			"$(GAMESTICK_GAMES_STORAGE_FIRSTBOOT_ASSET_DIR)/firstboot-transition.png" \
			"$(TARGET_DIR)/usr/share/gamestick/firstboot/firstboot-transition.png"; \
	else \
		rm -f "$(TARGET_DIR)/usr/share/gamestick/firstboot/firstboot-transition.png"; \
	fi
	@if [ -f "$(GAMESTICK_GAMES_STORAGE_FIRSTBOOT_ASSET_DIR)/firstboot-2.png" ]; then \
		$(INSTALL) -D -m 0644 \
			"$(GAMESTICK_GAMES_STORAGE_FIRSTBOOT_ASSET_DIR)/firstboot-2.png" \
			"$(TARGET_DIR)/usr/share/gamestick/firstboot/firstboot-2.png"; \
	else \
		rm -f "$(TARGET_DIR)/usr/share/gamestick/firstboot/firstboot-2.png"; \
	fi
	@if [ -f "$(GAMESTICK_GAMES_STORAGE_FIRSTBOOT_ASSET_DIR)/firstboot-complete.png" ]; then \
		$(INSTALL) -D -m 0644 \
			"$(GAMESTICK_GAMES_STORAGE_FIRSTBOOT_ASSET_DIR)/firstboot-complete.png" \
			"$(TARGET_DIR)/usr/share/gamestick/firstboot/firstboot-complete.png"; \
	else \
		rm -f "$(TARGET_DIR)/usr/share/gamestick/firstboot/firstboot-complete.png"; \
	fi
	mkdir -p $(TARGET_DIR)/storage
	mkdir -p $(TARGET_DIR)/var/lib/gamestick
	ln -snf /storage/roms $(TARGET_DIR)/roms
endef

$(eval $(generic-package))
