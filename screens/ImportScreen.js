import React from 'react';
import { SafeAreaView, View, ScrollView, StyleSheet, TextInput, Button, Text, TouchableOpacity } from 'react-native';
import FeatherIcon from 'react-native-vector-icons/Feather';

import { connect } from 'react-redux';

import { bindActionCreators } from 'redux';
import { importJson } from './../redux/Actions';
import { globalStyles } from '../Style';
import { globalColours } from '../Colours';

class ImportScreen extends React.Component {
  static navigationOptions = ({ navigate, navigation }) => ({
    title: 'Import',
    headerBackTitle: null,
    headerBackImage: <FeatherIcon name="chevron-left" size={24} color={globalColours.primary} />,
    headerRight: navigation.getParam('import') ? (
      <Button
        onPress={navigation.getParam('import')}
        title="Save"
        style={{ marginRight: 8 }}
        color={globalColours.primary}
      />) : null
  });

  constructor(props) {
    super(props);
    this.state = { text: ''};
  }

  componentDidMount() {
    this.props.navigation.setParams({ import: this.onSaveImport });
  }

  onSaveImport = () => {
    this.props.importJson(this.state.text);
    this.props.navigation.goBack();
  }

  render() {
    return (
      <SafeAreaView style={globalStyles.safeAreaView}>
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
              multiline = {true}
              placeholder="Paste your json export here"
              onChangeText={(text) => this.setState({ text: text })}
              value={this.state.text}
            />
          </View>
        </View>
      </SafeAreaView>
    );
  }
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    paddingTop: 15,
    backgroundColor: '#fff',
  },

  textInput: { height: 100, marginBottom: 24, borderBottomWidth: 1, borderBottomColor: '#E7E7E7' }
});

const mapStateToProps = (state) => {
  const { accounts } = state
  return { accounts }
};

const mapDispatchToProps = dispatch => (
  bindActionCreators({
    importJson
  }, dispatch)
);

export default connect(mapStateToProps, mapDispatchToProps)(ImportScreen);
