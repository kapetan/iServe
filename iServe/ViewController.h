//
//  ViewController.h
//  iServe
//
//  Created by Mirza Kapetanovic on 7/16/13.
//  Copyright (c) 2013 Mirza Kapetanovic. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController
@property (retain, nonatomic) IBOutlet UISwitch *onOffSwitch;
@property (retain, nonatomic) IBOutlet UILabel *addressLabel;
- (IBAction)onOffValueChanged:(id)sender;
@end
