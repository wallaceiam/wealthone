import React from 'react';
import { View, SectionList, Platform } from 'react-native';
import { connect } from 'react-redux';

import SectionHeader from '../../../Components/SectionHeader';
import { getNetWorthByAccount } from '../../../Redux/Selectors';
import AccountGrowthChart from './AccountGrowthChart';
import AccountStatItem from './AccountStatItem';
import AccountTopBar from './AccountTopBar';

const AccountStats = ({ netWorthByAccount, accountId }) => {
  if (accountId === null || accountId === undefined || accountId === '') {
    return null;
  }
  const accountStats = (netWorthByAccount || []).find(x => x.id === accountId);
  if (accountStats === null || accountStats === undefined) {
    return null;
  }

  if (accountStats.records.length < 1) {
    return null;
  }

  const last = accountStats.records[accountStats.records.length - 1];
  const first = accountStats.records[0];

  const totalGrowth = last.total - first.total;
  const totalGrowthPerc = first.total !== 0 ? totalGrowth / first.total : 0;

  const totalData = [
    { name: 'Growth', value: totalGrowth, type: 'currency' },
    { name: 'Growth %', value: totalGrowthPerc, type: 'percent' },
    { name: 'Profit/Loss', value: last.totalPL, type: 'currency' },
    { name: 'Profit/Loss %', value: last.totalPLPercent, type: 'percent' },
    { name: 'TWRR', value: last.twrrPercent, type: 'percent' },
    { name: 'Netflows', value: last.totalNetflows, type: 'currency' },
  ];

  const ytdData = [
    { name: 'Growth', value: last.yearlyGrowth, type: 'currency' },
    { name: 'Growth %', value: last.yearlyGrowthPercent, type: 'percent' },
    { name: 'Profit/Loss', value: last.yearlyPL, type: 'currency' },
    { name: 'Profit/Loss %', value: last.yearlyPLPercent, type: 'percent' },
    { name: 'TWRR', value: last.yearlyTwrrPercent, type: 'percent' },
    { name: 'Netflows', value: last.yearlyNetflows, type: 'currency' },
    {
      name: 'Netflows (Tax Year)',
      value: last.taxYearNetflows,
      type: 'currency',
    },
  ];

  const sections = [
    { title: 'YTD', data: ytdData },
    { title: 'Total', data: totalData },
  ];

  const renderItem = ({ item }) => {
    return <AccountStatItem item={item} />;
  };

  const header = () => (
    <View style={{ marginBottom: Platform.OS == 'ios' ? 20 : 0 }}>
      <AccountTopBar accountId={accountId} />
      <AccountGrowthChart accountId={accountId} />
    </View>
  );

  return (
    <SectionList
      ListHeaderComponent={header}
      sections={sections}
      renderSectionHeader={({ section }) => (
        <SectionHeader title={section.title} />
      )}
      renderItem={renderItem}
    />
  );
};

const mapStateToProps = state => {
  const netWorthByAccount = getNetWorthByAccount(state);
  return { netWorthByAccount };
};

export default connect(mapStateToProps)(AccountStats);
