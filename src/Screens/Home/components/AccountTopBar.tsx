import React from 'react';
import {Text, View} from 'react-native';
import {FormattedCurrency} from 'react-native-globalize';
import {connect} from 'react-redux';

import {getAccounts, getNetWorthByAccount} from '../../../Redux/Selectors';
import {useStyle} from './../../../Theme';

const AccountTopBar = ({accounts, netWorthByAccount, accountId}) => {
  const style = useStyle();

  const account =
    (netWorthByAccount || []).length > 0
      ? netWorthByAccount.find(x => x.id === accountId)
      : undefined;
  const latest =
    account !== undefined && account !== null && account.records.length > 0
      ? account.records[account.records.length - 1].total
      : 0;
  const nAccount = accounts.find(x => x.id === accountId);
  const accountName =
    nAccount !== undefined && nAccount !== null
      ? `${nAccount.name}${nAccount.provider ? ` - ${nAccount.provider}` : ''}`
      : '';

  return (
    <View style={style.bigHeader}>
      <Text style={style.h2}>{accountName}</Text>
      <FormattedCurrency
        value={latest}
        currency="GBP"
        maximumFractionDigits={0}
        minimumFractionDigits={0}
        style={style.h1}
      />
    </View>
  );
};

const mapStateToProps = state => {
  const accounts = getAccounts(state);
  const netWorthByAccount = getNetWorthByAccount(state);
  return {accounts, netWorthByAccount};
};

export default connect(mapStateToProps)(AccountTopBar);
