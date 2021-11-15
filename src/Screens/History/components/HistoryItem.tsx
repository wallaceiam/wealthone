import React from 'react';
import { Text, TouchableOpacity, View } from 'react-native';
import { FormattedCurrency } from 'react-native-globalize';
import ForwardIcon from '../../../Components/Icons/ForwardIcon';
import { justDate } from '../../../Redux/DateHelpers';
import { useStyle } from '../../../Theme';

export const HEIGHT = 64;

export interface IHistoryItemProps {
  readonly item: any;
  readonly selectedIndex: number;
  readonly onClick: () => void;
}

const HistoryItem = ({ item, selectedIndex, onClick }: IHistoryItemProps) => {
  const style = useStyle();
  return (
    <TouchableOpacity onPress={onClick}>
      <View style={[style.swipeRow]}>
        <View style={[style.column, style.noMargins, style.autoMargins]}>
          <Text style={style.text}>{justDate(item.date).toDateString()} </Text>
        </View>
        <View>
          {selectedIndex !== 2 && (
            <FormattedCurrency
              value={
                selectedIndex === 0
                  ? item.total
                  : selectedIndex === 1
                  ? item.changeAmount
                  : item.netflows
              }
              currency="GBP"
              maximumFractionDigits={0}
              minimumFractionDigits={0}
              style={[style.h2]}
            />
          )}
          {selectedIndex === 2 && (
            <Text style={[style.h2]}>
              {(item.changePercent * 100).toFixed(2)}%
            </Text>
          )}
        </View>
        <View style={style.autoMargins}>
          <ForwardIcon />
        </View>
      </View>
    </TouchableOpacity>
  );
};

export default HistoryItem;
