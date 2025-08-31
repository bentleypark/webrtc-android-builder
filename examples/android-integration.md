# 📱 Android 프로젝트 통합 예제

## 완전한 WebRTC Android 통합 가이드

### 🏗️ 프로젝트 구조
```
MyWebRTCApp/
├── app/
│   ├── libs/
│   │   └── libwebrtc.aar          # 빌드된 AAR 파일
│   ├── src/main/
│   │   └── java/.../
│   │       ├── MainActivity.java
│   │       ├── WebRTCManager.java
│   │       └── SignalingClient.java
│   ├── build.gradle               # 의존성 설정
│   └── proguard-rules.pro        # 난독화 규칙
└── build.gradle                   # 프로젝트 설정
```

## ⚙️ Gradle 설정

### 프로젝트 수준 build.gradle
```gradle
buildscript {
    ext {
        compileSdkVersion = 34
        targetSdkVersion = 34
        minSdkVersion = 24        // 16KB 페이지 크기 지원 필수
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}
```

### 앱 수준 build.gradle
```gradle
android {
    compileSdk 34
    
    defaultConfig {
        applicationId "com.yourcompany.webrtcapp"
        minSdk 24                 // 🔥 중요: 16KB 페이지 지원
        targetSdk 34
        versionCode 1
        versionName "1.0"
        
        testInstrumentationRunner "androidx.test.runner.AndroidJUnitRunner"
    }
    
    buildTypes {
        release {
            minifyEnabled true
            proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
        }
        debug {
            minifyEnabled false
            debuggable true
        }
    }
    
    compileOptions {
        sourceCompatibility JavaVersion.VERSION_1_8
        targetCompatibility JavaVersion.VERSION_1_8
    }
    
    // Java 8+ 기능 활성화
    kotlinOptions {
        jvmTarget = '1.8'
    }
    
    // 네이티브 라이브러리 관리
    packagingOptions {
        pickFirst '**/libc++_shared.so'
        pickFirst '**/libjingle_peerconnection_so.so'
    }
}

dependencies {
    // 🚀 WebRTC AAR 파일
    implementation files('libs/libwebrtc.aar')
    
    // Android 기본 라이브러리
    implementation 'androidx.appcompat:appcompat:1.6.1'
    implementation 'androidx.constraintlayout:constraintlayout:2.1.4'
    implementation 'com.google.android.material:material:1.10.0'
    
    // 권한 관리
    implementation 'androidx.activity:activity:1.8.1'
    implementation 'androidx.fragment:fragment:1.6.2'
    
    // JSON 처리 (시그널링용)
    implementation 'com.google.code.gson:gson:2.10.1'
    
    // 네트워킹 (WebSocket 등)
    implementation 'com.squareup.okhttp3:okhttp:4.12.0'
    
    // 테스트
    testImplementation 'junit:junit:4.13.2'
    androidTestImplementation 'androidx.test.ext:junit:1.1.5'
    androidTestImplementation 'androidx.test.espresso:espresso-core:3.5.1'
}
```

## 🛡️ ProGuard 규칙 (proguard-rules.pro)
```proguard
# WebRTC 라이브러리 보호
-keep class org.webrtc.** { *; }
-keepclassmembers class org.webrtc.** { *; }
-dontwarn org.webrtc.**

# JNI 메서드 보호
-keepclasseswithmembernames class * {
    native <methods>;
}

# WebRTC 콜백 보호
-keep class * implements org.webrtc.PeerConnection$Observer { *; }
-keep class * implements org.webrtc.SdpObserver { *; }
-keep class * implements org.webrtc.StatsObserver { *; }
-keep class * implements org.webrtc.MediaStreamTrack$Observer { *; }

# 데이터 클래스 보호 (JSON 직렬화용)
-keep class com.yourcompany.webrtcapp.models.** { *; }

# Gson 관련 설정
-keepattributes Signature
-keepattributes *Annotation*
-dontwarn sun.misc.**
-keep class com.google.gson.examples.android.model.** { <fields>; }
-keep class * extends com.google.gson.TypeAdapter
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer

# OkHttp 관련 설정
-dontwarn okhttp3.**
-dontwarn okio.**
```

## 📋 AndroidManifest.xml
```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="com.yourcompany.webrtcapp">

    <!-- 🔥 필수 권한 -->
    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
    <uses-permission android:name="android.permission.CAMERA" />
    <uses-permission android:name="android.permission.RECORD_AUDIO" />
    <uses-permission android:name="android.permission.MODIFY_AUDIO_SETTINGS" />
    <uses-permission android:name="android.permission.ACCESS_WIFI_STATE" />
    <uses-permission android:name="android.permission.CHANGE_WIFI_STATE" />
    
    <!-- 🔥 하드웨어 기능 선언 -->
    <uses-feature android:name="android.hardware.camera" />
    <uses-feature android:name="android.hardware.camera.autofocus" />
    <uses-feature android:name="android.hardware.microphone" />

    <application
        android:allowBackup="true"
        android:icon="@mipmap/ic_launcher"
        android:label="@string/app_name"
        android:theme="@style/AppTheme"
        android:hardwareAccelerated="true">
        
        <activity
            android:name=".MainActivity"
            android:exported="true"
            android:screenOrientation="portrait">
            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.LAUNCHER" />
            </intent-filter>
        </activity>
        
    </application>
</manifest>
```

## 🎯 WebRTC Manager 클래스

### WebRTCManager.java
```java
package com.yourcompany.webrtcapp;

import android.content.Context;
import android.util.Log;
import org.webrtc.*;
import java.util.ArrayList;
import java.util.List;

public class WebRTCManager {
    private static final String TAG = "WebRTCManager";
    
    private Context context;
    private PeerConnectionFactory peerConnectionFactory;
    private PeerConnection peerConnection;
    private EglBase eglBase;
    private SurfaceViewRenderer localRenderer;
    private SurfaceViewRenderer remoteRenderer;
    private VideoCapturer videoCapturer;
    private VideoTrack localVideoTrack;
    private AudioTrack localAudioTrack;
    
    public WebRTCManager(Context context) {
        this.context = context;
        initWebRTC();
    }
    
    private void initWebRTC() {
        // 🚀 WebRTC 초기화
        PeerConnectionFactory.initialize(
            PeerConnectionFactory.InitializationOptions.builder(context)
                .setEnableInternalTracer(true)
                .createInitializationOptions()
        );
        
        // EGL 컨텍스트 생성
        eglBase = EglBase.create();
        
        // PeerConnectionFactory 생성
        peerConnectionFactory = PeerConnectionFactory.builder()
            .setVideoDecoderFactory(new DefaultVideoDecoderFactory(eglBase.getEglBaseContext()))
            .setVideoEncoderFactory(new DefaultVideoEncoderFactory(eglBase.getEglBaseContext(), true, true))
            .createPeerConnectionFactory();
            
        Log.d(TAG, "✅ WebRTC initialized successfully!");
    }
    
    public void setupLocalVideo(SurfaceViewRenderer renderer) {
        this.localRenderer = renderer;
        renderer.init(eglBase.getEglBaseContext(), null);
        renderer.setMirror(true);
        
        // 카메라 캡처러 생성
        videoCapturer = createCameraCapturer();
        if (videoCapturer != null) {
            SurfaceTextureHelper surfaceTextureHelper = 
                SurfaceTextureHelper.create("CaptureThread", eglBase.getEglBaseContext());
            VideoSource videoSource = peerConnectionFactory.createVideoSource(videoCapturer.isScreencast());
            videoCapturer.initialize(surfaceTextureHelper, context, videoSource.getCapturerObserver());
            
            localVideoTrack = peerConnectionFactory.createVideoTrack("local_video", videoSource);
            localVideoTrack.addSink(renderer);
            
            videoCapturer.startCapture(1280, 720, 30);
        }
        
        // 오디오 트랙 생성
        AudioSource audioSource = peerConnectionFactory.createAudioSource(new MediaConstraints());
        localAudioTrack = peerConnectionFactory.createAudioTrack("local_audio", audioSource);
    }
    
    public void setupRemoteVideo(SurfaceViewRenderer renderer) {
        this.remoteRenderer = renderer;
        renderer.init(eglBase.getEglBaseContext(), null);
        renderer.setMirror(false);
    }
    
    private VideoCapturer createCameraCapturer() {
        CameraEnumerator enumerator = new Camera2Enumerator(context);
        
        // 전면 카메라 우선
        for (String deviceName : enumerator.getDeviceNames()) {
            if (enumerator.isFrontFacing(deviceName)) {
                return enumerator.createCapturer(deviceName, null);
            }
        }
        
        // 후면 카메라
        for (String deviceName : enumerator.getDeviceNames()) {
            if (!enumerator.isFrontFacing(deviceName)) {
                return enumerator.createCapturer(deviceName, null);
            }
        }
        
        return null;
    }
    
    public void createPeerConnection() {
        List<PeerConnection.IceServer> iceServers = new ArrayList<>();
        iceServers.add(PeerConnection.IceServer.builder("stun:stun.l.google.com:19302").createIceServer());
        
        PeerConnection.RTCConfiguration config = new PeerConnection.RTCConfiguration(iceServers);
        config.bundlePolicy = PeerConnection.BundlePolicy.MAXBUNDLE;
        config.rtcpMuxPolicy = PeerConnection.RtcpMuxPolicy.REQUIRE;
        config.tcpCandidatePolicy = PeerConnection.TcpCandidatePolicy.DISABLED;
        config.candidateNetworkPolicy = PeerConnection.CandidateNetworkPolicy.LOW_COST;
        
        peerConnection = peerConnectionFactory.createPeerConnection(config, new PeerConnectionObserver());
        
        // 로컬 미디어 스트림 추가
        if (localVideoTrack != null) {
            peerConnection.addTrack(localVideoTrack);
        }
        if (localAudioTrack != null) {
            peerConnection.addTrack(localAudioTrack);
        }
    }
    
    // PeerConnection 옵저버
    private class PeerConnectionObserver implements PeerConnection.Observer {
        @Override
        public void onSignalingChange(PeerConnection.SignalingState signalingState) {
            Log.d(TAG, "SignalingState: " + signalingState);
        }
        
        @Override
        public void onIceConnectionChange(PeerConnection.IceConnectionState iceConnectionState) {
            Log.d(TAG, "IceConnectionState: " + iceConnectionState);
        }
        
        @Override
        public void onIceConnectionReceivingChange(boolean b) {}
        
        @Override
        public void onIceGatheringChange(PeerConnection.IceGatheringState iceGatheringState) {
            Log.d(TAG, "IceGatheringState: " + iceGatheringState);
        }
        
        @Override
        public void onIceCandidate(IceCandidate iceCandidate) {
            Log.d(TAG, "IceCandidate: " + iceCandidate);
            // 시그널링 서버로 전송
        }
        
        @Override
        public void onIceCandidatesRemoved(IceCandidate[] iceCandidates) {}
        
        @Override
        public void onAddStream(MediaStream mediaStream) {
            Log.d(TAG, "onAddStream");
            if (mediaStream.videoTracks.size() > 0) {
                VideoTrack remoteVideoTrack = mediaStream.videoTracks.get(0);
                if (remoteRenderer != null) {
                    remoteVideoTrack.addSink(remoteRenderer);
                }
            }
        }
        
        @Override
        public void onRemoveStream(MediaStream mediaStream) {
            Log.d(TAG, "onRemoveStream");
        }
        
        @Override
        public void onDataChannel(DataChannel dataChannel) {}
        
        @Override
        public void onRenegotiationNeeded() {
            Log.d(TAG, "onRenegotiationNeeded");
        }
        
        @Override
        public void onAddTrack(RtpReceiver rtpReceiver, MediaStream[] mediaStreams) {
            Log.d(TAG, "onAddTrack");
        }
    }
    
    public void cleanup() {
        if (videoCapturer != null) {
            try {
                videoCapturer.stopCapture();
            } catch (InterruptedException e) {
                e.printStackTrace();
            }
            videoCapturer.dispose();
        }
        
        if (localRenderer != null) {
            localRenderer.release();
        }
        
        if (remoteRenderer != null) {
            remoteRenderer.release();
        }
        
        if (peerConnection != null) {
            peerConnection.close();
        }
        
        if (peerConnectionFactory != null) {
            peerConnectionFactory.dispose();
        }
        
        if (eglBase != null) {
            eglBase.release();
        }
        
        PeerConnectionFactory.shutdown();
    }
}
```

### MainActivity.java
```java
package com.yourcompany.webrtcapp;

import android.Manifest;
import android.content.pm.PackageManager;
import android.os.Bundle;
import android.widget.Toast;
import androidx.annotation.NonNull;
import androidx.appcompat.app.AppCompatActivity;
import androidx.core.app.ActivityCompat;
import androidx.core.content.ContextCompat;
import org.webrtc.SurfaceViewRenderer;

public class MainActivity extends AppCompatActivity {
    private static final int PERMISSION_REQUEST_CODE = 1001;
    private static final String[] PERMISSIONS = {
        Manifest.permission.CAMERA,
        Manifest.permission.RECORD_AUDIO,
        Manifest.permission.MODIFY_AUDIO_SETTINGS
    };
    
    private WebRTCManager webRTCManager;
    private SurfaceViewRenderer localRenderer;
    private SurfaceViewRenderer remoteRenderer;
    
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);
        
        // UI 초기화
        localRenderer = findViewById(R.id.local_renderer);
        remoteRenderer = findViewById(R.id.remote_renderer);
        
        // 권한 확인
        if (checkPermissions()) {
            initWebRTC();
        } else {
            requestPermissions();
        }
    }
    
    private boolean checkPermissions() {
        for (String permission : PERMISSIONS) {
            if (ContextCompat.checkSelfPermission(this, permission) 
                != PackageManager.PERMISSION_GRANTED) {
                return false;
            }
        }
        return true;
    }
    
    private void requestPermissions() {
        ActivityCompat.requestPermissions(this, PERMISSIONS, PERMISSION_REQUEST_CODE);
    }
    
    @Override
    public void onRequestPermissionsResult(int requestCode, @NonNull String[] permissions,
                                         @NonNull int[] grantResults) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults);
        
        if (requestCode == PERMISSION_REQUEST_CODE) {
            boolean allGranted = true;
            for (int result : grantResults) {
                if (result != PackageManager.PERMISSION_GRANTED) {
                    allGranted = false;
                    break;
                }
            }
            
            if (allGranted) {
                initWebRTC();
            } else {
                Toast.makeText(this, "권한이 필요합니다", Toast.LENGTH_SHORT).show();
                finish();
            }
        }
    }
    
    private void initWebRTC() {
        // WebRTC 매니저 초기화
        webRTCManager = new WebRTCManager(this);
        webRTCManager.setupLocalVideo(localRenderer);
        webRTCManager.setupRemoteVideo(remoteRenderer);
        webRTCManager.createPeerConnection();
        
        Toast.makeText(this, "WebRTC 초기화 완료!", Toast.LENGTH_SHORT).show();
    }
    
    @Override
    protected void onDestroy() {
        super.onDestroy();
        if (webRTCManager != null) {
            webRTCManager.cleanup();
        }
    }
}
```

### activity_main.xml
```xml
<?xml version="1.0" encoding="utf-8"?>
<androidx.constraintlayout.widget.ConstraintLayout 
    xmlns:android="http://schemas.android.com/apk/res/android"
    xmlns:app="http://schemas.android.com/apk/res-auto"
    android:layout_width="match_parent"
    android:layout_height="match_parent"
    android:background="@android:color/black">

    <!-- 원격 비디오 (전체 화면) -->
    <org.webrtc.SurfaceViewRenderer
        android:id="@+id/remote_renderer"
        android:layout_width="match_parent"
        android:layout_height="match_parent"
        app:layout_constraintTop_toTopOf="parent"
        app:layout_constraintStart_toStartOf="parent"
        app:layout_constraintEnd_toEndOf="parent"
        app:layout_constraintBottom_toBottomOf="parent" />

    <!-- 로컬 비디오 (소형 오버레이) -->
    <org.webrtc.SurfaceViewRenderer
        android:id="@+id/local_renderer"
        android:layout_width="120dp"
        android:layout_height="160dp"
        android:layout_margin="16dp"
        app:layout_constraintTop_toTopOf="parent"
        app:layout_constraintEnd_toEndOf="parent"
        android:background="@drawable/video_frame_border" />

</androidx.constraintlayout.widget.ConstraintLayout>
```

## 🚀 실행 및 테스트

1. **권한 확인**: 카메라, 마이크 권한 허용
2. **로컬 비디오**: 전면 카메라 영상 표시 확인
3. **WebRTC 초기화**: 로그에서 "WebRTC initialized successfully!" 메시지 확인
4. **네트워크 연결**: 시그널링 서버 연결 후 원격 피어와 통신

## ⚡ 성능 최적화 팁

### 해상도 및 프레임레이트 조정
```java
// 고해상도 (고품질)
videoCapturer.startCapture(1920, 1080, 30);

// 중해상도 (균형)  
videoCapturer.startCapture(1280, 720, 30);

// 저해상도 (저사양 기기)
videoCapturer.startCapture(640, 480, 24);
```

### 하드웨어 가속 설정
```java
// 하드웨어 인코딩/디코딩 활성화
PeerConnectionFactory.builder()
    .setVideoEncoderFactory(new DefaultVideoEncoderFactory(
        eglBase.getEglBaseContext(), 
        true,   // enableIntelVp8Encoder
        true    // enableH264HighProfile
    ))
    .setVideoDecoderFactory(new DefaultVideoDecoderFactory(eglBase.getEglBaseContext()))
    .createPeerConnectionFactory();
```

---

**🎉 완료! 이제 WebRTC가 완전히 통합된 Android 앱이 준비되었습니다!**