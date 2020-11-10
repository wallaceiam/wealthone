import React from 'react';
import { Text, View } from 'react-native';
import { FormattedCurrency } from 'react-native-globalize';

import { useStyle } from './../../../Theme';

const AccountTopBar = ({ portfolio, accountId }) => {
  const style = useStyle();

  const { stats, accounts } = portfolio;
  const { byAccount } = stats || { byAccount: [] };
  const account =
    (byAccount || []).length > 0
      ? byAccount.find((x) => x.id === accountId)
      : undefined;
  const latest =
    account !== undefined && account !== null && account.records.length > 0
      ? account.records[account.records.length - 1].total
      : 0;
  const nAccount = accounts.find((x) => x.id === accountId);
  const accountName =
    nAccount !== undefined && nAccount !== null
      ? `${nAccount.name} - ${nAccount.provider}`
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

export default AccountTopBar;
