import React from 'react';
import { SafeAreaView, View, ScrollView, TextInput, Button } from 'react-native';
import FeatherIcon from 'react-native-vector-icons/Feather';

import { connect } from 'react-redux';

import { bindActionCreators } from 'redux';
import { saveGoal, removeGoal } from './../redux/Actions';

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
      id: undefined,
      title: '',
      goalType: GoalTypes.OtherLifeMoments,
      amount: undefined,
      when: new Date(),
      frequency: GoalFrequency.Once,
      colour: 0,
    };
  }

  componentDidMount() {
    this.props.navigation.setParams({ saveGoal: this.onSaveGoal });
    const goal = this.props.navigation.getParam('goal', {
      id: undefined,
      title: '',
      goalType: GoalTypes.OtherLifeMoments,
      amount: undefined,
      when: new Date(),
      frequency: GoalFrequency.Once,
      colour: 0,
    });
    this.setState({
      id: goal.id,
      title: goal.title,
      goalType: goal.goalType,
      amount: goal.amount,
      when: goal.when,
      frequency: goal.frequency,
      colour: goal.colour
    });
  }

  onSaveGoal = () => {
    this.props.saveGoal(this.state);
    this.props.navigation.goBack();
  }

  onRemoveGoal = () => {
    this.props.removeGoal(this.state.id);
    this.props.navigation.goBack();
  }

  render() {
    const { id } = this.state;
    const RemoveButton = id !== undefined && id.length > 0 ? (
      <Button title="Remove goal" onPress={this.onRemoveGoal} />
    ) : '';
    return (
      <SafeAreaView style={globalStyles.safeAreaView}>
        <ScrollView style={globalStyles.container} contentContainerStyle={globalStyles.contentContainer}>
          <View style={{
            flex: 1,
            flexDirection: 'column',
            justifyContent: 'space-between',
            marginLeft: 32,
            marginRight: 32
          }}>

            <View style={{
              flex: 1,
              flexDirection: 'column',
              justifyContent: 'flex-start',
            }}>

              <TextInput
                style={globalStyles.textInput}
                placeholder="Account name"
                onChangeText={(text) => this.setState({ name: text })}
                value={this.state.name}
              />
              <TextInput
                style={globalStyles.textInput}
                placeholder="Provider"
                onChangeText={(text) => this.setState({ provider: text })}
                value={this.state.provider}
              />
            </View>
            <View style={{
              flex: 3,
              flexDirection: 'column',
              justifyContent: 'flex-end',
              marginLeft: 32,
              marginRight: 32,
              marginBottom: 32
            }}>
              {RemoveButton}
            </View>
          </View>
        </ScrollView>
      </SafeAreaView>
    );
  }
}

const mapStateToProps = (state) => {
  const { goals } = state
  return { goals }
};

const mapDispatchToProps = dispatch => (
  bindActionCreators({
    saveGoal,
    removeGoal
  }, dispatch)
);

export default connect(mapStateToProps, mapDispatchToProps)(EditGoalScreen);
