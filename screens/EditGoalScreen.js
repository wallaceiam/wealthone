import React from 'react';
import {
  SafeAreaView,
  View,
  ScrollView,
  TextInput,
  Text,
  SectionList,
  Slider,
  Button,
  StyleSheet
} from 'react-native';
import FeatherIcon from 'react-native-vector-icons/Feather';
import { FormattedCurrency, withGlobalize, Globalize } from 'react-native-globalize';

import { connect } from 'react-redux';

import { bindActionCreators } from 'redux';
import { saveGoal } from './../redux/Actions';

import { GoalTypes, GoalFrequency } from '../models/Goal';
import { globalStyles } from '../Style';
import { globalColours } from '../Colours';

class EditGoalScreen extends React.Component {
  static navigationOptions = ({ navigate, navigation }) => ({
    title: 'Edit Goal',
    headerBackTitle: null,
    headerBackImage: <FeatherIcon name="chevron-left" size={28} color={globalColours.primary} />,
    headerRight: navigation.getParam('saveGoal') ? (
      <Button
        onPress={navigation.getParam('saveGoal')}
        title="Save"
        color={globalColours.primary}
      />) : null
  });

  constructor(props) {
    super(props);
    this.state = {
      currentAge: 40,
      retirementAge: 68,
      earnings: 55000,
      contributions: 1700,
      pension: 0,
      investment: 3,
      lifestyle: 40

    };
  }

  componentDidMount() {
    this.props.navigation.setParams({ saveGoal: this.onSaveGoal });
    const { input } = this.props;
    if (input !== undefined) {
      this.setState({
        currentAge: input.currentAge,
        retirementAge: input.retirementAge,
        earnings: input.earnings,
        contributions: input.contributions,
        pension: input.pension,
        investment: input.investment,
        lifestyle: input.lifestyle
      });
    }
  }

  onSaveGoal = () => {
    this.props.saveGoal(this.state);
    this.props.navigation.goBack();
  }

  titleForItem = (item) => {
    switch (item) {
      case 'age': return 'Current age:';
      case 'retirementAge': return 'Retirement age:';
      case 'salary': return 'Annual salary';
      case 'contributions': return 'Montly contributions';
      case 'investmentStyle': return 'Investment style';
      case 'pension': return 'Pension';
      case 'retirementLifeStyle': return 'Life style';
    }
    return null;
  }

  sliderForItem = (item) => {
    switch (item) {
      case 'age': return (
        <Slider
          step={1}
          minimumValue={18}
          maximumValue={68}
          minimumTrackTintColor={globalColours.primary}
          onValueChange={(v) => this.setState({ currentAge: Math.min(v, this.state.retirementAge) })}
          value={this.state.currentAge}
        />
      );
      case 'retirementAge': return (
        <Slider
          step={1}
          minimumValue={18}
          maximumValue={68}
          minimumTrackTintColor={globalColours.primary}
          onValueChange={(v) => this.setState({ retirementAge: Math.max(v, this.state.currentAge) })}
          value={this.state.retirementAge}
        />
      );
      case 'salary': return (
        <Slider
          step={100}
          minimumValue={0}
          maximumValue={150000}
          minimumTrackTintColor={globalColours.primary}
          onValueChange={(v) => this.setState({ earnings: v })}
          value={this.state.earnings}
        />
      );
      case 'contributions': return (
        <Slider
          step={50}
          minimumValue={0}
          maximumValue={5000}
          minimumTrackTintColor={globalColours.primary}
          onValueChange={(v) => this.setState({ contributions: v })}
          value={this.state.contributions}
        />
      );
      case 'investmentStyle': return (
        <Slider
          step={1}
          minimumValue={0}
          maximumValue={6}
          minimumTrackTintColor={globalColours.primary}
          onValueChange={(v) => this.setState({ investment: v })}
          value={this.state.investment}
        />
      )
      case 'retirementLifeStyle': return (
        <Slider
          step={1}
          minimumValue={0}
          maximumValue={100}
          minimumTrackTintColor={globalColours.primary}
          onValueChange={(v) => this.setState({ lifestyle: v })}
          value={this.state.lifestyle}
        />
      )

    }
    return null;
  }

  valueForItem = (item) => {
    const currencyFormatter = (v) => (v);
    //Globalize.getCurrencyFormatter('GBP', {
    // minimumFractionDigits: 0, maximumFractionDigits: 0 });

    switch (item) {
      case 'age': return (<Text>{this.state.currentAge}</Text>);
      case 'retirementAge': return (<Text>{this.state.retirementAge}</Text>);
      case 'salary': return (<Text>{currencyFormatter(this.state.earnings)}/y</Text>);
      case 'contributions': return (<Text>{currencyFormatter(this.state.contributions)}/m</Text>);
      case 'investmentStyle': {
        switch (this.state.investment) {
          case 0: return (<Text>Safety first</Text>);
          case 1: return (<Text>Defensive</Text>);
          case 2: return (<Text>Cautious</Text>);
          case 3: return (<Text>Slightly cautious</Text>);
          case 4: return (<Text>Moderate</Text>);
          case 5: return (<Text>Adventurous</Text>);
          case 6: return (<Text>Very adventurous</Text>);
        }
        return null;
      }
      case 'pension': return null;
      case 'retirementLifeStyle': return (<Text>{this.state.lifestyle}%</Text>);
    }
    return null;
  }

  renderItem = ({ item }) => {
    const title = this.titleForItem(item);
    const slider = this.sliderForItem(item);
    const val = this.valueForItem(item);
    return (
      // <TouchableOpacity onPress={this.onPortfolioSelected.bind(this, item)}>
      <View style={globalStyles.altRow}>
        <View style={{
          flex: 1,
          flexDirection: 'row',
          justifyContent: 'space-between',
          marginTop: 'auto',
          marginBottom: 'auto'
        }}>
          <Text>{title} </Text>
          {val}
          {/* <Text>{item.provider} </Text> */}
        </View>
        <View style={{ flex: 2 }}>
          {/* <FormattedCurrency
                            value={item.amount}
                            currency="GBP"
                            maximumFractionDigits={0}
                            minimumFractionDigits={0}
                            style={[globalStyles.h2]} /> */}
          {slider}
        </View>

      </View>
      // </TouchableOpacity>
    )
  };

  render() {
    const sections = [
      { title: 'Time', data: ['age', 'retirementAge'] },
      { title: 'Money', data: ['salary', 'contributions', 'retirementLifeStyle'] },
      { title: 'Settings', data: ['investmentStyle', 'pension'] }
    ];
    const { value } = this.state;
    return (
      <SafeAreaView style={globalStyles.safeAreaView}>
        <ScrollView style={globalStyles.container} contentContainerStyle={globalStyles.contentContainer}>

          <SectionList
            sections={sections}

            renderSectionHeader={({ section }) => <Text style={globalStyles.sectionHeaderStyle}> {section.title} </Text>}
            renderItem={this.renderItem}
            keyExtractor={(item, index) => index}

          />
        </ScrollView>
      </SafeAreaView>
    );
  }
}



const mapStateToProps = (state) => {
  const { portfolio } = state;
  const { goal } = portfolio;
  const { input } = (goal || { input: undefined });

  return { input };

};

const mapDispatchToProps = dispatch => (
  bindActionCreators({
    saveGoal
  }, dispatch)
);

//export default withGlobalize(connect(mapStateToProps, mapDispatchToProps)(EditGoalScreen));
export default connect(mapStateToProps, mapDispatchToProps)(EditGoalScreen);
