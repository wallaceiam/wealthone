import * as React from 'react';
import {NavigationContainer} from '@react-navigation/native';
import {AppearanceProvider, useColorScheme} from 'react-native-appearance';

import {DefaultTheme, DarkTheme} from './Theming';
import {DefaultStyle, DarkStyle, StyleProvider} from './Styling';

export const ThemeProvider = ({children}: React.PropsWithChildren<unknown>) => {
  const scheme = useColorScheme();
  return (
    <AppearanceProvider>
      <NavigationContainer theme={scheme === 'dark' ? DarkTheme : DefaultTheme}>
        <StyleProvider value={scheme === 'dark' ? DarkStyle : DefaultStyle}>
          {children}
        </StyleProvider>
      </NavigationContainer>
    </AppearanceProvider>
  );
};
