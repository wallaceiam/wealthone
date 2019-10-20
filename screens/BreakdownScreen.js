import React from 'react';
import { ScrollView, View, StyleSheet, Text, AlertIOS } from 'react-native';
import { SafeAreaView } from 'react-navigation';
import { connect } from 'react-redux';

import AssetPieChart from './../charts/AssetPieChart';

import { globalStyles } from './../Style';
import { globalColours } from '../Colours';

import { IsAsset, AccountTypes } from '../models/Account';
import StackedAccountGrowthChart from '../charts/StackedAccountGrowthChart';

class BreakdownScreen extends React.PureComponent {
  static navigationOptions = {
    title: 'Breakdown',
  };

  render() {
    try {
    const { stats, accounts } = this.props.portfolio;
    const { byAccount } = (stats || { byAccount: [] });
    
    const accountKeys = (byAccount || [])
      .map(v => ({
        id: v.id, value: v.records[v.records.length - 1] !== undefined ?
          v.records[v.records.length - 1].total : 0
      })).sort((a, b) => a.value - b.value);

    const assetData = (accounts || [])
      .filter(x => x.isAsset === IsAsset.Asset)
      .map(x => ({
        key: `${x.name} - ${x.provider}`,
        value: accountKeys.find(y => y.id === x.id).value
      }));

    const assetGroupData = (accounts || [])
      .filter(x => x.isAsset === IsAsset.Asset)
      .map(x => ({
        key: AccountTypes.find(a => a.id === x.accountType).name,
        value: accountKeys.find(y => y.id === x.id).value
      }))
      .reduce((p, c) => {
        const prev = p.find(x => x.key === c.key);
        if (prev !== undefined && prev !== null) {
          prev.value += +c.value;
        } else {
          p.push({ key: c.key, value: +c.value });
        }
        return p;
      }, []);

    /*const assetGrowthData = (accounts || [])
      .filter(x => x.isAsset === IsAsset.Asset)
      .reduce((p, c) => {
        const values = (byAccount || []).find(x => x.id === c.id).records;
        (values || []).forEach(v => {
          const prev = p.find(x => x.date === v.date);
          if (prev !== undefined && prev !== null) {
            prev[c.id] = +v.total;
          } else {
            const newValue = {
              date: v.date,
            };
            newValue[c.id] = +v.total;
            p.push(newValue);
          }
        });
        return p;
      }, []);

    const assetGroupGrowthData = (accounts || [])
      .filter(x => x.isAsset === IsAsset.Asset)
      .reduce((p, c) => {
        const values = (byAccount || []).find(x => x.id === c.id).records;
        const key = AccountTypes.find(x => x.id === c.accountType).name;
        (values || []).forEach(v => {
          const prev = p.find(x => x.date === v.date);
          if (prev !== undefined && prev !== null) {
            prev[key] =+ +v.total;
          } else {
            const newValue = {
              date: v.date,
            };
            newValue[key] =+ +v.total;
            p.push(newValue);
          }
        });
        return p;
      }, []);

    const assetGrowthKeys = (accounts || [])
      .filter(x => x.isAsset === IsAsset.Asset)
      .map(x => x.id);

    const assetGroupGrowthKeys = (accounts || [])
      .filter(x => x.isAsset === IsAsset.Asset)
      .reduce((p, c) => {
        const name = AccountTypes.find(y => y.id === c.accountType).name;
        if(!p.includes(name)) {
          p.push(name);
        }
        return p;
      }, []);
      */

    const liabilityData = (accounts || [])
      .filter(x => x.isAsset === IsAsset.Liability)
      .map(x => ({
        key: `${x.name} - ${x.provider}`,
        value: accountKeys.find(y => y.id === x.id).value
      }));



    const assets = assetData.length > 0 ? (
      <View>
        <Text style={globalStyles.sectionHeaderStyle}> Assets </Text>
        <Text style={globalStyles.subSectionHeaderStyle}> By Type </Text>
        <AssetPieChart data={assetGroupData} />
         {/* <StackedAccountGrowthChart data={assetGroupGrowthData} keys={assetGroupGrowthKeys} />  */}
        <Text style={[globalStyles.subSectionHeaderStyle, { marginTop: 20 }]}> By Account </Text>
        <AssetPieChart data={assetData} />
        {/* <StackedAccountGrowthChart data={assetGrowthData} keys={assetGrowthKeys} /> */}
        

      </View>
    ) : null;
    const liabilities = liabilityData.length > 0 ? (
      <View>
        <Text style={globalStyles.sectionHeaderStyle}> Liabilities </Text>
        <AssetPieChart data={liabilityData} />
      </View>
    ) : null;

    return (
      <SafeAreaView style={globalStyles.safeAreaView}>
        <ScrollView style={globalStyles.container} contentContainerStyle={globalStyles.contentContainer}>

          {assets}

          {liabilities}

        </ScrollView>
      </SafeAreaView>
    );

    }
    catch(e) {
      AlertIOS.alert(e);
      return null;
    }
  }
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    paddingTop: 15,
    backgroundColor: '#fff',
  },
});

const mapStateToProps = (state) => {
  const { portfolio } = state
  return { portfolio }
};

export default connect(mapStateToProps)(BreakdownScreen);
