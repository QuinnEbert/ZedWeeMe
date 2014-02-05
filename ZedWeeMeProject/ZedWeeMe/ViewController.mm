//
//  ViewController.m
//  RoboMeBasicSample
//
//  Copyright (c) 2013 WowWee Group Limited. All rights reserved.
//

#import "ViewController.h"

//#import <OpenEars/FliteController.h>
#import <CoreLocation/CoreLocation.h>

@interface ViewController ()

@property (nonatomic, strong) RoboMe *roboMe;

@end

@implementation ViewController 

//@synthesize slt;
//@synthesize fliteController;
@synthesize batterySpeechCt;
@synthesize cm020;
@synthesize cm050;
@synthesize cm100;

@synthesize turning;
@synthesize turnDir;

@synthesize turnback_cur;

@synthesize logging;

@synthesize locationMgr;
@synthesize compass;
@synthesize orienting;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self logHollyAnn:@"********************** SYSTEM RESET **********************"];
    
    cm020 = NO;
    cm050 = NO;
    cm100 = NO;
    
    turning = NO;
    turnDir = 0;
    
    logging = NO;
    
    compass = 0.0;
    orienting = NO;
    
    // create RoboMe object
    self.roboMe = [[RoboMe alloc] initWithDelegate: self];
    
    [self.roboMe setDebugEnabled:NO];
    
    // start listening for events from RoboMe
    [self.roboMe startListening];
    
    // set the speech squelch:
    self.batterySpeechCt = 0;
}

- (IBAction)test_run:(id)sender {
    [self.roboMe sendCommand:kRobot_HeadTiltAllDown];
    self.orienting = YES;
    aTimer = [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(timerFired:) userInfo:nil repeats:YES];
}

-(bool)randomChance
{
    int val = arc4random_uniform(2);
    //NSLog(@"Got random value: %i",val);
    if (val>0)
        return YES;
    return NO;
}

-(void)startDelay:(NSTimer *) theTimer
{
    [self.roboMe sendCommand:kRobot_HeadTiltAllUp];
    [self.roboMe sendCommand:kRobot_GetBatteryLevel];
}

-(void)timerFired:(NSTimer *) theTimer
{
    if (!logging) {
        if (self.orienting) {
            if (self.compass>=COMPASS_ORIENT_HI||self.compass<=COMPASS_ORIENT_LO) {
                [self.roboMe sendCommand:kRobot_Stop];
                self.orienting = NO;
                [self logHollyAnn:@"0deg compass orientation completed!!!"];
            } else {
                [self.roboMe sendCommand:kRobot_TurnRightSlowest];
                [self logHollyAnn:[NSString stringWithFormat:@"0deg orientation: compass reads %fdg bearing, twitch right", self.compass]];
            }
        } else {
            if (turning && turnback_cur <= TURNBACK_MAX/2) {
                [self.roboMe sendCommand:kRobot_MoveBackward];
                turnback_cur--;
                if (turnback_cur < 0) {
                    [self logHollyAnn:@"Just finished turning back!"];
                    turnback_cur = 0;
                    turning = NO;
                } else {
                    [self logHollyAnn:@"In the midst of turning back!"];
                }
            } else {
                if (!self.cm050) {
                    turning = NO;
                    turnDir = 0;
                    //NSLog(@"Empty at 0.5metre");
                    [self logHollyAnn:@"Nothing 0.5 metres away, move forward!"];
                    [self.roboMe sendCommand:kRobot_MoveForward];
                } else {
                    //NSLog(@"Stuff at 0.5metre");
                    [self logHollyAnn:@"Detected object 0.5 metres away..."];
                    if (!turning) {
                        turnback_cur = TURNBACK_MAX;
                        turning = YES;
                        bool r = [self randomChance];
                        if (!r) {
                            [self logHollyAnn:@" >> Wasn't turning back, will begin turning left!"];
                            [self.roboMe sendCommand:kRobot_TurnLeft];
                            turnDir = 0;
                        } else {
                            [self logHollyAnn:@" >> Wasn't turning back, will begin turning left!"];
                            [self.roboMe sendCommand:kRobot_TurnRight];
                            turnDir = 1;
                        }
                    } else {
                        [self logHollyAnn:@" >> Was turning back, resuming with previous direction!"];
                        if (turnDir==0) {
                            [self.roboMe sendCommand:kRobot_TurnLeft];
                        } else {
                            [self.roboMe sendCommand:kRobot_TurnRight];
                        }
                        turnback_cur--;
                    }
                }
            }
        }
    }
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    NSLog(@"Location manager: Oh $#@%%!");
}
- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    //NSLog(@"Got updated device location!");
    
    //TODO: experimentations?!?
}
- (void)locationManager:(CLLocationManager *)manager didUpdateHeading:(CLHeading *)newHeading
{
    double heading = [newHeading trueHeading];
    NSLog(@"Updated device heading: %fdg",heading);
    self.compass = heading;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    /*self.slt = [[Slt alloc] init];
    self.fliteController = [[FliteController alloc] init];
    self.fliteController.duration_stretch = .9; // Change the speed
	self.fliteController.target_mean = 1.2; // Change the pitch
	self.fliteController.target_stddev = 1.5; // Change the variance*/
    
    // battery level of the iOS device
    bool doBatMon = [UIDevice currentDevice].batteryMonitoringEnabled;
    [[UIDevice currentDevice] setBatteryMonitoringEnabled:YES];
    float batteryLevel = [UIDevice currentDevice].batteryLevel;
    [[UIDevice currentDevice] setBatteryMonitoringEnabled:doBatMon];
    NSString *batteryLevelTextInfo = [NSString stringWithFormat:@"iOS device battery level: %i percent",(int)(batteryLevel*100)];
    [self displayText:batteryLevelTextInfo];
    
    self.aPlayer = [[AVAudioPlayer alloc] init];
    [self playAudio:@"ready_robot"];
    bTimer = [NSTimer scheduledTimerWithTimeInterval:5.0 target:self selector:@selector(startDelay:) userInfo:nil repeats:NO];
    
    /*dispatch_async(dispatch_get_main_queue(),^ {*/
        self.locationMgr = [[CLLocationManager alloc] init];
        self.locationMgr.desiredAccuracy = kCLLocationAccuracyBestForNavigation;
        self.locationMgr.delegate = self;
        self.locationMgr.distanceFilter = 0.1f;
        [self.locationMgr startUpdatingLocation];
        [self.locationMgr startUpdatingHeading];
    /*} );*/
}

- (void)playAudio: (NSString*)file {
    self.aPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:[NSURL URLWithString:[[NSBundle mainBundle] pathForResource:file ofType:@"aiff"]] error:nil];
    [self.aPlayer setVolume:0.50];
    [self.aPlayer play];
}

- (NSString *)urlEncode: (NSString *)str {
    CFStringRef safeString = CFURLCreateStringByAddingPercentEscapes (
                                                                      NULL,
                                                                      (CFStringRef)str,
                                                                      NULL,
                                                                      CFSTR("/%&=?$#+-~@<>|\\*,.()[]{}^!"),
                                                                      kCFStringEncodingUTF8
                                                                      );
    NSString *r = (__bridge NSString *)safeString;
    CFRelease(safeString);
    return r;
}

- (void)logHollyAnn: (NSString *)msg {
    self.logging = YES;
    if (DO_WEB_BASED_LOGS) {
        NSString *msgFull = [NSString stringWithFormat:@"%@",[[msg stringByReplacingOccurrencesOfString:@"\n" withString:@""] stringByReplacingOccurrencesOfString:@"\r" withString:@""]];
        NSString *m = [NSString stringWithFormat:@"http://192.168.1.25/~quinn/weeloggy/?msg=%@",[self urlEncode:msgFull]];
        NSURL *u = [[NSURL alloc] initWithString:m];
        NSURLRequest *r = [[NSURLRequest alloc] initWithURL:u];
        [NSURLConnection sendSynchronousRequest:r returningResponse:nil error:nil];
        //NSString *d = [[NSString alloc] initWithData:notUsed encoding:NSUTF8StringEncoding];
        //NSLog(@" ##retData## : %@",d);
    }
    self.logging = NO;
}

// Print out given text to text view
- (void)displayText: (NSString *)text {
    NSString *outputTxt = [NSString stringWithFormat: @"%@\n%@", self.outputTextView.text, text];
    
    // print command to output box
    [self.outputTextView setText: outputTxt];
    
    // scroll to bottom
    [self.outputTextView scrollRangeToVisible:NSMakeRange([self.outputTextView.text length], 0)];
    
    //NSLog(@" ##logHollyAnn## %@",outputTxt);
    [self logHollyAnn:outputTxt];
}

/*** #pragma mark - TTS Helpers ***/

/*- (void) say:(NSString *)message {
    [self.fliteController say:message withVoice:self.slt];
}*/

/*- (void) batterySay:(NSString *)message {
    if (! self.batterySpeechCt) {
        [self say:message];
        self.batterySpeechCt = (int)((300*1000)/(60*1000));
    } else {
        self.batterySpeechCt--;
    }
}*/

#pragma mark - RoboMeConnectionDelegate

// Event commands received from RoboMe
- (void)commandReceived:(IncomingRobotCommand)command {
    // Display incoming robot command in text view
    //[self displayText: [NSString stringWithFormat: @"Received: %@" ,[RoboMeCommandHelper incomingRobotCommandToString: command]]];
    
    // To check the type of command from RoboMe is a sensor status use the RoboMeCommandHelper class
    if([RoboMeCommandHelper isSensorStatus:command]){
        // Read the sensor status
        SensorStatus *sensors = [RoboMeCommandHelper readSensorStatus: command];
        
        // Update labels
        //[self.edgeLabel setText: (sensors.edge ? @"ON" : @"OFF")];
        self.cm020 = sensors.chest_20cm ? YES : NO;
        //[self.chest20cmLabel setText: (sensors.chest_20cm ? @"ON" : @"OFF")];
        self.cm050 = sensors.chest_50cm ? YES : NO;
        //[self.chest50cmLabel setText: (sensors.chest_50cm ? @"ON" : @"OFF")];
        self.cm100 = sensors.chest_100cm ? YES : NO;
        //[self.cheat100cmLabel setText: (sensors.chest_100cm ? @"ON" : @"OFF")];
    } else if ([RoboMeCommandHelper isBatteryStatus:command]) {
        // Read the battery status
        if (command==kRobotIncoming_Battery100) {
            //NSLog(@"Battery level reached 100 percent");
            [self displayText:@"Exoskeleton battery is full (100 percent)"];
            [self playAudio:@"battery_100"];
        } else if (command==kRobotIncoming_Battery80) {
            //NSLog(@"Battery level reached 80 percent");
            [self displayText:@"Exoskeleton batteries are strong (80 percent)"];
            [self playAudio:@"battery_080"];
        } else if (command==kRobotIncoming_Battery60) {
            //NSLog(@"Battery level reached 60 percent");
            [self displayText:@"Exoskeleton batteries are good (60 percent)"];
            [self playAudio:@"battery_060"];
        } else if (command==kRobotIncoming_Battery40) {
            //NSLog(@"Battery level reached 40 percent");
            [self displayText:@"Exoskeleton batteries are fair (40 percent)"];
            [self playAudio:@"battery_040"];
        } else if (command==kRobotIncoming_Battery20) {
            //NSLog(@"Battery level reached 20 percent");
            [self displayText:@"Exoskeleton batteries are weak (20 percent)"];
            [self playAudio:@"tired_robot"];
        } else if (command==kRobotIncoming_Battery10) {
            //NSLog(@"Battery level reached 10 percent");
            [self displayText:@"Exoskeleton batteries are nearly-exhausted (10 percent)"];
            [self displayText:@"WARNING: Exoskeleton may operate too slowly on nearly-exhausted batteries!"];
            [self playAudio:@"tired_robot"];
        }
    }
}

- (void)volumeChanged:(float)volume {
    if([self.roboMe isRoboMeConnected] && volume < 0.75){
        [self displayText: @"Volume needs to be set above 75% to send commands"];
    }
}

- (void)roboMeConnected {
    [self displayText: @"RoboMe Connected!"];
    [self.roboMe sendCommand:kRobot_GetBatteryLevel];
}

- (void)roboMeDisconnected {
    [self displayText: @"RoboMe Disconnected"];
}

@end
