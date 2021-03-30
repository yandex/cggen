#import <CoreGraphics/CoreGraphics.h>
@import BCRunner;

typedef const unsigned char bytecode;
void runBytecode(CGContextRef context, bytecode** arr, int len);

bytecode arr[] = {
    0,
    1, 0, 0, 128, 63,
    1, 0, 0, 0, 0,
    2, 0, 17, 0,
    2, 1, 6, 0,
    0,
    1, 0, 0, 128, 63,
    3, 1,
    1, 0, 0, 0, 64,
    3, 0,
    3, 0,
    0,
};

CGContextRef getContext() {
    static const size_t kBitsPerComponent = 8;
      static const size_t kBytesPerRow = 0;  // Auto
      const CGFloat w = 100;
      const CGFloat h = 100;
      CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
      return CGBitmapContextCreate(NULL,
                                                   w,
                                                   h,
                                                   kBitsPerComponent,
                                                   kBytesPerRow,
                                                   colorSpace,
                                                   kCGImageAlphaPremultipliedLast);
}

int main(int argc, const char * argv[]) {
    CGContextRef context = getContext();
    runBytecode(context, &arr, sizeof(arr));
    return 0;
}
