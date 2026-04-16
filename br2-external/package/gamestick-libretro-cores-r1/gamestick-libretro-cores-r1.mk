################################################################################
#
# gamestick-libretro-cores-r1
#
################################################################################

GAMESTICK_LIBRETRO_CORES_R1_VERSION = 60f5c62789af16379446544d64228afa1d6b28b7
GAMESTICK_LIBRETRO_CORES_R1_SITE = $(call github,libretro,libretro-super,$(GAMESTICK_LIBRETRO_CORES_R1_VERSION))
GAMESTICK_LIBRETRO_CORES_R1_LICENSE = Various
GAMESTICK_LIBRETRO_CORES_R1_LICENSE_FILES = COPYING
GAMESTICK_LIBRETRO_CORES_R1_REDISTRIBUTE = NO
GAMESTICK_LIBRETRO_CORES_R1_LOCKFILE = \
	$(BR2_EXTERNAL_GAMESTICK_PATH)/package/gamestick-libretro-cores-r1/core-sources.lock
GAMESTICK_LIBRETRO_CORES_R1_BUILDER = \
	$(BR2_EXTERNAL_GAMESTICK_PATH)/package/gamestick-libretro-cores-r1/build-libretro-cores.sh

define GAMESTICK_LIBRETRO_CORES_R1_BUILD_CMDS
	PATH="$(HOST_DIR)/bin:$$PATH" \
	JOBS="$(PARALLEL_JOBS)" \
	HOST_CC="$(patsubst %-,%,$(TARGET_CROSS))" \
	ARCH="aarch64" \
	CORES_LOCK_FILE="$(GAMESTICK_LIBRETRO_CORES_R1_LOCKFILE)" \
	$(TARGET_CONFIGURE_OPTS) \
	$(GAMESTICK_LIBRETRO_CORES_R1_BUILDER) $(@D)
endef

define GAMESTICK_LIBRETRO_CORES_R1_INSTALL_TARGET_CMDS
	rm -rf $(TARGET_DIR)/usr/share/gamestick/retroarch-seed/cores
	rm -rf $(TARGET_DIR)/usr/share/gamestick/retroarch-seed/info
	mkdir -p $(TARGET_DIR)/usr/share/gamestick/retroarch-seed/cores
	mkdir -p $(TARGET_DIR)/usr/share/gamestick/retroarch-seed/info
	while read -r module ref; do \
		[ -n "$$module" ] || continue; \
		case "$$module" in \#*) continue ;; esac; \
		$(INSTALL) -D -m 0644 \
			"$(@D)/dist/unix/$${module}_libretro.so" \
			"$(TARGET_DIR)/usr/share/gamestick/retroarch-seed/cores/$${module}_libretro.so"; \
		$(INSTALL) -D -m 0644 \
			"$(@D)/dist/info/$${module}_libretro.info" \
			"$(TARGET_DIR)/usr/share/gamestick/retroarch-seed/info/$${module}_libretro.info"; \
	done < "$(GAMESTICK_LIBRETRO_CORES_R1_LOCKFILE)"
	$(INSTALL) -D -m 0644 $(BR2_EXTERNAL_GAMESTICK_PATH)/package/gamestick-libretro-cores-r1/seed/cores/README.txt \
		$(TARGET_DIR)/usr/share/gamestick/retroarch-seed/cores/README.txt
endef

$(eval $(generic-package))
