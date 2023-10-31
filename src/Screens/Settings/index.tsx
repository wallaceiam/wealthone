import * as React from 'react';
import { createStackNavigator } from '@react-navigation/stack';

import SettingsScreen from './SettingsScreen';
import EditAccountScreen from './EditAccountScreen';
import ImportScreen from './ImportScreen';
import AboutScreen from './AboutScreen';
import screenOptions from '../screenOptions';

const Stack = createStackNavigator();

const SettingsStack = () => {
  return (
    <Stack.Navigator initialRouteName="Settings" screenOptions={screenOptions}>
      <Stack.Screen name="Settings" component={SettingsScreen} />
      <Stack.Screen name="EditAccount" component={EditAccountScreen} />
      <Stack.Screen name="Import" component={ImportScreen} />
      <Stack.Screen name="About" component={AboutScreen} />
    </Stack.Navigator>
  );
};

export default SettingsStack;
