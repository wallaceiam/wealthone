import React from 'react';
import {View, Text} from 'react-native';
import {FormattedCurrency} from 'react-native-globalize';

import {useStyle} from '../../../Theme';

const AccountStatItem = ({item}) => {
  const style = useStyle();

  return (
    <View style={style.row}>
      <View style={[style.column, style.noMargins, style.autoMargins]}>
        <Text style={style.text}>{item.name} </Text>
      </View>
      <View>
        {item.type === 'currency' ? (
          <FormattedCurrency
            value={item.value}
            currency="GBP"
            maximumFractionDigits={0}
            minimumFractionDigits={0}
            style={style.h2}
          />
        ) : (
          <Text style={style.h2}>{(item.value * 100).toFixed(2)}%</Text>
        )}
      </View>
    </View>
  );
};

export default AccountStatItem;
