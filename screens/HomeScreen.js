import React from 'react';
import {
  SafeAreaView,
  ScrollView,
  TouchableOpacity,
  View,
} from 'react-native';
import FeatherIcon from 'react-native-vector-icons/Feather';

import { connect } from 'react-redux';

import HomeTopBar from '../components/HomeTopBar';
import PortfolioList from '../components/PortfolioList';
import { NetworthGrowthChart } from '../charts/NetworthGrowthChart';

import { globalColours } from './../Colours';
import { globalStyles } from './../Style';

import { justDate } from './../helpers/Date';

class HomeScreen extends React.Component {
  static navigationOptions = ({ navigate, navigation }) => ({
    title: 'Home',
    headerBackTitleVisible: false,
    headerBackTitle: null,
    headerRight: navigation.getParam('navToEntry') ? (
      <TouchableOpacity
        style={{ marginRight: 8 }}
        onPress={navigation.getParam('navToEntry')}
      >
        <FeatherIcon name="plus" size={24} color={globalColours.primary} />
      </TouchableOpacity>) : null
  });


  constructor(props) {
    super(props);
  }

  componentDidMount() {
    this.props.navigation.setParams({ navToEntry: this._navToEntry });
  }

  _navToEntry = () => {
    this.props.navigation.navigate('HomeEntry', { date: justDate(new Date()) });
  }

  render() {
    const { portfolio } = this.props;
    return (
      <SafeAreaView style={globalStyles.safeAreaView}>
        <ScrollView style={globalStyles.container} contentContainerStyle={globalStyles.contentContainer}>
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


const mapStateToProps = (state) => {
  const { portfolio } = state
  return { portfolio }
};

export default connect(mapStateToProps)(HomeScreen);