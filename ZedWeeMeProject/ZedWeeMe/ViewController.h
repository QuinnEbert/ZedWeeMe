//
//  ViewController.h
//  RoboMeBasicSample
//
//  Copyright (c) 2013 WowWee Group Limited. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <RoboMe/RoboMe.h>
//#import <Slt/Slt.h>
#import <CoreLocation/CoreLocation.h>

#define TURNBACK_MAX   2

#define COMPASS_ORIENT_LO   (  0.0+(15.0/2.0))
#define COMPASS_ORIENT_HI   (360.0-(15.0/2.0))

#define DO_WEB_BASED_LOGS   0

/*@class FliteController;*/

@interface ViewController : UIViewController <RoboMeDelegate,CLLocationManagerDelegate> {
    //Slt *slt;
    //FliteController *fliteController;
    int batterySpeechCt;
    bool cm020;
    bool cm050;
    bool cm100;
    bool turning;
    bool logging;
    int turnDir;
    int turnback_cur;
    NSTimer *aTimer;
    NSTimer *bTimer;
    CLLocationManager *locationMgr;

    double compass;
    bool orienting;
}

@property (weak, nonatomic) IBOutlet UITextView *outputTextView;

@property (weak, nonatomic) IBOutlet UILabel *edgeLabel;
@property (weak, nonatomic) IBOutlet UILabel *chest20cmLabel;
@property (weak, nonatomic) IBOutlet UILabel *chest50cmLabel;
@property (weak, nonatomic) IBOutlet UILabel *cheat100cmLabel;

@property (nonatomic, strong) AVAudioPlayer *aPlayer;
@property (nonatomic, retain) CLLocationManager *locationMgr;

@property (nonatomic) int batterySpeechCt;
@property (nonatomic) bool cm020;
@property (nonatomic) bool cm050;
@property (nonatomic) bool cm100;
@property (nonatomic) bool turning;
@property (nonatomic) bool orienting;
@property (nonatomic) bool logging;
@property (nonatomic) int turnDir;
@property (nonatomic) int turnback_cur;

@property (nonatomic) double compass;

//@property (nonatomic, strong) Slt *slt;
//@property (nonatomic, strong) FliteController *fliteController;

@end
