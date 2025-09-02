# 🚀 WebRTC Android Builder

**GitHub Actions-powered WebRTC Android AAR Build System**

Build WebRTC Android libraries automatically in the cloud using GitHub Actions, eliminating local build complexity and
compatibility issues across all platforms.

## ✨ Key Features

- ☁️ **Zero Local Resources** - No local build environment required
- ⚡ **Cloud Build** - Generally saves several hours (varies by hardware/branch)
- 🎯 **Flexible WebRTC Versions** - Build any WebRTC branch with automatic version detection and latest security patches
- 📦 **Ready to Use** - Direct AAR file download (includes multi-ABI, may require ProGuard/R8/NDK configuration based on
  project setup)
- 💬 **Slack Integration** - Build notifications with results

## 🏗️ Build Architecture

### Cloud Build Pipeline

```
┌─────────────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   Any Device (Client)   │───▶│  GitHub Actions  │───▶│   Build Result  │
│                         │    │                  │    │                 │
│ • Windows/macOS/Linux   │    │ • Ubuntu Latest  │    │ • AAR File      │
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
1. 🔄  Trigger via GitHub Actions Workflow
2. 🖥️  Setup Ubuntu Latest Cloud Environment  
3. 🛠️  Install depot_tools & Dependencies
4. 📥  Fetch WebRTC Source (branch-heads/7258 default)
5. ⚙️  Configure Build (architectures, release optimized)
6. 🔨  Compile AAR (libwebrtc-M{MILESTONE}-{BRANCH}-patched-XX.aar)
7. ✅  Verify & Package
8. 📤  Upload Artifacts for Download
9. 💬  Send Slack Notifications
```

### 🌐 **Universal Platform Compatibility**

**Why It Works on All Platforms**:

- **Cloud-Based Build**: All compilation happens on GitHub's Ubuntu runners (ubuntu-latest = Ubuntu 24.04 as of Jan
  2025) - local systems only trigger workflows and download artifacts
- **Local Independence**: Your device only triggers the build and downloads results
- **No Architecture Conflicts**: Eliminates local build environment issues
- **Resource Efficient**: No local memory, disk, or CPU requirements
- **Runner Stability**: Consider using `runs-on: ubuntu-24.04` for build consistency if package changes cause issues
- **Build Optimization**: Integrated ccache compiler caching and `actions/cache` for optimal build performance and
  reduced minutes consumption

## 🚀 Quick Start (5 minutes)

### Step 1: Add Action to Workflow

To use this action in your workflow, add the following step to your `.github/workflows/your-workflow.yml` file:

```yaml
- name: Build WebRTC Android AAR
  uses: bentleypark/webrtc-android-builder@v1 # Replace with your username/repo and desired tag/branch
  with:
    webrtc_branch: 'branch-heads/7258' # Default: M139 (Current Stable), Options: branch-heads/7339 (M140 Beta), branch-heads/7258 (M139 Stable), branch-heads/7204 (M138 Stable)
    target_arch: 'armeabi-v7a,arm64-v8a' # Default: arm64-v8a,armeabi-v7a
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
    - **WebRTC Branch**: `branch-heads/7258` (M139, stable)
    - **Target Architectures**: `armeabi-v7a,arm64-v8a`
5. Click **Run workflow** button

### Step 4: Download AAR

- After build completion, check **Artifacts** section
- Download AAR file (pattern: `libwebrtc-M{MILESTONE}-{BRANCH}-patched-XX.aar`, example: `libwebrtc-M139-7258-patched-98.aar`)
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
    // Method 1: Direct file reference
    implementation files('libs/libwebrtc-M{MILESTONE}-{BRANCH}-patched-XX.aar')  // example: libwebrtc-M139-7258-patched-98.aar
    
    // Method 2: Using fileTree for multiple AARs
    // implementation fileTree(dir: 'libs', include: ['*.aar'])
    
    // Additional dependencies (if needed)
    implementation 'androidx.appcompat:appcompat:1.6.1'
    implementation 'com.google.android.material:material:1.10.0'
}
```

### ProGuard Rules (`proguard-rules.pro`)

```proguard
# WebRTC library protection (essential rules only)
-keep class org.webrtc.** { *; }
-dontwarn org.webrtc.**

# JNI methods protection
-keepclasseswithmembernames class * {
    native <methods>;
}

# Core WebRTC callbacks
-keep class * implements org.webrtc.PeerConnection$Observer { *; }
-keep class * implements org.webrtc.SdpObserver { *; }
```

## 📥 Inputs

This action has the following inputs:

| Input                        | Description                                                                                             | Default                 | Required |
|------------------------------|---------------------------------------------------------------------------------------------------------|-------------------------|:--------:|
| `webrtc_branch`              | The WebRTC branch to build. Supports branch-heads/XXXX format. Automatically detects milestone version. | `branch-heads/7258`     | `false`  |
| `target_arch`                | A comma-separated list of target architectures.                                                         | `armeabi-v7a,arm64-v8a` | `false`  |
| `slack_webhook_url`          | The Slack webhook URL for sending build notifications. Must be stored as a GitHub secret.               | `N/A`                   | `false`  |
| `slack_channel`              | The Slack channel to send notifications to.                                                             | `#build`                | `false`  |
| `enable_slack_notifications` | Set to `true` to enable Slack notifications. Requires `slack_webhook_url` to be set.                    | `false`                 | `false`  |

## 📤 Outputs

This action produces the following outputs:

| Output         | Description                                                                             |
|----------------|-----------------------------------------------------------------------------------------|
| `aar_filename` | The filename of the generated AAR package. Pattern: `libwebrtc-M{MILESTONE}-{BRANCH}-patched-XX.aar` |
| `download_url` | The URL to the GitHub Actions run where the build artifacts can be downloaded.          |
| `build_info`   | A summary of the build information.                                                     |

## ⚙️ Build Configuration Options

### WebRTC Branch Selection

The action automatically detects the WebRTC milestone version from the branch name and generates dynamic AAR filenames.

**Example Branches** (refer to [Chromium Dash](https://chromiumdash.appspot.com/branches) for current mappings):

| Branch              | Version | Release Status         | AAR Filename Pattern |
|---------------------|---------|------------------------|-----------------------|
| `branch-heads/7339` | M140    | **Beta** (Next Stable) | `libwebrtc-M140-7339-patched-{PATCH}.aar` |
| `branch-heads/7258` | M139    | **Stable** (Current)   | `libwebrtc-M139-7258-patched-{PATCH}.aar` |
| `branch-heads/7204` | M138    | **Stable** (Previous)  | `libwebrtc-M138-7204-patched-{PATCH}.aar` |
| `branch-heads/7151` | M137    | **Stable** (LTS)       | `libwebrtc-M137-7151-patched-{PATCH}.aar` |
| `branch-heads/7103` | M136    | Legacy                 | `libwebrtc-M136-7103-patched-{PATCH}.aar` |

**Dynamic Version Detection**: The action uses Chromium's Gitiles API to fetch exact version information from each branch's VERSION file, ensuring accurate AAR filenames.

**AAR Filename Pattern**: `libwebrtc-M{MILESTONE}-{BRANCH}-patched-XX.aar`
- example: `libwebrtc-M139-7258-patched-98.aar` (M139, branch-heads/7258, patch 98)

### 📊 WebRTC Milestone Reference

Need to find the right branch for your target milestone? Check [Chromium Dash](https://chromiumdash.appspot.com/branches) for official branch-to-milestone mappings and current Chrome release status verification.

**Note**: The patch number (`XX`) in AAR filenames is dynamic and automatically detected from the branch's current VERSION file. This ensures you always get the latest patches and security fixes for each milestone.

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
| **GitHub Actions** | Under 1 hour | 4 vCPU/16GB | 14GB SSD   | Free*         | **All Platforms** ✅    |
| Local Build        | 4-8 hours  | Varies      | 100GB+     | Power         | Platform Issues ❌      |
| Jenkins (AWS)      | 1.5 hours  | Custom      | Custom     | $30-120/month | All Platforms ✅        |
| Docker Local       | 6-10 hours | Varies      | 100GB+     | Power         | Docker Required ⚠️     |

*Public repositories: unlimited free. Private repositories: 2,000 minutes/month (Free plan), 3,000 minutes/month (Team
plan)

## 💬 Slack Notifications

### Success Notification

```
🎉 WebRTC Android AAR Build Success!

📋 Build Information:
• Milestone: M140
• Branch: branch-heads/7339
• Architectures: armeabi-v7a,arm64-v8a
• Configuration: release (optimized)

📦 AAR File: libwebrtc-M{MILESTONE}-{BRANCH}-patched-XX.aar
(example: libwebrtc-M140-7339-patched-15.aar)
🔒 SHA256: a1b2c3d4e5f6789...

🔗 [Download Artifacts](link)
```

### Failure Notification

```
❌ WebRTC Android AAR Build Failed!

📋 Build Information:
• Milestone: M140
• Branch: branch-heads/7339
• Configuration: release (optimized)

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

## 📄 License & Patents

**This Project**: Licensed under [MIT License](LICENSE)

**WebRTC**: Licensed under [BSD-3-Clause License](https://webrtc.org/support/license/)

- Copyright (c) 2011, The WebRTC project authors. All rights reserved.
- Source: [webrtc.org](https://webrtc.org/)
- Additional patent grant: [PATENTS](https://webrtc.googlesource.com/src/+/main/PATENTS)

**Important**: WebRTC includes an additional patent grant that provides protection for users and implementers. The
patent grant terminates if patent litigation is instituted against the WebRTC implementation.

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