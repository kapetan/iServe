//
//  ViewController.h
//  iServe
//
//  Created by Mirza Kapetanovic on 7/16/13.
//  Copyright (c) 2013 Mirza Kapetanovic. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate>
@property (retain, nonatomic) IBOutlet UITableView *tableView;
@end
