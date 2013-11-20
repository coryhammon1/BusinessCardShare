//
//  BCFirstViewController.m
//  BusinessCardShare
//
//  Created by Cory Hammon on 11/9/13.
//  Copyright (c) 2013 Cory Hammon. All rights reserved.
//

#import "BCFirstViewController.h"
#import <CoreBluetooth/CoreBluetooth.h>

@interface BCFirstViewController () <UITextFieldDelegate, CBCentralManagerDelegate, CBPeripheralManagerDelegate>

@property (weak, nonatomic) IBOutlet UITextField *nameTextField;
@property (weak, nonatomic) IBOutlet UITextField *organizationTextField;
@property (weak, nonatomic) IBOutlet UITextField *titleTextField;
@property (weak, nonatomic) IBOutlet UISwitch *shareSwitch;

@property (strong, nonatomic) CBCentralManager *centralManager;
@property (strong, nonatomic) CBPeripheralManager *peripheralManager;
@property (strong, nonatomic) CBUUID *serviceId;

@end

@implementation BCFirstViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    
    self.nameTextField.text = [userDefaults objectForKey:BCNameUserDefaultKey];
    self.organizationTextField.text = [userDefaults objectForKey:BCOrganizationUserDefaultKey];
    self.titleTextField.text = [userDefaults objectForKey:BCTitleUserDefaultKey];
    
    self.serviceId = [CBUUID UUIDWithString:@"360D"];
    
    self.centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
    self.peripheralManager = [[CBPeripheralManager alloc] initWithDelegate:self queue:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)shareSwitchAction:(UISwitch *)shareSwitch {
    if (!shareSwitch.on) {
        [self.centralManager stopScan];
        [self.peripheralManager stopAdvertising];
    } else {
        [self.centralManager scanForPeripheralsWithServices:@[self.serviceId] options:nil];
        [self.peripheralManager startAdvertising:@{CBAdvertisementDataServiceUUIDsKey: @[self.serviceId]}];
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    
    return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    
    if (textField == self.nameTextField) {
        [[NSUserDefaults standardUserDefaults] setObject:textField.text forKey:BCNameUserDefaultKey];
    } else if (textField == self.organizationTextField) {
        [[NSUserDefaults standardUserDefaults] setObject:textField.text forKey:BCOrganizationUserDefaultKey];
    } else if (textField == self.titleTextField) {
        [[NSUserDefaults standardUserDefaults] setObject:textField.text forKey:BCTitleUserDefaultKey];
    }
    
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)centralManagerDidUpdateState:(CBCentralManager *)central {
    
    if (self.shareSwitch.on && self.centralManager.state == CBCentralManagerStatePoweredOn) {
        [self.centralManager scanForPeripheralsWithServices:nil options:nil];
    }
    
    NSLog(@"Central Manager State: %d", central.state);
}

- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI {
    
    NSLog(@"Discovered %@", peripheral.name);
    
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Discovered device" message:@"Discovered a device" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alertView show];
    
}

- (void)peripheralManagerDidUpdateState:(CBPeripheralManager *)peripheral {
    
    if (self.shareSwitch.on && peripheral.state == CBPeripheralManagerStatePoweredOn) {
        CBMutableCharacteristic *characteristic = [[CBMutableCharacteristic alloc] initWithType:self.serviceId properties:CBCharacteristicPropertyRead value:[@"Characteristic" dataUsingEncoding:NSASCIIStringEncoding] permissions:CBAttributePermissionsReadable];
        
        CBMutableService *service = [[CBMutableService alloc] initWithType:self.serviceId primary:YES];
        
        service.characteristics = @[characteristic];
        
        [self.peripheralManager addService:service];
        
        [self.peripheralManager startAdvertising:@{CBAdvertisementDataServiceUUIDsKey: @[self.serviceId]}];
    }
    
    NSLog(@"Peripheral manager did update state: %d", peripheral.state);
}

- (void)peripheralManager:(CBPeripheralManager *)peripheral didAddService:(CBService *)service error:(NSError *)error {
    
    if (error) {
        NSLog(@"Error adding service: %@", [error localizedDescription]);
    }
}

- (void)peripheralManagerDidStartAdvertising:(CBPeripheralManager *)peripheral error:(NSError *)error {
    if (error) {
        NSLog(@"Error advertising: %@", [error localizedDescription]);
    } else {
        NSLog(@"Did start advertising");
    }
}

@end
