import React, { useLayoutEffect, useState } from 'react';
import {
  SafeAreaView,
  ScrollView,
  Text,
  TouchableOpacity,
  View,
} from 'react-native';
import { useNavigation } from '@react-navigation/native';
import SegmentedControlIOS from '@react-native-community/segmented-control';
import { FormattedCurrency } from 'react-native-globalize';
import { connect } from 'react-redux';

import { useTheme, useStyle } from '../../Theme';
import SlidersIcon from '../../Components/Icons/SlidersIcon';
import GoalChart from './components/GoalChart';
import { getGoalResults } from '../../Redux/Selectors';

const GoalsScreen = ({ result }) => {
  const navigation = useNavigation();
  const theme = useTheme();
  const style = useStyle();
  const [selectedIndex, setSelectedIndex] = useState(0);

  useLayoutEffect(() => {
    const onGoToSettings = () => {
      navigation.navigate('GoalsEntry');
    };

    navigation.setOptions({
      title: 'Goals',
      headerRight: () => (
        <TouchableOpacity
          style={style.rightMargin}
          onPress={() => onGoToSettings()}>
          <SlidersIcon />
        </TouchableOpacity>
      ),
    });
  }, [navigation, style.rightMargin]);

  const goalVal = result
    ? selectedIndex === 0
      ? result.projectedSavingsGoal || 0
      : result.projectedIncomeGoal || 0
    : 0;

  const poorVal = result
    ? selectedIndex === 0
      ? result.projectedSavingsPoor || 0
      : result.projectedIncomePoor || 0
    : 0;

  const avgVal = result
    ? selectedIndex === 0
      ? result.projectedSavingsAverage || 0
      : result.projectedIncomeAverage || 0
    : 0;

  return (
    <SafeAreaView style={style.safeAreaView}>
      <ScrollView
        style={style.container}
        contentContainerStyle={style.contentContainer}>
        <View style={style.sideMargins}>
          <SegmentedControlIOS
            values={['Savings', 'Income']}
            selectedIndex={selectedIndex}
            onChange={(event) =>
              setSelectedIndex(event.nativeEvent.selectedSegmentIndex)
            }
          />
        </View>

        <View style={style.bigHeader}>
          <Text style={style.text}>Your goal at retirement</Text>
          <FormattedCurrency
            value={goalVal}
            currency="GBP"
            maximumFractionDigits={0}
            minimumFractionDigits={0}
            style={style.h1}
          />
        </View>

        <View style={style.bigHeader}>
          <Text style={style.text}>On track to have</Text>
          <View>
            <FormattedCurrency
              value={poorVal}
              currency="GBP"
              maximumFractionDigits={0}
              minimumFractionDigits={0}
              style={[style.h1, { paddingBottom: 0, marginBottom: 8 }]}
            />
            <Text style={style.text}>
              if the market performs{' '}
              <Text style={{ fontWeight: 'bold' }}>poorly</Text>
            </Text>
          </View>
          <View>
            <FormattedCurrency
              value={avgVal}
              currency="GBP"
              maximumFractionDigits={0}
              minimumFractionDigits={0}
              style={[
                style.h1,
                {
                  color: theme.colors.secondary,
                  paddingBottom: 0,
                  marginBottom: 8,
                },
              ]}
            />
            <Text style={style.text}>
              if the market performs{' '}
              <Text style={{ fontWeight: 'bold' }}>average</Text>
            </Text>
          </View>
        </View>

        <View>
          <GoalChart
            projectedSavingsPoor={result.projectedSavingsPoor}
            projectedSavingsAverage={result.projectedSavingsAverage}
          />
        </View>
      </ScrollView>
    </SafeAreaView>
  );
};

const mapStateToProps = (state) => {
  const result = getGoalResults(state);
  return { result };
};

export default connect(mapStateToProps)(GoalsScreen);
