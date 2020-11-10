import React, { useEffect } from 'react';
import { NativeEventEmitter, Platform, StatusBar } from 'react-native';
import iCloudStorage from 'react-native-icloudstore';
import { Provider } from 'react-redux';
import { GlobalizeProvider, loadCldr } from 'react-native-globalize';

import { store, dispatch } from './src/Redux/Store';
import Screens from './src/Screens';
import { restoreSync } from './src/Redux/Actions';
import { ThemeProvider } from './src/Theme';

loadCldr(require('react-native-globalize/locale-data/en'));

const App = () => {
  useEffect(() => {
    const loadData = (userInfo) => {
      const changedKeys = userInfo.changedKeys;
      if (changedKeys != null && changedKeys.includes('backup')) {
        iCloudStorage
          .getItem('backup')
          .then((result) => dispatch(restoreSync(result)));
      }
    };

    const eventEmitter = new NativeEventEmitter(iCloudStorage);
    eventEmitter.addListener('iCloudStoreDidChangeRemotely', loadData);

    const cleanup = () => {
      eventEmitter.removeListener('iCloudStoreDidChangeRemotely', (msg) =>
        console.log(msg),
      );
    };
    return cleanup();
  });

  return (
    <GlobalizeProvider locale="en" currency="USD">
      <Provider store={store}>
        <ThemeProvider>
            {Platform.OS === 'ios' && <StatusBar barStyle="dark-content" />}
            <Screens />
        </ThemeProvider>
      </Provider>
    </GlobalizeProvider>
  );
};

export default App;
