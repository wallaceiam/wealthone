import { StyleSheet, Platform } from 'react-native';
import { globalColours } from './Colours';

export const globalStyles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#fff',
  },
  developmentModeText: {
    marginBottom: 20,
    color: 'rgba(0,0,0,0.4)',
    fontSize: 14,
    lineHeight: 19,
    textAlign: 'center',
  },
  contentContainer: {
    paddingTop: 30,
  },
  welcomeContainer: {
    alignItems: 'center',
    marginTop: 10,
    marginBottom: 20,
  },
  welcomeImage: {
    width: 100,
    height: 80,
    resizeMode: 'contain',
    marginTop: 3,
    marginLeft: -10,
  },
  getStartedContainer: {
    alignItems: 'center',
    marginHorizontal: 50,
  },
  homeScreenFilename: {
    marginVertical: 7,
  },
  codeHighlightText: {
    color: 'rgba(96,100,109, 0.8)',
  },
  codeHighlightContainer: {
    backgroundColor: 'rgba(0,0,0,0.05)',
    borderRadius: 3,
    paddingHorizontal: 4,
  },
  getStartedText: {
    fontSize: 17,
    color: 'rgba(96,100,109, 1)',
    lineHeight: 24,
    textAlign: 'center',
  },
  tabBarInfoContainer: {
    position: 'absolute',
    top: 0,
    left: 0,
    right: 0,
    ...Platform.select({
      ios: {
        shadowColor: 'black',
        shadowOffset: { height: 3 },
        shadowOpacity: 0.1,
        shadowRadius: 3,
      },
      android: {
        elevation: 20,
      },
    }),
    alignItems: 'center',
    backgroundColor: '#fbfbfb',
    paddingVertical: 20,
  },
  tabBarInfoText: {
    fontSize: 17,
    color: 'rgba(96,100,109, 1)',
    textAlign: 'center',
  },
  navigationFilename: {
    marginTop: 5,
  },
  helpContainer: {
    marginTop: 15,
    alignItems: 'center',
  },
  helpLink: {
    paddingVertical: 15,
  },
  helpLinkText: {
    fontSize: 14,
    color: '#2e78b7',
  },

  fill: {
    flex: 1,
  },
  content: {
    flex: 1,
  },
  /*header: {
    position: 'absolute',
    top: 0,
    left: 0,
    right: 0,
    backgroundColor: '#03A9F4',
    overflow: 'hidden',
    height: HEADER_MAX_HEIGHT,
  },
  backgroundImage: {
    position: 'absolute',
    top: 0,
    left: 0,
    right: 0,
    width: null,
    height: HEADER_MAX_HEIGHT,
    resizeMode: 'cover',
  },*/
  bar: {
    backgroundColor: 'transparent',
    marginTop: Platform.OS === 'ios' ? 28 : 38,
    height: 32,
    alignItems: 'center',
    justifyContent: 'center',
    position: 'absolute',
    top: 0,
    left: 0,
    right: 0,
  },
  title: {
    color: 'white',
    fontSize: 18,
  },
  scrollViewContent: {
    // iOS uses content inset, which acts like padding.
    paddingTop: Platform.OS !== 'ios' ? HEADER_MAX_HEIGHT : 0,
  },
  row: {
    height: 40,
    margin: 16,
    backgroundColor: '#D3D3D3',
    alignItems: 'center',
    justifyContent: 'center',
  },


  /* Containers */
  safeAreaView: { flex: 1, backgroundColor: '#fff' },


  /* Typography */
  root: {
    fontSize: 12,
    lineHeight: 16,
  },
  body: {
    fontSize: 12,
    lineHeight: 16,
    margin: 'auto',
    fontFamily: 'montserrat',
    color: globalColours.primary
  },
  h1: {
    fontSize: 51,
    lineHeight: 64,
    marginTop: 16,
    marginBottom: 32,
    fontFamily: 'karla',
    color: globalColours.secondary
  },
  h2: {
    fontSize: 31,
    lineHeight: 32,
    marginTop: 16,
    marginBottom: 16,
    fontFamily: 'karla'
  },
  h3: {
    fontSize: 29,
    lineHeight: 46,
    marginTop: 23,
    marginBottom: 0,
    fontFamily: 'karla'
  },
  h4: {
    fontSize: 18,
    lineHeight: 23,
    marginTop: 23,
    marginBottom: 0,
  },
  h5: {
    fontSize: 18,
    lineHeight: 23,
    marginTop: 23,
    marginBottom: 0,
  },
  p: {
    marginTop: 0,
    marginBottom: 23,
  },
  ul: {
    marginTop: 0,
    marginBottom: 0,
  },

  /* Let's make sure all's aligned */
  /*hr, .hr {
    border: 1px solid;
    margin: -1px 0;
  }
  a, b, i, strong, em, small, code {
    lineHeight: 0;
  }
  sub, sup {
    lineHeight: 0;
    position: relative;
    vertical-align: baseline;
  }
  sup {
    top: -0.5em;
  }
  sub {
    bottom: -0.25em;
  }*/

  /* Input */
  textInput: {
    height: 40,
    marginBottom: 24,
    borderBottomWidth: 1,
    borderBottomColor: '#E7E7E7'
  },
  numberInput: {
    textAlign: 'right'
  },

  /* Lists */
  sectionHeaderStyle: {
    padding: 16,
    paddingLeft: 24,
    paddingRight: 24,
    fontWeight: 'bold'
  },
});