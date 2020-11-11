import React, { useState } from 'react';
import { View, Dimensions, Text } from 'react-native';
import { FormattedCurrency } from 'react-native-globalize';
import * as scale from 'd3-scale';
import PieChart from './PieChart';

import { useStyle, useTheme } from '../../../Theme';

const BreakdownPieChart = ({ data }) => {
  const theme = useTheme();
  const style = useStyle();

  const [selectedLabel, setSelectedLabel] = useState('');
  const [selectedValue, setSelectedValue] = useState(0);
  const [firstSet, setFirstSet] = useState(false);
  const [labelWidth, setLabelWidth] = useState(0);

  const _onLayout = (key, value) => {
    if (selectedLabel !== key && !firstSet) {
      setTimeout(() => {
        setSelectedLabel(key);
        setSelectedValue(value);
        setFirstSet(false);
      }, 250);
    }
  };

  const length = (data || []).length;
  const colors = scale
    .scaleOrdinal()
    .domain([0, length])
    // .range(['#1E2833', '#2A4054', '#5E7A92', '#A1B3C4', '#CBD5E0', '#E5E7EE']);
    .range([
      theme.colors.primary,
      theme.colors.secondary,
      theme.colors.tertiary,
      theme.colors.quaternary,
      theme.colors.quinary,
      theme.colors.senary,
    ]);

  const total = (data || []).reduce((p, c) => p + c.value, 0);
  // const keys = ['google', 'facebook', 'linkedin', 'youtube', 'Twitter'];
  // const values = [15, 25, 35, 45, 55];
  // const colors = ['#600080', '#9900cc', '#c61aff', '#d966ff', '#ecb3ff']
  //const colors = ['#800060', '#cc0099', '#ff1ac6', '#ff66d9', '#ffb3ec']

  const pieData = data.map((item, index) => {
    const perc = total !== 0 ? (item.value / total) * 100 : 0;
    return {
      key: item.key,
      value: perc,
      svg: {
        fill: colors(index),
        onPress: () => {
          setSelectedLabel(item.key);
          setSelectedValue(item.value);
        },
        onPressIn: () => {
          setSelectedLabel(item.key);
          setSelectedValue(item.value);
        },
      },
      arc: {
        outerRadius: selectedLabel === item.key ? '125%' : '120%',
        innerRadius: selectedLabel === item.key ? '85%' : '80%',
        padAngle: selectedLabel === item.key ? 0.05 : 0,
      },
      onPress: () => {
        setSelectedLabel(item.key);
        setSelectedValue(item.value);
      },
      onPressIn: () => {
        setSelectedLabel(item.key);
        setSelectedValue(item.value);
      },
    };
  });
  const deviceWidth = Dimensions.get('window').width;
  const firstKey = data.length > 0 ? data[0].key : '';
  const firstValue = data.length > 0 ? data[0].value : 0;

  return (
    <View
      style={{ justifyContent: 'center', flex: 1 }}
      onLayout={() => _onLayout(firstKey, firstValue)}>
      <PieChart
        style={{ height: 200 }}
        outerRadius={'80%'}
        innerRadius={'60%'}
        data={pieData}
        animate={true}
      />
      <View
        onLayout={({
          nativeEvent: {
            layout: { width },
          },
        }) => setLabelWidth(width)}
        style={{
          position: 'absolute',
          left: deviceWidth / 2 - labelWidth / 2,
        }}>
        <Text style={{ color: theme.colors.secondary, textAlign: 'center' }}>
          {selectedLabel}
        </Text>
        <FormattedCurrency
          value={selectedValue}
          currency="GBP"
          maximumFractionDigits={0}
          minimumFractionDigits={0}
          style={[
            style.h2,
            { color: theme.colors.secondary, textAlign: 'center' },
          ]}
        />
      </View>
    </View>
  );
};

export default BreakdownPieChart;
