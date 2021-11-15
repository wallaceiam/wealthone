import React, { useEffect } from 'react';
import { Alert, NativeEventEmitter, Platform, StatusBar } from 'react-native';
import iCloudStorage from 'react-native-icloudstore';
import { Provider } from 'react-redux';
import { GlobalizeProvider, loadCldr } from 'react-native-globalize';

import { dispatch, store } from './src/Redux/Store';
import Screens from './src/Screens';
import { rehydrate } from './src/Redux/Actions';
import { ThemeProvider, useTheme } from './src/Theme';

loadCldr(require('react-native-globalize/locale-data/en'));

const ThemeStatusBar = () => {
  const theme = useTheme();

  return <StatusBar barStyle={theme.dark ? 'light-content' : 'dark-content'} />;
};

const App = () => {
  useEffect(() => {
    const loadData = (userInfo) => {
      const changedKeys = userInfo.changedKeys || [];
      Alert.alert(JSON.stringify(changedKeys));
      if (changedKeys.includes('persist:wealthone_data')) {
        iCloudStorage.getItem('persist:wealthone_data').then((result) => {
          Alert.alert(JSON.stringify(result));
          dispatch(rehydrate('wealthone_data', result));
        });
      }
    };

    const eventEmitter = new NativeEventEmitter(iCloudStorage);
    eventEmitter.addListener('iCloudStoreDidChangeRemotely', loadData);

    const cleanup = () => {
      eventEmitter.removeListener('iCloudStoreDidChangeRemotely', loadData);
    };
    return cleanup();
  });

  return (
    <GlobalizeProvider locale="en" currency="USD">
      <Provider store={store}>
        <ThemeProvider>
          {Platform.OS === 'ios' && <ThemeStatusBar />}
          <Screens />
        </ThemeProvider>
      </Provider>
    </GlobalizeProvider>
  );
};

export default App;
