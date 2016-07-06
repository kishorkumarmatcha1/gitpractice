#import <UIKit/UIKit.h>

@interface HomeViewController : UIViewController
@property (nonatomic,weak) IBOutlet UITableView *tblView;
@property (nonatomic,weak) IBOutlet UITableView *tblViewRoomsList;
-(void)updateDeviceConfigInServerInWAN:(NSString *)hubResponse;
-(void)fetchDeviceDetailsInWAN;
-(void)sleepAll;


// Over The Air Concept Related Methods
-(void)upgradeRequest;
-(void)upgradeData;
-(void)upgradeComplete;
-(void)upgradeResponse;

@end

