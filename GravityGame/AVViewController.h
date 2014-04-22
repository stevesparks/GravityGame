//
//  AVViewController.h
//  GravityGame
//
//  Created by Steve Sparks on 3/30/14.
//  Copyright (c) 2014 Me. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AVTouchView.h"

@interface AVViewController : UIViewController<AVTouchViewDelegate>
@property (weak, nonatomic) IBOutlet AVTouchView *touchView;

@end
