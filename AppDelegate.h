//
//  AppDelegate.h
//  QASA
//
//  Created by Raju M on 03/08/15.
//  Copyright (c) 2015 Raju M. All rights reserved.
//

#import <UIKit/UIKit.h>
@class SWRevealViewController;
@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) SWRevealViewController *viewController;
@property (strong, nonatomic) NSString *strLatitude;
@property (strong, nonatomic) NSString *strLangitude;
@property (strong, nonatomic) NSString *strDeviceId;
@property (strong, nonatomic) NSString *macID;
@property (strong, nonatomic) NSString *hubIPGlobal;
@property (strong, nonatomic) NSMutableArray *roomNamesArray;
@property (strong, nonatomic) NSMutableArray *roomImgNamesArray;
@property (strong, nonatomic) NSMutableArray *roomsArray;
@property (strong, nonatomic) NSMutableArray *themesArray;
@property (assign, readwrite) BOOL isRoomsAddOrDel;
@property (assign, readwrite) BOOL isSleepAll;
@property (assign, readwrite) BOOL isUserAuthorised;
@property (assign, readwrite) BOOL isFromLogin;
@property (assign, readwrite) CGFloat greaterPixelDimension;
-(NSDictionary *)isUserRegistered;
-(NSString *)lastSuccessReponseStr;

@property (strong, nonatomic) NSString *strLatitude1;
@property (strong, nonatomic) NSString *strLangitude1;

@end


