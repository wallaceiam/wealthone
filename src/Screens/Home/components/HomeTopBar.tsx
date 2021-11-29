import React from 'react';
import { Text, View } from 'react-native';
import { connect } from 'react-redux';
import { FormattedCurrency } from 'react-native-globalize';
import { useStyle } from '../../../Theme';
import { getNetWorth } from '../../../Redux/Selectors';

const HomeTopBar = ({ netWorth }) => {
  const style = useStyle();

  const interm =
    (netWorth || []).length > 0 ? netWorth[netWorth.length - 1].total : 0;
  const latest = interm || 0;

  return (
    <View style={style.bigHeader}>
      <Text style={style.h3}>Your total net worth</Text>
      <FormattedCurrency
        value={latest}
        currency="GBP"
        maximumFractionDigits={0}
        minimumFractionDigits={0}
        style={style.h1}
      />
    </View>
  );
};

const mapStateToProps = state => {
  const netWorth = getNetWorth(state);
  return { netWorth };
};

export default connect(mapStateToProps)(HomeTopBar);
