import React, { useState } from 'react';
import {
  SafeAreaView,
  SectionList,
  Text,
  View,
  TouchableOpacity,
} from 'react-native';
import SegmentedControlIOS from '@react-native-community/segmented-control';
import { FormattedCurrency } from 'react-native-globalize';
import { useNavigation } from '@react-navigation/native';

import { connect } from 'react-redux';

import { useStyle } from '../../Theme';

import { justDate } from '../../Redux/DateHelpers';
import SectionHeader from '../../Components/SectionHeader';
import ForwardIcon from '../../Components/Icons/ForwardIcon';

const HistoryItem = ({ item, selectedIndex, onClick}) => {
  const style = useStyle();
  return (
    <TouchableOpacity onPress={onClick}>
      <View style={style.row}>
        <View style={[style.column, style.noMargins, style.autoMargins]}>
          <Text style={style.text}>{justDate(item.date).toDateString()} </Text>
        </View>
        <View>
          {selectedIndex === 0 ? (
            <FormattedCurrency
              value={item.total}
              currency="GBP"
              maximumFractionDigits={0}
              minimumFractionDigits={0}
              style={[style.h2]}
            />
          ) : selectedIndex === 1 ? (
            <FormattedCurrency
              value={item.changeAmount}
              currency="GBP"
              maximumFractionDigits={0}
              minimumFractionDigits={0}
              style={[style.h2]}
            />
          ) : selectedIndex === 2 ? (
            <Text style={[style.h2]}>
              {(item.changePercent * 100).toFixed(2)}%
            </Text>
          ) : (
            <FormattedCurrency
              value={item.netflows}
              currency="GBP"
              maximumFractionDigits={0}
              minimumFractionDigits={0}
              style={[style.h2]}
            />
          )}
        </View>
        <View
          style={{
            marginTop: 'auto',
            marginBottom: 'auto',
          }}>
          <ForwardIcon />
        </View>
      </View>
    </TouchableOpacity>
  );
};

const HistoryScreen = ({ portfolio }) => {
  const navigation = useNavigation();
  const style = useStyle();

  const [selectedIndex, setSelectedIndex] = useState(0);

  const onEntrySelected = ({ item }) => {
    navigation.navigate('HistoryEntry', {
      date: new Date(item.date).getTime(),
    });
  };

  const { stats } = portfolio;
  const { netWorth } = stats;

  const allYears = (netWorth || []).map((v) => justDate(v.date).getFullYear());
  const uniqueYears = [...new Set(allYears)].reverse();

  const sections = uniqueYears.map((v) => {
    return {
      title: v.toString(),
      data: (netWorth || [])
        .filter((x) => justDate(x.date).getFullYear() === v)
        .map((c) => {
          return {
            date: c.date,
            total: c.total,
            changeAmount: c.changeAmount,
            changePercent: c.changePercent,
            netflows: c.netflows,
          };
        })
        .reverse(),
    };
  });

  return (
    <SafeAreaView style={style.safeAreaView}>
      <View style={[style.container, style.contentContainer]}>
        <View style={style.sideMargins}>
          <SegmentedControlIOS
            values={['Total', '+/-', '%', 'Netflows']}
            selectedIndex={selectedIndex}
            onChange={(event) =>
              setSelectedIndex(event.nativeEvent.selectedSegmentIndex)
            }
          />
        </View>

        <SectionList
          style={style.container}
          renderItem={(item) => (
            <HistoryItem item={item.item} selectedIndex={selectedIndex} onClick={() => onEntrySelected(item)} />
          )}
          renderSectionHeader={({ section }) => (
            <SectionHeader title={section.title} />
          )}
          stickySectionHeadersEnabled={true}
          keyExtractor={(item, index) => `${index}-${selectedIndex}`}
          sections={sections}
        />
      </View>
    </SafeAreaView>
  );
};

const mapStateToProps = (state) => {
  const { portfolio } = state;
  return { portfolio };
};

export default connect(mapStateToProps)(HistoryScreen);
