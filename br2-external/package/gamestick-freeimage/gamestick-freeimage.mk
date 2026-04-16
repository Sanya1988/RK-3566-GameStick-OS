################################################################################
#
# gamestick-freeimage
#
################################################################################

GAMESTICK_FREEIMAGE_VERSION = 3180
GAMESTICK_FREEIMAGE_SOURCE = FreeImage$(GAMESTICK_FREEIMAGE_VERSION).zip
GAMESTICK_FREEIMAGE_SITE = https://downloads.sourceforge.net/project/freeimage/Source%20Distribution/3.18.0
GAMESTICK_FREEIMAGE_LICENSE = FIPL-1.0
GAMESTICK_FREEIMAGE_LICENSE_FILES = license-fi.txt
GAMESTICK_FREEIMAGE_INSTALL_STAGING = YES
GAMESTICK_FREEIMAGE_INCLUDE_FLAGS = \
	-I. \
	-ISource \
	-ISource/Metadata \
	-ISource/FreeImageToolkit \
	-ISource/LibJPEG \
	-ISource/LibPNG \
	-ISource/LibTIFF4 \
	-ISource/ZLib \
	-ISource/LibOpenJPEG \
	-ISource/OpenEXR \
	-ISource/OpenEXR/Half \
	-ISource/OpenEXR/Iex \
	-ISource/OpenEXR/IlmImf \
	-ISource/OpenEXR/IlmThread \
	-ISource/OpenEXR/Imath \
	-ISource/OpenEXR/IexMath \
	-ISource/LibRawLite \
	-ISource/LibRawLite/dcraw \
	-ISource/LibRawLite/internal \
	-ISource/LibRawLite/libraw \
	-ISource/LibRawLite/src \
	-ISource/LibWebP \
	-ISource/LibJXR \
	-ISource/LibJXR/common/include \
	-ISource/LibJXR/image/sys \
	-ISource/LibJXR/jxrgluelib

define GAMESTICK_FREEIMAGE_EXTRACT_CMDS
	rm -rf $(@D)
	mkdir -p $(@D)
	rm -rf $(BUILD_DIR)/.gamestick-freeimage-extract
	mkdir -p $(BUILD_DIR)/.gamestick-freeimage-extract
	unzip -q $(DL_DIR)/gamestick-freeimage/$(GAMESTICK_FREEIMAGE_SOURCE) -d $(BUILD_DIR)/.gamestick-freeimage-extract
	mv $(BUILD_DIR)/.gamestick-freeimage-extract/FreeImage/* $(@D)/
	rmdir $(BUILD_DIR)/.gamestick-freeimage-extract/FreeImage
	rmdir $(BUILD_DIR)/.gamestick-freeimage-extract
endef

define GAMESTICK_FREEIMAGE_FIX_LIBJXR_BYTESWAP_DECL
	if ! grep -q 'U32 _byteswap_ulong(U32 bits);' $(@D)/Source/LibJXR/image/sys/strcodec.h; then \
		awk '{ \
			print; \
			if (index($$0, "#endif // PLATFORM_ANSI") == 1) { \
				print ""; \
				print "#if !((defined(WIN32) && !defined(UNDER_CE) && (!defined(__MINGW32__) || defined(__MINGW64_TOOLCHAIN__))) || (defined(UNDER_CE) && defined(_ARM_))) && !defined(_BIG__ENDIAN_)"; \
				print "U32 _byteswap_ulong(U32 bits);"; \
				print "#endif"; \
			} \
		}' $(@D)/Source/LibJXR/image/sys/strcodec.h > $(@D)/Source/LibJXR/image/sys/strcodec.h.tmp; \
		mv $(@D)/Source/LibJXR/image/sys/strcodec.h.tmp $(@D)/Source/LibJXR/image/sys/strcodec.h; \
	fi
endef

define GAMESTICK_FREEIMAGE_FIX_LIBJXR_WCSLEN_INCLUDE
	if ! grep -q '^#include <wchar.h>' $(@D)/Source/LibJXR/jxrgluelib/JXRGlueJxr.c; then \
		awk '{ \
			print; \
			if ($$0 == "#include <limits.h>\r" || $$0 == "#include <limits.h>") { \
				print "#include <wchar.h>"; \
			} \
		}' $(@D)/Source/LibJXR/jxrgluelib/JXRGlueJxr.c > $(@D)/Source/LibJXR/jxrgluelib/JXRGlueJxr.c.tmp; \
		mv $(@D)/Source/LibJXR/jxrgluelib/JXRGlueJxr.c.tmp $(@D)/Source/LibJXR/jxrgluelib/JXRGlueJxr.c; \
	fi
endef

GAMESTICK_FREEIMAGE_POST_PATCH_HOOKS += GAMESTICK_FREEIMAGE_FIX_LIBJXR_BYTESWAP_DECL
GAMESTICK_FREEIMAGE_POST_PATCH_HOOKS += GAMESTICK_FREEIMAGE_FIX_LIBJXR_WCSLEN_INCLUDE

define GAMESTICK_FREEIMAGE_BUILD_CMDS
	$(TARGET_MAKE_ENV) $(MAKE) -C $(@D) -f Makefile.gnu \
		CC="$(TARGET_CC)" \
		CXX="$(TARGET_CXX)" \
		AR="$(TARGET_AR)" \
		CFLAGS="$(TARGET_CFLAGS) -fPIC -fexceptions -fvisibility=hidden -DOPJ_STATIC -DNO_LCMS -DDISABLE_PERF_MEASUREMENT -D__ANSI__ -DPNG_ARM_NEON_OPT=0 $(GAMESTICK_FREEIMAGE_INCLUDE_FLAGS)" \
		CXXFLAGS="$(TARGET_CXXFLAGS) -std=gnu++11 -fPIC -fexceptions -fvisibility=hidden -Wno-ctor-dtor-privacy -D__ANSI__ -DPNG_ARM_NEON_OPT=0 $(GAMESTICK_FREEIMAGE_INCLUDE_FLAGS)" \
		LDFLAGS="$(TARGET_LDFLAGS)"
endef

define GAMESTICK_FREEIMAGE_INSTALL_STAGING_CMDS
	$(INSTALL) -D -m 0644 $(@D)/Source/FreeImage.h $(STAGING_DIR)/usr/include/FreeImage.h
	$(INSTALL) -D -m 0644 $(@D)/libfreeimage.a $(STAGING_DIR)/usr/lib/libfreeimage.a
	$(INSTALL) -D -m 0755 $(@D)/libfreeimage-3.18.0.so $(STAGING_DIR)/usr/lib/libfreeimage-3.18.0.so
	ln -snf libfreeimage-3.18.0.so $(STAGING_DIR)/usr/lib/libfreeimage.so.3
	ln -snf libfreeimage.so.3 $(STAGING_DIR)/usr/lib/libfreeimage.so
endef

define GAMESTICK_FREEIMAGE_INSTALL_TARGET_CMDS
	$(INSTALL) -D -m 0755 $(@D)/libfreeimage-3.18.0.so $(TARGET_DIR)/usr/lib/libfreeimage-3.18.0.so
	ln -snf libfreeimage-3.18.0.so $(TARGET_DIR)/usr/lib/libfreeimage.so.3
	ln -snf libfreeimage.so.3 $(TARGET_DIR)/usr/lib/libfreeimage.so
endef

$(eval $(generic-package))
