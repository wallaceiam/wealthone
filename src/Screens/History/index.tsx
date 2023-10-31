import * as React from 'react';
import {createStackNavigator} from '@react-navigation/stack';

import HistoryScreen from './HistoryScreen';
import EntryScreen from '../Home/EntryScreen';
import screenOptions from '../screenOptions';

const Stack = createStackNavigator();

const HistoryStack = () => {
  return (
    <Stack.Navigator initialRouteName="History" screenOptions={screenOptions}>
      <Stack.Screen name="History" component={HistoryScreen} />
      <Stack.Screen name="HistoryEntry" component={EntryScreen} />
    </Stack.Navigator>
  );
};

export default HistoryStack;
