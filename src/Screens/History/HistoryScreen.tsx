import React, { useState } from 'react';
import {
  SafeAreaView,
  SectionList,
  View,
} from 'react-native';
import SegmentedControlIOS from '@react-native-community/segmented-control';
import { useNavigation } from '@react-navigation/native';

import { connect } from 'react-redux';

import { useStyle } from '../../Theme';

import { justDate } from '../../Redux/DateHelpers';
import SectionHeader from '../../Components/SectionHeader';
import HistoryItem from './components/HistoryItem';
import { getNetWorth } from '../../Redux/Selectors';

const HistoryScreen = ({ netWorth }) => {
  const navigation = useNavigation();
  const style = useStyle();

  const [selectedIndex, setSelectedIndex] = useState(0);

  const onEntrySelected = ({ item }) => {
    navigation.navigate('HistoryEntry', {
      date: new Date(item.date).getTime(),
    });
  };

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
  const netWorth = getNetWorth(state);
  return { netWorth };
};

export default connect(mapStateToProps)(HistoryScreen);
