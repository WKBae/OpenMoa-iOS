# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when
working with code in this repository.

## 프로젝트 개요

**OpenMoa**는 삼성 모아키 한국어 입력 방식을 재구현한 오픈소스 iOS 커스텀 키보드 프로젝트입니다.
자음 키를 누른 채 방향으로 드래그하여 모음을 입력하는 제스처 기반 한글 입력 방식을 사용합니다.
기본 한글 자판의 `ㅂㅈㄷㄱㅅㅁㄴㅇㄹㅎ` 키에는 우상단 보조 숫자 `1~9,0`이 표시되며, 길게 누르면 해당 숫자를 바로 입력할 수 있습니다.

- 원본 Android 버전 저장소: `https://github.com/AiOO/OpenMoa`
- 호스트 앱 번들 ID: `pe.aioo.openmoa.ios`
- 키보드 익스텐션 번들 ID: `pe.aioo.openmoa.ios.keyboard`

## 빌드 및 테스트 명령어

```bash
# 공유 한글 조합 엔진 유닛 테스트
swift test

# iOS 호스트 앱 빌드
xcodebuild -project OpenMoa.xcodeproj \
  -target OpenMoaKeyboardHost \
  -sdk iphonesimulator \
  CODE_SIGNING_ALLOWED=NO build

# 키보드 익스텐션 빌드
xcodebuild -project OpenMoa.xcodeproj \
  -target OpenMoaKeyboardExtension \
  -sdk iphonesimulator \
  CODE_SIGNING_ALLOWED=NO build
```

공유 조합 엔진 테스트는 SwiftPM의 `Tests/OpenMoaKeyboardCoreTests`를 실행합니다.

## 아키텍처

### 핵심 레이어

**1. 키보드 익스텐션 (`KeyboardExtension/`)**

- `KeyboardViewController`: `UIInputViewController`를 상속한 메인 진입점
- `textDocumentProxy`를 통해 텍스트 입력, 삭제, 커서 이동 수행
- `KeyboardViewModel`과 연결되어 키보드 모드와 조합 중 문자열 상태를 반영

**2. 한글 조합 엔진 (`Sources/OpenMoaKeyboardCore/`)**

- `HangulAssembler`: 자음·모음 조합, 복합 자음/모음 처리
- `MoeumGestureProcessor`: 제스처 시퀀스를 모음으로 변환
- `HangulUnicode`: 한글 유니코드 조합 유틸리티

**3. 뷰 레이어 (`KeyboardExtension/KeyboardView.swift`, `App/`)**

- `KeyboardView`: SwiftUI 기반 키보드 레이아웃
- `NextKeyboardButton`: 시스템 키보드 전환 버튼 브리지
- 기본 한글 레이아웃의 `ㅂㅈㄷㄱㅅㅁㄴㅇㄹㅎ` 키는 우상단 숫자 힌트를 표시하고, 길게 누르면 숫자 입력으로 동작함
- 기본 한글 레이아웃의 `.,?!` 키는 상/하/좌/우 스와이프 방향을 보이도록 4방향 배치로 표시됨
- `ContentView`: 호스트 앱에서 키보드 활성화 방법과 iOS 제약사항 안내

**4. 상태 관리 계층 (`KeyboardViewModel.swift`)**

- `KeyboardViewModel`: 모든 입력 상태의 중심
- `Mode`: 한국어/문장부호/숫자/전화번호패드 + 이모지
- 입력 필드의 `UIKeyboardType`에 따라 숫자/전화번호 패드 모드 강제 전환

### 한글 입력 플로우

1. 사용자가 한국어 키를 탭하거나 드래그하고, 일부 자음 키는 길게 눌러 숫자를 입력할 수 있음
2. `KeyboardView`가 입력 이벤트를 `KeyboardViewModel`에 전달함
3. `MoeumGestureProcessor`가 제스처 시퀀스를 모음으로 변환함
4. `HangulAssembler`가 자음+모음을 조합해 조합 중 문자열을 계산함
5. `KeyboardViewController`가 `textDocumentProxy`를 통해 조합 문자열을 교체하거나 확정 입력함

### 키보드 모드 확장 시 주의사항

`KeyboardViewModel.Mode`에 새 항목을 추가하면 관련 분기에도 함께 케이스를 추가해야 합니다.
누락 시 모드 전환은 되더라도 복귀 경로 또는 특정 키 레이아웃이 깨질 수 있습니다. 대상 위치:

- `Mode.isNumber`, `Mode.isPhone`
- `toggleHanjaNumberPunctuationMode()`
- 숫자/전화번호 패드 강제 모드 복귀 로직
- `KeyboardView` 내 레이아웃 분기

현재 하단 `!#1` 키는 `korean -> punctuation -> number -> korean` 순으로 순환합니다.
`emoji`와 `phone` 같은 보조 모드는 이 순환에 직접 포함되지 않으므로,
복귀 시 어떤 기본 모드로 돌아갈지 함께 확인하는 편이 안전합니다.

### 메시지 시스템

키 입력은 Android처럼 브로드캐스트하지 않고 `KeyboardView` → `KeyboardViewModel` →
`KeyboardViewController` 순으로 전달됩니다.

- `KeyboardView`: 터치/드래그 입력 수집
- `KeyboardViewModel`: 조합 상태 및 편집 액션 결정
- `KeyboardViewModelDelegate`: 실제 텍스트 삽입, 삭제, 커서 이동 수행

### 설정

프로젝트 설정은 주로 Xcode 프로젝트와 plist에 정의되어 있습니다.

- `OpenMoa.xcodeproj/project.pbxproj`: 타깃, 번들 ID, 빌드 설정
- `Config/HostApp-Info.plist`: 호스트 앱 정보
- `Config/KeyboardExtension-Info.plist`: 키보드 익스텐션 정보
- `Settings.bundle/Root.plist`: 설정 앱에 노출되는 키보드 레이아웃 및 보조 키 설정
- `KeyboardExtension/KeyboardPreferences.swift`: 앱 그룹 `UserDefaults`를 통해 설정값을 읽는 헬퍼
- `RequestsOpenAccess`: 현재 `false`

현재 설정 앱에서 다음 항목을 조정할 수 있습니다.

- 세로 키보드 높이
- 가로 키보드 너비
- 가로 키보드 높이
- 한글 키보드 좌측 보조 키 4개 문자
- 스페이스 왼쪽 하단 보조 키 문자

## 주요 파일 위치

| 파일 | 역할 |
|------|------|
| `KeyboardExtension/KeyboardViewController.swift` | 메인 키보드 익스텐션 컨트롤러 |
| `KeyboardExtension/KeyboardViewModel.swift` | 키보드 상태 및 입력 처리 |
| `KeyboardExtension/KeyboardView.swift` | SwiftUI 키보드 레이아웃 |
| `KeyboardExtension/KeyboardPreferences.swift` | 설정 앱 값 로드 및 기본값 처리 |
| `KeyboardExtension/NextKeyboardButton.swift` | 다음 키보드 버튼 브리지 |
| `Sources/OpenMoaKeyboardCore/HangulAssembler.swift` | 한글 자모 조합 엔진 |
| `Sources/OpenMoaKeyboardCore/MoeumGestureProcessor.swift` | 제스처→모음 변환 |
| `Sources/OpenMoaKeyboardCore/HangulUnicode.swift` | 한글 유니코드 조합 유틸리티 |
| `App/ContentView.swift` | 호스트 앱 안내 화면 |
| `Config/KeyboardExtension-Info.plist` | 키보드 익스텐션 설정 |
| `Settings.bundle/Root.plist` | 설정 앱에 표시되는 환경설정 항목 |
| `Package.swift` | 공유 코어 모듈과 테스트 타깃 정의 |
