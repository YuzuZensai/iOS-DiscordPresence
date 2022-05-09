export TARGET := iphone:clang:latest:7.0
export ARCHS = armv7 arm64 arm64e
export SYSROOT = $(THEOS)/sdks/iPhoneOS14.5.sdk

INSTALL_TARGET_PROCESSES = SpringBoard
SUBPROJECTS += Tweak Preferences

include $(THEOS)/makefiles/common.mk
include $(THEOS_MAKE_PATH)/aggregate.mk
