import * as React from 'react';
import { createStackNavigator } from '@react-navigation/stack';
import FeatherIcon from 'react-native-vector-icons/Feather';

import HistoryScreen from './HistoryScreen';
import EntryScreen from '../Home/EntryScreen';
import { useTheme } from '@react-navigation/native';

const Stack = createStackNavigator();

const HistoryStack = () => {
  const theme = useTheme();
  return (
    <Stack.Navigator
      initialRouteName="History"
      screenOptions={{
        headerBackTitle: null,
        headerBackTitleVisible: false,
        headerBackImage: () => (
          <FeatherIcon
            name="chevron-left"
            size={24}
            color={theme.colors.primary}
          />
        ),
      }}>
      <Stack.Screen name="History" component={HistoryScreen} />
      <Stack.Screen name="HistoryEntry" component={EntryScreen} />
    </Stack.Navigator>
  );
};

export default HistoryStack;
