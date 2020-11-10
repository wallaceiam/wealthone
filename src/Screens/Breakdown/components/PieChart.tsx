import React, { useState } from 'react';
import { View } from 'react-native';
import * as shape from 'd3-shape';
import Svg, { G, Path } from 'react-native-svg';

export interface IPieChartData {
  svg: object;
  key: any;
  value: number;
  arc: object;
  onPress?: () => void;
}

export interface IPieChartProps {
  data: IPieChartData[];
  innerRadius?: number | string;
  outerRadius?: number | string;
  labelRadius?: number | string;
  padAngle?: number;
  animate: boolean;
  animationDuration?: number;
  style?: any;
  sort?: (a, b) => number;
  valueAccessor?: ({ item }) => number;
  startAngle?: number;
  endAngle?: number;
  children?: React.ReactNode[];
}
const PieChart = ({
  data,
  // dataPoints,
  innerRadius = '50%',
  outerRadius,
  labelRadius,
  padAngle = 0.05,
  animate = false,
  animationDuration = 0,
  style,
  sort = (a, b) => b.value - a.value,
  valueAccessor = ({ item }) => item.value,
  children,
  startAngle = 0,
  endAngle = Math.PI * 2,
}: IPieChartProps) => {
  const [width, setWidth] = useState(100);
  const [height, setHeight] = useState(100);

  const _onLayout = (event) => {
    const {
      nativeEvent: {
        layout: { height, width },
      },
    } = event;

    setWidth(width);
    setHeight(height);
  };

  const _calculateRadius = (arg, max, defaultVal) => {
    if (typeof arg === 'string') {
      return (arg.split('%')[0] / 100) * max;
    } else if (arg) {
      return arg;
    } else {
      return defaultVal;
    }
  };

  if (data.length === 0) {
    return <View style={style} />;
  }

  const maxRadius = Math.min(width, height) / 2;

  if (Math.min(...data.map((obj) => valueAccessor({ item: obj }))) < 0) {
    console.error(
      "don't pass negative numbers to pie-chart, it makes no sense!",
    );
  }

  const _outerRadius = _calculateRadius(outerRadius, maxRadius, maxRadius);
  const _innerRadius = _calculateRadius(innerRadius, maxRadius, 0);
  const _labelRadius = _calculateRadius(labelRadius, maxRadius, _outerRadius);

  if (outerRadius > 0 && _innerRadius >= outerRadius) {
    console.warn('innerRadius is equal to or greater than outerRadius');
  }

  const arcs = data.map((item) => {
    const arc = shape
      .arc()
      .outerRadius(_outerRadius)
      .innerRadius(_innerRadius)
      .padAngle(padAngle); // Angle between sections

    item.arc &&
      Object.entries(item.arc).forEach(([key, value]) => {
        if (typeof arc[key] === 'function') {
          if (typeof value === 'string') {
            arc[key]((value.split('%')[0] / 100) * _outerRadius);
          } else {
            arc[key](value);
          }
        }
      });

    return arc;
  });

  const labelArcs = data.map((item, index) => {
    if (labelRadius) {
      return shape
        .arc()
        .outerRadius(_labelRadius)
        .innerRadius(_labelRadius)
        .padAngle(padAngle);
    }
    return arcs[index];
  });

  const pieSlices = shape
    .pie()
    .value((d) => valueAccessor({ item: d }))
    .sort(sort)
    .startAngle(startAngle)
    .endAngle(endAngle)(data);

  const slices = pieSlices.map((slice, index) => ({
    ...slice,
    pieCentroid: arcs[index].centroid(slice),
    labelCentroid: labelArcs[index].centroid(slice),
  }));

  const extraProps = {
    width,
    height,
    data,
    slices,
  };

  return (
    <View style={style}>
      <View style={{ flex: 1 }} onLayout={(event) => _onLayout(event)}>
        {height > 0 && width > 0 && (
          <Svg style={{ height, width }}>
            <G x={width / 2} y={height / 2}>
              {pieSlices.map((slice, index) => {
                const { key, onPress, svg } = data[index];
                console.log(data[index]);
                return (
                  <Path
                    key={key}
                    onPress={onPress}
                    d={arcs[index](slice)} 
                    {...svg}
                  />
                );
              })}
            </G>
          </Svg>
        )}
      </View>
    </View>
  );
};

export default PieChart;
