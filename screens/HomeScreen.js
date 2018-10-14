import React from 'react';
import {
  SafeAreaView,
  Animated,
  Image,
  Platform,
  Button,
  ScrollView,
  StyleSheet,
  StatusBar,
  RefreshControl,
  Text,
  TouchableOpacity,
  View,
} from 'react-native';
import FeatherIcon from 'react-native-vector-icons/Feather';

import { connect } from 'react-redux';

import { MonoText } from '../components/StyledText';
import { BigHeader } from '../components/BigHeader';
import HomeTopBar from '../components/HomeTopBar';
import PortfolioList from '../components/PortfolioList';
import { NetworthGrowthChart } from '../charts/NetworthGrowthChart';

import { AreaChartExample } from '../charts/AreaChartExample';

import { globalColours } from './../Colours';
import { globalStyles } from './../Style';

const HEADER_MAX_HEIGHT = 300;

class HomeScreen extends React.Component {
  static navigationOptions = ({ navigate, navigation }) => ({
    title: 'Home',
    headerBackTitleVisible: false,
    headerBackTitle: null,
    headerRight: navigation.getParam('navToEntry') ? (
      <TouchableOpacity
        onPress={navigation.getParam('navToEntry')}
      >
        <FeatherIcon name="plus" size={28} color={globalColours.primary} />
      </TouchableOpacity>) : null
  });


  constructor(props) {
    super(props);
  }

  _justDate(d) {
    return new Date(d.getFullYear(), d.getMonth(), d.getDate());
  }

  componentDidMount() {
    this.props.navigation.setParams({ navToEntry: this._navToEntry });
  }

  _navToEntry = () => {
    this.props.navigation.navigate('Entry', { date: this._justDate(new Date()) });
  }

  render() {
    const { portfolio } = this.props;
    return (
      <SafeAreaView style={globalStyles.safeAreaView}>
        <ScrollView style={styles.container} contentContainerStyle={styles.contentContainer}>
          <HomeTopBar />
          <View>
            <NetworthGrowthChart portfolio={portfolio} />
          </View>

          <View>
            <PortfolioList />
          </View>


        </ScrollView>
      </SafeAreaView>
    );
  }
}

const styles = StyleSheet.create({
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
  header: {
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
  },
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
});

const mapStateToProps = (state) => {
  const { portfolio } = state
  return { portfolio }
};

export default connect(mapStateToProps)(HomeScreen);