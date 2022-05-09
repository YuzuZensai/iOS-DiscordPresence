TARGET := iphone:clang:latest:7.0

include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = iOSDiscordPresencePreferences

iOSDiscordPresencePreferences_FILES = iOSDiscordPresenceRootListController.m
iOSDiscordPresencePreferences_FRAMEWORKS = UIKit
iOSDiscordPresencePreferences_PRIVATE_FRAMEWORKS = Preferences
iOSDiscordPresencePreferences_INSTALL_PATH = /Library/PreferenceBundles
iOSDiscordPresencePreferences_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/bundle.mk
