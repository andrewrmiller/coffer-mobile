# Coffer Mobile
The Coffer Photos mobile application is a mobile client for the Coffer Photos service.

### Flutter Version Notes
Coffer currently must be built with the Flutter Beta channel because of bugs with VS Code and isolates.  Once these changes have made their way into the Stable channel Coffer should switch back.



### iOS Notes
- The debug version of the application can only be used when the device is connected to a host computer.

- The debug version of the app requires the Dart multicase DNS service.  Since we don't need/want this for the release build it is only enabled in debug.  We achieve this by having a `.plist` per build.  For more information see:

https://flutter.dev/docs/development/add-to-app/ios/project-setup#local-network-privacy-permissions

- To deploy the release version run:

```
flutter run --release
```

### Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://flutter.dev/docs/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://flutter.dev/docs/cookbook)

For help getting started with Flutter, view our
[online documentation](https://flutter.dev/docs), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
