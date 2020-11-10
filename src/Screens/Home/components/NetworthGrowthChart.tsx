import React from 'react';
import { AreaChart } from 'react-native-svg-charts';
import { Path, Defs, LinearGradient, Stop, Rect, Line } from 'react-native-svg';
import * as shape from 'd3-shape';
import * as scale from 'd3-scale';
import { connect } from 'react-redux';
import { useTheme } from '@react-navigation/native';
import { ITheme } from '../../../Theme';

const NetworthGrowthChart = ({ portfolio }) => {
  const theme = useTheme() as ITheme;
  const { stats } = portfolio;
  const { netWorth } = stats || { netWorth: [] };
  const data = (netWorth || []).map((c) => {
    return {
      date: new Date(Date.parse(c.date)),
      value: c.total,
    };
  });

  const Gradient = (any) => (
    <Defs>
      <LinearGradient id={'gradient'} x1={'0%'} y={'0%'} x2={'0%'} y2={'100%'}>
        <Stop
          offset={'0%'}
          stopColor={theme.colors.secondary}
          stopOpacity={0.2}
        />
        <Stop
          offset={'75%'}
          stopColor={theme.colors.secondary}
          stopOpacity={0.0}
        />
      </LinearGradient>
    </Defs>
  );

  const GraphLine = ({ line }) => (
    <Path
      key={'line'}
      d={line}
      stroke={theme.colors.secondary}
      fill={'none'}
    />
  );

  // const VerticalLine = ({ line }) =>
  //   this.state.isPressed ? (
  //     <Line
  //       x1={this.state.pressedX}
  //       x2={this.state.pressedX}
  //       y1={"0%"}
  //       y2={"100%"}
  //       stroke={globalColours.primary}
  //     />
  //   ) : // <Path
  //   //     key={'line'}
  //   //     d={line}
  //   //     stroke={'rgb(134, 65, 244)'}
  //   //     fill={'none'}
  //   // />

  //   null;

  return data.length > 1 ? (
    <AreaChart
      style={{ height: 200 }}
      data={data}
      yAccessor={({ item }) => item.value}
      xAccessor={({ item }) => item.date}
      xScale={scale.scaleTime}
      contentInset={{ top: 30, bottom: 30 }}
      curve={shape.curveNatural}
      svg={{ fill: 'url(#gradient)' }}
      // svg={{ fill: globalColours.primary_o20 }}
    >
      <GraphLine />
      <Defs key={'gradient'}>
        <LinearGradient
          id={'gradient'}
          x1={'0%'}
          y={'0%'}
          x2={'0%'}
          y2={'100%'}>
          <Stop
            offset={'0%'}
            stopColor={theme.colors.secondary}
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

const mapStateToProps = (state) => {
  const { portfolio } = state;
  return { portfolio };
};

export default connect(mapStateToProps)(NetworthGrowthChart);
