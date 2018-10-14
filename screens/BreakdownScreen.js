import React from 'react';
import { ScrollView, StyleSheet } from 'react-native';

import { AssetPieChart } from './../charts/AssetPieChart';

export default class BreakdownScreen extends React.Component {
  static navigationOptions = {
    title: 'Breakdown',
  };

  render() {
    return (
      <ScrollView style={styles.container}>
        
        <AssetPieChart />
      </ScrollView>
    );
  }
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    paddingTop: 15,
    backgroundColor: '#fff',
  },
});
