/**
 * IoTMainController.m
 *
 * Copyright (c) 2014~2015 Xtreme Programming Group, Inc.
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

#import "IoTMainController.h"
#import "IoTAlertView.h"
#import "IoTMainMenu.h"
#import "IoTRecord.h"
#import "IoTAlertView.h"
#import <CoreLocation/CoreLocation.h>

#define ALERT_TAG_SHUTDOWN          1

@interface IoTMainController ()<UIAlertViewDelegate,IoTAlertViewDelegate,CLLocationManagerDelegate, XPGWifiSDKDelegate, XPGWifiDeviceDelegate>
{
    //提示框
    IoTAlertView *_alertView;
    UIAlertView *cAlertView;
    //数据点的临时变量
    BOOL bSwitch;
    BOOL bFault;
    NSInteger iMode;
    NSInteger iFilter1;
    NSInteger iFilter2;
    NSInteger iFilter3;
    NSInteger iFilter4;
    NSInteger iFilter5;
    
    
}

@property (strong, nonatomic) SlideNavigationController *navCtrl;

@property (weak, nonatomic) IBOutlet UIView *shutDownView;
@property (weak, nonatomic) IBOutlet UIView *resetView;
@property (weak, nonatomic) IBOutlet UIView *viewFault;

@property (weak, nonatomic) IBOutlet UIButton *btnShutDown;
@property (weak, nonatomic) IBOutlet UIButton *btnFilterFlush;
@property (weak, nonatomic) IBOutlet UIButton *btnCleanWater;

@property (weak, nonatomic) IBOutlet UILabel *textFilterName;
@property (weak, nonatomic) IBOutlet UILabel *textFilterLift;
@property (weak, nonatomic) IBOutlet UILabel *textFilterStatus;
@property (weak, nonatomic) IBOutlet UILabel *textFilterValue;

@property (weak, nonatomic) IBOutlet UIButton *btnReset;
@property (weak, nonatomic) IBOutlet UIButton *btnFilter1;
@property (weak, nonatomic) IBOutlet UIButton *btnFilter2;
@property (weak, nonatomic) IBOutlet UIButton *btnFilter3;
@property (weak, nonatomic) IBOutlet UIButton *btnFilter4;
@property (weak, nonatomic) IBOutlet UIButton *btnFilter5;

@property (weak, nonatomic) IBOutlet UILabel *textDevice;
@property (weak, nonatomic) IBOutlet UILabel *textFilterStatus2;

@property (strong, nonatomic) NSArray *faults;

@end

@implementation IoTMainController

- (id)initWithDevice:(XPGWifiDevice *)device
{
    self = [super init];
    if(self)
    {
        if(nil == device)
        {
            NSLog(@"warning: device can't be null.");
            return nil;
        }
        self.device = device;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.title = @"净水机";
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"icon_menu"] style:UIBarButtonItemStylePlain target:[SlideNavigationController sharedInstance] action:@selector(toggleLeftMenu)];
    
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    //设置委托
    self.device.delegate = self;
    [XPGWifiSDK sharedInstance].delegate = self;
    
    //设备已解除绑定，或者断开连接，退出
    if(![self.device isBind:[IoTProcessModel sharedModel].currentUid] || !self.device.isConnected)
    {
        [self onDisconnected];
        return;
    }
    
    //更新侧边菜单数据
    [((IoTMainMenu *)[SlideNavigationController sharedInstance].leftMenu).tableView reloadData];
    
    //在页面加载后，自动更新数据
    if(self.device.isOnline)
    {
        IoTAppDelegate.hud.labelText = @"正在更新数据...";
        [IoTAppDelegate.hud showAnimated:YES whileExecutingBlock:^{
            sleep(61);
        }];
        [self writeDataPoint:IoTDeviceWriteUpdateData value:nil];
    }
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self initDevice];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    if([self.navigationController.viewControllers indexOfObject:self] > self.navigationController.viewControllers.count)
    {
        self.device.delegate = nil;
    }
    [XPGWifiSDK sharedInstance].delegate = nil;
    [_alertView hide:YES];
    [cAlertView dismissWithClickedButtonIndex:0 animated:NO];
}

- (void)initDevice{
    //加载页面时
    [[IoTRecord sharedInstance] clearAllRecord];
    [self onUpdateAlarm];
    
    bSwitch       = 0;
    iMode         = -1;
    
    [self selectMode:iMode sendToDevice:NO];
    
    self.viewFault.hidden = YES;
    self.resetView.hidden = YES;
    
    self.device.delegate = self;
    
}

- (void)setDevice:(XPGWifiDevice *)device
{
    _device.delegate = nil;
    _device = device;
    [self initDevice];
}

#pragma mark - SDK delegate
- (void)writeDataPoint:(IoTDeviceDataPoint)dataPoint value:(id)value{
    
    NSDictionary *data = nil;
    
    switch (dataPoint)
    {
        case IoTDeviceWriteUpdateData:
            data = @{DATA_CMD: @(IoTDeviceCommandRead)};
            break;
        case IoTDeviceWriteOnOff:
            data = @{DATA_CMD: @(IoTDeviceCommandWrite),
                     DATA_ENTITY: @{DATA_ATTR_SWITCH: value}};
            break;
        case IoTDeviceWriteMode:
            data = @{DATA_CMD: @(IoTDeviceCommandWrite),
                     DATA_ENTITY: @{DATA_ATTR_MODE: value}};
            break;
        case IoTDeviceWriteFilter_1_Life:
            data = @{DATA_CMD: @(IoTDeviceCommandWrite),
                     DATA_ENTITY: @{DATA_ATTR_FILTER_1_LIFE: value}};
            break;
        case IoTDeviceWriteFilter_2_Life:
            data = @{DATA_CMD: @(IoTDeviceCommandWrite),
                     DATA_ENTITY: @{DATA_ATTR_FILTER_2_LIFE: value}};
            break;
        case IoTDeviceWriteFilter_3_Life:
            data = @{DATA_CMD: @(IoTDeviceCommandWrite),
                     DATA_ENTITY: @{DATA_ATTR_FILTER_3_LIFE: value}};
            break;
        case IoTDeviceWriteFilter_4_Life:
            data = @{DATA_CMD:@(IoTDeviceCommandWrite),
                     DATA_ENTITY: @{DATA_ATTR_FILTER_4_LIFE: value}};
            break;
        case IoTDeviceWriteFilter_5_Life:
            data = @{DATA_CMD:@(IoTDeviceCommandWrite),
                     DATA_ENTITY: @{DATA_ATTR_FILTER_5_LIFE: value}};
            break;
        case IoTDeviceWriterDevice_fault:
            data = @{DATA_CMD:@(IoTDeviceCommandWrite),
                     DATA_ENTITY: @{DATA_ATTR_DEVICE_FAULT: value}};
        default:
            NSLog(@"Error: write invalid datapoint, skip.");
            return;
    }
    NSLog(@"Write data: %@", data);
    [self.device write:data];
}

- (id)readDataPoint:(IoTDeviceDataPoint)dataPoint data:(NSDictionary *)data
{
    if(![data isKindOfClass:[NSDictionary class]])
    {
        NSLog(@"Error: could not read data, error data format.");
        return nil;
    }
    
    NSNumber *nCommand = [data valueForKey:DATA_CMD];
    if(![nCommand isKindOfClass:[NSNumber class]])
    {
        NSLog(@"Error: could not read cmd, error cmd format.");
        return nil;
    }
    
    int nCmd = [nCommand intValue];
    if(nCmd != IoTDeviceCommandResponse && nCmd != IoTDeviceCommandNotify)
    {
        NSLog(@"Error: command is invalid, skip.");
        return nil;
    }
    
    NSDictionary *attributes = [data valueForKey:DATA_ENTITY];
    if(![attributes isKindOfClass:[NSDictionary class]])
    {
        NSLog(@"Error: could not read attributes, error attributes format.");
        return nil;
    }
    
    switch (dataPoint)
    {
        case IoTDeviceWriteOnOff:
            return [attributes valueForKey:DATA_ATTR_SWITCH];
        case IoTDeviceWriteMode:
            return [attributes valueForKey:DATA_ATTR_MODE];
        case IoTDeviceWriteFilter_1_Life:
            return [attributes valueForKey:DATA_ATTR_FILTER_1_LIFE];
        case IoTDeviceWriteFilter_2_Life:
            return [attributes valueForKey:DATA_ATTR_FILTER_2_LIFE];
        case IoTDeviceWriteFilter_3_Life:
            return [attributes valueForKey:DATA_ATTR_FILTER_3_LIFE];
        case IoTDeviceWriteFilter_4_Life:
            return [attributes valueForKey:DATA_ATTR_FILTER_4_LIFE];
        case IoTDeviceWriteFilter_5_Life:
            return [attributes valueForKey:DATA_ATTR_FILTER_5_LIFE];
        case IoTDeviceWriterDevice_fault:
            return [attributes valueForKey:DATA_ATTR_DEVICE_FAULT];
        default:
            NSLog(@"Error: read invalid datapoint, skip.");
            break;
    }
    return nil;
}

- (CGFloat)prepareForUpdateFloat:(NSString *)str value:(CGFloat)value
{
    if([str isKindOfClass:[NSNumber class]] ||
       ([str isKindOfClass:[NSString class]] && str.length > 0))
    {
        CGFloat newValue = [str floatValue];
        if(newValue != value)
        {
            value = newValue;
        }
    }
    return value;
}

- (NSInteger)prepareForUpdateInteger:(NSString *)str value:(NSInteger)value
{
    if([str isKindOfClass:[NSNumber class]] ||
       ([str isKindOfClass:[NSString class]] && str.length > 0))
    {
        NSInteger newValue = [str integerValue];
        if(newValue != value)
        {
            value = newValue;
        }
    }
    return value;
}

#pragma mark - Actions
-(void)setRightBarButtonItem{
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"icon_start"] style:UIBarButtonItemStylePlain target:self action:@selector(onPower)];
}

- (void)onDisconnected {
    //断线且页面在控制页面时才弹框
    UIViewController *currentController = self.navigationController.viewControllers.lastObject;
    
    if(!self.device.isConnected &&
       [currentController isKindOfClass:[IoTMainController class]])
    {
        [IoTAppDelegate.hud hide:YES];
        [_alertView hide:YES];
        [[[IoTAlertView alloc] initWithMessage:@"连接已断开" delegate:nil titleOK:@"确定"] show:YES];
        [self onExitToDeviceList];
    }
}

//退出到列表
- (void)onExitToDeviceList{
    UIViewController *currentController = self.navigationController.viewControllers.lastObject;
    for(int i=(int)(self.navigationController.viewControllers.count-1); i>0; i--)
    {
        UIViewController *controller = self.navigationController.viewControllers[i];
        if(([controller isKindOfClass:[IoTDeviceList class]] && [currentController isKindOfClass:[IoTMainController class]]))
        {
            [self.navigationController popToViewController:controller animated:YES];
        }
    }
}

- (void)onPower {
    //不在线就不能点
    if(!self.device.isOnline)
        return;
    
    if(bSwitch)
    {
        //关机
        cAlertView = [[UIAlertView alloc] initWithTitle:@"提示" message:@"是否确定关机？" delegate:self cancelButtonTitle:@"确定" otherButtonTitles:@"取消", nil];
        cAlertView.tag = ALERT_TAG_SHUTDOWN;
        [cAlertView show];
    }
    else
    {
        self.shutDownView.hidden = NO;
        self.navigationItem.rightBarButtonItem = nil;
    }
}

//开关
- (IBAction)onShutDown:(id)sender {
    [self writeDataPoint:IoTDeviceWriteOnOff value:@1];
    [self writeDataPoint:IoTDeviceWriteUpdateData value:nil];
    self.shutDownView.hidden = YES;
    [self setRightBarButtonItem];
}
//滤芯冲洗
- (IBAction)onCleanWater:(id)sender {
    if (iMode != 1) {
        [self selectMode:1 sendToDevice:YES];
    }
    [self writeDataPoint:IoTDeviceWriteUpdateData value:nil];
}
//净水
- (IBAction)onFilterFlush:(id)sender {
    if (iMode != 2) {
        [self selectMode:2 sendToDevice:YES];
    }
    [self writeDataPoint:IoTDeviceWriteUpdateData value:nil];
}
//模式
- (void)selectMode:(NSInteger)index sendToDevice:(BOOL)send
{
    if (nil == self.btnShutDown) {
        return;
    }
    
    NSArray *btnItems = @[self.btnShutDown, self.btnFilterFlush, self.btnCleanWater];
    
    //模式：滤芯冲洗，开始净水，就只能选择其中的一种
    if(index >= -1 && index <= 2)
    {
        iMode = index;
        for(int i=0; i<(btnItems.count); i++)
        {
            BOOL bSelected = (index == i);
            ((UIButton *)btnItems[i]).selected = bSelected;
            if (iMode == 0) {
                self.btnShutDown.selected = NO;
            }
        }
        if (index == 1) {
            self.textDevice.text = @"正在冲洗中";
            self.textDevice.textColor = [UIColor colorWithRed:0.34 green:0.70 blue:0.85 alpha:1.0];
            self.btnReset.selected = YES;
            self.btnReset.userInteractionEnabled = NO;
        }else if (index ==2){
            self.textDevice.text = @"正在净水中";
            self.textDevice.textColor = [UIColor colorWithRed:0.34 green:0.70 blue:0.85 alpha:1.0];
            self.btnReset.selected = YES;
            self.btnReset.userInteractionEnabled = NO;
        }else if (index == 0){
            self.textDevice.text = @"运行良好";
            self.textDevice.textColor = [UIColor blackColor];
            self.btnReset.selected = NO;
            self.btnReset.userInteractionEnabled = YES;
        }
        //发送数据
        if(send && index != -1)
            [self writeDataPoint:IoTDeviceWriteMode value:@(iMode)];
    }
}

- (IBAction)onFilter:(id)sender {
    UIButton *btn = sender;
    
    self.btnReset.tag = btn.tag;
    
    self.resetView.hidden = NO;
    
    [self setFilterStatus:btn.tag];
}

-(void)setFilterStatus:(NSInteger)index{
    
    switch (index) {
        case 0:
            self.textFilterName.text = @"PP棉";
            float value = ((float)iFilter1/2880)*100;
            [self setFilterValue:value andButton:self.btnFilter1 andFilter:iFilter1];
            break;
        case 1:
            self.textFilterName.text = @"活性炭GAC";
            float value1 = ((float)iFilter2/8640)*100;
            [self setFilterValue:value1 andButton:self.btnFilter2 andFilter:iFilter2];
            break;
        case 2:
            self.textFilterName.text = @"活性炭CTO";
            float value2 = ((float)iFilter3/8640)*100;
            [self setFilterValue:value2 andButton:self.btnFilter3 andFilter:iFilter3];
            break;
        case 3:
            self.textFilterName.text = @"RO膜";
            float value3 = ((float)iFilter4/17280)*100;
            [self setFilterValue:value3 andButton:self.btnFilter4 andFilter:iFilter4];
            break;
        case 4:
            self.textFilterName.text = @"活性炭T33";
            float value4 = ((float)iFilter5/8640)*100;
            [self setFilterValue:value4 andButton:self.btnFilter5 andFilter:iFilter5];
            break;
    }
    NSArray * array = @[self.btnFilter1,self.btnFilter2,self.btnFilter3,self.btnFilter4,self.btnFilter5];
    [self setFilterStatusValue:array];
}
//遍历每个滤芯的状态
-(void)setFilterStatusValue:(NSArray*)array{
    BOOL setSelected = NO;
    for (UIButton * button in array) {
        if ((button.selected == YES)) {
            setSelected = YES;;
        }
    }
    if (setSelected == YES) {
        self.textFilterStatus2.text = @"需要更换";
        self.textFilterStatus2.textColor = [UIColor redColor];
    }else{
        self.textFilterStatus2.text = @"运行良好";
        self.textFilterStatus2.textColor = [UIColor blackColor];
    }
}

-(void)setFilterValue:(float)value andButton:(UIButton*)button andFilter:(NSInteger)index{
    
    self.textFilterLift.text = [NSString stringWithFormat:@"%@小时",@(index)];
    self.textFilterValue.text = [NSString stringWithFormat:@"%ld%@",(long)value,@"%"];
    
    if (value < 11) {
        button.selected = YES;
        self.textFilterStatus.text = @"需要更换";
        self.textFilterStatus.textColor = [UIColor redColor];
    }else if (value >= 11){
        button.selected = NO;
        self.textFilterStatus.text = @"正常";
        self.textFilterStatus.textColor = [UIColor blackColor];
    }
}
//复位按钮
- (IBAction)onReset:(id)sender {
    //复位取滤芯数据点的最大值
    if (self.btnReset.tag == 0) {
        [self writeDataPoint:IoTDeviceWriteFilter_1_Life value:@(2880)];
    }else if (self.btnReset.tag ==1){
        [self writeDataPoint:IoTDeviceWriteFilter_2_Life value:@(8640)];
    }else if (self.btnReset.tag ==2){
        [self writeDataPoint:IoTDeviceWriteFilter_3_Life value:@(8640)];
    }else if (self.btnReset.tag ==3){
        [self writeDataPoint:IoTDeviceWriteFilter_4_Life value:@(17280)];
    }else if (self.btnReset.tag ==4){
        [self writeDataPoint:IoTDeviceWriteFilter_5_Life value:@(8640)];
    }
    [self writeDataPoint:IoTDeviceWriteUpdateData value:nil];
}

-(void)selectFilterStatus:(NSInteger)index Tag:(NSInteger)tag{
    if (tag == 0) {
        [self writeDataPoint:IoTDeviceWriteFilter_1_Life value:@(index)];
    }else if (tag == 1){
        [self writeDataPoint:IoTDeviceWriteFilter_2_Life value:@(index)];
    }else if (tag == 2){
        [self writeDataPoint:IoTDeviceWriteFilter_3_Life value:@(index)];
    }else if (tag == 3){
        [self writeDataPoint:IoTDeviceWriteFilter_4_Life value:@(index)];
    }else if (tag == 4){
        [self writeDataPoint:IoTDeviceWriteFilter_5_Life value:@(index)];
    }
    [self setFilterStatus:tag];
}

- (IBAction)onCancel:(id)sender {
    self.resetView.hidden = YES;
}

//警报
- (void)onUpdateAlarm {
    
    //故障条目数，原则上不大于65535
    NSInteger count = [IoTRecord sharedInstance].recordedCount;
    if(count > 65535)
        count = 65535;
    //故障条数目
    if(count > 0)
    {
        //弹出报警提示
        self.viewFault.hidden = NO;
        self.textDevice.text = @"设备故障";
        self.textDevice.textColor = [UIColor orangeColor];
    }else{
        self.viewFault.hidden = YES;
    }
}
//联系客服
- (IBAction)onCall:(id)sender {
    [IoTAppDelegate callServices];
}

#pragma mark - AlerView methods
- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if(alertView.tag == 1 && buttonIndex == 0)
    {
        IoTAppDelegate.hud.labelText = @"正在关机...";
        [IoTAppDelegate.hud showAnimated:YES whileExecutingBlock:^{
            sleep(61);
        }];
        [self writeDataPoint:IoTDeviceWriteOnOff value:@0];
        [self writeDataPoint:IoTDeviceWriteUpdateData value:nil];
        
        self.shutDownView.hidden = NO;
        self.navigationItem.rightBarButtonItem = nil;
    }
}

#pragma mark - Common methods
+ (IoTMainController *)currentController
{
    SlideNavigationController *navCtrl = [SlideNavigationController sharedInstance];
    for(int i=(int)(navCtrl.viewControllers.count-1); i>0; i--)
    {
        if([navCtrl.viewControllers[i] isKindOfClass:[IoTMainController class]])
            return navCtrl.viewControllers[i];
    }
    return nil;
}

#pragma mark - XPGWifiSDK delegate
- (void)XPGWifiSDK:(XPGWifiSDK *)wifiSDK didUnbindDevice:(NSString *)did error:(NSNumber *)error errorMessage:(NSString *)errorMessage
{
    //解绑事件
    if([error intValue] == XPGWifiError_NONE)
    {
        [[[UIAlertView alloc] initWithTitle:@"提示" message:@"解除绑定成功" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil] show];
        [self.navigationController popViewControllerAnimated:YES];
    }
}

- (void)XPGWifiDeviceDidDisconnected:(XPGWifiDevice *)device
{
    if(![device.did isEqualToString:self.device.did] || self.device.isConnected)
        return;
    [self onDisconnected];
}

//数据入口
- (BOOL)XPGWifiDevice:(XPGWifiDevice *)device didReceiveData:(NSDictionary *)data result:(int)result{
    
    if(![device.did isEqualToString:self.device.did])
        return YES;
    
    [IoTAppDelegate.hud hide:YES];
    /**
     * 数据部分
     */
    NSDictionary *_data = [data valueForKey:@"data"];
    if(nil != _data)
    {
        NSString *onOff             = [self readDataPoint:IoTDeviceWriteOnOff data:_data];
        NSString *Mode              = [self readDataPoint:(IoTDeviceWriteMode) data:_data];
        NSString *Filter1           = [self readDataPoint:IoTDeviceWriteFilter_1_Life data:_data];
        NSString *Filter2           = [self readDataPoint:IoTDeviceWriteFilter_2_Life data:_data];
        NSString *Filter3           = [self readDataPoint:IoTDeviceWriteFilter_3_Life data:_data];
        NSString *Filter4           = [self readDataPoint:IoTDeviceWriteFilter_4_Life data:_data];
        NSString *Filter5           = [self readDataPoint:IoTDeviceWriteFilter_5_Life data:_data];
        NSString *Fault             = [self readDataPoint:IoTDeviceWriterDevice_fault data:_data];
        
        bSwitch                     = [self prepareForUpdateFloat:onOff value:bSwitch];
        iMode                       = [self prepareForUpdateFloat:Mode value:iMode];
        iFilter1                    = [self prepareForUpdateFloat:Filter1 value:iFilter1];
        iFilter2                    = [self prepareForUpdateFloat:Filter2 value:iFilter2];
        iFilter3                    = [self prepareForUpdateFloat:Filter3 value:iFilter3];
        iFilter4                    = [self prepareForUpdateFloat:Filter4 value:iFilter4];
        iFilter5                    = [self prepareForUpdateFloat:Filter5 value:iFilter5];
        bFault                      = [self prepareForUpdateFloat:Fault value:bFault];
        
        /**
         * 更新到 UI
         */
        self.shutDownView.hidden = bSwitch;
        [self selectMode:iMode sendToDevice:NO];
        [self setRightBarButtonItem];
        
        [self selectFilterStatus:iFilter1 Tag:0];
        [self selectFilterStatus:iFilter2 Tag:1];
        [self selectFilterStatus:iFilter3 Tag:2];
        [self selectFilterStatus:iFilter4 Tag:3];
        [self selectFilterStatus:iFilter5 Tag:4];
        
        if (self.btnReset.tag == 0) {
            [self selectFilterStatus:iFilter1 Tag:0];
        }else if (self.btnReset.tag == 1){
            [self selectFilterStatus:iFilter2 Tag:1];
        }else if (self.btnReset.tag == 2){
            [self selectFilterStatus:iFilter3 Tag:2];
        }else if (self.btnReset.tag == 3){
            [self selectFilterStatus:iFilter4 Tag:3];
        }else if (self.btnReset.tag == 4){
            [self selectFilterStatus:iFilter5 Tag:4];
        }
        
        //没有开机，切换页面
        if(!bSwitch)
        {
            [self onPower];
            [cAlertView dismissWithClickedButtonIndex:0 animated:NO];
            return YES;
        }
    }
    /**
     * 报警和错误
     */
    if([self.navigationController.viewControllers lastObject] != self)
        return YES;
    
    self.faults = [data valueForKey:@"faults"];
    
    /**
     * 清理旧报警及故障
     */
    [[IoTRecord sharedInstance] clearAllRecord];
    
    if(self.faults.count == 0)
    {
        [self onUpdateAlarm];
        return YES;
    }
    
    /**
     * 添加当前故障
     */
    
    NSDate *date = [NSDate date];
    
    if(self.faults.count > 0)
    {
        for(NSDictionary *dict in self.faults)
        {
            for(NSString *name in dict.allKeys)
            {
                [[IoTRecord sharedInstance] addRecord:date information:name];
            }
        }
    }
    [self onUpdateAlarm];
    
    return YES;
}

@end
