# 🚀 WebRTC Android Builder

**Universal WebRTC Android AAR Build System for All Mac Users**

Build WebRTC Android libraries automatically in the cloud using GitHub Actions, eliminating local build complexity and compatibility issues across all Mac architectures (M1, M2, M3, M4, and Intel).

## ✨ Key Features

- 🍎 **Universal Mac Support** - Works on all Mac architectures (M1, M2, M3, M4, Intel)
- ☁️ **Zero Local Resources** - No local build environment required
- ⚡ **Fast Cloud Build** - 2.5 hours vs local 4-8 hours
- 🎯 **Latest WebRTC** - M130 (branch-heads/6845) default support
- 📱 **16KB Page Size Support** - Latest Android compatibility
- 🔄 **Full Automation** - Push, tag, and scheduled builds
- 📦 **Ready to Use** - Direct AAR file download
- 💬 **Slack Integration** - Build notifications with results
- 🛡️ **Security Enhanced** - Post-Quantum Cryptography ready

## 🏗️ Build Architecture

### Cloud Build Pipeline
```
┌─────────────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   Any Mac (Client)      │───▶│  GitHub Actions  │───▶│   Build Result  │
│                         │    │                  │    │                 │
│ • M1/M2/M3/M4/Intel     │    │ • Ubuntu 22.04   │    │ • AAR File      │
│ • Simple Git Push       │    │ • depot_tools     │    │ • Build Info    │
│ • Zero Local Resources  │    │ • WebRTC Source   │    │ • Artifacts     │
└─────────────────────────┘    └──────────────────┘    └─────────────────┘
                                        │
                                        ▼
                               ┌──────────────────┐
                               │ Slack Notification│
                               │                  │
                               │ • Success/Failure │
                               │ • Download Links  │
                               │ • Build Details   │
                               └──────────────────┘
```

### Build Process Flow
```
1. 🔄 Trigger from Any Mac (Manual/Tag/Schedule)
2. 🖥️  Setup Ubuntu 22.04 Cloud Environment  
3. 🛠️  Install depot_tools & Dependencies
4. 📥 Fetch WebRTC Source (branch-heads/6845)
5. ⚙️  Configure Build (16KB pages, architectures)
6. 🔨 Compile AAR (libwebrtc-m130-patched-X.aar)
7. ✅ Verify & Package
8. 📤 Upload Artifacts (Download from Any Mac)
9. 💬 Send Slack Notifications
```

### 🍎 **Universal Mac Compatibility**

**Supported Mac Architectures**:
| Mac Model | Compatibility | Performance | Recommended |
|-----------|--------------|-------------|-------------|
| **M4 Mac** (2024) | ✅ Perfect | ⭐⭐⭐⭐⭐ | **Best Experience** |
| **M3 Mac** (2023) | ✅ Perfect | ⭐⭐⭐⭐⭐ | Excellent |
| **M2 Mac** (2022) | ✅ Perfect | ⭐⭐⭐⭐ | Very Good |
| **M1 Mac** (2020) | ✅ Perfect | ⭐⭐⭐⭐ | Very Good |
| **Intel Mac** | ✅ Perfect | ⭐⭐⭐ | Good |

**Why It Works on All Macs**:
- **Cloud-Based Build**: All compilation happens on GitHub's Ubuntu runners
- **Local Independence**: Your Mac only triggers the build and downloads results
- **No Architecture Conflicts**: Eliminates ARM vs x86 compatibility issues
- **Resource Efficient**: No local memory, disk, or CPU requirements

## 🚀 Quick Start (5 minutes)

### Step 1: Repository Setup
```bash
# Upload this project to GitHub
git init
git add .
git commit -m "🚀 Initial WebRTC Android Builder setup"
git branch -M main
git remote add origin https://github.com/YOUR_USERNAME/webrtc-android-builder.git
git push -u origin main
```

### Step 2: Slack Integration (Optional)
1. Create Slack Webhook URL
2. Add to GitHub Secrets as `SLACK_WEBHOOK_URL`
3. Change channel name in workflow file (currently `#빌드`)

### Step 3: Run Build
1. GitHub Repository → **Actions** tab
2. Select **Build WebRTC Android AAR**
3. Click **Run workflow**
4. Configure build options:
   - **WebRTC Branch**: `branch-heads/6845` (M130, recommended)
   - **Target Architectures**: `armeabi-v7a,arm64-v8a`
   - **Build Configuration**: `release`
   - **16KB Page Support**: `true` ✅
5. Click **Run workflow** button

### Step 4: Download AAR
- After build completion, check **Artifacts** section
- Download `libwebrtc-m130-patched-X.aar` file
- Copy to your Android project's `app/libs/` folder

## 📱 Android Project Integration

### Gradle Configuration (`app/build.gradle`)
```gradle
android {
    compileSdk 34
    
    defaultConfig {
        applicationId "com.yourapp.example"
        minSdk 24        // Required for 16KB page size support
        targetSdk 34
        versionCode 1
        versionName "1.0"
    }
    
    compileOptions {
        sourceCompatibility JavaVersion.VERSION_1_8
        targetCompatibility JavaVersion.VERSION_1_8
    }
}

dependencies {
    implementation files('libs/libwebrtc-m130-patched-5.aar')
    
    // Additional dependencies (if needed)
    implementation 'androidx.appcompat:appcompat:1.6.1'
    implementation 'com.google.android.material:material:1.10.0'
}
```

### ProGuard Rules (`proguard-rules.pro`)
```proguard
# WebRTC library protection
-keep class org.webrtc.** { *; }
-dontwarn org.webrtc.**

# JNI method protection
-keepclasseswithmembernames class * {
    native <methods>;
}

# WebRTC callback protection
-keep class * implements org.webrtc.PeerConnection$Observer { *; }
-keep class * implements org.webrtc.SdpObserver { *; }
```

### Basic Usage
```java
import org.webrtc.*;

public class WebRTCManager {
    private PeerConnectionFactory peerConnectionFactory;
    
    public void initialize(Context context) {
        // WebRTC initialization
        PeerConnectionFactory.initialize(
            PeerConnectionFactory.InitializationOptions.builder(context)
                .setEnableInternalTracer(true)
                .createInitializationOptions()
        );
        
        // Create PeerConnectionFactory
        peerConnectionFactory = PeerConnectionFactory.builder()
            .createPeerConnectionFactory();
            
        Log.d("WebRTC", "✅ WebRTC initialized successfully!");
    }
}
```

## ⚙️ Build Configuration Options

### WebRTC Branch Selection
| Branch | Version | Stability | Recommended Use |
|--------|---------|-----------|-----------------|
| `branch-heads/6845` | M130 | ⭐⭐⭐⭐⭐ | **Production (Latest)** |
| `branch-heads/6478` | M126 | ⭐⭐⭐⭐⭐ | Production (Stable) |
| `branch-heads/6312` | M125 | ⭐⭐⭐⭐ | Legacy Support |
| `main` | Latest | ⭐⭐⭐ | Experimental |

### Target Architecture Options
```yaml
# All architectures (recommended)
target_arch: "armeabi-v7a,arm64-v8a"

# ARM64 only (modern devices)
target_arch: "arm64-v8a"

# Including x86 (emulator support)
target_arch: "armeabi-v7a,arm64-v8a,x86,x86_64"
```

## 📊 Performance Comparison

| Build Environment | Build Time | Memory Usage | Disk Space | Cost | Mac Compatibility |
|-------------------|------------|-------------|------------|------|------------------|
| **GitHub Actions** | 2.5 hours | 8GB | Unlimited | Free | **All Macs** ✅ |
| Local Mac Build | 4-8 hours | 16GB+ | 100GB+ | Power | M1-M4: Issues ❌ |
| Jenkins (AWS) | 1.5 hours | 16GB | 100GB+ | $50/month | All Macs ✅ |
| Local Intel Mac | 6-10 hours | 16GB+ | 100GB+ | Power | Intel Only ⚠️ |

## 🔄 Automated Build Options

### 1. Manual Trigger
- Run anytime from GitHub Actions tab

### 2. Tag-based Release
```bash
git tag -a v1.0.0 -m "WebRTC M130 release"
git push origin v1.0.0
# → Automatically creates GitHub Release (currently commented out)
```

### 3. Scheduled Build (Optional)
- Current: Every Sunday at 11:00 AM KST
- Modify: `.github/workflows/build-webrtc-android.yml` cron setting

## 💬 Slack Notifications

### Success Notification
```
🎉 WebRTC Android AAR Build Success!

📋 Build Information:
• Branch: branch-heads/6845
• Architectures: armeabi-v7a,arm64-v8a
• Configuration: release
• 16KB Pages: true

📦 AAR File: libwebrtc-m130-patched-5.aar

🔗 [Download Artifacts](link)
```

### Failure Notification
```
❌ WebRTC Android AAR Build Failed!

📋 Build Information:
• Branch: branch-heads/6845
• Configuration: release

🔍 [Check Build Log](link)
```

## 🔧 Troubleshooting

### Build Failures
1. Check **Actions** tab for logs
2. Common causes:
   - Invalid branch name
   - Unsupported architecture
   - Network timeout
   - depot_tools initialization issues

**Note**: Build failures are independent of your Mac model - they occur in the cloud environment, not locally.

### Architecture Errors
```yaml
# Wrong example
target_arch: "armv7,arm64"

# Correct example
target_arch: "armeabi-v7a,arm64-v8a"
```

### Slack Integration Issues
- Verify `SLACK_WEBHOOK_URL` secret is set
- Ensure channel exists in Slack workspace
- Check channel name format: `#빌드` or `#webrtc-builds`

## 📁 Project Structure

```
webrtc-android-builder/
├── .github/
│   └── workflows/
│       └── build-webrtc-android.yml    # Build workflow
├── docs/
│   ├── QUICK_START.md                  # 5-minute setup guide
│   ├── BUILD_GUIDE.md                  # Detailed build guide
│   └── INTEGRATION.md                  # Android integration guide
├── examples/
│   ├── android-integration.md          # Complete integration example
│   └── aarproject/                     # Sample Android project
├── scripts/
│   └── download-latest-aar.sh          # CLI download script
├── README.md                           # This file
└── LICENSE                             # License
```

## 📈 Version History

### v2.0.0 (Current - M130)
- ✅ Universal Mac support (M1/M2/M3/M4/Intel)
- ✅ M130 (branch-heads/6845) support
- ✅ Enhanced security with PQC preparation
- ✅ Slack build notifications
- ✅ Improved artifact naming
- ✅ Better error handling

### v1.0.0 (M126)
- ✅ M126 (branch-heads/6478) support
- ✅ 16KB page size support
- ✅ Automatic release system
- ✅ Detailed build information

### Future Plans
- 🔄 iOS build support
- 📊 Build cache optimization
- 🔧 Custom patch support
- 🌐 Multi-language documentation

## 🤝 Contributing

### Bug Reports
- Submit detailed information via GitHub Issues

### Feature Requests
- Suggest via Discussions tab

### Pull Requests
- Follow: Fork → Branch → Commit → PR workflow

## 🔒 Security & Compliance

- **Post-Quantum Cryptography**: M130 includes PQC preparation
- **Security Patches**: Latest CVE fixes included
- **16KB Page Size**: Full Android 15+ compatibility
- **Secure Build**: All builds from official WebRTC source

## 📄 License

This project is licensed under MIT License. WebRTC itself is under BSD License.

## ⭐ Star this repository!

If this project helped solve your Mac WebRTC build issues (M1, M2, M3, M4, or Intel), please give it a ⭐!

---

**🍎 Built for Mac users across all architectures - from M1 pioneers to M4 early adopters.**

**Universal solution for WebRTC development challenges on macOS.** 

**Need help or have questions? Open an issue!** 💬

## 🛠️ Advanced Usage

For detailed integration examples, troubleshooting, and advanced configurations, check out:

- 📖 [Quick Start Guide](docs/QUICK_START.md) - 5-minute setup
- 🔧 [Android Integration Example](examples/android-integration.md) - Complete code samples
- 📥 [AAR Download Script](scripts/download-latest-aar.sh) - Automated CLI download