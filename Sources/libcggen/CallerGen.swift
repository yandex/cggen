import Foundation

struct ObjcCallerGen: CoreGraphicsGenerator {
  let headerImportPath: String
  let scale: CGFloat
  let allowAntialiasing: Bool
  let prefix: String
  let outputPath: String
  func filePreambleNew() -> ObjcTerm {
    ObjcTerm(
      .hasFeatureSupport,
      .import(.coreGraphics, .foundation, .imageIO, .uniformTypeIdentifiers),
      .newLine,
      .quotedImport(headerImportPath),
      .newLine
    )
  }

  func filePreambleLegacy() -> String {
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

  func filePreamble() -> String {
    filePreambleNew().render(indent: 2)
      .joined(separator: "\n") + filePreambleLegacy()
  }

  func generateImageFunctions(images: [Image]) throws -> String {
    images.map { generateImageFunction(image: $0) }.joined(separator: "\n\n")
  }

  private func generateImageFunction(image: Image) -> String {
    let camel = image.name.upperCamelCase
    let function = ObjCGen.functionName(imageName: camel, prefix: prefix)
    return
      """
        retCode |= WriteImageToFile(\(function),
            k\(prefix)\(camel)ImageSize,
            @\"\(outputPath)/\(image.name).png\");
      """
  }

  func generatePathFuncton(path _: PathRoutine) -> String {
    // TODO: should be implemented, but not needed yet
    ""
  }

  func fileEnding() -> String {
    "  return retCode;\n}"
  }
}
