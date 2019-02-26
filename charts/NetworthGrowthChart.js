import React from "react";
import { Animated, StyleSheet } from "react-native";
import { AreaChart } from "react-native-svg-charts";
import { Path, Defs, LinearGradient, Stop, Rect, Line } from "react-native-svg";
import * as shape from "d3-shape";
import * as scale from "d3-scale";

import { globalColours } from "./../Colours";

export class NetworthGrowthChart extends React.Component {
  state = {
    isPressed: false,
    pressedX: 0,
    pressedY: 0
  };

  onPressedIn(e) {
    const { nativeEvent } = e;
    const { pageX, pageY } = nativeEvent;
    this.setState({ isPressed: true, pressedX: pageX, pressedY: pageY });
  }

  onMoved(e) {
    const { nativeEvent } = e;
    const { pageX, pageY } = nativeEvent;
    this.setState({ pressedX: pageX, pressedY: pageY });
  }

  onPressedOut(e) {
    this.setState({ isPressed: false });
    console.log(e);
  }

  render() {
    const { stats } = this.props.portfolio;
    const { netWorth } = stats || { netWorth: [] };
    const data = (netWorth || []).map(c => {
      return {
        date: new Date(Date.parse(c.date)),
        value: c.total
      };
    });

    const Gradient = any => (
      <Defs>
        <LinearGradient
          id={"gradient"}
          x1={"0%"}
          y={"0%"}
          x2={"0%"}
          y2={"100%"}
        >
          <Stop
            offset={"0%"}
            stopColor={globalColours.secondary}
            stopOpacity={0.2}
          />
          <Stop
            offset={"75%"}
            stopColor={globalColours.secondary}
            stopOpacity={0.0}
          />
        </LinearGradient>
      </Defs>
    );

    const GraphLine = ({ line }) => (
      <Path
        key={"line"}
        d={line}
        stroke={globalColours.secondary}
        fill={"none"}
      />
    );

    const VerticalLine = ({ line }) =>
      this.state.isPressed ? (
        <Line
          x1={this.state.pressedX}
          x2={this.state.pressedX}
          y1={"0%"}
          y2={"100%"}
          stroke={globalColours.primary}
        />
      ) : // <Path
      //     key={'line'}
      //     d={line}
      //     stroke={'rgb(134, 65, 244)'}
      //     fill={'none'}
      // />

      null;

    return data.length > 1 ? (
          <AreaChart
            style={{ height: 200 }}
            data={data}
            yAccessor={({ item }) => item.value}
            xAccessor={({ item }) => item.date}
            xScale={scale.scaleTime}
            contentInset={{ top: 30, bottom: 30 }}
            curve={shape.curveNatural}
            svg={{ fill: "url(#gradient)" }}
            // svg={{ fill: globalColours.primary_o20 }}
          >
            <GraphLine />
            <Defs key={"gradient"}>
              <LinearGradient
                id={"gradient"}
                x1={"0%"}
                y={"0%"}
                x2={"0%"}
                y2={"100%"}
              >
                <Stop
                  offset={"0%"}
                  stopColor={globalColours.secondary}
                  stopOpacity={0.2}
                />
                <Stop
                  offset={"75%"}
                  stopColor={globalColours.white}
                  stopOpacity={0.0}
                />
              </LinearGradient>
            </Defs>
            <VerticalLine />
            {/* <Rect x='0%' y='0%' width="100%" height="100%"
                    fill="#fff"
                    fillOpacity={0}
                    onPressIn={(e) => this.onPressedIn(e)}
                    onPressOut={(e) => this.onPressedOut(e)}
                    onResponderMove={(e) => this.onMoved(e)} /> */}
          </AreaChart>
    ) : null;
  }
}
