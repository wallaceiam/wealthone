import * as React from 'react';
import { createStackNavigator } from '@react-navigation/stack';

import BreakdownScreen from './BreakdownScreen';

const Stack = createStackNavigator();

const BreakdownStack = () => {
  return (
    <Stack.Navigator>
      <Stack.Screen name="Breakdown" component={BreakdownScreen} />
    </Stack.Navigator>
  );
};

export default BreakdownStack;
