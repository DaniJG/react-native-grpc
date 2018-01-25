#import <GRPCClient/GRPCCall+Tests.h>
#import <React/RCTLog.h>
#import "HelloWorldService.h"
#import <Helloworld.pbrpc.h>

// This provides the react native module which will use the grpc client
// See:
//  creating native module: https://grpc.io/docs/tutorials/basic/objective-c.html
//  using grpc with objective-c: https://github.com/grpc/grpc/tree/master/src/objective-c#install

@implementation HelloWorldService

// Apart from letting react know about the file, they have to be manually included into the xcodeproj
RCT_EXPORT_MODULE();

static NSString * const hostAddress = @"localhost:50050";

RCT_EXPORT_METHOD(sayHello:(NSString *)name
  resolver:(RCTPromiseResolveBlock)resolve
  rejecter:(RCTPromiseRejectBlock)reject)
{
  // Create service client
  // This should by an external class injected here and initialized once, rather than on each request: https://facebook.github.io/react-native/docs/native-modules-ios.html#dependency-injection
  [GRPCCall useInsecureConnectionsForHost:hostAddress];
  HLWGreeter *client = [[HLWGreeter alloc] initWithHost:hostAddress];

  // Construct the request message
  HLWHelloRequest *request = [HLWHelloRequest message];
  request.name = name;

  // Send request and get response
  RCTLogInfo(@"Sending 'sayHello' request to the server %@", hostAddress);
  [client sayHelloWithRequest:request handler:^(HLWHelloReply *response, NSError *error) {
    if (response) {
      RCTLogInfo(@"Received response %@ from server", response.message);
      resolve(response.message);
    } else {
      RCTLogInfo(@"We tried. And failed. But received a nice error in response: %@", error);
      reject(@"get_error", @"I dont know what these 2 string arguments are for but the docs say you pass them :)", error);
    }
  }];
}

@end
