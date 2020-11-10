import React, { useLayoutEffect } from 'react';
import { SafeAreaView, ScrollView, View, Text } from 'react-native';
import { connect } from 'react-redux';

import AccountTopBar from './components/AccountTopBar';
import AccountGrowthChart from './components/AccountGrowthChart';
import AccountStats from './components/AccountStats';

import { useStyle } from './../../Theme';
import { useNavigation, useRoute } from '@react-navigation/native';

const AccountScreen = ({ portfolio }) => {
  const navigation = useNavigation();
  const router = useRoute();
  const style = useStyle();

  const accountId = router.params['accountId'];
  const account = portfolio.accounts.find((x) => x.id === accountId);

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
        <AccountTopBar portfolio={portfolio} accountId={accountId} />

        <AccountGrowthChart portfolio={portfolio} accountId={accountId} />

        <AccountStats portfolio={portfolio} accountId={accountId} />
        <View>
          <Text>{JSON.stringify(router.params)}</Text>
        </View>
      </ScrollView>
    </SafeAreaView>
  );
};

const mapStateToProps = (state) => {
  const { portfolio } = state;
  return { portfolio };
};

export default connect(mapStateToProps)(AccountScreen);
