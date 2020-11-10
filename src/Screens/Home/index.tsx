import * as React from 'react';
import { createStackNavigator } from '@react-navigation/stack';
import FeatherIcon from 'react-native-vector-icons/Feather';

import HomeScreen from './HomeScreen';
import EntryScreen from './EntryScreen';
import AccountScreen from './AccountScreen';
import { useTheme } from '../../Theme';

const Stack = createStackNavigator();

const HomeStack = () => {
  const theme = useTheme();

  return (
    <Stack.Navigator
      initialRouteName="Home"
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
      <Stack.Screen name="Home" component={HomeScreen} />
      <Stack.Screen name="HomeEntry" component={EntryScreen} />
      <Stack.Screen name="HomeAccount" component={AccountScreen} />
    </Stack.Navigator>
  );
};

export default HomeStack;
