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


const HomeStack = createStackNavigator({
  Home: HomeScreen,
  HomeEntry: EntryScreen,
  HomeAccount: AccountScreen
});

HomeStack.navigationOptions = {
  tabBarLabel: 'Home',
  tabBarIcon: ({ focused }) => (
    <FeatherIcon name="home" size={24} color={focused ? globalColours.primary : globalColours.secondary} />
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
    <FeatherIcon name="bar-chart" size={24} color={focused ? globalColours.primary : globalColours.secondary} />
  ),
};

const HistoryStack = createStackNavigator({
  History: HistoryScreen,
  HistoryEntry: EntryScreen,
});

HistoryStack.navigationOptions = {
  tabBarLabel: 'History',
  tabBarIcon: ({ focused }) => (
    <FeatherIcon name="list" size={24} color={focused ? globalColours.primary : globalColours.secondary} />
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
    <FeatherIcon name="sliders" size={24} color={focused ? globalColours.primary : globalColours.secondary} />
  ),
};

const GoalsStack = createStackNavigator({
  Goals: GoalsScreen,
  Blank: BlankScreen
});

GoalsStack.navigationOptions = {
  tabBarLabel: 'Goals',
  tabBarIcon: ({ focused }) => (
    <FeatherIcon name="target" size={24} color={focused ? globalColours.primary : globalColours.secondary}  />    
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
  tabBarOptions: {
    activeTintColor: globalColours.primary,
  },
  navigationOptions: {
    headerTintColor: globalColours.primary,
  }
});
