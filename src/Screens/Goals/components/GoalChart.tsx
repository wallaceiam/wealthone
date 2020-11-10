import React from 'react';
import { View, StyleSheet } from 'react-native';
import { Path, Defs, LinearGradient, Stop } from 'react-native-svg';
import { AreaChart } from 'react-native-svg-charts';
import * as scale from 'd3-scale';
import * as shape from 'd3-shape';

import { useTheme } from '../../../Theme';

const GoallChart = ({portfolio}) => {
  const theme = useTheme();

  const getDataRange = (startDate, endDate) => {
    const interval = 1;

    var retVal = [];
    var current = new Date(startDate);

    while (current <= endDate) {
      retVal.push(new Date(current));
      current = addMonthsUTC(current, interval);
    }

    return retVal;
  };
  const addMonthsUTC = (date, count) => {
    if (date && count) {
      var m,
        d = (date = new Date(+date)).getDate();

      date.setMonth(date.getMonth() + count, 1);
      m = date.getMonth();
      date.setDate(d);
      if (date.getMonth() !== m) date.setDate(0);
    }
    return date;
  }

  const addYearsUTC = (date, count) => {
    if (date && count) {
      var y,
        d = (date = new Date(+date)).getDate();

      date.setFullYear(date.getFullYear() + count, 1);
      y = date.getFullYear();
      date.setDate(d);
      if (date.getFullYear() !== y) date.setDate(0);
    }
    return date;
  }

  const getNumberOfMonths = (d1, d2) => {
    return (
      (d1.getFullYear() - d2.getFullYear()) * 12 +
      (d1.getMonth() - d2.getMonth())
    );
  };

  const createPrediction = (startDate, startAmount, endDate, endAmount) => {
    const preddates = getDataRange(startDate, endDate);
    //this.addYearsUTC(endActualDate, 5));

    const interm = endAmount / (startAmount === 0 ? 1 : startAmount);

    const monthlyRate =
      Math.pow(interm, 1 / getNumberOfMonths(endDate, startDate)) - 1;
    var futureValue = startAmount;

    return preddates.map((v, i) => {
      futureValue = futureValue * (1 + monthlyRate);
      return {
        value: futureValue,
        date: v,
      };
    });
  };

  const { stats, goal } = portfolio;
    const { netWorth } = stats || { netWorth: [] };
    const { input, result } = goal || { input: {}, result: {} };

    if (!result) {
      return null;
    }

    const actuals = (netWorth || []).map((c) => {
      return {
        date: new Date(Date.parse(c.date)),
        value: c.total,
      };
    });

    const endDate = addYearsUTC(
      new Date(),
      input ? input.retirementAge - input.currentAge : 0,
    );
    const startDate = actuals.length > 0 ? actuals[0].date : new Date();
    const endActualDate =
      actuals.length > 0 ? actuals[actuals.length - 1].date : new Date();
    const startAmount = actuals.length > 0 ? actuals[0].value : 0;

    const predictionPoor = createPrediction(
      startDate,
      startAmount,
      endDate,
      result.projectedSavingsPoor,
    );
    const predictionAverage = createPrediction(
      startDate,
      startAmount,
      endDate,
      result.projectedSavingsAverage,
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
    /*new Date(Math.min(
                predictionPoor[predictionPoor.length - 1].date.getTime(),
                // // actuals[actuals.length-1].date.getTime(), 
                this.addYearsUTC(new Date(), 10).getTime()));
            */

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

    const yMin = Math.min(poorMinMax.min, avgMinMax.min, actMinMax.min);
    const yMax = Math.max(poorMinMax.max, avgMinMax.max, actMinMax.max);

    const ActualLine = ({ line }) => (
      <Path
        key={'line'}
        d={line}
        stroke={theme.colors.primary}
        fill={'none'}
      />
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

export default GoallChart;
