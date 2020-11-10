import * as React from 'react';
import { createStackNavigator } from '@react-navigation/stack';

import GoalsScreen from './GoalsScreen';
import EditGoalsScreen from './EditGoalsScreen';
import BackIcon from '../../Components/Icons/BackIcon';

const Stack = createStackNavigator();

const GoalsStack = () => {
  return (
    <Stack.Navigator
      initialRouteName="Goals"
      screenOptions={{
        headerBackTitle: null,
        headerBackTitleVisible: false,
        headerBackImage: () => <BackIcon />,
      }}>
      <Stack.Screen name="Goals" component={GoalsScreen} />
      <Stack.Screen name="GoalsEntry" component={EditGoalsScreen} />
    </Stack.Navigator>
  );
};

export default GoalsStack;
