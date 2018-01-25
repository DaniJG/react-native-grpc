#import "Helloworld.pbrpc.h"

#import <ProtoRPC/ProtoRPC.h>
#import <RxLibrary/GRXWriter+Immediate.h>

@implementation HLWGreeter

// Designated initializer
- (instancetype)initWithHost:(NSString *)host {
  return (self = [super initWithHost:host packageName:@"helloworld" serviceName:@"Greeter"]);
}

// Override superclass initializer to disallow different package and service names.
- (instancetype)initWithHost:(NSString *)host
                 packageName:(NSString *)packageName
                 serviceName:(NSString *)serviceName {
  return [self initWithHost:host];
}

+ (instancetype)serviceWithHost:(NSString *)host {
  return [[self alloc] initWithHost:host];
}


#pragma mark SayHello(HelloRequest) returns (HelloReply)

/**
 * Sends a greeting
 */
- (void)sayHelloWithRequest:(HLWHelloRequest *)request handler:(void(^)(HLWHelloReply *_Nullable response, NSError *_Nullable error))handler{
  [[self RPCToSayHelloWithRequest:request handler:handler] start];
}
// Returns a not-yet-started RPC object.
/**
 * Sends a greeting
 */
- (GRPCProtoCall *)RPCToSayHelloWithRequest:(HLWHelloRequest *)request handler:(void(^)(HLWHelloReply *_Nullable response, NSError *_Nullable error))handler{
  return [self RPCToMethod:@"SayHello"
            requestsWriter:[GRXWriter writerWithValue:request]
             responseClass:[HLWHelloReply class]
        responsesWriteable:[GRXWriteable writeableWithSingleHandler:handler]];
}
@end
