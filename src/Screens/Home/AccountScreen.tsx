import React, { useLayoutEffect } from 'react';
import { SafeAreaView, ScrollView, View, Text } from 'react-native';
import { connect } from 'react-redux';

import AccountTopBar from './components/AccountTopBar';
import AccountGrowthChart from './components/AccountGrowthChart';
import AccountStats from './components/AccountStats';

import { useStyle } from './../../Theme';
import { useNavigation, useRoute } from '@react-navigation/native';
import { getAccounts } from '../../Redux/Selectors';

const AccountScreen = ({ accounts }) => {
  const navigation = useNavigation();
  const router = useRoute();
  const style = useStyle();

  const accountId = router.params['accountId'];
  const account = accounts.find((x) => x.id === accountId);

  useLayoutEffect(() => {
    navigation.setOptions({
      title: account?.name || '',
    });
  }, [account]);

  return (
    <SafeAreaView style={style.safeAreaView}>
      <ScrollView
        style={style.container}
        contentContainerStyle={style.contentContainer}>
        <AccountTopBar accountId={accountId} />

        <AccountGrowthChart accountId={accountId} />

        <AccountStats accountId={accountId} />
      </ScrollView>
    </SafeAreaView>
  );
};

const mapStateToProps = (state) => {
  const accounts = getAccounts(state);
  return { accounts };
};

export default connect(mapStateToProps)(AccountScreen);
