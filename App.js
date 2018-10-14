import React from 'react';
import { SafeAreaView, Platform, StatusBar, StyleSheet, View, NativeEventEmitter } from 'react-native';
import { Provider } from 'react-redux';
import { FormattedProvider } from 'react-native-globalize';
// import { AppLoading, Asset, Font, Icon } from 'expo';
import AppNavigator from './navigation/AppNavigator';

import iCloudStorage from 'react-native-icloudstore';

import { store } from './redux/Store';
import { globalStyles } from './Style';

export default class App extends React.Component {
  state = {
    isLoadingComplete: false,
  };

  // componentWillMount() {
  //   this.eventEmitter = new NativeEventEmitter(iCloudStorage);
  //   this.eventEmitter.addListener('iCloudStoreDidChangeRemotely', this.loadData);
  // }

  // componentWillUnmount() {
  //   this.eventEmitter.remove();
  // }

  // loadData = (userInfo) => {
  //   const changedKeys = userInfo.changedKeys;
  //   if (changedKeys != null && changedKeys.includes('MY_STORAGE_KEY')) {
  //     iCloudStorage.getItem('MY_STORAGE_KEY').then(result => this.setState({ storage: result }));
  //   }
  // }

  render() {
    /*if (!this.state.isLoadingComplete && !this.props.skipLoadingScreen) {
      return (
        // <AppLoading
        //   startAsync={this._loadResourcesAsync}
        //   onError={this._handleLoadingError}
        //   onFinish={this._handleFinishLoading}
        // />
        <View></View>
      );
    } else {*/
    return (
      <Provider store={store}>
        <FormattedProvider locale="en" currency="GBP">
          <View style={[styles.container, globalStyles.body]}>
            {Platform.OS === 'ios' && <StatusBar barStyle="default" />}

            <AppNavigator />
          </View>
        </FormattedProvider>
      </Provider >
    );
    //}
  }

  _loadResourcesAsync = async () => {
    return Promise.all([
      Asset.loadAsync([
        require('./assets/images/robot-dev.png'),
        require('./assets/images/robot-prod.png'),
      ]),
      Font.loadAsync({
        // This is the font that we are using for our tab bar
        ...Icon.Ionicons.font,
        // We include SpaceMono because we use it in HomeScreen.js. Feel free
        // to remove this if you are not using it in your app
        'space-mono': require('./assets/fonts/SpaceMono-Regular.ttf'),
      }),
    ]);
  };

  _handleLoadingError = error => {
    // In this case, you might want to report the error to your error
    // reporting service, for example Sentry
    console.warn(error);
  };

  _handleFinishLoading = () => {
    this.setState({ isLoadingComplete: true });
  };
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#fff',
  },
});
