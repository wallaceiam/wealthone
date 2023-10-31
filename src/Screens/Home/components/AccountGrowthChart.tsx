import React from 'react';
import {connect} from 'react-redux';
import {Path} from 'react-native-svg';
import {AreaChart} from 'react-native-svg-charts';
import {Defs, LinearGradient, Stop} from 'react-native-svg';
import * as shape from 'd3-shape';
import * as scale from 'd3-scale';

import {useTheme} from '../../../Theme';
import {getNetWorthByAccount} from '../../../Redux/Selectors';

const AccountGrowthChart = ({netWorthByAccount, accountId}) => {
  const theme = useTheme();

  const account =
    (netWorthByAccount || []).length > 0
      ? netWorthByAccount.find(x => x.id === accountId)
      : undefined;

  if (account === undefined) {
    return null;
  }
  const data = (account.records || []).map(c => {
    return {
      date: new Date(Date.parse(c.date)),
      value: c.total,
    };
  });

  const Gradient = ({index}) => (
    <Defs key={index}>
      <LinearGradient id={'gradient'} x1={'0%'} y1={'0%'} x2={'0%'} y2={'100%'}>
        <Stop
          offset={'0%'}
          stopColor={theme.colors.secondary}
          stopOpacity={0.2}
        />
        <Stop offset={'75%'} stopColor={theme.colors.white} stopOpacity={0.0} />
      </LinearGradient>
    </Defs>
  );

  const Line = ({line}) => (
    <Path key={'line'} d={line} stroke={theme.colors.primary} fill={'none'} />
  );

  return data.length > 1 ? (
    <AreaChart
      style={{height: 200}}
      data={data}
      yAccessor={({item}) => item.value}
      xAccessor={({item}) => item.date}
      xScale={scale.scaleTime}
      contentInset={{top: 30, bottom: 30}}
      curve={shape.curveNatural}
      svg={{fill: 'url(#gradient)', viewBox: '0 0 200 200'}}
      // svg={{ fill: globalColours.primary_o20 }}
    >
      <Line />
      <Defs>
        <LinearGradient
          id={'gradient'}
          x1={'0%'}
          y={'0%'}
          x2={'0%'}
          y2={'100%'}>
          <Stop
            offset={'0%'}
            stopColor={theme.colors.primary}
            stopOpacity={0.2}
          />
          <Stop
            offset={'75%'}
            stopColor={theme.colors.white}
            stopOpacity={0.0}
          />
        </LinearGradient>
      </Defs>
    </AreaChart>
  ) : null;
};

const mapStateToProps = state => {
  const netWorthByAccount = getNetWorthByAccount(state);
  return {netWorthByAccount};
};

export default connect(mapStateToProps)(AccountGrowthChart);
