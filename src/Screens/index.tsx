import * as React from 'react';
import { createBottomTabNavigator } from '@react-navigation/bottom-tabs';
import FeatherIcon from 'react-native-vector-icons/Feather';

import Home from './Home';
import Settings from './Settings';
import Breakdown from './Breakdown';
import History from './History';
import Goals from './Goals';

import { useStyle, useTheme } from '../Theme';

const Tab = createBottomTabNavigator();

const Navigation = () => {
  const theme = useTheme();
  const style = useStyle();
  return (
    <Tab.Navigator
      sceneContainerStyle={[style.container, style.body]}
      screenOptions={({ route }) => ({
        unmountOnBlur: true,
        tabBarIcon: ({ color, size }) => {
          let iconName;

          if (route.name === 'Home') {
            iconName = 'home';
          } else if (route.name === 'Settings') {
            iconName = 'settings';
          } else if (route.name === 'History') {
            iconName = 'list';
          } else if (route.name === 'Breakdown') {
            iconName = 'bar-chart';
          } else if (route.name === 'Goals') {
            iconName = 'target';
          }

          // You can return any component that you like here!
          return <FeatherIcon name={iconName} size={size} color={color} />;
        },
      })}
      tabBarOptions={{
        activeTintColor: theme.colors.primary,
        inactiveTintColor: theme.colors.primary_alpha,
        showLabel: false,
      }}>
      <Tab.Screen name="Home" component={Home} />
      <Tab.Screen name="Breakdown" component={Breakdown} />
      <Tab.Screen name="Goals" component={Goals} />
      <Tab.Screen name="History" component={History} />
      <Tab.Screen name="Settings" component={Settings} />
    </Tab.Navigator>
  );
};

export default Navigation;
