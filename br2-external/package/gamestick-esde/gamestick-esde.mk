################################################################################
#
# gamestick-esde
#
################################################################################

GAMESTICK_ESDE_VERSION = local
GAMESTICK_ESDE_SITE = $(BR2_EXTERNAL_GAMESTICK_PATH)/../esde
GAMESTICK_ESDE_SITE_METHOD = local
GAMESTICK_ESDE_LICENSE = MIT
GAMESTICK_ESDE_LICENSE_FILES = LICENSE
GAMESTICK_ESDE_ASSET_DIR = $(BR2_EXTERNAL_GAMESTICK_PATH)/package/gamestick-esde/assets
GAMESTICK_ESDE_DEPENDENCIES = \
	alsa-lib \
	ffmpeg \
	freetype \
	gamestick-freeimage \
	gamestick-retroarch \
	harfbuzz \
	host-gettext \
	host-python3 \
	icu \
	poppler \
	pugixml \
	sdl2

GAMESTICK_ESDE_CONF_OPTS = \
	-DGL=OFF \
	-DGLES=ON \
	-DAPPLICATION_UPDATER=OFF \
	-DCOMPILE_LOCALIZATIONS=ON \
	-DGAMESTICK_OFFLINE=ON

define GAMESTICK_ESDE_GENERATE_CUSTOM_SYSTEMS
	mkdir -p $(TARGET_DIR)/usr/share/gamestick/esde-seed/custom_systems
	$(HOST_DIR)/bin/python3 \
		$(BR2_EXTERNAL_GAMESTICK_PATH)/package/gamestick-esde/tools/generate_esde_systems.py \
		--upstream $(@D)/resources/systems/linux/es_systems.xml \
		--whitelist $(BR2_EXTERNAL_GAMESTICK_PATH)/package/gamestick-esde/supported-systems.tsv \
		--active-cores $(TARGET_DIR)/usr/share/gamestick/retroarch-seed/cores \
		--output $(TARGET_DIR)/usr/share/gamestick/esde-seed/custom_systems/es_systems.xml
endef

define GAMESTICK_ESDE_INSTALL_TARGET_CMDS
	$(INSTALL) -D -m 0755 $(@D)/es-de \
		$(TARGET_DIR)/usr/bin/es-de
	$(INSTALL) -D -m 0755 $(BR2_EXTERNAL_GAMESTICK_PATH)/package/gamestick-esde/gamestick-esde \
		$(TARGET_DIR)/usr/bin/gamestick-esde
	$(INSTALL) -D -m 0755 $(BR2_EXTERNAL_GAMESTICK_PATH)/package/gamestick-esde/gamestick-esde-session \
		$(TARGET_DIR)/usr/bin/gamestick-esde-session
	mkdir -p $(TARGET_DIR)/usr/share/es-de
	rm -rf $(TARGET_DIR)/usr/share/es-de/resources
	rm -rf $(TARGET_DIR)/usr/share/es-de/themes
	cp -R $(@D)/resources $(TARGET_DIR)/usr/share/es-de/
	cp -R $(@D)/themes $(TARGET_DIR)/usr/share/es-de/
	$(INSTALL) -D -m 0644 $(BR2_EXTERNAL_GAMESTICK_PATH)/package/gamestick-esde/seed/es_settings.xml \
		$(TARGET_DIR)/usr/share/gamestick/esde-seed/settings/es_settings.xml
	$(INSTALL) -D -m 0644 $(BR2_EXTERNAL_GAMESTICK_PATH)/package/gamestick-esde/seed/custom_systems/es_find_rules.xml \
		$(TARGET_DIR)/usr/share/gamestick/esde-seed/custom_systems/es_find_rules.xml
	$(INSTALL) -D -m 0644 $(BR2_EXTERNAL_GAMESTICK_PATH)/package/gamestick-esde/supported-systems.tsv \
		$(TARGET_DIR)/usr/share/gamestick/esde-seed/supported-systems.tsv
	rm -rf $(TARGET_DIR)/usr/share/gamestick/esde-seed/scripts
	if [ -d "$(BR2_EXTERNAL_GAMESTICK_PATH)/package/gamestick-esde/seed/scripts" ]; then \
		mkdir -p "$(TARGET_DIR)/usr/share/gamestick/esde-seed/scripts"; \
		cp -R "$(BR2_EXTERNAL_GAMESTICK_PATH)/package/gamestick-esde/seed/scripts/." \
			"$(TARGET_DIR)/usr/share/gamestick/esde-seed/scripts/"; \
		find "$(TARGET_DIR)/usr/share/gamestick/esde-seed/scripts" -type f -name '*.sh' -exec chmod 0755 {} +; \
	fi
	rm -rf $(TARGET_DIR)/usr/share/gamestick/esde-seed/themes
	mkdir -p $(TARGET_DIR)/usr/share/gamestick/esde-seed/themes
	if [ -d "$(GAMESTICK_ESDE_ASSET_DIR)/themes" ]; then \
		cp -R "$(GAMESTICK_ESDE_ASSET_DIR)/themes/." \
			"$(TARGET_DIR)/usr/share/gamestick/esde-seed/themes/"; \
	fi
	$(INSTALL) -D -m 0644 $(BR2_EXTERNAL_GAMESTICK_PATH)/package/gamestick-esde/seed/themes/README.txt \
		$(TARGET_DIR)/usr/share/gamestick/esde-seed/themes/README.txt
	rm -rf $(TARGET_DIR)/usr/share/gamestick/esde-seed/resources
	mkdir -p $(TARGET_DIR)/usr/share/gamestick/esde-seed/resources/graphics
	if [ -f "$(BR2_EXTERNAL_GAMESTICK_PATH)/package/gamestick-esde/seed/resources/graphics/splash.png" ]; then \
		cp -f "$(BR2_EXTERNAL_GAMESTICK_PATH)/package/gamestick-esde/seed/resources/graphics/splash.png" \
			"$(TARGET_DIR)/usr/share/gamestick/esde-seed/resources/graphics/splash.png"; \
		cp -f "$(BR2_EXTERNAL_GAMESTICK_PATH)/package/gamestick-esde/seed/resources/graphics/splash.svg" \
			"$(TARGET_DIR)/usr/share/gamestick/esde-seed/resources/graphics/splash.svg"; \
	fi
	rm -rf $(TARGET_DIR)/usr/share/gamestick/esde-seed/downloaded_media
	if [ -d "$(BR2_EXTERNAL_GAMESTICK_PATH)/package/gamestick-esde/seed/downloaded_media" ]; then \
		mkdir -p "$(TARGET_DIR)/usr/share/gamestick/esde-seed/downloaded_media"; \
		cp -R "$(BR2_EXTERNAL_GAMESTICK_PATH)/package/gamestick-esde/seed/downloaded_media/." \
			"$(TARGET_DIR)/usr/share/gamestick/esde-seed/downloaded_media/"; \
	fi
	rm -rf $(TARGET_DIR)/usr/share/gamestick/music-seed
	mkdir -p $(TARGET_DIR)/usr/share/gamestick/music-seed
	if [ -d "$(GAMESTICK_ESDE_ASSET_DIR)/music" ]; then \
		cp -R "$(GAMESTICK_ESDE_ASSET_DIR)/music/." \
			"$(TARGET_DIR)/usr/share/gamestick/music-seed/"; \
	fi
	$(GAMESTICK_ESDE_GENERATE_CUSTOM_SYSTEMS)
endef

define GAMESTICK_ESDE_CONFIGURE_FRONTEND_SESSION
	if grep -q '^tty1::' $(TARGET_DIR)/etc/inittab; then \
		$(SED) 's#^tty1::.*#tty1::respawn:/usr/bin/gamestick-esde-session#' $(TARGET_DIR)/etc/inittab; \
	else \
		printf '%s\n' 'tty1::respawn:/usr/bin/gamestick-esde-session' >> $(TARGET_DIR)/etc/inittab; \
	fi
endef

GAMESTICK_ESDE_POST_INSTALL_TARGET_HOOKS += GAMESTICK_ESDE_CONFIGURE_FRONTEND_SESSION

$(eval $(cmake-package))
