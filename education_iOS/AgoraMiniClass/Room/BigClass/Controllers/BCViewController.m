//
//  BigClassViewController.m
//  AgoraMiniClass
//
//  Created by yangmoumou on 2019/10/22.
//  Copyright © 2019 yangmoumou. All rights reserved.
//

#import "BCViewController.h"
#import "EESegmentedView.h"
#import "EEPageControlView.h"
#import "EEChatContentTableView.h"
#import "EEWhiteboardTool.h"
#import "EEChatTextFiled.h"
#import "EEStudentVideoView.h"
#import <WhiteSDK.h>
#import "AgoraHttpRequest.h"
#import "MainViewController.h"
#import "EEPublicMethodsManager.h"
#import "RoomMessageModel.h"
#import "EEColorShowView.h"
#import "EEPublicMethodsManager.h"
#import "EEBCStudentAttrs.h"
#import "EEBCTeactherAttrs.h"


@interface BCViewController ()<EESegmentedDelegate,EEWhiteboardToolDelegate,EEPageControlDelegate,UIViewControllerTransitioningDelegate,WhiteCommonCallbackDelegate,AgoraRtcEngineDelegate,AgoraRtmDelegate,UITextFieldDelegate,AgoraRtmChannelDelegate,WhiteRoomCallbackDelegate>
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *navigationHeightCon;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *teacherVideoWidthCon;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *handupButtonRightCon;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *whiteboardToolTopCon; //默认 267
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *chatTableViewWidthCon;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *chatTextFiledWidthCon;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *chatTableViewTopCon;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *tipLabelTopCon;//默认 267
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *whiteboardViewRightCon;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *whiteboardViewTopCon;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *whiteboardViewLeftCon;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *teacherVideoViewHeightCon;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *studentVideoViewLeftCon;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *studentViewWidthCon;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *studentViewHeightCon;
@property (weak, nonatomic) IBOutlet UIView *lineView;

@property (nonatomic, weak) UIButton *closeButton;
@property (weak, nonatomic) IBOutlet EETeacherVideoView *teactherVideoView;
@property (weak, nonatomic) IBOutlet EEStudentVideoView *studentVideoView;
@property (weak, nonatomic) IBOutlet EESegmentedView *segmentedView;
@property (weak, nonatomic) IBOutlet EENavigationView *navigationView;
@property (weak, nonatomic) IBOutlet EEWhiteboardTool *whiteboardTool;
@property (weak, nonatomic) IBOutlet EEPageControlView *pageControlView;
@property (weak, nonatomic) IBOutlet UIView *whiteboardView;
@property (weak, nonatomic) IBOutlet UIButton *handUpButton;
@property (weak, nonatomic) IBOutlet UILabel *tipLabel;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *navigationHeightConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *textFiledBottomConstraint;

@property (weak, nonatomic) IBOutlet UIView *windowShareView;
@property (weak, nonatomic) IBOutlet EEChatTextFiled *chatTextFiled;
@property (weak, nonatomic) IBOutlet EEChatContentTableView *chatContentTableView;
@property (nonatomic, strong) WhiteBoardView *boardView;
@property (nonatomic, strong) WhiteSDK *sdk;
@property (nonatomic, strong, nullable) WhiteRoom *room;
@property (nonatomic, strong) AgoraRtcEngineKit *rtcEngineKit;
@property (nonatomic, strong) AgoraRtcVideoCanvas *teacherCanvas;
@property (nonatomic, strong) AgoraRtcVideoCanvas *studentCanvas;
@property (nonatomic, assign) BOOL teacherInRoom;
@property (nonatomic, copy) EEBCStudentAttrs *studentAttrs;
@property (nonatomic, strong) NSMutableDictionary *studentList;
@property (nonatomic, copy) EEBCTeactherAttrs *teacherAttr;
@property (weak, nonatomic) IBOutlet EEColorShowView *colorShowView;
@property (nonatomic, assign) NSInteger sceneIndex;
@property (nonatomic, copy) NSString *sceneDirectory;
@property (nonatomic, strong) NSArray<WhiteScene *> *scenes;
@property (nonatomic, strong) UIColor *pencilColor;
@property (nonatomic, strong) WhiteMemberState *memberState;
@property (nonatomic, assign) NSInteger *unreadMessageCount;
@property (nonatomic, assign) StudentLinkState linkState;
@property (nonatomic, strong) AgoraRtmChannel *rtmChannel;
@property (nonatomic, strong) NSMutableArray *channelAttrs;

@property (nonatomic, copy) NSString *channelName;
@property (nonatomic, strong) AgoraRtmKit *rtmKit;
@property (nonatomic, copy) NSString *userName;
@property (nonatomic, copy) NSString *userId;
@property (nonatomic, copy) NSString *rtmChannelName;
@end

@implementation BCViewController

- (void)setParams:(NSDictionary *)params {
    _params = params;
    if (params[@"rtmKit"]) {
        self.rtmKit = params[@"rtmKit"];
        self.channelName = params[@"channelName"];
        self.userName = params[@"userName"];
        self.userId = params[@"userId"];
        self.rtmChannel  =  [self.rtmKit createChannelWithId:params[@"rtmChannelName"] delegate:self];
        WEAK(self)
        [self.rtmChannel joinWithCompletion:^(AgoraRtmJoinChannelErrorCode errorCode) {
           if (errorCode == AgoraRtmJoinChannelErrorOk) {
               NSLog(@"频道加入成功");
               [weakself getRtmChannelAttrs];
           }
        }];
    }
}

- (void)getRtmChannelAttrs{
    WEAK(self)
    [self.rtmKit getChannelAllAttributes:self.channelName completion:^(NSArray<AgoraRtmChannelAttribute *> * _Nullable attributes, AgoraRtmProcessAttributeErrorCode errorCode) {
        [weakself parsingTheChannelAttr:attributes];
        if (weakself.teacherAttr) {
           weakself.teacherInRoom = YES;
           [weakself joinWhiteBoardRoomUUID:weakself.teacherAttr.whiteboard_uuid];
        }
        [weakself setChannelAttr];
    }];
}

- (void)setChannelAttr {
      AgoraRtmChannelAttribute *setAttr = [[AgoraRtmChannelAttribute alloc] init];
       setAttr.key = self.userId;
       setAttr.value = [EEPublicMethodsManager setChannelAttrsWithName:self.userName];
       AgoraRtmChannelAttributeOptions *options = [[AgoraRtmChannelAttributeOptions alloc] init];
       options.enableNotificationToChannelMembers = YES;
       NSArray *attrArray = [NSArray arrayWithObjects:setAttr, nil];
       [self.rtmKit addOrUpdateChannel:self.channelName Attributes:attrArray Options:options completion:^(AgoraRtmProcessAttributeErrorCode errorCode) {
           if (errorCode == AgoraRtmAttributeOperationErrorOk) {
               NSLog(@"更新成功");
           }else {
               NSLog(@"更新失败");
           }
       }];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setUpView];

    UIDeviceOrientation duration = [[UIDevice currentDevice] orientation];
    if (duration == UIDeviceOrientationLandscapeLeft || duration == UIDeviceOrientationLandscapeRight) {
       [self landscapeConstraints];
    }else {
       [self verticalScreenConstraints];
    }
    [self.rtmKit setAgoraRtmDelegate:self];
    [self addNotification];
    self.studentList = [NSMutableDictionary dictionary];
    [self joinAgoraRtcChannel];
    [self joinWhiteBoardRoomUUID:@"f988fb64078e48baa410058bd728009b"];
}

#pragma mark -----------------------------------Private Method ---------------------------
- (void)setUpView {

    self.view.backgroundColor = [UIColor whiteColor];
    if (@available(iOS 11, *)) {
    } else {
        self.automaticallyAdjustsScrollViewInsets = NO;
    }

    self.boardView = [[WhiteBoardView alloc] init];
    [self.whiteboardView addSubview:self.boardView];

    self.windowShareView.hidden = YES;
    self.handUpButton.hidden = YES;
    self.tipLabel.hidden = YES;
    self.studentVideoView.hidden = YES;
    self.whiteboardTool.hidden = YES;
    self.chatContentTableView.hidden = YES;
    self.chatTextFiled.hidden = YES;
    self.pageControlView.hidden = YES;
    [self.segmentedView setNeedsLayout];
    [self.segmentedView layoutIfNeeded];
    self.segmentedView.delegate = self;
    self.whiteboardTool.delegate = self;
    self.pageControlView.delegate = self;

    [self.navigationView.closeButton addTarget:self action:@selector(closeRoom:) forControlEvents:(UIControlEventTouchUpInside)];
    self.handUpButton.layer.borderWidth = 1.f;
    self.handUpButton.layer.borderColor = [UIColor colorWithRed:219/255.0 green:226/255.0 blue:229/255.0 alpha:1.0].CGColor;

    self.handUpButton.layer.backgroundColor = [UIColor colorWithRed:255/255.0 green:255/255.0 blue:255/255.0 alpha:1.0].CGColor;
    self.handUpButton.layer.cornerRadius = 6;
    [EEPublicMethodsManager addShadowWithView:self.handUpButton alpha:0.1];

    self.tipLabel.layer.backgroundColor = [UIColor colorWithRed:0/255.0 green:0/255.0 blue:0/255.0 alpha:0.7].CGColor;
    self.tipLabel.layer.cornerRadius = 6;
    [EEPublicMethodsManager addShadowWithView:self.tipLabel alpha:0.25];

    self.chatTextFiled.contentTextFiled.delegate = self;
    self.colorShowView.hidden = YES;
    WEAK(self)
    self.colorShowView.selectColor = ^(NSString *colorString) {
        NSArray *colorArray  =  [UIColor convertColorToRGB:[UIColor colorWithHexString:colorString]];
        weakself.memberState.strokeColor = colorArray;
        [weakself.room setMemberState:weakself.memberState];
    };
    self.navigationView.titleLabel.text = self.channelName;

}

- (void)joinAgoraRtcChannel {
    self.rtcEngineKit = [AgoraRtcEngineKit sharedEngineWithAppId:kAgoraAppid delegate:self];
    [self.rtcEngineKit setChannelProfile:(AgoraChannelProfileLiveBroadcasting)];
    [self.rtcEngineKit setClientRole:(AgoraClientRoleAudience)];
    [self.rtcEngineKit enableVideo];
    [self.rtcEngineKit startPreview];
    [self.rtcEngineKit enableAudioVolumeIndication:300 smooth:3 report_vad:NO];
    [self.rtcEngineKit joinChannelByToken:nil channelId:self.channelName info:nil uid:[self.userId integerValue] joinSuccess:^(NSString * _Nonnull channel, NSUInteger uid, NSInteger elapsed) {
    }];
}

- (void)joinWhiteBoardRoomUUID:(NSString *)uuid {
     self.sdk = [[WhiteSDK alloc] initWithWhiteBoardView:self.boardView config:[WhiteSdkConfiguration defaultConfig] commonCallbackDelegate:self];
     AgoraHttpRequest *request = [[AgoraHttpRequest alloc] init];
    WEAK(self)
    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:self.channelName,@"name",@"100",@"limit", nil];
    [request post:kGetWhiteBoardUuid params:params success:^(id responseObj) {
               NSDictionary *responseObject = [NSJSONSerialization JSONObjectWithData:responseObj options:0 error:nil];
               if ([responseObject[@"code"] integerValue] == 200) {
                   NSDictionary *roomDict = responseObject[@"msg"][@"room"];
                    WhiteRoomConfig *roomConfig = [[WhiteRoomConfig alloc] initWithUuid:roomDict[@"uuid"] roomToken:responseObject[@"msg"][@"roomToken"]];
                   [weakself.sdk joinRoomWithConfig:roomConfig callbacks:self completionHandler:^(BOOL success, WhiteRoom * _Nullable room, NSError * _Nullable error) {
                       weakself.room = room;
                       [weakself getWhiteboardSceneInfo];
//                       [weakself.room disableDeviceInputs:YES];
                 }];
               }
           } failure:^(NSError *error) {

           }];

//    [EERoomMessageManager parseWhiteBoardRoomWithUuid:uuid token:^(NSString * _Nonnull token) {
//        WhiteRoomConfig *roomConfig = [[WhiteRoomConfig alloc] initWithUuid:uuid roomToken:token];
//        [weakself.sdk joinRoomWithConfig:roomConfig callbacks:nil completionHandler:^(BOOL success, WhiteRoom * _Nullable room, NSError * _Nullable error) {
//            weakself.room = room;
//            [weakself getWhiteboardSceneInfo];
//            [weakself.room disableDeviceInputs:YES];
//        }];
//    } failure:^(NSString * _Nonnull msg) {
//        NSLog(@"获取失败 %@",msg);
//    }];
}
- (void)getWhiteboardSceneInfo {
    WEAK(self)
    [self.room getSceneStateWithResult:^(WhiteSceneState * _Nonnull state) {
        weakself.scenes = [NSArray arrayWithArray:state.scenes];
        weakself.sceneDirectory = @"/";
        weakself.sceneIndex = 1;
        [weakself.pageControlView.pageCountLabel setText:[NSString stringWithFormat:@"%ld/%ld",weakself.sceneIndex,weakself.scenes.count]];
   }];
}

//设备方向改变的处理
- (void)handleDeviceOrientationChange:(NSNotification *)notification{
    UIDeviceOrientation deviceOrientation = [UIDevice currentDevice].orientation;
    switch (deviceOrientation) {
        case UIDeviceOrientationPortrait:
            [self verticalScreenConstraints];
        break;
        case UIDeviceOrientationLandscapeLeft:
        case UIDeviceOrientationLandscapeRight:
        {
            [self landscapeConstraints];
        }
            break;
        default:
            NSLog(@"无法辨识");
            break;
    }
}
- (void)landscapeConstraints {

    self.segmentedView.hidden = YES;
    self.navigationHeightCon.constant = 30;
    self.navigationView.titleLabelBottomConstraint.constant = 5;
    self.navigationView.closeButtonBottomConstraint.constant = 0;
    self.teacherVideoWidthCon.constant = 223;
    self.handupButtonRightCon.constant = 233;
    self.whiteboardToolTopCon.constant = 10;
    self.chatTableViewWidthCon.constant = 223;
    self.chatTextFiledWidthCon.constant = 223;
    self.tipLabelTopCon.constant = 10;
    self.chatTableViewTopCon.constant = 0;
    self.whiteboardViewRightCon.constant = -223;
    self.whiteboardViewTopCon.constant = 0;
    self.teacherVideoViewHeightCon.constant = 125;
    self.studentVideoViewLeftCon.constant = 66;
    self.studentViewHeightCon.constant = 85;
    self.studentViewWidthCon.constant = 120;
    [self.view bringSubviewToFront:self.studentVideoView];
    self.boardView.frame = CGRectMake(0, 0, kScreenWidth - 223, kScreenHeight - 40);

    self.lineView.hidden = NO;
    self.chatTextFiled.hidden = NO;
    self.chatContentTableView.hidden = NO;
}

- (void)verticalScreenConstraints {

    CGFloat navigationBarHeight =  (kScreenHeight / kScreenWidth > 1.78) ? 88 : 64;
    self.navigationHeightCon.constant = navigationBarHeight;
    self.navigationView.titleLabelBottomConstraint.constant = 12;
    self.navigationView.closeButtonBottomConstraint.constant = 7;
    self.teacherVideoWidthCon.constant = kScreenWidth;
    self.handupButtonRightCon.constant = 10;
    self.whiteboardToolTopCon.constant = 267;
    self.chatTableViewWidthCon.constant = kScreenWidth;
    self.chatTextFiledWidthCon.constant = kScreenWidth;
    self.tipLabelTopCon.constant = 267;
    self.chatTableViewTopCon.constant = 44;
    self.segmentedView.hidden = NO;
    self.whiteboardViewRightCon.constant = 0;
    self.whiteboardViewTopCon.constant = 257;
    self.teacherVideoViewHeightCon.constant = 213;
    self.studentVideoViewLeftCon.constant = kScreenWidth - 100;
    self.studentViewWidthCon.constant = 85;
    self.studentViewHeightCon.constant = 120;
    [self.view bringSubviewToFront:self.studentVideoView];
    self.boardView.frame = CGRectMake(0, 0, kScreenWidth, kScreenHeight - 257);

    self.lineView.hidden = YES;
}

- (void)closeRoom:(UIButton *)sender {
    WEAK(self)
    UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:@"是否退出房间" message:nil preferredStyle:(UIAlertControllerStyleAlert)];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消" style:(UIAlertActionStyleCancel) handler:^(UIAlertAction * _Nonnull action) {
    }];
    UIAlertAction *confirmAction = [UIAlertAction actionWithTitle:@"确定" style:(UIAlertActionStyleDefault) handler:^(UIAlertAction * _Nonnull action) {
        [weakself.rtcEngineKit leaveChannel:nil];
        AgoraRtmChannelAttributeOptions *options = [[AgoraRtmChannelAttributeOptions alloc] init];
        options.enableNotificationToChannelMembers = YES;
        [weakself.rtmKit deleteChannel:weakself.channelName AttributesByKeys:@[weakself.userId] Options:options completion:nil];
        [weakself.rtmChannel leaveWithCompletion:nil];
        [weakself dismissViewControllerAnimated:NO completion:nil];
    }];
    [alertVC addAction:cancelAction];
    [alertVC addAction:confirmAction];
    [self presentViewController:alertVC animated:NO completion:nil];
}

- (IBAction)handUpEvent:(UIButton *)sender {
    if (self.teacherAttr) {
        WEAK(self)
        [self.rtmKit sendMessage:[[AgoraRtmMessage alloc] initWithText:[EEPublicMethodsManager studentApplyLink]] toPeer:self.teacherAttr.uid completion:^(AgoraRtmSendPeerMessageErrorCode errorCode) {
            if (errorCode == AgoraRtmSendPeerMessageErrorOk) {
                weakself.linkState = StudentLinkStateApply;
                [sender setBackgroundImage:[UIImage imageNamed:@"icon-handup x"] forState:(UIControlStateNormal)];
            }
        }];

        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5.f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            if (weakself.linkState == StudentLinkStateApply) {
                weakself.linkState = StudentLinkStateTimeout;
                [sender setBackgroundImage:[UIImage imageNamed:@"icon-handup"] forState:(UIControlStateNormal)];
            }
        });
    }
}

- (void)parsingTheChannelAttr:(NSArray<AgoraRtmChannelAttribute *> *)attributes {
    if (attributes.count > 0) {
        for (AgoraRtmChannelAttribute *channelAttr in attributes) {
           NSDictionary *valueDict =   [JsonAndStringConversions dictionaryWithJsonString:channelAttr.value];
           if ([channelAttr.key isEqualToString:@"teacher"]) {
               self.teacherAttr = [EEBCTeactherAttrs yy_modelWithJSON:valueDict];
               self.pageControlView.hidden = NO;
               self.handUpButton.hidden = NO;
               [self.teactherVideoView updateAndsetTeacherName:self.teacherAttr.account];
           }else {
               EEBCStudentAttrs *studentAttr = [EEBCStudentAttrs yy_modelWithJSON:valueDict];
               studentAttr.userId = channelAttr.key;
               [self.studentList setValue:studentAttr forKey:channelAttr.key];
           }
        }
    }
}

#pragma mark ---------------------------- Notification ---------------------
- (void)addNotification {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWasShow:) name:UIKeyboardDidShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillBeHiden:) name:UIKeyboardWillHideNotification object:nil];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(handleDeviceOrientationChange:) name:UIDeviceOrientationDidChangeNotification object:nil];
}

- (void)keyboardWasShow:(NSNotification *)notification {
    CGRect frame = [[[notification userInfo] objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    float bottom = frame.size.height;
    self.textFiledBottomConstraint.constant = bottom;
}

- (void)keyboardWillBeHiden:(NSNotification *)notification {
    self.textFiledBottomConstraint.constant = 0;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    WEAK(self)
    __block NSString *content = textField.text;
    [self.rtmChannel sendMessage:[[AgoraRtmMessage alloc] initWithText:textField.text] completion:^(AgoraRtmSendChannelMessageErrorCode errorCode) {
        if (errorCode == AgoraRtmSendChannelMessageErrorOk) {
            RoomMessageModel *messageModel = [[RoomMessageModel alloc] init];
            messageModel.content = content;
            messageModel.name = weakself.userName;
            messageModel.isSelfSend = YES;
            [weakself.chatContentTableView.messageArray addObject:messageModel];
            [weakself.chatContentTableView reloadData];
        }
    }];
    textField.text = nil;
    [textField resignFirstResponder];
    return NO;
}

#pragma mark --------------------- Segment Delegate -------------------
- (void)selectedItemIndex:(NSInteger)index {
    if (self.colorShowView.hidden == NO) {
        self.colorShowView.hidden = YES;
    }
    if (index == 0) {
        self.chatContentTableView.hidden = YES;
        self.chatTextFiled.hidden = YES;
        self.pageControlView.hidden = NO;
        self.handUpButton.hidden = NO;
        self.whiteboardTool.hidden = NO;
        self.whiteboardTool.hidden = self.linkState == StudentLinkStateApply ? NO : YES;
        self.handUpButton.hidden = self.teacherInRoom ? NO: YES;
    }else {
        self.chatContentTableView.hidden = NO;
        self.chatTextFiled.hidden = NO;
        self.pageControlView.hidden = YES;
        self.handUpButton.hidden = YES;
        self.whiteboardTool.hidden = YES;
        self.unreadMessageCount = 0;
        [self.segmentedView hiddeBadge];
    }
}

#pragma mark --------------------- WhiteBoard Tool Delegate -------------------
- (void)selectWhiteboardToolIndex:(NSInteger)index {

   self.memberState = [[WhiteMemberState alloc] init];
    switch (index) {
        case 0:
            self.memberState.currentApplianceName = ApplianceSelector;
            [self.room setMemberState:self.memberState];
            break;
        case 1:
            self.memberState.currentApplianceName = AppliancePencil;
            [self.room setMemberState:self.memberState];
        break;
        case 2:
            self.memberState.currentApplianceName = ApplianceText;
            [self.room setMemberState:self.memberState];
        break;
        case 3:
            self.memberState.currentApplianceName = ApplianceEraser;
            [self.room setMemberState:self.memberState];
        break;

        default:
            break;
    }
    if (index == 4) {
         self.colorShowView.hidden = NO;
    }else {
        if (self.colorShowView.hidden == NO) {
            self.colorShowView.hidden = YES;
        }
    }
}

#pragma mark ----------------------------------- PageControl Delegate ---------------------------
- (void)previousPage {
    if (self.sceneIndex > 1) {
        self.sceneIndex = self.sceneIndex -1;
       [self.room setScenePath:[NSString stringWithFormat:@"/%@",self.scenes[self.sceneIndex].name]];
       [self.pageControlView.pageCountLabel setText:[NSString stringWithFormat:@"%ld/%ld",self.sceneIndex,self.scenes.count]];
    }
}

- (void)nextPage {
    if (self.sceneIndex < self.scenes.count) {
        self.sceneIndex = self.sceneIndex + 1;
        [self.room setScenePath:[NSString stringWithFormat:@"/%@",self.scenes[self.sceneIndex].name]];
        [self.pageControlView.pageCountLabel setText:[NSString stringWithFormat:@"%ld/%ld",self.sceneIndex,self.scenes.count]];
    }
}

- (void)lastPage {
    self.sceneIndex = self.scenes.count;
    [self.room setScenePath:[NSString stringWithFormat:@"/%@",self.scenes[self.sceneIndex-1].name]];
    [self.pageControlView.pageCountLabel setText:[NSString stringWithFormat:@"%ld/%ld",self.sceneIndex,self.scenes.count]];
}

- (void)firstPage {
    self.sceneIndex = 1;
    [self.room setScenePath:[NSString stringWithFormat:@"/%@",self.scenes[self.sceneIndex-1].name]];
    [self.pageControlView.pageCountLabel setText:[NSString stringWithFormat:@"%ld/%ld",self.sceneIndex,self.scenes.count]];
}

#pragma mark --------------------- RTC Delegate -------------------
- (void)rtcEngine:(AgoraRtcEngineKit *)engine firstRemoteVideoDecodedOfUid:(NSUInteger)uid size:(CGSize)size elapsed:(NSInteger)elapsed {
    if (uid == [self.teacherAttr.uid integerValue]) {
        self.teactherVideoView.defaultImageView.hidden = NO;
        self.teacherCanvas = [[AgoraRtcVideoCanvas alloc] init];
        self.teacherCanvas.uid = uid;
        self.teacherCanvas.view = self.teactherVideoView.teacherRenderView;
        [self.rtcEngineKit setupRemoteVideo:self.teacherCanvas];
    }else {
        self.studentCanvas = [[AgoraRtcVideoCanvas alloc] init];
        self.studentCanvas.uid = uid;
        self.studentCanvas.view = self.studentVideoView.studentRenderView;
        [self.rtcEngineKit setupRemoteVideo:self.studentCanvas];
    }
}

- (void)rtcEngine:(AgoraRtcEngineKit *)engine didJoinedOfUid:(NSUInteger)uid elapsed:(NSInteger)elapsed {
    if (uid == [self.teacherAttr.shared_uid integerValue]) {
        self.windowShareView.hidden = NO;
        AgoraRtcVideoCanvas *canvas = [[AgoraRtcVideoCanvas alloc] init];
        canvas.uid = uid;
        canvas.view = self.windowShareView;
        [self.rtcEngineKit setupRemoteVideo:canvas];
    }
}

- (void)rtcEngine:(AgoraRtcEngineKit *)engine didOfflineOfUid:(NSUInteger)uid reason:(AgoraUserOfflineReason)reason {
    if (uid == [self.teacherAttr.uid integerValue]) {
        self.teacherCanvas = nil;
    }else {
        self.studentCanvas = nil;
    }
}

- (void)rtcEngine:(AgoraRtcEngineKit *)engine didAudioMuted:(BOOL)muted byUid:(NSUInteger)uid {
    [self.studentVideoView updateAudioImage:muted];
}

- (void)rtcEngine:(AgoraRtcEngineKit *)engine didVideoMuted:(BOOL)muted byUid:(NSUInteger)uid {
    [self.studentVideoView updateVideoImage:muted];
}

- (void)rtcEngine:(AgoraRtcEngineKit *)engine reportAudioVolumeIndicationOfSpeakers:(NSArray<AgoraRtcAudioVolumeInfo *> *)speakers totalVolume:(NSInteger)totalVolume {
    if (speakers.count > 0) {
        for (AgoraRtcAudioVolumeInfo *info in speakers) {
            if (info.uid == [self.teacherAttr.uid integerValue]) {
                NSArray *imageArray = @[@"eeSpeaker1",@"eeSpeaker2",@"eeSpeaker3"];
                [self.teactherVideoView.speakerImage setAnimationImages:imageArray];
                [self.teactherVideoView.speakerImage setAnimationRepeatCount:0];
                [self.teactherVideoView.speakerImage setAnimationDuration:3.0f];
                [self.teactherVideoView.speakerImage startAnimating];
            }
        }
    }
}
#pragma mark --------------------- RTM Delegate -------------------
- (void)channel:(AgoraRtmChannel * _Nonnull)channel memberJoined:(AgoraRtmMember * _Nonnull)member {

}

- (void)channel:(AgoraRtmChannel * _Nonnull)channel memberLeft:(AgoraRtmMember * _Nonnull)member {

}

- (void)channel:(AgoraRtmChannel * _Nonnull)channel messageReceived:(AgoraRtmMessage * _Nonnull)message fromMember:(AgoraRtmMember * _Nonnull)member {

    NSString *userName = nil;
    if ([member.userId isEqualToString: self.teacherAttr.uid]) {
        userName = self.teacherAttr.account;
    }else {
        EEBCStudentAttrs *attrs = self.studentList[member.userId];
        userName = attrs.account;
    }
    RoomMessageModel *messageModel = [[RoomMessageModel alloc] init];
    messageModel.content = message.text;
    messageModel.name = userName;
    messageModel.isSelfSend = NO;
    [self.chatContentTableView.messageArray addObject:messageModel];
    [self.chatContentTableView reloadData];
    if (self.chatContentTableView.hidden == YES) {
        self.unreadMessageCount = self.unreadMessageCount + 1;
        [self.segmentedView showBadgeWithCount:*(self.unreadMessageCount)];
    }
}

- (void)rtmKit:(AgoraRtmKit *)kit messageReceived:(AgoraRtmMessage *)message fromPeer:(NSString *)peerId {
    if ([peerId isEqualToString:self.teacherAttr.uid]) {
        NSDictionary *dict = [JsonAndStringConversions dictionaryWithJsonString:message.text];
        if ([dict[@"type"] isEqualToString:@"mute"]) {
            if ([dict[@"resource"] isEqualToString:@"video"]) {
                [self.rtcEngineKit muteLocalVideoStream:YES];
                [self.studentVideoView updateVideoImage:YES];
            }else if([dict[@"resource"] isEqualToString:@"audio"]) {
                [self.rtcEngineKit muteLocalAudioStream:YES];
                [self.studentVideoView updateAudioImage:NO];
            }
        }else if([dict[@"type"] isEqualToString:@"unmute"]){
            if ([dict[@"resource"] isEqualToString:@"video"]) {
               [self.rtcEngineKit muteLocalVideoStream:NO];
                [self.studentVideoView updateVideoImage:NO];
            }else if([dict[@"resource"] isEqualToString:@"audio"]) {
               [self.rtcEngineKit muteLocalAudioStream:NO];
               [self.studentVideoView updateAudioImage:NO];
            }
        }else if ([dict[@"type"] isEqualToString:@"accept"]) {
            [self.rtcEngineKit setClientRole:(AgoraClientRoleBroadcaster)];
            self.linkState = StudentLinkStateAccept;
            self.studentCanvas = [[AgoraRtcVideoCanvas alloc] init];
            self.studentCanvas.uid = [self.userId integerValue];
            self.studentCanvas.view = self.studentVideoView.studentRenderView;
            [self.rtcEngineKit setupLocalVideo:self.studentCanvas];
            [self.tipLabel setText:[NSString stringWithFormat:@"%@接受了你的连麦申请!",self.teacherAttr.account]];
            WEAK(self)
           dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
               weakself.tipLabel.hidden = YES;
           });
        }else if ([dict[@"type"] isEqualToString:@"accept"]) {
            [self.rtcEngineKit setClientRole:(AgoraClientRoleBroadcaster)];
            self.linkState = StudentLinkStateReject;
        }
    }
}

- (void)channel:(AgoraRtmChannel * _Nonnull)channel attributeUpdate:(NSArray< AgoraRtmChannelAttribute *> * _Nonnull)attributes {
    [self parsingTheChannelAttr:attributes];
}

#pragma mark ------------------------- whiteboard Delegate ---------------------------
- (void)fireRoomStateChanged:(WhiteRoomState *)modifyState {
    if (modifyState.sceneState && modifyState.sceneState.scenes.count > self.scenes.count) {
        self.scenes = [NSArray arrayWithArray:modifyState.sceneState.scenes];
        self.sceneDirectory = @"/";
        self.sceneIndex = self.sceneIndex+1;
        [self.room setScenePath:[NSString stringWithFormat:@"/%@",self.scenes[self.sceneIndex - 1].name]];
        [self.pageControlView.pageCountLabel setText:[NSString stringWithFormat:@"%ld/%ld",self.scenes.count,self.scenes.count]];
    }
}


#pragma mark  ------------------------- System methods --------------------------------
- (void)dealloc {
    NSLog(@"BigClassViewController is Dealloc");
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (BOOL)prefersStatusBarHidden {
    return NO;
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
