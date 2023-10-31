import * as React from 'react';
import { createStackNavigator } from '@react-navigation/stack';

import HomeScreen from './HomeScreen';
import EntryScreen from './EntryScreen';
import AccountScreen from './AccountScreen';
import screenOptions from '../screenOptions';

const Stack = createStackNavigator();

const HomeStack = () => {
  return (
    <Stack.Navigator initialRouteName="HomeDefault" screenOptions={screenOptions}>
      <Stack.Screen name="HomeDefault" component={HomeScreen} />
      <Stack.Screen name="HomeEntry" component={EntryScreen} />
      <Stack.Screen name="HomeAccount" component={AccountScreen} />
    </Stack.Navigator>
  );
};

export default HomeStack;
