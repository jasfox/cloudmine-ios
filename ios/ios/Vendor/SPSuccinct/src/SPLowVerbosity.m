#import "SPLowVerbosity.h"

NSString *$urlencode(NSString *unencoded) {
	// Thanks, http://www.tikirobot.net/wp/2007/01/27/url-encode-in-cocoa/
	return [(id)CFURLCreateStringByAddingPercentEscapes(
														kCFAllocatorDefault, 
														(CFStringRef)unencoded, 
														NULL, 
														NULL, 
														kCFStringEncodingUTF8
														) autorelease];
}

id SPDictionaryWithPairs(NSArray *pairs, BOOL mutablep)
{
	NSUInteger count = pairs.count/2;
	id keys[count], values[count];
	size_t kvi = 0;
	for(size_t idx = 0; kvi < count;) {
		keys[kvi] = [pairs objectAtIndex:idx++];
		values[kvi++] = [pairs objectAtIndex:idx++];
	}
	return [mutablep?[NSMutableDictionary class]:[NSDictionary class] dictionaryWithObjects:values forKeys:keys count:kvi];
}

NSError *$makeErr(NSString *domain, NSInteger code, NSString *localizedDesc)
{
    return [NSError errorWithDomain:domain code:code userInfo:$dict(
        NSLocalizedDescriptionKey, localizedDesc
    )];
}