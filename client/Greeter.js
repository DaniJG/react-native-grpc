import React, { Component } from 'react';
import {
  NativeModules,
  Button,
  Text,
  View
} from 'react-native';

export default class Greeter extends Component<{}> {
  componentWillMount() {
    this.setState({
      response: ''
    });
  }
  async onGreet(){
    var service = NativeModules.HelloWorldService;
    try {
      var response = await service.sayHello('World');
      this.setState({response});
    } catch (e) {
      console.error(e);
    }
  }
  render() {
    return (
      <View>
        <Text style={{textAlign: 'center', marginTop: 20}}>
          Greet the world?
        </Text>
        <Button
          onPress={this.onGreet.bind(this)}
          title="Greet!"
          color="#841584"
          accessibilityLabel="Lets hit that grpc server"
        />
        <Text style={{textAlign: 'center'}}>
          {this.state.response}
        </Text>
      </View>
    );
  }
}
