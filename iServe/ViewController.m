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

#define I18N(key) NSLocalizedString(key, nil)

const NSInteger ServerPort = 8080;

const NSInteger NumberOfSections = 2;

const NSInteger TextFieldMaxLength = 5;
const CGSize TextFieldSize = { 70, 30 };

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
    _optionsSection->header = I18N(@"OPTIONS_SECTION_HEADER");
    _optionsSection->footer = nil;
    
    _addressSection = malloc(sizeof(TableSection));
    
    _addressSection->index = 1;
    _addressSection->rows = 1;
    _addressSection->header = I18N(@"ADDRESS_SECTION_HEADER");
    _addressSection->footer = I18N(@"ADDRESS_SECTION_FOOTER");
    
    _tableSections[_optionsSection->index] = _optionsSection;
    _tableSections[_addressSection->index] = _addressSection;
    
    _server = nil;
    _port = ServerPort;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(NSString*) getAddress {
    NSString *ip = IpAddress();
    return FormatUrl(ip, [NSString stringWithFormat:@"%ld", (long)_port]);
}

/* Switch delegate */
-(void) onOffValueChanged:(BOOL)on {
    UITableViewCell *cell = [_tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:_addressSection->index]];
    
    if(on) {
        ALAuthorizationStatus auth = [ALAssetsLibrary authorizationStatus];
        
        if(auth == ALAuthorizationStatusDenied || auth == ALAuthorizationStatusRestricted) {
            UIAlertView *alert = [[UIAlertView alloc]
                                  initWithTitle:I18N(@"PHOTOS_ACCESS_TITLE")
                                  message:I18N(@"PHOTOS_ACCESS_MESSAGE")
                                  delegate:nil
                                  cancelButtonTitle:I18N(@"PHOTOS_ACCESS_CANCEL_BUTTON")
                                  otherButtonTitles:nil, nil];
            
            [alert show];
            [alert release];
        }
        
        _server = [[ISServer alloc] init];
        [_server listenOnPort:_port];
        
        [cell.textLabel setText:[self getAddress]];
    } else {
        [_server close];
        [_server release];
        
        _server = nil;
        
        [cell.textLabel setText:I18N(@"ADDRESS_SECTION_SERVER_NOT_STARTED")];
    }
}

-(BOOL) isServerOn {
    return !!_server;
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
    NSString *text = [textField text];
    NSScanner *scanner = [NSScanner scannerWithString:text];
    
    int port;
    BOOL numeric = [scanner scanInt:&port] && [scanner isAtEnd];
    
    if(!numeric) {
        [textField setText:[NSString stringWithFormat:@"%ld", (long)_port]];
        return;
    }
    
    _port = port;
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
    UITableViewCell *cell = nil;
    
    if(indexPath.section == _optionsSection->index) {
        switch (indexPath.row) {
            case 0:
                cell = [self reuseCellWithId:@"CellField" orCreateUsingSelector:@selector(createCellFieldViewWithId:)];
                UITextField *field = (UITextField*) cell.accessoryView;
                
                [field setText:[NSString stringWithFormat:@"%ld", (long)_port]];
                field.enabled = ![self isServerOn];
                
                [cell.textLabel setText:I18N(@"OPTIONS_SECTION_SERVER_PORT")];
                
                break;
            case 1:
                cell = [self reuseCellWithId:@"CellDefault" orCreateUsingSelector:@selector(createCellDefaultWithId:)];
                
                [cell.textLabel setText:I18N(@"OPTIONS_SECTION_SERVER_STATE")];
                [cell.detailTextLabel setText:[self isServerOn] ? I18N(@"SHARED_ON") : I18N(@"SHARED_OFF")];
                
                break;
        }
    } else if(indexPath.section == _addressSection->index) {
        cell = [self reuseCellWithId:@"CellLabel" orCreateUsingSelector:@selector(createCellLabelWithId:)];
        
        NSString *text = [self isServerOn] ? [self getAddress] : I18N(@"ADDRESS_SECTION_SERVER_NOT_STARTED");
        
        [cell.textLabel setText:text];
    }
    
    return cell;
}

-(UITableViewCell*) reuseCellWithId:(NSString*)cellId orCreateUsingSelector:(SEL)selector {
    UITableViewCell *cell = [_tableView dequeueReusableCellWithIdentifier:cellId];
    
    if(!cell) {
        cell = [self performSelector:selector withObject:cellId];
    }
    
    return cell;
}

-(UITableViewCell*) createCellFieldViewWithId:(NSString*)cellId {
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellId];
    UITextField *field = [[UITextField alloc] initWithFrame:CGRectMake(0, 0, TextFieldSize.width, TextFieldSize.height)];
    
    field.delegate = self;
    field.textAlignment = NSTextAlignmentRight;
    
    cell.accessoryView = field;
    
    return [cell autorelease];
}

-(UITableViewCell*) createCellLabelWithId:(NSString*)cellId {
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellId];
    
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.textLabel.font = [UIFont fontWithName:@"Verdana" size:16];
    cell.textLabel.textAlignment = NSTextAlignmentCenter;
    
    return [cell autorelease];
}

-(UITableViewCell*) createCellDefaultWithId:(NSString*)cellId {
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:cellId];
    
    return [cell autorelease];
}

-(void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if(indexPath.section == _optionsSection->index) {
        UITableViewCell *cell = [_tableView cellForRowAtIndexPath:
                                 [NSIndexPath indexPathForRow:0 inSection:_optionsSection->index]];
        
        UITextField *field = (UITextField*) cell.accessoryView;
        
        switch (indexPath.row) {
            case 0:
                [field becomeFirstResponder];
                break;
            case 1:
                [field resignFirstResponder];
                
                cell = [_tableView cellForRowAtIndexPath:indexPath];
                BOOL on = ![self isServerOn]; //![[cell.detailTextLabel.text lowercaseString] isEqualToString:@"on"];
                
                if(on) {
                    field.enabled = NO;
                    [cell.detailTextLabel setText:I18N(@"SHARED_ON")];
                } else {
                    field.enabled = YES;
                    [cell.detailTextLabel setText:I18N(@"SHARED_OFF")];
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
    
    [_tableView release];
    
    [super dealloc];
}
@end
