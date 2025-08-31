# 🚀 WebRTC Android Builder

**Universal WebRTC Android AAR Build System**

Build WebRTC Android libraries automatically in the cloud using GitHub Actions, eliminating local build complexity and
compatibility issues across all platforms.

## ✨ Key Features

- 🌐 **Universal Platform Support** - Works on all operating systems (Windows, macOS, Linux)
- ☁️ **Zero Local Resources** - No local build environment required
- ⚡ **Fast Cloud Build** - 1.5 hours vs local 4-8 hours
- 🎯 **Latest WebRTC** - M137 (branch-heads/7151) default support
- 📱 **Android Compatibility** - Latest WebRTC features
- 🔄 **Full Automation** - Push, tag, and scheduled builds
- 📦 **Ready to Use** - Direct AAR file download
- 💬 **Slack Integration** - Build notifications with results
- 🛡️ **Security Enhanced** - Latest security patches included

## 🏗️ Build Architecture

### Cloud Build Pipeline

```
┌─────────────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   Any Device (Client)   │───▶│  GitHub Actions  │───▶│   Build Result  │
│                         │    │                  │    │                 │
│ • Windows/macOS/Linux   │    │ • Ubuntu 22.04   │    │ • AAR File      │
│ • Simple Git Push       │    │ • depot_tools    │    │ • Build Info    │
│ • Zero Local Resources  │    │ • WebRTC Source  │    │ • Artifacts     │
└─────────────────────────┘    └──────────────────┘    └─────────────────┘
                                        │
                                        ▼
                               ┌────────────────── ┐
                               │ Slack Notification│
                               │                   │
                               │ • Success/Failure │
                               │ • Download Links  │
                               │ • Build Details   │
                               └────────────────── ┘
```

### Build Process Flow

```
1. 🔄  Trigger from Any Device (Manual/Tag/Schedule)
2. 🖥️  Setup Ubuntu 22.04 Cloud Environment  
3. 🛠️  Install depot_tools & Dependencies
4. 📥  Fetch WebRTC Source (branch-heads/7151)
5. ⚙️  Configure Build (architectures, debug/release)
6. 🔨  Compile AAR (libwebrtc-m137-X.aar)
7. ✅  Verify & Package
8. 📤  Upload Artifacts (Download from Any Device)
9. 💬  Send Slack Notifications
```

### 🌐 **Universal Platform Compatibility**

**Supported Platforms**:
| Platform | Compatibility | Performance | Notes |
|----------|--------------|-------------|-------|
| **Windows** | ✅ Perfect | ⭐⭐⭐⭐⭐ | All versions supported |
| **macOS** | ✅ Perfect | ⭐⭐⭐⭐⭐ | M1/M2/M3/M4 & Intel |
| **Linux** | ✅ Perfect | ⭐⭐⭐⭐⭐ | All distributions |

**Why It Works on All Platforms**:

- **Cloud-Based Build**: All compilation happens on GitHub's Ubuntu runners
- **Local Independence**: Your device only triggers the build and downloads results
- **No Architecture Conflicts**: Eliminates local build environment issues
- **Resource Efficient**: No local memory, disk, or CPU requirements

## 🚀 Quick Start (5 minutes)

### Step 1: Add Action to Workflow

To use this action in your workflow, add the following step to your `.github/workflows/your-workflow.yml` file:

```yaml
- name: Build WebRTC Android AAR
  uses: bentleypark/webrtc-android-builder@v1 # Replace with your username/repo and desired tag/branch
  with:
    webrtc_branch: 'branch-heads/7151' # Default: M137
    target_arch: 'armeabi-v7a,arm64-v8a' # Default: arm64-v8a,armeabi-v7a
    build_config: 'release' # Default: release
    # slack_webhook_url: ${{ secrets.SLACK_WEBHOOK_URL }} # Optional: Uncomment for Slack notifications
    # slack_channel: '#build-notifications' # Optional: Uncomment for Slack notifications
    # enable_slack_notifications: 'true' # Optional: Uncomment for Slack notifications
```

### Step 2: Slack Integration (Optional)

1. Create Slack App and Incoming Webhook in your workspace
2. Copy webhook URL and add to GitHub Repository Settings → Secrets → `SLACK_WEBHOOK_URL`
3. Configure channel name in workflow inputs

### Step 3: Run Build

1. GitHub Repository → **Actions** tab
2. Select **Build WebRTC Android AAR**
3. Click **Run workflow**
4. Configure build options:
    - **WebRTC Branch**: `branch-heads/7151` (M137, latest)
    - **Target Architectures**: `armeabi-v7a,arm64-v8a`
    - **Build Configuration**: `release`
5. Click **Run workflow** button

### Step 4: Download AAR

- After build completion, check **Artifacts** section
- Download `libwebrtc-m137-X.aar` file
- Copy to your Android project's `app/libs/` folder

## 📱 Android Project Integration

### Gradle Configuration (`app/build.gradle`)

```gradle
android {
    compileSdk 35
    
    defaultConfig {
        applicationId "com.yourapp.example"
        minSdk 24        // Modern Android support
        targetSdk 35
        versionCode 1
        versionName "1.0"
    }
    
    compileOptions {
        sourceCompatibility JavaVersion.VERSION_17
        targetCompatibility JavaVersion.VERSION_17
    }
}

dependencies {
    implementation files('libs/libwebrtc-m137-X.aar')  // X = GitHub run number
    
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

```kotlin
import org.webrtc.*
import android.content.Context
import android.util.Log

class WebRTCManager {
    private lateinit var peerConnectionFactory: PeerConnectionFactory

    fun initialize(context: Context) {
        // WebRTC initialization
        PeerConnectionFactory.initialize(
            PeerConnectionFactory.InitializationOptions.builder(context)
                .setEnableInternalTracer(true)
                .createInitializationOptions()
        )

        // Create PeerConnectionFactory
        peerConnectionFactory = PeerConnectionFactory.builder()
            .createPeerConnectionFactory()

        Log.d("WebRTC", "✅ WebRTC initialized successfully!")
    }
}
```

## 📥 Inputs

This action has the following inputs:

| Input                        | Description                                                                               | Default                 | Required |
|------------------------------|-------------------------------------------------------------------------------------------|-------------------------|:--------:|
| `webrtc_branch`              | The WebRTC branch to build (e.g., `branch-heads/7151`, `main`).                           | `branch-heads/7151`     | `false`  |
| `target_arch`                | A comma-separated list of target architectures.                                           | `armeabi-v7a,arm64-v8a` | `false`  |
| `build_config`               | The build configuration, either `release` or `debug`.                                     | `release`               | `false`  |
| `slack_webhook_url`          | The Slack webhook URL for sending build notifications. Must be stored as a GitHub secret. | `N/A`                   | `false`  |
| `slack_channel`              | The Slack channel to send notifications to.                                               | `#build`                | `false`  |
| `enable_slack_notifications` | Set to `true` to enable Slack notifications. Requires `slack_webhook_url` to be set.      | `false`                 | `false`  |

## 📤 Outputs

This action produces the following outputs:

| Output         | Description                                                                         |
|----------------|-------------------------------------------------------------------------------------|
| `aar_filename` | The filename of the generated AAR package (e.g., `libwebrtc-m137-123.aar`). |
| `download_url` | The URL to the GitHub Actions run where the build artifacts can be downloaded.      |
| `build_info`   | A summary of the build information.                                                 |

### Example: Using Outputs

You can use the outputs from this action in subsequent steps of your workflow. To do this, give the build step an `id`.

```yaml
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v3

      - name: Build WebRTC AAR
        id: webrtc_build # Add an ID here
        uses: bentleypark/webrtc-android-builder@v1
        with:
          enable_slack_notifications: 'false'

      - name: Announce AAR URL
        run: |
          echo "Build complete!"
          echo "You can download the artifacts from: ${{ steps.webrtc_build.outputs.download_url }}"
```

## ⚙️ Build Configuration Options

### WebRTC Branch Selection

| Branch              | Version | Recommended Use         |
|---------------------|---------|-------------------------|
| `branch-heads/7151` | M137    | **Production (Latest)** |
| `main`              | Latest  | Experimental            |

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

| Build Environment  | Build Time | CPU/Memory  | Disk Space | Cost          | Platform Compatibility |
|--------------------|------------|-------------|------------|---------------|------------------------|
| **GitHub Actions** | 1.5 hours  | 4 vCPU/16GB | 14GB SSD   | Free*         | **All Platforms** ✅    |
| Local Build        | 4-8 hours  | Varies      | 100GB+     | Power         | Platform Issues ❌      |
| Jenkins (AWS)      | 1.5 hours  | Custom      | Custom     | $30-120/month | All Platforms ✅        |
| Docker Local       | 6-10 hours | Varies      | 100GB+     | Power         | Docker Required ⚠️     |

*Free for public repositories. Private repositories: 2,000 minutes/month (Free), 3,000 minutes/month (Pro/Team)

## 💬 Slack Notifications

### Success Notification

```
🎉 WebRTC Android AAR Build Success!

📋 Build Information:
• Branch: branch-heads/7151
• Architectures: armeabi-v7a,arm64-v8a
• Configuration: release

📦 AAR File: libwebrtc-m137-X.aar

🔗 [Download Artifacts](link)
```

### Failure Notification

```
❌ WebRTC Android AAR Build Failed!

📋 Build Information:
• Branch: branch-heads/7151
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

**Note**: Build failures are independent of your local platform - they occur in the cloud environment, not locally.

### Architecture Errors

```yaml
# Wrong example
target_arch: "armv7,arm64"

# Correct example
target_arch: "armeabi-v7a,arm64-v8a"
```

### Slack Integration Setup

1. **Create Slack App**: Go to https://api.slack.com/apps and create new app
2. **Enable Incoming Webhooks**: Activate in Features → Incoming Webhooks
3. **Add Webhook to Workspace**: Choose target channel and copy webhook URL
4. **Set GitHub Secret**: Repository Settings → Secrets and variables → Actions → New repository secret
    - Name: `SLACK_WEBHOOK_URL`
    - Value: Your webhook URL
5. **Configure Notifications**: Enable in workflow inputs with your channel name

## 📁 Project Structure

```
webrtc-android-builder/
├── .github/
│   └── workflows/
│       └── build-webrtc-android.yml    # Build workflow
├── docs/
│   └── android-integration.md          # Complete integration example
├── scripts/
│   └── download-latest-aar.sh          # CLI download script
├── README.md                           # This file
├── LICENSE                             # License
└── action.yml                          # GitHub Action definition
```

## 📈 Version History

### v1.0.0 (Current - M137)

- ✅ Universal platform support (Windows/macOS/Linux)
- ✅ M137 (branch-heads/7151) support
- ✅ Enhanced security with latest patches
- ✅ Slack build notifications
- ✅ Modern Android compatibility
- ✅ Automatic release system
- ✅ Detailed build information

## 🤝 Contributing

### Bug Reports

- Submit detailed information via GitHub Issues

### Feature Requests

- Suggest via Discussions tab

### Pull Requests

- Follow: Fork → Branch → Commit → PR workflow

## 🔒 Security & Compliance

- **Security Patches**: Latest CVE fixes included
- **Modern Android**: Full Android compatibility
- **Secure Build**: All builds from official WebRTC source
- **H265/HEVC Support**: Advanced video codec features

## 📄 License

This project is licensed under MIT License. WebRTC itself is under BSD License.

## ⭐ Star this repository!

If this project helped solve your WebRTC build issues on any platform, please give it a ⭐!

---

**🌐 Built for developers across all platforms - Windows, macOS, and Linux.**

**Universal solution for WebRTC development challenges.**

**Need help or have questions? Open an issue!** 💬

## 🛠️ Advanced Usage

For detailed integration examples, troubleshooting, and advanced configurations, check out:

- 🔧 [Android Integration Example](docs/android-integration.md) - Complete code samples
- 📥 [AAR Download Script](scripts/download-latest-aar.sh) - Automated CLI download