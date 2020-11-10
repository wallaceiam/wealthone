import { StyleSheet } from 'react-native';
import { DarkTheme } from '../Theming';
import { GlobalStyles } from './DefaultStyle';

const darkStyle = {
  ...GlobalStyles,
  /* Overrides */
  safeAreaView: {
    ...GlobalStyles.safeAreaView,
    backgroundColor: DarkTheme.colors.background,
  },
  container: {
    ...GlobalStyles.container,
    backgroundColor: DarkTheme.colors.background,
  },
  body: {
    ...GlobalStyles.body,
    color: DarkTheme.colors.text,
  },
  text: {
    ...GlobalStyles.text,
    color: DarkTheme.colors.text,
  },
  h1: {
    ...GlobalStyles.h1,
    color: DarkTheme.colors.secondary,
  },
  h2: {
    ...GlobalStyles.h2,
    color: DarkTheme.colors.text,
  },
  h3: {
    ...GlobalStyles.h3,
    color: DarkTheme.colors.text,
  },
  h4: {
    ...GlobalStyles.h4,
    color: DarkTheme.colors.text,
  },
  h5: {
    ...GlobalStyles.h5,
    color: DarkTheme.colors.text,
  },
  p: {
    ...GlobalStyles.p,
    color: DarkTheme.colors.text,
  },
  ul: {
    ...GlobalStyles.ul,
    color: DarkTheme.colors.text,
  },
  label: {
    ...GlobalStyles.label,
    color: DarkTheme.colors.primary,
  },
  textInput: {
    ...GlobalStyles.textInput,
    color: DarkTheme.colors.primary,
  },
  sectionHeaderStyle: {
    ...GlobalStyles.sectionHeaderStyle,
    color: DarkTheme.colors.secondary,
    backgroundColor: DarkTheme.colors.background,
  },
  active: {
    ...GlobalStyles.active,
    color: DarkTheme.colors.primary
  },
  inactive: {
    ...GlobalStyles.inactive,
    color: DarkTheme.colors.primary_alpha
  },
};

const DarkStyle = StyleSheet.create(darkStyle);

export default DarkStyle;
