import React from 'react';
import { View, Text, TouchableOpacity } from 'react-native';
import { useNavigation } from '@react-navigation/native';
import { FormattedCurrency } from 'react-native-globalize';
import ForwardIcon from '../../../Components/Icons/ForwardIcon';

import { useStyle } from '../../../Theme';

const AccountItem = ({ item }) => {
  const navigation = useNavigation();
  const style = useStyle();

  const onPortfolioSelected = ({ id }) => {
    navigation.navigate('HomeAccount', { accountId: id });
  };

  return (
    <TouchableOpacity onPress={() => onPortfolioSelected(item)}>
      <View style={style.row}>
        <View style={[style.column, style.noMargins, style.autoMargins]}>
          <Text style={style.text}>{item.name} </Text>
          {item.provider !== undefined && item.provider !== '' && (
            <Text style={style.subText}>{item.provider} </Text>
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
};

export default AccountItem;
