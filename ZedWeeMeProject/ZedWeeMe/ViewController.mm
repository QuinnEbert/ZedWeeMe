//
//  ViewController.m
//  RoboMeBasicSample
//
//  Copyright (c) 2013 WowWee Group Limited. All rights reserved.
//

#import "ViewController.h"

#import <OpenEars/FliteController.h>

@interface ViewController ()

@property (nonatomic, strong) RoboMe *roboMe;

@end

@implementation ViewController 

@synthesize slt;
@synthesize fliteController;
@synthesize batterySpeechCt;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // create RoboMe object
    self.roboMe = [[RoboMe alloc] initWithDelegate: self];
    
    // start listening for events from RoboMe
    [self.roboMe startListening];
    
    // set the speech squelch:
    self.batterySpeechCt = 0;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    self.slt = [[Slt alloc] init];
    self.fliteController = [[FliteController alloc] init];
    self.fliteController.duration_stretch = .9; // Change the speed
	self.fliteController.target_mean = 1.2; // Change the pitch
	self.fliteController.target_stddev = 1.5; // Change the variance
    
}

// Print out given text to text view
- (void)displayText: (NSString *)text {
    NSString *outputTxt = [NSString stringWithFormat: @"%@\n%@", self.outputTextView.text, text];
    
    // print command to output box
    [self.outputTextView setText: outputTxt];
    
    // scroll to bottom
    [self.outputTextView scrollRangeToVisible:NSMakeRange([self.outputTextView.text length], 0)];
}

#pragma mark - TTS Helpers

- (void) say:(NSString *)message {
    [self.fliteController say:message withVoice:self.slt];
}

- (void) batterySay:(NSString *)message {
    if (! self.batterySpeechCt) {
        [self say:message];
        self.batterySpeechCt = (int)((300*1000)/(60*1000));
    } else {
        self.batterySpeechCt--;
    }
}

#pragma mark - RoboMeConnectionDelegate

// Event commands received from RoboMe
- (void)commandReceived:(IncomingRobotCommand)command {
    // Display incoming robot command in text view
    [self displayText: [NSString stringWithFormat: @"Received: %@" ,[RoboMeCommandHelper incomingRobotCommandToString: command]]];
    
    // To check the type of command from RoboMe is a sensor status use the RoboMeCommandHelper class
    if([RoboMeCommandHelper isSensorStatus:command]){
        // Read the sensor status
        SensorStatus *sensors = [RoboMeCommandHelper readSensorStatus: command];
        
        // Update labels
        [self.edgeLabel setText: (sensors.edge ? @"ON" : @"OFF")];
        [self.chest20cmLabel setText: (sensors.chest_20cm ? @"ON" : @"OFF")];
        [self.chest50cmLabel setText: (sensors.chest_50cm ? @"ON" : @"OFF")];
        [self.cheat100cmLabel setText: (sensors.chest_100cm ? @"ON" : @"OFF")];
    } else if ([RoboMeCommandHelper isBatteryStatus:command]) {
        // Read the battery status
        if (command==kRobotIncoming_Battery100) {
            NSLog(@"Battery level reached 100 percent");
        } else if (command==kRobotIncoming_Battery80) {
            NSLog(@"Battery level reached 80 percent");
        } else if (command==kRobotIncoming_Battery60) {
            NSLog(@"Battery level reached 60 percent");
        } else if (command==kRobotIncoming_Battery40) {
            NSLog(@"Battery level reached 40 percent");
        } else if (command==kRobotIncoming_Battery20) {
            NSLog(@"Battery level reached 20 percent");
        } else if (command==kRobotIncoming_Battery10) {
            NSLog(@"Battery level reached 10 percent");
            [self batterySay:@"Batteries are critically weak, please replace my batteries!"];
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
 
#pragma mark - Button callbacks

// The methods below send the desired command to RoboMe.
// Typically you would want to start a timer to repeatly send the
// command while the button is held down. For simplicity this wasn't
// included however if you do decide to implement this we recommand
// sending commands every 500ms for smooth movement.
// See RoboMeCommandHelper.h for a full list of robot commands
- (IBAction)moveForwardBtnPressed:(UIButton *)sender {
    // Adds command to the queue to send to the robot
    [self.roboMe sendCommand: kRobot_MoveForwardFastest];
}

- (IBAction)moveBackwardBtnPressed:(UIButton *)sender {
    [self.roboMe sendCommand: kRobot_MoveBackwardFastest];
}

- (IBAction)turnLeftBtnPressed:(UIButton *)sender {
    [self.roboMe sendCommand: kRobot_TurnLeftFastest];
}

- (IBAction)turnRightBtnPressed:(UIButton *)sender {
    [self.roboMe sendCommand: kRobot_TurnRightFastest];
}

- (IBAction)headUpBtnPressed:(UIButton *)sender {
    [self.roboMe sendCommand: kRobot_HeadTiltAllUp];
}

- (IBAction)headDownBtnPressed:(UIButton *)sender {
    [self.roboMe sendCommand: kRobot_HeadTiltAllDown];
}

@end
