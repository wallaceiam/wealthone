import { StyleSheet } from 'react-native';
import { DefaultTheme } from '../Theming';

export const GlobalStyles = {
  /* Containers */
  safeAreaView: {
    flex: 1,
    backgroundColor: DefaultTheme.colors.background,
  },
  container: {
    flex: 1,
    backgroundColor: DefaultTheme.colors.background,
  },
  contentContainer: {
    paddingTop: 32,
    paddingBottom: 16,
  },
  row: {
    flex: 1,
    flexDirection: 'row',
    justifyContent: 'space-between',
    marginLeft: 32,
    marginRight: 32,
  },
  column: {
    flex: 1,
    flexDirection: 'column',
    justifyContent: 'space-between',
    marginLeft: 32,
    marginRight: 32,
  },

  /* Padding & Margins */
  sideMargins: {
    marginLeft: 32,
    marginRight: 32,
  },
  topMargin: {
    marginTop: 16,
  },
  bottomMargin: {
    marginBottom: 16,
  },
  rightMargin: {
    marginRight: 8,
  },
  noMargins: {
    marginLeft: 0,
    marginRight: 0,
  },
  autoMargins: {
    marginTop: 'auto',
    marginBottom: 'auto',
  },

  /* Typography */
  body: {
    fontSize: 12,
    lineHeight: 16,
    margin: 'auto',
    fontFamily: 'montserrat',
    color: DefaultTheme.colors.text,
  },
  text: {
    color: DefaultTheme.colors.text,
  },
  h1: {
    fontSize: 51,
    lineHeight: 64,
    marginTop: 16,
    marginBottom: 32,
    fontFamily: 'karla',
    color: DefaultTheme.colors.secondary,
  },
  h2: {
    fontSize: 31,
    lineHeight: 32,
    marginTop: 16,
    marginBottom: 16,
    fontFamily: 'karla',
    color: DefaultTheme.colors.text,
  },
  h3: {
    fontSize: 29,
    lineHeight: 46,
    marginTop: 23,
    marginBottom: 0,
    fontFamily: 'karla',
    color: DefaultTheme.colors.text,
  },
  h4: {
    fontSize: 18,
    lineHeight: 23,
    marginTop: 23,
    marginBottom: 0,
    color: DefaultTheme.colors.text,
  },
  h5: {
    fontSize: 18,
    lineHeight: 23,
    marginTop: 23,
    marginBottom: 0,
    color: DefaultTheme.colors.text,
  },
  p: {
    marginTop: 0,
    marginBottom: 23,
    color: DefaultTheme.colors.text,
  },
  ul: {
    marginTop: 0,
    marginBottom: 0,
    color: DefaultTheme.colors.text,
  },

  /* Input */
  label: {
    color: DefaultTheme.colors.primary,
  },
  textInput: {
    height: 40,
    marginBottom: 24,
    borderBottomWidth: 1,
    color: DefaultTheme.colors.primary,
  },
  numberInput: {
    textAlign: 'right',
  },

  bigHeader: {
    padding: 32,
    paddingTop: 16,
    paddingBottom: 0,
  },

  /* Lists */
  sectionHeaderStyle: {
    padding: 16,
    paddingLeft: 32,
    paddingRight: 24,
    fontWeight: 'bold',
    color: DefaultTheme.colors.secondary,
    backgroundColor: DefaultTheme.colors.background,
  },
  subSectionHeaderStyle: {
    paddingBottom: 16,
    paddingTop: 0,
    paddingLeft: 32,
    paddingRight: 24,
    fontWeight: 'normal',
    textTransform: 'uppercase',
  },

  active: {
    color: DefaultTheme.colors.primary
  },
  inactive: {
    color: DefaultTheme.colors.primary_alpha
  },
};

const DefaultStyle = StyleSheet.create(GlobalStyles);

export default DefaultStyle;

