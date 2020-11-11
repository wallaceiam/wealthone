import React from 'react';
import {
  View,
  SectionList,
  Text,
  Platform,
  TouchableOpacity,
} from 'react-native';
import { useNavigation } from '@react-navigation/native';
import { FormattedCurrency } from 'react-native-globalize';
import { connect } from 'react-redux';

import { useStyle } from '../../../Theme';
import { IsAsset } from '../../..//Models/Account';
import SectionHeader from '../../../Components/SectionHeader';
import ForwardIcon from '../../../Components/Icons/ForwardIcon';
import {
  getAccounts,
  getAssetAccounts,
  getLiabilityAccounts,
  getRecords,
} from '../../../Redux/Selectors';

const PortfolioList = ({ assetAccounts, liabilityAccounts, records }) => {
  const navigation = useNavigation();
  const style = useStyle();

  const onPortfolioSelected = (item) => {
    navigation.navigate('HomeAccount', { accountId: item.id });
  };

  const renderItem = ({ item }) => (
    <TouchableOpacity onPress={() => onPortfolioSelected(item)}>
      <View style={style.row}>
        <View style={[style.column, style.noMargins, style.autoMargins]}>
          <Text style={style.text}>{item.name} </Text>
          {item.provider !== undefined && item.provider !== '' && (
            <Text style={style.text}>{item.provider} </Text>
          )}
        </View>
        <View>
          {!isNaN(+item.amount) && (
            <FormattedCurrency
              value={+item.amount}
              currency="GBP"
              maximumFractionDigits={0}
              minimumFractionDigits={0}
              style={style.h2}
            />
          )}
        </View>
        <View style={style.autoMargins}>
          <ForwardIcon />
        </View>
      </View>
    </TouchableOpacity>
  );

  const last = records.length - 1;

  const assets = assetAccounts
    .map((x) => {
      const lastRecord =
        last >= 0 ? records[last].totals.find((y) => y.id === x.id) : undefined;
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
  const liabilities = liabilityAccounts
    .map((x) => {
      const lastRecord =
        last >= 0 ? records[last].totals.find((y) => y.id === x.id) : undefined;
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
    <View style={{ marginTop: Platform.OS == 'ios' ? 20 : 0 }}>
      <SectionList
        sections={sections}
        renderSectionHeader={({ section }) => (
          <SectionHeader title={section.title} />
        )}
        renderItem={renderItem}
        keyExtractor={(item, index) => `${index}`}
      />
    </View>
  );
};

const mapStateToProps = (state) => {
  const assetAccounts = getAssetAccounts(state);
  const liabilityAccounts = getLiabilityAccounts(state);
  const records = getRecords(state);
  return { assetAccounts, liabilityAccounts, records };
};

export default connect(mapStateToProps)(PortfolioList);
