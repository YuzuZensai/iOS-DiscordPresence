#import <Tweak.h>

// Variables to store value from preferences
Boolean isEnabled = false;
NSString* discordToken = nil;

SBApplication* focusedApplication = nil;
NSString* lastKnownBundleIdentifier = nil;
Boolean isDeviceLocked = true;

// Rate-limit of Discord API requests
float requestRate = 4.0; // Requests
float requestPer = 25.0; // Seconds
float requestAllowance = 0; //The bucket, Initialized with 0
CFTimeInterval requestLastCheck; // Last time when the request was checked

static void showDiscordRatelimitAlert() {
    // Dispatch the alert after 1 seconds, to prevent it being closed automatically if user interacted with something it might think that user trying to dismiss the alert
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        NSMutableDictionary* dict = [NSMutableDictionary dictionary];
        [dict setObject: @"iOS-DiscordPresence" forKey: (__bridge NSString*)kCFUserNotificationAlertHeaderKey];
        [dict setObject: @"⚠️ Hey, slow down! ⚠️\n\nDiscord has rate-limited you\n\nContinuing to spam requests to discord can be considered API abuse, which may result in your discord account being suspended\n\nIf you did nothing and got rate-limited by Discord, it is possible that your IP address is blocked from their server or you are using multiple devices that are updating the presence or something is triggering the tweak to send the request too many time\n\nYou can disable the tweak for a while and try again later" forKey: (__bridge NSString*)kCFUserNotificationAlertMessageKey];
        [dict setObject: @"Close" forKey:(__bridge NSString*)kCFUserNotificationDefaultButtonTitleKey];

        SInt32 error = 0;
        CFUserNotificationRef alert = CFUserNotificationCreate(NULL, 0, kCFUserNotificationPlainAlertLevel, &error, (__bridge CFDictionaryRef)dict);
        CFRelease(alert);
    });
}

static Boolean isSBApplicationAGame(SBApplication* app) {
    SBApplicationInfo *appInfo = [app info];
    NSArray *category = [appInfo iTunesCategoriesOrderedByRelevancy];
   
    // Does application contains "Games" category?
    return [category containsObject:@"Games"];
}

static void sendRequestToDiscord(NSString *accessToken, NSString *bundleIdentifier, NSString *state) {
    // Discord API Presences endpoint
    NSMutableURLRequest *urlRequest = [[NSMutableURLRequest alloc]
        initWithURL:[NSURL URLWithString:@"https://discord.com/api/v6/presences"]
    ];

    // Our body payload
    NSDictionary *jsonBodyDict;
    if(bundleIdentifier != nil) {
        jsonBodyDict = @{ @"package_name":bundleIdentifier, @"update": state };
        NSLog(@"Sending: Package_name: %@ State: %@", bundleIdentifier, state);
    }
    else {
        if(lastKnownBundleIdentifier == nil) return;
        jsonBodyDict = @{ @"package_name":lastKnownBundleIdentifier, @"update": state };
        NSLog(@"Sending: Package_name: %@ State: %@", lastKnownBundleIdentifier, state);
    }

    lastKnownBundleIdentifier = bundleIdentifier;

    // Serializate to body JSON
    NSData *jsonBodyData = [NSJSONSerialization dataWithJSONObject:jsonBodyDict options:kNilOptions error:nil];
    if(jsonBodyData == nil) return;

    //Apply the data to the body
    [urlRequest setHTTPBody:jsonBodyData];

    // Set the request method to POST
    [urlRequest setHTTPMethod:@"POST"];

    // Set headers
    // Clean user token
    NSString *token = [accessToken stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    [urlRequest setValue:token forHTTPHeaderField:@"Authorization"];
    [urlRequest setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [urlRequest setValue:@"max-age=121" forHTTPHeaderField:@"Cache-Control"];
    // Use Android useragent. Well, so it's not sus
    [urlRequest setValue:@"Mozilla/5.0 (Linux; Android 11) AppleWebKit/537.36 (KHTML, like Gecko) Version/4.0 Chrome/100.0.4896.127 Mobile OceanHero/6 Safari/537.36" forHTTPHeaderField:@"User-Agent"];

    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *dataTask = [session dataTaskWithRequest:urlRequest completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        if(httpResponse.statusCode == 204)
        {
            NSLog(@"Request sent to Discord successfully");
        }
        else if (httpResponse.statusCode == 429) {
            NSLog(@"Request rate limited, applying rate limit");
            requestLastCheck = CACurrentMediaTime();
            requestAllowance = 0;
            showDiscordRatelimitAlert();
        }
        else
        {
            NSLog(@"Error from discord, Status Code: %ld", (long)httpResponse.statusCode);     
        }
    }];
    [dataTask resume];
}

static void updateDiscordPresence(id arg1, NSString *state) {

    if(![arg1 isKindOfClass:[%c(SBApplication) class]] && arg1 != nil) return;

    
    if(!isEnabled) return;

    //Rate limit check
    CFTimeInterval now = CACurrentMediaTime();
    CFTimeInterval timePassed = now - requestLastCheck;
    requestLastCheck = now;

    requestAllowance += timePassed * (requestRate / requestPer);
    
    NSLog(@"Request allowance: %f", requestAllowance);

    if(requestAllowance > requestRate)
        requestAllowance = requestRate;

    if(requestAllowance < 1.0) {
        NSLog(@"Request not sent, rate limted");
        return;
    }

    else
        requestAllowance -= 1.0;

    NSString *accessToken = @"";

    if(discordToken != nil)
        accessToken = discordToken;

    // If SBApplication is passed
    if(arg1 != nil) {
        SBApplication *app = (SBApplication *)arg1;
        sendRequestToDiscord(accessToken, [app bundleIdentifier], state);
    }
    // No SBApplication passed, only STOP should be sent
    else {
        if(![state isEqualToString: @"STOP"]) return;
        sendRequestToDiscord(accessToken, nil, state);
    }
}

%hook SpringBoard

-(void)frontDisplayDidChange:(id)arg1 {

    %orig;

    // Switched to SpringBoard
    if(arg1 == nil) {
        // If switched from SpringBoard to SpringBoard, ignore
        if(focusedApplication == arg1) return;

        // User is not in any application, clear the presence
        focusedApplication = nil;
        updateDiscordPresence(focusedApplication, @"STOP");
        
        return;
    }

    // Switched to Application
    else if ([arg1 isKindOfClass:[%c(SBApplication) class]]) {
        SBApplication *app = arg1;

        Boolean isSystemApplication = [app isSystemApplication];
        Boolean isGameApplication = isSBApplicationAGame(app);

        // Switched to itself, ignore
        if (focusedApplication == app) return;

        // Ignore if the application is system application or is not a game
        if(isSystemApplication || !isGameApplication) {
            // Remove any focused application, since the user switched to non game or system application
            if(focusedApplication != nil) {
                // Remove current focused application and stop the presence
                focusedApplication = nil;
                updateDiscordPresence(focusedApplication, @"STOP");
            }
            return;
        }

        // Didn't switched from one application to another, start new presence
        if(focusedApplication == nil) {
            focusedApplication = app;
            updateDiscordPresence(focusedApplication, @"START");
        }

        // Switched from one application to another, update the presence
        else {
            focusedApplication = app;
            updateDiscordPresence(focusedApplication, @"UPDATE");
        }

        return;
    }
}
%end

%hook SBLockScreenManager

-(void)_authenticationStateChanged:(id)arg1 {

    %orig;

    // Get the state changed notification, and find the SBFUserAuthenticationStateWasAuthenticatedKey value
    NSConcreteNotification *notification = arg1;
    int state = [[[notification userInfo] objectForKey: @"SBFUserAuthenticationStateWasAuthenticatedKey"] integerValue];

    isDeviceLocked = state != 0;
    // We don't need to take care anything else here. The frontDisplayDidChange will take care of it
}

-(void)_sendUILockStateChangedNotification {

    %orig;

    // The phone is locked or focused application is nil, ignore
    if(isDeviceLocked || focusedApplication == nil) return;
    // If the phone is unlocked, then the user is peeking at the notification or didn't swipe up to unlock yet.

    Boolean isOnLockScreen = [self isLockScreenVisible];

    // Switched to the lockscreen UI
    if(isOnLockScreen) {
        // Remove current focused application and stop the presence
        focusedApplication = nil;
        updateDiscordPresence(focusedApplication, @"STOP");
    }
}
%end

static void loadPreferences()
{
    NSString *preferencesPath = @"/var/mobile/Library/Preferences/pink.kirameki.yuzu.iosdiscordpresencepreferences.plist";
    NSMutableDictionary *preferences = [[NSMutableDictionary alloc] initWithContentsOfFile: preferencesPath];
    if(preferences)
    {
        NSLog(@"Updating preferences"); 

        isEnabled = ( [preferences objectForKey:@"isEnabled"] ? [[preferences objectForKey:@"isEnabled"] boolValue] : isEnabled );
        discordToken = ( [preferences objectForKey:@"discordToken"] ? [preferences objectForKey:@"discordToken"] : discordToken );
    }
}

%ctor 
{
    requestAllowance = requestRate;
    requestLastCheck = CACurrentMediaTime();
    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, (CFNotificationCallback)loadPreferences, CFSTR("pink.kirameki.yuzu.iosdiscordpresencepreferences/PreferencesChanged"), NULL, CFNotificationSuspensionBehaviorCoalesce);
    loadPreferences();
}