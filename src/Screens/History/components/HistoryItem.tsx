
import React from 'react';
import { Text, TouchableOpacity, View } from 'react-native';
import { FormattedCurrency } from 'react-native-globalize';
import ForwardIcon from '../../../Components/Icons/ForwardIcon';
import { justDate } from '../../../Redux/DateHelpers';
import { useStyle } from '../../../Theme';

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

export default HistoryItem;