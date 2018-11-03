import React from 'react';
import { SafeAreaView, ScrollView, View } from 'react-native';
import FeatherIcon from 'react-native-vector-icons/Feather';
import { connect } from 'react-redux';

import { IsAsset } from './../models/Account';
import AccountTopBar from './../components/AccountTopBar';
import { AccountGrowthChart } from './../charts/AccountGrowthChart';
import AccountStats from './../components/AccoutStats';

import { globalStyles } from './../Style';
import { globalColours } from '../Colours';

class AccountScreen extends React.Component {
  static navigationOptions = ({ navigate, navigation }) => {
    const account = navigation.getParam('account', { id: undefined, name: '', provider: '', isAsset: IsAsset.Asset });
    return {
      title: account.id !== undefined ? account.name : '',
      headerBackTitle: null,
      headerBackImage: <FeatherIcon name="chevron-left" size={24} color={globalColours.primary} />
    }
  };

  constructor(props) {
    super(props);

    this.state = { accountId: '' };
  }

  _justDate(d) {
    return new Date(d.getFullYear(), d.getMonth(), d.getDate());
  }

  componentDidMount() {
    const accountId = this.props.navigation.getParam('accountId', { accountId: '' });
    const account = this.props.portfolio.accounts.find(x => x.id === accountId);
    this.props.navigation.setParams({ account: account });
    // this._loadAccount(accountId);
    this.setState({ accountId: accountId, account: account });
  }

  render() {
    const { portfolio } = this.props;
    const { accountId } = this.state;
    return (
      <SafeAreaView style={globalStyles.safeAreaView}>
        <ScrollView style={globalStyles.container} contentContainerStyle={globalStyles.contentContainer}>
          <AccountTopBar portfolio={portfolio} accountId={accountId} />
          <View>
            <AccountGrowthChart portfolio={portfolio} accountId={accountId} />
          </View>
          <AccountStats portfolio={portfolio} accountId={accountId} />
          <View>
          </View>
        </ScrollView>
      </SafeAreaView >
    );
  }
}

const mapStateToProps = (state) => {
  const { portfolio } = state
  return { portfolio }
};

export default connect(mapStateToProps)(AccountScreen);
