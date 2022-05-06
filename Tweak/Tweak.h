#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>
#import <Foundation/Foundation.h>
#import <Foundation/NSObjCRuntime.h>
#import <SpringBoard/SpringBoard.h>
#import <SpringBoard/SBApplication.h>
#import <SpringBoard/SBApplicationInfo.h>
#import <SpringBoard/SBLockScreenManager.h>

@interface NSConcreteNotification
    @property(nonatomic, retain) NSString *name;   
    @property(nonatomic, retain) id object;
    @property(nonatomic, retain) NSDictionary *userInfo;
@end

@interface SpringBoard (Tweak)
    - (void)updateDiscordPresence:(id)arg1 withState:(NSString *)state;
    - (void)sendRequestToDiscord:(NSString *)accessToken withBundleIdentifier:(NSString *)bundleIdentifier withState:(NSString *)state;
    - (bool)isSBApplicationAGame:(SBApplication *)arg1;
@end

@interface UIApplication (Tweak)
    - (void)updateDiscordPresence:(id)arg1 withState:(NSString *)state;
@end

@interface SBApplication (Tweak)
    @property (nonatomic,readonly) NSString * bundleIdentifier;
    @property (getter=isSystemApplication,nonatomic,readonly) BOOL systemApplication; 
    @property (nonatomic,copy,readonly) NSArray * iTunesCategoriesOrderedByRelevancy;   
    @property (nonatomic,readonly) SBApplicationInfo * info;  
@end

@interface SBApplicationInfo (Tweak)
    @property (nonatomic,copy,readonly) NSArray * iTunesCategoriesOrderedByRelevancy;
@end

@interface SBLockScreenManager (Tweak)
    @property (readonly) BOOL isLockScreenVisible;
@end