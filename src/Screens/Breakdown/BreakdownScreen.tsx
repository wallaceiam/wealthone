import React from 'react';
import {SafeAreaView, ScrollView, View, Text} from 'react-native';
import {connect} from 'react-redux';

import PieChart from './components/BreakdownPieChart';

import {useStyle, useTheme} from '../../Theme';

import {IsAsset, AccountTypes} from '../../Models';
import {getAccounts, getNetWorthByAccount} from '../../Redux/Selectors';

const BreakdownScreen = ({accounts, netWorthByAccount}) => {
  const theme = useTheme();
  const style = useStyle();

  const accountKeys = (netWorthByAccount || [])
    .map(v => ({
      id: v.id,
      value:
        v.records[v.records.length - 1] !== undefined
          ? v.records[v.records.length - 1].total
          : 0,
    }))
    .sort((a, b) => a.value - b.value);

  const assetData = (accounts || [])
    .filter(x => x.isAsset === IsAsset.Asset)
    .map(x => ({
      key: `${x.name} - ${x.provider}`,
      value: accountKeys.find(y => y.id === x.id).value,
    }));

  const assetGroupData = (accounts || [])
    .filter(x => x.isAsset === IsAsset.Asset)
    .map(x => ({
      key: AccountTypes.find(a => a.id === x.accountType)?.name,
      value: accountKeys.find(y => y.id === x.id).value,
    }))
    .reduce((p, c) => {
      const prev = p.find(x => x.key === c.key);
      if (prev !== undefined && prev !== null) {
        prev.value += +c.value;
      } else {
        p.push({key: c.key, value: +c.value});
      }
      return p;
    }, []);

  const liabilityData = (accounts || [])
    .filter(x => x.isAsset === IsAsset.Liability)
    .map(x => ({
      key: `${x.name} - ${x.provider}`,
      value: accountKeys.find(y => y.id === x.id).value,
    }));

  const assets =
    assetData.length > 0 ? (
      <View>
        <Text style={[style.sectionHeaderStyle, {color: theme.colors.primary}]}>
          {' '}
          Assets{' '}
        </Text>
        <Text
          style={[
            style.subSectionHeaderStyle,
            {color: theme.colors.secondary},
          ]}>
          {' '}
          By Type{' '}
        </Text>
        <PieChart data={assetGroupData} />
        <Text
          style={[
            style.subSectionHeaderStyle,
            {color: theme.colors.secondary, marginTop: 20},
          ]}>
          By Account
        </Text>
        <PieChart data={assetData} />
      </View>
    ) : null;
  const liabilities =
    liabilityData.length > 0 ? (
      <View>
        <Text style={[style.sectionHeaderStyle, {color: theme.colors.primary}]}>
          {' '}
          Liabilities{' '}
        </Text>
        <Text
          style={[
            style.subSectionHeaderStyle,
            {color: theme.colors.secondary},
          ]}>
          {' '}
          By Account{' '}
        </Text>
        <PieChart data={liabilityData} />
      </View>
    ) : null;

  return (
    <SafeAreaView style={style.safeAreaView}>
      <ScrollView
        style={style.container}
        contentContainerStyle={style.contentContainer}>
        {assets}
        {liabilities}
      </ScrollView>
    </SafeAreaView>
  );
};

const mapStateToProps = state => {
  const accounts = getAccounts(state);
  const netWorthByAccount = getNetWorthByAccount(state);
  return {accounts, netWorthByAccount};
};

export default connect(mapStateToProps)(BreakdownScreen);
