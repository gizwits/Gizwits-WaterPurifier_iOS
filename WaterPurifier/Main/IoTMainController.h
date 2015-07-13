/**
 * IoTMainController.h
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

#import <UIKit/UIKit.h>

typedef enum
{
    // writable
    IoTDeviceWriteUpdateData = 0,           //更新数据
    IoTDeviceWriteOnOff,                    //开关
    IoTDeviceWriteMode,                     //选择模式
    IoTDeviceWriteFilter_1_Life,            //滤芯1寿命
    IoTDeviceWriteFilter_2_Life,            //滤芯2寿命
    IoTDeviceWriteFilter_3_Life,            //滤芯3寿命
    IoTDeviceWriteFilter_4_Life,            //滤芯4寿命
    IoTDeviceWriteFilter_5_Life,            //滤芯5寿命
    
    //fault
    IoTDeviceWriterDevice_fault,            //故障信息
    
}IoTDeviceDataPoint;

typedef enum
{
    IoTDeviceCommandWrite    = 1,//写
    IoTDeviceCommandRead     = 2,//读
    IoTDeviceCommandResponse = 3,//读响应
    IoTDeviceCommandNotify   = 4,//通知
}IoTDeviceCommand;

#define DATA_CMD                        @"cmd"                  //命令
#define DATA_ENTITY                     @"entity0"              //实体
#define DATA_ATTR_SWITCH                @"Switch"               //属性：开关
#define DATA_ATTR_MODE                  @"Mode"                 //选择模式
#define DATA_ATTR_FILTER_1_LIFE         @"Filter_1_Life"        //滤芯1寿命
#define DATA_ATTR_FILTER_2_LIFE         @"Filter_2_Life"        //滤芯2寿命
#define DATA_ATTR_FILTER_3_LIFE         @"Filter_3_Life"        //滤芯3寿命
#define DATA_ATTR_FILTER_4_LIFE         @"Filter_4_Life"        //滤芯4寿命
#define DATA_ATTR_FILTER_5_LIFE         @"Filter_5_Life"        //滤芯5寿命
#define DATA_ATTR_DEVICE_FAULT          @"Device_Fault"         //故障信息

@interface IoTMainController : UIViewController

//用于切换设备
@property (nonatomic, strong) XPGWifiDevice *device;

//写入数据接口
- (void)writeDataPoint:(IoTDeviceDataPoint)dataPoint value:(id)value;

- (id)initWithDevice:(XPGWifiDevice *)device;

//获取当前实例
+ (IoTMainController *)currentController;

@end
