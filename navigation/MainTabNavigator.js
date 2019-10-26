import React from 'react';
import { Platform } from 'react-native';
import FeatherIcon from 'react-native-vector-icons/Feather';
import { createStackNavigator, createBottomTabNavigator } from 'react-navigation';

import HomeScreen from '../screens/HomeScreen';
import BreakdownScreen from '../screens/BreakdownScreen';
import GoalsScreen from '../screens/GoalsScreen';
import SettingsScreen from '../screens/SettingsScreen';
import AboutScreen from '../screens/AboutScreen';
import EditAccountScreen from '../screens/EditAccountScreen';
import HistoryScreen from '../screens/HistoryScreen';

import EntryScreen from '../screens/EntryScreen';
import AccountScreen from '../screens/AccountScreen';

import BlankScreen from '../screens/BlankScreen';

import { globalColours } from '../Colours';
import ImportScreen from '../screens/ImportScreen';
import EditGoalScreen from '../screens/EditGoalScreen';


const HomeStack = createStackNavigator({
  Home: HomeScreen,
  HomeEntry: EntryScreen,
  HomeAccount: AccountScreen
});

HomeStack.navigationOptions = {
  tabBarLabel: 'Home',
  tabBarIcon: ({ focused }) => (
    <FeatherIcon name="home" size={24} color={focused ? globalColours.primary : globalColours.primary_alpha} />
  ),
  headerTintColor: globalColours.primary,
  headerBackTitleVisible: false,
  headerBackTitle: null
};

const BreakdownStack = createStackNavigator({
  Breakdown: BreakdownScreen,
  Blank: BlankScreen,
});

BreakdownStack.navigationOptions = {
  tabBarLabel: 'Breakdown',
  tabBarIcon: ({ focused }) => (
    <FeatherIcon name="bar-chart" size={24} color={focused ? globalColours.primary : globalColours.primary_alpha} />
  ),
};

const HistoryStack = createStackNavigator({
  History: HistoryScreen,
  HistoryEntry: EntryScreen,
});

HistoryStack.navigationOptions = {
  tabBarLabel: 'History',
  tabBarIcon: ({ focused }) => (
    <FeatherIcon name="list" size={24} color={focused ? globalColours.primary : globalColours.primary_alpha} />
  ),
};

const SettingsStack = createStackNavigator({
  Settings: SettingsScreen,
  EditAccount: EditAccountScreen,
  Import: ImportScreen,
  About: AboutScreen,
  Blank: BlankScreen
});

SettingsStack.navigationOptions = {
  tabBarLabel: 'Settings',
  tabBarIcon: ({ focused }) => (
    <FeatherIcon name="settings" size={24} color={focused ? globalColours.primary : globalColours.primary_alpha} />
  ),
};

const GoalsStack = createStackNavigator({
  Goals: GoalsScreen,
  EditGoal: EditGoalScreen
});

GoalsStack.navigationOptions = {
  tabBarLabel: 'Goals',
  tabBarIcon: ({ focused }) => (
    <FeatherIcon name="target" size={24} color={focused ? globalColours.primary : globalColours.primary_alpha} />
  ),
};


export default createBottomTabNavigator({
  HomeStack,
  BreakdownStack,
  GoalsStack,
  HistoryStack,
  SettingsStack,
}, {
    initialRouteName: 'HomeStack',
    lazy: true,
    tabBarOptions: {
      activeTintColor: globalColours.primary,
    },
    navigationOptions: {
      headerTintColor: globalColours.primary,
      headerBackTitle: null,
    }
  });
