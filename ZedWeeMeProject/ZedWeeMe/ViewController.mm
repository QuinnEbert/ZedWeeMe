//
//  ViewController.m
//  RoboMeBasicSample
//
//  Copyright (c) 2013 WowWee Group Limited. All rights reserved.
//

#import "ViewController.h"

//#import <OpenEars/FliteController.h>
#import <CoreLocation/CoreLocation.h>

#import <ImageIO/CGImageProperties.h>

UIImage *scaleAndRotateImage(UIImage *image)
{
    int kMaxResolution = 2048; // Or whatever
    
    CGImageRef imgRef = image.CGImage;
    
    CGFloat width = CGImageGetWidth(imgRef);
    CGFloat height = CGImageGetHeight(imgRef);
    
    CGAffineTransform transform = CGAffineTransformIdentity;
    CGRect bounds = CGRectMake(0, 0, width, height);
    if (width > kMaxResolution || height > kMaxResolution) {
        CGFloat ratio = width/height;
        if (ratio > 1) {
            bounds.size.width = kMaxResolution;
            bounds.size.height = bounds.size.width / ratio;
        }
        else {
            bounds.size.height = kMaxResolution;
            bounds.size.width = bounds.size.height * ratio;
        }
    }
    
    CGFloat scaleRatio = bounds.size.width / width;
    CGSize imageSize = CGSizeMake(CGImageGetWidth(imgRef), CGImageGetHeight(imgRef));
    CGFloat boundHeight;
    UIImageOrientation orient = image.imageOrientation;
    switch(orient) {
            
        case UIImageOrientationUp: //EXIF = 1
            transform = CGAffineTransformIdentity;
            break;
            
        case UIImageOrientationUpMirrored: //EXIF = 2
            transform = CGAffineTransformMakeTranslation(imageSize.width, 0.0);
            transform = CGAffineTransformScale(transform, -1.0, 1.0);
            break;
            
        case UIImageOrientationDown: //EXIF = 3
            transform = CGAffineTransformMakeTranslation(imageSize.width, imageSize.height);
            transform = CGAffineTransformRotate(transform, M_PI);
            break;
            
        case UIImageOrientationDownMirrored: //EXIF = 4
            transform = CGAffineTransformMakeTranslation(0.0, imageSize.height);
            transform = CGAffineTransformScale(transform, 1.0, -1.0);
            break;
            
        case UIImageOrientationLeftMirrored: //EXIF = 5
            boundHeight = bounds.size.height;
            bounds.size.height = bounds.size.width;
            bounds.size.width = boundHeight;
            transform = CGAffineTransformMakeTranslation(imageSize.height, imageSize.width);
            transform = CGAffineTransformScale(transform, -1.0, 1.0);
            transform = CGAffineTransformRotate(transform, 3.0 * M_PI / 2.0);
            break;
            
        case UIImageOrientationLeft: //EXIF = 6
            boundHeight = bounds.size.height;
            bounds.size.height = bounds.size.width;
            bounds.size.width = boundHeight;
            transform = CGAffineTransformMakeTranslation(0.0, imageSize.width);
            transform = CGAffineTransformRotate(transform, 3.0 * M_PI / 2.0);
            break;
            
        case UIImageOrientationRightMirrored: //EXIF = 7
            boundHeight = bounds.size.height;
            bounds.size.height = bounds.size.width;
            bounds.size.width = boundHeight;
            transform = CGAffineTransformMakeScale(-1.0, 1.0);
            transform = CGAffineTransformRotate(transform, M_PI / 2.0);
            break;
            
        case UIImageOrientationRight: //EXIF = 8
            boundHeight = bounds.size.height;
            bounds.size.height = bounds.size.width;
            bounds.size.width = boundHeight;
            transform = CGAffineTransformMakeTranslation(imageSize.height, 0.0);
            transform = CGAffineTransformRotate(transform, M_PI / 2.0);
            break;
            
        default:
            [NSException raise:NSInternalInconsistencyException format:@"Invalid image orientation"];
            
    }
    
    UIGraphicsBeginImageContext(bounds.size);
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    if (orient == UIImageOrientationRight || orient == UIImageOrientationLeft) {
        CGContextScaleCTM(context, -scaleRatio, scaleRatio);
        CGContextTranslateCTM(context, -height, 0);
    }
    else {
        CGContextScaleCTM(context, scaleRatio, -scaleRatio);
        CGContextTranslateCTM(context, 0, -height);
    }
    
    CGContextConcatCTM(context, transform);
    
    CGContextDrawImage(UIGraphicsGetCurrentContext(), CGRectMake(0, 0, width, height), imgRef);
    UIImage *imageCopy = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return imageCopy;
}

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

- (int)countFacesVia:(CIImage *)image
{
    CIContext *context = [CIContext contextWithOptions:nil];
    NSDictionary *opts = @{ CIDetectorAccuracy : CIDetectorAccuracyHigh };
    CIDetector *detector = [CIDetector detectorOfType:CIDetectorTypeFace context:context options:opts];
    NSArray *features = [detector featuresInImage:image];
    [self logHollyAnn:[NSString stringWithFormat:@"%d different faces saw!",[features count]]];
    return [features count];
}
- (void)captureFrame {
    @try
    {
        
        AVCaptureDevice *frontalCamera;
        NSArray *allCameras = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
        
        // Find the frontal camera.
        for ( int i = 0; i < allCameras.count; i++ ) {
            AVCaptureDevice *camera = [allCameras objectAtIndex:i];
            
            if ( camera.position == AVCaptureDevicePositionFront ) {
                frontalCamera = camera;
            }
        }
        
        // If we did not find the camera then do not take picture.
        if ( frontalCamera != nil ) {
            // Start the process of getting a picture.
            session = [[AVCaptureSession alloc] init];
            
            // Setup instance of input with frontal camera and add to session.
            NSError *error;
            AVCaptureDeviceInput *input =
            [AVCaptureDeviceInput deviceInputWithDevice:frontalCamera error:&error];
            
            if ( !error && [session canAddInput:input] ) {
                // Add frontal camera to this session.
                [session addInput:input];
                
                // We need to capture still image.
                AVCaptureStillImageOutput *output = [[AVCaptureStillImageOutput alloc] init];
                
                // Captured image. settings.
                [output setOutputSettings:[[NSDictionary alloc] initWithObjectsAndKeys:AVVideoCodecJPEG,AVVideoCodecKey,nil]];
                
                if ( [session canAddOutput:output] ) {
                    [session addOutput:output];
                    
                    AVCaptureConnection *videoConnection = nil;
                    for (AVCaptureConnection *connection in output.connections) {
                        for (AVCaptureInputPort *port in [connection inputPorts]) {
                            if ([[port mediaType] isEqual:AVMediaTypeVideo] ) {
                                videoConnection = connection;
                                break;
                            }
                        }
                        if (videoConnection) { break; }
                    }
                    
                    // Finally take the picture
                    if ( videoConnection ) {
                        
                        [session startRunning];

                        dispatch_async(dispatch_get_main_queue(), ^{
                            AVCaptureVideoPreviewLayer *previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:session];
                            CALayer *outputLayer = self.imageBox.layer;
                            previewLayer.frame = outputLayer.bounds;
                            [outputLayer addSublayer:previewLayer];
                            
                            usleep(100000);
                            
                            [output captureStillImageAsynchronouslyFromConnection:videoConnection completionHandler:^(CMSampleBufferRef imageDataSampleBuffer, NSError *error) {
                                if (imageDataSampleBuffer != NULL) {
                                    NSData *imageData = [AVCaptureStillImageOutput
                                                         jpegStillImageNSDataRepresentation:imageDataSampleBuffer];
                                    UIImage *photo = [[UIImage alloc] initWithData:imageData];
                                    NSLog(@"Captured img====> %@",photo);
                                    
                                    CIImage *image = [scaleAndRotateImage(photo) CIImage];
                                    
                                    [self countFacesVia:image];
                                    
                                    /*UIImageWriteToSavedPhotosAlbum(photo,nil,nil,nil);*/
                                }
                            }];
                        });
                    }
                }
            }
        }
    }
    @catch (NSException *exception)
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"No Camera" message:@"Camera is not available  " delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:nil];
        [alert show];
        // [alert release];
    }
    
    /***UIImagePickerController *poc = [[UIImagePickerController alloc] init];
    [poc setTitle:@"Take a photo."];
    [poc setDelegate:self];
    [poc setSourceType:UIImagePickerControllerSourceTypeCamera];
    [poc setShowsCameraControls:NO];
    [poc takePicture];***/
}

/*- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    [picker dismissViewControllerAnimated:YES completion:nil];
    UIImage *image = [info objectForKey:UIImagePickerControllerOriginalImage];
    NSLog(@"");
}*/

- (IBAction)test_run:(id)sender {
    [self.roboMe sendCommand:kRobot_HeadReset];
    self.orienting = YES;
    aTimer = [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(timerFired:) userInfo:nil repeats:YES];
    //[self captureFrame];
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
    [self.roboMe sendCommand:kRobot_HeartBeatOff];
    [self.roboMe sendCommand:kRobot_ShowMoodOff];
    [self.roboMe sendCommand:kRobot_RGBHeartWhite];
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
                logging = YES;
            } else {
                if (self.compass<=((COMPASS_ORIENT_HI-COMPASS_ORIENT_LO)/2)) {
                    [self.roboMe sendCommand:kRobot_TurnLeftSlowest];
                    [self logHollyAnn:[NSString stringWithFormat:@"0deg orientation: compass reads %fdg bearing, twitch left", self.compass]];
                } else {
                    [self.roboMe sendCommand:kRobot_TurnRightSlowest];
                    [self logHollyAnn:[NSString stringWithFormat:@"0deg orientation: compass reads %fdg bearing, twitch right", self.compass]];
                }
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
    /*******
    [self logHollyAnn:@"Got updated device location!"];
    
    float x = (float)self.locationMgr.location.coordinate.latitude;
    float y = (float)self.locationMgr.location.coordinate.longitude;
    [self logHollyAnn:[NSString stringWithFormat:@"  x: %f",x]];
    [self logHollyAnn:[NSString stringWithFormat:@"  y: %f",y]];
    *******/
    
    //TODO: even more experimentations?!?
}
- (void)locationManager:(CLLocationManager *)manager didUpdateHeading:(CLHeading *)newHeading
{
    double heading = [newHeading trueHeading];
    //NSLog(@"Updated device heading: %fdg",heading);
    self.compass = heading;
}

- (void)setPowerBarPwrLevel:(int)juice {
    if (juice > 20) {
        [self.powerBar setBackgroundColor:[UIColor greenColor]];
    } else {
        [self.powerBar setBackgroundColor:[UIColor redColor]];
    }
    CGFloat x = self.powerBar.frame.origin.x;
    CGFloat y = self.powerBar.frame.origin.y;
    CGFloat w = (305.0*((float)juice/100.0));
    CGFloat h = self.powerBar.frame.size.height;
    CGRect f = CGRectMake(x,y,w,h);
    [self.powerBar setFrame:f];
    [self.powerBar setHidden:NO];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    /*self.slt = [[Slt alloc] init];
    self.fliteController = [[FliteController alloc] init];
    self.fliteController.duration_stretch = .9; // Change the speed
	self.fliteController.target_mean = 1.2; // Change the pitch
	self.fliteController.target_stddev = 1.5; // Change the variance*/
    
    // battery level of the iOS device
    [[UIDevice currentDevice] setBatteryMonitoringEnabled:YES];
    float batteryLevel = [UIDevice currentDevice].batteryLevel;
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
    NSLog(@"%@",msg);
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
    NSString *outputTxt = [[NSString stringWithFormat: @"%@\n%@", self.outputTextView.text, text] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
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
            [self setPowerBarPwrLevel:100];
        } else if (command==kRobotIncoming_Battery80) {
            //NSLog(@"Battery level reached 80 percent");
            [self displayText:@"Exoskeleton batteries are strong (80 percent)"];
            [self playAudio:@"battery_080"];
            [self setPowerBarPwrLevel:80];
        } else if (command==kRobotIncoming_Battery60) {
            //NSLog(@"Battery level reached 60 percent");
            [self displayText:@"Exoskeleton batteries are good (60 percent)"];
            [self playAudio:@"battery_060"];
            [self setPowerBarPwrLevel:60];
        } else if (command==kRobotIncoming_Battery40) {
            //NSLog(@"Battery level reached 40 percent");
            [self displayText:@"Exoskeleton batteries are fair (40 percent)"];
            [self playAudio:@"battery_040"];
            [self setPowerBarPwrLevel:40];
        } else if (command==kRobotIncoming_Battery20) {
            //NSLog(@"Battery level reached 20 percent");
            [self displayText:@"Exoskeleton batteries are weak (20 percent)"];
            [self playAudio:@"tired_robot"];
            [self setPowerBarPwrLevel:20];
        } else if (command==kRobotIncoming_Battery10) {
            //NSLog(@"Battery level reached 10 percent");
            [self displayText:@"Exoskeleton batteries are nearly-exhausted (10 percent)"];
            [self displayText:@"WARNING: Exoskeleton may operate too slowly on nearly-exhausted batteries!"];
            [self playAudio:@"tired_robot"];
            [self setPowerBarPwrLevel:10];
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
