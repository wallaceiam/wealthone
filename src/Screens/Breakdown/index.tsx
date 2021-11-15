import * as React from 'react';
import { createStackNavigator } from '@react-navigation/stack';

import BreakdownScreen from './BreakdownScreen';
import screenOptions from '../screenOptions';

const Stack = createStackNavigator();

const BreakdownStack = () => {
  return (
    <Stack.Navigator initialRouteName="Breakdown" screenOptions={screenOptions}>
      <Stack.Screen name="Breakdown" component={BreakdownScreen} />
    </Stack.Navigator>
  );
};

export default BreakdownStack;
