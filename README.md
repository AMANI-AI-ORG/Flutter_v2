# Amani low level SDK bindings for flutter
This repository contains flutter bindings for our [Android](https://github.com/AmaniTechnologiesLtd/Android_SDK_V2_Public) and [iOS](https://github.com/AmaniTechnologiesLtd/IOS_SDK_V2_Public) SDK's.

On the [example folder](https://github.com/AmaniTechnologiesLtd/Flutter_v2/tree/main/example) you can find a close to real world solution on how to use this SDK.

### Requirements
- iOS 11 or later (13 for NFC Capture)
- Android API 21 or later
- Flutter 2.12.0 or later

## Table of Contents
- [Installation](#installation)
    - [Android changes](#android-changes)
    - [Android proguard](#android-proguard-rules) 
    - [iOS changes](#ios-changes)
    - [iOS Permissions](#ios-permissions)
    - [Adding the flutter plugin](#adding-the-flutter-plugin)
- [Usage](#usage)
    - [Upload source](#upload-source)
    - [ID Capture module](#idcapture-module)
    - [Selfie module](#selfie-module)
    - [Auto selfie module](#autoselfie-module)
    - [Pose estimation module](#pose-estimation-module)
    - [NFC Capture](#nfc-capture)
        - [NFC Capture on Android](#nfc-capture-on-android)
        - [NFC Capture on iOS](#nfc-capture-on-ios)
    - [Bio login](#bio-login)
    - [Getting the Customer Info]()
 - [F.A.Q](#faq)
## Installation
Before installing this SDK we must meet some requirements for your app to build with our native SDK's.

### Android changes
#### Adding the native Android SDK
On your apps `build.gradle` file, add our repository
```groovy
rootProject.allprojects {
    repositories {
        google()
        mavenCentral()
        maven { url "https://jfrog.amani.ai/artifactory/amani-sdk" }
        jcenter()
    }
}
```

On the same file add our SDK to dependencies
```groovy
dependencies {
    implementation 'ai.amani.android:AmaniAi:3.4.4' // add this line
}
```

Add this block to `android` section on your `build.gradle`.
```groovy 
  aaptOptions {
    noCompress "tflite"
}
```

#### Android Proguard Rules
Add this into your proguard-rules.pro
```
-keep class ai.amani.flutter_amanisdk
-keep class ai.** {*;}
-dontwarn ai.**
-keep class datamanager.** {*;}
-dontwarn datamanager.**
-keep class networkmanager.** {*;}
-dontwarn networkmanager.**

-keep class org.jmrtd.** {*;}
-keep class net.sf.scuba.** {*;}
-keep class org.bouncycastle.** {*;}
-keep class org.spongycastle.** {*;}
-keep class org.ejbca.** {*;}

-dontwarn org.ejbca.**
-dontwarn org.bouncycastle.**
-dontwarn org.spongycastle.**
-dontwarn org.jmrtd.**
-dontwarn net.sf.scuba.**

-keep class org.tensorflow.lite**{ *; }
-dontwarn org.tensorflow.lite.**
-keep class org.tensorflow.lite.support**{ *; }
-dontwarn org.tensorflow.lite.support**
```

#### Changing main activity type

For this Flutter Plugin to work, you must change your MainActivity class to implement `FlutterFragmentActivity`. \
**This change is required otherwise you'll have runtime issues.**

Example MainActivity.kt
```kotlin
package ai.amani.flutter_amanisdk_v2_example

import io.flutter.embedding.android.FlutterFragmentActivity

class MainActivity: FlutterFragmentActivity() {
}
```

#### Update your AndroidManifest.xml

You must add `tools:replace="android:label"` on your main android manifest file.

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    xmlns:tools="http://schemas.android.com/tools" # this line must be added
    package="ai.amani.amanisdk_example">
	<application
        android:label="amanisdk_example"
        android:name="${applicationName}"
        tools:replace="android:label, android:name" #this line must be added
        android:icon="@mipmap/ic_launcher">
        <activity
            android:name=".MainActivity"
            android:exported="true"
            android:launchMode="singleTop"
            android:theme="@style/LaunchTheme"
            tools:replace="android:theme" 
            android:configChanges="orientation|keyboardHidden|keyboard|screenSize|smallestScreenSize|locale|layoutDirection|fontScale|screenLayout|density|uiMode"
            android:hardwareAccelerated="true"
            android:windowSoftInputMode="adjustResize">
```

### iOS changes

Add these lines on your pod file
```ruby
source "https://github.com/AmaniTechnologiesLtd/Mobile_SDK_Repo"
source "https://github.com/CocoaPods/Specs"
```

If not yet set the default iOS version to 13
```ruby
 platform :ios, '13.0'
 ```

### iOS permissions

You have to add these permissions into your `info.plist` file. All permissions are required for app submission according to your usage.

For NFC:

```xml
    <key>com.apple.developer.nfc.readersession.iso7816.select-identifiers</key>
	<array>
		<string>A0000002471001</string>
	</array>
	<key>NFCReaderUsageDescription</key>
	<string>This application requires access to NFC to  scan IDs.</string>
```

For Location:

```xml
	<key>NSLocationWhenInUseUsageDescription</key>
	<string>This application requires access to your location to upload the document.</string>
	<key>NSLocationUsageDescription</key>
	<string>This application requires access to your location to upload the document.</string>
	<key>NSLocationAlwaysUsageDescription</key>
	<string>This application requires access to your location to upload the document.</string>
	<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
	<string>This application requires access to your location to upload the document.</string>
```

For Camera:

```xml
	<key>NSCameraUsageDescription</key>
	<string>This application requires access to your camera for scanning and uploading the document.</string>
```

**Note**: You need to add all keys according to your usage.

#### **Grant access to NFC**

Enable the Near Field Communication Tag Reading capability in the target Signing & Capabilities.

#### Building for devices that don’t support NFC

For the devices that don’t support NFC (like iPhone 6), there is no CoreNFC library in the system and we are also using some iOS crypto libraries for reading NFC data supported after iOS 13. You need to add libraries below as optional under the Build Phases->Link Binary With Libraries menu. Even if you don't use the NFC process, you should add this libraries below.

```
CoreNFC.framework
CryptoKit.framework
CryptoTokenKit.framework
```

### Adding the flutter plugin 
To add this flutter plugin you must add the lines below to your `pubspec.yaml` file.

```yaml
flutter_amanisdk_v2:
  git:
    url: https://github.com/AmaniTechnologiesLtd/Flutter_v2
    branch: feat/v3
```

## Usage
Modules uses the same pattern of containing `start`, `setType` and `upload` methods. Each `start` method can have different parameters.

Before using any of the modules, you **must** initalize the SDK. This method needs to be called only **once** unless you have some other plugin that starts it's own activity.
```dart
final AmaniSDK _amaniSDK = AmaniSDK();

bool initSuccess = await AmaniSDK.initAmani(
          server: "https://server.example",
          customerToken: "customer_token",
          customerIdCardNumber: "customer_id_card_number",
          lang: "tr",
          useLocation: true,
          sharedSecret: "optional shared secret"  
).catchError((err) {
    // TODO: Handle the error.
})

if(initSuccess) {
    // Call the any of the modules
    IdCapture idCaptureModule = AmaniSDK.getIdCapture();
    idCaptureModule.setType("XXX_ID_0");
} else {
    throw Exception("Failed to initialize AmaniSDK");
}
```

#### Registering the event callbacks

For getting the errors from this SDK, and getting information about the profile of the KYC as well as getting the
step results as the steps updated, you must set delegate callbacks.

First let's create the functions that are required.

```dart
// continued from the previous code block
void amaniOnError(String errorType, List<dynamic> errors) {
    print(errorType);
    print(errors);
  }

  void amaniOnProfileStatus(Map<String, dynamic> profileStatus) {
    print(profileStatus);
  }

  void amaniOnStepResult(List<dynamic> stepResult) {
    print(stepResult);
  }
```

Call the `setDelegateMethods` with function with the functions you just created.

```dart
AmaniSDK().setDelegateMethods(
  amaniOnError, amaniOnProfileStatus, amaniOnStepResult);
```

### Upload source
The upload source tells the Amani server which flow the uploaded documents belong to. It defaults to `AmaniUploadSource.kyc`. Available values are `kyc`, `video` and `password`.

Two methods work on both Android and iOS:

| Method | Argument | Use for |
|---|---|---|
| `setUploadSource` | `AmaniUploadSource` | The values in the enum (recommended) |
| `setUploadSourceString` | `String` | Values that the enum does not cover |

`setUploadSourceString` passes the string to the native SDK unchanged, without validating it. Each native SDK expects its own spelling, for example `"Video"` on Android and `"VIDEO"` on iOS.

The SDK init methods overwrite the upload source, so call either method after them:

| Platform | When to call |
|---|---|
| Android | After `setConfigure`, before `startAmaniSDKWithConfigure` |
| iOS | After `initAmani` or `initAmaniWithEmail` |

On Android, `setConfigure(uploadSource: ...)` also takes the upload source directly. `initAmani` always configures the SDK with `kyc`. A value you set after `initAmani` only applies to uploads made after login.

On iOS, `initAmani` and `initAmaniWithEmail` reset the upload source to `kyc`. A value set before them is discarded, so set it again after every re-init.

```dart
import 'dart:io';
import 'package:flutter_amanisdk/amani_sdk.dart';
import 'package:flutter_amanisdk/amaniAndroidConfigure.dart'; // AmaniUploadSource

final amani = AmaniSDK();

// 1. Platform-specific init
if (Platform.isAndroid) {
  await amani.setConfigure(server: "https://server.example");
} else if (Platform.isIOS) {
  await amani.initAmani(
    server: "https://server.example",
    customerToken: "customer_token",
    customerIdCardNumber: "customer_id_card_number",
    lang: "tr",
    useLocation: true,
  );
}

// 2. Shared: one call works on both platforms
await amani.setUploadSource(AmaniUploadSource.video);

// 3. Android only: start the session
if (Platform.isAndroid) {
  await amani.startAmaniSDKWithConfigure(token: "profile_token", id: "id_number");
}
```

For a value outside `AmaniUploadSource`, call `setUploadSourceString` in step 2 instead, using each native SDK's own spelling:

```dart
await amani.setUploadSourceString(Platform.isIOS ? "PHONE_UPDATE" : "Phone_update");
```

### IDCapture module
Get the id capture module from the main `AmaniSDK` [instance which you have previously initialized.](#usage)

```dart
final AmaniSDK _amaniSDK = AmaniSDK();

// Since the platform plugins are async, you must create this function
Future<void> initSDK() async {
    var idCapture = _amaniSDK.getIdCapture();
    await idCapture.setType("XXX_ID_0");
}

//And call it here.
@override
void initState() {
    super.initState();
    initSDK();
}

```

Later on the buttons `onPressed` 
```dart
onPressed: () async {
            final Uint8List imageData =
                await _flutterAmanisdkV2Plugin.getIDCapture().start(IdSide.front);
            // Do something with imageData
            setState(() {
                _imageData = imageData;
            });
          },
```

After getting the image data from the SDK, you can use it with `Image.memory()`.

### Capturing the NFC Data on iOS
ID Capture module has it's own NFC method on iOS for making things easier. To call it you must have captured the both front and back sides of the id since **capturing NFC data requires information can be extracted from the MRZ data.**

```dart
// After capturing the front and back side on the IdCapture
// Before calling upload
void iosStartNFCCapture() {
    if (Platform.isIOS) {
        _idCapture.startNFC().then((isNFCCaptureDone) {
            if (isNFCCaptureDone) {
                // nfc capture completed
                // You can safely proceed to upload.
            } else {
                startNFCCapture();
            }
        }).catchError((err) {
            // handle the error
        });
    }
}
```

### Capturing the NFC data after the ID Capture on Android
On android, you must do the following steps to capturing the NFC data after the side that containing the MRZ is captured from the camera
```dart
// After capturing the front and back side on the IdCapture
// Before calling upload
void androidStartNFCCapture() {
  // setAndroidUsesNFC sets a state on the NFCCaptureModule to get the MRZ Data from ID itself.
  _idCapture.setAndroidUsesNFC(true).then(() {
    _nfcCapture.startNFCListener(
      onFinishedCallback: (isCaptureCompleted) {
        // Capture is completed you can upload
        setState(() {
          _NFCCompleted = isCaptureCompleted;
          _nfcCapture.stopNFCListener();
        });
      },
      onErrorCallback: (errorString) {
        // handle the read errors here 
      },
      onScanStart: () {
        // This callback will be invoked when an NFC tag found
      }
    )
  }).catchError((err) {
    // Handle the intialization errors here
  });
}
```

> Using the `setAndroidUsesNFC` doesn't require you to call the setType on the AndroidNFCCapture module.

### Note
> If you want to use the NFC as a document please check out [this section.](#nfc-capture)

### Selfie Module
Get the selfie module from the main `AmaniSDK` [instance which you have previously initialized.](#usage)

```dart
final AmaniSDK _amaniSDK = AmaniSDK();

// Since the platform plugins are async, you must create this function
Future<void> initSelfie() async {
    var selfie = _amaniSDK.getSelfie();
    await selfie.setType("XXX_SE_0");
}

//And call it here.
@override
void initState() {
    super.initState();
    initSelfie();
}
```

Later on the buttons `onPressed` 
```dart
onPressed: () async {
            final Uint8List imageData =
                await _amaniSDK().getSelfie().start();
            // Do something with imageData
            setState(() {
                _imageData = imageData;
            });
          },
```

After getting the image data from the SDK, you can use it with `Image.memory()`.

### Auto selfie module

#### Changing the colors on Android
You must add a resource file on Android for AutoSelfie colors. You can find the keys in the example below.

To create this file, open the project on Android Studio right click on the `res` directory and create new Android Resource file. While creating select the "Resource Type" to values.

After that modify the file as shown below.
**note:** pose estimation module has different set of keys that you can add. If you want to use pose estimation while using the auto selfie merge the files.
```xml
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <color name="auto_selfie_text">#000000</color>
    <color name="auto_selfie_counter_text">#000000</color>
    <color name="auto_selfie_oval_view">#000000</color>
    <color name="auto_selfie_success_anim">#000000</color>
</resources>
```

#### Auto selfie usage
Get the auto selfie module from the main `AmaniSDK` [instance which you have previously initialized.](#usage)
```dart
final AmaniSDK _amaniSDK = AmaniSDK();

// Configure the AutoSelfie
final IOSAutoSelfieSettings _iOSAutoSelfieSettings = IOSAutoSelfieSettings(
      faceIsOk: "Please hold stable",
      notInArea: "Please align your face with the area",
      faceTooSmall: "Your face is in too far",
      faceTooBig: "Your face is in too close",
      completed: "All OK!",
      appBackgroundColor: "000000",
      appFontColor: "ffffff",
      primaryButtonBackgroundColor: "ffffff",
      ovalBorderSuccessColor: "00ff00",
      ovalBorderColor: "ffffff",
      countTimer: "3",
      manualCropTimeout: 30);

final  AndroidAutoSelfieSettings _androidAutoSelfieSettings =
      AndroidAutoSelfieSettings(
          textSize: 16,
          counterVisible: true,
          counterTextSize: 21,
          manualCropTimeout: 30,
          distanceText: "Please align your face with the area",
          faceNotFoundText: "No faces found",
          restartText: "Process failed, restarting...",
          stableText: "Please hold stable");

// Since the platform plugins are async, you must create this function
Future<void> initAutoSelfie() async {
    var selfie = _amaniSDK.getAutoSelfie();
    await selfie.setType("XXX_SE_0");
}

//And call it here.
@override
void initState() {
    super.initState();
    initAutoSelfie();
}
```

Later on the buttons `onPressed` 
```dart
onPressed: () async {
            final Uint8List imageData =
                await _amaniSDK().getAutoSelfie().start(
                    iosAutoSelfieSettings: _iOSAutoSelfieSettings,
                    androidAutoSelfieSettings: _androidAutoSelfieSettings,
                );
            // Do something with imageData
            setState(() {
                _imageData = imageData;
            });
          },
```

### Pose estimation module

#### Changing the colors on Android
You must add a resource file on Android for AutoSelfie colors. You can find the keys in the example below.

To create this file, open the project on Android Studio right click on the `res` directory and create new Android Resource file. While creating select the "Resource Type" to values.

After that modify the file as shown below.
**note:** auto selfie module has different set of keys that you can add. If you want to use pose estimation while using the auto selfie merge the files.

```xml
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <color name="pose_estimation_oval_view_start">#000000</color>
    <color name="pose_estimation_oval_view_success">#000000</color>
    <color name="pose_estimation_oval_view_error">#000000</color>
    <color name="pose_estimation_alert_title">#000000</color>
    <color name="pose_estimation_alert_description">#000000</color>
    <color name="pose_estimation_alert_try_again">#000000</color>
    <color name="pose_estimation_alert_background">#000000</color>
    <color name="pose_estimation_font">#000000</color>
</resources>
```

### Changing the guide images on Android

Open the android studio and add your images with following names. The SDK will automatically use the new images
for guide images.

> Secondary guide images shows up at bottom, while the main guide images shows in the center of the oval view.

| key                                   | description             |
| ------------------------------------- | ----------------------- |
| pose_estimation_main_guide_left       | Main Guide (left)       |
| pose_estimation_main_guide_right      | Main Guide (right)      |
| pose_estimation_main_guide_up         | Main Guide (up)         |
| pose_estimation_main_guide_down       | Main Guide (down)       |
| pose_estimation_main_guide_straight   | Main Guide (straight)   |
| pose_estimation_secondary_guide_left  | Secondary Guide (left)  |
| pose_estimation_secondary_guide_right | Secondary Guide (right) |
| pose_estimation_secondary_guide_up    | Secondary Guide (up)    |
| pose_estimation_secondary_guide_down  | Secondary Guide (down)  |

#### Pose estimation usage
Get the pose estimation module from the main `AmaniSDK` [instance which you have previously initialized.](#usage)
```dart
final AmaniSDK _amaniSDK = AmaniSDK();

// Configure the AutoSelfie
  final AndroidPoseEstimationSettings _androidPoseEstimationSettings =
      AndroidPoseEstimationSettings(
    poseCount: 3,
    animationDuration: 500,
    faceNotInside: "Your face is not inside the area",
    faceNotStraight: "Your face is not straight",
    keepStraight: "Please hold stable",
    alertTitle: "Verification Failed",
    alertDescription: "Failed 1",
    alertTryAgain: "Try again",
    mainGuideVisibility: true,
    secondaryGuideVisibility: true,
  );

  final IOSPoseEstimationSettings _iosPoseEstimationSettings =
      IOSPoseEstimationSettings(
    faceIsOk: "Please hold stable",
    notInArea: "Please align your face to the area",
    faceTooSmall: "Your face is in too far",
    faceTooBig: "Your face is in too close",
    completed: "Verification Completed",
    turnRight: "→",
    turnLeft: "←",
    turnUp: "↑",
    turnDown: "↓",
    lookStraight: "Look straight",
    errorMessage:
        "Please complete the steps while your face is aligned to the area",
    tryAgain: "Try again",
    errorTitle: "Verification Failure",
    confirm: "Confirm",
    next: "Next",
    holdPhoneVertically: "Please hold the phone straight",
    informationScreenDesc1:
        "To start verification, align your face with the area",
    informationScreenDesc2: "",
    informationScreenTitle: "Selfie Verification Instructions",
    wrongPose: "Your face must be straight",
    descriptionHeader:
        "Please make sure you are doing the correct pose and your face is aligned with the area",
    appBackgroundColor: "000000",
    appFontColor: "ffffff",
    primaryButtonBackgroundColor: "ffffff",
    primaryButtonTextColor: "000000",
    ovalBorderColor: "ffffff",
    ovalBorderSuccessColor: "00ff00",
    poseCount: "3",
    mainGuideVisibility: "true",
    buttonRadious: "10",
    manualCropTimeout: 30,
  );
// Since the platform plugins are async, you must create this function
Future<void> initPoseEstimation() async {
    var selfie = _amaniSDK.getPoseEstimation();
    await selfie.setType("XXX_SE_0");
}

//And call it here.
@override
void initState() {
    super.initState();
    initAutoSelfie();
}
```

Later on the buttons `onPressed` 
```dart
onPressed: () async {
            final Uint8List imageData =
                await _flutterAmanisdkV2Plugin
                  .getPoseEstimation()
                  .start(androidSettings: _androidPoseEstimationSettings, iosSettings: _iosPoseEstimationSettings);
            // Do something with imageData
            setState(() {
                _imageData = imageData;
            });
          },
```

### NFC capture
Due to differences in Android and iOS SDK's we had to seperate the NFC capture module. You must do a platform check and call the appropriate function.

#### NFC capture on Android
Android has single method for starting NFC Capture while there are multiple options to start the NFC Capture on iOS.

If you're not capturing the NFC Data after the IDCapture, this process requires some parameters from the id itself.

All date formats must be in `YYMMDD`. 
For example, `September 1st 1999` becomes `990901`.

Also you must stop the NFC listener on the `dispose()` method of your widget. You can also achive this on the `onFinishedCallback` parameter of `startNFCListener` method of `AndroidNFCCapture` class if you're calling this method from a stateless widget.

The example below uses statefull widget.
```dart
  Future<void> stopNFCListener() async {
    _nfcCapture.stopNFCListener();
  }

  Future<void> setNFCType() async {
    _nfcCapture.setType("XXX_NF_0");
  }

  @override
  void initState() {
    setNFCType();
    super.initState();
  }

  @override
  void dispose() {
    stopNFCListener();
    super.dispose();
  }
```

Starting the capture
```dart
OutlinedButton(
    onPressed: () {
      if (_dateOfBirth != "" &&
          _expireDate != "" &&
          _documentNo != "") {
        _nfcCapture.startNFCListener(
            birthDate: _dateOfBirth,
            expireDate: _expireDate,
            documentNo: _documentNo,
            onFinishedCallback: (isCaptureCompleted) {
              setState(() {
                _isCompleted = isCaptureCompleted;
              });
            },
            onErrorCallback: (errorString) {
              // handle the read errors here
            },
            onScanStart: () {
              // This callback will invoked when user shows an NFC tag 
            }
          ).catchError((err) {
            // Handle the intialization errors here
          });
      }
    },
    child:
        const Text("NVI Data Start (fields must be filled)"))
```


To upload you can call the upload method like this

```dart
OutlinedButton(
    onPressed: () {
      if (_isCompleted == false) {
        return;
      } else {
        _nfcCapture.upload();
      }
    },
    child: const Text("Upload (last step)"))
```


#### NFC capture on iOS
Native iOS SDK has different ways to start NFC Capture, but on the native Android you can only start with some fields that can found on the MRZ of the ID. 

Get the NFC module from the `AmaniSDK` class after you called the initAmani method with correct parameters. [See usage](#usage)

> **Note:** You can only run NFC capture on iOS 13.0 or later. If you want to compile your app for devices that runs iOS version before 13.0 check out [this section.](#building-for-devices-that-dont-support-nfc)

```dart
final _nfcModule = AmaniSDK().iOSNFC();
```

Starting with image of the back of the ID.
```dart
OutlinedButton(
    onPressed: () {
      _idCapture.start(IdSide.back).then((imageData) {
        _nfcCapture
            .startWithImageData(imageData)
            .then((isDone) => setState(() {
                  _isCompleted = isDone;
                }));
      });
    },
    child: const Text("Image Data Start")
)

```
If you want to use the NFC data as NFC Document, use this module. If you want to 
**Anything related to IDCapture, including the NFC data must be called from the id capture.**

```dart
OutlinedButton(
    onPressed: () {
    // Does the same thing as above, 
      _nfcCapture.startWithMRZCapture().then((isCompleted) {
        setState(() {
          _isCompleted = isCompleted;
        });
      });
    },
    child: const Text("MRZ Capture Start")
)
```

You can also start this module with some data on the id itself.

```dart
OutlinedButton(
    onPressed: () {
      _nfcCapture.startWithMRZCapture().then((isCompleted) {
        setState(() {
          _isCompleted = isCompleted;
        });
      });
    },
    child: const Text("MRZ Capture Start")
)
```


**Note** type of image data is `Uint8List`.

#### Small note for ID Capture on iOS


### Bio login
This SDK also contains methods for biologin. You don't need to call `initAmani` method from the `AmaniSDK` class for running this **as the Biologin is hosted on a different server.**

#### Initializing the bio login module

```dart
// Since the platform modules are async call on initState() 
Future<void> initBioLogin() async {
    await _bioLogin.init(
        server: "server",
        token: "bio login token to be used on bio login",
        customerId: "amani id of the customer",
        attemptId: "id of the current attempt");
  }

  @override
  void initState() {
    initBioLogin();
    super.initState();
  }
```

After the initialization, you can call the one of the methods below to start bio login process
#### Starting with AutoSelfie
For the parameters check out [usage section on auto selfie.](#auto-selfie-usage).

```dart
OutlinedButton(
    onPressed: () {
      _bioLogin.startWithAutoSelfie(
          iosAutoSelfieSettings: _iOSAutoSelfieSettings,
          androidAutoSelfieSettings: _androidAutoSelfieSettings);
    },
    child: const Text("Start AutoSelfie BioLogin"))
```
#### Starting with Pose Estimation 
For the parameters check out [usage section on pose estimation.](#pose-estimation-usage).
Due to differences in the native SDK's methods have been seperated. Use the methods below with an API check.

For iOS:
```dart
OutlinedButton(
    onPressed: () {
      _bioLogin.iOSStartWithPoseEstimation(
          settings: _iosPoseEstimationSettings,
    },
    child: const Text("Start PoseEstimation BioLogin (iOS)")),
```

For android:
```dart
OutlinedButton(
    onPressed: () {
      _bioLogin.androidStartWithPoseEstimation(
          settings: _androidPoseEstimationSettings,
          onSuccessCallback: (imageData) {
            // render the image with Image.memory(imageData)
          }, 
          onFailureCallback: (failureParams) {
            print(failureParams["reason"], failureParams["currentAttempt"])      
          }
      );
    },
    child: const Text("Start PoseEstimation BioLogin (Android)")),
```
#### Starting with Manual Selfie
```dart
OutlinedButton(
    onPressed: () {
      _bioLogin.startWithManualSelfie(
          androidSelfieDescriptionText: "Take a selfie to log in");
    },
    child: const Text("Start Manual Selfie BioLogin")),
```

### Customer Info
To fetch every data related to the customer you can use this function after [intializing the sdk](#usage)

```dart
// Use this after using AmaniSDK().initAmani method.
CustomerInfoModel customerInfo = await AmaniSDK().getCustomerInfo()
```


### F.A.Q.
#### How to use Uint8List image data to render images.

Just use the `Image.memory(data)` to render image and set width, height and other properties that you can give to `Image` widget with it. For example:

```dart
Image.memory(
            imageData,
            fit: BoxFit.contain,
            width: double.infinity,
            height: 450,
          ),
```

#### How to acquire customer token for using this SDK
1- On the server side, you need to log in with your credentials and get a token for the next steps. This token should be used only on server-side requests not used on Web SDK links.
```bash
curl --location --request POST 'https://demo.amani.ai/api/v1/user/login/' \

- -form 'email="user@account.com"' \
- -form 'password="password"'
```
2- Get or Create a customer using the request below. If there is no customer new one is created if there is a customer already created with this ID Card Number it will be returned.

This request will return a customer token that has a short life span and is valid only for this customer. Use this token to initialize Web SDK.
```
curl --location --request POST 'https://demo.amani.ai/api/v1/customer' \

- -header 'Authorization: TOKEN use_your_admin_token_here' \
- -form 'id_card_number="Customer_ID_Card_Number"'\ (Required)
- -form 'name="Customer Name"' \ (Optional)
- -form 'email="Customer Email"' \ (Optional)
- -form 'phone="Customer Phone"' (Optional)
```

### How to handle back button presses correctly on android
Due to a quirk in Flutter, we added back button handle functions
to each module. Depending on your navigation libary (we've used the flutter's default navigator) you must handle the back yourself.

#### Example for Flutter's built in navigation system

You can use the Flutter's WillPopScope feature to prevent default back press and close the view from there.

```dart
// On your component, somewhere safe from this quirk
Future<bool> onWillPop() async {
    if (Platform.isAndroid) {
      try {
        bool canPop = await _amaniSelfie.androidBackButtonHandle();
        return canPop;
      } catch (e) {
        return true;
      }
    } else {
      // default behaviour for iOS
      return true;
    }
  }
```

and don't forget to wrap your Widget with `WillPopScope`

```dart
@override
Widget build(BuildContext context) {
  return WillPopScope(
    onWillPop: onWillPop,
    child: Scaffold(
      // Start working your your selfie view.
    )
  )
}
```