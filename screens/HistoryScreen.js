import React from 'react';
import { SafeAreaView, SectionList, Text, View, ScrollView, TouchableOpacity, SegmentedControlIOS } from 'react-native';
import { FormattedCurrency } from 'react-native-globalize';
import FeatherIcon from 'react-native-vector-icons/Feather';

import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';

import { globalStyles } from './../Style';
import { globalColours } from './../Colours';

import { backup, restore } from './../redux/Actions';
import { IsAsset } from '../models/Account';

import { justDate } from './../helpers/Date';

class HistoryScreen extends React.Component {
  static navigationOptions = ({ navigate, navigation }) => ({
    title: 'History',
    headerBackTitleVisible: false,
    headerBackTitle: null
  });

  constructor(props) {
    super(props);
    this.state = {
      selectedIndex: 0
    }
  }

  render() {
    // const { manifest } = Constants;
    const { stats } = this.props.portfolio;
    const { netWorth } = stats;

    const allYears = (netWorth || []).map((v) => justDate(v.date).getFullYear());
    const uniqueYears = [...new Set(allYears)].reverse();

    const sections = uniqueYears.map((v) => {
      return {
        title: v.toString(),
        data: (netWorth || []).filter(x => justDate(x.date).getFullYear() === v).map((c) => {
          return {
            date: c.date,
            total: c.total,
            changeAmount: c.changeAmount,
            changePercent: c.changePercent,
            netflows: c.netflows
          }
        }).reverse()
      }
    });



    return (
      <SafeAreaView style={globalStyles.safeAreaView}>

        <ScrollView style={globalStyles.container} contentContainerStyle={globalStyles.contentContainer}>

          <View style={globalStyles.sideMargins}>
            <SegmentedControlIOS
              values={['Total', '+/-', '%', 'Netflows']}
              tintColor={globalColours.primary}
              selectedIndex={this.state.selectedIndex}
              onChange={(event) => {
                this.setState({ selectedIndex: event.nativeEvent.selectedSegmentIndex });
              }}
            />
          </View>

          <SectionList
            style={globalStyles.container}
            renderItem={this._renderItem}
            renderSectionHeader={({ section }) => <Text style={globalStyles.sectionHeaderStyle}> {section.title} </Text>}
            renderSectionFooter={this._readerSectionFooter}
            stickySectionHeadersEnabled={true}
            keyExtractor={(item, index) => index}
            sections={sections}
          />

        </ScrollView>

      </SafeAreaView >
    );
  }

  _renderItem = ({ item }) => {

    return (
      <TouchableOpacity onPress={this.onEntrySelected.bind(this, item)}>
        <View style={globalStyles.row}>
          <View style={{
            flex: 1,
            flexDirection: 'column',
            justifyContent: 'space-between',
            marginTop: 'auto',
            marginBottom: 'auto'
          }}>
            <Text>{justDate(item.date).toDateString()} </Text>
          </View>
          <View>
            {this.state.selectedIndex === 0 ? (<FormattedCurrency
              value={item.total}
              currency="GBP"
              maximumFractionDigits={0}
              minimumFractionDigits={0}
              style={[globalStyles.h2]} />)
              : (this.state.selectedIndex === 1 ? (
                <FormattedCurrency
                  value={item.changeAmount}
                  currency="GBP"
                  maximumFractionDigits={0}
                  minimumFractionDigits={0}
                  style={[globalStyles.h2]}
                />
              ) : (this.state.selectedIndex === 2) ? (
                <Text style={[globalStyles.h2]}>
                  {(item.changePercent * 100).toFixed(2)}%
                        </Text >
              ) : (<FormattedCurrency
                value={item.netflows}
                currency="GBP"
                maximumFractionDigits={0}
                minimumFractionDigits={0}
                style={[globalStyles.h2]}
              />))}

          </View>
          <View style={{
            marginTop: 'auto',
            marginBottom: 'auto'
          }}>
            <FeatherIcon name="chevron-right" color={globalColours.primary} />
          </View>
        </View>
      </TouchableOpacity>
    );
  };

  onEntrySelected = (item) => {
    this.props.navigation.navigate('HistoryEntry', { date: justDate(item.date) });
  }

}

const mapStateToProps = (state) => {
  const { portfolio } = state
  return { portfolio }
};

const mapDispatchToProps = dispatch => (
  bindActionCreators({
    backup,
    restore,
  }, dispatch)
);

export default connect(mapStateToProps, mapDispatchToProps)(HistoryScreen);
