import { StyleSheet } from 'react-native';
import { ITheme } from '../Theming/ITheme';

const css = (theme: ITheme) => ({
  /* Containers */
  safeAreaView: {
    flex: 1,
    backgroundColor: theme.colors.background,
  },
  container: {
    flex: 1,
    backgroundColor: theme.colors.background,
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
    color: theme.colors.text,
  },
  text: {
    color: theme.colors.text,
  },
  subText: {
    fontSize: 10,
    color: theme.colors.secondary,
  },
  h1: {
    fontSize: 51,
    lineHeight: 64,
    marginTop: 16,
    marginBottom: 32,
    fontFamily: 'Karla',
    color: theme.colors.secondary,
  },
  h2: {
    fontSize: 31,
    lineHeight: 32,
    marginTop: 16,
    marginBottom: 16,
    fontFamily: 'Karla',
    color: theme.colors.text,
  },
  h3: {
    fontSize: 29,
    lineHeight: 46,
    marginTop: 23,
    marginBottom: 0,
    fontFamily: 'Karla',
    color: theme.colors.text,
  },
  h4: {
    fontSize: 18,
    lineHeight: 23,
    marginTop: 23,
    marginBottom: 0,
    color: theme.colors.text,
  },
  h5: {
    fontSize: 18,
    lineHeight: 23,
    marginTop: 23,
    marginBottom: 0,
    color: theme.colors.text,
  },
  p: {
    marginTop: 0,
    marginBottom: 23,
    color: theme.colors.text,
  },
  ul: {
    marginTop: 0,
    marginBottom: 0,
    color: theme.colors.text,
  },

  /* Input */
  label: {
    color: theme.colors.primary,
  },
  textInput: {
    height: 40,
    marginBottom: 24,
    borderBottomWidth: 1,
    color: theme.colors.primary,
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
    color: theme.colors.secondary,
    backgroundColor: theme.colors.background,
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
    color: theme.colors.primary,
  },
  inactive: {
    color: theme.colors.primary_alpha,
  },

  /* App Header */
  appIcon: {
    width: 64,
    height: 64,
  },
  appHeaderContainer: {
    flexDirection: 'row',
    marginTop: 32,
    marginLeft: 32,
    marginRight: 32,
  },
  appHeaderIconContainer: {
    marginRight: 16,
    paddingTop: 2,
  },
  nameText: {
    fontWeight: '600',
    fontSize: 18,
    color: theme.colors.primary,
  },
  companyText: {
    color: theme.colors.secondary,
    fontSize: 14,
    backgroundColor: 'transparent',
  },
  descriptionText: {
    fontSize: 14,
    marginTop: 6,
    color: theme.colors.secondary,
  },

  // Swipable
  swipeBackground: {
    ...StyleSheet.absoluteFillObject,
    backgroundColor: theme.colors.background,
    flexDirection: 'row',
    justifyContent: 'flex-end',
    alignItems: 'center',
    overflow: 'hidden',
  },
  swipeRow: {
    flexGrow: 1,
    flexShrink: 0,
    flexDirection: 'row',
    justifyContent: 'space-between',
    marginLeft: 0,
    marginRight: 0,
    paddingLeft: 32,
    paddingRight: 32,

    alignItems: 'center',
  },
});

export default css;
