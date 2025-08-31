# 🚀 WebRTC Android Builder - 빠른 시작 가이드

## 📋 사전 준비

- GitHub 계정
- Android 프로젝트 (Android Studio)
- 5분의 시간

## 🎯 1단계: 프로젝트 설정 (2분)

### 1-1. 저장소 생성
```bash
# 현재 프로젝트를 GitHub에 업로드
cd webrtc-android-builder
git init
git add .
git commit -m "🚀 Initial WebRTC Android Builder setup"
git branch -M main

# GitHub에서 새 저장소 생성 후
git remote add origin https://github.com/YOUR_USERNAME/webrtc-android-builder.git
git push -u origin main
```

### 1-2. Actions 활성화 확인
- GitHub 저장소 → **Actions** 탭
- "I understand..." 클릭 (처음 한 번만)

## ⚡ 2단계: WebRTC 빌드 실행 (1분 설정, 2.5시간 대기)

### 2-1. 수동 빌드 실행
1. **Actions** 탭 → **Build WebRTC Android AAR** 선택
2. **Run workflow** (우상단 버튼) 클릭
3. 빌드 옵션 설정:

```yaml
WebRTC Branch: branch-heads/6478        # M126 최신 안정 버전
Target Architectures: armeabi-v7a,arm64-v8a  # 현대 기기 지원
Build Configuration: release            # 프로덕션용
Enable 16KB pages: true ✅             # 최신 Android 호환
```

4. **Run workflow** (녹색 버튼) 클릭

### 2-2. 빌드 진행 확인
```
✅ Checkout repository          (30초)
✅ Setup depot_tools            (1분)  
⏳ Fetch WebRTC source         (30분)
⏳ Install dependencies        (20분)
⏳ Build AAR                   (120분)
✅ Upload artifacts            (2분)
```

**총 소요시간: 약 2.5시간** ☕

## 📦 3단계: AAR 다운로드 및 통합 (2분)

### 3-1. AAR 파일 다운로드
1. 빌드 완료 후 Actions 페이지에서
2. **Artifacts** 섹션 → **webrtc-android-aar-...** 다운로드
3. ZIP 파일 압축 해제 → `libwebrtc.aar` 확인

### 3-2. Android 프로젝트에 추가
```bash
# Android Studio 프로젝트에서
mkdir -p app/libs
cp libwebrtc.aar app/libs/
```

### 3-3. Gradle 설정 수정

**app/build.gradle**
```gradle
android {
    compileSdk 34
    
    defaultConfig {
        minSdk 24        // 🔥 16KB 페이지 지원 필수!
        targetSdk 34
    }
}

dependencies {
    implementation files('libs/libwebrtc.aar')  // 🔥 추가
}
```

**proguard-rules.pro**
```proguard
# 🔥 WebRTC 보호 규칙 추가
-keep class org.webrtc.** { *; }
-dontwarn org.webrtc.**
```

### 3-4. 빌드 테스트
```bash
# Android Studio에서 또는 터미널에서
./gradlew clean build
```

## ✨ 완료! 이제 WebRTC 사용 가능

### 기본 사용법
```java
import org.webrtc.*;

public class MainActivity extends AppCompatActivity {
    private PeerConnectionFactory factory;
    
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);
        
        // 🚀 WebRTC 초기화
        initWebRTC();
    }
    
    private void initWebRTC() {
        // PeerConnectionFactory 초기화
        PeerConnectionFactory.initialize(
            PeerConnectionFactory.InitializationOptions.builder(this)
                .createInitializationOptions()
        );
        
        // Factory 생성
        factory = PeerConnectionFactory.builder()
            .createPeerConnectionFactory();
            
        Log.d("WebRTC", "✅ WebRTC initialized successfully!");
    }
}
```

## 🔄 자동화 설정 (선택사항)

### 태그 기반 자동 릴리즈
```bash
# 새 버전 릴리즈시
git tag -a v1.0.0 -m "Production WebRTC AAR"
git push origin v1.0.0

# → GitHub Release 자동 생성! 🎉
```

### 주기적 자동 빌드
- 현재: 매주 일요일 자동 빌드
- 수정하려면 `.github/workflows/build-webrtc-android.yml`의 cron 설정 변경

## 🎯 시나리오별 사용법

### 📱 일반적인 앱 개발
```yaml
WebRTC Branch: branch-heads/6478
Target Arch: armeabi-v7a,arm64-v8a
Build Config: release
16KB Pages: true ✅
```

### 🧪 실험적 기능 테스트
```yaml
WebRTC Branch: main
Target Arch: arm64-v8a
Build Config: debug  
16KB Pages: true ✅
```

### 🏛️ 레거시 지원
```yaml
WebRTC Branch: branch-heads/6312  # M125
Target Arch: armeabi-v7a,arm64-v8a,x86
Build Config: release
16KB Pages: false
```

## ⚠️ 주의사항

### Android 호환성
```gradle
// ❌ 잘못된 설정
minSdk 21   // 16KB 페이지 미지원

// ✅ 올바른 설정  
minSdk 24   // 16KB 페이지 완전 지원
```

### 메모리 사용량
- **GitHub Actions**: 무료로 8GB RAM 제공
- **로컬 빌드**: 16GB+ 메모리 필요

### 빌드 시간
- **첫 빌드**: 2.5시간 (소스 다운로드 포함)
- **후속 빌드**: 빠른 캐싱으로 시간 단축

## 🆘 문제 해결

### 빌드 실패
1. Actions 탭에서 로그 확인
2. 일반적인 원인:
   - 잘못된 브랜치명
   - 네트워크 타임아웃
   - GitHub Actions 용량 부족

### AAR 통합 오류
```bash
# Gradle 동기화 실패시
./gradlew clean
./gradlew build --refresh-dependencies
```

### ProGuard 오류
```proguard
# 추가 규칙이 필요한 경우
-keep class org.webrtc.** { *; }
-keepclassmembers class * {
    @org.webrtc.* <methods>;
}
-dontwarn org.webrtc.**
```

## 📞 도움이 필요하세요?

- 🐛 **버그 리포트**: [GitHub Issues](../../issues)
- 💡 **기능 요청**: [GitHub Discussions](../../discussions)
- 📖 **상세 문서**: `docs/` 폴더 참조

---

**🎉 축하합니다! M1 Mac에서 WebRTC Android 개발이 이제 가능합니다!**

**⏰ 총 소요시간: 5분 설정 + 2.5시간 자동 빌드 = 완료!** ✨