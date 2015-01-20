#import "NSString_URLEncode.h"


@implementation NSString (URLEncode)

+ (NSString *)URLEncodeString:(NSString *)text
{
    return (__bridge_transfer NSString *)CFURLCreateStringByAddingPercentEscapes(NULL,
                                                                        (__bridge CFStringRef)text, NULL,
                                                                        (CFStringRef)@"!*'();:@&=+$,/?%#[]",
                                                                        kCFStringEncodingUTF8);
}

@end