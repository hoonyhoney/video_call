import 'package:agora_rtc_engine/rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:video_call/const/agora.dart';
import 'package:agora_rtc_engine/rtc_local_view.dart' as RtcLocalView;
import 'package:agora_rtc_engine/rtc_remote_view.dart' as RtcRemoteView;

class CamScreen extends StatefulWidget {
  const CamScreen({Key? key}) : super(key: key);

  @override
  _CamScreenState createState() => _CamScreenState();
}

class _CamScreenState extends State<CamScreen> {

  RtcEngine? engine;
  int? uid;
  int? otherUid;


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Live"),
      ),
      body: FutureBuilder(
        future: init(),//퓨처함수 넣을수 있음, 변화가 있을때, 빌더를 실행해서 다시 그려줌
        builder: (context,snapshot) {
          if(snapshot.hasError){
            return Center(
              child: Text(snapshot.error.toString()),
            );
          }

          if(!snapshot.hasData) {
            return Center(
              child: CircularProgressIndicator(),
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: renderMainView()),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: ElevatedButton(onPressed: () async{
                  if(engine !=null) {
                    await engine!.leaveChannel();
                  }
                  Navigator.of(context).pop();
                }, child: Text('채널나가기')),
              )
            ],
          );
        }
      ),
    );
  }

  Widget renderSubView() {
    if(otherUid==null) {
      return Center(
        child: Text('채널에 유저가 없습니다.'),
      );
    }else {
      return RtcRemoteView.SurfaceView(
        uid:otherUid!,
        channelId: CHANNEL_NAME,
      );
    }
  }

  Widget renderMainView() {
    if(uid == null) {
      return Center(
        child: Text('채널에 들어가주세요'),
      );
    }else {
      return RtcLocalView.SurfaceView();
    }
  }


  Future<bool> init() async{
    final resp  = await [Permission.camera, Permission.microphone].request();

    final cameraPermission = resp[Permission.camera];
    final micPermission = resp[Permission.microphone];

    if(cameraPermission != PermissionStatus.granted || micPermission != PermissionStatus.granted){
      throw '카메라 또는 마이크 권한이 없습니다';
    }
   if(engine == null) {
     RtcEngineContext context = RtcEngineContext(APP_ID);
     engine = await RtcEngine.createWithContext(context);

     engine!.setEventHandler(
       RtcEngineEventHandler(
         joinChannelSuccess: (String channel, int uid, int elapsed){
           print('채널입장 uid: $uid');
           setState(() {
             this.uid = uid;
           });
         },
         leaveChannel: (state) {
           print('채널 퇴장');
           uid = null;
         },

         userJoined: (int uid, int elapsed) {
           print('상대가 채널에 입장했습니다 uid: $uid');
           setState(() {
             otherUid = uid;
           });
          },

         userOffline: (int uid, UserOfflineReason reason) {
           print('상대가 채널에서 나갔습니다. uid: $uid');
           setState(() {
             otherUid = null;
           });
         }
       ),
     );

     //비디오 활성화 
     await engine!.enableVideo();
     // 채널에 들어가기
     await engine!.joinChannel(TEMP_TOEKN, CHANNEL_NAME, null, 0);
   }

    return true;
  }
}
