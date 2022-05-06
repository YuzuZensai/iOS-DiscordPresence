#import <Tweak.h>

SBApplication* focusedApplication = nil;
NSString* lastKnownBundleIdentifier = nil;
Boolean isDeviceLocked = true;

%hook SpringBoard

-(void)frontDisplayDidChange:(id)arg1 {

    %orig;
    // Switched to SpringBoard
    if(arg1 == nil) {
        // If switched from SpringBoard to SpringBoard, ignore
        if(focusedApplication == arg1) return;

        // User is not in any application, clear the presence
        focusedApplication = nil;
        [self updateDiscordPresence:focusedApplication withState:@"STOP"];
        
        return;
    }

    // Switched to Application
    else if ([arg1 isKindOfClass:[%c(SBApplication) class]]) {
        SBApplication *app = arg1;

        Boolean isSystemApplication = [app isSystemApplication];
        Boolean isGameApplication = [self isSBApplicationAGame:app];

        // Switched to itself, ignore
        if (focusedApplication == app) return;

        // Ignore if the application is system application or is not a game
        if(isSystemApplication || !isGameApplication) {
            // Remove any focused application, since the user switched to non game or system application
            if(focusedApplication != nil) {
                // Remove current focused application and stop the presence
                focusedApplication = nil;
                [self updateDiscordPresence:focusedApplication withState:@"STOP"];
            }
            return;
        }

        // Didn't switched from one application to another, start new presence
        if(focusedApplication == nil) {
            focusedApplication = app;
            [self updateDiscordPresence:focusedApplication withState:@"START"];
        }

        // Switched from one application to another, update the presence
        else {
            focusedApplication = app;
            [self updateDiscordPresence:focusedApplication withState:@"UPDATE"];
        }

        return;
    }
}

%new
- (bool)isSBApplicationAGame:(SBApplication *)app {
    SBApplicationInfo *appInfo = [app info];
    NSArray *category = [appInfo iTunesCategoriesOrderedByRelevancy];
    //NSString *categoryStr = [category componentsJoinedByString:@", "];

    // Does application contains "Games" category?
    return [category containsObject:@"Games"];
}

%new
-(void)updateDiscordPresence:(id)arg1 withState:(NSString *)state {

    if(![arg1 isKindOfClass:[%c(SBApplication) class]] && arg1 != nil) return;
    NSString *accessToken = @"";

    // TODO: Make settings preferences or somehow fetch Discord token from the app?
    // Load discord token from text file at /var/mobile/Documents/DiscordToken.txt
    NSString* content = [NSString
        stringWithContentsOfFile: @"/var/mobile/Documents/DiscordToken.txt"
        encoding:NSUTF8StringEncoding
        error:NULL
    ];

    if(content != nil)
        accessToken = content;

    // If SBApplication is passed
    if(arg1 != nil) {
        SBApplication *app = (SBApplication *)arg1;
        [self sendRequestToDiscord:accessToken withBundleIdentifier:[app bundleIdentifier] withState:state];
    }
    // No SBApplication passed, only STOP should be sent
    else {
        if(![state isEqualToString: @"STOP"]) return;
        [self sendRequestToDiscord:accessToken withBundleIdentifier:nil withState:state];
    }
}

%new
-(void)sendRequestToDiscord:(NSString *)accessToken withBundleIdentifier:(NSString *)bundleIdentifier withState:(NSString *)state {

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
        else
        {
            NSLog(@"Error from discord, Status Code: %ld", (long)httpResponse.statusCode);     
        }
    }];
    [dataTask resume];
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
        [[%c(SpringBoard) sharedApplication] updateDiscordPresence:focusedApplication withState:@"STOP"];
    }
}
%end
