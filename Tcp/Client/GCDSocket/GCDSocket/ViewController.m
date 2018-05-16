//
//  ViewController.m
//  GCDSocket
//
//  Created by 柴栓柱 on 2018/5/15.
//  Copyright © 2018年 柴栓柱. All rights reserved.
//

#import "ViewController.h"
#import <GCDAsyncSocket.h>

@interface ViewController ()<GCDAsyncSocketDelegate>
// 客户端socket
@property (strong, nonatomic) GCDAsyncSocket *clientSocket;

@property (strong, nonatomic) NSTimer *connectTimer;

@property (assign, nonatomic) BOOL connected;
@property (weak, nonatomic) IBOutlet UITextField *addressTF;
@property (weak, nonatomic) IBOutlet UITextField *portTF;
@property (weak, nonatomic) IBOutlet UITextField *messageTF;

- (IBAction)Connect:(UIButton *)sender;
- (IBAction)close:(UIButton *)sender;

@property (weak, nonatomic) IBOutlet UITextView *txtView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (IBAction)Connect:(UIButton *)sender {
    
    // 创建socket并指定代理对象为self,代理队列必须为主队列.
    self.clientSocket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
    // 连接指定主机的对应端口.
    NSError *error = nil;
    self.connected = [self.clientSocket connectToHost:self.addressTF.text onPort:[self.portTF.text integerValue] viaInterface:nil withTimeout:-1 error:&error];
}

- (IBAction)close:(UIButton *)sender {
    self.clientSocket.delegate = nil;
    self.clientSocket = nil;
    self.connected = NO;
    [self.connectTimer invalidate];
}

// 发送数据
- (IBAction)sendMessageAction:(id)sender {
    NSData *data = [self.messageTF.text dataUsingEncoding:NSUTF8StringEncoding];
    // withTimeout -1 : 无穷大,一直等
    // tag : 消息标记
    [self.clientSocket writeData:data withTimeout:- 1 tag:0];
}

//成功连接主机对应端口号.
- (void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(uint16_t)port {
    
    //    NSLog(@"连接主机对应端口%@", sock);
    //    [self showMessageWithStr:@"链接成功"];
    //    [self showMessageWithStr:[NSString stringWithFormat:@"服务器IP: %@-------端口: %d", host,port]];
    NSLog(@"链接成功");
    NSLog(@"服务器IP: %@-------端口: %d", host,port);
    
    // 连接成功开启定时器
    [self addTimer];
    // 连接后,可读取服务端的数据
    [self.clientSocket readDataWithTimeout:- 1 tag:0];
    self.connected = YES;
}

/**
 读取数据
 
 @param sock 客户端socket
 @param data 读取到的数据
 @param tag 本次读取的标记
 */
- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag {
    NSString *text = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
//    [self showMessageWithStr:text];
    NSLog(@"%@",text);
    
    self.txtView.text = [NSString stringWithFormat:@"%@\n%@", _txtView.text, text];
    [self.txtView scrollRangeToVisible:NSMakeRange(0, _txtView.text.length)];
    // 读取到服务端数据值后,能再次读取
    [self.clientSocket readDataWithTimeout:- 1 tag:0];
}

/**
 客户端socket断开
 
 @param sock 客户端socket
 @param err 错误描述
 */
- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err {
//    [self showMessageWithStr:@"断开连接"];
    NSLog(@"断开连接");
    self.clientSocket.delegate = nil;
    self.clientSocket = nil;
    self.connected = NO;
    [self.connectTimer invalidate];
}

//建立心跳连接.

// 添加定时器
- (void)addTimer {
    // 长连接定时器
    self.connectTimer = [NSTimer scheduledTimerWithTimeInterval:5.0 target:self selector:@selector(longConnectToSocket) userInfo:nil repeats:YES];
    // 把定时器添加到当前运行循环,并且调为通用模式
    [[NSRunLoop currentRunLoop] addTimer:self.connectTimer forMode:NSRunLoopCommonModes];
}

// 心跳连接
- (void)longConnectToSocket {
    // 发送固定格式的数据,指令@"longConnect"
    float version = [[UIDevice currentDevice] systemVersion].floatValue;
    NSString *longConnect = [NSString stringWithFormat:@"123%f",version];
    
    NSData  *data = [longConnect dataUsingEncoding:NSUTF8StringEncoding];
    
    [self.clientSocket writeData:data withTimeout:- 1 tag:0];
}

///**
// 处理数据粘包
// 
// @param readData 读取到的数据
// */
//- (void)dealStickPackageWithData:(NSString *)readData
//{
//    // 缓冲池还需要存储的数据个数
//    NSInteger tempCount;
//    
//    if (readData.length > 0)
//    {
//        // 还差tempLength个数填满缓冲池
//        tempCount = 4 - self.tempData.length;
//        if (readData.length <= tempCount)
//        {
//            self.tempData = [self.tempData stringByAppendingString:readData];
//            
//            if (self.tempData.length == 4)
//            {
//                [self.mutArr addObject:self.tempData];
//                self.tempData = @"";
//            }
//        }
//        else
//        {
//            // 下一次的数据个数比要填满缓冲池的数据个数多,一定能拼接成完整数据,剩余的继续
//            self.tempData = [self.tempData stringByAppendingString:[readData substringToIndex:tempCount]];
//            [self.mutArr addObject:self.tempData];
//            self.tempData = @"";
//            
//            // 多余的再执行一次方法
//            [self dealStickPackageWithData:[readData substringFromIndex:tempCount]];
//        }
//    }
//}


@end
