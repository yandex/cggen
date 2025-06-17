import Foundation

func generateObjCCallerFile(
  headerImportPath: String,
  scale: CGFloat,
  allowAntialiasing: Bool,
  prefix: String,
  outputPath: String,
  outputs: [Output]
) -> String {
  var sections = [String]()

  // Header comment
  sections.append(commonHeaderPrefix)

  // Imports
  sections.append(generateCallerImports(headerImportPath: headerImportPath))

  // Helper function and main start
  sections.append(generateCallerHelpers(
    scale: scale,
    allowAntialiasing: allowAntialiasing
  ))

  // Image calls
  let imageCalls = outputs.map(\.image).map { image in
    generateImageCall(image: image, prefix: prefix, outputPath: outputPath)
  }.joined(separator: "\n\n")
  sections.append(imageCalls)

  // Main end
  sections.append("  return retCode;\n}")

  return sections.joined(separator: "\n\n") + "\n"
}

private func generateCallerImports(headerImportPath: String) -> String {
  """
  #ifndef __has_feature
  #define __has_feature(x) 0
  #endif

  #if __has_feature(modules)
  @import CoreGraphics;
  @import Foundation;
  @import ImageIO;
  @import UniformTypeIdentifiers;
  #else
  #import <CoreGraphics/CoreGraphics.h>
  #import <Foundation/Foundation.h>
  #import <ImageIO/ImageIO.h>
  #import <UniformTypeIdentifiers/UniformTypeIdentifiers.h>
  #endif

  #import "\(headerImportPath)"
  """
}

private func generateCallerHelpers(
  scale: CGFloat,
  allowAntialiasing: Bool
) -> String {
  """
  typedef void (*DrawingFunction)(CGContextRef);
  static const CGFloat kScale = \(scale);

  static int WriteImageToFile(DrawingFunction f,
                              CGSize s,
                              NSString* outputFilePath) {
    CGSize contextSize =
    CGSizeApplyAffineTransform(s, CGAffineTransformMakeScale(kScale, kScale));
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef ctx =
      CGBitmapContextCreate(NULL, (size_t)contextSize.width, (size_t)contextSize.height, 8, 0,
                            colorSpace, kCGImageAlphaPremultipliedLast);
    CGContextSetAllowsAntialiasing(ctx, \(allowAntialiasing ? "YES" : "NO"));
    CGContextScaleCTM(ctx, kScale, kScale);
    f(ctx);
    CGImageRef img = CGBitmapContextCreateImage(ctx);
    NSURL* url = [NSURL fileURLWithPath:outputFilePath];
    CGImageDestinationRef destination = CGImageDestinationCreateWithURL(
      (__bridge CFURLRef)url,
      (__bridge CFStringRef)UTTypePNG.identifier,
      1, nil
    );
    CGImageDestinationAddImage(destination, img, nil);
    BOOL t = CGImageDestinationFinalize(destination);

    CGColorSpaceRelease(colorSpace);
    CGContextRelease(ctx);
    CGImageRelease(img);
    CFRelease(destination);
    return t ? 0 : 1;
  }

  int main(
    int __attribute__((unused)) argc,
    const char* __attribute__((unused)) argv[]
  ) {
    int retCode = 0;
  """
}

private func generateImageCall(
  image: Image,
  prefix: String,
  outputPath: String
) -> String {
  let camel = image.name.upperCamelCase
  let function = ObjCGen.functionName(imageName: camel, prefix: prefix)
  return """
    retCode |= WriteImageToFile(\(function),
        k\(prefix)\(camel)ImageSize,
        @"\(outputPath)/\(image.name).png");
  """
}
