//
//  MainViewController.m
//  OpenCV-iPad
//
//  Created by Kyle Roche on 10/20/11.
//  Copyright (c) 2011 Isidorey. All rights reserved.
/*
Utility methods derived from github.com/macmade/facedetect
Improved by Kyle Roche for use in Professional iOS 5 Augmented Reality (Apress)
Distributed under Boost Software License. 
 
Boost Software License - Version 1.0 - August 17th, 2003

Permission is hereby granted, free of charge, to any person or organization
obtaining a copy of the software and accompanying documentation covered by
this license (the "Software") to use, reproduce, display, distribute,
execute, and transmit the Software, and to prepare derivative works of the
Software, and to permit third-parties to whom the Software is furnished to
do so, all subject to the following:

The copyright notices in the Software and this entire statement, including
the above license grant, this restriction and the following disclaimer,
must be included in all copies of the Software, in whole or in part, and
all derivative works of the Software, unless such copies or derivative
works are solely in the form of machine-executable object code generated by
a source language processor.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE, TITLE AND NON-INFRINGEMENT. IN NO EVENT
SHALL THE COPYRIGHT HOLDERS OR ANYONE DISTRIBUTING THE SOFTWARE BE LIABLE
FOR ANY DAMAGES OR OTHER LIABILITY, WHETHER IN CONTRACT, TORT OR OTHERWISE,
ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
DEALINGS IN THE SOFTWARE.

*/


#import "MainViewController.h"
#import <opencv/cv.h>
#import "CodeTimestamps.h"

@interface MainViewController (Private)
- (IplImage *)createIplImage:(UIImage *)image;
- (void)openCVFaceDetect;
- (void)CIDetectorFaceDetect;
- (void)FaceDotComFaceDetect;
@end

@implementation MainViewController
@synthesize cameraView;
@synthesize timerLabel;
@synthesize toolbar;
@synthesize detector = _detector;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}


- ( void )openCVFaceDetect
{
    LogTimestamp;
    
    NSInteger                 i;
    NSUInteger                scale;
    NSAutoreleasePool       * pool;
    IplImage                * image;
    IplImage                * smallImage;
    NSString                * xmlPath;
    CvHaarClassifierCascade * cascade;
    CvMemStorage            * storage;
    CvSeq                   * faces;
    UIAlertView             * alert;
    CGImageRef                imageRef;
    CGColorSpaceRef           colorSpaceRef;
    CGContextRef              context;
    CvRect                    rect;
    CGRect                    faceRect;
    
    pool  = [ [ NSAutoreleasePool alloc ] init ];
    scale = 2;
    
    cvSetErrMode( CV_ErrModeParent );
    
    xmlPath    = [ [ NSBundle mainBundle ] pathForResource: @"haarcascade_frontalface_default" ofType: @"xml" ];
    image      = [ self createIplImage: cameraView.image ];
    smallImage = cvCreateImage( cvSize( image->width / scale, image->height / scale ), IPL_DEPTH_8U, 3 );
    
    cvPyrDown( image, smallImage, CV_GAUSSIAN_5x5 );
    
    cascade = ( CvHaarClassifierCascade * )cvLoad( [ xmlPath cStringUsingEncoding: NSASCIIStringEncoding ], NULL, NULL, NULL );
    storage = cvCreateMemStorage( 0 );
    faces   = cvHaarDetectObjects( smallImage, cascade, storage, ( float )1.2, 2, CV_HAAR_DO_CANNY_PRUNING, cvSize( 20, 20 ) );
    
    cvReleaseImage( &smallImage );
    
    imageRef      = cameraView.image.CGImage;
    colorSpaceRef = CGColorSpaceCreateDeviceRGB();
    context       = CGBitmapContextCreate
    (
     NULL,
     cameraView.image.size.width,
     cameraView.image.size.height,
     8,
     cameraView.image.size.width * 4,
     colorSpaceRef,
     kCGImageAlphaPremultipliedLast | kCGBitmapByteOrderDefault
     );
    
    CGContextDrawImage
    (
     context,
     CGRectMake( 0, 0, cameraView.image.size.width, cameraView.image.size.height ),
     imageRef
     );
    
    CGContextSetLineWidth( context, 1 );
    CGContextSetRGBStrokeColor( context, ( CGFloat )0, ( CGFloat )0, ( CGFloat )0, ( CGFloat )0.5 );
    CGContextSetRGBFillColor( context, ( CGFloat )1, ( CGFloat )1, ( CGFloat )1, ( CGFloat )0.5 );
    
    if( faces->total == 0 )
    {
        alert = [ [ UIAlertView alloc ] initWithTitle: @"No faces" message: @"No faces were detected in the picture. Please try with another one." delegate: NULL cancelButtonTitle: @"OK" otherButtonTitles: nil ];
        
        [ alert show ];
        [ alert release ];
    }
    else
    {
        for( i = 0; i < faces->total; i++ )
        {
            rect     = *( CvRect * )cvGetSeqElem( faces, i );
            faceRect = CGContextConvertRectToDeviceSpace( context, CGRectMake( rect.x * scale, rect.y * scale, rect.width * scale, rect.height * scale ) );
            
            CGContextFillRect( context, faceRect );
            CGContextStrokeRect( context, faceRect );
        }
        
        cameraView.image = [ UIImage imageWithCGImage: CGBitmapContextCreateImage( context ) ];
    }
    
    CGContextRelease( context );
    CGColorSpaceRelease( colorSpaceRef );
    cvReleaseMemStorage( &storage );
    cvReleaseHaarClassifierCascade( &cascade );
    cvReleaseImage( &smallImage );
    
    [pool release];
    LogTimestamp;
}

- ( IplImage * )createIplImage: ( UIImage * )image
{
    CGImageRef      imageRef;
    CGColorSpaceRef colorSpaceRef;
    CGContextRef    context;
    IplImage      * iplImage;
    IplImage      * returnImage;
    
    imageRef      = image.CGImage;
    colorSpaceRef = CGColorSpaceCreateDeviceRGB();
    iplImage      = cvCreateImage( cvSize( image.size.width, image.size.height ), IPL_DEPTH_8U, 4 );
    context       = CGBitmapContextCreate
    (
     iplImage->imageData,
     iplImage->width,
     iplImage->height,
     iplImage->depth,
     iplImage->widthStep,
     colorSpaceRef,
     kCGImageAlphaPremultipliedLast | kCGBitmapByteOrderDefault
     );
    
    CGContextDrawImage( context, CGRectMake( 0, 0, image.size.width, image.size.height ), imageRef );
    CGContextRelease( context );
    CGColorSpaceRelease( colorSpaceRef );
    
    returnImage = cvCreateImage( cvGetSize( iplImage ), IPL_DEPTH_8U, 3 );
    
    cvCvtColor( iplImage, returnImage, CV_RGBA2BGR );
    cvReleaseImage( &iplImage );
    
    return returnImage;
}

-(void) CIDetectorFaceDetect {
    LogTimestamp;
    NSLog(@"CI Face Detect started");
    NSArray *arr = [self.detector featuresInImage:[CIImage imageWithCGImage:[cameraView.image CGImage]]];
    NSLog(@"Set up Array");
    if([arr count]>0){
        for(int i=0;i<[arr count];i++){
            NSLog(@"%d Face found!",i + 1);
            CIFaceFeature * feature = [arr objectAtIndex:i];
            if(feature.hasLeftEyePosition){
                NSLog(@"Left eye position: (%f, %f)",feature.leftEyePosition.x,feature.leftEyePosition.y);
            }
            if(feature.hasRightEyePosition){
                NSLog(@"Right eye position: (%f, %f)",feature.rightEyePosition.x,feature.rightEyePosition.y);
            }
            if(feature.hasMouthPosition){
                NSLog(@"Mouth position: (%f, %f)",feature.mouthPosition.x,feature.mouthPosition.y);
            }
            
        }
    } else {
        NSLog(@"Nothing detected");
    }
    LogTimestamp;
}

- (void)FaceDotComFaceDetect {
    LogTimestamp;
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
    NSData * imageData = UIImageJPEGRepresentation(cameraView.image, 90);
        
    NSURL * url = [NSURL URLWithString:@"http://api.face.com/faces/detect.json"];
        
    ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:url];
    [request addPostValue:@"" forKey:@"api_key"];
    [request addPostValue:@"" forKey:@"api_secret"];
    [request addPostValue:@"all" forKey:@"attributes"];
    [request addData:imageData withFileName:@"image.jpg" andContentType:@"image/jpeg" forKey:@"filename"];
    
    [request startSynchronous];
    
    NSError *error = [request error];
    if (!error) {
        NSString *response = [request responseString];
        NSDictionary *feed = [NSJSONSerialization JSONObjectWithData:[request responseData] 
                                                             options:kNilOptions 
                                                               error:&error];
        
        NSLog(@"RETURN: %@", [feed allKeys]);
        NSLog(@"%@",response);
    } else {
        NSLog(@"An error occured %d",[error code]);
    }
    
    [pool drain];  
    LogTimestamp;
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    _imagePicker = [[UIImagePickerController alloc] init];
    _imagePicker.delegate = self;
    
    // CIDetector test
    NSDictionary *_options = [NSDictionary dictionaryWithObjectsAndKeys:CIDetectorAccuracyLow, CIDetectorAccuracy, nil];
    self.detector = [CIDetector detectorOfType:CIDetectorTypeFace context:nil options:_options];
}

- (void)viewDidUnload
{
    [self setCameraView:nil];
    [self setTimerLabel:nil];
    [self setToolbar:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
	return YES;
}

- (void)dealloc {
    [cameraView release];
    [timerLabel release];
    [_imagePicker release];
    [toolbar release];
    [_detector release];
    [super dealloc];
}
- (IBAction)cameraButtonClicked:(id)sender {
    UIActionSheet *_sheet = [[UIActionSheet alloc] initWithTitle:@"Choose Source" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Camera", @"Library", @"Photo Album", nil];
    [_sheet showInView:self.view];
    [_sheet release];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 0) {
        _imagePicker.sourceType = UIImagePickerControllerSourceTypeCamera;
        [self presentModalViewController:_imagePicker animated:YES];
        return;
    } else if (buttonIndex == 1) {
        _imagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    } else {
        _imagePicker.sourceType = UIImagePickerControllerSourceTypeSavedPhotosAlbum;
    }
    _imagePopover = [[UIPopoverController alloc] initWithContentViewController:_imagePicker];
    _imagePopover.delegate = self;
    [_imagePopover presentPopoverFromRect:toolbar.frame
                                   inView:self.view
                 permittedArrowDirections:UIPopoverArrowDirectionAny
                                 animated:YES];
    [_imagePicker release];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingImage:(UIImage *)image editingInfo:(NSDictionary *)editingInfo {
    [self dismissModalViewControllerAnimated:YES];
    cameraView.image = image;
    
    //[self openCVFaceDetect];
    //[self CIDetectorFaceDetect];
    [self FaceDotComFaceDetect];
}

@end
