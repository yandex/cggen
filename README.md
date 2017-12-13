# cggen

Tool for generating Core Graphics code from vector PDF files

Install:
1. Compile via `swift build --product cggen --configuration release`
2. Add compiled binary to PATH

Usage:
```
cggen [--objc-header OBJC_HEADER] [--objc-impl OBJC_IMPL]
      [--objc-header-import-path OBJC_HEADER_IMPORT_PATH]
      [--objc-prefix OBJC_PREFIX]
      [-h] [--verbose]
      pdfs

positional arguments:
  pdfs                  pdf files to process


optional arguments:
  -h, --help            show help message and exit
  --verbose             print some debug info to stdout
  --objc-header OBJC_HEADER
                        Path to file where objc header will be generated,
                        intermediate dirs should exist
  --objc-impl OBJC_IMPL
                        Path to file where objc implementanion will be generated,
                        intermediate dirs should exist
  --objc-header-import-path OBJC_HEADER_IMPORT_PATH
                        Objc implementation file should import header file, so
                        this argument will be used in #import "..."
  --objc-prefix OBJC_PREFIX
                        It is usally good to prefix names of function in objc
                        code, because of global namespace. This prefix
                        will be added to every function and constant name.
```

After generation is done, generated implementation file should be compiled 
and linked into your project. 

You access to drawing functions by importing header file.
Names for functions are: `($PRFX)Draw($PDFNAME)ImageInContext`, 
sizes in logical points: `k($PRFX)($PDFNAME)ImageSize`

For easy to use, add this helper to your UIImage category (I bet you have one :) )

Objc:
```
@interface UIImage (Additions)

+ (UIImage*)imageWithSize:(CGSize)size
          drawingFunction:(void(*)(CGContextRef))drawingFunction;

@end

@implementation UIImage (YBAdditions)

+ (UIImage*)imageWithSize:(CGSize)size
          drawingFunction:(void(*)(CGContextRef))drawingFunction {
  static const size_t kBitsPerComponent = 8;
  static const size_t kBytesPerRow = 0;  // Auto
  const CGFloat scale = UIScreen.mainScreen.scale;
  const CGFloat w = size.width * scale;
  const CGFloat h = size.height * scale;
  CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
  CGContextRef context = CGBitmapContextCreate(NULL,
                                               w,
                                               h,
                                               kBitsPerComponent,
                                               kBytesPerRow,
                                               colorSpace,
                                               kCGImageAlphaPremultipliedLast);
  CGAffineTransform transform = CGAffineTransformMakeScale(scale, scale);
  CGContextConcatCTM(context, transform);
  CGColorSpaceRelease(colorSpace);

  drawingFunction(context);

  CGImageRef imgRef = CGBitmapContextCreateImage(context);
  UIImage* img = [UIImage imageWithCGImage:imgRef
                                     scale:scale
                               orientation:UIImageOrientationUp];
  CGImageRelease(imgRef);
  CGContextRelease(context);
  return img;
}

@end
```

swift:

```
extension UIImage {
  static func makeImage(size: CGSize, function: (CGContext) -> Void) -> UIImage {
    let bitsPerComponent = 8
    let bytesPerRow = 0
    let scale = UIScreen.main.scale
    let w = size.width * scale
    let h = size.height * scale
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let context = CGContext.init(data: nil,
                                 width: Int(w),
                                 height: Int(h),
                                 bitsPerComponent: bitsPerComponent,
                                 bytesPerRow: bytesPerRow,
                                 space: colorSpace,
                                 bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
    function(context)
    let cgImage = context.makeImage()!
    return UIImage(cgImage: cgImage, scale: scale, orientation: .up)
  }
}
```

So you can use it like this:

Objc:
```
UIImage* img = [UIImage yb_imageWithSize:kYYIconImageSize
                         drawingFunction:YYDrawIconImageInContext];
```

swift:
```
let img = UIImage.makeImage(size: kYYIconImageSize,
                            function: YYDrawIconImageInContext)
```
