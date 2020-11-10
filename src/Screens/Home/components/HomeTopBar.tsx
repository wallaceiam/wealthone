import React from 'react';
import { Text, View } from 'react-native';
import { connect } from 'react-redux';
import { FormattedCurrency } from 'react-native-globalize';
import { useStyle } from '../../../Theme';

const HomeTopBar = ({ portfolio }) => {
  const style = useStyle();

  const { stats } = portfolio;
  const { netWorth } = stats || { netWorth: [] };
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

const mapStateToProps = (state) => {
  const { portfolio } = state;
  return { portfolio };
};

export default connect(mapStateToProps)(HomeTopBar);
