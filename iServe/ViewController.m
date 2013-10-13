//
//  ViewController.m
//  iServe
//
//  Created by Mirza Kapetanovic on 7/16/13.
//  Copyright (c) 2013 Mirza Kapetanovic. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import <ifaddrs.h>
#import <arpa/inet.h>

#import "ViewController.h"

#import "ISServer.h"

const NSInteger ServerPort = 8080;

const NSInteger NumberOfSections = 2;

const NSInteger TextFieldTag = 1;
const NSInteger TextFieldMaxLength = 5;
const CGSize TextFieldSize = { 70, 30 };

const NSInteger SwitchTag = 2;

const NSInteger MarginRight = 12;

typedef struct {
    NSInteger index;
    NSInteger rows;
    NSString *header;
    NSString *footer;
} TableSection;

NSString *IpAddress() {
    struct ifaddrs *interfaces = NULL;
    struct ifaddrs *temp_addr = NULL;
    
    NSString *wifiAddress = nil;
    NSString *cellAddress = nil;
    
    // retrieve the current interfaces - returns 0 on success
    if(!getifaddrs(&interfaces)) {
        // Loop through linked list of interfaces
        temp_addr = interfaces;
        
        while(temp_addr != NULL) {
            sa_family_t sa_type = temp_addr->ifa_addr->sa_family;
            
            if(sa_type == AF_INET || sa_type == AF_INET6) {
                NSString *name = [NSString stringWithUTF8String:temp_addr->ifa_name];
                NSString *addr = [NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)temp_addr->ifa_addr)->sin_addr)]; // pdp_ip0
                
                if([name isEqualToString:@"en0"]) {
                    // Interface is the wifi connection on the iPhone
                    wifiAddress = addr;
                } else if([name isEqualToString:@"pdp_ip0"]) {
                    // Interface is the cell connection on the iPhone
                    cellAddress = addr;
                }
            }
            
            temp_addr = temp_addr->ifa_next;
        }
        
        // Free memory
        freeifaddrs(interfaces);
    }
    
    NSString *addr = wifiAddress ? wifiAddress : cellAddress;
    return addr ? addr : @"0.0.0.0";
}

NSString *FormatUrl(NSString *ip, NSString *port) {
    return [NSString stringWithFormat:@"http://%@:%@", ip, port];
}

@interface ViewController ()

@end

@implementation ViewController {
    ISServer *_server;
    NSString *_ip;
    NSInteger _port;
    
    TableSection *_tableSections[NumberOfSections];
    TableSection *_optionsSection;
    TableSection *_addressSection;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    _optionsSection = malloc(sizeof(TableSection));
    
    _optionsSection->index = 0;
    _optionsSection->rows = 2;
    _optionsSection->header = @"Server";
    _optionsSection->footer = nil;
    
    _addressSection = malloc(sizeof(TableSection));
    
    _addressSection->index = 1;
    _addressSection->rows = 1;
    _addressSection->header = @"Browser URL";
    _addressSection->footer = @"After starting the server, type in the URL in any browser connected to the same network";
    
    _tableSections[_optionsSection->index] = _optionsSection;
    _tableSections[_addressSection->index] = _addressSection;
    
    _ip = [IpAddress() retain];
    _port = ServerPort;
    
    /*self.addressLabel.layer.cornerRadius = 10;
    self.addressLabel.backgroundColor = [UIColor lightGrayColor];
    self.addressLabel.text = [NSString stringWithFormat:@"http://%@:%i", IpAddress(), ServerPort];
    
    _server = [[ISServer alloc] init];
    [_server listenOnPort:8080];*/
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/* Switch delegate */
-(void) onOffValueChanged:(BOOL)on {
    
}

/* Text field delegate */
-(BOOL) textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    NSUInteger oldLength = [textField.text length];
    NSUInteger replacementLength = [string length];
    NSUInteger rangeLength = range.length;
    
    NSUInteger newLength = oldLength - rangeLength + replacementLength;
    
    BOOL returnKey = [string rangeOfString: @"\n"].location != NSNotFound;
    
    return newLength <= TextFieldMaxLength || returnKey;
}

-(void) textFieldDidEndEditing:(UITextField *)textField {
    
}

/* Table view data source and delegate */
-(NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _tableSections[section]->rows;
}

-(NSInteger) numberOfSectionsInTableView:(UITableView *)tableView {
    return NumberOfSections;
}

-(NSString*) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return _tableSections[section]->header;
}

-(NSString*) tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    return _tableSections[section]->footer;
}

-(UITableViewCell*) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if(indexPath.section == _optionsSection->index) {
        switch (indexPath.row) {
            case 0:
                return [self createCellFieldViewWithId:@"CellField" text:@"Port"
                                           defaultText:[NSString stringWithFormat:@"%ld", (long)ServerPort]];
            case 1:
                return [self createCellDefaultWithId:@"CellDefault" text:@"Server" defaultValue:@"Off"];
        }
    } else if(indexPath.section == _addressSection->index) {
        return [self createCellLabelWithId:@"CellLabel"
                                      text:FormatUrl(_ip, [NSString stringWithFormat:@"%ld", (long)_port])];
    }
    
    return nil;
}

-(UITableViewCell*) createCellFieldViewWithId:(NSString*)cellId text:(NSString*)text defaultText:(NSString*)defaultText {
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellId];
    UITextField *field = [[UITextField alloc] initWithFrame:CGRectMake(0, 0, TextFieldSize.width, TextFieldSize.height)];
    
    field.tag = TextFieldTag;
    field.delegate = self;
    
    CGRect container = cell.contentView.frame;
    
    field.textAlignment = NSTextAlignmentRight;
    field.center = CGPointMake(container.size.width - (field.frame.size.width / 2) - MarginRight, container.size.height / 2);
    
    [field setText:defaultText];
    
    [cell.textLabel setText:text];
    [cell.contentView addSubview:field];
    
    return [cell autorelease];
}

-(UITableViewCell*) createCellLabelWithId:(NSString*)cellId text:(NSString*)text {
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellId];
    
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.textLabel.font = [UIFont fontWithName:@"Verdana" size:16];
    cell.textLabel.textAlignment = NSTextAlignmentCenter;
    [cell.textLabel setText:text];
    
    return [cell autorelease];
}

-(UITableViewCell*) createCellDefaultWithId:(NSString*)cellId text:(NSString*)text defaultValue:(NSString*)value {
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:cellId];
    
    [cell.textLabel setText:text];
    [cell.detailTextLabel setText:value];
    
    return [cell autorelease];
}

-(void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if(indexPath.section == _optionsSection->index) {
        UITableViewCell *cell = [_tableView cellForRowAtIndexPath:
                                 [NSIndexPath indexPathForRow:0 inSection:_optionsSection->index]];
        
        UITextField *field = (UITextField*) [cell.contentView viewWithTag:TextFieldTag];
        
        switch (indexPath.row) {
            case 0:
                [field becomeFirstResponder];
                break;
            case 1:
                [field resignFirstResponder];
                
                cell = [_tableView cellForRowAtIndexPath:indexPath];
                BOOL on = ![[cell.detailTextLabel.text lowercaseString] isEqualToString:@"on"];
                
                if(on) {
                    field.enabled = NO;
                    [cell.detailTextLabel setText:@"On"];
                } else {
                    field.enabled = YES;
                    [cell.detailTextLabel setText:@"Off"];
                }
                
                [self onOffValueChanged:on];
                
                break;
        }
    }
    
    [_tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)dealloc {
    for(int i = 0; i < NumberOfSections; i++) {
        free(_tableSections[i]);
        _tableSections[i] = NULL;
    }
    
    _optionsSection = NULL;
    _addressSection = NULL;
    
    [_server release];
    [_ip release];
    
    [_tableView release];
    
    [super dealloc];
}
@end
