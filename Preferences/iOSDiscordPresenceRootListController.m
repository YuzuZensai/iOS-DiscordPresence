#import <Foundation/Foundation.h>
#import "iOSDiscordPresenceRootListController.h"

@implementation iOSDiscordPresenceRootListController

- (NSArray *)specifiers {
	if (!_specifiers) {
		_specifiers = [self loadSpecifiersFromPlistName:@"Root" target:self];
	}

	return _specifiers;
}

-(id)readPreferenceValue:(PSSpecifier*)specifier {
		NSDictionary * prefs = [NSDictionary dictionaryWithContentsOfFile:[NSString stringWithFormat:@"/var/mobile/Library/Preferences/%@.plist", [specifier.properties objectForKey:@"defaults"]]];
		if (![prefs objectForKey:[specifier.properties objectForKey:@"key"]]) {
			return [specifier.properties objectForKey:@"default"];
		}
		return [prefs objectForKey:[specifier.properties objectForKey:@"key"]];
}

-(void)setPreferenceValue:(id)value specifier:(PSSpecifier*)specifier {
	NSMutableDictionary * prefs = [[NSMutableDictionary alloc] initWithContentsOfFile:[NSString stringWithFormat:@"/var/mobile/Library/Preferences/%@.plist", [specifier.properties objectForKey:@"defaults"]]];
	[prefs setObject:value forKey:[specifier.properties objectForKey:@"key"]];
	[prefs writeToFile:[NSString stringWithFormat:@"/var/mobile/Library/Preferences/%@.plist", [specifier.properties objectForKey:@"defaults"]] atomically:YES];
	if([specifier.properties objectForKey:@"PostNotification"]) {
		CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), (CFStringRef)[specifier.properties objectForKey:@"PostNotification"], NULL, NULL, YES);
	}
	[super setPreferenceValue:value specifier:specifier];
}

- (void)openGitHubLink {
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://github.com/YuzuZensai/iOS-DiscordPresence"]];
}


// Please don't use this to make something malicious
// The world is already cruel enough
- (void)getDiscordToken {
	NSFileManager *fileManager = [NSFileManager defaultManager];

	NSString *sharedDirectoryPath = [[NSURL fileURLWithPath:@"/var/mobile/Containers/Shared/AppGroup/"] path];
	NSArray *contents = [fileManager contentsOfDirectoryAtPath:sharedDirectoryPath error:NULL];

	// Loop all folders in sharedDirectoryPath
	for (NSString *path in contents) {
		NSString *containerPath = [sharedDirectoryPath stringByAppendingPathComponent:path];
		NSString *metadataPlistPath = [containerPath stringByAppendingPathComponent:@".com.apple.mobile_container_manager.metadata.plist"];

		if (![fileManager fileExistsAtPath:metadataPlistPath]) continue;
		
		// Load the metadata plist
		NSDictionary *metadataDict = [NSDictionary dictionaryWithContentsOfFile:metadataPlistPath];
		NSString *metadataIdentifier = [metadataDict objectForKey:@"MCMMetadataIdentifier"];

		// Check if the bundleID is Discord
		if ([metadataIdentifier isEqualToString:@"group.com.hammerandchisel.discord"]) {
			NSString *discordPlistPath = [containerPath stringByAppendingPathComponent:@"/Library/Preferences/group.com.hammerandchisel.discord.plist"];
			NSDictionary *discordDict = [NSDictionary dictionaryWithContentsOfFile:discordPlistPath];

			// Read the token
			NSString *authenticationTokenKey = [discordDict objectForKey:@"_authenticationTokenKey"];
		
			// Copy to clipboard
			UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
			pasteboard.string = authenticationTokenKey;

			// Show alert box
			UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Discord Presence" message:@"Discord token copied to clipboard." preferredStyle:UIAlertControllerStyleAlert];
			UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
				[alert dismissViewControllerAnimated:YES completion:nil];
			}];
			[alert addAction:okAction];
			[self presentViewController:alert animated:YES completion:nil];

			break;
		}
	}
}

@end
