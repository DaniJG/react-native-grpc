# GRPC integration with React Native

This repo contains a sample react native app that communicates using GRPC with a sample server, also contained in this repo. Both the client app and the server share the protocol buffer definition, which is used to generate both server and client side code.

Quick start:
```
# start sample grpc server
docker-compose up -d

# build and start the ios client
cd client
npm install
pod install
react-native run-ios
```

## Server

The GRPC server is taken from the official go hello world example found [in github](https://github.com/grpc/grpc-go/tree/master/examples).

### Generate grpc code and run it with docker

Simply run `docker-compose up`. This will both regenerate the grpc go files and start the server!

### Regenerate grpc files and Run it locally

First ensure you have the prerequisites:

- Go 1.6 or later
- Protobuf compiler (only if regerenerating the grpc code). Installation instructions [here](https://github.com/google/protobuf/blob/master/README.md#protocol-compiler-installation)

You can run the code with:
```
go run ./server/main.go &
```

If you want to regenerate the grpc code after changing the proto file, then:
```
# Install prerequisites:
go get -u google.golang.org/grpc
go get -u github.com/golang/protobuf/proto
go get -u github.com/golang/protobuf/protoc-gen-go
export PATH=$HOME/go/bin:$PATH

# Regenerate files using the proto compiler and the grpc plugin
protoc --proto_path=proto --go_out=plugins=grpc:server/helloworld helloworld.proto
```

## React Native Client

The client is a standard react native application created with the [react-native CLI](https://facebook.github.io/react-native/docs/getting-started.html) tool as in `react-native init`.

This application can talk to the GRPC server through a [native module](https://facebook.github.io/react-native/docs/native-modules-ios.html) that bridges react native and the grpc generated client in objective-c/Java.

The proto files are then used to generate the go server and the react native bridge. This allows the client and server to communicate with each other sharing the same proto definition.

The app can be run with the following instructions:
```
cd client
npm install

# Run iOS app
pod install
react-native run-ios

# Run Android app
react-native run-android
```

You will see a "Greet" button that will try to communicate with a GRPC server on localhost:50050. You can start the server located in this repo.

### How-to: Native GRPC iOS Module

Creating the code needed to talk to a grpc server from iOS in a react-native app is a 2 step process:

- First we need to generate from the proto files the objective-c code able to communicate with a server implementing the same proto definition. This process is described in the [grpc documentation](https://grpc.io/docs/tutorials/basic/objective-c.html)
- Next we need to create a react native module that bridges the react native and objective-c code, exposing to react the generated grpc client. The process of exposing native objective-c functionality to react is described in [the react native docs](https://facebook.github.io/react-native/docs/native-modules-ios.html).

#### 1.Generating the objective-c GRPC client

In order to generate the objective-c client we will add to our project a development pod. This pod will generate the grpc client in objective-c and include those generated files in the project. It is the recommended process in the [grpc documentation](https://grpc.io/docs/tutorials/basic/objective-c.html).

Prerequisites:

- [Cocoapods](https://cocoapods.org/#install)

Now start by initializing the the pod file:
```
cd client/ios
pod init

# edit the file and leave only the ReactNativeGrpc and his nested targets
```

Next we need to create a new podspec file following the [grpc template](https://github.com/grpc/grpc/blob/master/examples/objective-c/helloworld/HelloWorld.podspec). It is important that this file is located in the root ios directory.

The file in our [example repo](https://github.com/DaniJG/react-native-grpc/blob/master/client/ios/ReactNativeGrpc.podspec) has been created from that template by replacing:

- Metadata like author, source, summary
- The src variable pointing to the folder with the .proto files

Now you can include that file from the Podfile located also in the root ios directory (which was a result of the `pod init` command)
```
pod 'ReactNativeGrpc', :path => '.'
```

- Where `ReactNativeGrpc` matches the name of the podspec file and the internal name attribute.

After all these steps you should be able to run the following command in the root ios directory. It will generate the code and install the GRPC dependencies:
```
pod install
```

If everything is fine, you should be able to see the generated code in the following locations:
- client/ios/Pods/ReactNativeGrpc
- client/ios/Pods/Headers/Private/ReactNativeGrpc
- client/ios/Pods/Headers/Public/ReactNativeGrpc

If some of these files are missing, your pod isnt correctly setup. Check the pod and podspec names, and their file names.

#### 2.Exposing the objective-c GRPC client to React
After the earlier step you will end up with objective-c code that needs to be exposed to React. The way to do so is through a [React Native Module](https://facebook.github.io/react-native/docs/native-modules-ios.html).

Add a new file `HelloWorldService.h` to the main ios project (located in `client/ios/ReactNativeGrpc/HelloWorldService.h`). This will define a service that implements the react bridge:
```
#import <React/RCTBridgeModule.h>

@interface HelloWorldService : NSObject <RCTBridgeModule>
@end
```

Next lets create a new file `client/ios/ReactNativeGrpc/HelloWorldService.m` and implement the react bridge. We will expose our GRPC service as a method that can be called from React:
```
#import <GRPCClient/GRPCCall+Tests.h>
#import "HelloWorldService.h"
#import <Helloworld.pbrpc.h>

@implementation HelloWorldService

RCT_EXPORT_MODULE();

static NSString * const hostAddress = @"localhost:50050";

RCT_EXPORT_METHOD(sayHello:(NSString *)name
  resolver:(RCTPromiseResolveBlock)resolve
  rejecter:(RCTPromiseRejectBlock)reject)
{
  // Create service client
  // This could by an external class injected here and initialized once, rather than on each request: https://facebook.github.io/react-native/docs/native-modules-ios.html#dependency-injection
  [GRPCCall useInsecureConnectionsForHost:hostAddress];
  HLWGreeter *client = [[HLWGreeter alloc] initWithHost:hostAddress];

  // Construct the request message
  HLWHelloRequest *request = [HLWHelloRequest message];
  request.name = name;

  // Send request and get response
  [client sayHelloWithRequest:request handler:^(HLWHelloReply *response, NSError *error) {
    if (response) {
      resolve(response.message);
    } else {
      reject(@"get_error", "Error", error);
    }
  }];
}

@end
```

- Notice the `#import <Helloworld.pbrpc.h>` statement? Thats basically importing the code from the pod we created before, which is generated itself from the proto file. Since the pod is a development pod with the same name than the project, we only need to specify the file rather than <ReactNativeGrpc/Helloworld.pbrpc.h>.
- The `RCT_EXPORT_MODULE` and `RCT_EXPORT_METHOD` macros tell react that this is a native module that needs to be exposed to react code. The module is named is defaulted to the file name unless a explicit name is given on the `RCT_EXPORT_MODULE` macro, while the method name and its input parameters are specified in the `RCT_EXPORT_METHOD` macro.
- Notice also how in the `RCT_EXPORT_METHOD` macro, the last 2 parameters that our method will take are `resolve` and `reject`. That allows us to send a response back to react using promises.

**One important step before moving on!** Make sure you open the project with xcode and include the 2 new files HelloWorldService.h and HelloWorldService.m in the project. Otherwise they will be ignored when building (and the module wont be exposed to the react code)

- _About the file location_. I havent managed to get my native modules exposed to the react code unless located in the root of the main ios project. (That is, `client/ios/ReactNativeGrpc`) Any other location or subfolder was ignored.

### How-to: Native GRPC Android Module

### How-to: Using the Native Module from React
Once a native module as been correctly defined and included in the project, they will be exposed as part of `NativeModules` in react.

The name of the exported native module was `HelloWorldService` and it exposed a method named `sayHello`. Assuming the ios/android steps were correct, this can be used from react as in:
```
import { NativeModules } from 'react-native';
const service = NativeModules.HelloWorldService;

async onGreet(){
  try {
    let response = await service.sayHello('World');
    this.setState({response});
  } catch (e) {
    console.error(e);
  }
}
```