import React from 'react';
import { SafeAreaView, View, ScrollView, Text, Button, Picker, KeyboardAvoidingView } from 'react-native';
import FeatherIcon from 'react-native-vector-icons/Feather';

import { FloatingLabelTextInput } from './../components/FloatingLabelTextInput';

import { connect } from 'react-redux';

import { bindActionCreators } from 'redux';
import { saveAccount, removeAccount } from './../redux/Actions';
import { IsAsset, AccountTypes } from '../models/Account';
import { globalStyles } from '../Style';
import { globalColours } from '../Colours';

class EditAccountScreen extends React.Component {
  static navigationOptions = ({ navigate, navigation }) => {
    const account = navigation.getParam('account', { id: undefined, name: '', provider: '', isAsset: IsAsset.Asset });
    const isValid = navigation.getParam('isValid');
    return {
      title: account.id !== undefined ? 'Edit ' + account.name : 'Add ' + (account.isAsset === IsAsset.Asset ? 'asset' : 'liability'),
      headerBackTitle: null,
      headerBackImage: <FeatherIcon name="chevron-left" size={28} color={globalColours.primary} />,
      headerRight: navigation.getParam('saveAccount') ? (
        <Button
          onPress={navigation.getParam('saveAccount')}
          title="Save"
          color={globalColours.primary}
          disabled={!isValid}
        />) : null
    };
  };

  constructor(props) {
    super(props);
    this.state = { id: undefined, name: '', provider: '', isAsset: '' };
  }

  componentDidMount() {
    this.props.navigation.setParams({ saveAccount: this.onSaveAccount });
    this.props.navigation.setParams({ isValid: this.onIsValid });
    const account = this.props.navigation.getParam('account', { id: undefined, name: '', provider: '', isAsset: IsAsset.Asset, accountType: AccountTypes[0].id });
    this.setState({ id: account.id, name: account.name, provider: account.provider, isAsset: account.isAsset, accountType: account.accountType });
  }

  onSaveAccount = () => {
    this.props.saveAccount(this.state);
    this.props.navigation.goBack();
  }

  onRemoveAccount = () => {
    this.props.removeAccount(this.state.id);
    this.props.navigation.goBack();
  }

  onIsValid = () => {
    return (this.state.name || '') !== '';
  }

  render() {
    const { id, isAsset } = this.state;
    const RemoveButton = () => {
      return id !== undefined && id.length > 0 ? (
        <Button title="Remove account" onPress={this.onRemoveAccount} />
      ) : null;
    }

    const accountTypes = AccountTypes.filter(x => x.isAsset === isAsset).map((s, i) => {
      return <Picker.Item key={i} value={s.id} label={s.name} />
    });

    // const RemoveButton = () => (<Button title="Remove account" onPress={this.onRemoveAccount} />);

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
              flex: 3,
              flexDirection: 'column',
              justifyContent: 'flex-start',
            }}>

              <FloatingLabelTextInput
                label="Account name"
                onChangeText={(text) => this.setState({ name: text })}
                value={this.state.name}
              />
              <FloatingLabelTextInput
                label="Provider"
                onChangeText={(text) => this.setState({ provider: text })}
                value={this.state.provider}
              />
              <View>
                <Text style={globalStyles.labelStyle}>
                  Type
                </Text>
                <Picker
                  selectedValue={this.state.accountType}
                  onValueChange={(itemValue, itemIndex) => this.setState({ accountType: itemValue })}>
                  {accountTypes}
                </Picker>
              </View>
            </View>
            <View style={{
              flex: 1,
              flexDirection: 'column',
              justifyContent: 'flex-end',
              marginLeft: 32,
              marginRight: 32,
              marginBottom: 32
            }}>
              <RemoveButton />
            </View>
          </View>
        </ScrollView>
      </SafeAreaView>
    );
  }
}

const mapStateToProps = (state) => {
  const { accounts } = state
  return { accounts }
};

const mapDispatchToProps = dispatch => (
  bindActionCreators({
    saveAccount,
    removeAccount
  }, dispatch)
);

export default connect(mapStateToProps, mapDispatchToProps)(EditAccountScreen);
