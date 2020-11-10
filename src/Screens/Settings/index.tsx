import * as React from 'react';
import { createStackNavigator } from '@react-navigation/stack';

import BackIcon from '../../Components/Icons/BackIcon';
import { useTheme } from '../../Theme';

import SettingsScreen from './SettingsScreen';
import EditAccountScreen from './EditAccountScreen';
import ImportScreen from './ImportScreen';
import AboutScreen from './AboutScreen';

const Stack = createStackNavigator();

const SettingsStack = () => {
  const theme = useTheme();

  return (
    <Stack.Navigator
      initialRouteName="Settings"
      screenOptions={{
        headerBackTitle: null,
        headerBackTitleVisible: false,
        headerBackImage: () => (
          <BackIcon />
        ),
      }}>
      <Stack.Screen name="Settings" component={SettingsScreen} />
      <Stack.Screen name="EditAccount" component={EditAccountScreen} />
      <Stack.Screen name="Import" component={ImportScreen} />
      <Stack.Screen name="About" component={AboutScreen} />
    </Stack.Navigator>
  );
};

export default SettingsStack;
