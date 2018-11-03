import React from 'react';
import {
  SafeAreaView,
  Platform,
  ScrollView,
  Text,
  TouchableOpacity,
  View,
  SegmentedControlIOS
} from 'react-native';
import { FormattedCurrency } from 'react-native-globalize';
import FeatherIcon from 'react-native-vector-icons/Feather';
import { connect } from 'react-redux';

import { globalColours } from './../Colours';
import { globalStyles } from './../Style';

import { GoalChartExample } from '../charts/GoalChartExample';

class GoalsScreen extends React.Component {
  static navigationOptions = ({ navigate, navigation }) => ({
    title: 'Goals',
    headerBackTitleVisible: false,
    headerBackTitle: null,
    headerRight: navigation.getParam('navToEdit') ? (
      <TouchableOpacity
        style={{ marginRight: 8 }}
        onPress={navigation.getParam('navToEdit')}
      >
        <FeatherIcon name="sliders" size={24} color={globalColours.primary} />
      </TouchableOpacity>) : null
  });


  constructor(props) {
    super(props);
    this.state = {
      selectedIndex: 0
    }
  }

  componentDidMount() {
    this.props.navigation.setParams({ navToEdit: this.onNavToEditGoal });
  }

  onNavToEditGoal = () => {
    this.props.navigation.navigate('EditGoal', {});
  }

  render() {
    const { portfolio } = this.props;
    const { goal } = portfolio;
    const { result } = (goal || { result: {} });

    const goalVal = this.state.selectedIndex === 0 ?
      (result.projectedSavingsGoal || 0) : (result.projectedIncomeGoal || 0);

    const poorVal = this.state.selectedIndex === 0 ?
      (result.projectedSavingsPoor || 0) : (result.projectedIncomePoor || 0);
    const avgVal = this.state.selectedIndex === 0 ?
      (result.projectedSavingsAverage || 0) : (result.projectedIncomeAverage || 0);

    return (
      <SafeAreaView style={globalStyles.safeAreaView}>
        <ScrollView style={globalStyles.container} contentContainerStyle={globalStyles.contentContainer}>


          <View style={globalStyles.sideMargins}>
            <SegmentedControlIOS
              values={['Savings', 'Income']}
              tintColor={globalColours.primary}
              selectedIndex={this.state.selectedIndex}
              onChange={(event) => {
                this.setState({ selectedIndex: event.nativeEvent.selectedSegmentIndex });
              }}
            />
          </View>

          <View style={globalStyles.bigHeader}>
            <Text>Your goal at retirement</Text>
            <FormattedCurrency
              value={goalVal}
              currency="GBP"
              maximumFractionDigits={0}
              minimumFractionDigits={0}
              style={globalStyles.h1} />
          </View>

          <View style={globalStyles.bigHeader}>
            <Text>On track to have</Text>
            <View>
              <FormattedCurrency
                value={poorVal}
                currency="GBP"
                maximumFractionDigits={0}
                minimumFractionDigits={0}
                style={[globalStyles.h1, { paddingBottom: 0, marginBottom: 8 }]} />
              <Text>if the market performs <Text style={{ fontWeight: "bold" }}>poorly</Text></Text>
            </View>
            <View>
              <FormattedCurrency
                value={avgVal}
                currency="GBP"
                maximumFractionDigits={0}
                minimumFractionDigits={0}
                style={[globalStyles.h1, { paddingBottom: 0, marginBottom: 8 }]} />
              <Text>if the market performs <Text style={{ fontWeight: "bold" }}>average</Text></Text>
            </View>
          </View>



          <View>
            <GoalChartExample portfolio={portfolio} />
          </View>



        </ScrollView>

      </SafeAreaView>
    );
  }
}

const mapStateToProps = (state) => {
  const { portfolio, goal } = state
  return { portfolio, goal }
};

export default connect(mapStateToProps)(GoalsScreen);
