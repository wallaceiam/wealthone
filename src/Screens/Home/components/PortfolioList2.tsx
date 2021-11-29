import React from 'react';
import { View, SectionList, Platform } from 'react-native';
import { connect } from 'react-redux';

import SectionHeader from '../../../Components/SectionHeader';
import {
  getAssetAccounts,
  getLiabilityAccounts,
  getRecords,
} from '../../../Redux/Selectors';
import AccountItem from './AccountItem';
import HomeTopBar from './HomeTopBar';
import NetworthGrowthChart from './NetworthGrowthChart';

const PortfolioList = ({ assetAccounts, liabilityAccounts, records }) => {
  const last = records.length - 1;

  const assets = assetAccounts.map(x => {
    const lastRecord =
      last >= 0 ? records[last].totals.find(y => y.id === x.id) : undefined;
    return {
      id: x.id,
      name: x.name,
      provider: x.provider,
      amount:
        last < 0
          ? 0
          : lastRecord !== undefined && lastRecord !== null
          ? lastRecord.amount
          : 0,
    };
  });
  const liabilities = liabilityAccounts.map(x => {
    const lastRecord =
      last >= 0 ? records[last].totals.find(y => y.id === x.id) : undefined;
    return {
      id: x.id,
      name: x.name,
      provider: x.provider,
      amount:
        last < 0
          ? 0
          : lastRecord !== undefined && lastRecord !== null
          ? lastRecord.amount
          : 0,
    };
  });

  const renderItem = ({ item }) => <AccountItem item={item} />;

  const header = () => (
    <View style={{ marginBottom: Platform.OS == 'ios' ? 20 : 0 }}>
      <HomeTopBar />
      <NetworthGrowthChart />
    </View>
  );

  const sections =
    assets.length > 0 && liabilities.length > 0
      ? [
          { title: 'Assets', data: assets },
          { title: 'Liabilities', data: liabilities },
        ]
      : assets.length > 0
      ? [{ title: 'Assets', data: assets }]
      : liabilities.length > 0
      ? [{ title: 'Liabilities', data: liabilities }]
      : [];

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
  const assetAccounts = getAssetAccounts(state);
  const liabilityAccounts = getLiabilityAccounts(state);
  const records = getRecords(state);
  return { assetAccounts, liabilityAccounts, records };
};

export default connect(mapStateToProps)(PortfolioList);
