import React from 'react';
import {
  SafeAreaView,
  Platform,
  ScrollView,
  Text,
  TouchableOpacity,
  View,
} from 'react-native';
import { connect } from 'react-redux';

import { globalStyles } from './../Style';
import { GoalChartExample } from '../charts/GoalChartExample';

class GoalsScreen extends React.Component {
  static navigationOptions = {
    title: 'Goals'
  };


  constructor(props) {
    super(props);
  }

  render() {
    const { portfolio } = this.props;
    return (
      <SafeAreaView style={globalStyles.safeAreaView}>
        <ScrollView style={globalStyles.container} contentContainerStyle={globalStyles.contentContainer}>

          <View>
            <GoalChartExample portfolio={portfolio} />
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

export default connect(mapStateToProps)(GoalsScreen);
