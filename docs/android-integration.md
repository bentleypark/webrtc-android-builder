# 📱 Android Project Integration Example
## Complete WebRTC Android Integration Guide

### 🎯 Dynamic WebRTC Version Support

This guide demonstrates integration with **dynamically generated WebRTC AAR files** from our GitHub Action. The action automatically detects the milestone version from the selected branch and generates appropriately named AAR files:

- **branch-heads/7151** → `libwebrtc-m137-X.aar` (M137)
- **branch-heads/7103** → `libwebrtc-m136-X.aar` (M136)
- **branch-heads/7000+** → `libwebrtc-m135-X.aar` (M135)

**🔗 Milestone Reference**: Use [Chromium Dash](https://chromiumdash.appspot.com/branches) to find branch numbers for your target WebRTC milestone.

### 🏗️ Project Structure
```
MyWebRTCApp/
├── app/
│   ├── libs/
│   │   └── libwebrtc-mXXX-X.aar          # The built AAR file (dynamic milestone)
│   ├── src/main/
│   │   └── java/.../
│   │       ├── MainActivity.kt
│   │       ├── WebRTCManager.kt
│   │       └── SignalingClient.kt
│   ├── build.gradle               # Dependency configuration
│   └── proguard-rules.pro        # ProGuard rules
└── build.gradle                   # Project configuration
```

## ⚙️ Gradle Configuration

### Project-level build.gradle
```gradle
buildscript {
    ext {
        compileSdkVersion = 35
        targetSdkVersion = 35
        minSdkVersion = 24  
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}
```

### App-level build.gradle
```gradle
android {
    compileSdk 34
    
    defaultConfig {
        applicationId "com.yourcompany.webrtcapp"
        minSdk 24                 
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
        sourceCompatibility JavaVersion.VERSION_17
        targetCompatibility JavaVersion.VERSION_17
    }
    
    // Enable Java 17+ features
    kotlinOptions {
        jvmTarget = '17'
    }
    
    // Native library management
    packagingOptions {
        pickFirst '**/libc++_shared.so'
        pickFirst '**/libjingle_peerconnection_so.so'
    }
}

dependencies {
    // 🚀 WebRTC AAR file
    implementation files('libs/libwebrtc-m137-X.aar')  // Example: M137, X = GitHub run number
    
    // Android base libraries
    implementation 'androidx.appcompat:appcompat:1.6.1'
    implementation 'androidx.constraintlayout:constraintlayout:2.1.4'
    implementation 'com.google.android.material:material:1.10.0'
    
    // Permission management
    implementation 'androidx.activity:activity:1.8.1'
    implementation 'androidx.fragment:fragment:1.6.2'
    
    // JSON processing (for signaling)
    implementation 'com.google.code.gson:gson:2.10.1'
    
    // Networking (WebSocket, etc.)
    implementation 'com.squareup.okhttp3:okhttp:4.12.0'
    
    // Testing
    testImplementation 'junit:junit:4.13.2'
    androidTestImplementation 'androidx.test.ext:junit:1.1.5'
    androidTestImplementation 'androidx.test.espresso:espresso-core:3.5.1'
}
```

## 🛡️ ProGuard Rules (proguard-rules.pro)
```proguard
# Protect WebRTC library
-keep class org.webrtc.** { *; }
-keepclassmembers class org.webrtc.** { *; }
-dontwarn org.webrtc.**

# Protect JNI methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Protect WebRTC callbacks
-keep class * implements org.webrtc.PeerConnection$Observer { *; }
-keep class * implements org.webrtc.SdpObserver { *; }
-keep class * implements org.webrtc.StatsObserver { *; }
-keep class * implements org.webrtc.MediaStreamTrack$Observer { *; }

# Protect data classes (for JSON serialization)
-keep class com.yourcompany.webrtcapp.models.** { *; }

# Gson related settings
-keepattributes Signature
-keepattributes *Annotation*
-dontwarn sun.misc.**
-keep class com.google.gson.examples.android.model.** { <fields>; }
-keep class * extends com.google.gson.TypeAdapter
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer

# OkHttp related settings
-dontwarn okhttp3.**
-dontwarn okio.**
```

## 📋 AndroidManifest.xml
```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="com.yourcompany.webrtcapp">

    <!-- 🔥 Required Permissions -->
    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
    <uses-permission android:name="android.permission.CAMERA" />
    <uses-permission android:name="android.permission.RECORD_AUDIO" />
    <uses-permission android:name="android.permission.MODIFY_AUDIO_SETTINGS" />
    <uses-permission android:name="android.permission.ACCESS_WIFI_STATE" />
    <uses-permission android:name="android.permission.CHANGE_WIFI_STATE" />
    
    <!-- 🔥 Declare Hardware Features -->
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

## 🎯 WebRTC Manager Class

### WebRTCManager.kt
```kotlin
package com.yourcompany.webrtcapp

import android.content.Context
import android.util.Log
import org.webrtc.*
import java.util.ArrayList

class WebRTCManager(private val context: Context) {
    private val eglBase: EglBase = EglBase.create()
    private val peerConnectionFactory: PeerConnectionFactory
    private var peerConnection: PeerConnection? = null
    private var localRenderer: SurfaceViewRenderer? = null
    private var remoteRenderer: SurfaceViewRenderer? = null
    private var videoCapturer: VideoCapturer? = null
    private var localVideoTrack: VideoTrack? = null
    private var localAudioTrack: AudioTrack? = null

    companion object {
        private const val TAG = "WebRTCManager"
    }

    init {
        // Initialize WebRTC
        PeerConnectionFactory.initialize(
            PeerConnectionFactory.InitializationOptions.builder(context)
                .setEnableInternalTracer(true)
                .createInitializationOptions()
        )

        // Create PeerConnectionFactory
        peerConnectionFactory = PeerConnectionFactory.builder()
            .setVideoDecoderFactory(DefaultVideoDecoderFactory(eglBase.eglBaseContext))
            .setVideoEncoderFactory(DefaultVideoEncoderFactory(eglBase.eglBaseContext, true, true))
            .createPeerConnectionFactory()

        Log.d(TAG, "✅ WebRTC initialized successfully!")
    }

    fun setupLocalVideo(renderer: SurfaceViewRenderer) {
        this.localRenderer = renderer
        renderer.init(eglBase.eglBaseContext, null)
        renderer.setMirror(true)

        // Create camera capturer
        videoCapturer = createCameraCapturer()?.also { capturer ->
            val surfaceTextureHelper = SurfaceTextureHelper.create("CaptureThread", eglBase.eglBaseContext)
            val videoSource = peerConnectionFactory.createVideoSource(capturer.isScreencast)
            capturer.initialize(surfaceTextureHelper, context, videoSource.capturerObserver)

            localVideoTrack = peerConnectionFactory.createVideoTrack("local_video", videoSource)
            localVideoTrack?.addSink(renderer)

            capturer.startCapture(1280, 720, 30)
        }

        // Create audio track
        val audioSource = peerConnectionFactory.createAudioSource(MediaConstraints())
        localAudioTrack = peerConnectionFactory.createAudioTrack("local_audio", audioSource)
    }

    fun setupRemoteVideo(renderer: SurfaceViewRenderer) {
        this.remoteRenderer = renderer
        renderer.init(eglBase.eglBaseContext, null)
        renderer.setMirror(false)
    }

    private fun createCameraCapturer(): VideoCapturer? {
        val enumerator = Camera2Enumerator(context)
        val deviceNames = enumerator.deviceNames

        // Prioritize front-facing camera
        deviceNames.firstOrNull { enumerator.isFrontFacing(it) }?.let {
            return enumerator.createCapturer(it, null)
        }

        // Fallback to any other camera
        deviceNames.firstOrNull { !enumerator.isFrontFacing(it) }?.let {
            return enumerator.createCapturer(it, null)
        }

        return null
    }

    fun createPeerConnection() {
        val iceServers = ArrayList<PeerConnection.IceServer>()
        iceServers.add(PeerConnection.IceServer.builder("stun:stun.l.google.com:19302").createIceServer())

        val config = PeerConnection.RTCConfiguration(iceServers).apply {
            bundlePolicy = PeerConnection.BundlePolicy.MAXBUNDLE
            rtcpMuxPolicy = PeerConnection.RtcpMuxPolicy.REQUIRE
            tcpCandidatePolicy = PeerConnection.TcpCandidatePolicy.DISABLED
            candidateNetworkPolicy = PeerConnection.CandidateNetworkPolicy.LOW_COST
        }

        peerConnection = peerConnectionFactory.createPeerConnection(config, PeerConnectionObserver())

        // Add local media stream
        localVideoTrack?.let { peerConnection?.addTrack(it) }
        localAudioTrack?.let { peerConnection?.addTrack(it) }
    }

    private inner class PeerConnectionObserver : PeerConnection.Observer {
        override fun onSignalingChange(state: PeerConnection.SignalingState) {
            Log.d(TAG, "SignalingState: $state")
        }

        override fun onIceConnectionChange(state: PeerConnection.IceConnectionState) {
            Log.d(TAG, "IceConnectionState: $state")
        }

        override fun onIceConnectionReceivingChange(receiving: Boolean) {}

        override fun onIceGatheringChange(state: PeerConnection.IceGatheringState) {
            Log.d(TAG, "IceGatheringState: $state")
        }

        override fun onIceCandidate(candidate: IceCandidate) {
            Log.d(TAG, "IceCandidate: $candidate")
            // Send to signaling server
        }

        override fun onIceCandidatesRemoved(candidates: Array<out IceCandidate>) {}

        override fun onAddStream(stream: MediaStream) {
            Log.d(TAG, "onAddStream")
            if (stream.videoTracks.isNotEmpty()) {
                val remoteVideoTrack = stream.videoTracks[0]
                remoteRenderer?.let { remoteVideoTrack.addSink(it) }
            }
        }

        override fun onRemoveStream(stream: MediaStream) {
            Log.d(TAG, "onRemoveStream")
        }

        override fun onDataChannel(dataChannel: DataChannel) {}

        override fun onRenegotiationNeeded() {
            Log.d(TAG, "onRenegotiationNeeded")
        }

        override fun onAddTrack(receiver: RtpReceiver, mediaStreams: Array<out MediaStream>) {
            Log.d(TAG, "onAddTrack")
        }
    }

    fun cleanup() {
        try {
            videoCapturer?.stopCapture()
        } catch (e: InterruptedException) {
            e.printStackTrace()
        }
        videoCapturer?.dispose()
        localRenderer?.release()
        remoteRenderer?.release()
        peerConnection?.close()
        peerConnectionFactory.dispose()
        eglBase.release()
        PeerConnectionFactory.shutdown()
    }
}
```

### MainActivity.kt
```kotlin
package com.yourcompany.webrtcapp

import android.Manifest
import android.content.pm.PackageManager
import android.os.Bundle
import android.widget.Toast
import androidx.appcompat.app.AppCompatActivity
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import org.webrtc.SurfaceViewRenderer

class MainActivity : AppCompatActivity() {

    private lateinit var webRTCManager: WebRTCManager
    private lateinit var localRenderer: SurfaceViewRenderer
    private lateinit var remoteRenderer: SurfaceViewRenderer

    companion object {
        private const val PERMISSION_REQUEST_CODE = 1001
        private val PERMISSIONS = arrayOf(
            Manifest.permission.CAMERA,
            Manifest.permission.RECORD_AUDIO,
            Manifest.permission.MODIFY_AUDIO_SETTINGS
        )
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)

        // Initialize UI
        localRenderer = findViewById(R.id.local_renderer)
        remoteRenderer = findViewById(R.id.remote_renderer)

        // Check for permissions
        if (checkPermissions()) {
            initWebRTC()
        } else {
            requestPermissions()
        }
    }

    private fun checkPermissions(): Boolean {
        return PERMISSIONS.all {
            ContextCompat.checkSelfPermission(this, it) == PackageManager.PERMISSION_GRANTED
        }
    }

    private fun requestPermissions() {
        ActivityCompat.requestPermissions(this, PERMISSIONS, PERMISSION_REQUEST_CODE)
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == PERMISSION_REQUEST_CODE) {
            if (grantResults.all { it == PackageManager.PERMISSION_GRANTED }) {
                initWebRTC()
            } else {
                Toast.makeText(this, "Permissions are required", Toast.LENGTH_SHORT).show()
                finish()
            }
        }
    }

    private fun initWebRTC() {
        // Initialize WebRTC Manager
        webRTCManager = WebRTCManager(this)
        webRTCManager.setupLocalVideo(localRenderer)
        webRTCManager.setupRemoteVideo(remoteRenderer)
        webRTCManager.createPeerConnection()

        Toast.makeText(this, "WebRTC Initialized!", Toast.LENGTH_SHORT).show()
    }

    override fun onDestroy() {
        super.onDestroy()
        if (::webRTCManager.isInitialized) {
            webRTCManager.cleanup()
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

    <!-- Remote Video (Full Screen) -->
    <org.webrtc.SurfaceViewRenderer
        android:id="@+id/remote_renderer"
        android:layout_width="match_parent"
        android:layout_height="match_parent"
        app:layout_constraintTop_toTopOf="parent"
        app:layout_constraintStart_toStartOf="parent"
        app:layout_constraintEnd_toEndOf="parent"
        app:layout_constraintBottom_toBottomOf="parent" />

    <!-- Local Video (Small Overlay) -->
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

## 🚀 Run and Test

1. **Check Permissions**: Allow camera and microphone permissions
2. **Local Video**: Confirm front camera video display
3. **WebRTC Initialization**: Confirm "WebRTC initialized successfully!" message in logs
4. **Network Connection**: Communicate with remote peer after connecting to signaling server

## ⚡ Performance Optimization Tips

### Adjust Resolution and Frame Rate
```kotlin
// High resolution (high quality)
videoCapturer?.startCapture(1920, 1080, 30)

// Medium resolution (balanced)  
videoCapturer?.startCapture(1280, 720, 30)

// Low resolution (low-end devices)
videoCapturer?.startCapture(640, 480, 24)
```

### Hardware Acceleration Settings
```kotlin
// Enable hardware encoding/decoding
val peerConnectionFactory = PeerConnectionFactory.builder()
    .setVideoEncoderFactory(
        DefaultVideoEncoderFactory(
            eglBase.eglBaseContext, 
            true,   // enableIntelVp8Encoder
            true    // enableH264HighProfile
        )
    )
    .setVideoDecoderFactory(DefaultVideoDecoderFactory(eglBase.eglBaseContext))
    .createPeerConnectionFactory()
```

---

**🎉 Done! Your Android app with WebRTC fully integrated is ready!**