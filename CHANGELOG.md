## 1.3.1+1

* Remove unnecessary code

## 1.3.1

* Fixed iOS 13 bugs

## 1.3.0

* Video support. 

# Breaking changes
### Updated
* `ShareViewController.swift` Please copy the whole class again as there are many code changes.
* `getInitialImage` changed to `getInitialMedia` for images and videos
* `getImageStream` changed to `getMediaStream` for images and videos
* both `getInitialMedia` and `getMediaStream` now return video duration and thumbnail along with the shared file path

### Removed
* `getInitialImageAsUri`
* `getImageStreamAsUri`

## 1.2.0+1

* New method added to reset the already consumed callbacks

## 1.1.5

* Example project updated. Check the method [handleImages] in example/Sharing Extension/ShareViewController.swift
* Fix some images are not successfully shared on iOS

## 1.1.4

* Add screen recorded demo

## 1.1.3

* Fix sharing image does not work sometimes on iOS and on Android when sharing from google photos (cloud)

## 1.1.2

* Return absolute path for images instead of a reference that can be used directly with File.dart
* Refactor code

## 1.0.1

* Bug fixes and updated api name

## 1.0.0

* Add support for urls

## 0.9.2

* Remove un-necessary jar libraries

## 0.9.1

* Fix issue where sharing in iOS simulator does not work
