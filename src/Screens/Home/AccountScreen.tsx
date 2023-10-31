import React, {useLayoutEffect} from 'react';
import {SafeAreaView} from 'react-native';
import {connect} from 'react-redux';

import AccountStats from './components/AccountStats';

import {useStyle} from './../../Theme';
import {useNavigation, useRoute} from '@react-navigation/native';
import {getAccounts} from '../../Redux/Selectors';
import {IAccount} from '../../Redux/IAccount';

interface props {
  accounts: IAccount[];
}

const AccountScreen = ({accounts}: props) => {
  const navigation = useNavigation();
  const router = useRoute();
  const style = useStyle();

  const {accountId} = router.params as any;
  const account = accounts.find(x => x.id === accountId);

  useLayoutEffect(() => {
    navigation.setOptions({
      title: account.name || '',
    });
  }, [navigation, account]);

  return (
    <SafeAreaView style={style.safeAreaView}>
      <AccountStats accountId={accountId} />
    </SafeAreaView>
  );
};

const mapStateToProps = state => {
  const accounts = getAccounts(state);
  return {accounts};
};

export default connect(mapStateToProps)(AccountScreen);
