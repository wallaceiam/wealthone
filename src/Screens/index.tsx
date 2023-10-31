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
        headerShown: false,
        tabBarActiveTintColor: theme.colors.primary,
        tabBarInactiveTintColor: theme.colors.primary_alpha,
        tabBarShowLabel: false,
        tabBarStyle: [{
          display: "flex"
        }],
        safeAreaInsets: { top: 0, bottom: 24 },
        
        unmountOnBlur: true,
        tabBarIcon: ({ color, size }) => {
          let iconName = '';

          if (route.name === 'HomeTab') {
            iconName = 'home';
          } else if (route.name === 'SettingsTab') {
            iconName = 'settings';
          } else if (route.name === 'HistoryTab') {
            iconName = 'list';
          } else if (route.name === 'BreakdownTab') {
            iconName = 'bar-chart';
          } else if (route.name === 'GoalsTab') {
            iconName = 'target';
          }

          // You can return any component that you like here!
          return <FeatherIcon name={iconName} size={size} color={color} />;
        },
      })}
     > 
      <Tab.Screen name="HomeTab" component={Home} />
      <Tab.Screen name="BreakdownTab" component={Breakdown} />
      <Tab.Screen name="GoalsTab" component={Goals} />
      <Tab.Screen name="HistoryTab" component={History} />
      <Tab.Screen name="SettingsTab" component={Settings} />
    </Tab.Navigator>
  );
};

export default Navigation;
