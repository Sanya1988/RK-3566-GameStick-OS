################################################################################
#
# gamestick-input
#
################################################################################

GAMESTICK_INPUT_VERSION = local
GAMESTICK_INPUT_SITE = $(BR2_EXTERNAL_GAMESTICK_PATH)/package/gamestick-input
GAMESTICK_INPUT_SITE_METHOD = local
GAMESTICK_INPUT_LICENSE = MIT
GAMESTICK_INPUT_REDISTRIBUTE = NO
GAMESTICK_INPUT_DEPENDENCIES = host-python3

define GAMESTICK_INPUT_BUILD_CMDS
	rm -rf $(@D)/generated
	mkdir -p $(@D)/generated/retroarch-autoconfig/udev
	$(HOST_DIR)/bin/python3 $(BR2_EXTERNAL_GAMESTICK_PATH)/package/gamestick-input/tools/es_input_to_profiles.py \
		--es-input $(BR2_EXTERNAL_GAMESTICK_PATH)/package/gamestick-input/data/batocera-es_input.cfg \
		--autoconfig-dir $(@D)/generated/retroarch-autoconfig/udev \
		--index $(@D)/generated/autoconfig-index.tsv \
		--sdl-db $(@D)/generated/gamecontrollerdb.txt
endef

define GAMESTICK_INPUT_INSTALL_TARGET_CMDS
	mkdir -p $(TARGET_DIR)/usr/share/gamestick/input
	mkdir -p $(TARGET_DIR)/usr/share/gamestick/input/retroarch-autoconfig/udev
	mkdir -p $(TARGET_DIR)/usr/share/retroarch/autoconfig/udev
	cp -a $(@D)/generated/retroarch-autoconfig/udev/. \
		$(TARGET_DIR)/usr/share/gamestick/input/retroarch-autoconfig/udev/
	cp -a $(@D)/generated/retroarch-autoconfig/udev/. \
		$(TARGET_DIR)/usr/share/retroarch/autoconfig/udev/
	$(INSTALL) -D -m 0644 $(BR2_EXTERNAL_GAMESTICK_PATH)/package/gamestick-input/data/batocera-es_input.cfg \
		$(TARGET_DIR)/usr/share/gamestick/input/batocera-es_input.cfg
	$(INSTALL) -D -m 0644 $(@D)/generated/autoconfig-index.tsv \
		$(TARGET_DIR)/usr/share/gamestick/input/autoconfig-index.tsv
	$(INSTALL) -D -m 0644 $(@D)/generated/gamecontrollerdb.txt \
		$(TARGET_DIR)/usr/share/gamestick/input/gamecontrollerdb.txt
	$(INSTALL) -D -m 0755 $(BR2_EXTERNAL_GAMESTICK_PATH)/package/gamestick-input/gamestick-input-refresh \
		$(TARGET_DIR)/usr/bin/gamestick-input-refresh
	$(INSTALL) -D -m 0755 $(BR2_EXTERNAL_GAMESTICK_PATH)/package/gamestick-input/S42gamestick-input \
		$(TARGET_DIR)/etc/init.d/S42gamestick-input
endef

$(eval $(generic-package))
