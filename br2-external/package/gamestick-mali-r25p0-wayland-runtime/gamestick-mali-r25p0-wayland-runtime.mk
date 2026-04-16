################################################################################
#
# gamestick-mali-r25p0-wayland-runtime
#
################################################################################

GAMESTICK_MALI_R25P0_WAYLAND_RUNTIME_VERSION = local
GAMESTICK_MALI_R25P0_WAYLAND_RUNTIME_SITE = $(BR2_EXTERNAL_GAMESTICK_PATH)/package/gamestick-mali-r25p0-wayland-runtime/src
GAMESTICK_MALI_R25P0_WAYLAND_RUNTIME_SITE_METHOD = local
GAMESTICK_MALI_R25P0_WAYLAND_RUNTIME_LICENSE = Proprietary
GAMESTICK_MALI_R25P0_WAYLAND_RUNTIME_REDISTRIBUTE = NO
GAMESTICK_MALI_R25P0_WAYLAND_RUNTIME_DEPENDENCIES = rockchip-mali

define GAMESTICK_MALI_R25P0_WAYLAND_RUNTIME_INSTALL_TARGET_CMDS
	mkdir -p $(TARGET_DIR)/usr/lib/mali
	rm -f $(TARGET_DIR)/usr/lib/libmali-bifrost-g31-rxp0-gbm.so
	rm -f $(TARGET_DIR)/usr/lib/libmali-bifrost-g31-g24p0-gbm.so
	rm -f $(TARGET_DIR)/usr/lib/libmali-bifrost-g52-g24p0-gbm.so
	rm -f $(TARGET_DIR)/usr/lib/libmali-bifrost-g52-g13p0-gbm.so
	rm -f $(TARGET_DIR)/usr/lib/libmali-bifrost-g52-r25p0-gbm.so
	rm -f $(TARGET_DIR)/usr/lib/libmali-bifrost-g52-r25p0-wayland.so
	rm -f $(TARGET_DIR)/usr/lib/libmali.so
	rm -f $(TARGET_DIR)/usr/lib/libmali.so.1
	rm -f $(TARGET_DIR)/usr/lib/libmali.so.1.9.0
	rm -f $(TARGET_DIR)/usr/lib/libMali.so
	rm -f $(TARGET_DIR)/usr/lib/libMali.so.1
	rm -f $(TARGET_DIR)/usr/lib/libEGL.so
	rm -f $(TARGET_DIR)/usr/lib/libEGL.so.1
	rm -f $(TARGET_DIR)/usr/lib/libGLESv1_CM.so
	rm -f $(TARGET_DIR)/usr/lib/libGLESv1_CM.so.1
	rm -f $(TARGET_DIR)/usr/lib/libGLESv2.so
	rm -f $(TARGET_DIR)/usr/lib/libGLESv2.so.2
	rm -f $(TARGET_DIR)/usr/lib/libgbm.so
	rm -f $(TARGET_DIR)/usr/lib/libgbm.so.1
	rm -f $(TARGET_DIR)/usr/lib/libwayland-egl.so
	rm -f $(TARGET_DIR)/usr/lib/libwayland-egl.so.1
	rm -f $(TARGET_DIR)/usr/lib/libffi.so.8
	rm -f $(TARGET_DIR)/usr/lib/libffi.so.8.1.2
	rm -f $(TARGET_DIR)/usr/lib/libwayland-client.so.0
	rm -f $(TARGET_DIR)/usr/lib/libwayland-client.so.0.21.0
	rm -f $(TARGET_DIR)/usr/lib/libwayland-server.so.0
	rm -f $(TARGET_DIR)/usr/lib/libwayland-server.so.0.21.0
	rm -f $(TARGET_DIR)/usr/lib/mali/libEGL.so
	rm -f $(TARGET_DIR)/usr/lib/mali/libEGL.so.1
	rm -f $(TARGET_DIR)/usr/lib/mali/libGLESv1_CM.so
	rm -f $(TARGET_DIR)/usr/lib/mali/libGLESv1_CM.so.1
	rm -f $(TARGET_DIR)/usr/lib/mali/libGLESv2.so
	rm -f $(TARGET_DIR)/usr/lib/mali/libGLESv2.so.2
	rm -f $(TARGET_DIR)/usr/lib/mali/libMali.so
	rm -f $(TARGET_DIR)/usr/lib/mali/libMali.so.1
	rm -f $(TARGET_DIR)/usr/lib/mali/libgbm.so
	rm -f $(TARGET_DIR)/usr/lib/mali/libgbm.so.1
	rm -f $(TARGET_DIR)/usr/lib/mali/libwayland-egl.so
	rm -f $(TARGET_DIR)/usr/lib/mali/libwayland-egl.so.1
	$(INSTALL) -D -m 0755 $(@D)/r25p0-wayland/usr/lib/aarch64-linux-gnu/libmali.so.1.9.0 \
		$(TARGET_DIR)/usr/lib/libmali.so.1.9.0
	$(INSTALL) -D -m 0755 $(@D)/r25p0-wayland/usr/lib/aarch64-linux-gnu/mali/libEGL.so.1 \
		$(TARGET_DIR)/usr/lib/mali/libEGL.so.1
	$(INSTALL) -D -m 0755 $(@D)/r25p0-wayland/usr/lib/aarch64-linux-gnu/mali/libGLESv1_CM.so.1 \
		$(TARGET_DIR)/usr/lib/mali/libGLESv1_CM.so.1
	$(INSTALL) -D -m 0755 $(@D)/r25p0-wayland/usr/lib/aarch64-linux-gnu/mali/libGLESv2.so.2 \
		$(TARGET_DIR)/usr/lib/mali/libGLESv2.so.2
	$(INSTALL) -D -m 0755 $(@D)/r25p0-wayland/usr/lib/aarch64-linux-gnu/mali/libMali.so.1 \
		$(TARGET_DIR)/usr/lib/mali/libMali.so.1
	$(INSTALL) -D -m 0755 $(@D)/r25p0-wayland/usr/lib/aarch64-linux-gnu/mali/libgbm.so.1 \
		$(TARGET_DIR)/usr/lib/mali/libgbm.so.1
	$(INSTALL) -D -m 0755 $(@D)/r25p0-wayland/usr/lib/aarch64-linux-gnu/mali/libwayland-egl.so.1 \
		$(TARGET_DIR)/usr/lib/mali/libwayland-egl.so.1
	$(INSTALL) -D -m 0755 $(@D)/wayland-runtime/libffi8/usr/lib/aarch64-linux-gnu/libffi.so.8.1.2 \
		$(TARGET_DIR)/usr/lib/libffi.so.8.1.2
	$(INSTALL) -D -m 0755 $(@D)/wayland-runtime/libwayland-client0/usr/lib/aarch64-linux-gnu/libwayland-client.so.0.21.0 \
		$(TARGET_DIR)/usr/lib/libwayland-client.so.0.21.0
	$(INSTALL) -D -m 0755 $(@D)/wayland-runtime/libwayland-server0/usr/lib/aarch64-linux-gnu/libwayland-server.so.0.21.0 \
		$(TARGET_DIR)/usr/lib/libwayland-server.so.0.21.0
	ln -sfn libmali.so.1 $(TARGET_DIR)/usr/lib/libmali-bifrost-g52-r25p0-wayland.so
	ln -sfn libmali.so.1 $(TARGET_DIR)/usr/lib/libmali-bifrost-g52-r25p0-gbm.so
	ln -sfn libmali.so.1.9.0 $(TARGET_DIR)/usr/lib/libmali.so.1
	ln -sfn libmali.so.1 $(TARGET_DIR)/usr/lib/libmali.so
	ln -sfn libmali.so.1 $(TARGET_DIR)/usr/lib/libMali.so
	ln -sfn libEGL.so.1 $(TARGET_DIR)/usr/lib/mali/libEGL.so
	ln -sfn libGLESv1_CM.so.1 $(TARGET_DIR)/usr/lib/mali/libGLESv1_CM.so
	ln -sfn libGLESv2.so.2 $(TARGET_DIR)/usr/lib/mali/libGLESv2.so
	ln -sfn libMali.so.1 $(TARGET_DIR)/usr/lib/mali/libMali.so
	ln -sfn libgbm.so.1 $(TARGET_DIR)/usr/lib/mali/libgbm.so
	ln -sfn libwayland-egl.so.1 $(TARGET_DIR)/usr/lib/mali/libwayland-egl.so
	ln -sfn mali/libEGL.so.1 $(TARGET_DIR)/usr/lib/libEGL.so.1
	ln -sfn libEGL.so.1 $(TARGET_DIR)/usr/lib/libEGL.so
	ln -sfn mali/libGLESv1_CM.so.1 $(TARGET_DIR)/usr/lib/libGLESv1_CM.so.1
	ln -sfn libGLESv1_CM.so.1 $(TARGET_DIR)/usr/lib/libGLESv1_CM.so
	ln -sfn mali/libGLESv2.so.2 $(TARGET_DIR)/usr/lib/libGLESv2.so.2
	ln -sfn libGLESv2.so.2 $(TARGET_DIR)/usr/lib/libGLESv2.so
	ln -sfn mali/libgbm.so.1 $(TARGET_DIR)/usr/lib/libgbm.so.1
	ln -sfn libgbm.so.1 $(TARGET_DIR)/usr/lib/libgbm.so
	ln -sfn mali/libwayland-egl.so.1 $(TARGET_DIR)/usr/lib/libwayland-egl.so.1
	ln -sfn libwayland-egl.so.1 $(TARGET_DIR)/usr/lib/libwayland-egl.so
	ln -sfn libffi.so.8.1.2 $(TARGET_DIR)/usr/lib/libffi.so.8
	ln -sfn libwayland-client.so.0.21.0 $(TARGET_DIR)/usr/lib/libwayland-client.so.0
	ln -sfn libwayland-server.so.0.21.0 $(TARGET_DIR)/usr/lib/libwayland-server.so.0
endef

$(eval $(generic-package))
