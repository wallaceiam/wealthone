import React from 'react';
import { View, StyleSheet } from 'react-native';
import { Path, Defs, LinearGradient, Stop } from 'react-native-svg';
import { AreaChart } from 'react-native-svg-charts';
import { connect } from 'react-redux';
import * as scale from 'd3-scale';
import * as shape from 'd3-shape';

import { useTheme } from '../../../Theme';
import { toUtc } from '../../../Redux/DateHelpers';
import { CAGR } from './Finance';
import { getGoalInput, getNetWorth } from '../../../Redux/Selectors';

const GoallChart = ({
  netWorth,
  goal,
  projectedSavingsPoor,
  projectedSavingsAverage,
}) => {
  const theme = useTheme();

  const getDataRange = (startDate, endDate) => {
    const interval = 1;

    let retVal = [];
    let current = new Date(startDate);

    retVal.push(new Date(current));
    do {
      current = addMonthsUTC(current, interval);
      retVal.push(new Date(current));
    } while (current <= endDate);

    return retVal;
  };
  const addMonthsUTC = (date: Date, count: number): Date => {
    const m = date.getUTCMonth() + count;
    const year = date.getUTCFullYear() + (m > 12 ? 1 : 0);
    const month = m > 12 ? m - 12 : m;
    const day = date.getUTCDate();

    return new Date(Date.UTC(year, month, day));
  };

  const addYearsUTC = (date: Date, count: number): Date =>
    new Date(
      Date.UTC(
        date.getUTCFullYear() + count,
        date.getUTCMonth(),
        date.getUTCDay(),
      ),
    );

  const createPrediction = (
    startDate,
    startAmount,
    endDate,
    endAmount,
    monthlyContributions,
  ) => {
    const preddates = getDataRange(startDate, endDate);
    const totalContributions = monthlyContributions * (preddates.length - 1);
    const rate =
      CAGR(
        startAmount + totalContributions,
        endAmount,
        Math.floor(preddates.length / 12),
      ) /
      100 /
      7;
    let amount = startAmount + monthlyContributions;
    console.log(rate);
    const result = preddates.map((v) => {
      amount += monthlyContributions + amount * rate;
      return {
        value: amount,
        date: v,
      };
    });
    return result;
  };

  const actuals = (netWorth || []).map((c) => {
    return {
      date: new Date(Date.parse(c.date)),
      value: c.total,
    };
  });

  if (actuals.length < 1) {
    return null;
  }

  const endDate = addYearsUTC(toUtc(goal.birthDate), goal.retirementAge);

  const startDate = actuals.length > 0 ? actuals[0].date : new Date();
  const startAmount = actuals.length > 0 ? actuals[0].value : 0;

  const predictionPoor = createPrediction(
    startDate,
    startAmount,
    endDate,
    projectedSavingsPoor,
    goal.contributions,
  );
  const predictionAverage = createPrediction(
    startDate,
    startAmount,
    endDate,
    projectedSavingsAverage,
    goal.contributions,
  );

  const xMin = new Date(
    Math.max(
      predictionPoor[0].date.getTime(),
      startDate.getTime(),
      addYearsUTC(new Date(), -2).getTime(),
    ),
  );
  const xMax = new Date(
    predictionPoor[predictionPoor.length - 1].date.getTime(),
  );

  const getMinMax = (a) =>
    a
      .filter(
        (x) =>
          x.date.getTime() >= xMin.getTime() &&
          x.date.getTime() <= xMax.getTime(),
      )
      .reduce(
        (p, c) => {
          return {
            min: Math.min(c.value, p.min !== undefined ? p.min : c.value),
            max: Math.max(c.value, p.max !== undefined ? p.max : c.value),
          };
        },
        { min: undefined, max: undefined },
      );

  const poorMinMax = getMinMax(predictionPoor);
  const avgMinMax = getMinMax(predictionAverage);
  const actMinMax = getMinMax(actuals);

  const yMin = Math.min(poorMinMax.min, avgMinMax.min, actMinMax.min || 0);
  const yMax = Math.max(poorMinMax.max, avgMinMax.max, actMinMax.max || 1);

  const ActualLine = ({ line }) => (
    <Path key={'line'} d={line} stroke={theme.colors.primary} fill={'none'} />
  );

  const PredictLine = ({ line }) => (
    <Path key={'line'} d={line} stroke={theme.colors.alt} fill={'none'} />
  );

  return (
    <View style={{ height: 200 }}>
      <AreaChart
        style={{ height: 200 }}
        data={predictionPoor}
        yAccessor={({ item }) => item.value}
        xAccessor={({ item }) => item.date}
        xScale={scale.scaleTime}
        yMin={yMin}
        yMax={yMax}
        xMin={xMin}
        xMax={xMax}
        svg={{ fill: 'url(#gradientPoor)' }}
        contentInset={{ top: 20, bottom: 20 }}
        curve={shape.curveNatural}>
        <PredictLine />
        <Defs key={'gradientPoor'}>
          <LinearGradient
            id={'gradientPoor'}
            x1={'0%'}
            y={'0%'}
            x2={'0%'}
            y2={'100%'}>
            <Stop
              offset={'0%'}
              stopColor={theme.colors.alt}
              stopOpacity={0.2}
            />
            <Stop
              offset={'75%'}
              stopColor={theme.colors.alt}
              stopOpacity={0.0}
            />
          </LinearGradient>
        </Defs>
      </AreaChart>

      <AreaChart
        style={StyleSheet.absoluteFill}
        data={predictionAverage}
        yAccessor={({ item }) => item.value}
        xAccessor={({ item }) => item.date}
        xScale={scale.scaleTime}
        yMin={yMin}
        yMax={yMax}
        xMin={xMin}
        xMax={xMax}
        svg={{ fill: 'url(#gradientAvg)' }}
        contentInset={{ top: 20, bottom: 20 }}
        curve={shape.curveNatural}>
        <PredictLine />
        <Defs key={'gradientAvg'}>
          <LinearGradient
            id={'gradientAvg'}
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

      <AreaChart
        style={StyleSheet.absoluteFill}
        data={actuals}
        yAccessor={({ item }) => item.value}
        xAccessor={({ item }) => item.date}
        xScale={scale.scaleTime}
        yMin={yMin}
        yMax={yMax}
        xMin={xMin}
        xMax={xMax}
        svg={{ fill: 'url(#gradient)' }}
        contentInset={{ top: 20, bottom: 20 }}
        curve={shape.curveNatural}>
        <ActualLine />
        <Defs key={'gradient'}>
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
    </View>
  );
};

const mapStateToProps = (state) => {
  const netWorth = getNetWorth(state);
  const goal = getGoalInput(state);

  return { netWorth, goal };
};

export default connect(mapStateToProps)(GoallChart);
