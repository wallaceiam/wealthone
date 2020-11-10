import { StyleSheet } from 'react-native';
import { DarkTheme, DefaultTheme } from '../Theming';
import css from './Stylesheet';

export const DefaultStyle = StyleSheet.create(css(DefaultTheme));
export const DarkStyle = StyleSheet.create(css(DarkTheme));