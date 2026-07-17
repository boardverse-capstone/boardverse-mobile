> ## Documentation Index
> This page is part of the Image and Video APIs product. Fetch the complete documentation index for Image and Video APIs at: https://cloudinary.com/documentation/llms-image-and-video-apis.txt?referrer=docpage and then use it to discover all relevant pages before exploring further.
> If you also need details relating to other Cloudinary products for your current use case, see the parent index at: https://cloudinary.com/documentation/llms.txt?referrer=docpage

# Flutter SDK


[changelog-link]: https://github.com/cloudinary/cloudinary_flutter/blob/master/CHANGELOG.md

The Cloudinary Flutter SDK provides simple, yet comprehensive image and video transformation, optimization, and delivery capabilities through the [Cloudinary APIs](cloudinary_references#url_and_rest_apis), that you can implement using code that integrates seamlessly with your existing Flutter application.
> **INFO**: :title=SDK security upgrade, June 2025

We recently released an enhanced security version of this SDK that improves the validation and handling of input parameters. We recommend upgrading to the [latest version][changelog-link] of the SDK to benefit from these security improvements.

## How would you like to learn?

{table:class=no-borders overview}Resource | Description 
--|--
[Flutter quick start](flutter_quick_start) | Get up and running in five minutes with a walk through of installation, configuration, and transformations.
[Video tutorials](flutter_video_tutorials) | Watch tutorials relevant to your use cases, from getting started with the Flutter SDK, to transforming your images and videos.
[Cloudinary Flutter SDK GitHub repo](https://github.com/cloudinary/cloudinary_flutter) | Explore the source code and see the [CHANGELOG][changelog-link] for details on all new features and fixes from previous versions.

Other helpful resources...

This guide focuses on how to set up and implement popular Cloudinary capabilities using the Flutter SDK, but it doesn't cover every feature or option. Check out these other resources to learn about additional concepts and functionality in general. 

{table:class=no-borders overview}Resource | Description 
--|--
[Developer kickstart](dev_kickstart) |A hands-on, step-by-step introduction to Cloudinary features.
[Glossary](cloudinary_glossary) | A helpful resource to understand Cloudinary-specific terminology.
[Guides](programmable_media_guides) | In depth guides to help you understand the many, varied capabilities provided by the product. 
[References](cloudinary_references) | Comprehensive references for all APIs, including Flutter code examples.

## Install

Cloudinary's Flutter SDK is available as an open-source package. To use this SDK, add Cloudinary as a [dependency in your pubspec.yaml file](https://docs.flutter.dev/development/packages-and-plugins/using-packages):

```
dependencies:
  cloudinary_flutter: ^1.0.0
  cloudinary_url_gen: ^1.0.0
```

> **NOTE**:
>
> The Flutter mobile framework library must be used in conjunction with the [Dart](dart_integration) backend library to provide all of Cloudinary's transformation and optimization functionality. Two GitHub repositories provide all the functionality:

> * [cloudinary_flutter](https://github.com/cloudinary/cloudinary_flutter) contains all the functionality required to deliver Cloudinary images using the dedicated `CldImageWidget`. All the Cloudinary Flutter functionality is installed by adding the `cloudinary_flutter` package as a dependency. 

> * [cloudinary_url_gen](https://github.com/cloudinary/cloudinary_dart) contains the functionality required to create delivery URLs for your Cloudinary assets based on the configuration and transformation actions that you specify. All the Cloudinary Dart functionality is installed by adding the `cloudinary_url_gen` package as a dependency.

## Configure

The `Cloudinary` class is the main entry point for using the library. Your `cloud_name` is required to create an instance of this class and can be found in the **Dashboard** of the Cloudinary Console.

Here's an example of setting up a `Cloudinary` instance in your Flutter application:
  
```dart
CloudinaryContext.cloudinary = Cloudinary.fromCloudName(cloudName: '<your-cloud-name>');
```

### Set additional configuration parameters

In addition to your cloud name, you can define a number of optional [configuration parameters](cloudinary_sdks#configuration_parameters) if relevant.

For example, set the `secure` optional configuration parameter to `true`: 

```dart
CloudinaryContext.cloudinary.config.urlConfig.secure=true;
```

> **NOTE**: By default, URLs generated with this SDK include an appended SDK-usage query parameter. Cloudinary tracks aggregated data from this parameter to improve future SDK versions. We don't collect any individual data. If needed, you can disable the `urlAnalytics` configuration option. [Learn more](cloudinary_sdks#analytics_config).

### Configuration video tutorial

Watch this video tutorial to see how to install and configure the Flutter SDK:

  This video is brought to you by Cloudinary's video player - embed your own!Use the controls to set the playback speed, navigate to chapters of interest and select subtitles in your preferred language.
{videoTranscript:publicId=training/Install_Configure_Flutter}

## Use

Once you've installed and configured the Flutter SDK, you can use it for:

* **Transform and optimize**: Dynamically transform and optimize your media assets on-the-fly using powerful transformations.
* **Deliver**: Generate dynamic URLs for seamless delivery of transformed images and videos.

> **NOTE**: The Flutter SDK allows you to transform and deliver assets that are already in your Cloudinary repository. See [Flutter image and video upload](flutter_image_and_video_upload) for ways to upload assets to Cloudinary.

Capitalization and data type guidelines...

When using the Flutter SDK, keep these guidelines in mind:

* Uses Cloudinary's new SDK action based syntax with enhanced code autocomplete.
* Actions and transformations are immutable, for easier and safer code reuse.
* The `CldImageWidget` allows you to transform and deliver Cloudinary images, and make other modifications to your assets. It wraps Flutter's authenticated `Image` widget for easy and convenient integration into your apps.
* By default, the images you display using the `CldImageWidget` are [cached](flutter_media_transformations#the_cldimagewidget) to reduce loading time and improve user experience.

### Quick example: Image transformation

Here's a simple example for creating a Flutter widget that transforms and delivers a Cloudinary image, including a resize transformation, using the Flutter SDK:

```flutter
CldImageWidget(
  publicId: 'cld-sample-5.jpg',
  transformation: Transformation()
    ..resize(Resize.pad()
      ..width(100)
      ..height(150))
),
```

![Image example](https://res.cloudinary.com/demo/image/upload/c_fill,h_150,w_200/cld-sample-5.jpg "with_code: false, with_url: false, thumb: u_docs:iphone_template,h_600")

> **Learn more about transformations**:
>
> * Read the [Transform and customize assets](image_transformations) guide to learn about the different ways to transform your assets.

> * See examples of powerful [image and video](flutter_media_transformations) transformations using Flutter code and see our [image transformations](image_transformations) and [video transformations](video_manipulation_and_delivery) docs.

> * See all possible transformations in the [Transformation URL API reference](transformation_reference).

> * See all the Dart-based transformation actions and qualifiers that you can use in Flutter in the [Dart-based cloudinary_url_gen package reference](https://cloudinary.com/documentation/sdks/dart/url-gen/index.html).

### Quick example: Video transformation

Here is a simple example for generating a Cloudinary video URL, including a resize transformation with boomerang and vignette effects, using the Flutter SDK:

```dart
(CloudinaryContext.cloudinary.video('ski_jump')
  ..transformation(Transformation()
    ..effect(Effect.boomerang())
    ..effect(Effect.vignette(30))
    ..resize(Resize.pad()
      ..height(360)
      ..width(480))))
  .toString();
```

  
    
    
    
  

> **NOTE**: Most transformations can be passed as parameters using Cloudinary's new action based syntax with enhanced code autocomplete. Transformations that aren't yet supported for the new syntax can still be implemented by passing them directly as strings via the `..addTransformation()` method of the Flutter SDK.
For more information about the Flutter SDK syntax, see [Syntax overview](flutter_media_transformations#syntax_overview).

> **Learn more about transformations**:
>
> * Read the [Transform and customize assets](image_transformations) guide to learn about the different ways to transform your assets.

> * See examples of powerful [image and video](flutter_media_transformations) transformations using Flutter code and see our [image transformations](image_transformations) and [video transformations](video_manipulation_and_delivery) docs.

> * See all possible transformations in the [Transformation URL API reference](transformation_reference).

## Sample projects

Use the example code at [pub.dev](https://pub.dev/packages/cloudinary_flutter/example) to quickly get a simple app working for delivering assets that are already in your Cloudinary repository.

> **READING**:
>
> * See examples of powerful [image and video](flutter_media_transformations) transformations using Flutter code and see our [image transformations](image_transformations) and [video transformations](video_manipulation_and_delivery) docs.

> * Take a look at our [iOS](ios_integration) and [Android](android_integration) SDKs as alternatives for mobile development with Cloudinary.

> * Stay tuned for updates by following the [Release Notes](programmable_media_release_notes) and the [Cloudinary Blog](https://cloudinary.com/blog).
