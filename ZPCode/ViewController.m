//
//  ViewController.m
//  ZPCode
//
//  Created by xinzhipeng on 2017/9/8.
//  Copyright © 2017年 apple. All rights reserved.
//

#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "ZPShadowView.h"

#define screenW [UIScreen mainScreen].bounds.size.width
#define screenH [UIScreen mainScreen].bounds.size.height
#define scanSize CGSizeMake(250, 250)
@interface ViewController ()<AVCaptureMetadataOutputObjectsDelegate, UINavigationControllerDelegate, UIImagePickerControllerDelegate>

/*输入数据源*/
@property (strong, nonatomic) AVCaptureDeviceInput *input;
/*输出数据源*/
@property (strong, nonatomic) AVCaptureMetadataOutput *output;
/*输入输出的中间桥梁 负责把捕获的音视频数据输出到输出设备中*/
@property (strong, nonatomic) AVCaptureSession *session;
/*相机拍摄预览图层*/
@property (weak, nonatomic) AVCaptureVideoPreviewLayer *previewLayer;
/** 预览图层尺寸 */
@property (nonatomic, assign) CGSize layerViewSize;
/** 有效扫码范围 */
//@property (nonatomic, assign) CGSize showSize;
/** 自定义的View视图 */
@property (nonatomic, weak) ZPShadowView *shadowView;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self creatScanQR];
    [self.session startRunning];
    //添加上层阴影视图
    ZPShadowView *shadowView = [[ZPShadowView alloc] initWithFrame:CGRectMake(0, 64, screenW, screenH - 64)];
    [self.view addSubview:shadowView];
    self.shadowView = shadowView;
    self.shadowView.showSize = scanSize;
    self.layerViewSize = CGSizeMake(screenW, screenH - 64);
    [self allowScanRect];
    
    //添加扫码相册按钮
    UIButton *photoBtn = [[UIButton alloc] initWithFrame:CGRectMake(100, 20, 80, 40)];
    [self.view addSubview:photoBtn];
    [photoBtn setTitle:@"相册选中" forState:UIControlStateNormal];
    [photoBtn setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
    [photoBtn addTarget:self action:@selector(takeQRCodeFromPic:) forControlEvents:UIControlEventTouchUpInside];
    photoBtn.layer.borderColor = [UIColor redColor].CGColor;
    photoBtn.layer.borderWidth = 1.0f;
}

- (void)creatScanQR {
    /** 创建输入数据源 */
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    NSError *error;
    self.input = [AVCaptureDeviceInput deviceInputWithDevice:device error:&error];
    
    /** 创建输出数据源 */
    self.output = [[AVCaptureMetadataOutput alloc] init];
    [self.output setMetadataObjectsDelegate:self queue:dispatch_get_main_queue()]; //设置代理 在主线程里刷新
    
    /* 会话设置 */
    self.session = [[AVCaptureSession alloc] init];
    if ([self.session canSetSessionPreset:AVCaptureSessionPreset1920x1080]) {
        [self.session setSessionPreset:AVCaptureSessionPreset1920x1080];//除了iphone 4 ,其他都支持.
    } else {
        [self.session setSessionPreset:AVCaptureSessionPresetHigh];//高质量采集
    }
    [self.session addInput:self.input];
    [self.session addOutput:self.output];
    /*
     AVMetadataObjectTypeQRCode, 这个就是我们常用的二维码了  开发中主要用的这个 (格式多了会扫描边慢,开发中用这个一般就够了)
     AVMetadataObjectTypeEAN13Code, 我国商品码主要就是这和 EAN8
     AVMetadataObjectTypeEAN8Code,
     AVMetadataObjectTypeCode128Code 这个可能也是升级版 更牛逼点虽然不知道原理，推测肯定牛逼
     */
    //设置扫码支持的格式
    self.output.metadataObjectTypes = @[
                                        AVMetadataObjectTypeQRCode,
                                        AVMetadataObjectTypeEAN13Code,
                                        AVMetadataObjectTypeEAN8Code,
                                        AVMetadataObjectTypeCode128Code
                                        ];
    /** 扫码视图 */
    //扫描框的位置和大小
    self.previewLayer = [AVCaptureVideoPreviewLayer layerWithSession:self.session];
    /*
     AVLayerVideoGravityResizeAspect  保持纵横比；适合层范围内
     AVLayerVideoGravityResizeAspectFill  保持纵横比；填充层边界
     AVLayerVideoGravityResize  拉伸填充层边界
     */
    self.previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    self.previewLayer.frame = CGRectMake(0, 64, self.view.frame.size.width, self.view.frame.size.height - 64);
    [self.view.layer addSublayer:self.previewLayer];
}

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection{
    NSMutableArray *resultStr = [NSMutableArray array];
    if (metadataObjects.count > 0) {
        [self.session stopRunning];
        for (AVMetadataMachineReadableCodeObject *obj in metadataObjects) {
            [resultStr addObject:obj.stringValue];
        }
        [self alertShowWithTitle:@"扫描结果:" message:[NSString stringWithFormat:@"%@",resultStr[0]] actionTitle:@"确定"];
    }
}

/** 配置扫码范围 */
-(void)allowScanRect{
    //看到矩形的原点是左上角, 但是真正测试 你会发现却是在右上角, 因为扫码默认是 横屏, 所以原右上角变成左上角, 原宽变成高, 原高变成宽. 取值是按照 摄像头分辨率 来取的比例 而不是屏幕的宽高比例.
    /** 扫描是默认是横屏, 原点在[右上角]
     *  rectOfInterest = CGRectMake(0, 0, 1, 1);
     *  AVCaptureSessionPresetHigh = 1920×1080   摄像头分辨率
     *  需要转换坐标 将屏幕与 分辨率统一
     */
    
    //剪切出需要的大小位置
    CGRect shearRect = CGRectMake((self.layerViewSize.width - self.shadowView.showSize.width) / 2,
                                  (self.layerViewSize.height - self.shadowView.showSize.height) / 2,
                                  self.shadowView.showSize.height,
                                  self.shadowView.showSize.height);
    
    
    CGFloat deviceProportion = 1920.0 / 1080.0;
    CGFloat screenProportion = self.layerViewSize.height / self.layerViewSize.width;
    
    
    NSLog(@"%f - %f",deviceProportion,screenProportion);
    //分辨率比> 屏幕比 ( 相当于屏幕的高不够)
    if (deviceProportion > screenProportion) {
        //换算出 分辨率比 对应的 屏幕高
        CGFloat finalHeight = self.layerViewSize.width * deviceProportion;
        // 得到 偏差值
        CGFloat addNum = (finalHeight - self.layerViewSize.height) / 2;
        // (对应的实际位置 + 偏差值)  /  换算后的屏幕高
        self.output.rectOfInterest = CGRectMake((shearRect.origin.y + addNum) / finalHeight,
                                                shearRect.origin.x / self.layerViewSize.width,
                                                shearRect.size.height/ finalHeight,
                                                shearRect.size.width/ self.layerViewSize.width);
    }else{
        CGFloat finalWidth = self.layerViewSize.height / deviceProportion;
        CGFloat addNum = (finalWidth - self.layerViewSize.width) / 2;
        self.output.rectOfInterest = CGRectMake(shearRect.origin.y / self.layerViewSize.height,
                                                (shearRect.origin.x + addNum) / finalWidth,
                                                shearRect.size.height / self.layerViewSize.height,
                                                shearRect.size.width / finalWidth);
    }
    
}
#pragma mark - 相册中读取二维码
/* navi按钮实现 */
-(void)takeQRCodeFromPic:(UIButton *)leftBar{
    
    
    
    if ([[[UIDevice currentDevice] systemVersion] doubleValue] < 8) {
        [self alertShowWithTitle:@"提示" message:@"请更新系统至8.0以上!" actionTitle:@"确定"];
    }else{
        if([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary]){
            UIImagePickerController *pickerC = [[UIImagePickerController alloc] init];
            pickerC.delegate = self;
            pickerC.sourceType = UIImagePickerControllerSourceTypeSavedPhotosAlbum;  //来自相册
            [self presentViewController:pickerC animated:YES completion:NULL];
        }else{
            [self alertShowWithTitle:@"提示" message:@"设备不支持访问相册,请在设置->隐私->照片中进行设置" actionTitle:@"确定"];
        }
    }
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    //1.获取选择的图片
    UIImage *image = info[UIImagePickerControllerEditedImage];
    if (!image) {
        image = info[UIImagePickerControllerOriginalImage];
    }
    //2.初始化一个监测器
    CIDetector*detector = [CIDetector detectorOfType:CIDetectorTypeQRCode context:nil options:@{ CIDetectorAccuracy : CIDetectorAccuracyHigh }];
    [picker dismissViewControllerAnimated:YES completion:^{
        //监测到的结果数组  放置识别完之后的数据
        NSArray *features = [detector featuresInImage:[CIImage imageWithCGImage:image.CGImage]];
        //判断是否有数据（即是否是二维码）
        if (features.count >= 1) {
            /**结果对象 */
            CIQRCodeFeature *feature = [features objectAtIndex:0];
            NSString *scannedResult = feature.messageString;
            [self alertShowWithTitle:@"提示" message:scannedResult actionTitle:@"确定"];
        }
        else{
            [self alertShowWithTitle:@"提示" message:@"该图片没有包含二维码" actionTitle:@"确定"];
        }
    }];
}
- (void) alertShowWithTitle: (NSString *)title message: (NSString *)message actionTitle: (NSString *)actionTitle{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *sure = [UIAlertAction actionWithTitle:actionTitle style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        
    }];
    [alert addAction:sure];
    [self presentViewController:alert animated:YES completion:nil];
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}


@end








