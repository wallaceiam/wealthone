import React from 'react';
import { View, StyleSheet } from 'react-native';
import { Path, Defs, LinearGradient, Stop } from 'react-native-svg';
import { AreaChart } from 'react-native-svg-charts';
import { connect } from 'react-redux';
import * as scale from 'd3-scale';
import * as shape from 'd3-shape';

import { useTheme } from '../../../Theme';
import { toUtc } from '../../../Redux/DateHelpers';

const GoallChart = ({
  portfolio,
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

  const getNumberOfMonths = (d1, d2) => {
    return (
      (d1.getFullYear() - d2.getFullYear()) * 12 +
      (d1.getMonth() - d2.getMonth())
    );
  };

  const createPrediction = (
    startDate,
    startAmount,
    endDate,
    endAmount,
    monthlyContributions,
  ) => {
    const preddates = getDataRange(startDate, endDate);
    //this.addYearsUTC(endActualDate, 5));

    /*
    const interm = endAmount / (startAmount === 0 ? 1 : startAmount);

    const monthlyRate =
      Math.pow(interm, 1 / getNumberOfMonths(endDate, startDate)) - 1;
    let futureValue = startAmount === 0 ? 1 : startAmount;

    return preddates.map((v, i) => {
      futureValue = futureValue * (1 + monthlyRate);
      return {
        value: futureValue,
        date: v,
      };
    });*/

    // https://github.com/ebradyjobory/finance.js/blob/master/finance.js
    // Compound Interest (CI)
    const CI = (rate, numOfCompoundings, principal, numOfPeriods) => {
      const ci =
        principal *
        Math.pow(
          1 + rate / 100 / numOfCompoundings,
          numOfCompoundings * numOfPeriods,
        );
      return Math.round(ci * 100) / 100;
    };

    // Compound Annual Growth Rate (CAGR)
    const CAGR = (beginningValue, endingValue, numOfPeriods) => {
      var cagr = Math.pow(endingValue / beginningValue, 1 / numOfPeriods) - 1;
      return Math.round(cagr * 10000) / 100;
    };

    const rate = CAGR(
      startAmount === 0 ? 1 : startAmount,
      endAmount,
      preddates.length + 1,
    );
    console.log(rate);
    return preddates.map((v, i) => {
      const amount = monthlyContributions * (i + 1) * (1 + rate / 100 / 12);
      if (amount > endAmount) {
        throw new Error(`${amount} > ${endAmount}`);
      }
      return {
        value: amount,
        date: v,
      };
    });
  };

  const { stats } = portfolio;
  const { netWorth } = stats || { netWorth: [] };

  const actuals = (netWorth || []).map((c) => {
    return {
      date: new Date(Date.parse(c.date)),
      value: c.total,
    };
  });

  const endDate = addYearsUTC(toUtc(goal.birthDate), goal.retirementAge);

  const startDate = actuals.length > 0 ? actuals[0].date : new Date();
  const endActualDate =
    actuals.length > 0 ? actuals[actuals.length - 1].date : new Date();
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
  const yMax = Math.max(poorMinMax.max, avgMinMax.max, actMinMax.max || 0);

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
  const portfolio = state.portfolio;
  const goal = state.goal;
  return { portfolio, goal };
};

export default connect(mapStateToProps)(GoallChart);
