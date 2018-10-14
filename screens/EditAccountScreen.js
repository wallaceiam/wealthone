import React from 'react';
import { SafeAreaView, View, ScrollView, StyleSheet, TextInput, Button, Text, TouchableOpacity } from 'react-native';
import FeatherIcon from 'react-native-vector-icons/Feather';

import { connect } from 'react-redux';

import { bindActionCreators } from 'redux';
import { saveAccount, removeAccount } from './../redux/Actions';
import { AccountTypes } from '../models/Account';
import { globalStyles } from '../Style';
import { globalColours } from '../Colours';

class EditAccountScreen extends React.Component {
  static navigationOptions = ({ navigate, navigation }) => {
    const account = navigation.getParam('account', { id: undefined, name: '', provider: '', accountType: AccountTypes.Asset });
    return {
      title: account.id !== undefined ? 'Edit ' + account.name : 'Add ' + (account.accountType === AccountTypes.Asset ? 'asset' : 'liability'),
      headerBackTitle: null,
      headerBackImage: <FeatherIcon name="chevron-left" size={28} color={globalColours.primary} />,
      headerRight: navigation.getParam('saveAccount') ? (
        <Button
          onPress={navigation.getParam('saveAccount')}
        title="Save"
        color={globalColours.primary}
      />) : null
    };
  };

  constructor(props) {
    super(props);
    this.state = { id: undefined, name: '', provider: '', accountType: '' };
  }

  componentDidMount() {
    this.props.navigation.setParams({ saveAccount: this.onSaveAccount });
    const account = this.props.navigation.getParam('account', { id: undefined, name: '', provider: '', accountType: AccountTypes.Asset });
    this.setState({ id: account.id, name: account.name, provider: account.provider, accountType: account.accountType });
  }

  onSaveAccount = () => {
    this.props.saveAccount(this.state);
    this.props.navigation.goBack();
  }

  onRemoveAccount = () => {
    this.props.removeAccount(this.state.id);
    this.props.navigation.goBack();
  }

  render() {
    const { id } = this.state;
    const RemoveButton = () => {
      return id !== undefined && id.length > 0 ? (
        <Button title="Remove account" onPress={this.onRemoveAccount} />
      ) : null;
    }

    return (
      <SafeAreaView style={globalStyles.safeAreaView}>
        <ScrollView style={style.container}>
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
              <RemoveButton />
            </View>
          </View>
        </ScrollView>
      </SafeAreaView>
    );
  }
}

const style = StyleSheet.create({
  container: {
    flex: 1,
    paddingTop: 15,
    backgroundColor: '#fff',
  },

  textInput: { height: 40, marginBottom: 24, borderBottomWidth: 1, borderBottomColor: '#E7E7E7' }
});

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
