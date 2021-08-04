# 💬 Duet 💬

> 회원들 간 실시간 채팅 어플리케이션 개발
<br>

기간 : 2021.07.13 ~ 07.31 <br>
개발환경 : Xcode 12.5, GitHub, CocoaPods <br>

사용 언어 및 기술 : `Swift5`, `Storyboard`, `Data Task`, `URLSession`, `NotificationCenter`, `GCD`, `Firebase Auth`, `Firebase Database(real time)`, `Firebase Storage`, `FBSDKCoreKit`, `JGProgressHUD`, `MessageKit`, `SDWebImage`<br>
 
------------------------------------------------------------------------

<br>


## 📱 기능 동작 - 실시간 채팅
<img width="46%" src="https://github.com/naldal/readmegifs/blob/master/register,registerImage,facebook%20login/chatSend.gif?raw=true"/>|<img width="46%" src="https://github.com/naldal/readmegifs/blob/master/register,registerImage,facebook%20login/chatreceive.gif?raw=true"/>

<br><br>

-------------------

<br>
<br>
<br>

## 📋 프로젝트 상세내용
 
### 📍 주제
```
  * 회원들 간의 실시간 채팅 어플리케이션
```
<br>
 
### ⭐ 개발목적
```
 
  * CocoaPods 활용

    - 페이스북 로그인 지원과 MessageKit 활용, JGProgessHUD를 이용한 Activity Indicator View 구현

  * Firebase 활용

    - Firebase를 사용하여 일반 로그인 및 페이스북 로그인 프로세스 구현, 사용자의 프로필 정보 저장, 채팅 기록 저장 및 실시간 채팅 구현
 
```
<br>
 
### 💻 구현목표
```

  * FBSDKCoreKit을 이용한 페이스북 로그인 구현

  * Firebase Auth를 이용한 일반 회원가입 및 로그인 구현

  * Firebase Database, Firebase Storage를 이용한 회원 프로필 (이름, 이메일, 회원사진)

  * 회원 이름 검색 후 채팅창 이동

  * 실시간 채팅 구현
  
  * 기능 모듈화

    - DatabaseManager, StorageManager 클래스를 만들어 firebase database 및 firebase storage 기능 전담
  
```
<br>

### ✍🏻 제작과정

   - [x] [Firebase 를 이용한 회원가입과 프로필 사진 등록](https://codecrafting.tistory.com/47) <br> 
   - [x] [데이터 검색기능 구현 Firebase Database](https://codecrafting.tistory.com/48) <br>
   - [x] [회원 사진 불러오기 Firebase Storage](https://codecrafting.tistory.com/51) <br>
   - [ ] 실시간 채팅 기능 구현 Firebase Database (작성중)

<br>
<br>
<br>

-------------------

## 📱 기능 동작 - 페이스북 로그인
<img width="42%" src="https://github.com/naldal/readmegifs/blob/master/register,registerImage,facebook%20login/facebook%20login.gif?raw=true"/>

<br>

## 📱 기능 동작 - 회원가입
<img width="42%" src="https://github.com/naldal/readmegifs/blob/master/register,registerImage,facebook%20login/registerImage.gif?raw=true"/>

<br>

## 📱 기능 동작 - 일반 로그인
<img width="42%" src="https://github.com/naldal/readmegifs/blob/master/register,registerImage,facebook%20login/login.gif?raw=true"/>

<br>

