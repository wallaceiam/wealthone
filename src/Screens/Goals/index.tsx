import * as React from 'react';
import { createStackNavigator } from '@react-navigation/stack';

import GoalsScreen from './GoalsScreen';
import EditGoalsScreen from './EditGoalsScreen';
import screenOptions from '../screenOptions';

const Stack = createStackNavigator();

const GoalsStack = () => {
  return (
    <Stack.Navigator initialRouteName="GoalsDefault" screenOptions={screenOptions}>
      <Stack.Screen name="GoalsDefault" component={GoalsScreen} />
      <Stack.Screen name="GoalsEntry" component={EditGoalsScreen} />
    </Stack.Navigator>
  );
};

export default GoalsStack;
