#import "SPDepends.h"
#import "SPKVONotificationCenter.h"
#import <objc/runtime.h>

@interface SPDependency : NSObject
@property(copy) SPDependsFancyCallback callback;
@property(assign) id owner;
@property(retain) NSMutableArray *subscriptions;
@end

@implementation SPDependency
@synthesize callback = _callback, owner = _owner;
@synthesize subscriptions = _subscriptions;

-initWithDependencies:(NSArray*)pairs callback:(SPDependsFancyCallback)callback owner:(id)owner;
{
	
	self.callback = callback;
	self.owner = owner;
	
	self.subscriptions = [NSMutableArray array];
	
	SPKVONotificationCenter *nc = [SPKVONotificationCenter defaultCenter];
	
	
	NSEnumerator *en = [pairs objectEnumerator];
	id object = [en nextObject];
	id next = [en nextObject];
	
	for(;;) {
		SPKVObservation *subscription = [nc addObserver:self toObject:object forKeyPath:next options:0 selector:@selector(somethingChanged:inObject:forKey:)];
		[_subscriptions addObject:subscription];
		
		next = [en nextObject];
		if(!next) break;
		
		if(![next isKindOfClass:[NSString class]]) {
			object = next;
			next = [en nextObject];
		}
	}
	
	self.callback(nil, nil, nil);
	
	return self;
}
-(void)invalidate;
{
	for(SPKVObservation *observation in _subscriptions)
		[observation invalidate];
	self.callback = nil;
}
-(void)dealloc;
{
	self.subscriptions = nil;
	self.owner = nil;
	self.callback = nil;
	[super dealloc];
}
-(void)somethingChanged:(NSDictionary*)change inObject:(id)object forKey:(NSString*)key;
{
#if _DEBUG
	NSAssert(self.callback != nil, @"Somehow a KVO reached us after an 'invalidate'?");
#endif
	if(self.callback)
		self.callback(change, object, key);
}
@end

static void *dependenciesKey = &dependenciesKey;

id SPAddDependency(id owner, NSString *associationName, NSArray *dependenciesAndNames, SPDependsCallback callback)
{
	id dep = [[[SPDependency alloc] initWithDependencies:dependenciesAndNames callback:(SPDependsFancyCallback)callback owner:owner] autorelease];
	if(owner && associationName) {
		NSMutableDictionary *dependencies = objc_getAssociatedObject(owner, dependenciesKey);
		if(!dependencies) dependencies = [NSMutableDictionary dictionary];

		SPDependency *oldDependency = [dependencies objectForKey:associationName];
		if(oldDependency) [oldDependency invalidate];
		
		[dependencies setObject:dep forKey:associationName];
		objc_setAssociatedObject(owner, dependenciesKey, dependencies, OBJC_ASSOCIATION_RETAIN);
	}
	return dep;
}

id SPAddDependencyV(id owner, NSString *associationName, ...)
{
	NSMutableArray *dependenciesAndNames = [NSMutableArray new];
	va_list va;
	va_start(va, associationName);
	
	id object = va_arg(va, id);
	id peek = va_arg(va, id);
	do {
		[dependenciesAndNames addObject:object];
		object = peek;
		peek = va_arg(va, id);
	} while(peek != nil);
	
	id dep = SPAddDependency(owner, associationName, dependenciesAndNames, object);
	
	[dependenciesAndNames release];
	return dep;
}

void SPRemoveAssociatedDependencies(id owner)
{
	NSMutableDictionary *dependencies = objc_getAssociatedObject(owner, dependenciesKey);
	for(SPDependency *dep in [dependencies allValues])
		[dep invalidate];
	
	objc_setAssociatedObject(owner, dependenciesKey, nil, OBJC_ASSOCIATION_RETAIN);
}