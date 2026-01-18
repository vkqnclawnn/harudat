
---

# 📘 [통합 마스터 가이드] Windows 개발자를 위한 iOS 배포 & 위젯 연동 표준 매뉴얼

이 가이드는 맥북 없이 **Windows + Codemagic VNC** 환경에서 iOS 앱(위젯 포함)을 개발하고 스토어에 배포하는 **표준 절차(Standard Operating Procedure)**입니다.

---

### 0단계: Apple Developer 사전 설정 (집 컴퓨터) 🏗️

**Xcode에서 체크박스를 누르기 전에, 애플 서버에 '공용 사물함(App Group)'을 먼저 만들어야 합니다.**

1. **Apple Developer 사이트 > Identifiers** 이동.
2. 오른쪽 위 필터를 **App Groups**로 변경 > `+` 버튼 클릭.
3. **Identifier:** `group.[내앱패키지명].ddot` (예: `group.com.vkqnclawnn.ddot`) 입력 후 등록.
4. 다시 **App IDs**로 돌아와서:
* **메인 앱 ID** 클릭 > App Groups 탭 > 방금 만든 그룹 **체크(✅)** > Save.
* **위젯 앱 ID** 클릭 > App Groups 탭 > 방금 만든 그룹 **체크(✅)** > Save.



---

### 1단계: 코드 준비 & VNC 시작 (집 컴퓨터) 🎒

1. **코드 정리 및 업로드:**
VS Code 터미널에서 현재까지 작업한 내용을 깃허브에 올립니다.
```powershell
git add .
git commit -m "Ready for VNC work"
git push origin main

```


2. **Codemagic VNC 시작:**
* Codemagic > Start new build.
* **Enable remote access (VNC)** 체크 필수.
* 빌드 시작 후 IP/Port/Password가 나올 때까지 대기.



---

### 2단계: VNC 접속 & Xcode 작업 (Mac 환경) 🍎

**여기가 핵심 수술실입니다. 위젯을 만들고 '빌드 순서'를 교정합니다.**

1. **Xcode 실행:**
* 하단 Dock의 Finder > `clone` > `ios` > **`Runner.xcworkspace`** 실행.


2. **위젯 타겟 생성:**
* File > New > Target > **Widget Extension**.
* Product Name: `[위젯이름]` (예: `ddotWidget`) 입력.
* **Include Configuration Intent** 체크 해제 > Finish > Activate.


3. **App Groups 연결 (데이터 통로):**
* **[Runner 타겟]** Signing & Capabilities > `+ App Groups` > `group.[...].ddot` 체크.
* **[위젯 타겟]** Signing & Capabilities > `+ App Groups` > `group.[...].ddot` 체크.
* *(0단계에서 만들어놔서 에러 없이 체크됩니다)*


4. **🚨 빌드 순서 수정 (★핵심 필살기):**
* 왼쪽 파일 트리에서 파란색 **Runner** 아이콘 클릭.
* 오른쪽 화면에서 **TARGETS > Runner** 선택.
* 상단 탭 **Build Phases** 클릭.
* 리스트에 있는 **`Embed Foundation Extensions`** 항목을 마우스로 잡고 드래그하여 **`Copy Bundle Resources` 바로 밑**으로 옮깁니다.


**[정답 순서 확인]**
1. Copy Bundle Resources
2. **Embed Foundation Extensions** (👈 여기가 명당입니다!)
3. Embed Frameworks
4. Thin Binary
5. [CP] Embed Pods Frameworks


> **논리:** 위젯을 먼저 넣고(Embed) → 나서 다듬어라(Script)


5. **저장:** `Cmd + S`로 저장하고 VNC 터미널을 엽니다.

---

### 3단계: 작업물 회수 (Mac → Windows) 📦

수술이 끝난 코드를 압축해서 윈도우로 보냅니다.

1. **VNC 터미널:**
```bash
cd ~/clone
zip -r WidgetWork.zip ios

```


2. **파일 전송:** Send Anywhere([send-anywhere.com](https://send-anywhere.com)) 등을 통해 `WidgetWork.zip`을 윈도우로 전송.

---

### 4단계: 코드 병합 & 깃허브 반영 (집 컴퓨터) ✅

1. 프로젝트 폴더에서 기존 `ios` 폴더 **삭제**.
2. 가져온 `WidgetWork.zip` 압축을 풀고, 그 안의 `ios` 폴더로 **교체**.
3. **Git Push:**
```powershell
git add ios
git commit -m "Add Widget & Fix Build Phases Order"
git push origin main

```



---

### 5단계: 인증서(.p12) & 프로파일 발급 (PowerShell 범용) 🔐

**이 과정은 앱을 처음 배포할 때 딱 한 번만 수행하면 됩니다.** (윈도우 기본 터미널 사용)

#### 0. 사전 준비 (OpenSSL 확인)

PowerShell을 실행하고 아래 명령어를 입력해 OpenSSL이 설치되어 있는지 확인합니다.

```powershell
openssl version

```

* 버전 정보가 뜨면 **통과**.
* 에러가 뜨면 설치: `winget install -e --id ShiningLight.OpenSSL.Light` 입력 후 엔터. (설치 완료 후 터미널 재실행)

#### 1. 작업 공간 생성 (바탕화면)

바탕화면에 인증서 작업을 위한 임시 폴더(`iOS_Build_Keys`)를 만들고 이동합니다.

```powershell
$work="$env:USERPROFILE\Desktop\iOS_Build_Keys"
New-Item -ItemType Directory -Force -Path $work | Out-Null
Set-Location $work

```

#### 2. 비밀키(.key) & 요청서(CSR) 생성

암호화의 핵심인 키와 요청서를 생성합니다. (국가 코드는 `KR`로 고정)

```powershell
openssl genrsa -out private_key.key 2048
openssl req -new -key private_key.key -out request.csr -subj "/C=KR"

```

👉 **확인:** 폴더에 `request.csr`, `private_key.key` 파일 생성 확인.

#### 3. 애플 사이트에서 인증서(.cer) 발급

[Apple Developer Certificates](https://www.google.com/search?q=https://developer.apple.com/account/resources/certificates/list) 페이지로 이동.

1. `+` 버튼 > **iOS Distribution (App Store and Ad Hoc)** 선택.
2. `request.csr` 업로드 > **Download**.
3. 다운로드된 파일을 `iOS_Build_Keys` 폴더로 이동하고 이름을 **`distribution.cer`**로 변경.

#### 4. 배포용 인증서(.p12) 변환 (핵심 작업)

다시 PowerShell로 돌아와서 변환합니다.

1. **포맷 변환 (.cer → .pem):**
```powershell
openssl x509 -in distribution.cer -inform DER -out distribution.pem -outform PEM

```


2. **최종 합체 (.p12 생성):**
```powershell
openssl pkcs12 -export -inkey private_key.key -in distribution.pem -out distribution.p12

```


* 🔑 **비밀번호 설정:** `Enter Export Password:` 메시지가 나오면 **기억하기 쉬운 비밀번호(예: 1234)** 입력.



👉 **결과:** 폴더에 **`distribution.p12`** 파일 생성 완료.

#### 5. 프로비저닝 프로파일 생성 (웹사이트)

[Apple Developer Profiles](https://www.google.com/search?q=https://developer.apple.com/account/resources/profiles/list) 페이지로 이동.

1. **[메인 앱용 프로파일]**
* `+` 버튼 > **App Store** > 메인 App ID 선택 > **방금 만든 인증서** 선택.
* Profile Name: `[앱이름]_AppStore_Main` > Download.


2. **[위젯용 프로파일]**
* `+` 버튼 > **App Store** > 위젯 App ID 선택 > **동일한 인증서** 선택.
* Profile Name: `[앱이름]_AppStore_Widget` > Download.



#### 6. 결과물 확인 🎒

`iOS_Build_Keys` 폴더에 다음 3개가 있어야 합니다.

1. ✅ **`distribution.p12`** (Codemagic 업로드용)
2. ✅ **`[앱이름]_AppStore_Main.mobileprovision`**
3. ✅ **`[앱이름]_AppStore_Widget.mobileprovision`**

---

### 6단계: Codemagic 최종 설정 & 빌드 🏁

1. Codemagic > App settings > **Code signing > iOS** 이동.
2. **Manual** 모드 선택.
3. **Code signing certificate:** 5단계에서 만든 **`distribution.p12`** 업로드 (비밀번호 입력).
4. **Provisioning profiles:** 5단계에서 받은 **프로파일 2개** 모두 업로드.
5. **매핑(짝짓기):**
* 메인 번들 ID ↔ `..._Main` 프로파일
* 위젯 번들 ID ↔ `..._Widget` 프로파일


6. **Save** 버튼 클릭.
7. **Start new build** 클릭 (이제 VNC 체크할 필요 없음!).

---

