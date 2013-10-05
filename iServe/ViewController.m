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

NSInteger ServerPort = 8080;

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

@interface ViewController ()

@end

@implementation ViewController {
    ISServer *_server;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    self.addressLabel.layer.cornerRadius = 10;
    self.addressLabel.backgroundColor = [UIColor lightGrayColor];
    self.addressLabel.text = [NSString stringWithFormat:@"http://%@:%i", IpAddress(), ServerPort];
    
    _server = [[ISServer alloc] init];
    [_server listenOnPort:8080];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)onOffValueChanged:(id)sender {
    UISwitch *btn = (UISwitch *) sender;
    
    if(btn.on) {
        
    } else {
        
    }
}

- (void)dealloc {
    [_addressLabel release];
    [_onOffSwitch release];
    
    [_server release];
    
    [super dealloc];
}
@end
