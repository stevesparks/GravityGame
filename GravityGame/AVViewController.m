//
//  AVViewController.m
//  GravityGame
//
//  Created by Steve Sparks on 3/30/14.
//  Copyright (c) 2014 Me. All rights reserved.
//

#import "AVViewController.h"
#import <CoreMotion/CoreMotion.h>

@interface AVViewController ()
@property (strong, nonatomic) UIDynamicAnimator *animator;
@property (strong, nonatomic) UICollisionBehavior *collider;
@property (strong, nonatomic) UIGravityBehavior *gravity;
@property (strong, nonatomic) UIDynamicItemBehavior *boxBehavior;
@property (strong, nonatomic) UIDynamicItemBehavior *roxBehavior;
@property (weak, nonatomic) IBOutlet UISlider *elasticitySlider;
@property (weak, nonatomic) IBOutlet UILabel *elasticityLabel;
@property (weak, nonatomic) IBOutlet UILabel *sourceLabel;
@property (weak, nonatomic) IBOutlet UISwitch *sourceSwitch;


@property (strong, nonatomic) NSOperationQueue *motionQueue;
@property (strong, nonatomic) CMMotionManager *motionMgr;

@property (nonatomic) CGFloat boxElasticity;

@end
static NSString * const RoxIdentifier = @"barrier %d %@";

@implementation AVViewController

#define RAND8	(((float)(rand()&0xFFFF))/65536)
#define RANDCOLOR [UIColor colorWithRed:RAND8 green:RAND8 blue:RAND8 alpha:0.7];

- (void)viewDidLoad
{
    [super viewDidLoad];
	self.touchView.delegate = self;

	self.motionMgr = [[CMMotionManager alloc] init];
	self.motionQueue = [[NSOperationQueue alloc] init];

	self.elasticitySlider.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.8];

	self.animator = [[UIDynamicAnimator alloc] initWithReferenceView:self.view];

	UICollisionBehavior *collider = [[UICollisionBehavior alloc] init];
    collider.collisionMode = UICollisionBehaviorModeEverything;
    collider.translatesReferenceBoundsIntoBoundary = YES;
	self.collider = collider;
	[self.animator addBehavior:collider];

	UIDynamicItemBehavior *rox = [[UIDynamicItemBehavior alloc] init];
	rox.allowsRotation = NO;
	rox.elasticity = 20;
	rox.density = 1000;
	rox.friction = 0.01;
	self.roxBehavior = rox;
	[self.animator addBehavior:rox];


	UIDynamicItemBehavior *box = [[UIDynamicItemBehavior alloc] init];
	box.allowsRotation = YES;
	box.elasticity = _elasticitySlider.value;
	box.friction = 0.1;
	self.boxBehavior = box;
	[self.animator addBehavior:box];

	UIGravityBehavior *grav = [[UIGravityBehavior alloc] init];
	self.gravity = grav;
	[self.animator addBehavior:grav];

	[self touchViewDidChange:self.touchView];
}

- (void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];
	[self redrawBoxAndRocks];
}

- (IBAction)redrawStuff:(id)sender {
	[self redrawBoxAndRocks];
}

- (void) redrawBoxAndRocks {
	// first clear 'em all
	int nBoxes = 10;
	int nRocks = 10;
	int boxSize = 20;
	int roxSize = 10;

	if([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
		nBoxes = 10;
		nRocks = 10;
		boxSize = 40;
		roxSize = 25;
	}


	for(UIView *v in self.boxBehavior.items) {
		[self.collider removeItem:v];
		[self.boxBehavior removeItem:v];
		[v removeFromSuperview];
	}

	for(UIView *v in self.roxBehavior.items) {
		[self.collider removeBoundaryWithIdentifier:[NSString stringWithFormat:RoxIdentifier, (int)v.tag, @"top"]];
		[self.collider removeBoundaryWithIdentifier:[NSString stringWithFormat:RoxIdentifier, (int)v.tag, @"bottom"]];
		[self.collider removeBoundaryWithIdentifier:[NSString stringWithFormat:RoxIdentifier, (int)v.tag, @"left"]];
		[self.collider removeBoundaryWithIdentifier:[NSString stringWithFormat:RoxIdentifier, (int)v.tag, @"right"]];
		[self.roxBehavior removeItem:v];
		[v removeFromSuperview];
	}

	int maxX = self.view.bounds.size.width - boxSize;
	int maxY = self.elasticitySlider.frame.origin.y;

	for(int x = 0; x < nBoxes; x++) {
		CGFloat x = arc4random()%maxX;
		CGFloat y = arc4random()%maxY;
		CGRect frm = CGRectMake(x, y, boxSize, boxSize);
		UIView *v = [[UIView alloc] initWithFrame:frm];
		v.layer.cornerRadius = boxSize/4;
		v.backgroundColor = RANDCOLOR;

		[self.view insertSubview:v atIndex:0];
		[self.boxBehavior addItem:v];
		[self.gravity addItem:v];
		[self.collider addItem:v];
	}

	for(int c = 0; c < nRocks; c++) {
		CGFloat x = arc4random()%maxX;
		CGFloat y = arc4random()%maxY;
		CGRect frm = CGRectMake(x, y, roxSize, roxSize);
		UIView *v = [[UIView alloc] initWithFrame:frm];
		v.backgroundColor = [UIColor blackColor];
		[self.view insertSubview:v atIndex:0];
		[self.roxBehavior addItem:v];
		v.tag = c;

		v.layer.shadowColor = [UIColor blackColor].CGColor;
		v.layer.shadowOffset = CGSizeMake(roxSize/12,roxSize/12);
		v.layer.shadowOpacity = 0.9;
		v.layer.shadowRadius = roxSize/12;

		CGPoint bottomRightCorner = CGPointMake(x + roxSize, y + roxSize);
		CGPoint topRightCorner = CGPointMake(x + roxSize, y);
		CGPoint bottomLeftCorner = CGPointMake(x, y + roxSize);

		[self.collider addBoundaryWithIdentifier:[NSString stringWithFormat:RoxIdentifier, c, @"top"]
									   fromPoint:frm.origin
										 toPoint:topRightCorner];
		[self.collider addBoundaryWithIdentifier:[NSString stringWithFormat:RoxIdentifier, c, @"left"]
									   fromPoint:frm.origin
										 toPoint:bottomLeftCorner];
		[self.collider addBoundaryWithIdentifier:[NSString stringWithFormat:RoxIdentifier, c, @"bottom"]
									   fromPoint:bottomLeftCorner
										 toPoint:bottomRightCorner];
		[self.collider addBoundaryWithIdentifier:[NSString stringWithFormat:RoxIdentifier, c, @"right"]
									   fromPoint:topRightCorner
										 toPoint:bottomRightCorner];
	}
}

- (BOOL)shouldAutorotate {
	return (self.sourceSwitch.on);
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
	[self redrawBoxAndRocks];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)setBoxElasticity:(CGFloat)boxElasticity {
	_boxElasticity = boxElasticity;
	_boxBehavior.elasticity = boxElasticity;
}

- (void)touchViewDidChange:(AVTouchView *)touchView {
	CGPoint p = touchView.offsetFromCenter;

	CGVector v = CGVectorMake(0 - (p.x / 50),0 - (p.y / 50));

	self.gravity.gravityDirection = v;
};

- (IBAction)elasticitySliderChanged:(UISlider*)sender {
	self.boxElasticity = sender.value;
	self.elasticityLabel.text = [NSString stringWithFormat:@"%.3f elasticity", self.boxElasticity];
}

- (IBAction)sourceSwitchChanged:(UISwitch*)sender {

	if(! sender.on) {
		self.sourceLabel.text = @"Gravity";
		self.touchView.userInteractionEnabled = NO;

		[self.motionMgr startDeviceMotionUpdatesUsingReferenceFrame:CMAttitudeReferenceFrameXArbitraryCorrectedZVertical toQueue:self.motionQueue withHandler:^(CMDeviceMotion *motion, NSError *err){
			CGPoint p = CGPointMake(motion.gravity.x * 50,
									motion.gravity.y * -50);

			// Have to correct for orientation.
			UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
			if(orientation == UIInterfaceOrientationLandscapeLeft) {
				CGFloat t = p.x;
				p.x = 0 - p.y;
				p.y = t;
			} else if (orientation == UIInterfaceOrientationLandscapeRight) {
				CGFloat t = p.x;
				p.x = p.y;
				p.y = 0 - t;
			} else if (orientation == UIInterfaceOrientationPortraitUpsideDown) {
				p.x *= -1;
				p.y *= -1;
			}

			dispatch_async(dispatch_get_main_queue(), ^{
				[self.touchView setOffsetFromCenter:p];
			});
		}];
	} else {
		self.sourceLabel.text = @"Joystick";
		[self.motionMgr stopDeviceMotionUpdates];
		self.touchView.userInteractionEnabled = YES;
	}




}


@end
