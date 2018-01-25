#import "Helloworld.pbobjc.h"

#import <ProtoRPC/ProtoService.h>
#import <ProtoRPC/ProtoRPC.h>
#import <RxLibrary/GRXWriteable.h>
#import <RxLibrary/GRXWriter.h>



NS_ASSUME_NONNULL_BEGIN

@protocol HLWGreeter <NSObject>

#pragma mark SayHello(HelloRequest) returns (HelloReply)

/**
 * Sends a greeting
 */
- (void)sayHelloWithRequest:(HLWHelloRequest *)request handler:(void(^)(HLWHelloReply *_Nullable response, NSError *_Nullable error))handler;

/**
 * Sends a greeting
 */
- (GRPCProtoCall *)RPCToSayHelloWithRequest:(HLWHelloRequest *)request handler:(void(^)(HLWHelloReply *_Nullable response, NSError *_Nullable error))handler;


@end

/**
 * Basic service implementation, over gRPC, that only does
 * marshalling and parsing.
 */
@interface HLWGreeter : GRPCProtoService<HLWGreeter>
- (instancetype)initWithHost:(NSString *)host NS_DESIGNATED_INITIALIZER;
+ (instancetype)serviceWithHost:(NSString *)host;
@end

NS_ASSUME_NONNULL_END
