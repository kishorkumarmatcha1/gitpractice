
//  ViewController.m
//  QASA

#import "HomeViewController.h"
#import "SWRevealViewController.h"
#import "DataServices.h"
#import "AppDelegate.h"
#import "WebRequest.h"
#import "NetworkManager.h"
#import "Reachability.h"
#import "MBProgressHUD.h"
#import "TcpClient.h"
#import "ParseClass.h"
#import "NSString+URLEncoding.h"
#import "RoomData.h"
#import "DeviceData.h"
#import "LoginViewController.h"
#import "DeviceDisplayCustomCell.h"
#import "SchedulerViewController.h"
#import "TCPGlobal.h"

#define SYSTEM_VERSION_LESS_THAN(v)                 ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedAscending)
@interface HomeViewController ()<MBProgressHUDDelegate,WebRequestDelegate,TcpClientDelegate,UIActionSheetDelegate,LoginViewControllerDelegate,UIGestureRecognizerDelegate,SchedulerViewControllerDelegate>
{
    MBProgressHUD *HUD;
    AppDelegate *appDelegate;
    BOOL isFromLogin;
    UIRefreshControl *refreshControl;
    UIBarButtonItem *sleepAllBtn;
    NSString *strImageName;
    NSString *sleepStatusValue;
    NSString *sleepStatusValue1;
}
@property(nonatomic,strong)NSDictionary *userInfoDict;
@property(nonatomic,strong)NSMutableArray *arrDevices;
@property(nonatomic,strong)RoomData *selectedRoomData;
@property(nonatomic,assign)NSInteger selRoomIndex;
@property(nonatomic,assign)NSInteger selDeviceIndex;
@property(nonatomic,strong)NSString* reqString;
@property(nonatomic,assign)BOOL isAllRoomsSleepAll;
@property(nonatomic,assign)BOOL isSelectedRoomSleepAll;
@property(nonatomic,strong)LoginViewController *loginVC;
@property(nonatomic,strong)UIButton *titleLabelButton;
@end

@implementation HomeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Do any additional setup after loading the view, typically from a nib.

    self.automaticallyAdjustsScrollViewInsets = NO;
    self.title = @"Select Room";
    appDelegate = [[UIApplication sharedApplication] delegate];
    _tblViewRoomsList.hidden = YES;
    
    if (appDelegate.greaterPixelDimension == 667) {
        self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"backgroundImage6.png"]];
    }else{
        self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"backgroundImage"]];
    }
    
    self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"backgroundImage"]];
    
    SWRevealViewController *revealController = [self revealViewController];
    [revealController tapGestureRecognizer];
    
    UIBarButtonItem *revealButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"menu"]
                                                                         style:UIBarButtonItemStylePlain target:revealController action:@selector(revealToggle:)];
    
    self.navigationItem.leftBarButtonItem = revealButtonItem;
    
    strImageName = nil;
    if (appDelegate.isSleepAll)
    {
        
        strImageName = @"sleepModeOff";
        sleepAllBtn = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:strImageName]
                                                       style:UIBarButtonItemStylePlain target:self action:@selector(sleepAll)];
        
        self.navigationItem.rightBarButtonItem = sleepAllBtn;
    }
    else
    {
        strImageName = @"bulbOn";
        sleepAllBtn = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:strImageName]
                                                       style:UIBarButtonItemStylePlain target:self action:@selector(sleepAll)];
        
        self.navigationItem.rightBarButtonItem = sleepAllBtn;
    }
    

    
    NSString *roomName = nil;
    if (appDelegate.roomNamesArray && appDelegate.roomNamesArray.count) {
        roomName = [appDelegate.roomNamesArray objectAtIndex:0];
    }else{
        roomName = @"Select Room";
    }
    _titleLabelButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [_titleLabelButton setTitle:roomName forState:UIControlStateNormal];
    _titleLabelButton.frame = CGRectMake(0, 0, 120, 44);
    _titleLabelButton.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    _titleLabelButton.titleLabel.font = [UIFont boldSystemFontOfSize:18];
    _titleLabelButton.titleLabel.textColor = [UIColor whiteColor];
    [_titleLabelButton addTarget:self action:@selector(didTapTitleView:) forControlEvents:UIControlEventTouchUpInside];
    self.navigationItem.titleView = _titleLabelButton;
    
    if (appDelegate.isUserAuthorised) {
        _tblView.hidden = NO;
        self.navigationController.navigationBarHidden = NO;
        [self getTheUserData];
        [self refreshRoomData];
    }else{
        _tblView.hidden = YES;
        _loginVC = [[LoginViewController alloc] init];
        _loginVC.delegate = self;
        _loginVC.view.frame = self.view.bounds;
        [self.view addSubview:_loginVC.view];
        self.navigationController.navigationBarHidden = YES;
    }
    if([UIDevice currentDevice].systemVersion.floatValue < 8.0) {
     self.navigationController.navigationBar.translucent = NO;
    }
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(runTCPAgain:) name:@"runTCP" object:nil];
    
}
- (void)didTapTitleView:(id) sender
{
    NSLog(@"Title tap");
    if (appDelegate.roomNamesArray && appDelegate.roomNamesArray.count) {
        _tblViewRoomsList.hidden = NO;
        [_tblViewRoomsList reloadData];
    }
}
-(void)getTheUserData
{
    _reqString = @"";
    _selRoomIndex = 0;
    _selDeviceIndex = 0;
    _isAllRoomsSleepAll = NO;
    _isSelectedRoomSleepAll = NO;
    NSLog(@"viewdidload");
    self.tblView.tableHeaderView = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, self.tblView.bounds.size.width, 0.01f)];
    _userInfoDict = [appDelegate isUserRegistered];
    
    UISwipeGestureRecognizer *recognizer;
    recognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipeRight:)];
    recognizer.delegate = self;
    [recognizer setDirection:(UISwipeGestureRecognizerDirectionRight)];
    [self.view addGestureRecognizer:recognizer];
    
    recognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipeLeft:)];
    recognizer.delegate = self;
    [recognizer setDirection:(UISwipeGestureRecognizerDirectionLeft)];
    [self.view addGestureRecognizer:recognizer];
    
    UIView *refreshView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, 0)];
    refreshView.backgroundColor = [UIColor redColor];
    [_tblView insertSubview:refreshView atIndex:0]; //the tableView is a IBOutlet
    
    refreshControl = [[UIRefreshControl alloc] init];
    refreshControl.tintColor = [UIColor redColor];
    [refreshControl addTarget:self action:@selector(getDeviceConfigData) forControlEvents:UIControlEventValueChanged];
    [refreshView addSubview:refreshControl];
}
-(void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
//    if ([self isBeingPresented] || [self isMovingToParentViewController]) {
//        // Perform an action that will only be done once
//        if (appDelegate.isUserAuthorised == YES) {
//        //    [self refreshRoomData];
//        }
//    }
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {

    return YES;
}
-(void)loginOrRegisterSuccess:(NSString *)str
{
    self.navigationController.navigationBarHidden = NO;
    CGRect frame = _loginVC.view.frame;
    frame.origin.x = -(self.view.frame.size.width);
    [UIView animateWithDuration:0.6f
                          delay:0.1f
                        options:UIViewAnimationOptionShowHideTransitionViews
                     animations:^{
                         [_loginVC.view setFrame:frame];
                         [_loginVC.view setAlpha:0.0f];
                     }
                     completion:^(BOOL finished){
                        [_loginVC.view removeFromSuperview];
                         _loginVC = nil;
                         _tblView.hidden = NO;
                         [self getTheUserData];
                         if ([@"Login" isEqualToString:str]) {
                             [self refreshRoomData];
                         }
                     }
     ];
}

-(void)getHubIP
{
    sleep(3);
    [NetworkManager getHubIpAddress];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (void)refreshRoomData
{
    HUD = [[MBProgressHUD alloc] initWithView:self.view];
    HUD.color = [UIColor clearColor];
    HUD.delegate = self;
    [self.view addSubview:HUD];
    HUD.taskInProgress = YES;
    [HUD show:YES];
    HUD.dimBackground = YES;
    HUD.labelText = @"Fetching Data Inprogress";
    [self performSelector:@selector(getDeviceConfigData) withObject:nil afterDelay:1];
}

- (void)reloadData
{
    // End the refreshing
    if (refreshControl) {
        
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"MMM d, h:mm a"];
        NSString *title = [NSString stringWithFormat:@"Last update: %@", [formatter stringFromDate:[NSDate date]]];
        NSDictionary *attrsDictionary = [NSDictionary dictionaryWithObject:[UIColor whiteColor]
                                                                    forKey:NSForegroundColorAttributeName];
        NSAttributedString *attributedTitle = [[NSAttributedString alloc] initWithString:title attributes:attrsDictionary];
        refreshControl.attributedTitle = attributedTitle;
        
        [refreshControl endRefreshing];
        
        
    }
}
#pragma mark - Table view data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if (tableView.tag == 1111) {
        if (!_arrDevices) {
            
            // Display a message when the table is empty
            UILabel *messageLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height)];
            
            messageLabel.text = @"No data is currently available. Please Configure the rooms.";
            messageLabel.textColor = [UIColor whiteColor];
            messageLabel.numberOfLines = 0;
            messageLabel.textAlignment = NSTextAlignmentCenter;
            messageLabel.font = [UIFont fontWithName:@"Palatino-Italic" size:20];
            [messageLabel sizeToFit];
            
            _tblView.backgroundView = messageLabel;
            _tblView.separatorStyle = UITableViewCellSeparatorStyleNone;
            return 0;
            
        }
        tableView.backgroundView = nil;
        // Return the number of sections.
        return 1;
    }else{
        return 1;
    }
    return 1;
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (tableView.tag == 1111) {
        return _arrDevices.count;
    }else{
        return appDelegate.roomNamesArray.count;
    }
    return _arrDevices.count;
    
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    if (tableView.tag == 1111) {
        DeviceDisplayCustomCell *cell = (DeviceDisplayCustomCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        if (cell == nil) {
            cell = [[DeviceDisplayCustomCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
            cell.backgroundColor = [UIColor clearColor];
            cell.textLabel.textColor = [UIColor whiteColor];
            cell.detailTextLabel.textColor = [UIColor whiteColor];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            [cell.btnScheduler addTarget:self action:@selector(setTheScheduler:) forControlEvents:UIControlEventTouchUpInside];
            cell.btnScheduler.frame = CGRectMake(self.view.frame.size.width - 110 , 12, 44, 44);
        }
        
        if (_selectedRoomData) {
            NSString *imageName = nil;
            DeviceData *devData = [_arrDevices objectAtIndex:indexPath.row];
            cell.tag = devData.devicePositionIndex;
            cell.textLabel.text = devData.deviceName;
            cell.btnSwitch.tag = devData.devicePositionIndex;
            cell.regulatorSlider.tag = devData.devicePositionIndex;
            cell.btnScheduler.tag = devData.devicePositionIndex;
            NSString *deviceTpe = devData.deviceType;
            //NSLog(@"devData.deviceType...%@",devData.deviceType);
            if ([deviceTpe isEqualToString:@"Switch"]) {
                [cell sliderShow:false];
                if ([devData.deviceStatus isEqualToString:@"ON"]) {
                    cell.detailTextLabel.text = @"Turned ON";
                    [cell.btnSwitch setSelected:YES];
                    
                    NSString *sleepStatus = @"ON";
                    sleepStatusValue = sleepStatus;
                    [[NSUserDefaults standardUserDefaults] setObject:sleepStatusValue forKey:@"sleepStatuss"];
                    [[NSUserDefaults standardUserDefaults] synchronize];
                    
                    if ([@"PLG" isEqualToString:devData.deviceName]) {
                        imageName = @"plugOn";
                        cell.labelNumber.text = @"";
                    }else if ([@"Sleep All" isEqualToString:devData.deviceName]){
                        imageName = @"sleepModeOn";
                        cell.labelNumber.text = @"";
                    }else{
                        cell.labelNumber.text = [NSString stringWithFormat:@"%ld",devData.devicePositionIndex + 1];

                        imageName = @"bulbOn";
                        strImageName = @"sleepModeOff";
                    }
                    
                    cell.labelNumber.textColor = [UIColor whiteColor];
                }else{
                    cell.detailTextLabel.text = @"Turned OFF";
                    [cell.btnSwitch setSelected:NO];
                    
                    NSString *sleepStatus = @"OFF";
                    sleepStatusValue1 = sleepStatus;
                    [[NSUserDefaults standardUserDefaults] setObject:sleepStatusValue1 forKey:@"sleepStatuss"];
                    [[NSUserDefaults standardUserDefaults] synchronize];
                    
                    if ([@"PLG" isEqualToString:devData.deviceName]) {
                        imageName = @"plugOff";
                        cell.labelNumber.text = @"";
                    }else if ([@"Sleep All" isEqualToString:devData.deviceName]){
                        imageName = @"sleepModeOff";
                        cell.labelNumber.text = @"";
                    }else{
                        cell.labelNumber.text = [NSString stringWithFormat:@"%ld",devData.devicePositionIndex + 1];
                        imageName = @"bulbOff";
                        strImageName = @"bulbOn";
                        

                    }
                    cell.labelNumber.textColor = [UIColor grayColor];
                }
                
                [cell.btnSwitch addTarget:self action:@selector(changeSwitch:) forControlEvents:UIControlEventTouchUpInside];
                
            }else{
                [cell sliderShow:true];
                [cell.regulatorSlider addTarget:self action:@selector(sliderAction:) forControlEvents:UIControlEventTouchUpInside];
                cell.regulatorSlider.value = [devData.deviceStatus intValue];
                //NSLog(@"cell.regulatorSlider.value....%f",cell.regulatorSlider.value);
                cell.detailTextLabel.text = [NSString stringWithFormat:@"Level %.f",cell.regulatorSlider.value];
                //NSLog(@"Fan Levels is : %@",cell.detailTextLabel.text);
                
                if ([devData.deviceStatus intValue] > 0) {
                    [cell.btnSwitch setSelected:YES];
                    imageName = @"fanOn";
                    strImageName = @"sleepModeOff";

                }else{
                    [cell.btnSwitch setSelected:NO];
                    imageName = @"fanOff";
                    strImageName = @"bulbOn";

                }
                [cell.btnSwitch addTarget:self action:@selector(changeSwitch:) forControlEvents:UIControlEventTouchUpInside];
            }
            cell.imageView.image = [UIImage imageNamed:imageName];
        }
        
        return cell;
    }else{
        UITableViewCell *cell = (UITableViewCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
            cell.backgroundColor = [UIColor clearColor];
            cell.textLabel.textAlignment = NSTextAlignmentCenter;
            cell.selectionStyle = UITableViewCellEditingStyleNone;
        }
        if (_selRoomIndex == indexPath.row) {
            cell.textLabel.font = [UIFont boldSystemFontOfSize:17];
            cell.textLabel.textColor = [UIColor whiteColor];
        }else{
            cell.textLabel.font = [UIFont systemFontOfSize:17];
            cell.textLabel.textColor = [UIColor lightGrayColor];
        }
        cell.textLabel.text = appDelegate.roomNamesArray[indexPath.row];
        return cell;
    }

    
}
-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath{
    
    if ([tableView respondsToSelector:@selector(setSeparatorInset:)]) {
        [tableView setSeparatorInset:UIEdgeInsetsZero];
    }
    
    if ([tableView respondsToSelector:@selector(setLayoutMargins:)]) {
        [tableView setLayoutMargins:UIEdgeInsetsZero];
    }
    
    if ([cell respondsToSelector:@selector(setLayoutMargins:)]) {
        [cell setLayoutMargins:UIEdgeInsetsZero];
    }
    if (tableView.tag == 2222) {
        cell.textLabel.textAlignment = NSTextAlignmentCenter;
    }
    
}
#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (tableView.tag == 2222) {
        _tblViewRoomsList.hidden = YES;
        _selRoomIndex = indexPath.row;
        if (appDelegate.roomsArray && appDelegate.roomsArray.count) {
            _selectedRoomData = appDelegate.roomsArray[_selRoomIndex];
            NSString *roomName = appDelegate.roomNamesArray[_selRoomIndex];
            [_titleLabelButton setTitle:roomName forState:UIControlStateNormal];
            _arrDevices = [_selectedRoomData.devicesArray mutableCopy];
            for (int i = 0; i<_selectedRoomData.devicesArray.count; i++) {
                DeviceData *devData = [_selectedRoomData.devicesArray objectAtIndex:i];
                if (devData && !devData.deviceName.length) {
                    [_arrDevices removeObject:devData];
                }
            }
            [_tblView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationTop];
        }
    }
}

-(void)sliderAction:(id)sender
{
    HUD = [[MBProgressHUD alloc] initWithView:self.view];
    HUD.color = [UIColor clearColor];
    HUD.delegate = self;
    [self.view addSubview:HUD];
    HUD.taskInProgress = YES;
    [HUD show:YES];
    HUD.dimBackground = YES;
    HUD.labelText = @"Device status update Inprogress";
    UISlider *slider = (UISlider*)sender;
    int value = slider.value;
    NSLog(@"%s slider value: %d", __func__, value);
   
    CGPoint sliderPosition = [sender convertPoint:CGPointZero toView:self.tblView];
    NSIndexPath *indexPath = [self.tblView indexPathForRowAtPoint:sliderPosition];
    UITableViewCell *cell = [self.tblView cellForRowAtIndexPath:indexPath];
    cell.detailTextLabel.text = [NSString stringWithFormat:@"Level %d", (int)(slider.value)];

    int netWorkStatus = [NetworkManager netWorkStatus];
    NSString *deviceState = [ParseClass requlatorCharacter:value];
    NSString *roomAddress = @"";
    NSString *deviceAddress = @"";
    NSInteger seldeviceTag = [sender tag];
    _selDeviceIndex = seldeviceTag;
    roomAddress = [ParseClass requlatorCharacter:_selRoomIndex];
    deviceAddress = [ParseClass requlatorCharacter:_selDeviceIndex];
    if(netWorkStatus == 0)
    {
        [HUD hide:YES];
        
        [_tblView reloadData];
        
        if (SYSTEM_VERSION_LESS_THAN(@"8.0")) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Network Message" message:@"No Internet Connection" delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
            [alert show];
        }
        else{
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Network Message"
                                                                           message:@"No Internet Connection"
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:@"Cancel"
                                                      style:UIAlertActionStyleCancel
                                                    handler:nil]];
            
            [self presentViewController:alert animated:YES completion:nil];
        }
    }
    else if (netWorkStatus == 1 && [[_userInfoDict valueForKey:@"wifiName"] isEqualToString:[NetworkManager fetchSSIDInfo]])
    {
        TcpClient *tcpConnection = [[TcpClient alloc] init];
        tcpConnection.delegate = self;
        NSString *reqStr = [NSString stringWithFormat:@"B%@%@%@",roomAddress,deviceAddress,deviceState];
        [tcpConnection tcpConnectionForHubData:reqStr hubIP:appDelegate.hubIPGlobal];
        
    }else{
        _reqString = [NSString stringWithFormat:@"B%@%@%@",roomAddress,deviceAddress,deviceState];
        NSDictionary *dict= [NSDictionary dictionaryWithObjectsAndKeys:roomAddress,@"roomID",deviceAddress,@"deviceID",_reqString,@"reqData",@"IB",@"Operation", nil];
        [self deviceStatusUpdateInCloud:dict];
    }
}

- (void)changeSwitch:(id)sender{
    
    NSString* seldeviceTag = [NSString stringWithFormat:@"%ld",(long)[sender tag]];
    NSString *deviceState = @"";
    if([sender isSelected])
    {
        // Execute any code when the switch is ON
        NSLog(@"Switch is ON");
        deviceState = @"A";
        strImageName = @"bulbOn";
        sleepAllBtn = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:strImageName]
                                                       style:UIBarButtonItemStylePlain target:self action:@selector(sleepAll)];
        
        self.navigationItem.rightBarButtonItem = sleepAllBtn;
        
    } else{
        deviceState = @"F";
        // Execute any code when the switch is OFF
        NSLog(@"Switch is OFF");
        strImageName = @"sleepModeOff";
        sleepAllBtn = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:strImageName]
                                                       style:UIBarButtonItemStylePlain target:self action:@selector(sleepAll)];
        
        self.navigationItem.rightBarButtonItem = sleepAllBtn;
    }
    NSDictionary *dict = [[NSDictionary alloc] initWithObjectsAndKeys:deviceState,@"state",seldeviceTag,@"tag", nil];
    
    HUD = [[MBProgressHUD alloc] initWithView:self.view];
    HUD.color = [UIColor clearColor];
    HUD.delegate = self;
    [self.view addSubview:HUD];
    HUD.taskInProgress = YES;
    [HUD show:YES];
    HUD.dimBackground = YES;
    HUD.labelText = @"Device status update Inprogress";
    
    [self performSelector:@selector(deviceStatusUpdate:) withObject:dict afterDelay:0.1];
    
}
-(void)deviceStatusUpdate:(NSDictionary *)dict
{
    NSString *deviceState  = [dict valueForKey:@"state"];
    NSInteger seldeviceTag  = [[dict valueForKey:@"tag"] integerValue];
    NSString *roomAddress = @"";
    NSString *deviceAddress = @"";
    if (44444 == seldeviceTag) {
        roomAddress = [ParseClass requlatorCharacter:_selRoomIndex];
        deviceAddress = @"z";
        deviceState = @"A";
    }else if (99999 == seldeviceTag)
    {
        roomAddress = [ParseClass requlatorCharacter:_selRoomIndex];
        deviceAddress = @"z";
        deviceState = @"F";
    }
    else
    {
        _selDeviceIndex = seldeviceTag;
        roomAddress = [ParseClass requlatorCharacter:_selRoomIndex];
        deviceAddress = [ParseClass requlatorCharacter:_selDeviceIndex];
    }
    int netWorkStatus = [NetworkManager netWorkStatus];
    if(netWorkStatus == 0)
    {
        
        [HUD hide:YES];
        
        [_tblView reloadData];
        
        if (SYSTEM_VERSION_LESS_THAN(@"8.0")) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Network Message" message:@"No Internet Connection" delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
            [alert show];
        }
        else{
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Network Message"
                                                                           message:@"No Internet Connection"
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:@"Cancel"
                                                      style:UIAlertActionStyleCancel
                                                    handler:nil]];
            
            [self presentViewController:alert animated:YES completion:nil];
        }
    }
    else if (netWorkStatus == 1 && [[_userInfoDict valueForKey:@"wifiName"] isEqualToString:[NetworkManager fetchSSIDInfo]])
    {
        TcpClient *tcpConnection = [[TcpClient alloc] init];
        tcpConnection.delegate = self;
        NSString *reqStr = [NSString stringWithFormat:@"B%@%@%@",roomAddress,deviceAddress,deviceState];
        [tcpConnection tcpConnectionForHubData:reqStr hubIP:appDelegate.hubIPGlobal];
        
    }else{
        _isAllRoomsSleepAll = NO;
        _isSelectedRoomSleepAll = NO;
        if ([@"z" isEqualToString:deviceAddress]) {
            _isSelectedRoomSleepAll = YES;
        }
        _reqString = [NSString stringWithFormat:@"B%@%@%@",roomAddress,deviceAddress,deviceState];
        
        NSDictionary *dict= [NSDictionary dictionaryWithObjectsAndKeys:roomAddress,@"roomID",deviceAddress,@"deviceID",_reqString,@"reqData",@"IB",@"Operation", nil];
        [self deviceStatusUpdateInCloud:dict];
    }
}

-(void)sleepAll
{
    if (appDelegate.isSleepAll) {
        NSLog(@"sleep all");
    }
    else{
        NSLog(@"no sleep all ");
    }
    HUD = [[MBProgressHUD alloc] initWithView:self.view];
    HUD.color = [UIColor clearColor];
    HUD.delegate = self;
    [self.view addSubview:HUD];
    HUD.taskInProgress = YES;
    [HUD show:YES];
    HUD.dimBackground = YES;
    HUD.labelText = @"Sleep all devices Inprogress";
    [_tblView reloadData];
    int netWorkStatus = [NetworkManager netWorkStatus];
    if(netWorkStatus == 0)
    {
        [HUD hide:YES];
        
          //[_tblView reloadData];
        
        if (SYSTEM_VERSION_LESS_THAN(@"8.0")) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Network Message" message:@"No Internet Connection" delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
            [alert show];
        }
        else{
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Network Message"
                                                                           message:@"No Internet Connection"
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:@"Cancel"
                                                      style:UIAlertActionStyleCancel
                                                    handler:nil]];
            
            [self presentViewController:alert animated:YES completion:nil];
        }
    }
    else if (netWorkStatus == 1 && [[_userInfoDict valueForKey:@"wifiName"] isEqualToString:[NetworkManager fetchSSIDInfo]])
    {
        strImageName = nil;

        if (appDelegate.isSleepAll)
        {
            //_isAllRoomsSleepAll = NO;
            strImageName = @"sleepModeOff";
            sleepAllBtn = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:strImageName]
                                                           style:UIBarButtonItemStylePlain target:self action:@selector(sleepAll)];
            
            self.navigationItem.rightBarButtonItem = sleepAllBtn;
            
            NSString *reqStr = @"BzzF";
            TcpClient *tcpConnection = [[TcpClient alloc] init];
            tcpConnection.delegate = self;
            [tcpConnection tcpConnectionForHubData:reqStr hubIP:appDelegate.hubIPGlobal];
        }
        
        else
        {
            strImageName = @"bulbOn";
            sleepAllBtn = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:strImageName]
                                                           style:UIBarButtonItemStylePlain target:self action:@selector(sleepAll)];
            
            self.navigationItem.rightBarButtonItem = sleepAllBtn;
            _isAllRoomsSleepAll = YES;
            NSString *reqStr = @"BzzA";
            TcpClient *tcpConnection = [[TcpClient alloc] init];
            tcpConnection.delegate = self;
            [tcpConnection tcpConnectionForHubData:reqStr hubIP:appDelegate.hubIPGlobal];
        }
        
        
    }else{
        strImageName = nil;
        if (appDelegate.isSleepAll) {
            strImageName = @"sleepModeOff";
            sleepAllBtn = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:strImageName]
                                                           style:UIBarButtonItemStylePlain target:self action:@selector(sleepAll)];
            
            self.navigationItem.rightBarButtonItem = sleepAllBtn;
            
            //4_isAllRoomsSleepAll = NO;
            _reqString = @"BzzF";
            NSDictionary *dict= [NSDictionary dictionaryWithObjectsAndKeys:@"z",@"roomID",@"z",@"deviceID",_reqString,@"reqData",@"B",@"Operation", nil];
            [self deviceStatusUpdateInCloud:dict];
        }
        else
        {
            strImageName = @"bulbOn";
            sleepAllBtn = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:strImageName]
                                                           style:UIBarButtonItemStylePlain target:self action:@selector(sleepAll)];
            
            self.navigationItem.rightBarButtonItem = sleepAllBtn;
            _isAllRoomsSleepAll = YES;
            _reqString = @"BzzA";
            NSDictionary *dict= [NSDictionary dictionaryWithObjectsAndKeys:@"z",@"roomID",@"z",@"deviceID",_reqString,@"reqData",@"B",@"Operation", nil];
            [self deviceStatusUpdateInCloud:dict];
        }
    }
}
-(void)getDeviceConfigData
{
    int networkStatus = [NetworkManager netWorkStatus];
    NSLog(@"%@ lol %@", [_userInfoDict valueForKey:@"wifiName"], [NetworkManager fetchSSIDInfo]);
    if(networkStatus == 0)
    {
        NSLog(@"zero");
        if (refreshControl) {
            [refreshControl endRefreshing];
        }
        
        if (HUD) {
            [HUD hide:YES];
        }
        
        
        if (SYSTEM_VERSION_LESS_THAN(@"8.0")) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Network Message" message:@"No Internet Connection" delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
            [alert show];
        }
        else{
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Network Message"
                                                                           message:@"No Internet Connection"
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:@"Cancel"
                                                      style:UIAlertActionStyleCancel
                                                    handler:nil]];
            [self presentViewController:alert animated:YES completion:nil];
        }
    }
    else if (networkStatus == 1 && [[_userInfoDict valueForKey:@"wifiName"] isEqualToString:[NetworkManager fetchSSIDInfo]]) {
        NSLog(@"net stat");
        if ([appDelegate.hubIPGlobal isEqualToString:@"78.160.1.5"] || [@"Fail" isEqualToString:appDelegate.hubIPGlobal]) {
            HUD.labelText = @"Connecting to hub";
            [self getHubIP];
            HUD.labelText = @"Fetching Data Inprogress";
        }
        if(![@"78.160.1.5" isEqualToString:appDelegate.hubIPGlobal] && ![@"Fail" isEqualToString:appDelegate.hubIPGlobal])
        {
            
            NSLog(@"I am here");
            TcpClient *tcpConnection = [[TcpClient alloc] init];
            tcpConnection.delegate = self;
            [TCPGlobal sharedInstance].isRetreivingDataIA = YES;
            NSString *cmd = [NSString stringWithFormat:@"IA"];

            [TCPGlobal sharedInstance].isFetchingDataIA = NO;
            [tcpConnection tcpConnectionForHubData:cmd hubIP:appDelegate.hubIPGlobal];
        }
        else{
            [HUD hide:YES];
            if (SYSTEM_VERSION_LESS_THAN(@"8.0")) {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Network Message" message:@"Hub not detected" delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
                [alert show];
            }
            else{
                UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Network Message"
                                                                               message:@"Hub not detected"
                                                                        preferredStyle:UIAlertControllerStyleAlert];
                [alert addAction:[UIAlertAction actionWithTitle:@"Cancel"
                                                          style:UIAlertActionStyleCancel
                                                        handler:nil]];
                
                [self presentViewController:alert animated:YES completion:nil];
            }
        }
        
    }else{

        [self fetchDeviceDetailsInWAN];
    }
}

-(void)runTCPAgain:(NSNotification *)notification
{
    TcpClient *tcpConnection = [[TcpClient alloc] init];
    tcpConnection.delegate = self;
    [TCPGlobal sharedInstance].isRetreivingDataIA = NO;
    NSString *cmd = [NSString stringWithFormat:@"IB"];
    
    [tcpConnection tcpConnectionForHubData:cmd hubIP:appDelegate.hubIPGlobal];
}
//HUb Response delegate method
-(void)hubResponseString:(NSString *)str
{
    
    NSLog(@"str....%@",str);
    if (refreshControl && [refreshControl isRefreshing]) {
        [self reloadData];
    }
    if (HUD) {
        [HUD hide:YES];
    }
    if([@"disconnect" isEqualToString:str])
    {
        return;
    }
    if (!str || [@"write data time out" isEqualToString:str] || [@"read data time out" isEqualToString:str]) {
        
        if (SYSTEM_VERSION_LESS_THAN(@"8.0")) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Connection Time Out" message:@"Please refresh your data" delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
            [alert show];
        }
        else{
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Connection Time Out"
                                                                           message:@"Please refresh your data"
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:@"Cancel"
                                                      style:UIAlertActionStyleCancel
                                                    handler:nil]];
            
            [self presentViewController:alert animated:YES completion:nil];
        }
        return;
    }
    if (str && str.length <=5) {
        NSString *lastSuccessStr = [appDelegate lastSuccessReponseStr];
        if (lastSuccessStr) {
            [self cloudDataParse:lastSuccessStr];
        }
        return;
    }
    if (str && [str rangeOfString:@"FAIL"].location != NSNotFound) {
        
        if (SYSTEM_VERSION_LESS_THAN(@"8.0")) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Network Message" message:@"Command error" delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
            [alert show];
        }
        else{
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Network Message"
                                                                           message:@"Command error"
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:@"Cancel"
                                                      style:UIAlertActionStyleCancel
                                                    handler:nil]];
            
            [self presentViewController:alert animated:YES completion:nil];
        }
        return;
    }
    if (str && ![@"error" isEqualToString:str] && ![@"disconnect" isEqualToString:str]){
        
        [self cloudDataParse:str];
    }
    else{
        [_tblView reloadData];
        
        if (SYSTEM_VERSION_LESS_THAN(@"8.0")) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Network Message" message:@"Command error" delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
            [alert show];
        }
        else{
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Network Message"
                                                                           message:@"Command error"
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:@"Cancel"
                                                      style:UIAlertActionStyleCancel
                                                    handler:nil]];
            
            [self presentViewController:alert animated:YES completion:nil];
        }
        NSString *lastSuccessStr = [appDelegate lastSuccessReponseStr];
        if (lastSuccessStr) {
            [self cloudDataParse:lastSuccessStr];
        }
    }
}

-(void)deviceStatusUpdateInCloud:(NSDictionary *)dict
{
    NSLog(@"dict dict dict .....%@",dict);
    NSString *strLatLong = [NSString stringWithFormat:@"%@-%@",appDelegate.strLatitude,appDelegate.strLangitude];
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    [dateFormat setDateFormat:@"YYYY-MM-dd HH:mm:ss"];
    NSDate *currentDate = [NSDate date];
    NSString *curDtaeStr = [dateFormat stringFromDate:currentDate];
    
    NSArray *keys = [NSArray arrayWithObjects:@"ip", @"gps",@"roomID",@"deviceID",@"operation",@"authCode",@"authToken",@"data",@"key",@"phoneTime", nil];
    NSArray *objects = [NSArray arrayWithObjects:[NetworkManager getIPAddress],strLatLong,[dict valueForKey:@"roomID"],[dict valueForKey:@"deviceID"],@"B",[_userInfoDict valueForKey:@"authCode"],[_userInfoDict valueForKey:@"authToken"],[dict valueForKey:@"reqData"],@"test",curDtaeStr,nil];

    NSData *__jsonData = nil;
    NSString *__jsonString = nil;
    
    NSURL *url = [NSURL URLWithString:@"https://qws.qasa.io/service/issueCommand"];
    
    
    NSDictionary *jsonDictionary = [NSDictionary dictionaryWithObjects:objects forKeys:keys];
    
    
    if([NSJSONSerialization isValidJSONObject:jsonDictionary])
    {
        __jsonData = [NSJSONSerialization dataWithJSONObject:jsonDictionary options:0 error:nil];
        __jsonString = [[NSString alloc]initWithData:__jsonData encoding:NSUTF8StringEncoding];
    }
    
    NSString *postString = [NSString stringWithFormat:@"command=%@",__jsonString];
    postString = [postString urlEncodeUsingEncoding:NSUTF8StringEncoding];
    WebRequest *webReq = [[WebRequest alloc] init];
    webReq.delegate = self;
    NSMutableURLRequest *request = nil;
    if (url) {
        request = [NSMutableURLRequest requestWithURL:url];
        NSString *contentType = [NSString stringWithFormat:@"application/x-www-form-urlencoded"];
        [request addValue:contentType forHTTPHeaderField:@"Content-Type"];
        [request setHTTPMethod:@"POST"];
        [request setHTTPBody:[postString dataUsingEncoding:NSUTF8StringEncoding]];
        if (request) {
            [webReq startLoading:request];
        }
    }
}
-(void)updateDeviceConfigInServer:(NSString *)hubResponse
{
    NSData *__jsonData = nil;
    NSString *__jsonString = nil;
    NSArray *keys = [NSArray arrayWithObjects:@"authCode", @"authToken",@"data", nil];
    NSArray *objects = [NSArray arrayWithObjects:[_userInfoDict valueForKey:@"authCode"],[_userInfoDict valueForKey:@"authToken"],hubResponse,nil];
    NSURL *url = [NSURL URLWithString:@"https://qws.qasa.io/service/updateDeviceConfig"];
    
    NSDictionary *jsonDictionary = [NSDictionary dictionaryWithObjects:objects forKeys:keys];
    
    if([NSJSONSerialization isValidJSONObject:jsonDictionary])
    {
        __jsonData = [NSJSONSerialization dataWithJSONObject:jsonDictionary options:0 error:nil];
        __jsonString = [[NSString alloc]initWithData:__jsonData encoding:NSUTF8StringEncoding];
    }
    
    NSString *postString = [NSString stringWithFormat:@"deviceConfig=%@",__jsonString];
    postString = [postString urlEncodeUsingEncoding:NSUTF8StringEncoding];
    
    WebRequest *webReq = [[WebRequest alloc] init];
    webReq.delegate = self;
    NSMutableURLRequest *request = nil;
    if (url) {
        request = [NSMutableURLRequest requestWithURL:url];
        NSString *contentType = [NSString stringWithFormat:@"application/x-www-form-urlencoded"];
        [request addValue:contentType forHTTPHeaderField:@"Content-Type"];
        [request setHTTPMethod:@"POST"];
        [request setHTTPBody:[postString dataUsingEncoding:NSUTF8StringEncoding]];
        if (request) {
            [webReq startLoading:request];
        }
    }
}
-(void)fetchDeviceConfigInWA
{
    NSLog(@"WAN");
    [TCPGlobal sharedInstance].isFetchingDataIA = YES;
    
    NSArray *keys = [NSArray arrayWithObjects:@"authCode", @"authToken", nil];
    NSLog(@"_userInfoDict : %@", _userInfoDict);
    NSArray *objects = [NSArray arrayWithObjects:[_userInfoDict valueForKey:@"authCode"],[_userInfoDict valueForKey:@"authToken"],nil];
    NSData *__jsonData = nil;
    NSString *__jsonString = nil;
    
    NSURL *url = [NSURL URLWithString:@"https://qws.qasa.io/service/fetchDeviceConfig"];
    // NSLog(@"Url %@", url);
    NSDictionary *jsonDictionary = [NSDictionary dictionaryWithObjects:objects forKeys:keys];
    
    if([NSJSONSerialization isValidJSONObject:jsonDictionary])
    {
        __jsonData = [NSJSONSerialization dataWithJSONObject:jsonDictionary options:0 error:nil];
        __jsonString = [[NSString alloc]initWithData:__jsonData encoding:NSUTF8StringEncoding];
    }
    
    NSString *postString = [NSString stringWithFormat:@"deviceConfig=%@",__jsonString];
    NSLog(@"postString : %@", postString);
    WebRequest *webReq = [[WebRequest alloc] init];
    webReq.delegate = self;
    NSMutableURLRequest *request = nil;
    if (url) {
        
        request = [NSMutableURLRequest requestWithURL:url];
        NSString *contentType = [NSString stringWithFormat:@"application/x-www-form-urlencoded"];
        [request addValue:contentType forHTTPHeaderField:@"Content-Type"];
        [request setHTTPMethod:@"POST"];
        [request setHTTPBody:[postString dataUsingEncoding:NSUTF8StringEncoding]];
        if (request) {
            [webReq startLoading:request];
        }else
        {
            [HUD hide:YES];
        }
    }else
    {
        [HUD hide:YES];
    }
}

-(void)cloudDataParse:(NSString *)str 
{
    
    NSLog(@"cloud str : %@", str);
    if (str)
    {
        [ParseClass parseString:str];
                // Update the UI
        
            if (appDelegate.roomsArray && appDelegate.roomsArray.count)
            {
//                NSLog(@"appDelegate.roomsArray.count...%lu",(unsigned long)appDelegate.roomsArray.count);
               
                _selectedRoomData = appDelegate.roomsArray[_selRoomIndex];
                NSString *roomName = appDelegate.roomNamesArray[_selRoomIndex];
               
                NSLog(@"room NNNN : %@", roomName);
                self.title = NSLocalizedString(roomName, nil);
                _arrDevices = [_selectedRoomData.devicesArray mutableCopy];
                for (int i = 0; i<_selectedRoomData.devicesArray.count; i++)
                {
                    DeviceData *devData = [_selectedRoomData.devicesArray objectAtIndex:i];
                    if (devData && !devData.deviceName.length)
                    {
                        [_arrDevices removeObject:devData];
                        //[_arrDevices addObject:devData];
                    }
                }
                [_titleLabelButton setTitle:roomName forState:UIControlStateNormal];
                
                strImageName = nil;
                if (appDelegate.isSleepAll)
                {
                    strImageName = @"sleepModeOff";
                }
                else
                {
                    strImageName = @"bulbOn";
                }
                [self.navigationController.navigationItem.leftBarButtonItem setImage:[UIImage imageNamed:strImageName]];
                [_tblView reloadData];
            }

        }
} 
//Delegate method
- (void)webRequest:(WebRequest *)webRequest webRequestReceivedData:(NSData *)data {
    
    [self reloadData];
    [HUD hide:YES];
    if (!data) {
        NSString *lastSuccessStr = [appDelegate lastSuccessReponseStr];
        if (lastSuccessStr) {
            [self cloudDataParse:lastSuccessStr];
        }
        if (SYSTEM_VERSION_LESS_THAN(@"8.0")) {
            
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Request failed" delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
            [alertView show];
        }
        else{
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Error"
                                                                           message:@"Request failed"
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:@"Cancel"
                                                      style:UIAlertActionStyleCancel
                                                    handler:nil]];
            
            [self presentViewController:alert animated:YES completion:nil];
        }
        return;
    }
    NSDictionary *responseDict = [NSJSONSerialization JSONObjectWithData:data
                                                                 options:kNilOptions
                                                                   error:nil];
    NSLog(@"response DICT : %@", responseDict);
    if (responseDict && [@"SUCCESS" isEqualToString:[responseDict valueForKey:@"status"]] && responseDict.count > 2 && ![[responseDict valueForKey:@"message"] isEqualToString:@"Command accepted"])
    {
        
        NSString *rry =  [responseDict valueForKey:@"deviceInfo"];
        NSString *responseStr123 = [rry stringByReplacingOccurrencesOfString:@"$" withString:@""];
        NSArray *roomsStrArray123 = [responseStr123 componentsSeparatedByString:@"!"];
        NSLog(@"rry....%@",roomsStrArray123);

        [TCPGlobal sharedInstance].arrayIA = roomsStrArray123;
        [[NSUserDefaults standardUserDefaults] setObject:roomsStrArray123 forKey:@"stringIA123"];
        
        [self cloudDataParse:[responseDict valueForKey:@"deviceConfig"]];
        
    }
    else if(responseDict && [@"SUCCESS" isEqualToString:[responseDict valueForKey:@"status"]] && [@"Command accepted" isEqualToString:[responseDict valueForKey:@"message"]] && [@"SUCCESS" isEqualToString:[responseDict valueForKey:@"errorCode"]])
    {
        [self updateTheResponseString];
    }
    else
    {
        NSString *lastSuccessStr = [appDelegate lastSuccessReponseStr];
        if (lastSuccessStr) {
            [self cloudDataParse:lastSuccessStr];
        }
    }
}

-(void)updateTheResponseString
{
    NSString *lastSuccesStr = [appDelegate lastSuccessReponseStr];
    if (_isAllRoomsSleepAll) {
        _isAllRoomsSleepAll = NO;
        
        NSMutableArray *roomsStrArray = [NSMutableArray arrayWithArray:[lastSuccesStr componentsSeparatedByString:@"!"]];
        for (int roomsIndex = 1; roomsIndex < roomsStrArray.count; roomsIndex++) {
            NSMutableArray *devicesArray =  [NSMutableArray arrayWithArray:[roomsStrArray[roomsIndex] componentsSeparatedByString:@"*"]];
            for (int deviceIndex = 1; deviceIndex < devicesArray.count; deviceIndex++) {
                NSString *selDeviceStr = [devicesArray objectAtIndex:deviceIndex];
                NSMutableArray *deviceProps = [NSMutableArray arrayWithArray:[selDeviceStr componentsSeparatedByString:@"-"]];
                [deviceProps replaceObjectAtIndex:2 withObject:@"A"];
                NSString *combinedStuff = [deviceProps componentsJoinedByString:@"-"];
                [devicesArray replaceObjectAtIndex:deviceIndex withObject:combinedStuff];
            }
            NSString *roomString = [devicesArray componentsJoinedByString:@"*"];
            [roomsStrArray replaceObjectAtIndex:roomsIndex withObject:roomString];
        }
        
        lastSuccesStr = [roomsStrArray componentsJoinedByString:@"!"];
        
    }
    else if (_isSelectedRoomSleepAll)
    {
        
        NSMutableArray *roomsStrArray = [NSMutableArray arrayWithArray:[lastSuccesStr componentsSeparatedByString:@"!"]];
        NSMutableArray *devicesArray =  [NSMutableArray arrayWithArray:[roomsStrArray[_selRoomIndex + 1] componentsSeparatedByString:@"*"]];
        for (int deviceIndex = 1; deviceIndex < devicesArray.count; deviceIndex++) {
            NSString *selDeviceStr = [devicesArray objectAtIndex:deviceIndex];
            NSMutableArray *deviceProps = [NSMutableArray arrayWithArray:[selDeviceStr componentsSeparatedByString:@"-"]];
            [deviceProps replaceObjectAtIndex:2 withObject:@"A"];
            NSString *combinedStuff = [deviceProps componentsJoinedByString:@"-"];
            [devicesArray replaceObjectAtIndex:deviceIndex withObject:combinedStuff];
        }
        NSString *roomString = [devicesArray componentsJoinedByString:@"*"];
        [roomsStrArray replaceObjectAtIndex:_selRoomIndex + 1 withObject:roomString];
        
        lastSuccesStr = [roomsStrArray componentsJoinedByString:@"!"];
    }else{
        if (_reqString.length <= 0) {
            return;
        }
        NSString *deviceState = [_reqString substringFromIndex:3];
        NSMutableArray *roomsStrArray = [NSMutableArray arrayWithArray:[lastSuccesStr componentsSeparatedByString:@"!"]];
        NSMutableArray *devicesArray =  [NSMutableArray arrayWithArray:[roomsStrArray[_selRoomIndex + 1] componentsSeparatedByString:@"*"]];
        NSString *selDeviceStr = [devicesArray objectAtIndex:_selDeviceIndex+1];
        NSMutableArray *deviceProps = [NSMutableArray arrayWithArray:[selDeviceStr componentsSeparatedByString:@"-"]];
        [deviceProps replaceObjectAtIndex:2 withObject:deviceState];
        NSString *combinedStuff = [deviceProps componentsJoinedByString:@"-"];
        [devicesArray replaceObjectAtIndex:_selDeviceIndex+1 withObject:combinedStuff];
        NSString *roomString = [devicesArray componentsJoinedByString:@"*"];
        [roomsStrArray replaceObjectAtIndex:_selRoomIndex + 1 withObject:roomString];
        lastSuccesStr = [roomsStrArray componentsJoinedByString:@"!"];
    }
    
    
    [self cloudDataParse:lastSuccesStr];
}
- (void)handleSwipeLeft:(UISwipeGestureRecognizer *)gestureRecognizer
{
    if (_selRoomIndex >= appDelegate.roomsArray.count - 1) {
        return;
    }
    _selRoomIndex++;
    if (appDelegate.roomsArray && appDelegate.roomsArray.count) {
        _selectedRoomData = appDelegate.roomsArray[_selRoomIndex];
        NSString *roomName = appDelegate.roomNamesArray[_selRoomIndex];
        [_titleLabelButton setTitle:roomName forState:UIControlStateNormal];        _arrDevices = [_selectedRoomData.devicesArray mutableCopy];
        for (int i = 0; i<_selectedRoomData.devicesArray.count; i++) {
            DeviceData *devData = [_selectedRoomData.devicesArray objectAtIndex:i];
            if (devData && !devData.deviceName.length) {
                [_arrDevices removeObject:devData];
            }
        }
        
        [_tblView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationLeft];
    }
    
    
}

- (void)handleSwipeRight:(UISwipeGestureRecognizer *)gestureRecognizer
{
    if (_selRoomIndex <= 0) {
        return;
    }
    _selRoomIndex--;
    if (appDelegate.roomsArray && appDelegate.roomsArray.count) {
        _selectedRoomData = appDelegate.roomsArray[_selRoomIndex];
        NSString *roomName = appDelegate.roomNamesArray[_selRoomIndex];
        [_titleLabelButton setTitle:roomName forState:UIControlStateNormal];
        _arrDevices = [_selectedRoomData.devicesArray mutableCopy];
        for (int i = 0; i<_selectedRoomData.devicesArray.count; i++) {
            DeviceData *devData = [_selectedRoomData.devicesArray objectAtIndex:i];
            if (devData && !devData.deviceName.length) {
                [_arrDevices removeObject:devData];
            }
        }
        [_tblView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationRight];
    }
}

#pragma mark - MBProgressHUDDelegate
- (void)hudWasHidden:(MBProgressHUD *)hud {
    // Remove HUD from screen when the HUD was hidded
    if(HUD)
    {
        [HUD removeFromSuperview];
        HUD = nil;
    }
    
}

- (void)changeDate:(UIDatePicker *)sender {
    NSLog(@"New Date: %@", sender.date);
}

- (void)removeViews:(id)object {
    [[self.view viewWithTag:9] removeFromSuperview];
    [[self.view viewWithTag:10] removeFromSuperview];
    [[self.view viewWithTag:11] removeFromSuperview];
}

- (void)dismissDatePicker:(id)sender {
    CGRect toolbarTargetFrame = CGRectMake(0, self.view.bounds.size.height, 320, 44);
    CGRect datePickerTargetFrame = CGRectMake(0, self.view.bounds.size.height+44, 320, 216);
    [UIView beginAnimations:@"MoveOut" context:nil];
    [self.view viewWithTag:9].alpha = 0;
    [self.view viewWithTag:10].frame = datePickerTargetFrame;
    [self.view viewWithTag:11].frame = toolbarTargetFrame;
    [UIView setAnimationDelegate:self];
    [UIView setAnimationDidStopSelector:@selector(removeViews:)];
    [UIView commitAnimations];
}

- (void)setTheScheduler:(id)sender {
    if ([sender tag] == 44444) {
        return;
    }
    _selDeviceIndex = [sender tag];
    RoomData *selectedRoomData = appDelegate.roomsArray[_selRoomIndex];
    DeviceData *devData = [selectedRoomData.devicesArray objectAtIndex:_selDeviceIndex];
    SchedulerViewController *scheduleVC = [[SchedulerViewController alloc] init];
    scheduleVC.myDelegate = self;
    scheduleVC.roomNameStr = appDelegate.roomNamesArray[_selRoomIndex];
    scheduleVC.deviceNameStr = devData.deviceName;
    [self.navigationController pushViewController:scheduleVC animated:YES];
}
-(void) setTimerMessageString:(NSDictionary *)schedulerDict
{
 //   CCBB1080,B360
    NSString *scheduleTime = @"";
    if ([@"B" isEqualToString:[schedulerDict valueForKey:@"isOntime"]]) {
        scheduleTime = [NSString stringWithFormat:@"B%@,",[schedulerDict valueForKey:@"onTime"]];
    }else{
        scheduleTime = @"A00,";
    }
    if ([@"B" isEqualToString:[schedulerDict valueForKey:@"isOffTime"]]) {
        scheduleTime = [scheduleTime stringByAppendingString:[NSString stringWithFormat:@"B%@,",[schedulerDict valueForKey:@"offTime"]]] ;
    }else{
        scheduleTime = [scheduleTime stringByAppendingString:@"A00,"] ;
    }
    NSString *reqStr = [NSString stringWithFormat:@"C%@%@%@",[ParseClass requlatorCharacter:_selRoomIndex],[ParseClass requlatorCharacter:_selDeviceIndex],scheduleTime];
    
    [self schedulerCommand:reqStr];
}
-(void)schedulerCommand:(NSString *)reqStr
{
 //   _reqString = reqStr;
    HUD = [[MBProgressHUD alloc] initWithView:self.view];
    HUD.color = [UIColor clearColor];
    HUD.delegate = self;
    [self.view addSubview:HUD];
    HUD.taskInProgress = YES;
    [HUD show:YES];
    HUD.dimBackground = YES;
    HUD.labelText = @"Scheduler Inprogress";
    int netWorkStatus = [NetworkManager netWorkStatus];
    if(netWorkStatus == 0)
    {
        
        [HUD hide:YES];
        
        [_tblView reloadData];
        
        if (SYSTEM_VERSION_LESS_THAN(@"8.0")) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Network Message" message:@"No Internet Connection" delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
            [alert show];
        }
        else{
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Network Message"
                                                                           message:@"No Internet Connection"
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:@"Cancel"
                                                      style:UIAlertActionStyleCancel
                                                    handler:nil]];
            
            [self presentViewController:alert animated:YES completion:nil];
        }
    }
    else if (netWorkStatus == 1 && [[_userInfoDict valueForKey:@"wifiName"] isEqualToString:[NetworkManager fetchSSIDInfo]])
    {
        TcpClient *tcpConnection = [[TcpClient alloc] init];
        tcpConnection.delegate = self;
        [tcpConnection tcpConnectionForHubData:reqStr hubIP:appDelegate.hubIPGlobal];
        
    }else{
        NSDictionary *dict= [NSDictionary dictionaryWithObjectsAndKeys:[ParseClass requlatorCharacter:_selRoomIndex],@"roomID",[ParseClass requlatorCharacter:_selDeviceIndex],@"deviceID",reqStr,@"reqData",@"C",@"Operation", nil];
        [self deviceStatusUpdateInCloud:dict];
    }
}


-(void)fetchDeviceDetailsInWAN
{
    NSLog(@"WAN");
    
    [TCPGlobal sharedInstance].isFetchingDataIA = YES;
    NSLog(@"_userInfoDict : %@", _userInfoDict);

    
    NSURL *url = [NSURL URLWithString:@"https://qws.qasa.io/service/fetch-device-config-1"];
    
    NSString *postString = [NSString stringWithFormat:@"authCode=%@&authToken=%@",[_userInfoDict valueForKey:@"authCode"],[_userInfoDict valueForKey:@"authToken"]];
    NSLog(@"postString : %@", postString);
    WebRequest *webReq = [[WebRequest alloc] init];
    webReq.delegate = self;
    NSMutableURLRequest *request = nil;
    if (url) {
        
        request = [NSMutableURLRequest requestWithURL:url];
        NSString *contentType = [NSString stringWithFormat:@"application/x-www-form-urlencoded"];
        [request addValue:contentType forHTTPHeaderField:@"Content-Type"];
        [request setHTTPMethod:@"POST"];
        [request setHTTPBody:[postString dataUsingEncoding:NSUTF8StringEncoding]];
        if (request) {
            [webReq startLoading:request];
        }else
        {
            [HUD hide:YES];
        }
    }else
    {
        [HUD hide:YES];
    }
}

-(void)updateDeviceConfigInServerInWAN:(NSString *)hubResponse
{
    NSLog(@"hubResponse.....%@",hubResponse);
   
    AppDelegate *delegate = [[UIApplication sharedApplication] delegate];

    NSData *__jsonData = nil;
    NSString *__jsonString = nil;
    NSArray *keys = [NSArray arrayWithObjects:@"authCode",@"authToken",@"deviceInfo", nil];
    
    NSLog(@"_userInfoDict : %@",[delegate isUserRegistered]);
    

    NSArray *objects = [NSArray arrayWithObjects:[[delegate isUserRegistered] valueForKey:@"authCode"],[[delegate isUserRegistered] valueForKey:@"authToken"],hubResponse,nil];
    NSURL *url = [NSURL URLWithString:@"https://qws.qasa.io/service/update-device-info"];
    
    NSDictionary *jsonDictionary = [NSDictionary dictionaryWithObjects:objects forKeys:keys];
    
    if([NSJSONSerialization isValidJSONObject:jsonDictionary])
    {
        __jsonData = [NSJSONSerialization dataWithJSONObject:jsonDictionary options:0 error:nil];
        __jsonString = [[NSString alloc]initWithData:__jsonData encoding:NSUTF8StringEncoding];
    }
    
    NSString *postString = [NSString stringWithFormat:@"%@",__jsonString];
    NSLog(@"post STr : %@", postString);
    
    
    WebRequest *webReq = [[WebRequest alloc] init];
    webReq.delegate = self;
    NSMutableURLRequest *request = nil;
    if (url) {
        request = [NSMutableURLRequest requestWithURL:url];
       // NSString *contentType = [NSString stringWithFormat:@"application/x-www-form-urlencoded"];
        //[request addValue:contentType forHTTPHeaderField:@"Content-Type"];
        [request setHTTPMethod:@"POST"];
        [request setHTTPBody:[postString dataUsingEncoding:NSUTF8StringEncoding]];
        if (request) {
            [webReq startLoading:request];
        }
    }
}


//This packet is send by mobile app to notify the hub of the firmware upgrade available.The packet format is UAFIRMWARE_SIZE$
-(void)upgradeRequest
{
    NSInteger FIRMWARE_SIZE;

    TcpClient *tcpConnection = [[TcpClient alloc] init];
    tcpConnection.delegate = self;
    
    NSString *cmd = [NSString stringWithFormat:@"UA%lu$",(unsigned long)FIRMWARE_SIZE];
    
    
    [TCPGlobal sharedInstance].isFetchingDataIA = NO;
    [tcpConnection tcpConnectionForHubData:cmd hubIP:appDelegate.hubIPGlobal];
    NSLog(@"requested command is...%@",cmd);
    
}
//This packet sent by mobile app will contain the firmware data. The firmware data should be sent in blocks of 1024 bytes(max). The packet format is UC<P_NO><P_SIZE><DATA>$
-(void)upgradeData
{
    NSInteger P_NO ;
    long long P_SIZE;
    long long DATA;
    TcpClient *tcpConnection = [[TcpClient alloc] init];
    tcpConnection.delegate = self;
    
    NSString *cmd = [NSString stringWithFormat:@"UC%lu%lld%lld$",(unsigned long)P_NO,P_SIZE,DATA];
    
    
    [TCPGlobal sharedInstance].isFetchingDataIA = NO;
    [tcpConnection tcpConnectionForHubData:cmd hubIP:appDelegate.hubIPGlobal];
    NSLog(@"upgrated data command is...%@",cmd);
}

//This packet is sent from the mobile app to hub after the upgrade data is completed. The packet format is UD$
-(void)upgradeComplete
{
    TcpClient *tcpConnection = [[TcpClient alloc] init];
    tcpConnection.delegate = self;
    
    NSString *cmd = [NSString stringWithFormat:@"UD$"];
    
    
    [TCPGlobal sharedInstance].isFetchingDataIA = NO;
    [tcpConnection tcpConnectionForHubData:cmd hubIP:appDelegate.hubIPGlobal];
    NSLog(@"upgrade complete command is...%@",cmd);
}
//This packet is sent by the hub as response to all the requests from mobile app. The packet format is a json string based on the result. If an error is occurred during upgrade, the mobile app should re-initiate the upgrade process from the beginning.
-(void)upgradeResponse
{
    
}
@end
