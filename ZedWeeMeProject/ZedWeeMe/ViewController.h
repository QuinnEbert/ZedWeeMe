//
//  ViewController.h
//  RoboMeBasicSample
//
//  Copyright (c) 2013 WowWee Group Limited. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <RoboMe/RoboMe.h>
#import <Slt/Slt.h>

@class FliteController;

@interface ViewController : UIViewController <RoboMeDelegate> {
    Slt *slt;
    FliteController *fliteController;
    int batterySpeechCt;
}

@property (weak, nonatomic) IBOutlet UITextView *outputTextView;

@property (weak, nonatomic) IBOutlet UILabel *edgeLabel;
@property (weak, nonatomic) IBOutlet UILabel *chest20cmLabel;
@property (weak, nonatomic) IBOutlet UILabel *chest50cmLabel;
@property (weak, nonatomic) IBOutlet UILabel *cheat100cmLabel;

@property (nonatomic) int batterySpeechCt;

@property (nonatomic, strong) Slt *slt;
@property (nonatomic, strong) FliteController *fliteController;

@end
